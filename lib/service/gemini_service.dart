import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:visage/view/Creation/visage_creation_types.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyC5p5fxEqDBYWtA1Td2waIObaekDeixzik';
  static const String _model = 'gemini-2.0-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// 사용자 입력(텍스트/이미지/PDF)에서 컬러/무드 키워드를 추출합니다.
  /// 첨부 파일(이미지, PDF)이 없으면 사용자 텍스트를 그대로 반환합니다.
  static Future<String> extractColorMood(PromptData data) async {
    final hasFiles = data.hasImage || data.hasPdf;

    // 첨부 파일 없으면 텍스트 그대로 반환 (Gemini 호출 안 함)
    if (!hasFiles) {
      debugPrint('[Gemini] 첨부 파일 없음 → 사용자 텍스트 그대로 사용');
      return data.text.trim().isNotEmpty
          ? data.text.trim()
          : 'beautiful aesthetic mood board';
    }

    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      final parts = <Map<String, dynamic>>[];

      // 시스템 지시
      parts.add({'text': _systemPrompt});

      // 사용자 텍스트
      if (data.text.trim().isNotEmpty) {
        parts.add({'text': '사용자 입력 텍스트: "${data.text.trim()}"'});
        debugPrint('[Gemini] 텍스트 입력: "${data.text.trim()}"');
      }

      // 이미지 파일 첨부
      final imageFiles =
          data.files.where((f) => f.type == AttachedFileType.image).toList();
      if (imageFiles.isNotEmpty) {
        debugPrint('[Gemini] 이미지 ${imageFiles.length}장 분석');
        for (final file in imageFiles) {
          final base64Data = base64Encode(file.bytes);
          final mimeType = _guessMimeType(file.name);
          parts.add({
            'inlineData': {'mimeType': mimeType, 'data': base64Data},
          });
          parts.add({'text': '이미지 파일: ${file.name}'});
        }
      }

      // PDF 파일 첨부
      final pdfFiles =
          data.files.where((f) => f.type == AttachedFileType.pdf).toList();
      if (pdfFiles.isNotEmpty) {
        debugPrint('[Gemini] PDF ${pdfFiles.length}개 분석');
        for (final file in pdfFiles) {
          final base64Data = base64Encode(file.bytes);
          parts.add({
            'inlineData': {'mimeType': 'application/pdf', 'data': base64Data},
          });
          parts.add({'text': 'PDF 파일: ${file.name}'});
        }
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
          final content =
              candidates.first['content'] as Map<String, dynamic>?;
          final responseParts = content?['parts'] as List<dynamic>?;

          if (responseParts != null && responseParts.isNotEmpty) {
            final keywords = (responseParts.first['text'] as String).trim();
            debugPrint('[Gemini] 추출 키워드: "$keywords"');

            // 사용자 텍스트 + 추출 키워드 결합
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
      debugPrint('[Gemini] 분석 실패: $e');
      return data.text.trim().isNotEmpty
          ? data.text.trim()
          : 'beautiful aesthetic mood board';
    }
  }

  static const String _systemPrompt = '''
You are a color and mood extraction AI. The user will provide images and/or PDF files related to their aesthetic preference ("추구미").

Your task:
1. Analyze ALL provided inputs (images, PDFs) and extract ONLY the key color palette and mood/atmosphere keywords.
2. For images: identify dominant colors, color harmony, lighting mood, and emotional tone.
3. For PDFs: extract color references, mood descriptions, and atmospheric keywords.
4. Output a short comma-separated list of English keywords (colors, moods, textures, atmosphere).
5. Keep it concise: maximum 5-8 keywords.
6. Do NOT write sentences or explanations - ONLY keywords.

Example outputs:
- "warm terracotta, golden hour, rustic, earthy brown, cozy"
- "neon pink, cyberpunk, dark blue, futuristic, chrome"
- "pastel lavender, soft pink, dreamy, ethereal, film grain"
''';

  /// 추구미 키워드를 기반으로 9개 레이아웃 중 가장 어울리는 2~3개를 추천합니다.
  /// 반환값: 0-based 인덱스 리스트 (예: [0, 2, 5])
  static Future<List<int>> recommendLayouts({
    required String styleName,
    required List<String> layoutDescriptions,
    required String aestheticKeywords,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

      final prompt = '''
You are a professional UI/UX curator. Given a user's aesthetic preference (color/mood keywords) and a design style category, recommend the 3 most suitable layouts from the list below.

User's aesthetic: "$aestheticKeywords"
Design style: "$styleName"

Available layouts (0-indexed):
${layoutDescriptions.asMap().entries.map((e) => '${e.key}: ${e.value.substring(0, e.value.length.clamp(0, 120))}...').join('\n')}

Rules:
1. Choose exactly 3 layouts that best match the user's color/mood aesthetic.
2. Consider visual harmony between the aesthetic keywords and layout characteristics.
3. Output ONLY a JSON array of 3 integers (0-based indices). Example: [0, 3, 7]
4. No explanation, no text - ONLY the JSON array.
''';

      debugPrint('[Gemini] 레이아웃 추천 요청: style=$styleName, aesthetic=$aestheticKeywords');

      final body = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 32},
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

          if (responseParts != null && responseParts.isNotEmpty) {
            final text = (responseParts.first['text'] as String).trim();
            debugPrint('[Gemini] 레이아웃 추천 응답: "$text"');

            // JSON 배열 파싱
            final match = RegExp(r'\[[\d\s,]+\]').firstMatch(text);
            if (match != null) {
              final list = (jsonDecode(match.group(0)!) as List<dynamic>)
                  .map((e) => (e as num).toInt())
                  .where((i) => i >= 0 && i < layoutDescriptions.length)
                  .toList();
              if (list.isNotEmpty) {
                debugPrint('[Gemini] 추천 레이아웃 인덱스: $list');
                return list.take(3).toList();
              }
            }
          }
        }
      } else {
        debugPrint(
          '[Gemini] 추천 API 오류 [${response.statusCode}]: ${response.body}',
        );
      }

      // fallback: 첫 3개
      debugPrint('[Gemini] 추천 실패 → fallback [0, 1, 2]');
      return [0, 1, 2];
    } catch (e) {
      debugPrint('[Gemini] 레이아웃 추천 예외: $e');
      return [0, 1, 2];
    }
  }

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
