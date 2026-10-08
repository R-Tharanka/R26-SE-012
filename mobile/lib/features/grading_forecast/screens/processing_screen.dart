import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pepper_care/l10n/app_localizations.dart';

import '../services/grading_forecast_analysis_service.dart';
import '../grading_forecast_localizations.dart';
import '../services/grading_forecast_api_service.dart'
    show GradingForecastApiException;
import 'berry_quality_result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.imageBytes,
    required this.imageName,
  });

  final Uint8List imageBytes;
  final String imageName;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final _analysisService = GradingForecastAnalysisService();

  bool _isRunning = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _isRunning = true;
      _errorMessage = null;
    });

    try {
      final result = await _analysisService.analyzeBytes(
        widget.imageBytes,
        widget.imageName,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BerryQualityResultScreen(
            imageBytes: widget.imageBytes,
            result: result,
          ),
        ),
      );
    } on GradingForecastApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _errorMessage = e.localizedMessage(AppLocalizations.of(context));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _errorMessage = AppLocalizations.of(context).analyzeFailed;
      });
    }
  }

  @override
  void dispose() {
    _analysisService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.processing)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isRunning
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(t.phase7ProcessingMessage),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage ?? t.backendError,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _start, child: Text(t.retry)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
