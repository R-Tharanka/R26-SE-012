import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/grading_forecast_result.dart';

class PriceForecastScreen extends StatefulWidget {
  const PriceForecastScreen({
    super.key,
    required this.imageBytes,
    required this.result,
  });

  final Uint8List imageBytes;
  final GradingForecastResult result;

  @override
  State<PriceForecastScreen> createState() => _PriceForecastScreenState();
}

class _PriceForecastScreenState extends State<PriceForecastScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final forecast = widget.result.forecast;
    final grading = widget.result.grading;
    final rec = widget.result.recommendation;
    final priceAvailable = _hasPredictedMarketPrice(forecast);

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
              child: Image.memory(
                widget.imageBytes,
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
                  Text('Price Forecast', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _kvRow(context, label: 'Predicted grade', value: grading.predictedGrade),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  _kvRow(
                    context,
                    label: 'Predicted market price',
                    value: _predictedMarketPriceLabel(forecast),
                  ),
                  if (priceAvailable)
                    _trendRow(
                      context,
                      label: 'Trend',
                      icon: trendIcon,
                      iconColor: trendColor,
                      value: trendLabel,
                    ),
                  const SizedBox(height: 8),
                  Text(_priceDataNote(grading.predictedGrade), style: theme.textTheme.bodySmall),
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
                  Row(
                    children: [
                      Expanded(child: Text('Recommendation', style: theme.textTheme.titleLarge)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text('Decision: ${_prettyDecision(rec.decision)}'),
                        backgroundColor: colorScheme.primaryContainer,
                      ),
                      Chip(
                        label: Text('Urgency: ${_prettyUrgency(rec.urgencyLevel)}'),
                        backgroundColor: colorScheme.secondaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(rec.message, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _kvRow(context, label: 'Suggested action', value: rec.suggestedAction),
                  const SizedBox(height: 12),
                  if (rec.explanation.isNotEmpty)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
                      title: const Text('Why this recommendation?'),
                      children: rec.explanation.map(_bulletLine).toList(growable: false),
                    ),
                  const SizedBox(height: 12),
                  Text(rec.limitationNote, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Analyze Another Image'),
            ),
          ),
        ],
      ),
    );
  }

  static bool _hasPredictedMarketPrice(ForecastResult forecast) {
    return forecast.predictedPriceLkrPerKg > 0 &&
        !forecast.model.toLowerCase().contains('unavailable');
  }

  static String _predictedMarketPriceLabel(ForecastResult forecast) {
    if (!_hasPredictedMarketPrice(forecast)) {
      return 'Not available';
    }
    return 'Rs. ${forecast.predictedPriceLkrPerKg} / kg';
  }

  static String _priceDataNote(String grade) {
    switch (grade.trim()) {
      case 'Grade 1':
        return 'Based on National Grade 1 average weekly market data.';
      case 'Grade 2':
        return 'Estimated from National Grade 1 data using the observed Grade 1 to Grade 2 market-price gap.';
      case 'Grade 3':
        return 'Grade 3 market-price prediction is not shown because historical Grade 3 price data is not available.';
      default:
        return 'Grade-specific market-price data is limited.';
    }
  }

  static Widget _bulletLine(String line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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

  static Widget _kvRow(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleSmall,
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
    final theme = Theme.of(context);
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
              Text(value, style: theme.textTheme.titleSmall),
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

  static String _prettyDecision(String raw) {
    final upper = raw.trim().toUpperCase();
    switch (upper) {
      case 'WAIT_OR_TARGET_EXPORT_BUYER':
        return 'Wait / Target export buyer';
      case 'SELL_EXPORT':
        return 'Sell (export)';
      case 'SELL_SOON':
        return 'Sell soon';
      case 'WAIT_SHORTLY':
        return 'Wait shortly';
      case 'MONITOR':
        return 'Monitor';
      case 'SORT_OR_PROCESS':
        return 'Sort or process';
      case 'PROCESS_LOCAL':
        return 'Process locally';
      case 'PROCESS_OR_SELL_IMMEDIATELY':
        return 'Process or sell now';
      default:
        return raw.replaceAll('_', ' ').trim();
    }
  }
}
