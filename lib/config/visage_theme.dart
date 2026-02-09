/// =========================================================================
/// Visage Theme Config - visage 프로젝트 전용 테마
/// =========================================================================
///
/// nyx_kernel의 NyxKernelThemeConfig 구현체
library;

import 'package:flutter/material.dart';
import 'package:nyx_kernel/config/nyx_kernel_theme_config.dart';

/// Visage 프로젝트의 테마 설정 구현
class VisageThemeConfig extends NyxKernelThemeConfig {
  @override
  NyxKernelHomeThemeConfig get home => _VisageHomeTheme();

  @override
  NyxKernelCanvasThemeConfig get canvas => _VisageCanvasTheme();

  @override
  ThemeData get homeTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF7C4DFF), // Visage 퍼플
        secondary: Color(0xFFB388FF), // 밝은 퍼플
        surface: Color(0xFF0A0A0F), // 메인 배경
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
    );
  }
}

/// Visage Home 테마 구현
class _VisageHomeTheme implements NyxKernelHomeThemeConfig {
  @override
  Color get prePrimary => const Color(0xFFB388FF);

  @override
  Color get primary => const Color(0xFF7C4DFF);

  @override
  Color get secondary => const Color(0xFF651FFF);

  @override
  Color get onGradient => const Color(0xFFFFFFFF);

  @override
  Color get surfaceTop => const Color(0xFF0A0A0F);

  @override
  Color get surfaceBottom => const Color(0xFF1A1A2E);

  @override
  Color get onSurface => const Color(0xFFFFFFFF);

  @override
  Color get mainLnbCardBackground => const Color(0xFF0A0A0F);

  @override
  Color get mainLnbCardMainText => const Color(0xFFFFFFFF);

  @override
  Color get mainLnbCardSubText => const Color(0xFFA8ACB7);

  @override
  Color get backgroundGradientTop => const Color(0xFF0A0A0F);

  @override
  Color get backgroundGradientBottom => const Color(0xFF1A1A2E);

  @override
  Color get backgroundText => const Color(0xFFFFFFFF);

  @override
  Color get onBackgroundCard => const Color(0xFF16162A);

  @override
  Color get onBackgroundCardButton =>
      const Color(0xFF000000).withValues(alpha: 0.1);

  @override
  Color get onBackgroundCardButtonIcon => const Color(0xFFFFFFFF);

  @override
  Color get buttonGradientLeft => const Color(0xFF7C4DFF);

  @override
  Color get buttonGradientRight => const Color(0xFF651FFF);

  @override
  Color get selectedButtonBg => const Color(0xFFEDE7F6);

  @override
  Color get selectedButtonIcon => const Color(0xFF7C4DFF);

  @override
  Color get selectedButtonText => const Color(0xFF7C4DFF);

  @override
  Color get borderButton => Colors.white;

  @override
  Color get borderButtonBorder => const Color(0xFF7C4DFF);

  @override
  Color get borderButtonSelectedBg => const Color(0xFFEDE7F6);

  @override
  Color get borderButtonText => const Color(0xFF7C4DFF);

  @override
  Color get menuPanelBackground => const Color(0xFFF1F3F8);

  @override
  Color get menuPanelText => Colors.black;

  @override
  Color get menuPanelSelectedText => const Color(0xFF7C4DFF);

  @override
  Color get menuPanelSelectedBg => const Color(0xFFEDE7F6);

  @override
  Color get dropdownBackground => const Color(0xFFF1F3F8);

  @override
  Color get containerBackground => const Color(0xFFF1F3F8);

  @override
  Color get pureWhite => Colors.white;

  @override
  Color get pureBlack => Colors.black;

  @override
  Color get shadowColor => Colors.black.withValues(alpha: 0.05);

  @override
  Color get hoverColor => Colors.black.withValues(alpha: 0.05);

  @override
  Color get errorColor => const Color(0xFFF44336);
}

/// Visage Canvas 테마 구현
class _VisageCanvasTheme implements NyxKernelCanvasThemeConfig {
  @override
  Color get primary => const Color(0xFF7C4DFF);

  @override
  Color get backgroundGradientTop => const Color(0xFFF3EEFF);

  @override
  Color get backgroundGradientBottom => const Color(0xFFFFFFFF);

  @override
  Color get buttonGradientLeft => const Color(0xFF7C4DFF);

  @override
  Color get buttonGradientRight => const Color(0xFF651FFF);

  @override
  Color get normalButton => const Color(0xFFF1F3F8);

  @override
  Color get normalButtonText => Colors.black;

  @override
  Color get selectedButtonBg =>
      const Color(0xFF7C4DFF).withValues(alpha: 0.15);

  @override
  Color get selectedButtonIcon => const Color(0xFF7C4DFF);

  @override
  Color get selectedButtonText => const Color(0xFF7C4DFF);

  @override
  Color get borderButton => Colors.white;

  @override
  Color get borderButtonBorder => const Color(0xFF7C4DFF);

  @override
  Color get borderButtonSelectedBg => const Color(0xFFEDE7F6);

  @override
  Color get borderButtonText => const Color(0xFF7C4DFF);

  @override
  Color get menuPanelBackground => const Color(0xFFF1F3F8);

  @override
  Color get menuPanelText => Colors.black;

  @override
  Color get menuPanelSelectedText => const Color(0xFF7C4DFF);

  @override
  Color get menuPanelSelectedBg => const Color(0xFFEDE7F6);

  @override
  Color get dropdownBackground => const Color(0xFFF1F3F8);

  @override
  Color get containerBackground => const Color(0xFFF1F3F8);

  @override
  Color get pureWhite => Colors.white;

  @override
  Color get pureBlack => Colors.black;

  @override
  Color get shadowColor => Colors.black.withValues(alpha: 0.05);

  @override
  Color get hoverColor => Colors.black.withValues(alpha: 0.05);
}
