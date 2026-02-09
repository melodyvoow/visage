import 'dart:typed_data';
import 'package:flutter/material.dart';
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

    if (data.hasImage) {
      // Has image in attachments → go directly to upload step
      _goToStep(CreationStep.imageUpload);
    } else {
      // No image → generate images
      _goToStep(CreationStep.imageGeneration);
      _simulateImageGeneration();
    }
  }

  Future<void> _simulateImageGeneration() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _goToStep(CreationStep.imageSelection);
    }
  }

  void _onImageSelected(int index) {
    _goToStep(CreationStep.imageUpload);
  }

  void _onRegenerateImages() {
    _goToStep(CreationStep.imageGeneration);
    _simulateImageGeneration();
  }

  void _onCompositeImageUploaded(Uint8List? image) {
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

  // --- Background image with dark overlay ---
  Widget _buildBackground() {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset('assets/image/visage_bg.png', fit: BoxFit.cover),
        ),
        // Dark overlay for glass readability
        Container(color: Colors.black.withOpacity(0.35)),
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
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                        )
                      : null,
                  color: isCompleted ? null : Colors.white.withOpacity(0.1),
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: (isActive || isCompleted)
                        ? const LinearGradient(
                            colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                          )
                        : null,
                    color: (isActive || isCompleted)
                        ? null
                        : Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: (isActive || isCompleted)
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7B2FBE).withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
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
          onImageSelected: _onImageSelected,
          onRegenerate: _onRegenerateImages,
        );
      case CreationStep.imageUpload:
        child = VisageImageUploadStep(
          key: const ValueKey('imageUpload'),
          onSubmit: _onCompositeImageUploaded,
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
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow background
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2FBE).withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Rotating ring
          RotationTransition(
            turns: _controller,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    const Color(0xFF7B2FBE),
                    const Color(0xFFE040FB),
                    const Color(0xFF7B2FBE).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          // Inner circle (creates ring effect)
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0A0A14),
            ),
          ),
        ],
      ),
    );
  }
}
