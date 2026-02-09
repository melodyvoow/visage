import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:visage/widget/glass_container.dart';

class VisageLayoutRecommendStep extends StatefulWidget {
  final List<Uint8List> layoutImages;
  final void Function(int index) onLayoutSelected;
  final VoidCallback onRegenerate;

  const VisageLayoutRecommendStep({
    super.key,
    required this.layoutImages,
    required this.onLayoutSelected,
    required this.onRegenerate,
  });

  @override
  State<VisageLayoutRecommendStep> createState() =>
      _VisageLayoutRecommendStepState();
}

class _VisageLayoutRecommendStepState extends State<VisageLayoutRecommendStep> {
  int? _selectedIndex;
  int _hoveredIndex = -1;

  static const List<List<Color>> _fallbackGradients = [
    [Color(0xFF6A1B9A), Color(0xFFE040FB)],
    [Color(0xFF1565C0), Color(0xFF42A5F5)],
    [Color(0xFF00695C), Color(0xFF26A69A)],
    [Color(0xFFC62828), Color(0xFFEF5350)],
  ];

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.layoutImages.isEmpty
        ? 4
        : widget.layoutImages.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Text(
                'SELECT A LAYOUT',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.layoutImages.isEmpty
                    ? 'Layout generation failed. Please try again.'
                    : 'Select One of The AI-Recommended Comp Card Layouts',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Layout images grid
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 16 / 10,
                  ),
                  itemCount: imageCount,
                  itemBuilder: (context, index) => _buildLayoutCard(index),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Refresh
                  GestureDetector(
                    onTap: widget.onRegenerate,
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      borderRadius: 28,
                      blur: 10,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'REFRESH',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Select
                  GestureDetector(
                    onTap: _selectedIndex != null
                        ? () => widget.onLayoutSelected(_selectedIndex!)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: _selectedIndex != null
                            ? const Color(0xFF15234A)
                            : const Color(0xFF15234A).withOpacity(0.4),
                        boxShadow: _selectedIndex != null
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF15234A).withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'SELECT',
                        style: TextStyle(
                          color: _selectedIndex != null
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
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

  Widget _buildLayoutCard(int index) {
    final isSelected = _selectedIndex == index;
    final isHovered = _hoveredIndex == index;
    final hasImage = index < widget.layoutImages.length;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: hasImage ? () => setState(() => _selectedIndex = index) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withOpacity(0.6)
                  : isHovered
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                // 생성된 레이아웃 이미지 또는 placeholder
                if (hasImage)
                  SizedBox.expand(
                    child: Image.memory(
                      widget.layoutImages[index],
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            _fallbackGradients[index %
                                _fallbackGradients.length],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dashboard_customize_outlined,
                            color: Colors.white.withOpacity(0.5),
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pending',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 하단 그라데이션 오버레이 + 레이아웃 번호
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Text(
                      'Layout ${index + 1}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // Selection check
                if (isSelected)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF15234A),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF15234A).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
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
