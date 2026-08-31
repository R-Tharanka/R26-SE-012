import 'package:flutter/material.dart';

import '../../../shared/models/scanner_model_config.dart';
import '../../../shared/widgets/scanner_view.dart';

/// Combined leaf-disease + pest scanner. The AI detector decides leaf-vs-pest
/// and the specific class from the merged vocabulary; recommendations then
/// route to the matching leaf or pest flow.
const _plantConfig = ScannerModelConfig(
  id: 'plant',
  label: 'Plant Health',
  assetPath: 'assets/models/new_leaf_yolo_model_int8.tflite',
  classNames: ['Healthy leaves', 'Leaf Blight', 'Little Leaf', 'Quick Wilt'],
  classColors: [
    Color(0xFF2ECC71),
    Color(0xFFE74C3C),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
  ],
);

class PlantHealthScannerScreen extends StatelessWidget {
  const PlantHealthScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScannerView(modelConfig: _plantConfig, title: 'Leaf & Pest');
  }
}
