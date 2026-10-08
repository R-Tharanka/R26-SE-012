import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepper_care/features/grading_forecast/grading_forecast_localizations.dart';
import 'package:pepper_care/features/grading_forecast/models/grading_forecast_result.dart';
import 'package:pepper_care/features/grading_forecast/screens/grading_forecast_home_screen.dart';
import 'package:pepper_care/features/grading_forecast/services/grading_forecast_api_service.dart';
import 'package:pepper_care/l10n/app_localizations.dart';

Widget _localizedApp(Locale locale) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const GradingForecastHomeScreen(),
);

GradingForecastResult _acceptedResult() => GradingForecastResult.fromJson({
  'schema_version': 'phase6_decision_support_v1',
  'grading': {
    'status': 'ACCEPTED',
    'decision': 'GRADE_1',
    'grade': 'V3 Grade 1',
    'model_confidence': 0.92,
    'quality_status': 'PASSED',
    'confidence_interpretation': 'model score; not a calibrated probability',
  },
  'market': {
    'status': 'AVAILABLE',
    'source': 'EAC farm-gate reference price',
    'price_grade': 'Grade 1',
    'latest_reference_date': '2026-09-15',
    'latest_reference_price': 1987.5,
    'forecast_target_date': '2026-09-29',
    'forecast_price': 1990.6,
    'forecast_return': 0.0015,
    'forecast_direction': 'UP',
    'forecast_signal': 'HIGH_UNCERTAINTY',
    'model_vs_persistence': 'RIDGE_BETTER',
  },
  'decision_support': {
    'category': 'HIGH_UNCERTAINTY_OUTLOOK',
    'summary': 'server-owned English summary',
    'limitations': ['server-owned English limitation'],
  },
  'trace': {'grading_model_sha256': 'abc'},
  'runtime': {
    'grading': 'ONNX_RUNTIME_CPU',
    'price': 'FROZEN_RECORDS',
    'mobile': 'BACKEND_API',
    'tflite': 'NOT_USED',
  },
});

void main() {
  testWidgets('grading home renders Sinhala Phase 7 presentation text', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const Locale('si')));
    await tester.pumpAndSettle();

    expect(
      find.text('ගම්මිරිස් ශ්‍රේණිගත කිරීම සහ අපනයන මිල පුරෝකථනය'),
      findsOneWidget,
    );
    expect(find.textContaining('ව්‍යාපෘතියට විශේෂිත'), findsOneWidget);
    expect(find.text('Check Berry Quality'), findsNothing);
  });

  testWidgets('grading home renders Tamil Phase 7 presentation text', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const Locale('ta')));
    await tester.pumpAndSettle();

    expect(
      find.text('மிளகு தரப்படுத்தல் மற்றும் ஏற்றுமதி விலை முன்னறிவிப்பு'),
      findsOneWidget,
    );
    expect(find.textContaining('திட்டத்திற்குரிய'), findsOneWidget);
    expect(find.text('Check Berry Quality'), findsNothing);
  });

  test('localized mappings preserve internal Phase 6 values', () {
    final result = _acceptedResult();
    final sinhala = lookupAppLocalizations(const Locale('si'));
    final tamil = lookupAppLocalizations(const Locale('ta'));

    expect(result.decisionSupport.category, 'HIGH_UNCERTAINTY_OUTLOOK');
    expect(
      localizedDecisionCategory(sinhala, result.decisionSupport.category),
      'ඉහළ අනිශ්චිතතා දැක්ම',
    );
    expect(
      localizedDecisionCategory(tamil, result.decisionSupport.category),
      'அதிக நிச்சயமின்மை நோக்கு',
    );
    expect(
      localizedDecisionSummary(sinhala, result),
      contains('V3 ශ්‍රේණිය 1'),
    );
    expect(localizedDecisionSummary(tamil, result), contains('V3 தரம் 1'));
  });

  test('API error kinds receive locale-specific safe messages', () {
    const error = GradingForecastApiException(
      'Cannot reach the research backend.',
      kind: GradingForecastApiErrorKind.unreachable,
    );
    final sinhala = lookupAppLocalizations(const Locale('si'));
    final tamil = lookupAppLocalizations(const Locale('ta'));

    expect(error.localizedMessage(sinhala), contains('සම්බන්ධ විය නොහැක'));
    expect(error.localizedMessage(tamil), contains('அணுக முடியவில்லை'));
  });
}
