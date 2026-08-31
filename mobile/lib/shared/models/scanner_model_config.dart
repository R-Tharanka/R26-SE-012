import 'dart:ui';

class ScannerModelConfig {
  final String id;
  final String label;
  final String assetPath;
  final List<String> classNames;
  final List<Color> classColors;

  const ScannerModelConfig({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.classNames,
    required this.classColors,
  });

  int get numClasses => classNames.length;

  int get outputChannels => numClasses + 4;

  Color colorFor(int classId) {
    if (classColors.isEmpty) {
      return const Color(0xFF2D6A4F);
    }
    return classColors[classId % classColors.length];
  }
}
