import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxMember/nyx_member_firecat_auth_controller.dart';
import 'package:visage/view/Creation/visage_creation_flow_view.dart';
import 'package:visage/view/Portfolio/visage_portfolio_view.dart';
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

  void _navigateToPortfolio() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const VisagePortfolioView(),
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
      body: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 타이틀
            Text(
              'CREATE YOUR COLOR & YOUR STORY',
              style: GoogleFonts.alata(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w400,
                letterSpacing: -1,
              ),
            ),

            const SizedBox(height: 16),

            // 스크래치 카드 영역 (화면의 85% 크기)
            const VisageHomeScratchCard(),

            const SizedBox(height: 18),

            // 로그인 상태에 따라 버튼 전환
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
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
                  ? _buildLoggedInButtons()
                  : _buildGoogleLoginButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 공통 버튼 규격 ───
  static const double _btnHeight = 56;
  static const double _btnRadius = 30;
  static const double _btnFontSize = 15;
  static const EdgeInsets _btnPadding = EdgeInsets.symmetric(
    horizontal: 32,
    vertical: 0,
  );

  /// 로그인 후 버튼 (컴카드 만들기 + 포트폴리오)
  Widget _buildLoggedInButtons() {
    return Row(
      key: const ValueKey('loggedInButtons'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 컴카드 만들기 버튼
        SizedBox(
          height: _btnHeight,
          child: ElevatedButton(
            onPressed: _navigateToCreation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: _btnPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_btnRadius),
              ),
              elevation: 10,
            ),
            child: const Text(
              '나만의 컴카드 만들기',
              style: TextStyle(
                fontSize: _btnFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 포트폴리오 버튼
        SizedBox(
          height: _btnHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_btnRadius),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B6FD6).withOpacity(0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _navigateToPortfolio,
              icon: const Icon(Icons.collections_bookmark_rounded, size: 18),
              label: const Text(
                'PORTFOLIO',
                style: TextStyle(
                  fontSize: _btnFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.08),
                foregroundColor: Colors.white,
                padding: _btnPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_btnRadius),
                  side: BorderSide(
                    color: const Color(0xFF9B6FD6).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
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
        child: SizedBox(
          height: _btnHeight,
          child: _isLoginInProgress
              ? Container(
                  padding: _btnPadding,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(_btnRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '로그인 중...',
                        style: TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontSize: _btnFontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                )
              : Image.asset(
                  'assets/image/google_login.png',
                  height: _btnHeight,
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}
