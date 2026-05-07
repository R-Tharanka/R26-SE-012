import 'dart:io';

import 'package:flutter/material.dart';

import '../models/grading_forecast_result.dart';
import 'price_forecast_screen.dart';

class BerryQualityResultScreen extends StatelessWidget {
  const BerryQualityResultScreen({
    super.key,
    required this.imageFile,
    required this.result,
  });

  final File imageFile;
  final GradingForecastResult result;

  @override
  Widget build(BuildContext context) {
    final grading = result.grading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berry Quality Result'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
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
                  Text(
                    'Predicted Grade',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    grading.predictedGrade,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _kvRow(
                    context,
                    label: 'Quality Score',
                    value: '${grading.qualityScore.toStringAsFixed(1)}/100',
                  ),
                  _kvRow(
                    context,
                    label: 'Confidence',
                    value: '${(grading.confidence * 100).toStringAsFixed(0)}%',
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
                  Text(
                    'Visual Factors Detected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _featureRow('Color uniformity', grading.visualFeatures.colorUniformityScore),
                  _featureRow('Dark berry ratio', grading.visualFeatures.darkBerryRatio),
                  _featureRow('Light berry ratio', grading.visualFeatures.lightBerryRatio),
                  _featureRow('Texture score', grading.visualFeatures.textureScore),
                  _featureRow('Defect ratio', grading.visualFeatures.defectRatio),
                  _featureRow('Cleanliness score', grading.visualFeatures.cleanlinessScore),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('Size: ${grading.supportingLabels.sizeQuality}'),
                      _chip('Color: ${grading.supportingLabels.colorQuality}'),
                      _chip('Texture: ${grading.supportingLabels.textureQuality}'),
                      _chip('Broken: ${grading.supportingLabels.brokenLevel}'),
                      _chip('Light berries: ${grading.supportingLabels.lightBerryLevel}'),
                      _chip('Pinheads: ${grading.supportingLabels.pinheadLevel}'),
                      _chipBool('Foreign matter', grading.supportingLabels.foreignMatterVisible),
                      _chipBool('Mould', grading.supportingLabels.mouldVisible),
                      _chipBool('Insect damage', grading.supportingLabels.insectDamageVisible),
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
                  Text(
                    'Explanation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...grading.explanation.map(
                    (line) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('- '),
                          Expanded(child: Text(line)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    grading.limitation.isNotEmpty
                        ? grading.limitation
                        : 'Camera-based visual estimate only. Chemical requirements and bulk density are not measured.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PriceForecastScreen(imageFile: imageFile, result: result),
                ),
              );
            },
            child: const Text('View Price Forecast'),
          ),
        ],
      ),
    );
  }

  static Widget _kvRow(BuildContext context, {required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  static Widget _featureRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }

  static Widget _chip(String text) {
    return Chip(label: Text(text));
  }

  static Widget _chipBool(String label, bool value) {
    final text = value ? '$label: yes' : '$label: no';
    return Chip(label: Text(text));
  }
}
