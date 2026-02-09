import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nyx_kernel/Firecat/viewmodel/NyxUpload/nyx_upload_firecat_crud_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxUpload/nyx_upload_ux_card.dart';
import 'package:visage/service/svg_to_image.dart' as svg_renderer;
import 'package:visage/view/Creation/visage_creation_types.dart';

/// Visage SVG 생성 + 업로드 서비스
///
/// Gemini로 SVG를 생성한 뒤,
/// 브라우저 Canvas로 SVG → PNG 렌더링 → NyxUploadFirecatCrudController.uploadFile()로 업로드합니다.
class VisageSvgService {
  VisageSvgService._();

  static const String _apiKey = 'AIzaSyAVGK1hJQtUGCwTfjV7Zu7SuF0TBpuISKg';
  static const String _model = 'gemini-3-pro-preview';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// SVG 1장 생성 + 이미지 업로드
  ///
  /// [layoutImage]가 제공되면 Gemini에 시각적 레퍼런스로 함께 전달됩니다.
  /// 반환: NyxUploadUXThumbCardStore (업로드된 이미지 카드)
  static Future<NyxUploadUXThumbCardStore?> generateAndUpload({
    required String moodKeywords,
    required DesignStyle designStyle,
    required String userPrompt,
    required String layoutPrompt,
    required String userId,
    Uint8List? layoutImage,
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
      debugPrint('[SVG] 레이아웃 이미지: ${layoutImage != null ? "${layoutImage.length} bytes" : "없음"}');
      debugPrint('[SVG] 프롬프트 길이: ${combinedPrompt.length}자');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // 2. Gemini로 SVG 생성 (레이아웃 이미지를 시각적 레퍼런스로 포함)
      onState?.call('AI is generating SVG design...');

      final svgCode = await _generateSvgWithGemini(
        combinedPrompt,
        layoutImage: layoutImage,
      );

      if (svgCode == null || svgCode.isEmpty) {
        debugPrint('[SVG] SVG 코드 비어있음');
        onState?.call('SVG generation failed');
        return null;
      }

      debugPrint('[SVG] SVG 생성 완료: ${svgCode.length}자');

      // 3. SVG → PNG 렌더링 (브라우저 네이티브 Canvas)
      onState?.call('Converting SVG to image...');

      final imageBytes = await svg_renderer.renderSvgToPng(svgCode, 1080);
      if (imageBytes == null) {
        debugPrint('[SVG] 이미지 렌더링 실패');
        onState?.call('SVG image conversion failed');
        return null;
      }

      debugPrint('[SVG] 이미지 렌더링 완료: ${imageBytes.length} bytes');

      // 4. NyxUploadFirecatCrudController.uploadFile()로 업로드
      onState?.call('Uploading image...');

      final platformFile = PlatformFile(
        name: 'visage_svg_${DateTime.now().millisecondsSinceEpoch}.png',
        size: imageBytes.length,
        bytes: imageBytes,
      );

      final uploadResult = await NyxUploadFirecatCrudController.uploadFile(
        userId,
        platformFile,
        (progress) {
          debugPrint('[SVG Upload] $progress');
          onState?.call(progress);
        },
      );

      if (uploadResult != null) {
        debugPrint('[SVG] 업로드 완료: ${uploadResult.uploadData?.ee_file_url}');
        onState?.call('SVG saved!');
      } else {
        debugPrint('[SVG] 업로드 실패');
        onState?.call('SVG upload failed');
      }

      return uploadResult;
    } catch (e) {
      debugPrint('[SVG] 예외: $e');
      onState?.call('Error: $e');
      return null;
    }
  }

  // ── Private Helpers ──

  /// Gemini로 SVG 코드 직접 생성
  ///
  /// [layoutImage]가 제공되면 텍스트 프롬프트와 함께 multimodal 입력으로 전달하여
  /// 레이아웃 이미지의 시각적 구조를 SVG에 반영합니다.
  static Future<String?> _generateSvgWithGemini(
    String prompt, {
    Uint8List? layoutImage,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      // parts 구성: 레이아웃 이미지가 있으면 시각적 레퍼런스로 포함
      final List<Map<String, dynamic>> parts = [];

      if (layoutImage != null) {
        parts.add({
          'inlineData': {
            'mimeType': 'image/png',
            'data': base64Encode(layoutImage),
          },
        });
        parts.add({
          'text':
              '[레이아웃 레퍼런스] 위 이미지는 선택된 레이아웃 디자인입니다. '
              '이 레이아웃의 시각적 구조, 요소 배치, 비율, 여백을 정확히 반영하여 SVG를 생성하세요.\n\n'
              '$prompt',
        });
      } else {
        parts.add({'text': prompt});
      }

      final body = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 65536},
      };

      debugPrint('[SVG/Gemini] API 호출 시작 (prompt: ${prompt.length}자, 이미지: ${layoutImage != null})');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[SVG/Gemini] API 오류 [${response.statusCode}]: ${response.body}',
        );
        return null;
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = result['candidates'] as List<dynamic>?;

      if (candidates == null || candidates.isEmpty) {
        debugPrint('[SVG/Gemini] 응답에 candidates 없음');
        return null;
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final responseParts = content?['parts'] as List<dynamic>?;

      if (responseParts == null || responseParts.isEmpty) {
        debugPrint('[SVG/Gemini] 응답에 parts 없음');
        return null;
      }

      String text = (responseParts.first['text'] as String).trim();
      debugPrint('[SVG/Gemini] 응답 길이: ${text.length}자');

      // 마크다운 코드 블록에서 SVG 추출
      final svgBlockMatch = RegExp(
        r'```(?:svg|xml)?\s*\n?([\s\S]*?)```',
        caseSensitive: false,
      ).firstMatch(text);

      if (svgBlockMatch != null) {
        text = svgBlockMatch.group(1)!.trim();
        debugPrint('[SVG/Gemini] 코드 블록에서 SVG 추출 완료');
      }

      // <svg 태그 시작점 찾기
      final svgStart = text.indexOf('<svg');
      if (svgStart == -1) {
        debugPrint('[SVG/Gemini] <svg> 태그를 찾을 수 없음');
        return null;
      }

      // </svg> 끝점 찾기
      final svgEnd = text.lastIndexOf('</svg>');
      if (svgEnd == -1) {
        debugPrint('[SVG/Gemini] </svg> 닫는 태그를 찾을 수 없음');
        return null;
      }

      final svgCode = text.substring(svgStart, svgEnd + 6);
      debugPrint('[SVG/Gemini] SVG 추출 완료: ${svgCode.length}자');

      return svgCode;
    } catch (e) {
      debugPrint('[SVG/Gemini] 예외: $e');
      return null;
    }
  }

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
- Inline attributes preferred (fill, stroke, opacity, etc.)
- Include shadows via feDropShadow filter in <defs> if needed
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
