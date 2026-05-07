import 'dart:io';

import 'package:flutter/material.dart';

import '../models/grading_forecast_result.dart';

class PriceForecastScreen extends StatelessWidget {
  const PriceForecastScreen({
    super.key,
    required this.imageFile,
    required this.result,
  });

  final File imageFile;
  final GradingForecastResult result;

  @override
  Widget build(BuildContext context) {
    final forecast = result.forecast;
    final rec = result.recommendation;
    final trendLabel = _prettyTrend(forecast.trend);
    final trendIcon = _trendIcon(forecast.trend);
    final trendColor = _trendColor(context, forecast.trend);

    return Scaffold(
      appBar: AppBar(title: const Text('Price Forecast')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                height: 160,
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
                    'Price Forecast',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _kvRow(
                    context,
                    label: 'Current price (LKR/kg)',
                    value: forecast.currentPriceLkrPerKg.toString(),
                  ),
                  _kvRow(
                    context,
                    label: 'Predicted price (LKR/kg)',
                    value: forecast.predictedPriceLkrPerKg.toString(),
                  ),
                  _trendRow(
                    context,
                    label: 'Trend',
                    icon: trendIcon,
                    iconColor: trendColor,
                    value: trendLabel,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Model: ${forecast.model}',
                    style: Theme.of(context).textTheme.bodySmall,
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
                    'Recommendation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rec.message,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _kvRow(context, label: 'Urgency', value: _prettyUrgency(rec.urgencyLevel)),
                  _kvRow(context, label: 'Suggested action', value: rec.suggestedAction),
                  const SizedBox(height: 12),
                  ...rec.explanation.map(
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
                    rec.limitationNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Analyze Another Image'),
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _trendRow(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ],
      ),
    );
  }

  static String _prettyUrgency(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'HIGH':
        return 'High';
      case 'MEDIUM':
        return 'Medium';
      case 'LOW':
        return 'Low';
      default:
        return raw;
    }
  }

  static String _prettyTrend(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'upward':
        return 'Rising';
      case 'downward':
        return 'Falling';
      case 'stable':
        return 'Stable';
      default:
        return raw;
    }
  }

  static IconData _trendIcon(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'upward':
        return Icons.arrow_upward;
      case 'downward':
        return Icons.arrow_downward;
      case 'stable':
        return Icons.arrow_forward;
      default:
        return Icons.trending_up;
    }
  }

  static Color _trendColor(BuildContext context, String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'upward':
        return Colors.green;
      case 'downward':
        return Colors.red;
      case 'stable':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
