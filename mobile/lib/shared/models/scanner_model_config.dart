// =============================================================================
// File: scanner_model_config.dart
// Purpose: Defines the scanner model config data model.
// =============================================================================
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

  // Return the number of model classes.
  int get numClasses => classNames.length;

  // Return the number of model output channels.
  int get outputChannels => numClasses + 4;

  Color colorFor(int classId) {
    // Return the display color assigned to this class identifier.
    if (classColors.isEmpty) {
      return const Color(0xFF2D6A4F);
    }
    return classColors[classId % classColors.length];
  }
}
