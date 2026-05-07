import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'processing_screen.dart';

class BerryCaptureScreen extends StatefulWidget {
  const BerryCaptureScreen({super.key});

  @override
  State<BerryCaptureScreen> createState() => _BerryCaptureScreenState();
}

class _BerryCaptureScreenState extends State<BerryCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selected;

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
      );
      if (!mounted) return;
      setState(() => _selected = picked);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open camera/gallery. Please try again.')),
      );
    }
  }

  void _analyze() {
    final selected = _selected;
    if (selected == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProcessingScreen(imageFile: File(selected.path)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _selected?.path;
    final canAnalyze = imagePath != null && imagePath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Pepper Berry Image'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: imagePath == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_outlined, size: 48),
                              SizedBox(height: 8),
                              Text('No image selected yet.'),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: canAnalyze ? _analyze : null,
              child: const Text('Analyze'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: use a clear, well-lit photo and avoid blur.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

