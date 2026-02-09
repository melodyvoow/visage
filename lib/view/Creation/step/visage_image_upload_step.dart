import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:visage/widget/glass_container.dart';

class VisageImageUploadStep extends StatefulWidget {
  final void Function(List<Uint8List> images) onSubmit;

  const VisageImageUploadStep({super.key, required this.onSubmit});

  @override
  State<VisageImageUploadStep> createState() => _VisageImageUploadStepState();
}

class _VisageImageUploadStepState extends State<VisageImageUploadStep> {
  final List<_UploadedImage> _images = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile> files = await _picker.pickMultiImage();
    if (files.isNotEmpty) {
      for (final file in files) {
        final bytes = await file.readAsBytes();
        setState(() {
          _images.add(_UploadedImage(name: file.name, bytes: bytes));
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

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
                '합성할 이미지를 업로드해주세요',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '컴카드에 합성하고 싶은 사진을 올려주세요 (여러 장 가능)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Uploaded images grid + add button
              GlassContainer(
                width: double.infinity,
                child: _images.isEmpty
                    ? _buildEmptyUploadArea()
                    : _buildImageGrid(),
              ),
              const SizedBox(height: 24),

              // Submit button
              GestureDetector(
                onTap: () =>
                    widget.onSubmit(_images.map((e) => e.bytes).toList()),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyUploadArea() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
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
                'JPG, PNG, WEBP · 여러 장 선택 가능',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: Colors.white.withOpacity(0.5),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '업로드된 이미지 (${_images.length}장)',
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
            ..._images.asMap().entries.map(
              (entry) => _buildImageThumbnail(entry.key, entry.value),
            ),
            _buildAddButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index, _UploadedImage image) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            image.bytes,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        // Remove button
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _removeImage(index),
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

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 100,
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
              '추가',
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
}

class _UploadedImage {
  final String name;
  final Uint8List bytes;

  const _UploadedImage({required this.name, required this.bytes});
}
