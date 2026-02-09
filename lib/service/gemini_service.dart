import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:visage/view/Creation/visage_creation_types.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyC5p5fxEqDBYWtA1Td2waIObaekDeixzik';
  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// PDF에서 컬러/무드 키워드를 추출하여
  /// 사용자 텍스트와 결합한 프롬프트를 반환합니다.
  /// PDF가 없으면 사용자 텍스트를 그대로 반환합니다.
  static Future<String> extractPdfKeywords(PromptData data) async {
    // PDF가 없으면 사용자 텍스트 그대로 반환 (Gemini 호출 안 함)
    if (!data.hasPdf) {
      debugPrint('[Gemini] PDF 없음 → 사용자 텍스트 그대로 사용');
      return data.text.trim().isNotEmpty
          ? data.text.trim()
          : 'beautiful aesthetic mood board';
    }

    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      final parts = <Map<String, dynamic>>[];

      // 시스템 지시: PDF에서 컬러/무드만 추출
      parts.add({'text': _systemPrompt});

      // 사용자 텍스트
      if (data.text.trim().isNotEmpty) {
        parts.add({'text': '사용자 입력 텍스트: "${data.text.trim()}"'});
        debugPrint('[Gemini] 텍스트 입력: "${data.text.trim()}"');
      }

      // PDF 파일만 첨부
      final pdfFiles = data.files
          .where((f) => f.type == AttachedFileType.pdf)
          .toList();
      debugPrint('[Gemini] PDF 파일 ${pdfFiles.length}개 분석 시작');

      for (final file in pdfFiles) {
        final base64Data = base64Encode(file.bytes);
        parts.add({
          'inlineData': {'mimeType': 'application/pdf', 'data': base64Data},
        });
        parts.add({'text': 'PDF 파일: ${file.name}'});
      }

      final body = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {'temperature': 0.5, 'maxOutputTokens': 128},
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
            final keywords = (responseParts.first['text'] as String).trim();
            debugPrint('[Gemini] PDF 추출 키워드: "$keywords"');

            // 사용자 텍스트 + PDF 키워드 결합
            if (data.text.trim().isNotEmpty) {
              final combined = '${data.text.trim()}, $keywords';
              debugPrint('[Gemini] 최종 결합 프롬프트: "$combined"');
              return combined;
            }
            return keywords;
          }
        }
      } else {
        debugPrint(
          '[Gemini] API error [${response.statusCode}]: ${response.body}',
        );
      }

      // fallback
      return data.text.trim().isNotEmpty
          ? data.text.trim()
          : 'beautiful aesthetic mood board';
    } catch (e) {
      debugPrint('[Gemini] PDF 분석 실패: $e');
      return data.text.trim().isNotEmpty
          ? data.text.trim()
          : 'beautiful aesthetic mood board';
    }
  }

  static const String _systemPrompt = '''
You are a color and mood extraction AI. The user will provide PDF files related to their aesthetic preference ("추구미").

Your task:
1. Analyze the PDF content and extract ONLY the key color palette and mood/atmosphere keywords.
2. Output a short comma-separated list of English keywords (colors, moods, textures, atmosphere).
3. Keep it concise: maximum 5-8 keywords.
4. Do NOT write sentences or explanations - ONLY keywords.

Example outputs:
- "warm terracotta, golden hour, rustic, earthy brown, cozy"
- "neon pink, cyberpunk, dark blue, futuristic, chrome"
- "pastel lavender, soft pink, dreamy, ethereal, film grain"
''';
}
