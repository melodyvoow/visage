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
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                '추구미 이미지를 선택해주세요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.images.isEmpty
                    ? '이미지 생성에 실패했습니다. 다시 시도해주세요.'
                    : 'AI가 생성한 이미지 중 마음에 드는 것을 선택하세요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
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
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: imageCount,
                  itemBuilder: (context, index) => _buildImageCard(index),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Regenerate button
                  GestureDetector(
                    onTap: widget.onRegenerate,
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      borderRadius: 20,
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
                            '다시 생성',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Select button
                  GestureDetector(
                    onTap: _selectedIndex != null
                        ? () => widget.onImageSelected(_selectedIndex!)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: _selectedIndex != null
                            ? const LinearGradient(
                                colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                              )
                            : null,
                        color: _selectedIndex != null
                            ? null
                            : Colors.white.withOpacity(0.05),
                        boxShadow: _selectedIndex != null
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7B2FBE,
                                  ).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '이 이미지로 진행',
                        style: TextStyle(
                          color: _selectedIndex != null
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
                  ? const Color(0xFFE040FB)
                  : isHovered
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE040FB).withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
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
                            '생성 실패',
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

                // Selection overlay
                if (isSelected)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE040FB).withOpacity(0.4),
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
