import 'dart:typed_data';

enum CreationStep {
  promptInput,
  imageGeneration,
  imageSelection,
  imageUpload,
  processing,
  result,
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
  bool get isEmpty => text.trim().isEmpty && files.isEmpty;
}
