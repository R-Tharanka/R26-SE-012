import 'package:flutter/material.dart';

import '../../core/locale/app_locale.dart';
import '../../core/theme/app_theme.dart';
import '../home/screens/home_screen.dart';

/// Starter screen shown on first launch to pick a language, and reused from the
/// home menu to change it later. The prompt is shown in all three languages
/// because we don't yet know which one the user reads.
class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key});

  Future<void> _choose(BuildContext context, Locale locale) async {
    await setLocale(locale);
    if (!context.mounted) return;
    // Opened from the menu → just go back; starter launch → enter the app.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.eco, size: 72, color: kBrand),
                  const SizedBox(height: 12),
                  Text(
                    'Pepper Care',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Choose your language\nභාෂාව තෝරන්න\nமொழியைத் தேர்ந்தெடுக்கவும்',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final locale in kSupportedLocales)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LanguageTile(
                        label: languageDisplayName(locale.languageCode),
                        selected:
                            appLocale.value?.languageCode ==
                            locale.languageCode,
                        onTap: () => _choose(context, locale),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? kBrand.withValues(alpha: 0.15)
          : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? kBrand : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: kBrand),
            ],
          ),
        ),
      ),
    );
  }
}
