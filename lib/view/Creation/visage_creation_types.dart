import 'dart:typed_data';

enum CreationStep {
  promptInput,
  imageGeneration,
  imageSelection,
  imageUpload,
  styleSelection,
  layoutGenerating,
  layoutRecommend,
  processing,
  result,
}

/// 디자인 스타일 카테고리 (3종)
enum DesignStyle {
  softRound,   // 소프트 라운드, 카드 UI
  sharpGrid,   // 샤프 그리드, 고대비
  editorial,   // 에디토리얼, 콜라주
}

extension DesignStyleExtension on DesignStyle {
  String get label => switch (this) {
    DesignStyle.softRound => '소프트 라운드',
    DesignStyle.sharpGrid => '샤프 그리드',
    DesignStyle.editorial => '에디토리얼',
  };

  String get description => switch (this) {
    DesignStyle.softRound => '카드 UI, 그림자, 친근한 테크 스타일',
    DesignStyle.sharpGrid => '라인 구분, 고대비, 전문적인 기업 스타일',
    DesignStyle.editorial => '콜라주, 마스킹, 감성적인 패션 스타일',
  };
}

enum AttachedFileType { image, pdf }

class AttachedFile {
  final String name;
  final Uint8List bytes;
  final AttachedFileType type;

  const AttachedFile({
    required this.name,
    required this.bytes,
    required this.type,
  });
}

class PromptData {
  final String text;
  final List<AttachedFile> files;

  const PromptData({this.text = '', this.files = const []});

  bool get hasImage => files.any((f) => f.type == AttachedFileType.image);
  bool get hasPdf => files.any((f) => f.type == AttachedFileType.pdf);
  bool get isEmpty => text.trim().isEmpty && files.isEmpty;
}
