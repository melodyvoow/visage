import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImagenService {
  static const String _apiKey = 'AIzaSyC5p5fxEqDBYWtA1Td2waIObaekDeixzik';
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

  /// 4가지 다른 컨셉으로 추구미 이미지를 병렬 생성합니다.
  static Future<List<Uint8List>> generateAestheticImages(
    String analyzedPrompt,
  ) async {
    final prompts = _buildConceptPrompts(analyzedPrompt);

    debugPrint('[Imagen] 4가지 컨셉 추구미 이미지 생성 시작');
    for (var i = 0; i < prompts.length; i++) {
      debugPrint('[Imagen] 컨셉 ${i + 1}: "${prompts[i]}"');
    }

    // 4개 프롬프트 병렬 호출
    final futures = prompts.map((prompt) => _generateSingleImage(prompt));
    final results = await Future.wait(futures);

    final images = results.whereType<Uint8List>().toList();
    debugPrint('[Imagen] 추구미 이미지 ${images.length}/4개 생성 성공');
    return images;
  }

  /// 단일 이미지 생성 (1:1)
  static Future<Uint8List?> _generateSingleImage(String prompt) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:predict');
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
          final base64String = (predictions.first
              as Map<String, dynamic>)['bytesBase64Encoded'] as String?;
          if (base64String != null) return base64Decode(base64String);
        }
      } else {
        debugPrint(
          '[Imagen] API 오류 [${response.statusCode}]: ${response.body}',
        );
      }
      return null;
    } catch (e) {
      debugPrint('[Imagen] 이미지 생성 예외: $e');
      return null;
    }
  }

  /// 4가지 컨셉 프롬프트 생성
  static List<String> _buildConceptPrompts(String userPrompt) {
    return [
      // 1. 컴카드 / 무드보드
      'Create a beautiful aesthetic comp card image that visually '
          'represents the style and mood of: "$userPrompt". '
          'Artistic, visually striking, high quality fashion/mood board style. '
          'No text overlays.',

      // 2. 추상 아트 / 컬러 텍스처
      'Abstract artistic interpretation of "$userPrompt". '
          'Expressive brushstrokes, rich color textures, and layered compositions. '
          'Fine art painting style with bold, emotional visual impact. '
          'No text, no people.',

      // 3. 미니멀 / 모던
      'Minimalist modern aesthetic inspired by "$userPrompt". '
          'Clean geometric composition with carefully curated color palette. '
          'Elegant negative space, subtle gradients, and refined simplicity. '
          'Contemporary design sensibility. No text.',

      // 4. 에디토리얼 / 시네마틱
      'Cinematic editorial photograph capturing the essence of "$userPrompt". '
          'Dramatic lighting with intentional color grading and atmospheric depth. '
          'High-end fashion editorial or film still quality. '
          'Evocative and visually compelling. No text overlays.',
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
