import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:visage/service/imagen_service.dart';
import 'package:visage/view/Creation/visage_creation_types.dart';
import 'package:visage/widget/glass_container.dart';
import 'step/visage_prompt_input_step.dart';
import 'step/visage_image_select_step.dart';
import 'step/visage_image_upload_step.dart';
import 'step/visage_result_step.dart';

class VisageCreationFlowView extends StatefulWidget {
  const VisageCreationFlowView({super.key});

  @override
  State<VisageCreationFlowView> createState() => _VisageCreationFlowViewState();
}

class _VisageCreationFlowViewState extends State<VisageCreationFlowView> {
  CreationStep _currentStep = CreationStep.promptInput;
  bool _isForward = true;

  // Flow data
  PromptData? _promptData;
  List<Uint8List> _generatedImages = [];

  // Dynamic background
  Uint8List? _generatedBackground;

  // Step indicator mapping
  int get _indicatorStep => switch (_currentStep) {
    CreationStep.promptInput ||
    CreationStep.imageGeneration ||
    CreationStep.imageSelection => 0,
    CreationStep.imageUpload => 1,
    CreationStep.processing || CreationStep.result => 2,
  };

  void _goToStep(CreationStep step) {
    setState(() {
      _isForward = step.index > _currentStep.index;
      _currentStep = step;
    });
  }

  // --- Step Handlers ---

  void _onPromptSubmitted(PromptData data) {
    _promptData = data;

    // 배경 이미지 생성을 병렬로 시작
    _generateBackground(data);

    if (data.hasImage) {
      // Has image in attachments → go directly to upload step
      _goToStep(CreationStep.imageUpload);
    } else {
      // No image → generate aesthetic images
      _goToStep(CreationStep.imageGeneration);
      _generateAestheticImages();
    }
  }

  /// 프롬프트 기반 배경 이미지 생성 (병렬 실행)
  Future<void> _generateBackground(PromptData data) async {
    final prompt = data.text.isNotEmpty ? data.text : '아름다운 추상적인 배경';

    final bgImage = await ImagenService.generateBackground(prompt);

    if (mounted && bgImage != null) {
      setState(() {
        _generatedBackground = bgImage;
      });
    }
  }

  Future<void> _generateAestheticImages() async {
    final prompt = _promptData?.text ?? '';
    final images = await ImagenService.generateAestheticImages(prompt);

    if (mounted) {
      setState(() {
        _generatedImages = images;
      });
      _goToStep(CreationStep.imageSelection);
    }
  }

  void _onImageSelected(int index) {
    _goToStep(CreationStep.imageUpload);
  }

  void _onRegenerateImages() {
    _goToStep(CreationStep.imageGeneration);
    _generateAestheticImages();
  }

  void _onCompositeImagesUploaded(List<Uint8List> images) {
    _goToStep(CreationStep.processing);
    _simulateProcessing();
  }

