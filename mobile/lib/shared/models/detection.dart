import 'dart:ui';

class Detection {
  final int classId;
  final String className;
  final double score;
  final Rect rect;
  final Color color;

  const Detection({
    required this.classId,
    required this.className,
    required this.score,
    required this.rect,
    required this.color,
  });
}
