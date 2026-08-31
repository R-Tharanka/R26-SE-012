import 'package:flutter/material.dart';

import '../../../shared/models/scanner_model_config.dart';
import '../../../shared/widgets/scanner_view.dart';

const _leafConfig = ScannerModelConfig(
  id: 'leaf',
  label: 'Leaf',
  assetPath: 'assets/models/new_leaf_yolo_model_int8.tflite',
  classNames: ['Healthy leaves', 'Leaf Blight', 'Little Leaf', 'Quick Wilt'],
  classColors: [
    Color(0xFF2ECC71),
    Color(0xFFE74C3C),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
  ],
);

class LeafScannerScreen extends StatelessWidget {
  const LeafScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScannerView(
      modelConfig: _leafConfig,
      title: 'Leaf Scan',
    );
  }
}
