import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:visage/widget/glass_container.dart';

class VisageImageSelectStep extends StatefulWidget {
  final List<Uint8List> images;
  final void Function(int index) onImageSelected;
  final VoidCallback onRegenerate;

  const VisageImageSelectStep({
    super.key,
    required this.images,
    required this.onImageSelected,
    required this.onRegenerate,
  });

  @override
  State<VisageImageSelectStep> createState() => _VisageImageSelectStepState();
}

class _VisageImageSelectStepState extends State<VisageImageSelectStep> {
  int? _selectedIndex;
  int _hoveredIndex = -1;

  // 이미지가 없을 때 사용할 fallback 그라데이션
  static const List<List<Color>> _fallbackGradients = [
    [Color(0xFF6A1B9A), Color(0xFFE040FB)],
    [Color(0xFF1565C0), Color(0xFF42A5F5)],
    [Color(0xFF00695C), Color(0xFF26A69A)],
    [Color(0xFFC62828), Color(0xFFEF5350)],
  ];

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.images.isEmpty ? 4 : widget.images.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'SELECT YOUR MOOD',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.images.isEmpty
                    ? 'Image generation failed. Please try again.'
                    : 'Select The Most Your Favorite Image, which AI Generated',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Image grid - 2x2
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1,
                  ),
                  itemCount: imageCount,
                  itemBuilder: (context, index) => _buildImageCard(index),
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Refresh button
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

                  // Select button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _selectedIndex != null
                        ? () => widget.onImageSelected(_selectedIndex!)
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

  Widget _buildImageCard(int index) {
    final isSelected = _selectedIndex == index;
    final isHovered = _hoveredIndex == index;
    final hasImage = index < widget.images.length;

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
                // 실제 이미지 또는 fallback 그라데이션
                if (hasImage)
                  SizedBox.expand(
                    child: Image.memory(
                      widget.images[index],
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
                            Icons.image_not_supported_outlined,
                            color: Colors.white.withOpacity(0.5),
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generation failed',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
