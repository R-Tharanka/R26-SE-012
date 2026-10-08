// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pepper Care';

  @override
  String get chooseLanguage => 'Choose your language';

  @override
  String get chooseLanguageSubtitle =>
      'You can change this anytime from the menu.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSinhala => 'සිංහල';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get language => 'Language';

  @override
  String get homeLeafPest => 'Leaf & Pest';

  @override
  String get homeBerryScan => 'Berry Scan';

  @override
  String get homeGradingForecast => 'Grading & Forecast';

  @override
  String get homePests => 'Pests';

  @override
  String get homeLeafHealth => 'Leaf Health';

  @override
  String get homeBerryDisease => 'Berry Disease';

  @override
  String get homeQualityPrice => 'Quality &\nPrice';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get berryLabel => 'Berry';

  @override
  String get leafLabel => 'Leaf';

  @override
  String get pestLabel => 'Pest';

  @override
  String get plantLabel => 'Plant Health';

  @override
  String get statusThinking => 'Thinking…';

  @override
  String get statusValidating => 'Validating the photo…';

  @override
  String get statusInspecting => 'Inspecting the leaves…';

  @override
  String get statusMatching => 'Matching against known patterns…';

  @override
  String get statusCloserLook => 'Hmm, this one needs a closer look…';

  @override
  String get statusAlmostThere => 'Almost there…';

  @override
  String get preparing => 'Preparing…';

  @override
  String scanHint(String label) {
    return 'Scan a $label — tap the shutter or pick from gallery';
  }

  @override
  String get cameraUnavailable => 'Camera unavailable';

  @override
  String modelLoadFailed(String label) {
    return 'Couldn\'t load the \"$label\" model';
  }

  @override
  String get otherScanTypesUnaffected => 'The other scan types are unaffected.';

  @override
  String get couldNotReadImage =>
      'That photo couldn\'t be read. Please try another photo.';

  @override
  String get errSetup =>
      'The scanner isn\'t set up correctly. Please contact support.';

  @override
  String get errOffline =>
      'No internet connection. Check your network and try again.';

  @override
  String get errBusy =>
      'The scanner is busy right now. Please try again in a moment.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get nothingDetected => 'Nothing detected';

  @override
  String findingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count findings',
      one: '1 finding',
    );
    return '$_temp0';
  }

  @override
  String get noMatchesHint =>
      'No matches above the confidence threshold. Try moving closer, steadying the shot, or improving the lighting.';

  @override
  String get lowConfidenceNotice =>
      'Low confidence. Nothing met the usual bar, so weaker matches are shown instead — treat these as a hint, not a diagnosis, and retake in better light if you can.';

  @override
  String get showRecommendations => 'Show recommendations';

  @override
  String get takeAnotherPhoto => 'Take another photo';

  @override
  String get looksHealthy => 'Looks healthy — no treatment needed.';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get retakePhoto => 'Retake photo';

  @override
  String get analyze => 'Analyze';

  @override
  String get gradingHomeTitle => 'Berry Grading and Export Price Forecasting';

  @override
  String get gradingHomeSubtitle =>
      'Capture a pepper berry image to estimate berry quality and get a simple price forecast.';

  @override
  String get checkBerryQuality => 'Check Berry Quality';

  @override
  String get captureBerryTitle => 'Capture Pepper Berry Image';

  @override
  String get noImageSelected => 'No image selected yet.';

  @override
  String get captureTip => 'Tip: use a clear, well-lit photo and avoid blur.';

  @override
  String get couldNotOpenCameraGallery =>
      'Could not open camera/gallery. Please try again.';

  @override
  String get processing => 'Processing';

  @override
  String get analyzingBerryQuality => 'Analyzing berry quality...';

  @override
  String get analyzeFailed => 'Failed to analyze the image. Please try again.';

  @override
  String get backendError => 'Backend error. Please try again.';

  @override
  String get berryQualityResult => 'Berry Quality Result';

  @override
  String get predictedGrade => 'Predicted Grade';

  @override
  String get confidence => 'Confidence';

  @override
  String get qualityScore => 'Quality Score';

  @override
  String get explanation => 'Explanation';

  @override
  String get noExplanation => 'No additional explanation available.';

  @override
  String get visualFactors => 'Visual Factors Detected';

  @override
  String get colorUniformity => 'Color uniformity';

  @override
  String get darkBerryRatio => 'Dark berry ratio';

  @override
  String get lightBerryRatio => 'Light berry ratio';

  @override
  String get textureScore => 'Texture score';

  @override
  String get defectRatio => 'Defect ratio';

  @override
  String get cleanlinessScore => 'Cleanliness score';

  @override
  String get viewPriceForecast => 'View Price Forecast';

  @override
  String get qualityGrade => 'QUALITY GRADE';

  @override
  String get visualEstimateDisclaimer =>
      'Camera-based visual estimate only. Chemical requirements and bulk density are not measured.';

  @override
  String get priceForecast => 'Price Forecast';

  @override
  String get predictedGradeShort => 'Predicted grade';

  @override
  String get useGradeForRecommendation =>
      'Use grade for recommendation (optional)';

  @override
  String get currentPrice => 'Current price (LKR/kg)';

  @override
  String get predictedPrice => 'Predicted price (LKR/kg)';

  @override
  String get trend => 'Trend';

  @override
  String modelLabelPrefix(String model) {
    return 'Model: $model';
  }

  @override
  String get recommendation => 'Recommendation';

  @override
  String decisionLabel(String value) {
    return 'Decision: $value';
  }

  @override
  String urgencyLabel(String value) {
    return 'Urgency: $value';
  }

  @override
  String get suggestedAction => 'Suggested action';

  @override
  String get whyThisRecommendation => 'Why this recommendation?';

  @override
  String get analyzeAnotherImage => 'Analyze Another Image';

  @override
  String get gradeSpecificNote =>
      'Grade-specific forecasting will be improved after grade-wise market data is available.';

  @override
  String get couldNotUpdateRecShowingPrevious =>
      'Could not update recommendation. Showing previous recommendation.';

  @override
  String get couldNotUpdateRec =>
      'Could not update recommendation. Please try again.';

  @override
  String get grade1 => 'Grade 1';

  @override
  String get grade2 => 'Grade 2';

  @override
  String get grade3 => 'Grade 3';

  @override
  String get urgencyHigh => 'High';

  @override
  String get urgencyMedium => 'Medium';

  @override
  String get urgencyLow => 'Low';

  @override
  String get trendRising => 'Rising';

  @override
  String get trendFalling => 'Falling';

  @override
  String get trendStable => 'Stable';

  @override
  String get decisionWaitExport => 'Wait / Target export buyer';

  @override
  String get decisionSellExport => 'Sell (export)';

  @override
  String get decisionSellSoon => 'Sell soon';

  @override
  String get decisionWaitShortly => 'Wait shortly';

  @override
  String get decisionMonitor => 'Monitor';

  @override
  String get decisionSortProcess => 'Sort or process';

  @override
  String get decisionProcessLocal => 'Process locally';

  @override
  String get decisionProcessOrSellNow => 'Process or sell now';

  @override
  String get severity => 'Severity';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get whatWeSee => 'What we see';

  @override
  String get recommendedTreatment => 'Recommended treatment';

  @override
  String get safeRemediation => 'Safe remediation';

  @override
  String get exportMarket => 'Export market';

  @override
  String get leafAnalysisTitle => 'Leaf analysis';

  @override
  String get healthyLeaf => 'Healthy leaf';

  @override
  String get leafRetryHint =>
      'Fill the frame with a single leaf in good light and try again.';

  @override
  String get leafDisclaimer =>
      'AI estimate from one photo. Confirm with a local agronomist before applying any treatment.';

  @override
  String get pestAnalysisTitle => 'Pest analysis';

  @override
  String get noPestsFound => 'No pests found';

  @override
  String get aboveTreatmentThreshold => 'Above treatment threshold';

  @override
  String get pestRetryHint =>
      'Get closer to the leaf/stem/berry in good light and retry.';

  @override
  String get pestDisclaimer =>
      'AI estimate from one photo. Confirm the pest, economic threshold, and exact product and dose with a local agronomist before spraying.';

  @override
  String get berryGradingTitle => 'Berry grading';

  @override
  String get exportCleanCluster => 'Export-clean cluster';

  @override
  String get berryRetryHint =>
      'Fill the frame with a berry cluster in good light and retry.';

  @override
  String get berryDisclaimer =>
      'AI estimate from one photo. Confirm the diagnosis, exact dose, MRL and pre-harvest interval with a local agronomist before applying.';

  @override
  String get low => 'Low';

  @override
  String get analysingLeaf => 'Analysing leaf with AI…';

  @override
  String get analysingBerry => 'Grading berries with AI…';

  @override
  String get analysingPest => 'Inspecting for pests with AI…';

  @override
  String get notPepperLeaf => 'This doesn\'t look like a pepper leaf';

  @override
  String get notBerryCluster => 'This doesn\'t look like a berry cluster';

  @override
  String get notPepperPlant => 'This doesn\'t look like a pepper plant';

  @override
  String get recommendedActionIpm => 'Recommended action (IPM)';

  @override
  String get belowThreshold => 'Below treatment threshold — monitor only';

  @override
  String get clsHealthy => 'Healthy';

  @override
  String get clsHealthyLeaves => 'Healthy leaves';

  @override
  String get clsHealthyBerry => 'Healthy berry';

  @override
  String get clsLeafBlight => 'Leaf Blight';

  @override
  String get clsLittleLeaf => 'Little Leaf';

  @override
  String get clsQuickWilt => 'Quick Wilt';

  @override
  String get clsLaceBugDamage => 'Lace bug damage';

  @override
  String get clsNutrientDeficiency => 'Nutrient deficiency';

  @override
  String get clsOtherDisease => 'Other disease';

  @override
  String get clsOtherDamage => 'Other damage';

  @override
  String get clsUncertain => 'Uncertain';

  @override
  String get scanInstructionsTitle => 'How to scan';

  @override
  String scanInstructionsStep1(String object) {
    return 'Point the camera at the $object and tap the shutter button.';
  }

  @override
  String get scanInstructionsStep2 =>
      'Hold steady in good light and fill the frame with the subject.';

  @override
  String get scanInstructionsStep3 =>
      'Check what we found, then tap Show recommendations to see treatment advice.';

  @override
  String get scanInstructionsStart => 'Got it, start scanning';

  @override
  String get howToScan => 'How to scan';
}
