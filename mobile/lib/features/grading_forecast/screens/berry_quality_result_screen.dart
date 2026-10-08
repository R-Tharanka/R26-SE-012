import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pepper_care/l10n/app_localizations.dart';

import '../grading_forecast_localizations.dart';
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
    final t = AppLocalizations.of(context);
    final grading = result.grading;
    return Scaffold(
      appBar: AppBar(title: Text(t.phase7DecisionSupportTitle)),
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
                    localizedDecisionCategory(
                      t,
                      result.decisionSupport.category,
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(localizedDecisionSummary(t, result)),
                  const Divider(),
                  _row(
                    t.phase7GradingDecision,
                    localizedDecision(t, grading.decision),
                  ),
                  _row(t.phase7ProjectGrade, localizedGrade(t, grading.grade)),
                  _row(
                    t.phase7QualityGate,
                    localizedQualityStatus(t, grading.qualityStatus),
                  ),
                  if (grading.modelConfidence != null)
                    _row(
                      t.phase7ModelScore,
                      grading.modelConfidence!.toStringAsFixed(4),
                    ),
                  Text(
                    t.phase7ConfidenceInterpretation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (grading.rejectionReason != null)
                    _row(
                      t.phase7Reason,
                      localizedRejectionReason(t, grading.rejectionReason!),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.phase7ResearchLimitations,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...localizedResearchLimitations(t).map(
                    (limitation) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $limitation'),
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
              child: Text(t.phase7ViewPriceOutlook),
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
