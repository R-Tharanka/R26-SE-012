import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pepper_care/shared/widgets/detection_overlay.dart';

void main() {
  group('OverlayTransform', () {
    test('contain shrinks to the tighter axis and letterboxes the other', () {
      // A 1000x500 frame into a 500x500 box: width is the binding axis.
      final t = OverlayTransform.forFit(
        imageSize: const Size(1000, 500),
        widgetSize: const Size(500, 500),
        fit: OverlayFit.contain,
      );

      expect(t.scale, closeTo(0.5, 1e-9));
      expect(t.dx, closeTo(0.0, 1e-9));
      expect(t.dy, closeTo(125.0, 1e-9)); // (500 - 250) / 2
    });

    test('cover fills the box and centre-crops the overflow', () {
      final t = OverlayTransform.forFit(
        imageSize: const Size(1000, 500),
        widgetSize: const Size(500, 500),
        fit: OverlayFit.cover,
      );

      expect(t.scale, closeTo(1.0, 1e-9));
      expect(t.dx, closeTo(-250.0, 1e-9)); // (500 - 1000) / 2, cropped
      expect(t.dy, closeTo(0.0, 1e-9));
    });

    test('matching aspect ratios need no offset either way', () {
      for (final fit in OverlayFit.values) {
        final t = OverlayTransform.forFit(
          imageSize: const Size(640, 640),
          widgetSize: const Size(320, 320),
          fit: fit,
        );
        expect(t.scale, closeTo(0.5, 1e-9));
        expect(t.dx, closeTo(0.0, 1e-9));
        expect(t.dy, closeTo(0.0, 1e-9));
      }
    });

    test('apply maps a normalized rect into widget space', () {
      const imageSize = Size(1000, 500);
      final t = OverlayTransform.forFit(
        imageSize: imageSize,
        widgetSize: const Size(500, 500),
        fit: OverlayFit.contain,
      );

      // Middle half of the frame on both axes.
      final rect = t.apply(const Rect.fromLTRB(0.25, 0.25, 0.75, 0.75), imageSize);

      expect(rect.left, closeTo(125.0, 1e-9)); // 0.25*1000*0.5 + 0
      expect(rect.right, closeTo(375.0, 1e-9)); // 0.75*1000*0.5 + 0
      expect(rect.top, closeTo(187.5, 1e-9)); // 0.25*500*0.5 + 125
      expect(rect.bottom, closeTo(312.5, 1e-9)); // 0.75*500*0.5 + 125
    });

    test('a full-frame box under contain covers exactly the drawn image', () {
      const imageSize = Size(1000, 500);
      const widgetSize = Size(500, 500);
      final t = OverlayTransform.forFit(
        imageSize: imageSize,
        widgetSize: widgetSize,
        fit: OverlayFit.contain,
      );

      final rect = t.apply(const Rect.fromLTRB(0, 0, 1, 1), imageSize);

      expect(rect.left, closeTo(0.0, 1e-9));
      expect(rect.right, closeTo(widgetSize.width, 1e-9));
      expect(rect.top, closeTo(125.0, 1e-9));
      expect(rect.bottom, closeTo(375.0, 1e-9));
    });
  });

  group('DetectionOverlay', () {
    test('repaints when detections, size, or fit change', () {
      const a = DetectionOverlay([], Size(640, 640));
      const sameFitDifferentSize = DetectionOverlay([], Size(320, 320));
      const differentFit =
          DetectionOverlay([], Size(640, 640), fit: OverlayFit.cover);

      expect(a.shouldRepaint(sameFitDifferentSize), isTrue);
      expect(a.shouldRepaint(differentFit), isTrue);
    });

    test('defaults to contain, the fit used for captured stills', () {
      const overlay = DetectionOverlay([], Size(640, 640));
      expect(overlay.fit, OverlayFit.contain);
    });
  });
}
