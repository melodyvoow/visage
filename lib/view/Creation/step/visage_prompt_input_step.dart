import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:visage/view/Creation/visage_creation_types.dart';
import 'package:visage/widget/glass_container.dart';

class VisagePromptInputStep extends StatefulWidget {
  final void Function(PromptData data) onSubmit;

  const VisagePromptInputStep({super.key, required this.onSubmit});

  @override
  State<VisagePromptInputStep> createState() => _VisagePromptInputStepState();
}

class _VisagePromptInputStepState extends State<VisagePromptInputStep> {
  final TextEditingController _textController = TextEditingController();
  final List<AttachedFile> _attachedFiles = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- File Pickers ---

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (final image in images) {
        final bytes = await image.readAsBytes();
        setState(() {
          _attachedFiles.add(
            AttachedFile(
              name: image.name,
              bytes: bytes,
              type: AttachedFileType.image,
            ),
          );
        });
      }
    }
  }

  Future<void> _pickPdf() async {
    // TODO: PDF 파일 피커 연동 (file_picker 패키지 필요)
    // 현재는 placeholder
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  // --- Submit ---

  void _submit() {
    final data = PromptData(
      text: _textController.text.trim(),
      files: List.from(_attachedFiles),
    );
    widget.onSubmit(data);
  }

  bool get _canSubmit =>
      _textController.text.trim().isNotEmpty || _attachedFiles.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                '추구미 프롬프트를 입력해주세요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '텍스트와 함께 이미지, PDF를 자유롭게 첨부할 수 있어요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Text input area
              GlassContainer(
                width: double.infinity,
                child: TextField(
                  controller: _textController,
                  onChanged: (_) => setState(() {}),
                  maxLines: 6,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        '원하는 추구미를 자유롭게 묘사해주세요.\n\n예: 몽환적인 분위기의 파스텔톤 인물 사진, 부드러운 자연광...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 15,
                      height: 1.6,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // File attachment area
              GlassContainer(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '파일 첨부',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_attachedFiles.length}개',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Attached files grid + add buttons
                    _buildFileGrid(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // --- File attachment grid ---
  Widget _buildFileGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Existing attached files
        for (int i = 0; i < _attachedFiles.length; i++) _buildFileThumbnail(i),

        // Add image button
        _buildAddButton(
          icon: Icons.image_rounded,
          label: '이미지',
          onTap: _pickImages,
        ),

        // Add PDF button
        _buildAddButton(
          icon: Icons.picture_as_pdf_rounded,
          label: 'PDF',
          onTap: _pickPdf,
        ),
      ],
    );
  }

  Widget _buildFileThumbnail(int index) {
    final file = _attachedFiles[index];
    final isImage = file.type == AttachedFileType.image;

    return Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isImage
                ? Image.memory(file.bytes, fit: BoxFit.cover)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white.withOpacity(0.5),
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            file.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        // Remove button
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () => _removeFile(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.6),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          color: Colors.white.withOpacity(0.04),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.35), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Submit button ---
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _canSubmit ? _submit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _canSubmit
              ? const LinearGradient(
                  colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                )
              : null,
          color: _canSubmit ? null : Colors.white.withOpacity(0.05),
          boxShadow: _canSubmit
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B2FBE).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          '다음',
          style: TextStyle(
            color: _canSubmit ? Colors.white : Colors.white.withOpacity(0.3),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
