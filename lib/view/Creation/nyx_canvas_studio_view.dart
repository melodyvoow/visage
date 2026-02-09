import 'package:flutter/material.dart';

import 'package:nyx_kernel/Melody/melody_theme.dart';
import 'package:nyx_kernel/Melody/component/melody_typography.dart';
import 'package:nyx_kernel/Desk/Canvas/Firecat/Main/firecat_nyx_canvas_main_listener.dart';
import 'package:nyx_kernel/Desk/Canvas/nyx_canvas_view.dart';
import 'package:nyx_kernel/Firecat/api/nyx_service_manager.dart';
import 'package:nyx_kernel/core/firestore_collections.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxMember/nyx_member_firecat_auth_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxMember/nyx_member_firecat_crud_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxMember/nyx_member_ux_card.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxProject/ProjectSlider/project_slider_firecat_crud_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxProject/nyx_project_default_firecat_crud_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxProject/nyx_project_firecat_crud_controller.dart';
import 'package:nyx_kernel/Firecat/viewmodel/NyxProject/nyx_project_ux_card.dart';

/// Nyx Canvas Studio View - 캔버스 에디터의 메인 화면을 관리하는 StatefulWidget
///
/// 이 클래스는 다음 주요 기능들을 담당합니다:
/// - 사용자 인증 및 프로젝트 초기화
/// - 기존 프로젝트 로드 또는 새 프로젝트 생성
/// - 폰트 로딩 및 프로젝트 설정 관리
/// - 로딩 상태 및 에러 처리
class NyxCanvasStudioView extends StatefulWidget {
  const NyxCanvasStudioView({super.key, required this.projectUXThumbCardStore, required this.databaseId});

  /// 기존 프로젝트 데이터 (null인 경우 새 프로젝트 생성)
  final NyxProjectUXThumbCardStore? projectUXThumbCardStore;
  final String databaseId;

  @override
  State<NyxCanvasStudioView> createState() => _NyxCanvasStudioViewState();
}

class _NyxCanvasStudioViewState extends State<NyxCanvasStudioView> {
  // ==========================================================================
  // CONSTANTS
  // ==========================================================================

  static const int _defaultCanvasSize = 1080;
  static const Duration _initializationDelay = Duration(milliseconds: 100);
  static const Duration _errorMessageDelay = Duration(seconds: 3);
  static const double _loadingSpacing = 16.0;
  static const double _smallSpacing = 8.0;

  // ==========================================================================
  // STATE VARIABLES
  // ==========================================================================

  /// 현재 로그인한 사용자의 정보를 저장하는 변수
  NyxMemberUXThumbCardStore? _playerUXThumbCardStore;

  /// 현재 작업 중인 프로젝트의 정보를 저장하는 변수
  NyxProjectUXThumbCardStore? _projectUXThumbCardStore;

  /// 프로젝트 생성/로딩 중인지를 나타내는 플래그
  bool _isUploading = false;

  /// 로딩 중 사용자에게 표시할 메시지
  String _messageData = '잠시만 기다려주세요.';

  /// 현재 로딩 중인 폰트 패밀리명
  String _loadedFontFamily = '';

  // ==========================================================================
  // LIFECYCLE METHODS
  // ==========================================================================

