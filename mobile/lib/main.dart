import 'package:flutter/material.dart';

import 'core/locale/app_locale.dart';
import 'core/theme/app_theme.dart';
import 'features/home/screens/home_screen.dart';
import 'features/onboarding/language_picker_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedLocale();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (_, mode, __) => ValueListenableBuilder<Locale?>(
        valueListenable: appLocale,
        builder: (_, locale, __) => MaterialApp(
          title: 'Pepper Care',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: hasChosenLanguage
              ? const HomeScreen()
              : const LanguagePickerScreen(),
        ),
      ),
    );
  }
}
