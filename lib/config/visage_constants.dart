/// =========================================================================
/// Visage Constants Config - visage 프로젝트 전용 설정
/// =========================================================================
///
/// nyx_kernel의 NyxKernelConstantsConfig 구현체
library;

import 'package:nyx_kernel/config/nyx_kernel_constants_config.dart';

/// Visage 프로젝트의 상수 설정 구현
class VisageConstantsConfig extends NyxKernelConstantsConfig {
  @override
  String get databaseName => "visage";

  @override
  String get appTitle => 'Visage';

  @override
  String get appVersion => '0.1.0';

  @override
  bool get livemode => false; // 기본값: test 환경
}
