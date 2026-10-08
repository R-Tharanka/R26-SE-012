import 'package:flutter/material.dart';
import 'package:pepper_care/l10n/app_localizations.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/farmer_ui.dart';
import '../../recommendations/analysis_ui.dart' show FadeSlideIn;
import '../grading_forecast_localizations.dart';
import '../models/grading_forecast_result.dart';

class PriceForecastScreen extends StatelessWidget {
  const PriceForecastScreen({super.key, required this.result});

  final GradingForecastResult result;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final market = result.market;
    final direction = market.forecastDirection;
    final directionColor = switch (direction) {
      'UP' => const Color(0xFF1F7A45),
      'DOWN' => const Color(0xFFB5473C),
      _ => const Color(0xFF52625A),
    };
    final directionIcon = switch (direction) {
      'UP' => Icons.trending_up_rounded,
      'DOWN' => Icons.trending_down_rounded,
      _ => Icons.trending_flat_rounded,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t.farmerPriceOutlookTitle),
        actions: [
          IconButton(
            tooltip: t.backToHome,
            onPressed: () => popToHome(context),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(kCardRadius),
                ),
                child: Column(
                  children: [
                    Text(
                      t.farmerEstimatedPrice,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _price(t, market.forecastPrice),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(directionIcon, color: Colors.white, size: 21),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              farmerDirectionLabel(t, direction),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delayMs: 70,
              child: FarmerNoticeCard(
                icon: market.forecastSignal == 'HIGH_UNCERTAINTY'
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                message: farmerPriceConfidenceMessage(t, market.forecastSignal),
                color: market.forecastSignal == 'HIGH_UNCERTAINTY'
                    ? kWarmAccent
                    : directionColor,
              ),
            ),
            const SizedBox(height: 14),
            FadeSlideIn(
              delayMs: 140,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.farmerPriceDetails,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        icon: Icons.workspace_premium_outlined,
                        label: t.phase7ProjectGrade,
                        value: localizedGrade(t, market.priceGrade),
                      ),
                      _DetailRow(
                        icon: Icons.event_outlined,
                        label: t.farmerOutlookDate,
                        value:
                            market.forecastTargetDate ?? t.phase7NotAvailable,
                      ),
                      _DetailRow(
                        icon: Icons.receipt_long_outlined,
                        label: t.farmerReferencePrice,
                        value: _price(t, market.latestReferencePrice),
                      ),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: t.farmerReferenceDate,
                        value:
                            market.latestReferenceDate ?? t.phase7NotAvailable,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FarmerNoticeCard(
              icon: Icons.eco_outlined,
              message: t.farmerForecastNotice,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => popToHome(context),
              icon: const Icon(Icons.home_outlined),
              label: Text(t.backToHome),
            ),
          ],
        ),
      ),
    );
  }

  static String _price(AppLocalizations t, double? value) => value == null
      ? t.phase7NotAvailable
      : t.phase7PriceValue(value.toStringAsFixed(2));
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
