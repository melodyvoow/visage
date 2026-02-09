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
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                'ADD IMAGES TO MERGE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select Multiple Images You Would Like to Add Your Work',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Uploaded images grid + add button
              GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: _images.isEmpty
                    ? _buildEmptyUploadArea()
                    : _buildImageGrid(),
              ),
              const SizedBox(height: 32),

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
                            const Color(0xFF15234A),
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
                      horizontal: 56,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: _images.isNotEmpty
                          ? const Color(0xFF15234A)
                          : const Color(0xFF15234A).withOpacity(0.4),
                      boxShadow: _images.isNotEmpty
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
                      'MERGE',
                      style: TextStyle(
                        color: _images.isNotEmpty
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
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
      child: SizedBox(
        height: 180,
        child: Center(
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
                'UPLOAD YOUR IMAGES',
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
                'JPG, PNG, WEBP · Multiple Images Allowed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
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
    return GestureDetector(
      onTap: _pickImages,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 180),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            ..._images.asMap().entries.map(
              (entry) => _buildImageThumbnail(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(int index, _UploadedImage image) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            image.bytes,
            width: 140,
            height: 140,
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
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF15234A),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadedImage {
  final String name;
  final Uint8List bytes;

  const _UploadedImage({required this.name, required this.bytes});
}
