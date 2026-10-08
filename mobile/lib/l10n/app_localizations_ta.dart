// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'Pepper Care';

  @override
  String get chooseLanguage => 'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get chooseLanguageSubtitle =>
      'இதை எப்போது வேண்டுமானாலும் மெனுவில் மாற்றலாம்.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSinhala => 'සිංහල';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get language => 'மொழி';

  @override
  String get homeLeafPest => 'இலை & பூச்சி';

  @override
  String get homeBerryScan => 'மிளகு ஸ்கேன்';

  @override
  String get homeGradingForecast => 'தரப்படுத்தல் & முன்னறிவிப்பு';

  @override
  String get homePests => 'பூச்சிகள்';

  @override
  String get homeLeafHealth => 'இலை ஆரோக்கியம்';

  @override
  String get homeBerryDisease => 'மிளகு பெர்ரி நோய்';

  @override
  String get homeQualityPrice => 'தரம் மற்றும்\nவிலை';

  @override
  String get lightMode => 'ஒளி பயன்முறை';

  @override
  String get darkMode => 'இருள் பயன்முறை';

  @override
  String get berryLabel => 'மிளகு கொட்டை';

  @override
  String get leafLabel => 'இலை';

  @override
  String get pestLabel => 'பூச்சி';

  @override
  String get plantLabel => 'தாவர ஆரோக்கியம்';

  @override
  String get statusThinking => 'சிந்திக்கிறது…';

  @override
  String get statusValidating => 'புகைப்படத்தைச் சரிபார்க்கிறது…';

  @override
  String get statusInspecting => 'இலைகளைப் பரிசோதிக்கிறது…';

  @override
  String get statusMatching => 'அறியப்பட்ட வடிவங்களுடன் ஒப்பிடுகிறது…';

  @override
  String get statusCloserLook => 'ம்ம், இதை இன்னும் கூர்ந்து பார்க்க வேண்டும்…';

  @override
  String get statusAlmostThere => 'கிட்டத்தட்ட முடிந்தது…';

  @override
  String get preparing => 'தயாராகிறது…';

  @override
  String scanHint(String label) {
    return '$label ஸ்கேன் செய்யவும் — ஷட்டரைத் தட்டவும் அல்லது கேலரியில் இருந்து தேர்ந்தெடுக்கவும்';
  }

  @override
  String get cameraUnavailable => 'கேமரா கிடைக்கவில்லை';

  @override
  String modelLoadFailed(String label) {
    return '\"$label\" மாதிரியை ஏற்ற முடியவில்லை';
  }

  @override
  String get otherScanTypesUnaffected =>
      'மற்ற ஸ்கேன் வகைகள் பாதிக்கப்படவில்லை.';

  @override
  String get couldNotReadImage =>
      'அந்தப் புகைப்படத்தைப் படிக்க முடியவில்லை. வேறு புகைப்படத்தை முயற்சிக்கவும்.';

  @override
  String get errSetup =>
      'ஸ்கேனர் சரியாக அமைக்கப்படவில்லை. ஆதரவைத் தொடர்பு கொள்ளவும்.';

  @override
  String get errOffline =>
      'இணைய இணைப்பு இல்லை. உங்கள் நெட்வொர்க்கைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get errBusy =>
      'ஸ்கேனர் இப்போது பணிமிகுதியாக உள்ளது. சிறிது நேரத்தில் மீண்டும் முயற்சிக்கவும்.';

  @override
  String get errGeneric => 'ஏதோ தவறு ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get nothingDetected => 'எதுவும் கண்டறியப்படவில்லை';

  @override
  String findingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count கண்டுபிடிப்புகள்',
      one: '1 கண்டுபிடிப்பு',
    );
    return '$_temp0';
  }

  @override
  String get noMatchesHint =>
      'நம்பகத் தேர்வுக்கு மேல் பொருத்தங்கள் இல்லை. அருகில் சென்று, படத்தை நிலையாக வைத்து, அல்லது வெளிச்சத்தை மேம்படுத்தி மீண்டும் முயற்சிக்கவும்.';

  @override
  String get lowConfidenceNotice =>
      'குறைந்த நம்பகத்தன்மை. வழக்கமான அளவை எதுவும் எட்டவில்லை, எனவே பலவீனமான பொருத்தங்கள் காட்டப்படுகின்றன — இவற்றை நோயறிதலாக அல்ல, ஒரு குறிப்பாகக் கருதவும்; முடிந்தால் நல்ல வெளிச்சத்தில் மீண்டும் படம் எடுக்கவும்.';

  @override
  String get showRecommendations => 'பரிந்துரைகளைக் காட்டு';

  @override
  String get takeAnotherPhoto => 'மற்றொரு புகைப்படம் எடுக்கவும்';

  @override
  String get looksHealthy => 'ஆரோக்கியமாகத் தெரிகிறது — சிகிச்சை தேவையில்லை.';

  @override
  String get camera => 'கேமரா';

  @override
  String get gallery => 'கேலரி';

  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get tryAgain => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get retakePhoto => 'புகைப்படத்தை மீண்டும் எடுக்கவும்';

  @override
  String get analyze => 'பகுப்பாய்வு';

  @override
  String get gradingHomeTitle =>
      'மிளகு தரப்படுத்தல் மற்றும் ஏற்றுமதி விலை முன்னறிவிப்பு';

  @override
  String get gradingHomeSubtitle =>
      'மிளகு கொட்டையின் படத்தை எடுத்து தரத்தை மதிப்பிட்டு எளிய விலை முன்னறிவிப்பைப் பெறுங்கள்.';

  @override
  String get checkBerryQuality => 'கொட்டையின் தரத்தைச் சரிபார்க்கவும்';

  @override
  String get captureBerryTitle => 'மிளகு கொட்டை படத்தை எடுக்கவும்';

  @override
  String get noImageSelected => 'இன்னும் படம் தேர்ந்தெடுக்கப்படவில்லை.';

  @override
  String get captureTip =>
      'குறிப்பு: தெளிவான, நன்கு வெளிச்சமான படத்தைப் பயன்படுத்தி மங்கலைத் தவிர்க்கவும்.';

  @override
  String get couldNotOpenCameraGallery =>
      'கேமரா/கேலரியைத் திறக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get processing => 'செயலாக்கம்';

  @override
  String get analyzingBerryQuality =>
      'கொட்டையின் தரத்தைப் பகுப்பாய்வு செய்கிறது...';

  @override
  String get analyzeFailed =>
      'படத்தைப் பகுப்பாய்வு செய்ய முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get backendError => 'சேவையக பிழை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get berryQualityResult => 'கொட்டை தர முடிவு';

  @override
  String get predictedGrade => 'முன்னறிவிக்கப்பட்ட தரம்';

  @override
  String get confidence => 'நம்பகத்தன்மை';

  @override
  String get qualityScore => 'தர மதிப்பெண்';

  @override
  String get explanation => 'விளக்கம்';

  @override
  String get noExplanation => 'கூடுதல் விளக்கம் இல்லை.';

  @override
  String get visualFactors => 'கண்டறியப்பட்ட காட்சி காரணிகள்';

  @override
  String get colorUniformity => 'நிற சீரான தன்மை';

  @override
  String get darkBerryRatio => 'கரும் கொட்டை விகிதம்';

  @override
  String get lightBerryRatio => 'வெளிர் கொட்டை விகிதம்';

  @override
  String get textureScore => 'அமைப்பு மதிப்பெண்';

  @override
  String get defectRatio => 'குறைபாடு விகிதம்';

  @override
  String get cleanlinessScore => 'சுத்தம் மதிப்பெண்';

  @override
  String get viewPriceForecast => 'விலை முன்னறிவிப்பைக் காண்க';

  @override
  String get qualityGrade => 'தரம்';

  @override
  String get visualEstimateDisclaimer =>
      'கேமரா அடிப்படையிலான காட்சி மதிப்பீடு மட்டுமே. இரசாயனத் தேவைகள் மற்றும் அடர்த்தி அளவிடப்படவில்லை.';

  @override
  String get priceForecast => 'விலை முன்னறிவிப்பு';

  @override
  String get predictedGradeShort => 'முன்னறிவிக்கப்பட்ட தரம்';

  @override
  String get useGradeForRecommendation =>
      'பரிந்துரைக்கு தரத்தைப் பயன்படுத்தவும் (விருப்பத்தேர்வு)';

  @override
  String get currentPrice => 'தற்போதைய விலை (ரூ./கி.கி.)';

  @override
  String get predictedPrice => 'முன்னறிவிக்கப்பட்ட விலை (ரூ./கி.கி.)';

  @override
  String get trend => 'போக்கு';

  @override
  String modelLabelPrefix(String model) {
    return 'மாதிரி: $model';
  }

  @override
  String get recommendation => 'பரிந்துரை';

  @override
  String decisionLabel(String value) {
    return 'முடிவு: $value';
  }

  @override
  String urgencyLabel(String value) {
    return 'அவசரம்: $value';
  }

  @override
  String get suggestedAction => 'பரிந்துரைக்கப்பட்ட நடவடிக்கை';

  @override
  String get whyThisRecommendation => 'ஏன் இந்தப் பரிந்துரை?';

  @override
  String get analyzeAnotherImage => 'மற்றொரு படத்தைப் பகுப்பாய்வு செய்யவும்';

  @override
  String get gradeSpecificNote =>
      'தரம் வாரியான சந்தை தரவு கிடைத்த பிறகு தரம் சார்ந்த முன்னறிவிப்பு மேம்படுத்தப்படும்.';

  @override
  String get couldNotUpdateRecShowingPrevious =>
      'பரிந்துரையைப் புதுப்பிக்க முடியவில்லை. முந்தைய பரிந்துரை காட்டப்படுகிறது.';

  @override
  String get couldNotUpdateRec =>
      'பரிந்துரையைப் புதுப்பிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get grade1 => 'தரம் 1';

  @override
  String get grade2 => 'தரம் 2';

  @override
  String get grade3 => 'தரம் 3';

  @override
  String get urgencyHigh => 'அதிகம்';

  @override
  String get urgencyMedium => 'நடுத்தரம்';

  @override
  String get urgencyLow => 'குறைவு';

  @override
  String get trendRising => 'உயர்கிறது';

  @override
  String get trendFalling => 'குறைகிறது';

  @override
  String get trendStable => 'நிலையானது';

  @override
  String get decisionWaitExport =>
      'காத்திருங்கள் / ஏற்றுமதி வாங்குபவரை இலக்காக்குங்கள்';

  @override
  String get decisionSellExport => 'விற்கவும் (ஏற்றுமதி)';

  @override
  String get decisionSellSoon => 'விரைவில் விற்கவும்';

  @override
  String get decisionWaitShortly => 'சிறிது நேரம் காத்திருங்கள்';

  @override
  String get decisionMonitor => 'கண்காணியுங்கள்';

  @override
  String get decisionSortProcess => 'வகைப்படுத்துங்கள் அல்லது பதப்படுத்துங்கள்';

  @override
  String get decisionProcessLocal => 'உள்நாட்டில் பதப்படுத்துங்கள்';

  @override
  String get decisionProcessOrSellNow =>
      'இப்போது பதப்படுத்துங்கள் அல்லது விற்கவும்';

  @override
  String get severity => 'தீவிரம்';

  @override
  String get high => 'அதிகம்';

  @override
  String get medium => 'நடுத்தரம்';

  @override
  String get whatWeSee => 'நாம் காண்பது';

  @override
  String get recommendedTreatment => 'பரிந்துரைக்கப்பட்ட சிகிச்சை';

  @override
  String get safeRemediation => 'பாதுகாப்பான தீர்வு';

  @override
  String get exportMarket => 'ஏற்றுமதி சந்தை';

  @override
  String get leafAnalysisTitle => 'இலை பகுப்பாய்வு';

  @override
  String get healthyLeaf => 'ஆரோக்கியமான இலை';

  @override
  String get leafRetryHint =>
      'நல்ல வெளிச்சத்தில் ஒரு இலையால் சட்டத்தை நிரப்பி மீண்டும் முயற்சிக்கவும்.';

  @override
  String get leafDisclaimer =>
      'ஒரு புகைப்படத்தில் இருந்து AI மதிப்பீடு. எந்த சிகிச்சையையும் செய்வதற்கு முன் உள்ளூர் வேளாண் நிபுணரிடம் உறுதிப்படுத்தவும்.';

  @override
  String get pestAnalysisTitle => 'பூச்சி பகுப்பாய்வு';

  @override
  String get noPestsFound => 'பூச்சிகள் எதுவும் இல்லை';

  @override
  String get aboveTreatmentThreshold => 'சிகிச்சை வரம்பிற்கு மேல்';

  @override
  String get pestRetryHint =>
      'நல்ல வெளிச்சத்தில் இலை/தண்டு/கொட்டையை நெருங்கி மீண்டும் முயற்சிக்கவும்.';

  @override
  String get pestDisclaimer =>
      'ஒரு புகைப்படத்தில் இருந்து AI மதிப்பீடு. தெளிப்பதற்கு முன் பூச்சி, பொருளாதார வரம்பு மற்றும் சரியான தயாரிப்பு மற்றும் அளவை உள்ளூர் வேளாண் நிபுணரிடம் உறுதிப்படுத்தவும்.';

  @override
  String get berryGradingTitle => 'கொட்டை தரப்படுத்தல்';

  @override
  String get exportCleanCluster => 'ஏற்றுமதிக்கு ஏற்ற சுத்தமான கொத்து';

  @override
  String get berryRetryHint =>
      'நல்ல வெளிச்சத்தில் கொட்டை கொத்தால் சட்டத்தை நிரப்பி மீண்டும் முயற்சிக்கவும்.';

  @override
  String get berryDisclaimer =>
      'ஒரு புகைப்படத்தில் இருந்து AI மதிப்பீடு. பயன்படுத்துவதற்கு முன் நோயறிதல், சரியான அளவு, MRL மற்றும் அறுவடைக்கு முந்தைய இடைவெளியை உள்ளூர் வேளாண் நிபுணரிடம் உறுதிப்படுத்தவும்.';

  @override
  String get low => 'குறைவு';

  @override
  String get analysingLeaf => 'AI மூலம் இலையைப் பகுப்பாய்வு செய்கிறது…';

  @override
  String get analysingBerry => 'AI மூலம் கொட்டைகளைத் தரப்படுத்துகிறது…';

  @override
  String get analysingPest => 'AI மூலம் பூச்சிகளைப் பரிசோதிக்கிறது…';

  @override
  String get notPepperLeaf => 'இது மிளகு இலையாகத் தெரியவில்லை';

  @override
  String get notBerryCluster => 'இது கொட்டை கொத்தாகத் தெரியவில்லை';

  @override
  String get notPepperPlant => 'இது மிளகு தாவரமாகத் தெரியவில்லை';

  @override
  String get recommendedActionIpm => 'பரிந்துரைக்கப்பட்ட நடவடிக்கை (IPM)';

  @override
  String get belowThreshold =>
      'சிகிச்சை வரம்பிற்குக் கீழ் — கண்காணிப்பு மட்டும்';

  @override
  String get clsHealthy => 'ஆரோக்கியம்';

  @override
  String get clsHealthyLeaves => 'ஆரோக்கியமான இலைகள்';

  @override
  String get clsHealthyBerry => 'ஆரோக்கியமான கொட்டை';

  @override
  String get clsLeafBlight => 'இலை கருகல்';

  @override
  String get clsLittleLeaf => 'சிறு இலை நோய்';

  @override
  String get clsQuickWilt => 'விரைவு வாடல்';

  @override
  String get clsLaceBugDamage => 'லேஸ் பூச்சி சேதம்';

  @override
  String get clsNutrientDeficiency => 'ஊட்டச்சத்து குறைபாடு';

  @override
  String get clsOtherDisease => 'மற்ற நோய்';

  @override
  String get clsOtherDamage => 'மற்ற சேதம்';

  @override
  String get clsUncertain => 'உறுதியற்றது';

  @override
  String get scanInstructionsTitle => 'எப்படி ஸ்கேன் செய்வது';

  @override
  String scanInstructionsStep1(String object) {
    return '$object மீது கேமராவைக் காட்டி ஷட்டர் பொத்தானைத் தட்டவும்.';
  }

  @override
  String get scanInstructionsStep2 =>
      'நல்ல வெளிச்சத்தில் நிலையாகப் பிடித்து, பொருளால் சட்டத்தை நிரப்பவும்.';

  @override
  String get scanInstructionsStep3 =>
      'நாங்கள் கண்டறிந்ததைச் சரிபார்த்து, சிகிச்சை ஆலோசனைக்கு “பரிந்துரைகளைக் காட்டு” என்பதைத் தட்டவும்.';

  @override
  String get scanInstructionsStart => 'புரிந்தது, ஸ்கேன் செய்யத் தொடங்கு';

  @override
  String get howToScan => 'எப்படி ஸ்கேன் செய்வது';
}
