import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Nano Banana (Gemini Image Generation) 서비스
/// 추구미 이미지 + 상품 이미지를 기반으로 컴카드 레이아웃 추천 이미지를 생성합니다.
class NanoBananaService {
  static const String _apiKey = 'AIzaSyC5p5fxEqDBYWtA1Td2waIObaekDeixzik';
  static const String _model = 'gemini-3-pro-image-preview';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// 추구미 이미지와 상품 이미지를 기반으로 레이아웃 추천 이미지 4장을 생성합니다.
  static Future<List<Uint8List>> generateLayoutImages({
    required Uint8List aestheticImage,
    required List<Uint8List> productImages,
    String? userPrompt,
  }) async {
    final images = <Uint8List>[];

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[NanoBanana] 레이아웃 이미지 생성 시작');
    debugPrint('[NanoBanana] 추구미 이미지: ${aestheticImage.length} bytes');
    debugPrint('[NanoBanana] 상품 이미지: ${productImages.length}장');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 4장 병렬 생성
    final futures = List.generate(
      4,
      (i) => _generateSingleLayout(
        index: i,
        aestheticImage: aestheticImage,
        productImages: productImages,
        userPrompt: userPrompt,
      ),
    );

    final results = await Future.wait(futures);

    for (final result in results) {
      if (result != null) images.add(result);
    }

    debugPrint('[NanoBanana] 레이아웃 이미지 ${images.length}/4장 생성 완료');
    return images;
  }

  /// 단일 레이아웃 이미지 생성
  static Future<Uint8List?> _generateSingleLayout({
    required int index,
    required Uint8List aestheticImage,
    required List<Uint8List> productImages,
    String? userPrompt,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      // 프롬프트 구성
      final prompt = _buildLayoutPrompt(index: index, userPrompt: userPrompt);

      debugPrint('[NanoBanana] 레이아웃 #${index + 1} 프롬프트: "$prompt"');

      // 멀티모달 파츠 구성: 프롬프트 텍스트 + 추구미 이미지 + 상품 이미지들
      final parts = <Map<String, dynamic>>[];

      // 텍스트 프롬프트
      parts.add({'text': prompt});

      // 추구미 이미지 첨부
      parts.add({
        'inlineData': {
          'mimeType': 'image/png',
          'data': base64Encode(aestheticImage),
        },
      });

      // 상품 이미지들 첨부
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
          final content = candidates.first['content'] as Map<String, dynamic>?;
          final responseParts = content?['parts'] as List<dynamic>?;

          if (responseParts != null) {
            for (final part in responseParts) {
              final partMap = part as Map<String, dynamic>;

              // 텍스트 응답 로그
              if (partMap.containsKey('text')) {
                debugPrint(
                  '[NanoBanana] 레이아웃 #${index + 1} 텍스트: "${partMap['text']}"',
                );
              }

              // 이미지 응답 추출
              if (partMap.containsKey('inlineData')) {
                final inlineData =
                    partMap['inlineData'] as Map<String, dynamic>;
                final base64String = inlineData['data'] as String?;

                if (base64String != null) {
                  debugPrint('[NanoBanana] 레이아웃 #${index + 1} 이미지 생성 성공');
                  return base64Decode(base64String);
                }
              }
            }
          }
        }

        debugPrint('[NanoBanana] 레이아웃 #${index + 1} 응답에 이미지 없음');
      } else {
        debugPrint(
          '[NanoBanana] 레이아웃 #${index + 1} API 오류 '
          '[${response.statusCode}]: ${response.body}',
        );
      }

      return null;
    } catch (e) {
      debugPrint('[NanoBanana] 레이아웃 #${index + 1} 생성 예외: $e');
      return null;
    }
  }

  /// 레이아웃 추천 프롬프트 생성
  /// TODO: 사용자가 나중에 프롬프트를 세팅할 예정
  static String _buildLayoutPrompt({required int index, String? userPrompt}) {
    final basePrompt = userPrompt ?? '';
    final extraContext = basePrompt.isNotEmpty ? ' Theme: "$basePrompt".' : '';

    return 'You are a professional comp card designer. '
        'Using the provided aesthetic reference image (Image 1) and '
        'product/model images (remaining images), '
        'create a visually compelling comp card layout design.$extraContext '
        'The layout should be a complete, production-ready comp card composition '
        'that harmoniously combines the aesthetic mood with the product images. '
        'Output ONLY the final comp card image, no explanations. '
        'Variation ${index + 1} of 4 — explore a different creative layout direction.';
  }
}
