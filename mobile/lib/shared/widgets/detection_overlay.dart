import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/detection.dart';

/// How a frame is fitted into the widget the overlay paints over.
///
/// This must match the [BoxFit] used by the widget showing the image,
/// otherwise the boxes drift away from what the user sees.
enum OverlayFit {
  /// Whole frame visible, letterboxed. Used for a captured still.
  contain,

  /// Frame fills the widget, overflow center-cropped. Used for a live preview.
  cover,
}

/// The scale-and-offset that maps frame pixels onto widget pixels.
@immutable
class OverlayTransform {
  final double scale;
  final double dx;
  final double dy;

  const OverlayTransform(this.scale, this.dx, this.dy);

  /// Replicates Flutter's own fit math so boxes land where the image does.
  factory OverlayTransform.forFit({
    required Size imageSize,
    required Size widgetSize,
    required OverlayFit fit,
  }) {
    final sx = widgetSize.width / imageSize.width;
    final sy = widgetSize.height / imageSize.height;
    final scale = fit == OverlayFit.cover ? math.max(sx, sy) : math.min(sx, sy);
    return OverlayTransform(
      scale,
      (widgetSize.width - imageSize.width * scale) / 2,
      (widgetSize.height - imageSize.height * scale) / 2,
    );
  }

  /// Maps a 0..1 normalized rect in frame space to widget space.
  Rect apply(Rect normalized, Size imageSize) => Rect.fromLTRB(
        normalized.left * imageSize.width * scale + dx,
        normalized.top * imageSize.height * scale + dy,
        normalized.right * imageSize.width * scale + dx,
        normalized.bottom * imageSize.height * scale + dy,
      );
}

/// Draws bounding boxes and labels over a frame.
///
/// Boxes arrive normalized 0..1 in the upright frame ([imageSize]); [fit] must
/// match how that frame is displayed underneath.
class DetectionOverlay extends CustomPainter {
  final List<Detection> detections;

  /// Upright frame size in pixels.
  final Size imageSize;

  final OverlayFit fit;

  const DetectionOverlay(
    this.detections,
    this.imageSize, {
    this.fit = OverlayFit.contain,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.isEmpty || size.isEmpty) return;

    final transform = OverlayTransform.forFit(
      imageSize: imageSize,
      widgetSize: size,
      fit: fit,
    );

    for (final d in detections) {
      final rect = transform.apply(d.rect, imageSize);

      final boxPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = d.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        boxPaint,
      );

      _drawLabel(canvas, rect, d);
    }
  }

  void _drawLabel(Canvas canvas, Rect box, Detection d) {
    final text = '${d.className}  ${(d.score * 100).toStringAsFixed(0)}%';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    const padH = 6.0;
    const padV = 3.0;
    final labelW = tp.width + padH * 2;
    final labelH = tp.height + padV * 2;

    // Sit the label above the box; flip below if it would go off the top.
    double ly = box.top - labelH;
    if (ly < 0) ly = box.top;
    final lx = box.left.clamp(0.0, double.infinity);

    final bg = Paint()..color = d.color;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(lx, ly, labelW, labelH),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomRight: const Radius.circular(6),
      ),
      bg,
    );
    tp.paint(canvas, Offset(lx + padH, ly + padV));
  }

  @override
  bool shouldRepaint(covariant DetectionOverlay old) =>
      old.detections != detections ||
      old.imageSize != imageSize ||
      old.fit != fit;
}
