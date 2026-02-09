import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VisageMobileGuideView extends StatefulWidget {
  const VisageMobileGuideView({super.key});

  @override
  State<VisageMobileGuideView> createState() => _VisageMobileGuideViewState();
}

class _VisageMobileGuideViewState extends State<VisageMobileGuideView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── 배경 이미지 ───
          Image.asset('assets/image/visage_bg_ee.jpeg', fit: BoxFit.cover),

          // ─── 어두운 오버레이 ───
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ─── 콘텐츠 ───
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // 로고 / 타이틀
                      Text(
                        'VISAGE',
                        style: GoogleFonts.alata(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 8,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'AI Comp Card Generator',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ─── 글래스 카드 ───
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 36,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.18),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 0.8,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 아이콘
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(
                                          0xFF7C4DFF,
                                        ).withOpacity(0.8),
                                        const Color(
                                          0xFF651FFF,
                                        ).withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.desktop_mac_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // 메인 텍스트
                                Text(
                                  'Desktop Only',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // 서브 텍스트
                                Text(
                                  'Creation and editing are optimized\nfor the desktop experience.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1.6,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // 구분선
                                Container(
                                  width: 40,
                                  height: 1,
                                  color: Colors.white.withOpacity(0.15),
                                ),

                                const SizedBox(height: 24),

                                // 안내 항목들
                                _buildGuideItem(
                                  Icons.brush_rounded,
                                  'Precision Editing Tools',
                                ),
                                const SizedBox(height: 14),
                                _buildGuideItem(
                                  Icons.auto_awesome_rounded,
                                  'AI-Powered Comp Card Creation',
                                ),
                                const SizedBox(height: 14),
                                _buildGuideItem(
                                  Icons.download_rounded,
                                  'High-Resolution Download',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // 하단 안내
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.open_in_browser_rounded,
                            color: Colors.white.withOpacity(0.4),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'visage-u.web.app',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.08),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
