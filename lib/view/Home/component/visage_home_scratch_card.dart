import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class VisageHomeScratchCard extends StatefulWidget {
  const VisageHomeScratchCard({super.key});

  @override
  State<VisageHomeScratchCard> createState() => _VisageHomeScratchCardState();
}

class _VisageHomeScratchCardState extends State<VisageHomeScratchCard> {
  final List<Offset> _revealedPoints = [];
  static const double brushRadius = 80.0; // 브러시 크기

  void _onHover(PointerHoverEvent event) {
    setState(() {
      // 마우스 위치 저장
      _revealedPoints.add(event.localPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      child: Container(
        width: 800,
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // 1. 맨 아래: 컬러풀 이미지
              _buildColorfulCard(),

              // 2. 맨 위: 회색 레이어 (마우스 경로 제외)
              RepaintBoundary(
                child: CustomPaint(
                  size: const Size(800, 500),
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
    return SizedBox(
      width: 800,
      height: 500,
      child: Image.asset(
        'assets/image/example.jpeg',
        width: 800,
        height: 500,
        fit: BoxFit.cover,
      ),
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

    // 마우스가 지나간 영역을 투명하게 제거
    if (revealedPoints.isNotEmpty) {
      final erasePaint = Paint()
        ..blendMode = BlendMode
            .clear // 완전히 제거
        ..style = PaintingStyle.fill;

      for (final point in revealedPoints) {
        canvas.drawCircle(point, brushRadius, erasePaint);
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
