import 'package:flutter/material.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxMember/nyx_member_firecat_auth_controller.dart';
import 'package:visage/view/Creation/visage_creation_flow_view.dart';
import 'component/visage_home_scratch_card.dart';

class VisageHomeView extends StatefulWidget {
  const VisageHomeView({super.key});

  @override
  State<VisageHomeView> createState() => _VisageHomeViewState();
}

class _VisageHomeViewState extends State<VisageHomeView> {
  bool _isLoginInProgress = false;

  bool get _isLoggedIn =>
      NyxMemberFirecatAuthController.getCurrentUserUid() != null;

  Future<void> _handleGoogleLogin() async {
    if (_isLoginInProgress) return;

    setState(() {
      _isLoginInProgress = true;
    });

    try {
      final success = await NyxMemberFirecatAuthController.login((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      });

      if (mounted && success) {
        debugPrint('✅ Google 로그인 성공');
        setState(() {}); // 로그인 성공 시 화면 갱신
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoginInProgress = false;
        });
      }
    }
  }

  void _navigateToCreation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const VisageCreationFlowView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 타이틀
            const Text(
              'Your Color, Your Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),

            const SizedBox(height: 25),

            // 스크래치 카드 영역 (화면의 85% 크기)
            const VisageHomeScratchCard(),

            const SizedBox(height: 25),

            // 로그인 상태에 따라 버튼 전환
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: _isLoggedIn
                  ? _buildCreateButton()
                  : _buildGoogleLoginButton(),
            ),
          ],
        ),
      ),
    );
  }

  /// 컴카드 생성하러 가기 버튼
  Widget _buildCreateButton() {
    return ElevatedButton(
      key: const ValueKey('createButton'),
      onPressed: _navigateToCreation,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(
          horizontal: 48,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
      ),
      child: const Text(
        '나만의 컴카드 만들기',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Google 로그인 버튼
  Widget _buildGoogleLoginButton() {
    return GestureDetector(
      key: const ValueKey('loginButton'),
      onTap: _isLoginInProgress ? null : _handleGoogleLogin,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isLoginInProgress ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Google 로고 (SVG 대신 직접 그리기)
              _buildGoogleLogo(),
              const SizedBox(width: 16),
              Text(
                _isLoginInProgress ? '로그인 중...' : 'Google로 시작하기',
                style: const TextStyle(
                  color: Color(0xFF1F1F1F),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              if (_isLoginInProgress) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Google 로고 위젯
  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

/// Google 로고를 그리는 CustomPainter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w * 0.45;

    // Google "G" 로고 간소화 버전
    // 파란색 (오른쪽 상단)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    // 빨간색 (오른쪽 하단 → 왼쪽 상단)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    // 노란색
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    // 초록색
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // 그리기 순서: 빨강(상단) → 노랑(좌하단) → 초록(하단) → 파랑(우측)
    // 각도: 0 = 3시, 90 = 6시 (시계방향), -90 = 12시

    // 빨간색: 12시 ~ 9시 (왼쪽 상단)
    canvas.drawArc(rect, -2.8, -0.75, false, redPaint);

    // 노란색: 9시 ~ 6시 (왼쪽 하단)
    canvas.drawArc(rect, 2.6, 0.75, false, yellowPaint);

    // 초록색: 6시 ~ 3시 (오른쪽 하단)
    canvas.drawArc(rect, 0.55, 0.75, false, greenPaint);

    // 파란색: 3시 ~ 12시 (오른쪽 상단) + 가로선
    canvas.drawArc(rect, -0.55, 0.75, false, bluePaint);

    // 파란색 가로선 (G의 가운데 획)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(cx - w * 0.02, cy - h * 0.08, w * 0.5, h * 0.16),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
