import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImagenService {
  static const String _apiKey = 'AIzaSyAVGK1hJQtUGCwTfjV7Zu7SuF0TBpuISKg';
  static const String _model = 'imagen-4.0-generate-001';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// 사용자의 추구미 프롬프트를 기반으로 배경 이미지를 생성합니다.
  static Future<Uint8List?> generateBackground(String analyzedPrompt) async {
    try {
      final bgPrompt = _buildBackgroundPrompt(analyzedPrompt);
      debugPrint('[Imagen] 배경 생성 프롬프트: "$bgPrompt"');
      final url = Uri.parse('$_baseUrl/$_model:predict');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'instances': [
            {'prompt': bgPrompt},
          ],
          'parameters': {'sampleCount': 1, 'aspectRatio': '16:9'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final predictions = data['predictions'] as List<dynamic>?;

        if (predictions != null && predictions.isNotEmpty) {
          final imageData = predictions.first as Map<String, dynamic>;
          final base64String = imageData['bytesBase64Encoded'] as String?;

          if (base64String != null) {
            debugPrint(
              '[Imagen] 배경 이미지 생성 성공 (${base64String.length} bytes base64)',
            );
            return base64Decode(base64String);
          }
        }
        debugPrint('[Imagen] 배경 이미지 생성 실패: predictions가 비어있음');
      } else {
        debugPrint(
          '[Imagen] 배경 API 오류 [${response.statusCode}]: ${response.body}',
        );
      }

      return null;
    } catch (e) {
      debugPrint('[Imagen] 배경 생성 예외: $e');
      return null;
    }
  }

  /// 4개의 서로 다른 프롬프트로 각각 1장씩 병렬 생성합니다.
  static Future<List<Uint8List>> generateAestheticImages(
    String analyzedPrompt,
  ) async {
    final prompts = _buildVariedPrompts(analyzedPrompt);
    final url = Uri.parse('$_baseUrl/$_model:predict');

    // 4개 프롬프트를 동시에 병렬 호출
    final futures = prompts.asMap().entries.map((entry) async {
      final idx = entry.key;
      final prompt = entry.value;
      debugPrint('[Imagen] 추구미 #${idx + 1} 프롬프트: "$prompt"');

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'instances': [
              {'prompt': prompt},
            ],
            'parameters': {'sampleCount': 1, 'aspectRatio': '1:1'},
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final predictions = data['predictions'] as List<dynamic>?;

          if (predictions != null && predictions.isNotEmpty) {
            final base64String =
                (predictions.first
                        as Map<String, dynamic>)['bytesBase64Encoded']
                    as String?;
            if (base64String != null) {
              debugPrint('[Imagen] 추구미 #${idx + 1} 생성 성공');
              return base64Decode(base64String);
            }
          }
        } else {
          debugPrint(
            '[Imagen] 추구미 #${idx + 1} API 오류 [${response.statusCode}]: '
            '${response.body}',
          );
        }
      } catch (e) {
        debugPrint('[Imagen] 추구미 #${idx + 1} 예외: $e');
      }
      return null;
    }).toList();

    final results = await Future.wait(futures);
    final images = results.whereType<Uint8List>().toList();
    debugPrint('[Imagen] 추구미 이미지 총 ${images.length}/4장 생성 완료');
    return images;
  }

  /// 4가지 서로 다른 디자인 방향의 프롬프트를 생성합니다.
  static List<String> _buildVariedPrompts(String analyzedPrompt) {
    const base =
        'No text, no watermarks, no visible grids. '
        'High resolution, editorial quality, professional photography aesthetic.';

    return [
      // 1) 무드보드 콜라주
      'An organic collage-style mood board inspired by: "$analyzedPrompt". '
          'Overlapping photos, torn paper edges, polaroids, color swatches, '
          'fabric samples, dried flowers, and textures arranged naturally '
          'on a surface. NO GRID LINES, seamlessly blended composition. '
          'Overhead flat-lay shot, scrapbook feel. $base',

      // 2) 시네마틱 풍경
      'A sweeping cinematic landscape or atmospheric environment '
          'capturing the mood of: "$analyzedPrompt". '
          'Dramatic natural lighting, depth of field, golden hour or '
          'moody blue tones, vast scale and emotional atmosphere. '
          'Film grain, widescreen cinematic photography feel. $base',

      // 3) 추상 아트
      'An expressive abstract art piece expressing: "$analyzedPrompt". '
          'Bold brushstrokes, fluid acrylic pours, ink bleeds, '
          'watercolor washes, or geometric color blocking. '
          'Purely artistic and non-representational. '
          'Contemporary art gallery style. $base',

      // 4) 스틸라이프 클로즈업
      'An intimate macro close-up of carefully arranged objects '
          'reflecting: "$analyzedPrompt". '
          'Natural materials, delicate textures like linen or ceramics, '
          'botanical elements, soft window light, shallow depth of field. '
          'Styled like a professional still life photograph. $base',
    ];
  }

  /// 분석된 프롬프트를 배경 이미지용으로 변환합니다.
  static String _buildBackgroundPrompt(String analyzedPrompt) {
    return 'Create an abstract atmospheric background that captures '
        'the mood and essence of: "$analyzedPrompt". '
        'Soft, ethereal, dreamy quality with beautiful color gradients. '
        'No text, no people, no faces. '
        'Blurred artistic background suitable as wallpaper. '
        'High quality, 16:9 wide format.';
  }
}
