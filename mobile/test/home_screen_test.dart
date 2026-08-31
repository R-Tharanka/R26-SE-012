import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepper_care/features/home/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders a card for each of the four features', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.text('Pests'), findsOneWidget);
      expect(find.text('Leaf Health'), findsOneWidget);
      expect(find.text('Berry Disease'), findsOneWidget);
      expect(find.text('Quality &\nPrice'), findsOneWidget);
    });

    testWidgets('every card is tappable', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      for (final label in const [
        'Pests',
        'Leaf Health',
        'Berry Disease',
        'Quality &\nPrice',
      ]) {
        final inkWell = tester.widget<InkWell>(
          find.ancestor(of: find.text(label), matching: find.byType(InkWell)),
        );
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
