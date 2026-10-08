import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepper_care/features/berry_disease/berry_scanner_screen.dart';
import 'package:pepper_care/features/grading_forecast/screens/grading_forecast_home_screen.dart';
import 'package:pepper_care/features/home/screens/home_screen.dart';
import 'package:pepper_care/features/plant_health/screens/plant_health_scanner_screen.dart';
import 'package:pepper_care/l10n/app_localizations.dart';

Widget _app() => const MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: HomeScreen(),
);

void main() {
  testWidgets('current shell retains all four component entries', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final label in const [
      'Pests',
      'Leaf Health',
      'Berry Disease',
      'Quality &\nPrice',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('grading entry retains the current Phase 7 route', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final card = find.ancestor(
      of: find.text('Quality &\nPrice'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.byType(GradingForecastHomeScreen), findsOneWidget);
    expect(
      find.text('Berry Grading and Export Price Forecasting'),
      findsOneWidget,
    );
    expect(find.textContaining('Grade 3'), findsNothing);
  });

  testWidgets('pest and leaf entries retain the combined plant-health route', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Crop Scan'));
    await tester.pump();

    expect(find.byType(PlantHealthScannerScreen), findsOneWidget);
  });

  testWidgets('berry-disease entry reaches the imported berry scanner', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Berry Disease'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Crop Scan'));
    await tester.pump();

    expect(find.byType(BerryScannerScreen), findsOneWidget);
  });
}
