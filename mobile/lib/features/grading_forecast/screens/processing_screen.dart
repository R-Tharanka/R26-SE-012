import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pepper_care/l10n/app_localizations.dart';

import '../../../shared/widgets/farmer_ui.dart';
import '../grading_forecast_localizations.dart';
import '../services/grading_forecast_analysis_service.dart';
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
    } on GradingForecastApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _errorMessage = error.localizedMessage(AppLocalizations.of(context));
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.processing)),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _isRunning
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              t.processingFarmerTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.phase7ProcessingMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              size: 48,
                              color: scheme.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.processingErrorTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage ?? t.backendError,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _start,
                                child: Text(t.retry),
                              ),
                            ),
                            TextButton(
                              onPressed: () => popToHome(context),
                              child: Text(t.backToHome),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
