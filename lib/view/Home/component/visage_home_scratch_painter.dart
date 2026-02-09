import 'package:flutter/material.dart';

class VisageHomeScratchPainter extends CustomPainter {
  final List<Offset> revealedPoints;
  final double brushRadius;

  VisageHomeScratchPainter({
    required this.revealedPoints,
    required this.brushRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (revealedPoints.isEmpty) return;

    // 마스크 생성을 위한 Path
    final path = Path();

    for (final point in revealedPoints) {
      // 각 포인트 주변에 원형 브러시 그리기
      path.addOval(Rect.fromCircle(center: point, radius: brushRadius));
    }

    // 드러난 영역을 투명하게 만들기 (회색 레이어에 구멍 뚫기)
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 드러난 영역을 투명하게
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VisageHomeScratchPainter oldDelegate) {
    return revealedPoints.length != oldDelegate.revealedPoints.length;
  }
}
