import 'package:flutter/material.dart';
import 'package:visage/view/Creation/visage_creation_types.dart';

class VisageStyleSelectionStep extends StatefulWidget {
  final void Function(DesignStyle style) onStyleSelected;

  const VisageStyleSelectionStep({
    super.key,
    required this.onStyleSelected,
  });

  @override
  State<VisageStyleSelectionStep> createState() =>
      _VisageStyleSelectionStepState();
}

class _VisageStyleSelectionStepState extends State<VisageStyleSelectionStep> {
  DesignStyle? _selected;
  int _hoveredIndex = -1;

  static const _styleIcons = [
    Icons.rounded_corner_rounded,
    Icons.grid_on_rounded,
    Icons.auto_awesome_mosaic_rounded,
  ];

  static const _stylePreviewColors = <DesignStyle, List<Color>>{
    DesignStyle.softRound: [Color(0xFF6366F1), Color(0xFFA78BFA)],
    DesignStyle.sharpGrid: [Color(0xFF1E293B), Color(0xFF475569)],
    DesignStyle.editorial: [Color(0xFFBE185D), Color(0xFFF472B6)],
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Text(
                '디자인 스타일을 선택해주세요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI가 선택한 스타일에 맞는 최적의 레이아웃을 추천해드릴게요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // 3 Style cards
              Row(
                children: DesignStyle.values.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final style = entry.value;
                  final isSelected = _selected == style;
                  final isHovered = _hoveredIndex == idx;
                  final colors = _stylePreviewColors[style]!;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: idx == 0 ? 0 : 8,
                        right: idx == 2 ? 0 : 8,
                      ),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _hoveredIndex = idx),
                        onExit: (_) => setState(() => _hoveredIndex = -1),
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = style),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            transform: Matrix4.identity()
                              ..translate(
                                0.0,
                                isSelected ? -4.0 : (isHovered ? -2.0 : 0.0),
                              ),
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
                                        color: const Color(0xFFE040FB)
                                            .withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Column(
                                children: [
                                  // Preview gradient area
                                  Container(
                                    height: 140,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: colors,
                                      ),
                                    ),
                                    child: Center(
                                      child: _buildStylePreview(style),
                                    ),
                                  ),

                                  // Info area
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.06),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              _styleIcons[idx],
                                              color: Colors.white
                                                  .withOpacity(0.8),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              style.label,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          style.description,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withOpacity(0.4),
                                            fontSize: 12,
                                            height: 1.4,
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
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Confirm button
              GestureDetector(
                onTap: _selected != null
                    ? () => widget.onStyleSelected(_selected!)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: _selected != null
                        ? const LinearGradient(
                            colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                          )
                        : null,
                    color: _selected != null
                        ? null
                        : Colors.white.withOpacity(0.05),
                    boxShadow: _selected != null
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF7B2FBE).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '이 스타일로 레이아웃 추천받기',
                    style: TextStyle(
                      color: _selected != null
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 각 스타일의 미리보기 아이콘/도형
  Widget _buildStylePreview(DesignStyle style) {
    switch (style) {
      case DesignStyle.softRound:
        // 둥근 카드 스타일 미리보기
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 48,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        );

      case DesignStyle.sharpGrid:
        // 샤프한 그리드 미리보기
        return SizedBox(
          width: 96,
          height: 64,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case DesignStyle.editorial:
        // 에디토리얼/콜라주 미리보기
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            Positioned(
              left: 32,
              top: -8,
              child: Container(
                width: 40,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 28,
              child: Container(
                width: 48,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        );
    }
  }
}
