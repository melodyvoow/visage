import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:visage/view/Creation/visage_creation_types.dart';

/// Nano Banana (Gemini Image Generation) 서비스
class NanoBananaService {
  static const String _apiKey = 'AIzaSyC5p5fxEqDBYWtA1Td2waIObaekDeixzik';
  static const String _model = 'gemini-3-pro-image-preview';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// 선택된 스타일 + 추천된 레이아웃 인덱스들로 이미지를 생성합니다.
  static Future<List<Uint8List>> generateLayoutImages({
    required Uint8List aestheticImage,
    required List<Uint8List> productImages,
    required DesignStyle style,
    required List<int> layoutIndices,
    String? userPrompt,
  }) async {
    final prompts = _layoutPrompts[style]!;

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[NanoBanana] 레이아웃 이미지 생성 시작');
    debugPrint('[NanoBanana] 스타일: ${style.label}');
    debugPrint('[NanoBanana] 추천 인덱스: $layoutIndices');
    debugPrint('[NanoBanana] 추구미 이미지: ${aestheticImage.length} bytes');
    debugPrint('[NanoBanana] 상품 이미지: ${productImages.length}장');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 추천된 인덱스의 프롬프트만 병렬 생성
    final futures = layoutIndices.map((idx) {
      final prompt = prompts[idx].replaceAll(
        '[사용자 프롬프트]',
        userPrompt ?? 'modern aesthetic',
      );
      return _generateSingleImage(
        prompt: prompt,
        aestheticImage: aestheticImage,
        productImages: productImages,
        label: 'Visage_${idx + 1}',
      );
    });

    final results = await Future.wait(futures);
    final images = results.whereType<Uint8List>().toList();

    debugPrint(
      '[NanoBanana] 레이아웃 이미지 ${images.length}/${layoutIndices.length}장 생성 완료',
    );
    return images;
  }

  /// 스타일 대표 이미지 3장 생성 (스타일 선택 화면용)
  static Future<List<Uint8List>> generateStylePreviews({
    required Uint8List aestheticImage,
    String? userPrompt,
  }) async {
    debugPrint('[NanoBanana] 스타일 대표 이미지 3장 생성 시작');

    final futures = DesignStyle.values.map((style) {
      // 각 스타일의 첫 번째 프롬프트를 대표로 사용
      final prompt = _layoutPrompts[style]![0].replaceAll(
        '[사용자 프롬프트]',
        userPrompt ?? 'modern aesthetic',
      );
      return _generateSingleImage(
        prompt: prompt,
        aestheticImage: aestheticImage,
        productImages: [],
        label: style.label,
      );
    });

    final results = await Future.wait(futures);
    final images = results.whereType<Uint8List>().toList();

    debugPrint('[NanoBanana] 스타일 프리뷰 ${images.length}/3장 생성 완료');
    return images;
  }

  /// 단일 이미지 생성 (공통)
  static Future<Uint8List?> _generateSingleImage({
    required String prompt,
    required Uint8List aestheticImage,
    required List<Uint8List> productImages,
    required String label,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      debugPrint('[NanoBanana] $label 프롬프트: "${prompt.substring(0, prompt.length.clamp(0, 80))}..."');

      final parts = <Map<String, dynamic>>[];

      parts.add({'text': prompt});

      // 추구미 이미지
      parts.add({
        'inlineData': {
          'mimeType': 'image/png',
          'data': base64Encode(aestheticImage),
        },
      });

      // 상품 이미지
      for (final img in productImages) {
        parts.add({
          'inlineData': {'mimeType': 'image/png', 'data': base64Encode(img)},
        });
      }

      final body = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {
          'responseModalities': ['TEXT', 'IMAGE'],
          'imageConfig': {'aspectRatio': '16:9'},
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = result['candidates'] as List<dynamic>?;

        if (candidates != null && candidates.isNotEmpty) {
          final content =
              candidates.first['content'] as Map<String, dynamic>?;
          final responseParts = content?['parts'] as List<dynamic>?;

          if (responseParts != null) {
            for (final part in responseParts) {
              final partMap = part as Map<String, dynamic>;
              if (partMap.containsKey('text')) {
                debugPrint('[NanoBanana] $label 텍스트: "${partMap['text']}"');
              }
              if (partMap.containsKey('inlineData')) {
                final inlineData =
                    partMap['inlineData'] as Map<String, dynamic>;
                final base64String = inlineData['data'] as String?;
                if (base64String != null) {
                  debugPrint('[NanoBanana] $label 이미지 생성 성공');
                  return base64Decode(base64String);
                }
              }
            }
          }
        }
        debugPrint('[NanoBanana] $label 응답에 이미지 없음');
      } else {
        debugPrint(
          '[NanoBanana] $label API 오류 [${response.statusCode}]: ${response.body}',
        );
      }
      return null;
    } catch (e) {
      debugPrint('[NanoBanana] $label 생성 예외: $e');
      return null;
    }
  }

