// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sinhala Sinhalese (`si`).
class AppLocalizationsSi extends AppLocalizations {
  AppLocalizationsSi([String locale = 'si']) : super(locale);

  @override
  String get appTitle => 'Pepper Care';

  @override
  String get chooseLanguage => 'ඔබේ භාෂාව තෝරන්න';

  @override
  String get chooseLanguageSubtitle =>
      'ඔබට මෙය ඕනෑම විටෙක මෙනුවෙන් වෙනස් කළ හැක.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSinhala => 'සිංහල';

  @override
  String get languageTamil => 'தமிழ்';

  @override
  String get language => 'භාෂාව';

  @override
  String get homeLeafPest => 'කොළ සහ පළිබෝධ';

  @override
  String get homeBerryScan => 'ගම්මිරිස් ස්කෑන්';

  @override
  String get homeGradingForecast => 'ශ්‍රේණිගත කිරීම සහ පුරෝකථනය';

  @override
  String get homePests => 'පළිබෝධ';

  @override
  String get homeLeafHealth => 'කොළ සෞඛ්‍යය';

  @override
  String get homeBerryDisease => 'ගම්මිරිස් ගෙඩි රෝග';

  @override
  String get homeQualityPrice => 'ගුණාත්මකභාවය සහ\nමිල';

  @override
  String get lightMode => 'ආලෝක ප්‍රකාරය';

  @override
  String get darkMode => 'අඳුරු ප්‍රකාරය';

  @override
  String get berryLabel => 'ගම්මිරිස් ගෙඩිය';

  @override
  String get leafLabel => 'කොළය';

  @override
  String get pestLabel => 'පළිබෝධය';

  @override
  String get plantLabel => 'ශාක සෞඛ්‍යය';

  @override
  String get statusThinking => 'සිතමින්…';

  @override
  String get statusValidating => 'ඡායාරූපය පරීක්ෂා කරමින්…';

  @override
  String get statusInspecting => 'කොළ පරීක්ෂා කරමින්…';

  @override
  String get statusMatching => 'හඳුනාගත් රටා සමඟ ගළපමින්…';

  @override
  String get statusCloserLook => 'හ්ම්, මෙය සමීපව බැලිය යුතුයි…';

  @override
  String get statusAlmostThere => 'තවත් ටිකයි…';

  @override
  String get preparing => 'සූදානම් වෙමින්…';

  @override
  String scanHint(String label) {
    return '$label ස්කෑන් කරන්න — ෂටරය තට්ටු කරන්න හෝ ගැලරියෙන් තෝරන්න';
  }

  @override
  String get cameraUnavailable => 'කැමරාව නොමැත';

  @override
  String modelLoadFailed(String label) {
    return '\"$label\" ආකෘතිය පූරණය කළ නොහැකි විය';
  }

  @override
  String get otherScanTypesUnaffected => 'අනෙක් ස්කෑන් වර්ග වලට බලපෑමක් නැත.';

  @override
  String get couldNotReadImage =>
      'එම ඡායාරූපය කියවිය නොහැකි විය. වෙනත් ඡායාරූපයක් උත්සාහ කරන්න.';

  @override
  String get errSetup => 'ස්කෑනරය නිවැරදිව සකසා නැත. කරුණාකර සහාය අමතන්න.';

  @override
  String get errOffline =>
      'අන්තර්ජාල සම්බන්ධතාවක් නැත. ඔබේ ජාලය පරීක්ෂා කර නැවත උත්සාහ කරන්න.';

  @override
  String get errBusy =>
      'ස්කෑනරය දැන් කාර්යබහුලයි. මොහොතකින් නැවත උත්සාහ කරන්න.';

  @override
  String get errGeneric => 'යම් දෝෂයක් ඇති විය. නැවත උත්සාහ කරන්න.';

  @override
  String get nothingDetected => 'කිසිවක් හමු නොවීය';

