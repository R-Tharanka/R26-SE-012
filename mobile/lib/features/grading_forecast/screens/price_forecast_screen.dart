import 'package:flutter/material.dart';
import 'package:pepper_care/l10n/app_localizations.dart';

import '../grading_forecast_localizations.dart';
import '../models/grading_forecast_result.dart';

class PriceForecastScreen extends StatelessWidget {
  const PriceForecastScreen({super.key, required this.result});

  final GradingForecastResult result;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final market = result.market;
    final interval = market.forecastInterval;
    return Scaffold(
      appBar: AppBar(title: Text(t.phase7PriceOutlookTitle)),
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
                    localizedDecisionCategory(
                      t,
                      result.decisionSupport.category,
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _row(
                    t.phase7PriceSeries,
                    localizedGrade(t, market.priceGrade),
                  ),
                  _row(t.phase7Source, localizedMarketSource(t, market.source)),
                  _row(
                    t.phase7LatestReferenceDate,
                    market.latestReferenceDate ?? t.phase7NotAvailable,
                  ),
                  _row(
                    t.phase7LatestReferencePrice,
                    _price(t, market.latestReferencePrice),
                  ),
                  _row(
                    t.phase7FrozenForecastTarget,
                    market.forecastTargetDate ?? t.phase7NotAvailable,
                  ),
                  _row(
                    t.phase7FrozenForecastPrice,
                    _price(t, market.forecastPrice),
                  ),
                  _row(
                    t.phase7Direction,
                    localizedDirection(t, market.forecastDirection),
                  ),
                  _row(
                    t.phase7Signal,
                    localizedSignal(t, market.forecastSignal),
                  ),
                  _row(
                    t.phase7PersistenceComparison,
                    localizedPersistence(t, market.modelVsPersistence),
                  ),
                  if (interval != null)
                    _row(
                      t.phase7ForecastInterval,
                      '${_price(t, interval.lower)} – ${_price(t, interval.upper)}',
                    ),
                  const SizedBox(height: 12),
                  Text(t.phase7ForecastDisclaimer),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: Text(t.phase7ResearchTrace),
            children: result.trace.entries
                .map(
                  (entry) => ListTile(
                    dense: true,
                    title: Text(entry.key),
                    subtitle: Text(
                      entry.value?.toString() ?? t.phase7NullValue,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static String _price(AppLocalizations t, double? value) => value == null
      ? t.phase7NotAvailable
      : t.phase7PriceValue(value.toStringAsFixed(2));

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
