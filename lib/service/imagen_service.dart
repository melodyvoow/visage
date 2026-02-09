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

  /// 마스터 프롬프트로 4장의 다양한 컨셉 추구미 이미지를 생성합니다.
  static Future<List<Uint8List>> generateAestheticImages(
    String analyzedPrompt,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:predict');
      final prompt = _buildMasterPrompt(analyzedPrompt);

      debugPrint('[Imagen] 마스터 프롬프트: "$prompt"');

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
          'parameters': {'sampleCount': 4, 'aspectRatio': '1:1'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final predictions = data['predictions'] as List<dynamic>?;

        if (predictions != null) {
          debugPrint('[Imagen] 추구미 이미지 ${predictions.length}개 생성 성공');
          return predictions
              .map(
                (p) => base64Decode(
                  (p as Map<String, dynamic>)['bytesBase64Encoded'] as String,
                ),
              )
              .toList();
        }
        debugPrint('[Imagen] 추구미 이미지 생성 실패: predictions가 비어있음');
      } else {
        debugPrint(
          '[Imagen] 추구미 API 오류 [${response.statusCode}]: ${response.body}',
        );
      }

      return [];
    } catch (e) {
      debugPrint('[Imagen] 추구미 이미지 생성 예외: $e');
      return [];
    }
  }

  /// 컬러/무드에 집중한 추구미 마스터 프롬프트
  static String _buildMasterPrompt(String userPrompt) {
    return 'Create a beautiful aesthetic image that purely expresses '
        'the color palette and mood of: "$userPrompt". '
        'Focus on rich colors, tones, textures, lighting, and atmosphere. '
        'Each image should explore a different color and mood interpretation. '
        'No layout, no composition structure, no text overlays. '
        'Pure visual mood and color expression only.';
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
