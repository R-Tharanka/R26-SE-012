import 'package:flutter/material.dart';
import '../models/grading_forecast_result.dart';

class PriceForecastScreen extends StatelessWidget {
  const PriceForecastScreen({super.key, required this.result});
  final GradingForecastResult result;
  @override
  Widget build(BuildContext context) {
    final market = result.market;
    final interval = market.forecastInterval;
    return Scaffold(
      appBar: AppBar(title: const Text('Price Outlook')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.decisionSupport.category.replaceAll('_', ' '),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _row('Price series', market.priceGrade ?? 'Not available'),
                  _row('Source', market.source ?? 'Not available'),
                  _row(
                    'Latest reference date',
                    market.latestReferenceDate ?? 'Not available',
                  ),
                  _row(
                    'Latest reference price',
                    _price(market.latestReferencePrice),
                  ),
                  _row(
                    'Frozen forecast target',
                    market.forecastTargetDate ?? 'Not available',
                  ),
                  _row('Frozen forecast price', _price(market.forecastPrice)),
                  _row(
                    'Direction',
                    market.forecastDirection ?? 'Not available',
                  ),
                  _row('Signal', market.forecastSignal ?? 'Not available'),
                  _row(
                    'Persistence comparison',
                    market.modelVsPersistence ?? 'Not available',
                  ),
                  if (interval != null)
                    _row(
                      interval.label,
                      '${_price(interval.lower)} – ${_price(interval.upper)}',
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'This is a frozen EAC farm-gate research forecast, not a live buyer offer, guaranteed price, or buy/sell instruction.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: const Text('Research trace'),
            children: result.trace.entries
                .map(
                  (e) => ListTile(
                    dense: true,
                    title: Text(e.key),
                    subtitle: Text(e.value?.toString() ?? 'null'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static String _price(double? value) =>
      value == null ? 'Not available' : 'LKR ${value.toStringAsFixed(2)} / kg';
  static Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        Flexible(child: Text(value, textAlign: TextAlign.right)),
      ],
    ),
  );
}
