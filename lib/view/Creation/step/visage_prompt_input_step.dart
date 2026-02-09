import 'package:file_picker/file_picker.dart';
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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      for (final file in result.files) {
        if (file.bytes != null) {
          final ext = file.extension?.toLowerCase() ?? '';
          final isImage = ['jpg', 'jpeg', 'png'].contains(ext);
          setState(() {
            _attachedFiles.add(
              AttachedFile(
                name: file.name,
                bytes: file.bytes!,
                type: isImage ? AttachedFileType.image : AttachedFileType.pdf,
              ),
            );
          });
        }
      }
    }
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
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'INPUT YOUR PROMPT',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Visualize Your Design Mood with Upload Your Reference Files',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Text input area with "+" overlay
              GestureDetector(
                onTap: _pickImages,
                child: GlassContainer(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Text field
                      TextField(
                        controller: _textController,
                        onChanged: (_) => setState(() {}),
                        maxLines: 7,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Modern and Minimal, Mute Pink, Model Portfolio',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 15,
                            height: 1.6,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // File upload area
              GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 32,
                ),
                child: _attachedFiles.isEmpty
                    ? _buildEmptyUploadArea()
                    : _buildUploadedFilesArea(),
              ),
              const SizedBox(height: 32),

              // Submit button
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // --- Empty upload area ---
  Widget _buildEmptyUploadArea() {
    return GestureDetector(
      onTap: _pickFiles,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            color: Colors.white.withOpacity(0.6),
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            'UPLOAD YOUR VISUAL IDEA & YOUR STORY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'PDF, JPG, PNG files are allowed',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // --- Uploaded files area with add button ---
  Widget _buildUploadedFilesArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_file_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Attached Files (${_attachedFiles.length})',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (int i = 0; i < _attachedFiles.length; i++)
              _buildFileThumbnail(i),
            _buildAddButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildFileThumbnail(int index) {
    final file = _attachedFiles[index];
    final isImage = file.type == AttachedFileType.image;

    return Stack(
      clipBehavior: Clip.none,
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
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeFile(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.6),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
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

  // --- Add file button ---
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          color: Colors.white.withOpacity(0.03),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
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
      behavior: HitTestBehavior.opaque,
      onTap: _canSubmit ? _submit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: _canSubmit
              ? const Color(0xFF15234A)
              : const Color(0xFF15234A).withOpacity(0.4),
          boxShadow: _canSubmit
              ? [
                  BoxShadow(
                    color: const Color(0xFF15234A).withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          'NEXT',
          style: TextStyle(
            color: _canSubmit ? Colors.white : Colors.white.withOpacity(0.4),
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
