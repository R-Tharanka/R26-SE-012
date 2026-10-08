import 'package:pepper_care/l10n/app_localizations.dart';

import 'models/grading_forecast_result.dart';
import 'services/grading_forecast_api_service.dart';

extension GradingForecastApiExceptionLocalization
    on GradingForecastApiException {
  String localizedMessage(AppLocalizations t) => switch (kind) {
    GradingForecastApiErrorKind.emptyImage => t.phase7EmptyImage,
    GradingForecastApiErrorKind.imageTooLarge => t.phase7ImageTooLarge,
    GradingForecastApiErrorKind.invalidBackendAddress =>
      t.phase7InvalidBackendAddress,
    GradingForecastApiErrorKind.invalidImage => t.phase7InvalidImage,
    GradingForecastApiErrorKind.unsupportedImage => t.phase7UnsupportedImage,
    GradingForecastApiErrorKind.malformedRequest => t.phase7MalformedRequest,
    GradingForecastApiErrorKind.serviceBusy => t.phase7ServiceBusy,
    GradingForecastApiErrorKind.serviceUnavailable =>
      t.phase7ServiceUnavailable,
    GradingForecastApiErrorKind.timeout => t.phase7Timeout,
    GradingForecastApiErrorKind.unreachable => t.phase7Unreachable,
    GradingForecastApiErrorKind.malformedResponse => t.phase7MalformedResponse,
    GradingForecastApiErrorKind.analysisFailed => t.phase7AnalysisFailed,
  };
}

String localizedDecisionCategory(AppLocalizations t, String category) =>
    switch (category) {
      'REJECT' => t.phase7CategoryReject,
      'UNCERTAIN_GRADE' => t.phase7CategoryUncertainGrade,
      'CONFLICTING_SAMPLE_VIEWS' => t.phase7CategoryConflictingViews,
      'PRICE_DATA_UNAVAILABLE' => t.phase7CategoryPriceUnavailable,
      'FORECAST_UNAVAILABLE' => t.phase7CategoryForecastUnavailable,
      'UPWARD_PRICE_OUTLOOK' => t.phase7CategoryUpwardOutlook,
      'DOWNWARD_PRICE_OUTLOOK' => t.phase7CategoryDownwardOutlook,
      'FLAT_PRICE_OUTLOOK' => t.phase7CategoryFlatOutlook,
      'HIGH_UNCERTAINTY_OUTLOOK' => t.phase7CategoryHighUncertainty,
      _ => category.replaceAll('_', ' '),
    };

String localizedDecision(AppLocalizations t, String value) => switch (value) {
  'GRADE_1' => t.phase7DecisionGrade1,
  'GRADE_2' => t.phase7DecisionGrade2,
  'NO_PEPPER' => t.phase7DecisionNoPepper,
  'POOR_IMAGE' => t.phase7DecisionPoorImage,
  'UNCERTAIN_GRADE' => t.phase7CategoryUncertainGrade,
  'CONFLICTING_SAMPLE_VIEWS' => t.phase7CategoryConflictingViews,
  _ => value.replaceAll('_', ' '),
};

String localizedGrade(AppLocalizations t, String? value) => switch (value) {
  'V3 Grade 1' => t.phase7ProjectGrade1,
  'V3 Grade 2' => t.phase7ProjectGrade2,
  'Grade 1' => t.phase7PriceGrade1,
  'Grade 2' => t.phase7PriceGrade2,
  null => t.phase7NotAvailable,
  _ => value,
};

String localizedQualityStatus(AppLocalizations t, String value) =>
    switch (value) {
      'PASSED' => t.phase7Passed,
      'FAILED' => t.phase7Failed,
      _ => value,
    };

String localizedRejectionReason(AppLocalizations t, String value) =>
    switch (value) {
      'no_detection_above_threshold' => t.phase7ReasonNoDetection,
      'blur_variance_below_minimum' => t.phase7ReasonBlur,
      'brightness_below_minimum' => t.phase7ReasonTooDark,
      'brightness_above_maximum' => t.phase7ReasonTooBright,
      'detected_area_below_minimum' => t.phase7ReasonSmallArea,
      'grade_confidence_below_minimum' => t.phase7ReasonLowConfidence,
      'grade_margin_below_minimum' => t.phase7ReasonLowMargin,
      _ => value.replaceAll('_', ' '),
    };

String localizedDirection(AppLocalizations t, String? value) => switch (value) {
  'UP' => t.phase7DirectionUp,
  'DOWN' => t.phase7DirectionDown,
  'FLAT' => t.phase7DirectionFlat,
  null => t.phase7NotAvailable,
  _ => value,
};

String localizedSignal(AppLocalizations t, String? value) => switch (value) {
  'HIGH_UNCERTAINTY' => t.phase7SignalHighUncertainty,
  'LIMITED_SIGNAL' => t.phase7SignalLimited,
  null => t.phase7NotAvailable,
  _ => value.replaceAll('_', ' '),
};

String localizedPersistence(AppLocalizations t, String? value) =>
    switch (value) {
      'RIDGE_BETTER' => t.phase7RidgeBetter,
      'PERSISTENCE_BETTER' => t.phase7PersistenceBetter,
      'TIE' => t.phase7PersistenceTie,
      null => t.phase7NotAvailable,
      _ => value.replaceAll('_', ' '),
    };

String localizedDecisionSummary(
  AppLocalizations t,
  GradingForecastResult result,
) => switch (result.decisionSupport.category) {
  'REJECT' => t.phase7SummaryReject,
  'UNCERTAIN_GRADE' || 'CONFLICTING_SAMPLE_VIEWS' => t.phase7SummaryUncertain,
  'PRICE_DATA_UNAVAILABLE' => t.phase7SummaryPriceUnavailable,
  'FORECAST_UNAVAILABLE' => t.phase7SummaryForecastUnavailable,
  _ => t.phase7SummaryAccepted(
    localizedGrade(t, result.grading.grade),
    localizedGrade(t, result.market.priceGrade),
    localizedDirection(t, result.market.forecastDirection).toLowerCase(),
    localizedSignal(t, result.market.forecastSignal),
  ),
};

List<String> localizedResearchLimitations(AppLocalizations t) => [
  t.phase7LimitationProjectGrade,
  t.phase7LimitationResearchOnly,
  t.phase7LimitationMixedForecast,
];

String localizedMarketSource(AppLocalizations t, String? source) =>
    source == null
    ? t.phase7NotAvailable
    : source == 'EAC farm-gate reference price'
    ? t.phase7EacReferencePrice
    : source;
