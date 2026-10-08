import 'package:flutter_test/flutter_test.dart';
import 'package:pepper_care/core/locale/app_locale.dart';
import 'package:pepper_care/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await loadSavedLocale();
  });

  testWidgets('first launch asks for language before showing home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Pepper Care'), findsWidgets);
    expect(find.text('Quality &\nPrice'), findsOneWidget);
  });
}
