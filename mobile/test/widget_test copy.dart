import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pepper_care/main.dart';

void main() {
  testWidgets('App boots into the home grid', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Berry Scan'), findsOneWidget);
    expect(find.text('Leaf Scan'), findsOneWidget);
    expect(find.text('Pest Scan'), findsOneWidget);
    expect(find.text('Grading & Forecast'), findsOneWidget);
  });

  // The grading feature no longer sits at the app's root, so this covers both
  // that it still works and that the home -> grading route is wired up. The
  // scanner routes can't be exercised here: they initialise the camera plugin,
  // which is unavailable under flutter_test.
  testWidgets('Home routes into the grading feature', (tester) async {
    await tester.pumpWidget(const MyApp());

    final card = find.ancestor(
      of: find.text('Grading & Forecast'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(
      find.text('Berry Grading and Export Price Forecasting'),
      findsOneWidget,
    );
    expect(find.text('Check Berry Quality'), findsOneWidget);
  });
}
