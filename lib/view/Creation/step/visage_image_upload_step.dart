import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:visage/widget/glass_container.dart';

class VisageImageUploadStep extends StatefulWidget {
  final void Function(Uint8List? image) onSubmit;

  const VisageImageUploadStep({super.key, required this.onSubmit});

  @override
  State<VisageImageUploadStep> createState() => _VisageImageUploadStepState();
}

class _VisageImageUploadStepState extends State<VisageImageUploadStep> {
  Uint8List? _uploadedImage;
  String? _fileName;
  final ImagePicker _picker = ImagePicker();
  bool _isHovering = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _uploadedImage = bytes;
        _fileName = image.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                '합성할 이미지를 업로드해주세요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '컴카드에 합성하고 싶은 인물 사진을 올려주세요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Upload area
              GlassContainer(
                width: double.infinity,
                child: _uploadedImage != null
                    ? _buildPreview()
                    : _buildUploadArea(),
              ),
              const SizedBox(height: 24),

              // Submit button
              GestureDetector(
                onTap: () => widget.onSubmit(_uploadedImage),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B2FBE).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Text(
                    '합성하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: _pickImage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovering
                  ? const Color(0xFFE040FB).withOpacity(0.5)
                  : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
            color: _isHovering
                ? Colors.white.withOpacity(0.03)
                : Colors.transparent,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.white.withOpacity(0.4),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '클릭하여 이미지를 업로드하세요',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'JPG, PNG, WEBP (최대 10MB)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            _uploadedImage!,
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFFE040FB),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _fileName ?? '이미지 선택됨',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _pickImage,
              child: const Text(
                '변경',
                style: TextStyle(
                  color: Color(0xFFE040FB),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
