import 'package:flutter/material.dart';
import 'package:pepper_care/l10n/app_localizations.dart';

import 'berry_capture_screen.dart';

class GradingForecastHomeScreen extends StatelessWidget {
  const GradingForecastHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.appTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.gradingHomeTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.phase7GradingHomeSubtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const BerryCaptureScreen(),
                          ),
                        );
                      },
                      child: Text(t.checkBerryQuality),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
