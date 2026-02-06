import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class VisageHomeScratchCard extends StatefulWidget {
  const VisageHomeScratchCard({super.key});

  @override
  State<VisageHomeScratchCard> createState() => _VisageHomeScratchCardState();
}

class _VisageHomeScratchCardState extends State<VisageHomeScratchCard> {
  final List<Offset> _revealedPoints = [];
  static const double brushRadius = 60.0; // 브러시 크기
  ui.Image? _sketchImage;

  @override
  void initState() {
    super.initState();
    _loadSketchImage();
  }

  Future<void> _loadSketchImage() async {
    final ByteData data = await rootBundle.load('assets/image/example_sketch.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _sketchImage = frame.image;
      });
    }
  }

  void _onHover(PointerHoverEvent event) {
    setState(() {
      // 마우스 위치 저장
      _revealedPoints.add(event.localPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.85; // 화면의 85%
    final cardHeight = screenSize.height * 0.80; // 화면의 70%

    return MouseRegion(
      onHover: _onHover,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // 1. 맨 아래: 컬러풀 이미지
              _buildColorfulCard(),

              // 2. 맨 위: 스케치 마스크
              if (_sketchImage != null)
                RepaintBoundary(
                  child: CustomPaint(
                    size: Size(cardWidth, cardHeight),
                    isComplex: true,
                    willChange: true,
                    painter: _SketchWithMaskPainter(
                      revealedPoints: List.from(_revealedPoints),
                      brushRadius: brushRadius,
                      sketchImage: _sketchImage!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 컴카드 이미지
  Widget _buildColorfulCard() {
    return Image.asset(
      'assets/image/example.jpeg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

}

// 스케치 with 마스크 Painter
class _SketchWithMaskPainter extends CustomPainter {
  final List<Offset> revealedPoints;
  final double brushRadius;
  final ui.Image sketchImage;

  _SketchWithMaskPainter({
    required this.revealedPoints,
    required this.brushRadius,
    required this.sketchImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 스케치 이미지 그리기
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: sketchImage,
      fit: BoxFit.cover,
    );

    // 마우스가 지나간 영역만 투명하게 제거
    if (revealedPoints.isNotEmpty) {
      final erasePaint = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;

      // 각 포인트마다 불규칙한 브러시 스탬프 그리기
      for (int i = 0; i < revealedPoints.length; i++) {
        final point = revealedPoints[i];

        // 메인 원 그리기
        canvas.drawCircle(point, brushRadius * 0.4, erasePaint);

        // 주변에 불규칙한 타원형 스플래터 배치 (붓으로 튄 느낌)
        final seed = (point.dx * 1000 + point.dy).toInt();
        final random = math.Random(seed);

        final splatterCount = 12; // 스플래터 개수
        for (int j = 0; j < splatterCount; j++) {
          final angle =
              (j / splatterCount) * 2 * math.pi + random.nextDouble() * 1.2;
          final distance = brushRadius * (0.5 + random.nextDouble() * 1.0);

          final splatterPoint = Offset(
            point.dx + math.cos(angle) * distance,
            point.dy + math.sin(angle) * distance,
          );

          // 길쭉한 타원 (붓으로 튄 모양)
          final splatterWidth = brushRadius * (0.3 + random.nextDouble() * 0.6);
          final splatterHeight =
              splatterWidth * (0.2 + random.nextDouble() * 0.3); // 좁고 길쭉하게

          canvas.save();
          canvas.translate(splatterPoint.dx, splatterPoint.dy);
          canvas.rotate(angle + random.nextDouble() * 0.5); // 바깥 방향으로 회전

          // 타원 그리기
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: splatterWidth,
              height: splatterHeight,
            ),
            erasePaint,
          );

          canvas.restore();
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SketchWithMaskPainter oldDelegate) {
    return true;
  }
}
