import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pepper_care/core/services/yolo_detector.dart';
import 'package:pepper_care/shared/models/detection.dart';
import 'package:pepper_care/shared/models/scanner_model_config.dart';

const _twoClassConfig = ScannerModelConfig(
  id: 'test',
  label: 'Test',
  assetPath: 'test.tflite',
  classNames: ['a', 'b'],
  classColors: [Color(0xFF000000), Color(0xFFFFFFFF)],
);

/// Allocates a zeroed output buffer shaped like the model's
/// `[1, 4 + numClasses, 8400]`, flattened row-wise.
Float32List emptyOutput(ScannerModelConfig cfg) =>
    Float32List(cfg.outputChannels * YoloDetector.numAnchors);

/// Writes one anchor into [out]. Box values are normalized 0..1 against the
/// letterboxed input, matching what the model emits.
void writeAnchor(
  Float32List out,
  int anchor, {
  required double cx,
  required double cy,
  required double w,
  required double h,
  required List<double> scores,
}) {
  const n = YoloDetector.numAnchors;
  out[0 * n + anchor] = cx;
  out[1 * n + anchor] = cy;
  out[2 * n + anchor] = w;
  out[3 * n + anchor] = h;
  for (int c = 0; c < scores.length; c++) {
    out[(4 + c) * n + anchor] = scores[c];
  }
}

List<Detection> makeDets(List<(int, double, Rect)> specs) {
  return specs
      .map((s) => Detection(
            classId: s.$1,
            className: 'c${s.$1}',
            score: s.$2,
            rect: s.$3,
            color: const Color(0xFF000000),
          ))
      .toList();
}

