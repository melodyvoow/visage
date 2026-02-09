import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxMember/nyx_member_firecat_auth_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxUpload/nyx_upload_firecat_crud_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxUpload/nyx_upload_ux_card.dart';
import 'package:visage/widget/glass_container.dart';

class VisageImageUploadStep extends StatefulWidget {
  final void Function(
    List<Uint8List> images,
    List<NyxUploadUXThumbCardStore> uploadResults,
  ) onSubmit;

  const VisageImageUploadStep({super.key, required this.onSubmit});

  @override
  State<VisageImageUploadStep> createState() => _VisageImageUploadStepState();
}

class _VisageImageUploadStepState extends State<VisageImageUploadStep> {
  final List<_UploadedImage> _images = [];
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  String _uploadProgress = '';
  int _uploadedCount = 0;

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

  /// 이미지들을 NyxUpload로 Firestore에 업로드한 뒤 onSubmit 호출
  Future<void> _uploadAndSubmit() async {
    if (_images.isEmpty) return;

    final uid = NyxMemberFirecatAuthController.getCurrentUserUid();
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login is required.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _uploadProgress = 'Preparing upload...';
    });

    final List<NyxUploadUXThumbCardStore> uploadResults = [];

    try {
      for (var i = 0; i < _images.length; i++) {
        final image = _images[i];

        final platformFile = PlatformFile(
          name: image.name,
          size: image.bytes.length,
          bytes: image.bytes,
        );

        final result = await NyxUploadFirecatCrudController.uploadFile(
          uid,
          platformFile,
          (progress) {
            if (mounted) {
              setState(() {
                _uploadProgress = '(${i + 1}/${_images.length}) $progress';
              });
            }
          },
        );

        if (result != null) {
          uploadResults.add(result);
          debugPrint('[VisageUpload] 업로드 성공: ${image.name} → ${result.uploadData?.ee_file_url}');
          setState(() => _uploadedCount = i + 1);
        } else {
          debugPrint('[VisageUpload] 업로드 실패: ${image.name}');
        }
      }

      debugPrint('[VisageUpload] 전체 업로드 완료: ${uploadResults.length}/${_images.length}');
    } catch (e) {
      debugPrint('[VisageUpload] 업로드 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred during upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = '';
        });
      }
    }

    if (uploadResults.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 업로드 완료 후 이미지 + 업로드 결과를 함께 전달
    widget.onSubmit(
      _images.map((e) => e.bytes).toList(),
      uploadResults,
    );
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
                'Upload Images for Compositing',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload photos to composite into your comp card (multiple allowed)',
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

              // Upload progress
              if (_isUploading) ...[
                GlassContainer(
                  width: double.infinity,
                  borderRadius: 20,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFE040FB),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _uploadProgress,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_uploadedCount / ${_images.length} completed',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Submit button
              if (!_isUploading)
                GestureDetector(
                  onTap: _images.isNotEmpty ? _uploadAndSubmit : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: _images.isNotEmpty
                          ? const LinearGradient(
                              colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                            )
                          : null,
                      color: _images.isNotEmpty
                          ? null
                          : Colors.white.withOpacity(0.05),
                      boxShadow: _images.isNotEmpty
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
                      'Composite',
                      style: TextStyle(
                        color: _images.isNotEmpty
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
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
                'Click to upload images',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'JPG, PNG, WEBP · Multiple selection allowed',
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
}

class _UploadedImage {
  final String name;
  final Uint8List bytes;

  const _UploadedImage({required this.name, required this.bytes});
}
