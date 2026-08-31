import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepper_care/features/home/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders a card for each of the four features', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.byType(Card), findsNWidgets(4));
      expect(find.text('Berry Scan'), findsOneWidget);
      expect(find.text('Leaf Scan'), findsOneWidget);
      expect(find.text('Pest Scan'), findsOneWidget);
      expect(find.text('Grading & Forecast'), findsOneWidget);
    });

    testWidgets('every card is tappable', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
      expect(inkWells, hasLength(4));
      for (final inkWell in inkWells) {
        expect(inkWell.onTap, isNotNull);
      }
    });

    testWidgets('lays the cards out in a two-column grid', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });
  });
}
