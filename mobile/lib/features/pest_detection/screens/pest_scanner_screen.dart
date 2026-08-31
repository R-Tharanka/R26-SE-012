import 'package:flutter/material.dart';

import '../../../shared/models/scanner_model_config.dart';
import '../../../shared/widgets/scanner_view.dart';

const _pestConfig = ScannerModelConfig(
  id: 'pest',
  label: 'Pest',
  assetPath: 'assets/models/new_pest_yolo_model_int8.tflite',
  classNames: [
    'Diconocoris distanti',
    'Gynaikothrips karny',
    'Pterolopha annulata',
    'healthy',
  ],
  classColors: [
    Color(0xFFE74C3C),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
    Color(0xFF2ECC71),
  ],
);

class PestScannerScreen extends StatelessWidget {
  const PestScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScannerView(
      modelConfig: _pestConfig,
      title: 'Pest Scan',
    );
  }
}
