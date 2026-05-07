import 'dart:io';

import 'package:flutter/material.dart';

import '../models/grading_forecast_result.dart';
import '../services/grading_forecast_api_service.dart';

class PriceForecastScreen extends StatefulWidget {
  const PriceForecastScreen({
    super.key,
    required this.imageFile,
    required this.result,
  });

  final File imageFile;
  final GradingForecastResult result;

  @override
  State<PriceForecastScreen> createState() => _PriceForecastScreenState();
}

class _PriceForecastScreenState extends State<PriceForecastScreen> {
  static const _gradeOptions = <String>['Grade 1', 'Grade 2', 'Grade 3'];
  static const _gradeDataNote =
      'Grade-specific forecasting will be improved after grade-wise market data is available.';

  final _api = GradingForecastApiService();

  late String _selectedGrade;
  late RecommendationResult _recommendation;
  bool _isUpdating = false;
  String? _updateError;

  @override
  void initState() {
    super.initState();
    final initial = widget.result.grading.predictedGrade;
    _selectedGrade = _gradeOptions.contains(initial) ? initial : _gradeOptions.first;
    _recommendation = widget.result.recommendation;
  }

  Future<void> _onGradeChanged(String? next) async {
    if (next == null || next.trim().isEmpty || next == _selectedGrade) return;

    setState(() {
      _selectedGrade = next;
      _isUpdating = true;
      _updateError = null;
    });

    final forecast = widget.result.forecast;
    final grading = widget.result.grading;

    try {
      final updated = await _api.recommend(
        grade: next,
        trend: forecast.trend,
        qualityScore: grading.qualityScore,
        currentPriceLkrPerKg: forecast.currentPriceLkrPerKg,
        predictedPriceLkrPerKg: forecast.predictedPriceLkrPerKg,
      );
      if (!mounted) return;
      setState(() {
        _recommendation = updated;
        _isUpdating = false;
      });
    } on GradingForecastApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _updateError = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update recommendation. Showing previous recommendation.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _updateError = 'Could not update recommendation. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update recommendation. Showing previous recommendation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final forecast = widget.result.forecast;
    final grading = widget.result.grading;
    final rec = _recommendation;

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
                widget.imageFile,
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    items: _gradeOptions
                        .map((g) => DropdownMenuItem<String>(value: g, child: Text(g)))
                        .toList(growable: false),
                    decoration: const InputDecoration(
                      labelText: 'Use grade for recommendation (optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onGradeChanged,
                  ),
                  const SizedBox(height: 8),
                  Text(_gradeDataNote, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  const Divider(),
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
                  Text('Model: ${forecast.model}', style: theme.textTheme.bodySmall),
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
                      if (_isUpdating)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isUpdating) const LinearProgressIndicator(),
                  if (_updateError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _updateError!,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ],
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
