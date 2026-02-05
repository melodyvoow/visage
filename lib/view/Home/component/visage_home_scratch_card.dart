import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;

class VisageHomeScratchCard extends StatefulWidget {
  const VisageHomeScratchCard({super.key});

  @override
  State<VisageHomeScratchCard> createState() => _VisageHomeScratchCardState();
}

class _VisageHomeScratchCardState extends State<VisageHomeScratchCard> {
  final List<Offset> _revealedPoints = [];
  static const double brushRadius = 60.0; // 브러시 크기

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

              // 2. 맨 위: 회색 레이어 (마우스 경로 제외)
              RepaintBoundary(
                child: CustomPaint(
                  size: Size(cardWidth, cardHeight),
                  isComplex: true,
                  willChange: true,
                  painter: _GrayscaleOverlayPainter(
                    revealedPoints: List.from(_revealedPoints), // 새 리스트로 복사
                    brushRadius: brushRadius,
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

// 회색 오버레이 Painter (스크래치 영역 제외)
class _GrayscaleOverlayPainter extends CustomPainter {
  final List<Offset> revealedPoints;
  final double brushRadius;

  _GrayscaleOverlayPainter({
    required this.revealedPoints,
    required this.brushRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // saveLayer 시작
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 전체를 반투명 회색으로 채우기 (실루엣이 보이도록)
    final grayPaint = Paint()
      ..color =
          const Color(0xF0EEEEEE) // 82% 불투명도의 밝은 회색
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grayPaint);

    // 마우스가 지나간 영역을 투명하게 제거 (불규칙한 브러시 효과)
    if (revealedPoints.isNotEmpty) {
      final erasePaint = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;

      // 각 포인트마다 불규칙한 브러시 스탬프 그리기
      for (int i = 0; i < revealedPoints.length; i++) {
        final point = revealedPoints[i];

        // 메인 원 그리기 (더 작게)
        canvas.drawCircle(point, brushRadius * 0.5, erasePaint);

        // 주변에 불규칙한 작은 원들 배치 (페인트 브러시 효과)
        final seed = (point.dx * 1000 + point.dy).toInt(); // 위치 기반 시드
        final random = math.Random(seed);

        final splatterCount = 10; // 주변 원 개수 (줄임)
        for (int j = 0; j < splatterCount; j++) {
          final angle =
              (j / splatterCount) * 2 * math.pi + random.nextDouble() * 1.0;
          final distance =
              brushRadius * (0.6 + random.nextDouble() * 0.8); // 더 멀리
          final splatterRadius =
              brushRadius * (0.15 + random.nextDouble() * 0.4); // 더 작게

          final splatterPoint = Offset(
            point.dx + math.cos(angle) * distance,
            point.dy + math.sin(angle) * distance,
          );

          canvas.drawCircle(splatterPoint, splatterRadius, erasePaint);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GrayscaleOverlayPainter oldDelegate) {
    // 항상 다시 그리기
    return true;
  }
}
