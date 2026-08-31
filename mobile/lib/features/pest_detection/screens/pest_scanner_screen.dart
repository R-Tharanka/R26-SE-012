// Imports Flutter Material package for UI components

import 'package:flutter/material.dart';

// Imports the model configuration class used to configure the scanner model
import '../../../shared/models/scanner_model_config.dart';

// Imports the reusable scanner UI that performs the scanning process
import '../../../shared/widgets/scanner_view.dart';

// Configuration details for the pest detection YOLO model
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
