import 'dart:typed_data';

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
  Uint8List? _selectedBytes;

  Future<void> _pick(ImageSource source) async {
    try {
      // Preserve the selected bytes for the frozen Phase 7 backend pipeline.
      // Resizing or JPEG recompression here changes the blur, detection, and
      // class-margin inputs used by the frozen rejection/uncertainty gates.
      final picked = await _picker.pickImage(source: source);
      if (!mounted) return;
      if (picked == null) {
        setState(() {
          _selected = null;
          _selectedBytes = null;
        });
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        _showSelectionError('The selected image is empty. Choose another image.');
        return;
      }
      if (bytes.length > 10 * 1024 * 1024) {
        _showSelectionError('The selected image exceeds the 10 MB upload limit.');
        return;
      }
      setState(() {
        _selected = picked;
        _selectedBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open camera/gallery. Please try again.')),
      );
    }
  }

  void _showSelectionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _analyze() {
    final selected = _selected;
    final bytes = _selectedBytes;
    if (selected == null) return;
    if (bytes == null || bytes.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProcessingScreen(imageBytes: bytes, imageName: selected.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _selectedBytes;
    final canAnalyze = imageBytes != null && imageBytes.isNotEmpty;

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
                  child: imageBytes == null
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
                          child: Image.memory(
                            imageBytes,
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
