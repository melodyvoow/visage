import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:visage/view/Creation/visage_creation_types.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyC5p5fxEqDBYWtA1Td2waIObaekDeixzik';
  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// 사용자의 PromptData(텍스트/이미지/PDF)를 통합 분석하여
  /// Imagen 이미지 생성에 최적화된 영어 프롬프트를 반환합니다.
  static Future<String> analyzePromptData(PromptData data) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      final parts = <Map<String, dynamic>>[];

      // 시스템 지시: 추구미 분석 및 프롬프트 생성
      parts.add({'text': _systemPrompt});

      // 사용자 텍스트
      if (data.text.trim().isNotEmpty) {
        parts.add({'text': '사용자 입력 텍스트: "${data.text.trim()}"'});
        debugPrint('[Gemini] 텍스트 입력: "${data.text.trim()}"');
      }

      debugPrint(
        '[Gemini] 첨부 파일 ${data.files.length}개: '
        '${data.files.map((f) => "${f.name}(${f.type.name})").join(", ")}',
      );

      // 첨부 파일 (이미지, PDF)
      for (final file in data.files) {
        final base64Data = base64Encode(file.bytes);
        final mimeType = file.type == AttachedFileType.image
            ? _guessMimeType(file.name)
            : 'application/pdf';

        parts.add({
          'inlineData': {'mimeType': mimeType, 'data': base64Data},
        });

        parts.add({'text': '첨부 파일: ${file.name} (${file.type.name})'});
      }

      final body = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 512},
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

          if (responseParts != null && responseParts.isNotEmpty) {
            final analyzed = (responseParts.first['text'] as String).trim();
            debugPrint('[Gemini] 분석 결과 프롬프트: "$analyzed"');
            return analyzed;
          }
        }
      } else {
        debugPrint(
          'Gemini API error [${response.statusCode}]: ${response.body}',
        );
      }

      // fallback: 사용자 텍스트 그대로 반환
      return data.text.trim().isNotEmpty
          ? data.text.trim()
          : 'beautiful aesthetic mood board';
    } catch (e) {
      debugPrint('Gemini analysis failed: $e');
      return data.text.trim().isNotEmpty
          ? data.text.trim()
          : 'beautiful aesthetic mood board';
    }
  }

  static const String _systemPrompt = '''
You are an aesthetic analysis AI. The user will provide their "추구미" (aesthetic preference) through text, images, and/or PDF files.

Your task:
1. Analyze ALL provided inputs (text, images, PDFs) to understand the user's aesthetic taste and style preferences.
2. Generate a single, optimized English prompt for the Imagen image generation model.
3. The prompt should capture the mood, colors, textures, style, and visual elements of the user's aesthetic.
4. Focus on visual descriptors: lighting, color palette, composition, atmosphere, artistic style.
5. Do NOT include any explanation - output ONLY the image generation prompt.
6. The prompt should be 2-4 sentences, detailed but concise.
7. Do NOT include instructions like "no text" or "no people" - just describe the desired visual.

Example output:
"A dreamy pastel-toned portrait with soft natural lighting, featuring gentle pink and lavender hues. Ethereal atmosphere with bokeh effects, reminiscent of film photography with grain texture. Romantic and delicate mood with flowing fabrics."
''';

  static String _guessMimeType(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}
