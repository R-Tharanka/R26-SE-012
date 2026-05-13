import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/grading_forecast_result.dart';
import 'price_forecast_screen.dart';

class BerryQualityResultScreen extends StatelessWidget {
  const BerryQualityResultScreen({
    super.key,
    required this.imageBytes,
    required this.result,
  });

  final Uint8List imageBytes;
  final GradingForecastResult result;

  static const _requiredLimitationNote =
      'Camera-based visual estimate only. Chemical requirements and bulk density are not measured.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grading = result.grading;
    final visual = grading.visualFeatures;
    final explanation = _explanationLines(grading.explanation);
    final limitation = _requiredLimitationNote;

    return Scaffold(
      appBar: AppBar(title: const Text('Berry Quality Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes, fit: BoxFit.cover),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: _gradeBadge(
                      context,
                      grade: grading.predictedGrade,
                      background: colorScheme.primary,
                      foreground: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Predicted Grade', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          grading.predictedGrade,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _pill(
                        context,
                        label: 'Confidence',
                        value: '${(grading.confidence * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Quality Score', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _roundedProgress(
                          value: (grading.qualityScore / 100.0).clamp(0.0, 1.0).toDouble(),
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${grading.qualityScore.toStringAsFixed(1)}/100',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Explanation', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...explanation.map(_bulletLine),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Visual Factors Detected', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _featureSummaryRow(context, label: 'Color uniformity', value: visual.colorUniformityScore),
                  _featureSummaryRow(context, label: 'Dark berry ratio', value: visual.darkBerryRatio),
                  _featureSummaryRow(context, label: 'Light berry ratio', value: visual.lightBerryRatio),
                  _featureSummaryRow(context, label: 'Texture score', value: visual.textureScore),
                  _featureSummaryRow(
                    context,
                    label: 'Defect ratio',
                    value: visual.defectRatio,
                    colorOverride: colorScheme.error,
                  ),
                  _featureSummaryRow(context, label: 'Cleanliness score', value: visual.cleanlinessScore),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(limitation, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                        builder: (_) => PriceForecastScreen(imageBytes: imageBytes, result: result),
                  ),
                );
              },
              child: const Text('View Price Forecast'),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _gradeBadge(
    BuildContext context, {
    required String grade,
    required Color background,
    required Color foreground,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'QUALITY GRADE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground.withAlpha(220),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            grade,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _pill(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  static Widget _roundedProgress({required double value, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        color: color,
      ),
    );
  }

  static Widget _featureSummaryRow(
    BuildContext context, {
    required String label,
    required double value,
    Color? colorOverride,
  }) {
    final theme = Theme.of(context);
    final normalized = value.clamp(0.0, 1.0).toDouble();
    final percent = (normalized * 100).round();
    final color = colorOverride ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$percent%', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          _roundedProgress(value: normalized, color: color),
        ],
      ),
    );
  }

  static Widget _bulletLine(String line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.circle, size: 6),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(line)),
        ],
      ),
    );
  }

  static List<String> _explanationLines(List<String> raw) {
    final cleaned = raw.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (cleaned.isNotEmpty) return cleaned;
    return const ['No additional explanation available.'];
  }
}
