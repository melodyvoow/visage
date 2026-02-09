import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImagenService {
  static const String _apiKey = 'AIzaSyC5p5fxEqDBYWtA1Td2waIObaekDeixzik';
  static const String _model = 'imagen-4.0-generate-001';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// 사용자의 추구미 프롬프트를 기반으로 배경 이미지를 생성합니다.
  static Future<Uint8List?> generateBackground(String userPrompt) async {
    try {
      final bgPrompt = _buildBackgroundPrompt(userPrompt);
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
          'parameters': {
            'sampleCount': 1,
            'aspectRatio': '16:9',
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final predictions = data['predictions'] as List<dynamic>?;

        if (predictions != null && predictions.isNotEmpty) {
          final imageData = predictions.first as Map<String, dynamic>;
          final base64String = imageData['bytesBase64Encoded'] as String?;

          if (base64String != null) {
            return base64Decode(base64String);
          }
        }
      } else {
        debugPrint('Imagen API error [${response.statusCode}]: ${response.body}');
      }

      return null;
    } catch (e) {
      debugPrint('Background generation failed: $e');
      return null;
    }
  }

  /// 사용자 프롬프트를 배경 이미지용 프롬프트로 변환합니다.
  static String _buildBackgroundPrompt(String userPrompt) {
    return 'Create an abstract atmospheric background that captures '
        'the mood and essence of: "$userPrompt". '
        'Soft, ethereal, dreamy quality with beautiful color gradients. '
        'No text, no people, no faces. '
        'Blurred artistic background suitable as wallpaper. '
        'High quality, 16:9 wide format.';
  }
}
