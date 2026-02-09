import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Non-web 플랫폼 스텁 — 브라우저 Canvas가 없으므로 null 반환
Future<Uint8List?> renderSvgToPng(String svgString, int targetSize) async {
  debugPrint('⚠️ [Stub] SVG → PNG 는 웹 플랫폼에서만 지원됩니다.');
  return null;
}
