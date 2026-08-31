import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/services/yolo_detector.dart';
import '../../features/recommendations/ai_berry_service.dart';
import '../../features/recommendations/ai_detection_service.dart';
import '../../features/recommendations/ai_errors.dart';
import '../../features/recommendations/ai_leaf_service.dart';
import '../../features/recommendations/ai_pest_service.dart';
import '../../features/recommendations/analysis_ui.dart' show fadeScaleRoute;
import '../../features/recommendations/berry_analysis.dart';
import '../../features/recommendations/berry_analysis_screen.dart';
import '../../features/recommendations/leaf_analysis.dart';
import '../../features/recommendations/leaf_analysis_screen.dart';
import '../../features/recommendations/pest_analysis.dart';
import '../../features/recommendations/pest_analysis_screen.dart';
import '../models/scanner_model_config.dart';
import 'scan_result_view.dart';

/// Camera screen for one model: frame the plant, tap the shutter, see what the
/// model found.
///
/// The flow is deliberately one-shot rather than a live stream. A still capture
/// is higher resolution than a preview frame, the user controls exactly what
/// gets analysed, and inference runs once instead of continuously — which
/// matters because it occupies the UI isolate (see [YoloDetector]).
class ScannerView extends StatefulWidget {
  final ScannerModelConfig modelConfig;
  final String title;

