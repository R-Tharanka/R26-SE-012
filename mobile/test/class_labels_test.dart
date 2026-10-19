// =============================================================================
// File: class_labels_test.dart
// Purpose: Verifies the class labels test behavior.
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepper_care/l10n/app_localizations.dart';
import 'package:pepper_care/shared/class_labels.dart';

void main() {
  // Register the tests defined in this file.
  final t = lookupAppLocalizations(const Locale('en'));

  test('localizes known internal labels without changing the vocabulary', () {
    expect(localizedClassName('healthy_berry', t), 'Healthy berry');
    expect(localizedClassName('lace_bug_damage', t), 'Lace bug damage');
    expect(localizedClassName('Quick Wilt', t), 'Quick Wilt');
  });

  test('preserves scientific and unknown class names', () {
    expect(
      localizedClassName('Diconocoris distanti', t),
      'Diconocoris distanti',
    );
    expect(localizedClassName('new_class', t), 'new_class');
  });
}
