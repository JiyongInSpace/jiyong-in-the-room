import 'package:flutter/material.dart';

/// 앱에서 사용하는 모든 색상을 중앙에서 관리하는 클래스
/// 
/// 지도 테마를 기반으로 한 노랑+연황토 색상 팔레트를 사용합니다.
class AppColors {
  // Private constructor - 인스턴스 생성 방지
  AppColors._();

  /// ========== 메인 색상 팔레트 ==========
  
  /// 메인 컬러 - 밝은 노랑 (Material Design의 seedColor)
  /// 사용처: AppBar 배경, 주요 버튼
  static const Color primary = Color(0xFFF4D03F);
  
  /// 세컨더리 컬러 - 따뜻한 오렌지-노랑
  /// 사용처: 액센트 색상, 강조 포인트
  static const Color secondary = Color(0xFFF39C12);
  
  /// 터시어리 컬러 - 연황토색
  /// 사용처: 보조 UI 요소
  static const Color tertiary = Color(0xFFE67E22);
  
  /// 배경 컬러 - 매우 연한 크림색
  /// 사용처: 앱 전체 배경, 카드 배경
  static const Color surface = Color(0xFFFEF9E7);
  
  /// 연한 베이지 배경
  /// 사용처: 섹션 구분, 서브 배경
  static const Color backgroundLight = Color(0xFFFDF2E9);

  /// ========== 상태별 색상 ==========
  
  /// 성공 색상 그룹
  static const Color success = Colors.green;
  static const Color successLight = Color(0xFFE8F5E8);
  static final Color successShade = Colors.green.shade600;
  
  /// 실패/에러 색상 그룹
  static const Color error = Colors.red;
  static const Color errorLight = Color(0xFFFFEBEE);
  static final Color errorShade = Colors.red.shade600;
  
  /// 경고 색상 그룹 (오렌지 계열로 메인 테마와 조화)
  static final Color warning = Colors.orange.shade600;
  static final Color warningLight = Colors.orange.shade50;
  static final Color warningDark = Colors.orange.shade700;

  /// ========== 중성 색상 ==========
  
  /// 텍스트 색상
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF757575); // Colors.grey[600]
  static const Color textDisabled = Color(0xFFBDBDBD); // Colors.grey[400]
  
  /// 흰색 계열
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;
  
  /// 회색 계열
  static const Color grey = Colors.grey;
  static final Color greyLight = Colors.grey.shade100;
  static final Color greyMedium = Colors.grey.shade300;
  static final Color greyDark = Colors.grey.shade600;
  
  /// 검은색 계열
  static const Color black = Colors.black;
  static final Color blackLight = Colors.black.withOpacity(0.1);
  static final Color blackMedium = Colors.black.withOpacity(0.2);

  /// ========== 특수 용도 색상 ==========
  
  /// 앰버 (별점 표시)
  static const Color amber = Colors.amber;
  static final Color amberShade = Colors.amber.shade600;
  
  /// 스탬프 배경 색상
  static final Color stampSuccessBackground = Colors.green.shade100;
  static final Color stampFailBackground = Colors.red.shade100;
  static final Color stampUnknownBackground = Colors.grey.shade100;
  
  /// 친구 연동 상태 색상
  static final Color friendConnected = success;
  static final Color friendNotConnected = greyDark;
  
  /// 프로필 구분 색상 (본인 표시)
  static final Color selfHighlight = Colors.orange.shade50;
  static final Color selfBorder = Colors.orange.shade200;

  /// ========== 사용처별 색상 가이드 ==========
  
  /// AppBar
  static const Color appBarBackground = primary;
  static const Color appBarText = textPrimary;
  
  /// FloatingActionButton
  static const Color fabBackground = secondary;
  static const Color fabIcon = white;
  
  /// 카드
  static const Color cardBackground = white;
  static final Color cardShadow = blackLight;
  
  /// 바텀시트
  static final Color bottomSheetHandle = greyMedium;
  static final Color bottomSheetBackground = white;
  static final Color bottomSheetShadow = blackLight;
  
  /// 스켈레톤 로딩
  static final Color skeletonBase = Colors.grey.withOpacity(0.3);
  static final Color skeletonHighlight = Colors.grey.withOpacity(0.1);
  
  /// 오프라인 배너
  static final Color offlineBanner = errorShade;
  static final Color onlineBanner = successShade;
  
  /// 드래그 핸들
  static final Color dragHandle = greyMedium;

  /// ========== 헬퍼 메서드 ==========
  
  /// 색상에 투명도를 적용하는 헬퍼 메서드
  /// 
  /// [color] 기본 색상
  /// [opacity] 투명도 (0.0 ~ 1.0)
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
  
  /// 밝기에 따른 텍스트 색상을 반환하는 헬퍼 메서드
  /// 
  /// [backgroundColor] 배경 색상
  /// 어두운 배경이면 흰색, 밝은 배경이면 검은색 반환
  static Color getContrastingTextColor(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? white : black;
  }
  
  /// 상태별 색상을 반환하는 헬퍼 메서드
  /// 
  /// [isSuccess] 성공 상태 여부
  /// [isError] 에러 상태 여부
  /// [isWarning] 경고 상태 여부
  static Color getStatusColor({
    bool isSuccess = false,
    bool isError = false,
    bool isWarning = false,
  }) {
    if (isSuccess) return success;
    if (isError) return error;
    if (isWarning) return warning;
    return greyDark;
  }
  
  /// 탈출 결과에 따른 색상을 반환하는 헬퍼 메서드
  /// 
  /// [escaped] 탈출 성공 여부 (null이면 미지정)
  static Color getEscapeResultColor(bool? escaped) {
    if (escaped == true) return success;
    if (escaped == false) return error;
    return greyDark;
  }
  
  /// 탈출 결과에 따른 배경 색상을 반환하는 헬퍼 메서드
  /// 
  /// [escaped] 탈출 성공 여부 (null이면 미지정)
  static Color getEscapeResultBackground(bool? escaped) {
    if (escaped == true) return stampSuccessBackground;
    if (escaped == false) return stampFailBackground;
    return stampUnknownBackground;
  }
}

/// ========== 색상 사용 가이드 ==========
/// 
/// 1. **메인 색상 (primary, secondary, tertiary)**
///    - 브랜드 아이덴티티를 나타내는 핵심 색상
///    - AppBar, FAB, 주요 버튼에 사용
/// 
/// 2. **상태 색상 (success, error, warning)**
///    - 사용자 액션의 결과나 상태를 나타냄
///    - 성공/실패 메시지, 스탬프, 알림에 사용
/// 
/// 3. **중성 색상 (text, grey, white, black)**
///    - 텍스트, 배경, 구분선 등에 사용
///    - 가독성과 접근성을 고려하여 선택
/// 
/// 4. **특수 색상 (amber, friend colors 등)**
///    - 특정 기능이나 요소를 위한 색상
///    - 별점, 친구 상태 등에 사용
/// 
/// ========== 사용 예시 ==========
/// 
/// ```dart
/// // 기본 사용
/// Container(color: AppColors.primary)
/// 
/// // 헬퍼 메서드 사용
/// Container(color: AppColors.getEscapeResultColor(true)) // 성공 색상
/// 
/// // 투명도 적용
/// Container(color: AppColors.withOpacity(AppColors.primary, 0.5))
/// ```