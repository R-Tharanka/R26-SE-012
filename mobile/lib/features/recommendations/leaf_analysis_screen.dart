import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import 'analysis_ui.dart';
import 'ai_errors.dart';
import 'ai_leaf_service.dart';
import 'leaf_analysis.dart';

/// Runs an AI leaf analysis on a captured photo and shows the result.
///
/// [prefetch] lets the scanner start the analysis in the background the moment
/// a problem is detected, so the result is often ready by the time the user
/// opens this screen. If null (or after a retry), it runs its own call.
class LeafAnalysisScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Future<LeafAnalysis>? prefetch;
  const LeafAnalysisScreen({
    super.key,
    required this.imageBytes,
    this.prefetch,
  });

  @override
  State<LeafAnalysisScreen> createState() => _LeafAnalysisScreenState();
}

// Holds and manages the changing state of the analysis screen
class _LeafAnalysisScreenState extends State<LeafAnalysisScreen> {
  final _service = AiLeafService();
  late Future<LeafAnalysis>? _pending = widget.prefetch;
  bool _loading = true;
  LeafAnalysis? _result;
  String? _error;

  // Starts the leaf analysis as soon as the screen state is initialized.
  @override
  void initState() {
    super.initState();
    _run();
  }

  // Runs the AI analysis and updates the UI with its result or an error.
  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await (_pending ?? _service.analyze(widget.imageBytes));
      _pending = null; // a retry re-calls the service instead of the dead future
      if (!mounted) return;
      if (!mounted) return;
      setState(() {
        _result = r;
        _loading = false;
      });
    } catch (e, st) {
      logAiError('leaf-analysis', e, st);
      if (!mounted) return;
      setState(() {
        _error = friendlyAiMessage(e);
        _loading = false;
      });
    }
  }

  // Builds the shared analysis layout with the selected leaf image and results.
  @override
  Widget build(BuildContext context) {
    return AnalysisScaffold(
      imageBytes: widget.imageBytes,
      title: 'Leaf analysis',
      titleIcon: IconlyBold.activity,
      children: _body(),
    );
  }

  // Selects the appropriate content for the current loading, error, or result state.
  List<Widget> _body() {
    if (_loading) {
      return const [LoadingView(message: 'Analysing leaf with AI…')];
    }
    if (_error != null) {
      return [ErrorView(message: _error!, onRetry: _run)];
    }
    return _result == null ? const [] : _resultBody(_result!);
  }

  List<Widget> _resultBody(LeafAnalysis r) {
    if (!r.isPepperLeaf) {
      return [
        RetakeView(
          title: "This doesn't look like a pepper leaf",
          message: r.summary.isNotEmpty
              ? r.summary
              : 'Fill the frame with a single leaf in good light and try again.',
          onRetake: () => Navigator.of(context).pop(),
        ),
      ];
    }

    final accent = r.healthy ? kBrand : bandColor(r.severityBand);
    final sev = r.severityPercentage ?? 0;

    return [
      // headline
      Row(children: [
        Icon(r.healthy ? IconlyBold.shield_done : IconlyBold.danger,
            color: accent, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.healthy ? 'Healthy leaf' : r.diseaseType,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: kText)),
              if (r.summary.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(r.summary,
                      style: TextStyle(color: kTextSub, height: 1.35)),
                ),
            ],
          ),
        ),
      ]),
    
      // =====================================================
      // SEVERITY AND CONFIDENCE
      // =====================================================

      // Display severity percentage and AI confidence side by side
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          child: StatTile(
            icon: IconlyBold.chart,
            label: 'Severity',
            color: accent,
            value: r.healthy
                ? const Text('—',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800, color: kBrand))
                : CountUp(sev,
                    suffix: '%',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: accent)),
            sub: r.severityBand.toUpperCase(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatTile(
            icon: IconlyBold.activity,
            label: 'Confidence',
            color: const Color(0xFF3B82F6),
            value: CountUp(r.confidence * 100,
                suffix: '%',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3B82F6))),
            sub: _conf(r.confidence),
          ),
        ),
      ]),

      if (!r.healthy && sev > 0) ...[
        const SizedBox(height: 16),
        AnimatedBar(fraction: sev / 100, color: accent),
      ],
    
      // =====================================================
      // AFFECTED REGIONS
      // =====================================================

      // Display where the AI detected visible symptoms
      if (r.affectedRegions.isNotEmpty)
        SectionCard(
          icon: IconlyBold.show,
          title: 'What we see',
          child: Text(r.affectedRegions,
              style: TextStyle(color: kTextSub, height: 1.45)),
        ),

      // =====================================================
      // TREATMENT RECOMMENDATIONS
      // =====================================================

      // Display treatment suggestions only when treatments exist

      if (r.treatments.isNotEmpty)
        SectionCard(
          icon: IconlyBold.shield_done,
          title: 'Recommended treatment',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < r.treatments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                color: accent,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(r.treatments[i],
                              style: TextStyle(
                                  height: 1.4, color: kText))),
                    ],
                  ),
                ),
            ],
          ),
        ),

      // =====================================================
      // AI DISCLAIMER
      // =====================================================

      // Inform the farmer that the result is only an AI estimate
      // and professional confirmation is recommended

      const InfoCard(
        icon: IconlyBold.info_circle,
        color: Color(0xFF64748B),
        text:
            'AI estimate from one photo. Confirm with a local agronomist before '
            'applying chemical treatments.',
      ),

      const SizedBox(height: 18),
      // =====================================================
      // RETAKE BUTTON
      // =====================================================

      // Return to the previous screen so the user can
      // capture and analyse another leaf image
      FilledButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
        ),
        icon: const Icon(IconlyLight.camera, size: 18),
        label: const Text('Take another photo'),
      ),
    ];
  }

// Converts the AI confidence value into an easy-to-understand label
  String _conf(double c) => c >= 0.75 ? 'High' : (c >= 0.5 ? 'Medium' : 'Low');
}