  /// 특정 스타일의 레이아웃 설명 목록 반환 (Gemini 추천용)
  static List<String> getLayoutDescriptions(DesignStyle style) {
    return _layoutPrompts[style]!;
  }

  // ================================================================
  // 레이아웃 프롬프트 (3 스타일 × 9 변형 = 27개)
  // ================================================================

  static const Map<DesignStyle, List<String>> _layoutPrompts = {
    // ── 소프트 라운드 ──
    DesignStyle.softRound: [
      // Visage_1
      'Minimalist website hero section, rounded card UI aesthetic. Central focal point is a large, rounded rectangular glassmorphism card containing the main title typography and a soft abstract 3D shape. Background is a clean, matte surface with subtle gradient lighting inspired by [사용자 프롬프트]. Floating UI elements, soft drop shadows, clean sans-serif font, friendly and modern tech vibe.',
      // Visage_2
      'Split-screen web interface, soft card style. Two large rounded modules separated by generous whitespace gutter. Left module is a clean white card with bold sans-serif heading and description. Right module is a rounded image card featuring atmospheric photography related to [사용자 프롬프트]. Soft diffuse shadows, floating effect, balanced padding, modern UI layout.',
      // Visage_3
      'A flat-lay UI presentation, bento box grid layout. A composition of distinct rounded square and rectangular cards. Mixed content: one card with large typography, one card with an icon, and others with product photos related to [사용자 프롬프트]. Soft blurred shadows behind cards, uniform gaps, frosted glass accents, pastel color palette inspired by [사용자 프롬프트].',
      // Visage_4
      'Feature highlight section, asymmetrical split layout. A large, dominant rounded card on the left in a vibrant solid color inspired by [사용자 프롬프트] with white text. To the right, a vertical stack of smaller rounded image cards showing details. All corners are rounded. Smooth gradients, depth created by layering and shadows, modern app store aesthetic.',
      // Visage_5
      'Mobile app showcase slide, triple arch layout within rounded containers. Three vertical smartphone-shaped masks displaying images. Background features soft mesh gradients in colors inspired by [사용자 프롬프트]. Floating 3D interaction icons, soft lighting, dreamy and polished UI feel.',
      // Visage_6
      'Complex dashboard interface, dense bento grid system. Multiple rounded widget cards arranged perfectly. Includes data visualization charts, profile avatars, and status indicators related to [사용자 프롬프트]. Glassmorphism effects on overlay panels. Light gray background, high-end tech agency aesthetic, clean and organized.',
      // Visage_7
      'Modern editorial blog section, card-based layout. Large serif typography contained within a soft rounded text bubble. Overlapping rounded image cards scattered slightly off-grid to create a dynamic feel. Soft depth of field, warm lighting, color theme inspired by [사용자 프롬프트].',
      // Visage_8
      'Gallery wall interface, masonry grid with rounded corners. A collection of photographs related to [사용자 프롬프트] with varying aspect ratios, all having consistent corner radius. Soft white borders around images. Hover-state effects simulated with slight elevation and shadow. Clean, gallery-like whitespace.',
      // Visage_9
      'Website footer design, large rounded container. Dark mode card spanning full width with rounded corners. Contains minimal navigation links, social icons, and a "Subscribe" button in a contrasting color inspired by [사용자 프롬프트]. Clean sans-serif typography, final call to action, polished finish.',
    ],

    // ── 샤프 그리드 ──
    DesignStyle.sharpGrid: [
      // Visage_1
      'Corporate brand identity hero section, strict Swiss grid system. Full-width layout divided by thin black 1px lines. Massive, bold Helvetica typography aligned left. A single, sharp-edged cinematic photo related to [사용자 프롬프트] occupies the right third. High contrast, no shadows, flat design, structural and architectural look.',
      // Visage_2
      'Split-screen layout, divided by a visible vertical stroke. Left side is solid white with strictly aligned text blocks. Right side is a full-bleed black and white grainy photograph. Zero padding at the edges, sharp corners. Brutalist aesthetic, functional typography, color theme inspired by [사용자 프롬프트].',
      // Visage_3
      'Modular grid layout, wireframe aesthetic. The screen is divided into exact squares by visible grid lines. Cells contain a mix of solid color blocks inspired by [사용자 프롬프트], stark typographic numbers, and high-contrast monochrome images. Bauhaus influence, geometric precision, no gaps between modules.',
      // Visage_4
      'Exhibition poster style, bold vertical split. 70% of the screen is a solid vibrant color block inspired by [사용자 프롬프트] with giant vertical text. 30% is a sharp vertical image strip. Hard edges, intersectional layout, international typographic style, impactful and loud.',
      // Visage_5
      'Geometric showcase, arch and rectangle combination. Sharp rectangular frames containing images, contrasted with a single perfect semi-circle geometric shape in a solid color. Thin vector lines connecting elements like a blueprint. Technical diagram aesthetic, precise and calculated.',
      // Visage_6
      'Data grid layout, spreadsheet aesthetic. Tightly packed rectangular modules separated only by thin borders. No gaps, no rounded corners. Content includes technical schematics, raw data text, and desaturated images related to [사용자 프롬프트]. Industrial vibe, utilitarian design, monochromatic with one accent color.',
      // Visage_7
      'Newspaper editorial layout, multi-column text. Justified serif typography in narrow columns. Sharp rectangular images interrupting the text flow. Horizontal divider lines. Classical yet brutalist structure, minimal and information-heavy, inspired by [사용자 프롬프트].',
      // Visage_8
      'Mosaic image grid, edge-to-edge layout. Images touch each other with no whitespace. A mix of macro details and wide shots related to [사용자 프롬프트]. A superimposed white wireframe grid layer sits on top of the images. Artistic, raw, and unpolished vibe.',
      // Visage_9
      'Minimalist footer section, grid-based. A solid horizontal block divided into four equal vertical columns by lines. Each column contains list-style text. Large oversized logo at the bottom. Stark contrast, black text on white background, disciplined structure.',
    ],

    // ── 에디토리얼 ──
    DesignStyle.editorial: [
      // Visage_1
      'High-fashion website hero, artistic collage style. A central cutout image of a model or object related to [사용자 프롬프트] interacts with large, elegant serif typography. The text weaves behind and in front of the image. Background is a textured cream paper. Organic composition, negative space, luxury magazine vibe.',
      // Visage_2
      'Asymmetrical editorial split. Left side features a large, poetic serif quote with ample breathing room. Right side features an image masked in an organic shape (pill or blob) rather than a square. Background texture of grain or noise. Artistic direction, subtle overlaps, color theme inspired by [사용자 프롬프트].',
      // Visage_3
      'Deconstructed grid layout. Images and text blocks are scattered loosely, overlapping slightly. A mix of rectangular and circular image masks. Scotch tape or paper clip graphical elements holding the "photos". Moodboard aesthetic, fashion curation, beige and earth tones inspired by [사용자 프롬프트].',
      // Visage_4
      'Conceptual split layout. One half is a blurred, atmospheric abstract background color inspired by [사용자 프롬프트]. The other half is a sharp, high-definition macro shot. A thin, elegant italic font bridges the two halves. Sophisticated, mysterious, visual storytelling.',
      // Visage_5
      'Triple archway portfolio slide. Three tall, narrow images masked in classic roman arch shapes. Background is a solid, muted luxury color. Fine line vectors decorate the spaces between arches. Minimalist caption text below each arch. Museum curation aesthetic, timeless and elegant.',
      // Visage_6
      'Scrapbook style bento layout. Grid modules look like polaroids or printed photos arranged on a surface. Handwritten notes and doodle elements in the margins. A mix of color photos and black and white sketches related to [사용자 프롬프트]. Personal, warm, and creative atmosphere.',
      // Visage_7
      'Luxury editorial feature. Massive serif headline that breaks the grid, spanning across the entire width. Below it, a collage of images in varying sizes, some overlapping the text. Generous cream whitespace. Fine art photography style, sophisticated and expensive look.',
      // Visage_8
      'Abstract shapes image grid. Images are masked into circles, semicircles, and long pill shapes. They are arranged in a floating pattern connected by thin decorative lines (sunburst or constellation style). Central focus is a solid color circle with text. Avant-garde design, creative and unique.',
      // Visage_9
      'Brand conclusion section. A large, centered circular image or logo mark. The background is a soft, grainy gradient. Elegant "Thank You" typography in script or serif font. Minimalist social links arranged in a curve or circle. Soft ending, emotional connection.',
    ],
  };
}