  @override
  void initState() {
    super.initState();
    debugPrint("NyxCanvasStudioView : initState() - 초기화 시작");

    // 위젯이 완전히 빌드된 후 초기화 작업을 수행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint("NyxCanvasStudioView : initState() - PostFrameCallback 실행");
        _initializePlayer();
        _initializeProject();
      }
    });
  }

  @override
  void dispose() {
    FirecatNyxCanvasMainListener.dispose();
    super.dispose();
  }

  // ==========================================================================
  // INITIALIZATION METHODS
  // ==========================================================================
  /// 현재 로그인한 사용자의 정보를 조회하고 설정
  Future<void> _initializePlayer() async {
    debugPrint("NyxCanvasStudioView : _initializePlayer() - 플레이어 초기화 시작");

    final uid = _getCurrentUserId();
    if (uid == null) return;

    debugPrint("NyxCanvasStudioView : _initializePlayer() - 사용자 UID: $uid");

    try {
      final data = await NyxMemberFirecatCrudController.getMember(uid);
      if (mounted) {
        debugPrint("NyxCanvasStudioView : _initializePlayer() - 사용자 데이터 로드 완료");
        setState(() => _playerUXThumbCardStore = data);
      }
    } catch (error) {
      _handleError("사용자 정보 로드 중 오류 발생", error);
    }
  }

  /// 현재 사용자 ID를 가져오고 로그를 출력
  String? _getCurrentUserId() {
    final uid = NyxMemberFirecatAuthController.getCurrentUserUid();
    if (uid == null) {
      debugPrint("NyxCanvasStudioView : 사용자 UID가 null입니다");
    }
    return uid;
  }

  /// 에러 처리를 위한 공통 메서드
  void _handleError(String message, dynamic error) {
    debugPrint("NyxCanvasStudioView : $message: $error");
    if (mounted) {
      setState(() {
        _isUploading = false;
        _messageData = message;
      });
    }
  }

  // ==========================================================================
  // PROJECT INITIALIZATION METHODS
  // ==========================================================================
  /// 기존 프로젝트를 로드할지 새 프로젝트를 생성할지 결정
  void _initializeProject() {
    debugPrint("NyxCanvasStudioView : _initializeProject() - 프로젝트 초기화 시작");

    widget.projectUXThumbCardStore != null ? _loadExistingProject() : _handleNewProject();
  }

  /// 기존 프로젝트와 관련 폰트들을 로드
  void _loadExistingProject() {
    debugPrint("NyxCanvasStudioView : _loadExistingProject() - 기존 프로젝트 로드 시작");

    final projectData = widget.projectUXThumbCardStore!;
    final fontFamilies = projectData.projectData!.ee_list_font_family;

    if (fontFamilies != null && fontFamilies.isNotEmpty) {
      debugPrint("NyxCanvasStudioView : _loadExistingProject() - 폰트 로딩 시작, 폰트 수: ${fontFamilies.length}");
      _loadFontsAndSetProject(projectData, fontFamilies);
    } else {
      debugPrint("NyxCanvasStudioView : _loadExistingProject() - 폰트 없음, 프로젝트 바로 설정");
      setState(() => _projectUXThumbCardStore = projectData);
    }
  }

  /// 프로젝트의 폰트들을 로드하고 프로젝트 상태를 설정
  void _loadFontsAndSetProject(NyxProjectUXThumbCardStore projectData, List<String> fontFamilies) {
    debugPrint("NyxCanvasStudioView : _loadFontsAndSetProject() - 폰트 로딩 시작");

    // 폰트 로딩 상태를 UI에 표시
    _setLoadingState(true, '폰트를 로딩 중입니다...');

    NyxFontLoaderService.loadFontsFromStore(fontFamilies, (fontFamily) {
          if (mounted) {
            debugPrint("NyxCanvasStudioView : _loadFontsAndSetProject() - 폰트 로딩 중: $fontFamily");
            setState(() {
              _loadedFontFamily = fontFamily;
              _messageData = '폰트 로딩 중: $fontFamily';
            });
          }
        })
        .then((_) {
          if (mounted) {
            debugPrint("NyxCanvasStudioView : _loadFontsAndSetProject() - 폰트 로딩 완료, 프로젝트 설정");
            setState(() {
              _projectUXThumbCardStore = projectData;
              _isUploading = false;
              _messageData = '프로젝트 로딩 완료';
            });
          }
        })
        .catchError((error) {
          debugPrint("NyxCanvasStudioView : _loadFontsAndSetProject() - 폰트 로딩 에러: $error");
          _handleFontLoadingError(projectData);
        });
  }

  /// 폰트 로딩 실패 시 처리
  void _handleFontLoadingError(NyxProjectUXThumbCardStore projectData) {
    if (mounted) {
      // 폰트 로딩에 실패해도 프로젝트는 설정하되, 경고 메시지 표시
      setState(() {
        _projectUXThumbCardStore = projectData;
        _isUploading = false;
        _messageData = '일부 폰트 로딩에 실패했지만 프로젝트를 계속 진행합니다';
      });

      // 3초 후 메시지 초기화
      Future.delayed(_errorMessageDelay, () {
        if (mounted) {
          setState(() {
            _messageData = '잠시만 기다려주세요.';
          });
        }
      });
    }
  }

  /// 로딩 상태 설정 헬퍼 메서드
  void _setLoadingState(bool isLoading, String message) {
    if (mounted) {
      setState(() {
        _isUploading = isLoading;
        _messageData = message;
      });
    }
  }

  /// 새 프로젝트 생성 흐름을 처리
  void _handleNewProject() {
    final uid = _getCurrentUserId();
    if (uid == null) return;

    debugPrint("NyxCanvasStudioView : _handleNewProject() - 사용자 $uid 의 새 프로젝트 흐름 시작");

    // 홈 뷰가 완전히 안정된 후 프로젝트 로딩을 위한 소량의 지연 추가
    Future.delayed(_initializationDelay, () {
      if (!mounted) return;

      _getNewestProjectByMember(uid);
    });
  }

  /// 사용자의 최신 프로젝트를 조회
  Future<void> _getNewestProjectByMember(String uid) async {
    try {
      final projectData = await NyxProjectFirecatCrudController.getNewestProjectByMember(memberId: uid);

      if (!mounted) return;

      debugPrint("NyxCanvasStudioView : _handleNewProject() - 최신 프로젝트 조회 완료 - 존재: ${projectData != null}");

      if (projectData == null) {
        debugPrint("NyxCanvasStudioView : _handleNewProject() - 기존 프로젝트 없음, 새 프로젝트 생성");
        _createProject(uid);
        return;
      }

      debugPrint("NyxCanvasStudioView : _handleNewProject() - 기존 프로젝트의 슬라이더 확인");
      _checkExistingProjectSliders(uid, projectData);
    } catch (error) {
      _handleError("프로젝트 조회 중 오류 발생", error);
    }
  }

  /// 기존 프로젝트를 사용할 수 있는지 또는 새 프로젝트를 생성해야 하는지 확인
  void _checkExistingProjectSliders(String uid, NyxProjectUXThumbCardStore projectData) {
    debugPrint(
      "NyxCanvasStudioView : _checkExistingProjectSliders() - 프로젝트 슬라이더 확인 - 개수: ${projectData.projectData!.ee_list_order_slider.length}",
    );

    // 프로젝트에 정확히 하나의 슬라이더가 있는 경우, 비어있고 사용 가능한지 확인
    final sliderCount = projectData.projectData!.ee_list_order_slider.length;

    if (sliderCount == 1) {
      debugPrint("NyxCanvasStudioView : _checkExistingProjectSliders() - 단일 슬라이더 발견, 내용 확인");
      _checkSliderContent(uid, projectData);
    } else {
      debugPrint("NyxCanvasStudioView : _checkExistingProjectSliders() - 다중 슬라이더 발견, 새 프로젝트 생성");
      _createProject(uid);
    }
  }

  /// 슬라이더가 비어있고 사용 가능한지 확인
  Future<void> _checkSliderContent(String uid, NyxProjectUXThumbCardStore projectData) async {
    try {
      final sliderId = projectData.projectData!.ee_list_order_slider.first;

      // 슬라이더 데이터 확인
      final sliderData = await ProjectSliderFirecatCRUDController.getSliderById(projectData.documentRef!, sliderId);

      if (!mounted) return;

      // 슬라이더가 없으면 새 프로젝트 생성
      if (sliderData == null) {
        _createProject(uid);
        return;
      }

      // 레이어 개수 확인 (성능 최적화를 위해 count 사용)
      final layerCountSnapshot = await FirestoreCollections.getSliderLayerCollectionFromRef(
        projectData.documentRef!,
        sliderId,
      ).count().get();

      if (!mounted) return;

      final layerCount = layerCountSnapshot.count ?? 0;
      debugPrint("NyxCanvasStudioView : 레이어 개수: $layerCount");

      // 레이어가 없으면 기존 프로젝트 사용, 있으면 새 프로젝트 생성
      if (layerCount == 0) {
        setState(() => _projectUXThumbCardStore = projectData);
      } else {
        _createProject(uid);
      }
    } catch (error) {
      debugPrint("NyxCanvasStudioView : 슬라이더 확인 에러 - 새 프로젝트 생성: $error");
      if (mounted) _createProject(uid);
    }
  }

  // ==========================================================================
  // PROJECT CREATION METHODS
  // ==========================================================================

  /// 기본 프로젝트 생성 (사용자 정의 설정 가능)
  Future<void> _createProject(String uid, {String? projectName, int? canvasWidth, int? canvasHeight}) async {
    // 프로젝트 생성을 시작하기 전에 위젯이 아직 마운트되어 있는지 확인
    if (!mounted) return;

    // 로딩 상태 설정
    _setLoadingState(true, '새 프로젝트를 생성하고 있습니다...');

    try {
      final result = await NyxProjectDefaultFirecatCrudController.createProjectDefault(
        memberId: uid,
        projectDefaultName: projectName ?? '새 프로젝트',
        canvasWidth: canvasWidth ?? _defaultCanvasSize,
        canvasHeight: canvasHeight ?? _defaultCanvasSize,
      );

      if (!mounted) return;

      if (result == null) {
        debugPrint("NyxCanvasStudioView : _createProject() - 프로젝트 생성 실패");
        _setLoadingState(false, '프로젝트 생성에 실패했습니다.');
        return;
      }

      // 프로젝트 생성이 성공하면 최신 프로젝트를 다시 불러옵니다.
      setState(() {
        _projectUXThumbCardStore = result;
        _isUploading = false;
      });
    } catch (error) {
      debugPrint("NyxCanvasStudioView : _createProject() - 프로젝트 생성 중 에러: $error");
      _handleError('프로젝트 생성 중 오류가 발생했습니다', error);
    }
  }

  // ==========================================================================
  // UI BUILD METHODS
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildContent());
  }

  /// 로딩 상태에 따라 적절한 콘텐츠를 빌드합니다
  Widget _buildContent() {
    // 플레이어 또는 프로젝트 데이터가 아직 로드되지 않은 경우 로딩 인디케이터 표시
    if (_playerUXThumbCardStore == null || _projectUXThumbCardStore == null) {
      return _buildLoadingIndicator(_loadedFontFamily, '폰트 로딩 중...');
    }

    // 템플릿 업로드 중일 때 로딩 인디케이터 표시
    if (_isUploading) {
      return _buildLoadingIndicator('', _messageData);
    }

    // 모든 데이터가 로드되었을 때 메인 캔버스 뷰 표시
    return _buildMainContent();
  }

  /// 메인 캔버스 뷰를 빌드합니다
  Widget _buildMainContent() {
    return NyxCanvasView(
      playerUXThumbCardStore: _playerUXThumbCardStore!,
      projectUXThumbCardStore: _projectUXThumbCardStore!,
      onStart: () {},
      databaseId: widget.databaseId,
    );
  }

  /// 메시지와 함께 로딩 인디케이터를 빌드합니다
  Widget _buildLoadingIndicator(String fontName, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: MelodyTheme.home.primary),
          SizedBox(height: _loadingSpacing),

          if (fontName.isNotEmpty) ...[
            Text('폰트 로딩 중: $fontName', style: MelodyTextStyle.p14_w600.copyWith(color: MelodyTheme.home.primary)),
            SizedBox(height: _smallSpacing),
          ],

          Text(
            message,
            style: MelodyTextStyle.p12_w400.copyWith(color: MelodyTheme.home.pureBlack),
            textAlign: TextAlign.center,
          ),

          if (_isUploading && fontName.isEmpty) ...[
            SizedBox(height: _loadingSpacing),
            Text('프로젝트를 설정하고 있습니다...', style: MelodyTextStyle.p10_w400.copyWith(color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }
}
