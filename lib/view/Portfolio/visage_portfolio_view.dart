import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nyx_kernel/nyx_kernel.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxVector/nyx_vector_ux_card.dart';
import 'package:visage/view/Creation/visage_creation_flow_view.dart';
import 'package:visage/widget/glass_container.dart';

/// 생성된 컴카드 히스토리를 보여주는 포트폴리오 뷰
class VisagePortfolioView extends StatefulWidget {
  const VisagePortfolioView({super.key});

  @override
  State<VisagePortfolioView> createState() => _VisagePortfolioViewState();
}

class _VisagePortfolioViewState extends State<VisagePortfolioView>
    with TickerProviderStateMixin {
  static const int _itemsPerPage = 20;

  final ScrollController _scrollController = ScrollController();
  final List<NyxVectorUXThumbCardStore> _cards = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  int _hoveredIndex = -1;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    final uid = NyxMemberFirecatAuthController.getCurrentUserUid();
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      final result =
          await NyxVectorFirecatCrudController.getRecentVectorsWithPagination(
            isVisible: true,
            uid: uid,
            limit: _itemsPerPage,
          );

      if (mounted) {
        setState(() {
          _cards.addAll(result.items);
          _lastDoc = result.lastDocument;
          _hasMore = result.items.length >= _itemsPerPage;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('[Portfolio] 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward();
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    final uid = NyxMemberFirecatAuthController.getCurrentUserUid();
    if (uid == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final result =
          await NyxVectorFirecatCrudController.getRecentVectorsWithPagination(
            isVisible: true,
            uid: uid,
            startAfter: _lastDoc,
            limit: _itemsPerPage,
          );

      if (mounted) {
        setState(() {
          _cards.addAll(result.items);
          if (result.items.isNotEmpty) _lastDoc = result.lastDocument;
          _hasMore = result.items.length >= _itemsPerPage;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('[Portfolio] 추가 로드 실패: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onRefresh() async {
    _cards.clear();
    _lastDoc = null;
    _hasMore = true;
    _fadeController.reset();
    await _loadInitial();
  }

  void _navigateToCreation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const VisageCreationFlowView(),
        transitionsBuilder: (_, animation, __, child) {
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

  /// 컴카드 삭제
  Future<void> _onDeleteCard(int index) async {
    final card = _cards[index];
    final docId = card.documentRef?.id;
    if (docId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => _buildDeleteConfirm(ctx),
    );

    if (confirmed != true) return;

    final success = await NyxVectorFirecatCrudController.deleteVector(docId);
    if (success && mounted) {
      setState(() => _cards.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('컴카드가 삭제되었습니다'),
          backgroundColor: Colors.white.withOpacity(0.15),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ─────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 16),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── Background ───────────

  Widget _buildBackground() {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            'assets/image/visage_bg_ee.jpeg',
            fit: BoxFit.cover,
          ),
        ),
        // 플로우 뷰와 동일한 톤 (카드 가독성 위해 약간 더 진하게)
        Container(color: Colors.black.withOpacity(0.18)),
        // Floating orb – top right (warm pink) : 플로우 뷰와 동일
        Positioned(
          top: -80,
          right: -60,
          child: _orb(320, const Color(0xFFEBB5FF), 0.30),
        ),
        // Floating orb – bottom left (soft blue) : 플로우 뷰와 동일
        Positioned(
          bottom: -100,
          left: -40,
          child: _orb(380, const Color(0xFFB5D4FF), 0.25),
        ),
        // Floating orb – center right (peach) : 플로우 뷰와 동일
        Positioned(
          top: size.height * 0.45,
          right: size.width * 0.15,
          child: _orb(220, const Color(0xFFFFCBD4), 0.18),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }

  // ─────────── Top Bar ───────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Back
          _glassIcon(
            Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PORTFOLIO',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isLoading ? '불러오는 중...' : '${_cards.length}개의 컴카드',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Refresh
          _glassIcon(Icons.refresh_rounded, onTap: _onRefresh),
        ],
      ),
    );
  }

  Widget _glassIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 16,
        blur: 10,
        child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
      ),
    );
  }

  // ─────────── Body ───────────

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_cards.isEmpty) return _buildEmptyState();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 반응형: 화면 너비에 따라 열 수 결정
          final crossAxisCount = constraints.maxWidth > 1200
              ? 4
              : constraints.maxWidth > 800
              ? 3
              : 2;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GridView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 16 / 10,
              ),
              itemCount: _cards.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _cards.length) {
                  return _buildLoadMoreIndicator();
                }
                return _PortfolioCardItem(
                  key: ValueKey(_cards[index].documentRef?.id ?? index),
                  card: _cards[index],
                  index: index,
                  isHovered: _hoveredIndex == index,
                  onHover: (hovered) =>
                      setState(() => _hoveredIndex = hovered ? index : -1),
                  onTap: () => _onCardTap(index),
                  onDelete: () => _onDeleteCard(index),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: Colors.white.withOpacity(0.5),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '포트폴리오를 불러오는 중...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF9B6FD6).withOpacity(0.12),
                    const Color(0xFFD070F0).withOpacity(0.06),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.dashboard_customize_outlined,
                size: 40,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '아직 생성된 컴카드가 없어요',
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 컴카드를 만들어보세요!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            // CTA 버튼
            GestureDetector(
              onTap: _navigateToCreation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9B6FD6), Color(0xFFD070F0)],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B6FD6).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '컴카드 만들기',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CircularProgressIndicator(
          color: Colors.white.withOpacity(0.3),
          strokeWidth: 2,
        ),
      ),
    );
  }

  // ─────────── Detail Dialog ───────────

  void _onCardTap(int index) {
    final card = _cards[index];
    final data = card.vectorData;
    if (data == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'detail',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) =>
          _DetailDialog(data: data, docId: card.documentRef?.id ?? ''),
    );
  }

  Widget _buildDeleteConfirm(BuildContext ctx) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: GlassContainer(
          borderRadius: 24,
          blur: 30,
          opacity: 0.2,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 40,
                color: Colors.redAccent.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              const Text(
                '이 컴카드를 삭제할까요?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '삭제된 컴카드는 복구할 수 없습니다',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: const Text(
                          '취소',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.redAccent.withOpacity(0.25),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.4),
                          ),
                        ),
                        child: const Text(
                          '삭제',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 카드 아이템 (별도 StatelessWidget으로 분리)
// ═══════════════════════════════════════════════════════════════

class _PortfolioCardItem extends StatelessWidget {
  final NyxVectorUXThumbCardStore card;
  final int index;
  final bool isHovered;
  final ValueChanged<bool> onHover;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PortfolioCardItem({
    super.key,
    required this.card,
    required this.index,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = card.vectorData;
    final thumbUrl = data?.ee_vector_thumbnail_url ?? '';
    final prompt = data?.ee_input_prompt ?? '';
    final designStyle = data?.ee_design_style ?? '';
    final createdAt = data?.sys_reg_date;
    final dateStr = createdAt != null
        ? '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}'
        : '';

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..translate(0.0, isHovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered
                  ? Colors.white.withOpacity(0.25)
                  : Colors.white.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF9B6FD6).withOpacity(0.25),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFFD070F0).withOpacity(0.10),
                      blurRadius: 16,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // Thumbnail
                if (thumbUrl.isNotEmpty)
                  SizedBox.expand(
                    child: Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _FallbackThumb(index: index),
                    ),
                  )
                else
                  _FallbackThumb(index: index),

                // Hover overlay
                if (isHovered)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                      ),
                    ),
                  ),

                // Bottom info
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.55),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (prompt.isNotEmpty)
                                    Text(
                                      prompt,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (dateStr.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        dateStr,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.35),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (designStyle.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: Text(
                                  designStyle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 썸네일 없을 때 표시되는 폴백 위젯
// ═══════════════════════════════════════════════════════════════

class _FallbackThumb extends StatelessWidget {
  final int index;
  const _FallbackThumb({required this.index});

  // visage_bg_ee.jpeg 톤에 맞춘 마젠타/딥네이비/틸 계열
  static const _gradients = [
    [Color(0xFF9B6FD6), Color(0xFFD070F0)], // 라벤더 → 핑크퍼플
    [Color(0xFF1A3A5C), Color(0xFF2E7D9B)], // 딥네이비 → 틸
    [Color(0xFFA0275E), Color(0xFFE04090)], // 딥마젠타 → 핫핑크
    [Color(0xFF2C3E6B), Color(0xFF7B6FBE)], // 네이비 → 라벤더
    [Color(0xFF1B5E7A), Color(0xFF80CBC4)], // 다크틸 → 민트
    [Color(0xFF6A1B5E), Color(0xFFEBB5FF)], // 딥퍼플 → 소프트핑크
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradients[index % _gradients.length],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white.withOpacity(0.25),
          size: 32,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 상세 보기 다이얼로그
// ═══════════════════════════════════════════════════════════════

class _DetailDialog extends StatelessWidget {
  final NyxVectorStore data;
  final String docId;

  const _DetailDialog({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final thumbUrl = data.ee_vector_thumbnail_url;
    final prompt = data.ee_input_prompt;
    final style = data.ee_design_style;
    final date = data.sys_reg_date;
    final ratio = data.ee_ratio;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              borderRadius: 28,
              blur: 40,
              opacity: 0.18,
              enableShadow: true,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 이미지
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: thumbUrl.isNotEmpty
                          ? Image.network(thumbUrl, fit: BoxFit.cover)
                          : Container(
                              color: Colors.white.withOpacity(0.05),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white.withOpacity(0.2),
                                size: 48,
                              ),
                            ),
                    ),
                  ),

                  // 정보 섹션
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (prompt.isNotEmpty) ...[
                          Text(
                            prompt,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                        ],
                        // 메타 정보
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Chip(
                              label:
                                  '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                              icon: Icons.calendar_today_rounded,
                            ),
                            if (style.isNotEmpty)
                              _Chip(label: style, icon: Icons.palette_outlined),
                            if (ratio.isNotEmpty)
                              _Chip(
                                label: ratio,
                                icon: Icons.aspect_ratio_rounded,
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 닫기 버튼
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withOpacity(0.08),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: const Text(
                              '닫기',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withOpacity(0.4)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
