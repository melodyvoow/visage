import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// 브라우저 네이티브 Canvas를 사용하여 SVG → PNG 변환
///
/// <img> 태그에 SVG를 로드하려면:
/// 1. xmlns 네임스페이스가 반드시 있어야 함
/// 2. 유효한 XML이어야 함
/// 3. <foreignObject>, <script> 등은 <img> 컨텍스트에서 차단됨
/// 4. data URL (base64)이 blob URL보다 안정적
Future<Uint8List?> renderSvgToPng(String svgString, int targetSize) async {
  try {
    debugPrint('🌐 [Web] SVG → PNG 렌더링 시작 (targetSize: $targetSize)');

    // ── SVG 전처리 ──
    String svg = svgString.trim();

    // 1) xmlns 네임스페이스 보장 (없으면 <img>가 SVG를 인식 못함)
    if (!svg.contains('xmlns="http://www.w3.org/2000/svg"') &&
        !svg.contains("xmlns='http://www.w3.org/2000/svg'")) {
      svg = svg.replaceFirst('<svg', '<svg xmlns="http://www.w3.org/2000/svg"');
    }

    // 2) xmlns:xlink 보장 (xlink:href 사용 시 필요)
    if (svg.contains('xlink:') && !svg.contains('xmlns:xlink')) {
      svg = svg.replaceFirst(
        'xmlns="http://www.w3.org/2000/svg"',
        'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"',
      );
    }

    // 3) width/height 보장
    if (!svg.contains(RegExp(r'<svg[^>]*\bwidth\s*='))) {
      svg = svg.replaceFirst('<svg', '<svg width="1920" height="1080"');
    }

    // 4) <img> 컨텍스트에서 차단되는 요소 제거
    svg = _sanitizeForImgContext(svg);

    debugPrint('🔧 [Web] SVG 전처리 완료: ${svg.length}자');

    // ── DOMParser로 XML 유효성 검증 ──
    final parser = web.DOMParser();
    final doc = parser.parseFromString(svg.toJS, 'image/svg+xml');
    final parseError = doc.querySelector('parsererror');
    if (parseError != null) {
      debugPrint('⚠️ [Web] SVG XML 파싱 오류 발견, 원본으로 진행');
      debugPrint('   ${parseError.textContent}');
      // 파싱 오류가 있어도 시도는 해봄
    } else {
      // 정상 파싱 → XMLSerializer로 재직렬화 (유효한 XML 보장)
      final serializer = web.XMLSerializer();
      svg = serializer.serializeToString(doc.documentElement!);
      debugPrint('✅ [Web] SVG XML 검증 & 재직렬화 완료');
    }

    // ── base64 data URL 생성 (blob URL보다 안정적) ──
    final svgBytes = utf8.encode(svg);
    final base64Svg = base64Encode(svgBytes);
    final dataUrl = 'data:image/svg+xml;base64,$base64Svg';

    debugPrint('📦 [Web] data URL 생성 완료 (${svgBytes.length} bytes)');

    final completer = Completer<Uint8List?>();

    // ── <img>에 로드 ──
    final img = web.HTMLImageElement();

    img.addEventListener(
      'load',
      (web.Event _) {
        try {
          final canvas =
              web.document.createElement('canvas') as web.HTMLCanvasElement
                ..width = targetSize
                ..height = targetSize;
          final ctx = canvas.getContext('2d')! as web.CanvasRenderingContext2D;

          // 흰색 배경
          ctx.fillStyle = '#FFFFFF'.toJS;
          ctx.fillRect(0, 0, targetSize.toDouble(), targetSize.toDouble());

          // 스케일 & 중앙 정렬
          final svgW = img.naturalWidth.toDouble();
          final svgH = img.naturalHeight.toDouble();
          final maxDim = svgW > svgH ? svgW : svgH;

          double sw, sh, ox, oy;
          if (maxDim > 0) {
            final scale = targetSize / maxDim;
            sw = svgW * scale;
            sh = svgH * scale;
            ox = (targetSize - sw) / 2;
            oy = (targetSize - sh) / 2;
          } else {
            sw = targetSize.toDouble();
            sh = targetSize.toDouble();
            ox = 0;
            oy = 0;
          }

          ctx.drawImage(img, ox, oy, sw, sh);

          // PNG data URL → bytes
          final pngDataUrl = canvas.toDataURL('image/png');
          final pngBase64 = pngDataUrl.split(',')[1];
          final bytes = Uint8List.fromList(base64Decode(pngBase64));

          debugPrint('✅ [Web] SVG → PNG 완료: ${bytes.length} bytes');
          completer.complete(bytes);
        } catch (e) {
          debugPrint('❌ [Web] Canvas 렌더링 오류: $e');
          completer.complete(null);
        }
      }.toJS,
    );

    img.addEventListener(
      'error',
      (web.Event ev) {
        debugPrint('❌ [Web] SVG 이미지 로드 실패');
        debugPrint('   src 길이: ${img.src.length}');
        completer.complete(null);
      }.toJS,
    );

    img.src = dataUrl;

    // 30초 타임아웃
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint('⏰ [Web] SVG 렌더링 타임아웃');
        return null;
      },
    );
  } catch (e, st) {
    debugPrint('❌ [Web] SVG → PNG 예외: $e');
    debugPrint('   $st');
    return null;
  }
}

/// <img> 태그 컨텍스트에서 차단/무시되는 SVG 요소 제거
String _sanitizeForImgContext(String svg) {
  String result = svg;

  // <foreignObject> — <img>에서 완전 차단됨
  result = result.replaceAll(
    RegExp(r'<foreignObject[^>]*/>', caseSensitive: false),
    '',
  );
  result = result.replaceAll(
    RegExp(
      r'<foreignObject[^>]*>[\s\S]*?</foreignObject>',
      caseSensitive: false,
    ),
    '',
  );

  // <script> — 보안상 차단
  result = result.replaceAll(
    RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
    '',
  );

  // <animate*>, <set> — <img>에서 무시되지만 파싱 오류 유발 가능
  for (final tag in ['animate', 'animateTransform', 'animateMotion', 'set']) {
    result = result.replaceAll(
      RegExp('<$tag[^>]*/>', caseSensitive: false),
      '',
    );
    result = result.replaceAll(
      RegExp('<$tag[^>]*>[\\s\\S]*?</$tag>', caseSensitive: false),
      '',
    );
  }

  return result;
}