void main() {
  group('ScannerModelConfig invariants', () {
    test('outputChannels == numClasses + 4', () {
      const cfg = ScannerModelConfig(
        id: 'test',
        label: 'Test',
        assetPath: 'test.tflite',
        classNames: ['a', 'b', 'c'],
        classColors: [
          Color(0xFF000000),
          Color(0xFF111111),
          Color(0xFF222222),
        ],
      );
      expect(cfg.numClasses, 3);
      expect(cfg.outputChannels, 7);
    });

    test('colorFor wraps around for out-of-range classId', () {
      expect(_twoClassConfig.colorFor(2), const Color(0xFF000000));
      expect(_twoClassConfig.colorFor(3), const Color(0xFFFFFFFF));
    });

    test('shipped configs have enough colors for every class', () {
      const cfgs = [
        ScannerModelConfig(
          id: 'berry',
          label: 'Berry',
          assetPath: 'assets/models/new_berry_yolo_model_int8.tflite',
          classNames: ['healthy_berry', 'lace_bug_damage'],
          classColors: [Color(0xFF2ECC71), Color(0xFFE67E22)],
        ),
        ScannerModelConfig(
          id: 'leaf',
          label: 'Leaf',
          assetPath: 'assets/models/new_leaf_yolo_model_int8.tflite',
          classNames: [
            'Healthy leaves',
            'Leaf Blight',
            'Little Leaf',
            'Quick Wilt',
          ],
          classColors: [
            Color(0xFF2ECC71),
            Color(0xFFE74C3C),
            Color(0xFFE67E22),
            Color(0xFF9B59B6),
          ],
        ),
        ScannerModelConfig(
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
        ),
      ];
      for (final cfg in cfgs) {
        expect(cfg.classColors.length, greaterThanOrEqualTo(cfg.numClasses));
      }
    });
  });

  group('LetterboxGeometry', () {
    test('square frame needs no scaling or padding', () {
      final box = LetterboxGeometry.forFrame(
        frameWidth: 640,
        frameHeight: 640,
        inputSize: 640,
      );
      expect(box.scale, closeTo(1.0, 1e-9));
      expect(box.scaledWidth, 640);
      expect(box.scaledHeight, 640);
      expect(box.padX, 0);
      expect(box.padY, 0);
    });

    test('landscape frame pads top and bottom', () {
      final box = LetterboxGeometry.forFrame(
        frameWidth: 1280,
        frameHeight: 640,
        inputSize: 640,
      );
      expect(box.scale, closeTo(0.5, 1e-9));
      expect(box.scaledWidth, 640);
      expect(box.scaledHeight, 320);
      expect(box.padX, 0);
      expect(box.padY, 160);
    });

    test('portrait frame pads left and right', () {
      final box = LetterboxGeometry.forFrame(
        frameWidth: 640,
        frameHeight: 1280,
        inputSize: 640,
      );
      expect(box.scale, closeTo(0.5, 1e-9));
      expect(box.scaledWidth, 320);
      expect(box.scaledHeight, 640);
      expect(box.padX, 160);
      expect(box.padY, 0);
    });

    test('scaled frame never exceeds the input on either axis', () {
      for (final dims in const [
        (1920, 1080),
        (1080, 1920),
        (999, 1000),
        (37, 640),
        (640, 37),
      ]) {
        final box = LetterboxGeometry.forFrame(
          frameWidth: dims.$1,
          frameHeight: dims.$2,
          inputSize: 640,
        );
        expect(box.scaledWidth, lessThanOrEqualTo(640));
        expect(box.scaledHeight, lessThanOrEqualTo(640));
        expect(box.padX, greaterThanOrEqualTo(0));
        expect(box.padY, greaterThanOrEqualTo(0));
      }
    });

    test('an odd leftover pixel is absorbed by the right/bottom edge', () {
      // 641x640 -> scaledHeight rounds down to 639, leaving 1px unaccounted.
      final box = LetterboxGeometry.forFrame(
        frameWidth: 641,
        frameHeight: 640,
        inputSize: 640,
      );
      expect(box.scaledWidth, 640);
      expect(box.scaledHeight, 639);
      expect(box.padY, 0); // (640 - 639) ~/ 2 == 0
    });

    test('round-trips a frame-space box through letterbox and back', () {
      final box = LetterboxGeometry.forFrame(
        frameWidth: 1280,
        frameHeight: 640,
        inputSize: 640,
      );

      // Forward: frame pixels -> letterboxed input pixels.
      const frameLeft = 320.0;
      const frameTop = 100.0;
      final inputLeft = frameLeft * box.scale + box.padX;
      final inputTop = frameTop * box.scale + box.padY;

      // Reverse: exactly what decode() does to undo the letterbox.
      final backLeft = (inputLeft - box.padX) / box.scale;
      final backTop = (inputTop - box.padY) / box.scale;

      expect(backLeft, closeTo(frameLeft, 1e-9));
      expect(backTop, closeTo(frameTop, 1e-9));
    });
  });

  group('decode', () {
    late YoloDetector detector;
    setUp(() {
      detector = YoloDetector(confThreshold: 0.5, iouThreshold: 0.45);
    });

    LetterboxGeometry boxFor(int w, int h) => LetterboxGeometry.forFrame(
          frameWidth: w,
          frameHeight: h,
          inputSize: 640,
        );

    test('maps a centered box on an unpadded square frame', () {
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 0.5, h: 0.5, scores: [0.1, 0.9]);

      final dets =
          detector.decode(out, _twoClassConfig, 640, 640, boxFor(640, 640));

      expect(dets, hasLength(1));
      final d = dets.single;
      expect(d.classId, 1);
      expect(d.className, 'b');
      expect(d.score, closeTo(0.9, 1e-6));
      expect(d.rect.left, closeTo(0.25, 1e-6));
      expect(d.rect.top, closeTo(0.25, 1e-6));
      expect(d.rect.right, closeTo(0.75, 1e-6));
      expect(d.rect.bottom, closeTo(0.75, 1e-6));
    });

    test('undoes vertical padding on a letterboxed landscape frame', () {
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 0.5, h: 0.5, scores: [0.9, 0.1]);

      // 1280x640 -> scale 0.5, padY 160. The box spans the full frame height.
      final dets =
          detector.decode(out, _twoClassConfig, 1280, 640, boxFor(1280, 640));

      expect(dets, hasLength(1));
      final d = dets.single;
      expect(d.classId, 0);
      expect(d.rect.left, closeTo(0.25, 1e-6));
      expect(d.rect.top, closeTo(0.0, 1e-6));
      expect(d.rect.right, closeTo(0.75, 1e-6));
      expect(d.rect.bottom, closeTo(1.0, 1e-6));
    });

    test('drops anchors below the confidence threshold', () {
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 0.2, h: 0.2, scores: [0.49, 0.10]);

      expect(
        detector.decode(out, _twoClassConfig, 640, 640, boxFor(640, 640)),
        isEmpty,
      );
    });

    test('picks the argmax class when several score above threshold', () {
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 0.2, h: 0.2, scores: [0.60, 0.95]);

      final dets =
          detector.decode(out, _twoClassConfig, 640, 640, boxFor(640, 640));

      expect(dets, hasLength(1));
      expect(dets.single.classId, 1);
      expect(dets.single.score, closeTo(0.95, 1e-6));
    });

    test('clamps boxes that run past the frame edges', () {
      final out = emptyOutput(_twoClassConfig);
      // Centered but twice the input size: corners fall well outside.
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 2.0, h: 2.0, scores: [0.9, 0.1]);

      final d = detector
          .decode(out, _twoClassConfig, 640, 640, boxFor(640, 640))
          .single;

      expect(d.rect.left, 0.0);
      expect(d.rect.top, 0.0);
      expect(d.rect.right, 1.0);
      expect(d.rect.bottom, 1.0);
    });

    test('an all-zero output yields no detections', () {
      final out = emptyOutput(_twoClassConfig);
      expect(
        detector.decode(out, _twoClassConfig, 640, 640, boxFor(640, 640)),
        isEmpty,
      );
    });

    test('suppresses duplicate boxes on the same object via NMS', () {
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.50, cy: 0.50, w: 0.40, h: 0.40, scores: [0.9, 0.1]);
      writeAnchor(out, 1,
          cx: 0.51, cy: 0.51, w: 0.40, h: 0.40, scores: [0.7, 0.1]);

      final dets =
          detector.decode(out, _twoClassConfig, 640, 640, boxFor(640, 640));

      expect(dets, hasLength(1));
      expect(dets.single.score, closeTo(0.9, 1e-6));
    });
  });

  group('decodeWithFallback', () {
    late YoloDetector detector;
    setUp(() {
      detector = YoloDetector(
        confThreshold: 0.5,
        iouThreshold: 0.45,
        fallbackConfThreshold: 0.2,
      );
    });

    LetterboxGeometry boxFor(int w, int h) => LetterboxGeometry.forFrame(
          frameWidth: w,
          frameHeight: h,
          inputSize: 640,
        );

    test('uses the strict threshold when something clears it', () {
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 0.2, h: 0.2, scores: [0.80, 0.10]);

      final outcome = detector.decodeWithFallback(
          out, _twoClassConfig, 640, 640, boxFor(640, 640));

      expect(outcome.detections, hasLength(1));
      expect(outcome.usedFallback, isFalse);
      expect(outcome.threshold, 0.5);
    });

    test('retries at the relaxed threshold when the strict pass is empty', () {
      final out = emptyOutput(_twoClassConfig);
      // 0.35 misses 0.5 but clears 0.2.
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 0.2, h: 0.2, scores: [0.35, 0.10]);

      final outcome = detector.decodeWithFallback(
          out, _twoClassConfig, 640, 640, boxFor(640, 640));

      expect(outcome.detections, hasLength(1));
      expect(outcome.detections.single.score, closeTo(0.35, 1e-6));
      expect(outcome.usedFallback, isTrue);
      expect(outcome.threshold, 0.2);
    });

    test('does not flag low confidence when even the retry finds nothing', () {
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 0.2, h: 0.2, scores: [0.05, 0.01]);

      final outcome = detector.decodeWithFallback(
          out, _twoClassConfig, 640, 640, boxFor(640, 640));

      expect(outcome.detections, isEmpty);
      expect(outcome.usedFallback, isFalse);
      expect(outcome.threshold, 0.5);
    });

    test('a strong detection suppresses the retry entirely', () {
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.20, cy: 0.20, w: 0.10, h: 0.10, scores: [0.90, 0.01]);
      // A weak, well-separated box that only the relaxed pass would pick up.
      writeAnchor(out, 1,
          cx: 0.80, cy: 0.80, w: 0.10, h: 0.10, scores: [0.30, 0.01]);

      final outcome = detector.decodeWithFallback(
          out, _twoClassConfig, 640, 640, boxFor(640, 640));

      expect(outcome.detections, hasLength(1));
      expect(outcome.detections.single.score, closeTo(0.90, 1e-6));
      expect(outcome.usedFallback, isFalse);
    });

    test('fallback is disabled when set at or above the strict threshold', () {
      final lenient = YoloDetector(
        confThreshold: 0.5,
        fallbackConfThreshold: 0.5,
      );
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 0.2, h: 0.2, scores: [0.35, 0.10]);

      final outcome = lenient.decodeWithFallback(
          out, _twoClassConfig, 640, 640, boxFor(640, 640));

      expect(outcome.detections, isEmpty);
      expect(outcome.usedFallback, isFalse);
    });

    test('decode honours an explicit threshold override', () {
      final out = emptyOutput(_twoClassConfig);
      writeAnchor(out, 0,
          cx: 0.5, cy: 0.5, w: 0.2, h: 0.2, scores: [0.35, 0.10]);

      final box = boxFor(640, 640);
      expect(detector.decode(out, _twoClassConfig, 640, 640, box), isEmpty);
      expect(
        detector.decode(out, _twoClassConfig, 640, 640, box, threshold: 0.2),
        hasLength(1),
      );
    });
  });

  group('IoU', () {
    late YoloDetector detector;
    setUp(() {
      detector = YoloDetector();
    });

    test('identical rects have IoU = 1.0', () {
      const rect = Rect.fromLTRB(0.1, 0.1, 0.5, 0.5);
      expect(detector.iou(rect, rect), closeTo(1.0, 1e-6));
    });

    test('non-overlapping rects have IoU = 0.0', () {
      const a = Rect.fromLTRB(0.0, 0.0, 0.1, 0.1);
      const b = Rect.fromLTRB(0.5, 0.5, 0.6, 0.6);
      expect(detector.iou(a, b), closeTo(0.0, 1e-6));
    });

    test('partial overlap', () {
      const a = Rect.fromLTRB(0.0, 0.0, 0.4, 0.4);
      const b = Rect.fromLTRB(0.2, 0.2, 0.6, 0.6);
      // inter 0.04, union 0.28
      expect(detector.iou(a, b), closeTo(0.142857, 1e-4));
    });

    test('degenerate (zero-area) rects return 0 rather than NaN', () {
      const a = Rect.fromLTRB(0.2, 0.2, 0.2, 0.2);
      expect(detector.iou(a, a), 0);
    });
  });

  group('NMS', () {
    late YoloDetector detector;
    setUp(() {
      detector = YoloDetector();
    });

    test('keeps best when two boxes overlap heavily', () {
      final dets = makeDets([
        (0, 0.9, const Rect.fromLTRB(0.10, 0.10, 0.50, 0.50)),
        (0, 0.6, const Rect.fromLTRB(0.15, 0.15, 0.55, 0.55)),
      ]);
      final result = detector.nms(dets, 0.5);
      expect(result, hasLength(1));
      expect(result.single.score, 0.9);
    });

    test('keeps both when boxes do not overlap', () {
      final dets = makeDets([
        (0, 0.9, const Rect.fromLTRB(0.0, 0.0, 0.1, 0.1)),
        (1, 0.8, const Rect.fromLTRB(0.5, 0.5, 0.6, 0.6)),
      ]);
      expect(detector.nms(dets, 0.5), hasLength(2));
    });

    test('orders by score descending', () {
      final dets = makeDets([
        (0, 0.5, const Rect.fromLTRB(0.0, 0.0, 0.1, 0.1)),
        (1, 0.9, const Rect.fromLTRB(0.2, 0.2, 0.3, 0.3)),
        (2, 0.7, const Rect.fromLTRB(0.4, 0.4, 0.5, 0.5)),
      ]);
      final result = detector.nms(dets, 0.5);
      expect(result.map((d) => d.score).toList(), [0.9, 0.7, 0.5]);
    });

    test('leaves the caller\'s list unmodified', () {
      final dets = makeDets([
        (0, 0.5, const Rect.fromLTRB(0.0, 0.0, 0.1, 0.1)),
        (1, 0.9, const Rect.fromLTRB(0.2, 0.2, 0.3, 0.3)),
      ]);
      final before = dets.map((d) => d.score).toList();
      detector.nms(dets, 0.5);
      expect(dets.map((d) => d.score).toList(), before);
    });

    test('empty input yields empty output', () {
      expect(detector.nms(const [], 0.5), isEmpty);
    });
  });

  group('DetectionResult', () {
    test('const constructor works', () {
      const r = DetectionResult([], Size.zero, 0);
      expect(r.detections, isEmpty);
      expect(r.frameSize, Size.zero);
      expect(r.inferenceMs, 0);
    });
  });
}
