// =============================================================================
// File: history_labels.dart
// Purpose: Provides reusable history labels user-interface components.
// =============================================================================
import '../../../l10n/app_localizations.dart';
import '../../../shared/class_labels.dart';
import '../models/history_record.dart';

// Process history feature label for this flow.
String historyFeatureLabel(AppLocalizations t, HistoryFeature feature) =>
    switch (feature) {
      HistoryFeature.gradingForecast => t.featureGradingTitle,
      HistoryFeature.pestDetection => t.featurePestTitle,
      HistoryFeature.leafDisease => t.featureLeafTitle,
      HistoryFeature.berryDisease => t.featureBerryDiseaseTitle,
    };

String historyOutcomeLabel(AppLocalizations t, HistoryRecord record) {
  // Process history outcome label for this flow.
  final classCode = record.primaryClassCode;
  if (classCode != null && classCode.trim().isNotEmpty) {
    return localizedClassName(classCode, t);
  }
  return switch (record.outcomeCode) {
    'accepted' => t.historyAccepted,
    'rejected' => t.historyRejected,
    'uncertain' => t.historyUncertain,
    'healthy' => t.clsHealthy,
    'not_target' => t.historyRejected,
    'detected' => t.historyDetectedItems,
    _ => t.phase7NotAvailable,
  };
}
