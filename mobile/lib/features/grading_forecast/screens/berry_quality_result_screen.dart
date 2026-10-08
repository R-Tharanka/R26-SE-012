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
  @override
  Widget build(BuildContext context) {
    final grading = result.grading;
    final decision = result.decisionSupport;
    return Scaffold(
      appBar: AppBar(title: const Text('Pepper Decision Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(imageBytes, height: 180, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    decision.category.replaceAll('_', ' '),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(decision.summary),
                  const Divider(),
                  _row('Grading decision', grading.decision),
                  _row('Project grade', grading.grade ?? 'Not available'),
                  _row('Quality gate', grading.qualityStatus),
                  if (grading.modelConfidence != null)
                    _row(
                      'Model score',
                      grading.modelConfidence!.toStringAsFixed(4),
                    ),
                  Text(
                    grading.confidenceInterpretation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (grading.rejectionReason != null)
                    _row('Reason', grading.rejectionReason!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Research limitations',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...decision.limitations.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $e'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (result.market.isAvailable) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PriceForecastScreen(result: result),
                ),
              ),
              child: const Text('View grade-specific price outlook'),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        Flexible(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );
}
