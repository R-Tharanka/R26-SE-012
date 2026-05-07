import 'dart:io';

import 'package:flutter/material.dart';

import '../services/grading_forecast_api_service.dart';
import 'berry_quality_result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final _api = GradingForecastApiService();

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
      final result = await _api.analyze(widget.imageFile);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BerryQualityResultScreen(imageFile: widget.imageFile, result: result),
        ),
      );
    } on GradingForecastApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRunning = false;
        _errorMessage = 'Failed to analyze the image. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isRunning
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Analyzing berry quality...'),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage ?? 'Backend error. Please try again.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _start,
                            child: const Text('Retry'),
                          ),
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