  @override
  String findingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'සොයාගැනීම් $countක්',
      one: 'සොයාගැනීම් 1ක්',
    );
    return '$_temp0';
  }

  @override
  String get noMatchesHint =>
      'විශ්වාසනීය මට්ටමට ගැලපීම් නැත. ළඟට ගොස්, ඡායාරූපය ස්ථාවරව තබා, හෝ ආලෝකය වැඩි කර නැවත උත්සාහ කරන්න.';

  @override
  String get lowConfidenceNotice =>
      'අඩු විශ්වාසනීයත්වය. සුපුරුදු මට්ටමට කිසිවක් නොපැමිණි නිසා දුර්වල ගැලපීම් පෙන්වයි — මේවා රෝග විනිශ්චයක් ලෙස නොව ඉඟියක් ලෙස සලකන්න, හැකි නම් හොඳ ආලෝකයක නැවත ඡායාරූප ගන්න.';

  @override
  String get showRecommendations => 'නිර්දේශ පෙන්වන්න';

  @override
  String get takeAnotherPhoto => 'තවත් ඡායාරූපයක් ගන්න';

  @override
  String get looksHealthy => 'නිරෝගී බව පෙනේ — ප්‍රතිකාර අවශ්‍ය නැත.';

  @override
  String get camera => 'කැමරාව';

  @override
  String get gallery => 'ගැලරිය';

  @override
  String get retry => 'නැවත උත්සාහ කරන්න';

  @override
  String get tryAgain => 'නැවත උත්සාහ කරන්න';

  @override
  String get retakePhoto => 'ඡායාරූපය නැවත ගන්න';

  @override
  String get analyze => 'විශ්ලේෂණය කරන්න';

  @override
  String get gradingHomeTitle =>
      'ගම්මිරිස් ශ්‍රේණිගත කිරීම සහ අපනයන මිල පුරෝකථනය';

  @override
  String get gradingHomeSubtitle =>
      'ගම්මිරිස් ගෙඩියක ඡායාරූපයක් ගෙන ගුණත්වය ඇස්තමේන්තු කර සරල මිල පුරෝකථනයක් ලබාගන්න.';

  @override
  String get checkBerryQuality => 'ගෙඩියේ ගුණත්වය පරීක්ෂා කරන්න';

  @override
  String get captureBerryTitle => 'ගම්මිරිස් ගෙඩියේ ඡායාරූපය ගන්න';

  @override
  String get noImageSelected => 'තවම ඡායාරූපයක් තෝරා නැත.';

  @override
  String get captureTip =>
      'ඉඟිය: පැහැදිලි, හොඳින් ආලෝකමත් ඡායාරූපයක් භාවිතා කර බොඳ වීම වළක්වන්න.';

  @override
  String get couldNotOpenCameraGallery =>
      'කැමරාව/ගැලරිය විවෘත කළ නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get processing => 'සකසමින්';

  @override
  String get analyzingBerryQuality => 'ගෙඩියේ ගුණත්වය විශ්ලේෂණය කරමින්...';

  @override
  String get analyzeFailed =>
      'ඡායාරූපය විශ්ලේෂණය කිරීමට අසමත් විය. නැවත උත්සාහ කරන්න.';

  @override
  String get backendError => 'සේවාදායක දෝෂයකි. නැවත උත්සාහ කරන්න.';

  @override
  String get berryQualityResult => 'ගෙඩියේ ගුණත්ව ප්‍රතිඵලය';

  @override
  String get predictedGrade => 'පුරෝකථිත ශ්‍රේණිය';

  @override
  String get confidence => 'විශ්වාසනීයත්වය';

  @override
  String get qualityScore => 'ගුණත්ව ලකුණ';

  @override
  String get explanation => 'විස්තරය';

  @override
  String get noExplanation => 'අමතර විස්තරයක් නොමැත.';

  @override
  String get visualFactors => 'දෘශ්‍ය සාධක හඳුනාගන්නා ලදී';

  @override
  String get colorUniformity => 'වර්ණ ඒකාකාරිත්වය';

  @override
  String get darkBerryRatio => 'අඳුරු ගෙඩි අනුපාතය';

  @override
  String get lightBerryRatio => 'ළා ගෙඩි අනුපාතය';

  @override
  String get textureScore => 'වයනය ලකුණ';

  @override
  String get defectRatio => 'දෝෂ අනුපාතය';

  @override
  String get cleanlinessScore => 'පිරිසිදුකම ලකුණ';

  @override
  String get viewPriceForecast => 'මිල පුරෝකථනය බලන්න';

  @override
  String get qualityGrade => 'ගුණත්ව ශ්‍රේණිය';

  @override
  String get visualEstimateDisclaimer =>
      'කැමරාව පදනම් කරගත් දෘශ්‍ය ඇස්තමේන්තුවක් පමණි. රසායනික අවශ්‍යතා සහ ස්කන්ධ ඝනත්වය මනිනු නොලැබේ.';

  @override
  String get priceForecast => 'මිල පුරෝකථනය';

  @override
  String get predictedGradeShort => 'පුරෝකථිත ශ්‍රේණිය';

  @override
  String get useGradeForRecommendation =>
      'නිර්දේශය සඳහා ශ්‍රේණිය භාවිතා කරන්න (විකල්ප)';

  @override
  String get currentPrice => 'වත්මන් මිල (රු./කි.ග්‍රෑ.)';

  @override
  String get predictedPrice => 'පුරෝකථිත මිල (රු./කි.ග්‍රෑ.)';

  @override
  String get trend => 'ප්‍රවණතාව';

  @override
  String modelLabelPrefix(String model) {
    return 'ආකෘතිය: $model';
  }

  @override
  String get recommendation => 'නිර්දේශය';

  @override
  String decisionLabel(String value) {
    return 'තීරණය: $value';
  }

  @override
  String urgencyLabel(String value) {
    return 'හදිසිතාව: $value';
  }

  @override
  String get suggestedAction => 'යෝජිත ක්‍රියාව';

  @override
  String get whyThisRecommendation => 'මෙම නිර්දේශයට හේතුව?';

  @override
  String get analyzeAnotherImage => 'තවත් ඡායාරූපයක් විශ්ලේෂණය කරන්න';

  @override
  String get gradeSpecificNote =>
      'ශ්‍රේණි අනුව වෙළඳපොළ දත්ත ලැබුණු පසු ශ්‍රේණි-විශේෂිත පුරෝකථනය වැඩිදියුණු කෙරේ.';

  @override
  String get couldNotUpdateRecShowingPrevious =>
      'නිර්දේශය යාවත්කාලීන කළ නොහැකි විය. පෙර නිර්දේශය පෙන්වයි.';

  @override
  String get couldNotUpdateRec =>
      'නිර්දේශය යාවත්කාලීන කළ නොහැකි විය. නැවත උත්සාහ කරන්න.';

  @override
  String get grade1 => 'ශ්‍රේණිය 1';

  @override
  String get grade2 => 'ශ්‍රේණිය 2';

  @override
  String get grade3 => 'ශ්‍රේණිය 3';

  @override
  String get urgencyHigh => 'ඉහළ';

  @override
  String get urgencyMedium => 'මධ්‍යම';

  @override
  String get urgencyLow => 'අඩු';

  @override
  String get trendRising => 'ඉහළ යමින්';

  @override
  String get trendFalling => 'පහළ යමින්';

  @override
  String get trendStable => 'ස්ථාවර';

  @override
  String get decisionWaitExport =>
      'රැඳී සිටින්න / අපනයන ගැනුම්කරුවෙකු ඉලක්ක කරන්න';

  @override
  String get decisionSellExport => 'විකුණන්න (අපනයන)';

  @override
  String get decisionSellSoon => 'ඉක්මනින් විකුණන්න';

  @override
  String get decisionWaitShortly => 'ටික වේලාවක් රැඳී සිටින්න';

  @override
  String get decisionMonitor => 'නිරීක්ෂණය කරන්න';

  @override
  String get decisionSortProcess => 'වර්ග කරන්න හෝ සකසන්න';

  @override
  String get decisionProcessLocal => 'දේශීයව සකසන්න';

  @override
  String get decisionProcessOrSellNow => 'දැන් සකසන්න හෝ විකුණන්න';

  @override
  String get severity => 'තීව්‍රතාව';

  @override
  String get high => 'ඉහළ';

  @override
  String get medium => 'මධ්‍යම';

  @override
  String get whatWeSee => 'අප දකින දේ';

  @override
  String get recommendedTreatment => 'නිර්දේශිත ප්‍රතිකාරය';

  @override
  String get safeRemediation => 'ආරක්ෂිත පිළියම';

  @override
  String get exportMarket => 'අපනයන වෙළඳපොළ';

  @override
  String get leafAnalysisTitle => 'කොළ විශ්ලේෂණය';

  @override
  String get healthyLeaf => 'නිරෝගී කොළය';

  @override
  String get leafRetryHint =>
      'හොඳ ආලෝකයක තනි කොළයකින් රාමුව පුරවා නැවත උත්සාහ කරන්න.';

  @override
  String get leafDisclaimer =>
      'එක් ඡායාරූපයකින් AI ඇස්තමේන්තුවකි. ඕනෑම ප්‍රතිකාරයක් යෙදීමට පෙර දේශීය කෘෂිවිද්‍යාඥයෙකුගෙන් තහවුරු කරගන්න.';

  @override
  String get pestAnalysisTitle => 'පළිබෝධ විශ්ලේෂණය';

  @override
  String get noPestsFound => 'පළිබෝධ හමු නොවීය';

  @override
  String get aboveTreatmentThreshold => 'ප්‍රතිකාර සීමාවට වඩා ඉහළ';

  @override
  String get pestRetryHint =>
      'හොඳ ආලෝකයක කොළ/කඳ/ගෙඩිය වෙත ළඟා වී නැවත උත්සාහ කරන්න.';

  @override
  String get pestDisclaimer =>
      'එක් ඡායාරූපයකින් AI ඇස්තමේන්තුවකි. ඉසීමට පෙර පළිබෝධය, ආර්ථික සීමාව සහ නිවැරදි නිෂ්පාදනය හා මාත්‍රාව දේශීය කෘෂිවිද්‍යාඥයෙකුගෙන් තහවුරු කරගන්න.';

  @override
  String get berryGradingTitle => 'ගෙඩි ශ්‍රේණිගත කිරීම';

  @override
  String get exportCleanCluster => 'අපනයනයට සුදුසු පිරිසිදු පොකුර';

  @override
  String get berryRetryHint =>
      'හොඳ ආලෝකයක ගෙඩි පොකුරකින් රාමුව පුරවා නැවත උත්සාහ කරන්න.';

  @override
  String get berryDisclaimer =>
      'එක් ඡායාරූපයකින් AI ඇස්තමේන්තුවකි. යෙදීමට පෙර රෝග විනිශ්චය, නිවැරදි මාත්‍රාව, MRL සහ අස්වනු නෙළීමට පෙර කාලය දේශීය කෘෂිවිද්‍යාඥයෙකුගෙන් තහවුරු කරගන්න.';

  @override
  String get low => 'අඩු';

  @override
  String get analysingLeaf => 'AI සමඟ කොළය විශ්ලේෂණය කරමින්…';

  @override
  String get analysingBerry => 'AI සමඟ ගෙඩි ශ්‍රේණිගත කරමින්…';

  @override
  String get analysingPest => 'AI සමඟ පළිබෝධ සඳහා පරීක්ෂා කරමින්…';

  @override
  String get notPepperLeaf => 'මෙය ගම්මිරිස් කොළයක් ලෙස නොපෙනේ';

  @override
  String get notBerryCluster => 'මෙය ගෙඩි පොකුරක් ලෙස නොපෙනේ';

  @override
  String get notPepperPlant => 'මෙය ගම්මිරිස් ශාකයක් ලෙස නොපෙනේ';

  @override
  String get recommendedActionIpm => 'නිර්දේශිත ක්‍රියාව (IPM)';

  @override
  String get belowThreshold => 'ප්‍රතිකාර සීමාවට පහළ — නිරීක්ෂණය පමණි';

  @override
  String get clsHealthy => 'නිරෝගී';

  @override
  String get clsHealthyLeaves => 'නිරෝගී කොළ';

  @override
  String get clsHealthyBerry => 'නිරෝගී ගෙඩිය';

  @override
  String get clsLeafBlight => 'කොළ අංගමාරය';

  @override
  String get clsLittleLeaf => 'කුඩා කොළ රෝගය';

  @override
  String get clsQuickWilt => 'ක්ෂණික මැලවීම';

  @override
  String get clsLaceBugDamage => 'ලේස් මකුණු හානිය';

  @override
  String get clsNutrientDeficiency => 'පෝෂක ඌනතාව';

  @override
  String get clsOtherDisease => 'වෙනත් රෝගයක්';

  @override
  String get clsOtherDamage => 'වෙනත් හානියක්';

  @override
  String get clsUncertain => 'අවිනිශ්චිතයි';

  @override
  String get scanInstructionsTitle => 'ස්කෑන් කරන ආකාරය';

  @override
  String scanInstructionsStep1(String object) {
    return '$object වෙත කැමරාව යොමු කර ෂටර බොත්තම තට්ටු කරන්න.';
  }

  @override
  String get scanInstructionsStep2 =>
      'හොඳ ආලෝකයක ස්ථිරව අල්ලාගෙන රාමුව විෂයයෙන් පුරවන්න.';

  @override
  String get scanInstructionsStep3 =>
      'අප සොයාගත් දේ පරීක්ෂා කර, ප්‍රතිකාර උපදෙස් බැලීමට “නිර්දේශ පෙන්වන්න” තට්ටු කරන්න.';

  @override
  String get scanInstructionsStart => 'තේරුණා, ස්කෑන් කිරීම අරඹන්න';

  @override
  String get howToScan => 'ස්කෑන් කරන ආකාරය';
}
