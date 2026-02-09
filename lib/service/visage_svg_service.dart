import 'package:flutter/foundation.dart';
import 'package:nyx_kernel/nyx_kernel.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxVector/nyx_vector_ux_card.dart';
import 'package:visage/view/Creation/visage_creation_types.dart';

/// Visage SVG 생성 + 업로드 서비스
///
/// kernel의 NyxAI.generateSvg() + NyxVectorFirecatCrudController.createVector()를 활용합니다.
/// 추구미(무드보드) + 디자인 레이아웃 + 사용자 프롬프트를 결합하여 SVG를 생성하고 NyxVector에 업로드합니다.
class VisageSvgService {
  VisageSvgService._();

  /// SVG 1장 생성 + NyxVector 업로드
  ///
  /// 반환: NyxVectorUXThumbCardStore (업로드된 벡터 카드)
  static Future<NyxVectorUXThumbCardStore?> generateAndUpload({
    required String moodKeywords,
    required DesignStyle designStyle,
    required String userPrompt,
    required String layoutPrompt,
    required String userId,
    void Function(String state)? onState,
  }) async {
    try {
      // 1. 프롬프트 구성
      final combinedPrompt = _buildPrompt(
        moodKeywords: moodKeywords,
        designStyle: designStyle,
        userPrompt: userPrompt,
        layoutPrompt: layoutPrompt,
      );

      final layoutName = _designStyleName(designStyle);

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('[SVG] 생성 시작');
      debugPrint('[SVG] 스타일: $layoutName');
      debugPrint('[SVG] 무드: $moodKeywords');
      debugPrint('[SVG] 프롬프트 길이: ${combinedPrompt.length}자');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // 2. NyxAI.generateSvg() 호출
      onState?.call('AI가 SVG 디자인을 생성하고 있어요...');

      final svgResult = await NyxAI.generateSvg(
        prompt: combinedPrompt,
        ratio: '16:9',
        temperature: 0.7,
      );

      if (svgResult.svgCode.isEmpty) {
        debugPrint('[SVG] SVG 코드 비어있음');
        onState?.call('SVG 생성 실패');
        return null;
      }

      debugPrint('[SVG] SVG 생성 완료: ${svgResult.svgCode.length}자');

      // 3. NyxVectorFirecatCrudController.createVector()로 업로드
      onState?.call('SVG를 업로드하고 있어요...');

      final vectorCard = await NyxVectorFirecatCrudController.createVector(
        userId,
        svgResult.svgCode,
        1920,
        1080,
        userPrompt,
        combinedPrompt.substring(0, combinedPrompt.length.clamp(0, 500)),
        '16:9',
        designStyle.name,
        (state) {
          debugPrint('[SVG Upload] $state');
          onState?.call(state);
        },
      );

      if (vectorCard != null) {
        debugPrint('[SVG] 업로드 완료: ${vectorCard.documentRef?.id}');
        onState?.call('SVG 저장 완료!');
      } else {
        debugPrint('[SVG] 업로드 실패');
        onState?.call('SVG 업로드 실패');
      }

      return vectorCard;
    } on AiException catch (e) {
      debugPrint('[SVG] AiException: ${e.message}');
      onState?.call(e.userMessage);
      return null;
    } catch (e) {
      debugPrint('[SVG] 예외: $e');
      onState?.call('오류 발생: $e');
      return null;
    }
  }

  // ── Private Helpers ──

  /// 디자인 스타일 → 한국어 이름
  static String _designStyleName(DesignStyle style) {
    return switch (style) {
      DesignStyle.softRound => '디자인 레이아웃1 (소프트 라운드)',
      DesignStyle.sharpGrid => '디자인 레이아웃2 (샤프 그리드)',
      DesignStyle.editorial => '디자인 레이아웃3 (에디토리얼)',
    };
  }

  /// 통합 프롬프트 구성
  ///
  /// [무드보드] 키워드 + [디자인 레이아웃] + [사용자 프롬프트]를 결합합니다.
  static String _buildPrompt({
    required String moodKeywords,
    required DesignStyle designStyle,
    required String userPrompt,
    required String layoutPrompt,
  }) {
    final layoutName = _designStyleName(designStyle);
    final layoutDna = _layoutDna(designStyle);

    return '''
[무드보드] Color & Mood Keywords: $moodKeywords
Extract and apply these colors, gradients, textures, and atmosphere to ALL design elements.

[디자인 레이아웃] Selected: $layoutName
$layoutDna

Layout Detail: $layoutPrompt

[사용자 프롬프트]: $userPrompt

TASK: Generate a complete, production-ready 16:9 SVG comp card design.

SVG Requirements:
- ViewBox: 0 0 1920 1080 (16:9)
- Apply [무드보드] colors/gradients to [$layoutName] structure
- All decorative elements fully realized as SVG paths
- NO CSS - inline attributes only
- Include ALL shadows via feDropShadow filter in <defs>
- Label image placeholders clearly (Image_1, Image_2...)
- 98%+ visual fidelity, zero placeholder shortcuts
''';
  }

  /// 디자인 레이아웃 DNA 규칙
  static String _layoutDna(DesignStyle style) {
    return switch (style) {
      DesignStyle.softRound =>
        '''
Design DNA:
- Rounded corners (rx=16-24 cards, rx=12-16 images)
- Generous spacing (40-60px gaps, 120px margins)
- Typography: Arial/Helvetica, weights 400-600
- Soft shadows (dx=0, dy=8, blur=16, opacity=0.08-0.12)
- Asymmetric grids (60/40 splits), 70%+ whitespace
- Decorative: gradient blobs, abstract shapes, dot patterns
- Floating card-based structure''',
      DesignStyle.sharpGrid =>
        '''
Design DNA:
- Sharp corners (rx=0) or subtle (rx=4-8)
- Tight spacing (20-30px gaps), maximized content density
- Typography: Serif + Sans hybrid, weights 700-900, uppercase headers
- Hard shadows (dx=4, dy=4, blur=8, opacity=0.15-0.25)
- Strict 12-column modular grid (160px columns)
- Decorative: ruled lines (1-2px), geometric frames, grid textures
- High contrast, monochromatic + single accent color''',
      DesignStyle.editorial =>
        '''
Design DNA:
- Organic curves, irregular clipping paths, asymmetric compositions
- Varied spacing (20-150px), intentional asymmetry for rhythm
- Typography: Serif fonts (Georgia, Times), script accents, scale contrast 24-120px
- Soft glows (blur=20-40, opacity=0.1-0.2), subtle vignettes
- Broken grid, overlapping layers, negative space as design element
- Decorative: flowing curves, serif ornaments, gradient overlays, organic blob masks
- Muted tones OR high contrast B&W with gold accents''',
    };
  }
}