  const ScannerView({
    super.key,
    required this.modelConfig,
    required this.title,
  });

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with WidgetsBindingObserver {
  CameraController? _controller;
  final YoloDetector _detector = YoloDetector(); // kept as offline fallback
  final AiDetectionService _aiDetector = AiDetectionService();
  final AiLeafService _leafService = AiLeafService();
  final AiBerryService _berryService = AiBerryService();
  final AiPestService _pestService = AiPestService();
  // Recommendation fetched in the background the moment a problem is detected,
  // so it's ready when the user taps "Show recommendations".
  Future<LeafAnalysis>? _leafRec;
  Future<BerryAnalysis>? _berryRec;
  Future<PestAnalysis>? _pestRec;
  bool _disposed = false;

  /// True from shutter press until the result is ready.
  bool _analyzing = false;

  /// Set once a photo has been captured and analysed.
  Uint8List? _photo;
  DetectionResult? _result;

  String? _modelError;
  String? _cameraError;

  /// Orientations to restore on the way out. The scanner locks to portrait
  /// because the preview cover-fit assumes it, but the lock is process-wide —
  /// leaving it set would pin the rest of the app (notably the grading flow)
  /// to portrait for the remainder of the session.
  static const _defaultOrientations = <DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final cameras = await availableCameras();
      if (_disposed) return;
      await _initCamera(cameras);
      if (_disposed) return;
      await _detector.load(widget.modelConfig);
      if (_disposed) return;
      setState(() {});
    } on CameraException catch (e) {
      if (_disposed) return;
      setState(() => _cameraError = e.description ?? e.code);
    } catch (e) {
      if (_disposed) return;
      setState(() => _modelError = e.toString());
    }
  }

  Future<void> _initCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      throw CameraException('no_camera', 'No camera found on this device.');
    }
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    // Stills can afford more pixels than a 30fps preview could. The detector
    // letterboxes to 640 anyway, so going beyond ~720p costs decode time
    // without improving detections.
    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    if (_disposed) return;
    setState(() => _controller = controller);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _analyzing || !_detector.isReady) return;
    setState(() => _analyzing = true);
    try {
      final shot = await controller.takePicture();
      await _analyzeBytes(await shot.readAsBytes());
    } catch (e, st) {
      _onAnalyzeError(e, st);
    }
  }

  /// Picks an existing photo from the gallery and analyses it with the same
  /// pipeline as a live capture.
  Future<void> _pickFromGallery() async {
    if (_analyzing || !_detector.isReady) return;
    setState(() => _analyzing = true);
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 2000);
      if (picked == null) {
        if (!_disposed) setState(() => _analyzing = false);
        return;
      }
      await _analyzeBytes(await picked.readAsBytes());
    } catch (e, st) {
      _onAnalyzeError(e, st);
    }
  }

  /// Shared detection path for both camera capture and gallery pick.
  Future<void> _analyzeBytes(Uint8List bytes) async {
    // Run the on-device trained (YOLO) model up front. Its detections seed the
    // AI as a domain-trained second opinion (ensemble), and stand in as the
    // result if the AI call fails (offline / no key).
    DetectionResult? yolo;
    try {
      final decoded = img.decodeImage(bytes);
      // JPEG rotation lives in EXIF while the pixels stay in sensor orientation;
      // baking makes them upright to match how Image.memory displays them.
      if (decoded != null && _detector.isReady) {
        yolo = await _detector.detect(img.bakeOrientation(decoded), 0);
      }
    } catch (_) {
      yolo = null;
    }

    // Primary path: AI detection (multi-object, higher accuracy), informed by
    // the trained model's priors. Falls back to the YOLO result on failure.
    DetectionResult result;
    try {
      result = await _aiDetector.detect(
        bytes,
        widget.modelConfig,
        yoloPriors: yolo?.detections ?? const [],
      );
    } catch (_) {
      if (yolo == null) {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          throw StateError('Could not read that image.');
        }
        yolo = await _detector.detect(img.bakeOrientation(decoded), 0);
      }
      result = yolo;
    }
    if (_disposed) return;
    setState(() {
      _photo = bytes;
      _result = result;
      _analyzing = false;
    });
    _prefetchRecommendation(bytes);
  }

  /// Starts fetching the recommendation in the background as soon as a problem
  /// is detected, so it's ready when the user opens the recommendation screen.
  void _prefetchRecommendation(Uint8List bytes) {
    final dets = _result?.detections ?? const [];
    final hasProblem =
        dets.any((d) => !d.className.toLowerCase().contains('healthy'));
    if (!hasProblem) return;
    Future<T> guard<T>(Future<T> f) {
      f.then((_) {}, onError: (_) {}); // avoid unhandled-error reports if unused
      return f;
    }

    switch (widget.modelConfig.id) {
      case 'berry':
        _berryRec = guard(_berryService.analyze(bytes));
      case 'pest':
        _pestRec = guard(_pestService.analyze(bytes));
      case 'plant':
        if (_routesToPest()) {
          _pestRec = guard(_pestService.analyze(bytes));
        } else {
          _leafRec = guard(_leafService.analyze(bytes));
        }
      default:
        _leafRec = guard(_leafService.analyze(bytes));
    }
  }

  void _onAnalyzeError(Object e, [StackTrace? st]) {
    logAiError('scanner-${widget.modelConfig.id}', e, st);
    if (_disposed) return;
    setState(() => _analyzing = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(friendlyAiMessage(e))),
    );
  }

  void _retake() {
    setState(() {
      _photo = null;
      _result = null;
      _leafRec = null;
      _berryRec = null;
      _pestRec = null;
    });
  }

  /// Opens the AI recommendation screen for the captured [photo], choosing the
  /// flow from the active model — and for the combined 'plant' scanner, from
  /// what was actually detected (pest class → pest flow, else leaf).
  void _showRecommendations(Uint8List photo) {
    final Widget page;
    switch (widget.modelConfig.id) {
      case 'berry':
        page = BerryAnalysisScreen(imageBytes: photo, prefetch: _berryRec);
      case 'pest':
        page = PestAnalysisScreen(imageBytes: photo, prefetch: _pestRec);
      case 'plant':
        page = _routesToPest()
            ? PestAnalysisScreen(imageBytes: photo, prefetch: _pestRec)
            : LeafAnalysisScreen(imageBytes: photo, prefetch: _leafRec);
      default:
        page = LeafAnalysisScreen(imageBytes: photo, prefetch: _leafRec);
    }
    Navigator.of(context).push(fadeScaleRoute<void>(page));
  }

  /// For the combined scanner: route by the most-confident non-healthy
  /// detection — a pest class sends the user to the pest flow, otherwise leaf.
  bool _routesToPest() {
    final dets = _result?.detections ?? const [];
    final problems = dets
        .where((d) => !d.className.toLowerCase().contains('healthy'))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final top = problems.isNotEmpty
        ? problems.first
        : (dets.isNotEmpty ? dets.first : null);
    return top != null && AiDetectionService.isPestClass(top.className);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      if (!_disposed) setState(() => _controller = null);
    } else if (state == AppLifecycleState.resumed) {
      _bootstrap();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(_defaultOrientations);
    _controller?.dispose();
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cameraError != null) {
      return _message(
        icon: Icons.no_photography_outlined,
        title: 'Camera unavailable',
        detail: _cameraError!,
      );
    }

    if (_modelError != null) {
      return _message(
        icon: Icons.download_for_offline_outlined,
        title: 'Couldn\'t load the "${widget.modelConfig.label}" model',
        detail: '${widget.modelConfig.assetPath}\n\n$_modelError\n\n'
            'The other scan types are unaffected.',
      );
    }

    final photo = _photo;
    final result = _result;
    if (photo != null && result != null) {
      return ScanResultView(
        photo: photo,
        result: result,
        modelLabel: widget.modelConfig.label,
        onRetake: _retake,
        onShowRecommendations: () => _showRecommendations(photo),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _CoveredPreview(controller: controller),
        if (_analyzing)
          Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Analysing…',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        _buildShutterBar(),
      ],
    );
  }

  Widget _buildShutterBar() {
    final ready = _detector.isReady && !_analyzing;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ready
                      ? 'Scan a ${widget.modelConfig.label.toLowerCase()} — '
                          'tap the shutter or pick from gallery'
                      : 'Preparing…',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleAction(
                    icon: Icons.photo_library_outlined,
                    onPressed: ready ? _pickFromGallery : null,
                  ),
                  const SizedBox(width: 32),
                  _ShutterButton(onPressed: ready ? _capture : null),
                  const SizedBox(width: 32),
                  // Invisible twin keeps the shutter optically centered.
                  const Opacity(
                    opacity: 0,
                    child: IgnorePointer(
                      child: _CircleAction(icon: Icons.photo_library_outlined),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 56),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            style: const TextStyle(
                color: Colors.white54, height: 1.4, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A circular translucent action button (used for the gallery picker).
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CircleAction({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon,
              color: onPressed == null ? Colors.white54 : Colors.white),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _ShutterButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      label: 'Capture and scan',
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fills the screen with the preview using [BoxFit.cover].
class _CoveredPreview extends StatelessWidget {
  final CameraController controller;
  const _CoveredPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize!;
    // previewSize is in sensor (landscape) orientation; swap for portrait.
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: preview.height,
            height: preview.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}
