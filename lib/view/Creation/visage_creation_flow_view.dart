import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nyx_kernel/nyx_kernel.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxUpload/nyx_upload_ux_card.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxProject/ProjectSlider/project_slider_firecat_crud_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxProject/ProjectSlider/project_slider_ux_card.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxProject/ProjectSlider/SliderLayer/slider_layer_firecat_crud_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxProject/ProjectSlider/SliderLayer/slider_layer_ux_card.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxMember/nyx_member_firecat_crud_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxProject/nyx_project_ux_card.dart';
import 'package:visage/service/gemini_service.dart';
import 'package:visage/service/imagen_service.dart';
import 'package:visage/service/nanobanana_service.dart';
import 'package:visage/service/visage_svg_service.dart';
import 'package:visage/view/Creation/visage_creation_types.dart';
import 'package:visage/widget/glass_container.dart';
import 'step/visage_prompt_input_step.dart';
import 'step/visage_image_select_step.dart';
import 'step/visage_image_upload_step.dart';
import 'step/visage_layout_recommend_step.dart';
import 'step/visage_style_selection_step.dart';
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
  String? _analyzedPrompt; // Gemini 분석 결과
  List<Uint8List> _generatedImages = [];
  int? _selectedAestheticIndex; // 선택된 추구미 이미지 인덱스
  List<Uint8List> _compositeImages = []; // 합성용 상품 이미지
  List<NyxUploadUXThumbCardStore> _compositeUploadResults = []; // 업로드 결과
  DesignStyle? _selectedStyle; // 선택된 디자인 스타일
  List<int> _recommendedLayoutIndices = []; // Gemini가 추천한 레이아웃 인덱스
  List<Uint8List> _layoutImages = []; // 레이아웃 추천 이미지

  // Dynamic background
  Uint8List? _generatedBackground;

  // Step indicator mapping (4 steps)
  int get _indicatorStep => switch (_currentStep) {
    CreationStep.promptInput ||
    CreationStep.imageGeneration ||
    CreationStep.imageSelection => 0,
    CreationStep.imageUpload => 1,
    CreationStep.styleSelection ||
    CreationStep.layoutGenerating ||
    CreationStep.layoutRecommend => 2,
    CreationStep.processing || CreationStep.result => 3,
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

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[Flow] 프롬프트 제출됨');
    debugPrint('[Flow] 텍스트: "${data.text}"');
    debugPrint('[Flow] 첨부 파일: ${data.files.length}개');
    for (final f in data.files) {
      debugPrint(
        '[Flow]   - ${f.name} (${f.type.name}, ${f.bytes.length} bytes)',
      );
    }
    debugPrint('[Flow] 이미지 포함 여부: ${data.hasImage}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (data.hasImage) {
      // 이미지 첨부 → 사용자에게 선택권 부여
      _showImageChoiceDialog();
    } else {
      // 이미지 없음 → Gemini 분석 후 이미지 생성
      _goToStep(CreationStep.imageGeneration);
      _analyzeAndGenerate();
    }
  }

  /// 이미지 첨부 시 선택 다이얼로그
  void _showImageChoiceDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'choice',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GlassContainer(
              borderRadius: 28,
              blur: 40,
              opacity: 0.18,
              enableShadow: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Image Attached',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Proceed with the attached image,\nor let AI generate additional aesthetic images',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 바로 진행 버튼
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _proceedDirectly();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: const Color(0xFF15234A),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF15234A).withOpacity(0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Text(
                        'PROCEED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // AI 추가 생성 버튼
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _goToStep(CreationStep.imageGeneration);
                      _analyzeAndGenerate();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        color: Colors.white.withOpacity(0.06),
                      ),
                      child: Text(
                        'Generate more with AI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 이미지로 바로 진행 (배경 생성만 병렬 실행)
  void _proceedDirectly() {
    _generateBackgroundOnly();
    _goToStep(CreationStep.imageUpload);
  }

  /// 프롬프트 준비 → Imagen 이미지 생성 + 배경 생성
  Future<void> _analyzeAndGenerate() async {
    // PDF 있으면 Gemini로 키워드 추출, 없으면 텍스트 그대로 사용
    debugPrint('[Flow] 프롬프트 준비 시작 (PDF: ${_promptData!.hasPdf})...');
    final prompt = await GeminiService.extractColorMood(_promptData!);

    if (!mounted) return;
    _analyzedPrompt = prompt;
    debugPrint('[Flow] 최종 프롬프트 → Imagen 호출 시작');
    debugPrint('[Flow] 프롬프트: "$prompt"');

    // 2. 병렬로 추구미 이미지 + 배경 생성
    final results = await Future.wait([
      ImagenService.generateAestheticImages(prompt),
      ImagenService.generateBackground(prompt),
    ]);

    if (mounted) {
      final images = results[0] as List<Uint8List>;
      final bg = results[1] as Uint8List?;

      debugPrint(
        '[Flow] Imagen 결과: 추구미 이미지 ${images.length}개, 배경 ${bg != null ? "성공" : "실패"}',
      );

      setState(() {
        _generatedImages = images;
        if (bg != null) _generatedBackground = bg;
      });
      _goToStep(CreationStep.imageSelection);
    }
  }

  /// 배경만 생성 (바로 진행 시)
  Future<void> _generateBackgroundOnly() async {
    debugPrint('[Flow] 바로 진행 모드 → 배경만 생성');
    final prompt = await GeminiService.extractColorMood(_promptData!);
    if (!mounted) return;
    _analyzedPrompt = prompt;
    debugPrint('[Flow] 배경용 프롬프트: "$prompt"');

    final bgImage = await ImagenService.generateBackground(prompt);
    if (mounted && bgImage != null) {
      debugPrint('[Flow] 배경 이미지 생성 완료');
      setState(() {
        _generatedBackground = bgImage;
      });
    }
  }

  void _onImageSelected(int index) {
    _selectedAestheticIndex = index;
    _goToStep(CreationStep.imageUpload);
  }

  void _onRegenerateImages() {
    _goToStep(CreationStep.imageGeneration);
    _analyzeAndGenerate();
  }

  void _onCompositeImagesUploaded(
    List<Uint8List> images,
    List<NyxUploadUXThumbCardStore> uploadResults,
  ) {
    _compositeImages = images;
    _compositeUploadResults = uploadResults;

    debugPrint(
      '[Flow] 합성 이미지 ${images.length}장, 업로드 결과 ${uploadResults.length}건',
    );
    for (final result in uploadResults) {
      debugPrint(
        '[Flow]   - doc: ${result.documentRef?.id}, url: ${result.uploadData?.ee_file_url}',
      );
    }

    // 합성 이미지 업로드 후 → 스타일 선택 화면으로
    _goToStep(CreationStep.styleSelection);
  }

  /// 스타일 선택 → Gemini 추천 → NanoBanana 이미지 생성
  void _onStyleSelected(DesignStyle style) {
    _selectedStyle = style;
    _goToStep(CreationStep.layoutGenerating);
    _recommendAndGenerateLayouts(style);
  }

  /// Gemini로 추구미에 맞는 레이아웃 4개를 추천받고, NanoBanana로 이미지를 생성합니다.
  Future<void> _recommendAndGenerateLayouts(DesignStyle style) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[Flow] 레이아웃 추천 + 생성 시작');
    debugPrint('[Flow] 스타일: ${style.label}');

    final userPrompt = _analyzedPrompt ?? _promptData?.text ?? '';

    // 1. Gemini에게 추천 요청
    final layoutDescriptions = NanoBananaService.getLayoutDescriptions(style);
    final indices = await GeminiService.recommendLayouts(
      styleName: style.label,
      layoutDescriptions: layoutDescriptions,
      aestheticKeywords: userPrompt,
    );

    if (!mounted) return;

    setState(() => _recommendedLayoutIndices = indices);
    debugPrint('[Flow] Gemini 추천 레이아웃: $indices');

    // 2. 추구미 이미지 결정
    Uint8List? aestheticImage;
    if (_selectedAestheticIndex != null &&
        _selectedAestheticIndex! < _generatedImages.length) {
      aestheticImage = _generatedImages[_selectedAestheticIndex!];
    } else if (_promptData?.hasImage == true) {
      final imageFile = _promptData!.files.firstWhere(
        (f) => f.type == AttachedFileType.image,
      );
      aestheticImage = imageFile.bytes;
    }

    if (aestheticImage == null) {
      debugPrint('[Flow] 추구미 이미지 없음 → 레이아웃 생성 불가');
      if (mounted) _goToStep(CreationStep.layoutRecommend);
      return;
    }

    // 3. NanoBanana로 추천된 레이아웃 이미지 생성
    final layouts = await NanoBananaService.generateLayoutImages(
      aestheticImage: aestheticImage,
      productImages: _compositeImages,
      style: style,
      layoutIndices: indices,
      userPrompt: userPrompt,
    );

    if (mounted) {
      debugPrint('[Flow] 레이아웃 이미지 ${layouts.length}장 생성 완료');
      setState(() {
        _layoutImages = layouts;
      });
      _goToStep(CreationStep.layoutRecommend);
    }
  }

  void _onLayoutSelected(int index) {
    _goToStep(CreationStep.processing);
    _generateSvgAndProceed(index);
  }

  /// SVG 생성 + 이미지 업로드 → Desk 워크플로우 진입
  Future<void> _generateSvgAndProceed(int layoutIndex) async {
    final uid = NyxMemberFirecatAuthController.getCurrentUserUid();
    if (uid == null) {
      debugPrint('[Flow] 로그인 필요');
      if (mounted) {
        _showWarningDialog('Login is required.');
        _goToStep(CreationStep.layoutRecommend);
      }
      return;
    }

    final userPrompt = _analyzedPrompt ?? _promptData?.text ?? '';

    // 선택된 레이아웃의 프롬프트 가져오기
    String layoutPrompt = '';
    if (_selectedStyle != null && _recommendedLayoutIndices.isNotEmpty) {
      final descriptions = NanoBananaService.getLayoutDescriptions(
        _selectedStyle!,
      );
      final actualIndex = layoutIndex < _recommendedLayoutIndices.length
          ? _recommendedLayoutIndices[layoutIndex]
          : 0;
      if (actualIndex < descriptions.length) {
        layoutPrompt = descriptions[actualIndex];
      }
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('[Flow] SVG 생성 + 업로드 시작');
    debugPrint('[Flow] 스타일: ${_selectedStyle?.label}');
    debugPrint('[Flow] 레이아웃 인덱스: $layoutIndex');
    debugPrint('[Flow] 프롬프트: "$userPrompt"');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 선택된 레이아웃 이미지 가져오기 (시각적 레퍼런스로 SVG 생성에 전달)
    Uint8List? selectedLayoutImage;
    if (layoutIndex < _layoutImages.length) {
      selectedLayoutImage = _layoutImages[layoutIndex];
      debugPrint('[Flow] 레이아웃 이미지 전달: ${selectedLayoutImage.length} bytes');
    }

    try {
      // SVG 1장 생성 + 업로드 (레이아웃 이미지를 시각적 프롬프트로 포함)
      final result = await VisageSvgService.generateAndUpload(
        moodKeywords: userPrompt,
        designStyle: _selectedStyle ?? DesignStyle.softRound,
        userPrompt: _promptData?.text ?? '',
        layoutPrompt: layoutPrompt,
        layoutImage: selectedLayoutImage,
        userId: uid,
        onState: (state) {
          debugPrint('[Flow] SVG 진행: $state');
        },
      );

      if (!mounted) return;

      if (result != null) {
        setState(() => _compositeUploadResults.add(result));
      }

      debugPrint('[Flow] SVG 업로드 ${result != null ? "완료" : "실패"}');

      // SVG 업로드 완료 후 Desk 워크플로우 진입
      _handleDeskGeneration(layoutIndex);
    } catch (e) {
      debugPrint('[Flow] SVG 생성 오류: $e');
      if (mounted) {
        _showWarningDialog('An error occurred during SVG generation: $e');
        _goToStep(CreationStep.layoutRecommend);
      }
    }
  }

  void _onRegenerateLayouts() {
    if (_selectedStyle != null) {
      _goToStep(CreationStep.layoutGenerating);
      _recommendAndGenerateLayouts(_selectedStyle!);
    }
  }

  // =========================================================================
  // 🎨 Desk 워크플로우 - Shadow Agent를 통한 컴카드 생성
  // =========================================================================

  /// 레이아웃 선택 후 Desk 워크플로우로 진입
  ///
  /// 플로우:
  /// 1. 소스 프로젝트(템플릿) 조회
  /// 2. 초기 데이터 로드 (슬라이더 + 레이어)
  /// 3. 새 프로젝트 ID 생성
  /// 4. Shadow Agent 백엔드 호출 (비동기)
  /// 5. Shadow Preview View로 네비게이션
  Future<void> _handleDeskGeneration(int layoutIndex) async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('[Desk] Desk 워크플로우 진입 (레이아웃 #$layoutIndex)');

      // Step 1: 소스 프로젝트(템플릿) 조회
      const sourceProjectId = 'aBNcKEZlYr0DHlllbHlC';

      final sourceProject =
          await NyxProjectDatabaseFirecatCrudController.getProjectDatabase(
            sourceProjectId,
            database: '',
          );

      if (sourceProject == null) {
        debugPrint('[Desk] ❌ 소스 프로젝트를 찾을 수 없습니다: $sourceProjectId');
        if (mounted) {
          _showWarningDialog('Template project not found.');
          _goToStep(CreationStep.layoutRecommend);
        }
        return;
      }
      debugPrint('[Desk] ✓ 소스 프로젝트 로드 완료: ${sourceProject.documentRef?.id}');

      // Step 2: 초기 데이터 로드 (슬라이더 + 레이어)
      final (initialSlider, initialLayers) = await _loadShadowInitialData(
        sourceProject,
      );
      if (initialSlider == null) {
        debugPrint('[Desk] ❌ 초기 슬라이더 데이터를 로드할 수 없습니다.');
        if (mounted) {
          _showWarningDialog('Failed to load initial slider data.');
          _goToStep(CreationStep.layoutRecommend);
        }
        return;
      }

      // Step 3: 새 프로젝트 ID 생성
      final projectId = FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: NyxConstants.databaseName,
      ).collection(NyxConstants.collectionNyxProject).doc().id;
      debugPrint('[Desk] 🆔 생성된 프로젝트 ID: $projectId');

      // Step 4: Shadow Agent 백엔드 호출 (비동기)
      final userPrompt = _analyzedPrompt ?? _promptData?.text ?? '';
      _generateShadowAsync(
        sourceProject.documentRef!.id,
        userPrompt,
        projectId,
      );

      // Step 5: Shadow Preview View로 네비게이션
      if (mounted) {
        _navigateToShadowView(initialSlider, initialLayers, projectId);
      }

      debugPrint('[Desk] ✓ Desk 워크플로우 진입 완료');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      debugPrint('[Desk] ❌ Desk 워크플로우 오류: $e');
      if (mounted) {
        _showWarningDialog(
          'An error occurred while creating the comp card: $e',
        );
        _goToStep(CreationStep.layoutRecommend);
      }
    }
  }

  /// Shadow 초기 데이터 로드 (슬라이더 + 레이어)
  ///
  /// 선택된 프로젝트의 첫 번째 슬라이더와 그 레이어들을 로드
  /// - null을 반환하면 호출자에서 에러 처리
  Future<(ProjectSliderUXThumbCardStore?, List<SliderLayerUXThumbCardStore>)>
  _loadShadowInitialData(NyxProjectUXThumbCardStore sourceProject) async {
    try {
      debugPrint('[Desk] 📦 Shadow 초기 데이터 로드 시작');

      // Step 1: 첫 번째 슬라이더 로드
      final initialSlider =
          await ProjectSliderFirecatCRUDController.getFirstSlider(
            sourceProject.documentRef!,
          );
      if (initialSlider == null) {
        debugPrint('[Desk] ❌ 슬라이더를 찾을 수 없습니다.');
        return (null, <SliderLayerUXThumbCardStore>[]);
      }
      debugPrint('[Desk] ✓ 슬라이더 로드 완료: ${initialSlider.itemRef?.id}');

      // Step 2: 슬라이더의 레이어들 로드
      final initialLayers =
          await SliderLayerFirecatCRUDController.getSliderLayerList(
            initialSlider.itemRef!,
          );
      debugPrint('[Desk] ✓ 레이어 로드 완료: ${initialLayers.length}개');

      return (initialSlider, initialLayers);
    } catch (e) {
      debugPrint('[Desk] ❌ Shadow 초기 데이터 로드 실패: $e');
      return (null, <SliderLayerUXThumbCardStore>[]);
    }
  }

  /// Shadow 백엔드 생성 (비동기, 실패해도 무시)
  ///
  /// Cloud Function을 호출하여 Shadow 콘텐츠 생성
  /// - 실패해도 View는 계속 표시됨 (Firestore 리스너가 자동으로 업데이트)
  void _generateShadowAsync(
    String sourceProjectId,
    String userPrompt,
    String projectId,
  ) {
    debugPrint('[Desk] 🚀 Agent Shadow 백엔드 호출 시작');
    NyxAI.generateAgentShadow(
          sourceProjectId: sourceProjectId,
          userPrompt: userPrompt,
          sourceDatabaseId: 'default',
          targetDatabaseId: NyxConstants.databaseName,
          targetProjectId: projectId,
          uploadId: _compositeUploadResults
              .map((e) => e.documentRef!.id)
              .toList(),
        )
        .then((result) {
          debugPrint('[Desk] ✓ Agent Shadow 완료: ${result.message}');
        })
        .catchError((e) {
          debugPrint('[Desk] ❌ Agent Shadow 백엔드 호출 오류: $e');
        });
  }

  /// Shadow View로 네비게이션
  void _navigateToShadowView(
    ProjectSliderUXThumbCardStore initialSlider,
    List<SliderLayerUXThumbCardStore> initialLayers,
    String projectId,
  ) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => NyxCanvasAiAgentShadowView(
          databaseId: NyxConstants.databaseName,
          projectId: projectId,
          initialSlider: initialSlider,
          initialLayers: initialLayers,
          onCanvasProject: _navigateToCanvasView,
        ),
        fullscreenDialog: true,
      ),
      (route) => route.isFirst,
    );
  }

  /// Shadow 완료 후 Canvas View로 이동
  Future<void> _navigateToCanvasView(
    NyxProjectUXThumbCardStore nyxProject,
  ) async {
    try {
      // 현재 로그인된 사용자 정보 조회
      final uid = NyxMemberFirecatAuthController.getCurrentUserUid();
      if (uid == null) {
        debugPrint('[Desk] ❌ 로그인 정보를 찾을 수 없습니다.');
        return;
      }

      final member = await NyxMemberFirecatCrudController.getMember(uid);
      if (member == null || !mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => NyxCanvasView(
            projectUXThumbCardStore: nyxProject,
            playerUXThumbCardStore: member,
            databaseId: NyxConstants.databaseName,
            onStart: () {},
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      debugPrint('[Desk] ❌ Canvas 이동 오류: $e');
    }
  }

  /// 경고 다이얼로그 표시
  void _showWarningDialog(String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'warning',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GlassContainer(
              borderRadius: 24,
              blur: 40,
              opacity: 0.18,
              enableShadow: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.withOpacity(0.8),
                    size: 36,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onCreateNew() {
    setState(() {
      _currentStep = CreationStep.promptInput;
      _isForward = false;
      _promptData = null;
      _analyzedPrompt = null;
      _generatedImages = [];
      _selectedAestheticIndex = null;
      _compositeImages = [];
      _compositeUploadResults = [];
      _selectedStyle = null;
      _recommendedLayoutIndices = [];
      _layoutImages = [];
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
      case CreationStep.styleSelection:
        _goToStep(CreationStep.imageUpload);
      case CreationStep.layoutRecommend:
        _goToStep(CreationStep.styleSelection);
      case CreationStep.layoutGenerating:
      case CreationStep.processing:
      case CreationStep.result:
        break; // Cannot go back from generating/processing/result
    }
  }

  bool get _showBackButton => switch (_currentStep) {
    CreationStep.promptInput ||
    CreationStep.imageSelection ||
    CreationStep.imageUpload ||
    CreationStep.styleSelection ||
    CreationStep.layoutRecommend => true,
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
                    'assets/image/visage_bg_ee.jpeg',
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
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 22,
                ),
              ),
            )
          else
            const SizedBox(width: 54),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.12),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step indicator (4 steps) ---
  Widget _buildStepIndicator() {
    final steps = ['Create Moodboard', 'Image Merge', 'Layout', 'Complete'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          // 4 circles, 3 connectors: calculate spacing
          const circleSize = 48.0;
          const circleCount = 4;
          final connectorWidth =
              (totalWidth - circleSize * circleCount) / (circleCount - 1);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row: circles + connector lines
              Row(
                children: List.generate(steps.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    final stepIndex = index ~/ 2;
                    final isCompleted = _indicatorStep > stepIndex;
                    return SizedBox(
                      width: connectorWidth,
                      child: Container(
                        height: 1.5,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: isCompleted
                            ? const Color(0xFF15234A)
                            : Colors.white.withOpacity(0.15),
                      ),
                    );
                  } else {
                    final stepIndex = index ~/ 2;
                    final isActive = _indicatorStep == stepIndex;
                    final isCompleted = _indicatorStep > stepIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isActive || isCompleted)
                            ? const Color(0xFF15234A)
                            : Colors.white.withOpacity(0.12),
                        border: Border.all(
                          color: (isActive || isCompleted)
                              ? const Color(0xFF15234A)
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 22,
                              )
                            : Text(
                                '${stepIndex + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  }
                }),
              ),
              const SizedBox(height: 8),
              // Bottom row: labels with wider area
              Row(
                children: List.generate(steps.length, (stepIndex) {
                  final isActive = _indicatorStep == stepIndex;

                  if (stepIndex == 0) {
                    // First label: circle width + half connector
                    return SizedBox(
                      width: circleSize + connectorWidth / 2,
                      child: Text(
                        steps[stepIndex],
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.4),
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  } else if (stepIndex == steps.length - 1) {
                    // Last label: half connector + circle width
                    return SizedBox(
                      width: connectorWidth / 2 + circleSize,
                      child: Text(
                        steps[stepIndex],
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.4),
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  } else {
                    // Middle labels: half connector + circle + half connector
                    return SizedBox(
                      width: connectorWidth + circleSize,
                      child: Text(
                        steps[stepIndex],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.4),
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  }
                }),
              ),
            ],
          );
        },
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
          message: 'Generating aesthetic images...',
          subMessage: 'AI is analyzing the prompt and creating images',
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
      case CreationStep.styleSelection:
        child = VisageStyleSelectionStep(
          key: const ValueKey('styleSelection'),
          onStyleSelected: _onStyleSelected,
        );
      case CreationStep.layoutRecommend:
        child = VisageLayoutRecommendStep(
          key: const ValueKey('layoutRecommend'),
          layoutImages: _layoutImages,
          onLayoutSelected: _onLayoutSelected,
          onRegenerate: _onRegenerateLayouts,
        );
      case CreationStep.layoutGenerating:
        child = _buildLoadingStep(
          key: const ValueKey('layoutGenerating'),
          message: 'Recommending layouts...',
          subMessage: 'AI is composing the optimal layout',
        );
      case CreationStep.processing:
        child = _buildLoadingStep(
          key: const ValueKey('processing'),
          message: 'Composing your comp card...',
          subMessage: 'Combining images to create the final comp card',
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
                  color: const Color(0xFF15234A).withOpacity(0.25),
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
                    const Color(0xFF15234A),
                    const Color(0xFF2A4080),
                    const Color(0xFFB5D4FF).withOpacity(0.4),
                    const Color(0xFF15234A).withOpacity(0.0),
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
