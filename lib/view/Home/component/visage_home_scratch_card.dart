import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class VisageHomeScratchCard extends StatefulWidget {
  const VisageHomeScratchCard({super.key});

  @override
  State<VisageHomeScratchCard> createState() => _VisageHomeScratchCardState();
}

class _VisageHomeScratchCardState extends State<VisageHomeScratchCard>
    with SingleTickerProviderStateMixin {
  final List<Offset> _revealedPoints = [];
  static const double brushRadius = 60.0; // 브러시 크기
  ui.Image? _sketchImage;
  late AnimationController _hintAnimationController;
  late Animation<double> _hintAnimation;
  Offset? _centerPoint;

  @override
  void initState() {
    super.initState();
    _loadSketchImage();
    _setupHintAnimation();
  }

  Future<void> _loadSketchImage() async {
    final ByteData data = await rootBundle.load('assets/image/main_sketch.jpeg');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _sketchImage = frame.image;
      });
      // 이미지 로드 후 힌트 애니메이션 시작
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _hintAnimationController.forward();
        }
      });
    }
  }

  void _setupHintAnimation() {
    _hintAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _hintAnimation = CurvedAnimation(
      parent: _hintAnimationController,
      curve: Curves.easeOutCubic,
    );

    _hintAnimationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _hintAnimationController.dispose();
    super.dispose();
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

    // 중앙점 계산 (한 번만)
    _centerPoint ??= Offset(cardWidth / 2, cardHeight / 2);

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
                      hintProgress: _hintAnimation.value,
                      centerPoint: _centerPoint,
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
      'assets/image/main.jpeg',
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
  final double hintProgress;
  final Offset? centerPoint;

  _SketchWithMaskPainter({
    required this.revealedPoints,
    required this.brushRadius,
    required this.sketchImage,
    required this.hintProgress,
    this.centerPoint,
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

    // 힌트 애니메이션: 중앙에 자연스러운 스크래치
    if (hintProgress > 0 && centerPoint != null) {
      final erasePaint = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;

      final random = math.Random(42); // 고정 시드로 일관된 패턴
      final hintPointCount = (15 * hintProgress).toInt(); // 최대 15개 포인트

      // 중앙에서 약간씩 움직이는 자연스러운 경로
      for (int i = 0; i < hintPointCount; i++) {
        final t = i / 15;
        final angle = t * math.pi * 0.5 + random.nextDouble() * 0.3; // 약간 랜덤
        final distance = brushRadius * t * 1.5;

        final point = Offset(
          centerPoint!.dx + math.cos(angle) * distance,
          centerPoint!.dy + math.sin(angle) * distance,
        );

        // 메인 원
        canvas.drawCircle(point, brushRadius * 0.4, erasePaint);

        // 타원형 스플래터
        final splatterCount = 8;
        for (int j = 0; j < splatterCount; j++) {
          final splatterAngle =
              (j / splatterCount) * 2 * math.pi + random.nextDouble() * 1.2;
          final splatterDistance =
              brushRadius * (0.5 + random.nextDouble() * 1.0);

          final splatterPoint = Offset(
            point.dx + math.cos(splatterAngle) * splatterDistance,
            point.dy + math.sin(splatterAngle) * splatterDistance,
          );

          final splatterWidth = brushRadius * (0.3 + random.nextDouble() * 0.6);
          final splatterHeight =
              splatterWidth * (0.2 + random.nextDouble() * 0.3);

          canvas.save();
          canvas.translate(splatterPoint.dx, splatterPoint.dy);
          canvas.rotate(splatterAngle + random.nextDouble() * 0.5);

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