  Future<void> _simulateProcessing() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      _goToStep(CreationStep.result);
    }
  }

  void _onCreateNew() {
    setState(() {
      _currentStep = CreationStep.promptInput;
      _isForward = false;
      _promptData = null;
      _generatedImages = [];
      _generatedBackground = null;
    });
  }

  void _onBack() {
    switch (_currentStep) {
      case CreationStep.promptInput:
        Navigator.of(context).pop();
      case CreationStep.imageGeneration:
      case CreationStep.imageSelection:
        _goToStep(CreationStep.promptInput);
      case CreationStep.imageUpload:
        if (_promptData?.hasImage == true) {
          _goToStep(CreationStep.promptInput);
        } else {
          _goToStep(CreationStep.imageSelection);
        }
      case CreationStep.processing:
      case CreationStep.result:
        break; // Cannot go back from processing/result
    }
  }

  bool get _showBackButton => switch (_currentStep) {
    CreationStep.promptInput ||
    CreationStep.imageSelection ||
    CreationStep.imageUpload => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 16),
                _buildStepIndicator(),
                const SizedBox(height: 32),
                Expanded(child: _buildCurrentStep()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Background: static → AI-generated crossfade ---
  Widget _buildBackground() {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Crossfade between static and AI-generated background
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1200),
          child: _generatedBackground != null
              ? SizedBox.expand(
                  key: const ValueKey('generated_bg'),
                  child: Image.memory(
                    _generatedBackground!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                )
              : SizedBox.expand(
                  key: const ValueKey('static_bg'),
                  child: Image.asset(
                    'assets/image/visage_bg.png',
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        // Soft overlay for glass readability
        Container(color: Colors.black.withOpacity(0.12)),
        // Floating orb – top right (warm pink)
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFEBB5FF).withOpacity(0.30),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Floating orb – bottom left (soft blue)
        Positioned(
          bottom: -100,
          left: -40,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFB5D4FF).withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Floating orb – center right (peach)
        Positioned(
          top: size.height * 0.45,
          right: size.width * 0.15,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFCBD4).withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Top bar with back / close buttons ---
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          if (_showBackButton)
            GestureDetector(
              onTap: _onBack,
              child: GlassContainer(
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
                blur: 10,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
              ),
            )
          else
            const SizedBox(width: 42),
          const Spacer(),
          Text(
            'VISAGE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: GlassContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: 16,
              blur: 10,
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step indicator (3 steps) ---
  Widget _buildStepIndicator() {
    final steps = ['추구미 프롬프트', '합성 이미지', '컴카드 완성'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = _indicatorStep > stepIndex;
            return Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [Color(0xFF9B6FD6), Color(0xFFD070F0)],
                        )
                      : null,
                  color: isCompleted ? null : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          } else {
            // Step dot with label
            final stepIndex = index ~/ 2;
            final isActive = _indicatorStep == stepIndex;
            final isCompleted = _indicatorStep > stepIndex;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (isActive || isCompleted)
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF9B6FD6), Color(0xFFD070F0)],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.white.withOpacity(0.08),
                            ],
                          ),
                    border: Border.all(
                      color: (isActive || isCompleted)
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white.withOpacity(0.25),
                      width: 0.8,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF9B6FD6).withOpacity(0.35),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  steps[stepIndex],
                  style: TextStyle(
                    color: isActive
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  // --- Current step content ---
  Widget _buildCurrentStep() {
    Widget child;
    switch (_currentStep) {
      case CreationStep.promptInput:
        child = VisagePromptInputStep(
          key: const ValueKey('promptInput'),
          onSubmit: _onPromptSubmitted,
        );
      case CreationStep.imageGeneration:
        child = _buildLoadingStep(
          key: const ValueKey('imageGeneration'),
          message: '추구미 이미지를 생성하고 있어요...',
          subMessage: 'AI가 프롬프트를 분석하고 이미지를 만들고 있습니다',
        );
      case CreationStep.imageSelection:
        child = VisageImageSelectStep(
          key: const ValueKey('imageSelection'),
          images: _generatedImages,
          onImageSelected: _onImageSelected,
          onRegenerate: _onRegenerateImages,
        );
      case CreationStep.imageUpload:
        child = VisageImageUploadStep(
          key: const ValueKey('imageUpload'),
          onSubmit: _onCompositeImagesUploaded,
        );
      case CreationStep.processing:
        child = _buildLoadingStep(
          key: const ValueKey('processing'),
          message: '컴카드를 합성하고 있어요...',
          subMessage: '이미지를 합성하여 최종 컴카드를 만들고 있습니다',
        );
      case CreationStep.result:
        child = VisageResultStep(
          key: const ValueKey('result'),
          onCreateNew: _onCreateNew,
          onGoHome: () => Navigator.of(context).pop(),
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        final offset = _isForward
            ? const Offset(0.15, 0)
            : const Offset(-0.15, 0);
        final slideAnimation = Tween<Offset>(begin: offset, end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
      child: child,
    );
  }

  // --- Loading step (generation / processing) ---
  Widget _buildLoadingStep({
    required Key key,
    required String message,
    required String subMessage,
  }) {
    return Center(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _GlassLoadingIndicator(),
          const SizedBox(height: 32),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subMessage,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Glass loading indicator ---
class _GlassLoadingIndicator extends StatefulWidget {
  const _GlassLoadingIndicator();

  @override
  State<_GlassLoadingIndicator> createState() => _GlassLoadingIndicatorState();
}

class _GlassLoadingIndicatorState extends State<_GlassLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glow
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B6FD6).withOpacity(0.25),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Rotating ring
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    const Color(0xFF9B6FD6),
                    const Color(0xFFD070F0),
                    const Color(0xFFB5D4FF).withOpacity(0.4),
                    const Color(0xFF9B6FD6).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),
          // Inner frosted glass circle
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.10),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
