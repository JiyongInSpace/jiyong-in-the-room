import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 커스텀 예외 클래스들
class FriendNotFoundException implements Exception {
  final String message;
  FriendNotFoundException(this.message);
  @override
  String toString() => message;
}

class DuplicateFriendException implements Exception {
  final String message;
  DuplicateFriendException(this.message);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => message;
}

class DiaryValidationException implements Exception {
  final String message;
  DiaryValidationException(this.message);
  @override
  String toString() => message;
}

/// 에러 유형 정의
enum ErrorType {
  network,      // 네트워크 관련 에러
  auth,         // 인증 관련 에러
  validation,   // 입력 검증 에러
  permission,   // 권한 관련 에러
  server,       // 서버 관련 에러
  unknown,      // 알 수 없는 에러
}

/// 에러 정보 클래스
class ErrorInfo {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final ErrorType type;
  final String? actionText;
  final VoidCallback? action;

  const ErrorInfo({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.type,
    this.actionText,
    this.action,
  });
}

/// 에러 처리 및 사용자 친화적 메시지 변환을 담당하는 서비스
/// 
/// 주요 기능:
/// - 시스템 에러를 사용자가 이해하기 쉬운 메시지로 변환
/// - 에러 유형별 아이콘 및 색상 지정
/// - 통합된 에러 표시 UI 제공
class ErrorService {

  /// 에러 메시지 매핑 테이블
  static final Map<String, ErrorInfo> _errorMappings = {
    // 네트워크 에러
    'SocketException': ErrorInfo(
      title: '인터넷 연결 실패',
      message: '인터넷 연결을 확인한 후 다시 시도해주세요.',
      icon: Icons.wifi_off_rounded,
      color: Colors.orange,
      type: ErrorType.network,
      actionText: '다시 시도',
    ),
    
    'TimeoutException': ErrorInfo(
      title: '연결 시간 초과',
      message: '서버 응답이 지연되고 있습니다.\n잠시 후 다시 시도해주세요.',
      icon: Icons.timer_outlined,
      color: Colors.orange,
      type: ErrorType.network,
      actionText: '다시 시도',
    ),

    'HttpException': ErrorInfo(
      title: '서버 연결 실패',
      message: '서버와 통신 중 문제가 발생했습니다.\n잠시 후 다시 시도해주세요.',
      icon: Icons.cloud_off_outlined,
      color: Colors.red,
      type: ErrorType.server,
      actionText: '다시 시도',
    ),

    // 인증 에러
    'AuthException': ErrorInfo(
      title: '로그인 실패',
      message: '로그인 정보를 확인해주세요.',
      icon: Icons.lock_outline,
      color: Colors.red,
      type: ErrorType.auth,
      actionText: '다시 로그인',
    ),

    'SignInWithGoogleException': ErrorInfo(
      title: 'Google 로그인 실패',
      message: 'Google 계정으로 로그인할 수 없습니다.\n다시 시도하거나 다른 방법을 이용해주세요.',
      icon: Icons.account_circle_outlined,
      color: Colors.red,
      type: ErrorType.auth,
      actionText: '다시 시도',
    ),

    // 입력 검증 에러
    'ValidationException': ErrorInfo(
      title: '입력 정보 확인',
      message: '입력하신 정보를 다시 확인해주세요.',
      icon: Icons.edit_outlined,
      color: Colors.amber,
      type: ErrorType.validation,
    ),

    'FormatException': ErrorInfo(
      title: '잘못된 형식',
      message: '올바른 형식으로 입력해주세요.',
      icon: Icons.format_list_bulleted,
      color: Colors.amber,
      type: ErrorType.validation,
    ),

    // 권한 에러
    'PermissionException': ErrorInfo(
      title: '권한이 필요합니다',
      message: '이 기능을 사용하려면 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
      icon: Icons.security_outlined,
      color: Colors.blue,
      type: ErrorType.permission,
      actionText: '설정으로 이동',
    ),

    // Supabase 특정 에러
    'PostgrestException': ErrorInfo(
      title: '데이터 처리 실패',
      message: '데이터를 처리하는 중 문제가 발생했습니다.\n잠시 후 다시 시도해주세요.',
      icon: Icons.storage_outlined,
      color: Colors.red,
      type: ErrorType.server,
      actionText: '다시 시도',
    ),

    'StorageException': ErrorInfo(
      title: '파일 업로드 실패',
      message: '파일을 업로드할 수 없습니다.\n파일 크기나 형식을 확인해주세요.',
      icon: Icons.cloud_upload_outlined,
      color: Colors.red,
      type: ErrorType.server,
      actionText: '다시 시도',
    ),

    // 친구 관련 에러
    'FriendNotFoundException': ErrorInfo(
      title: '친구를 찾을 수 없습니다',
      message: '입력하신 친구 코드가 올바르지 않습니다.\n코드를 다시 확인해주세요.',
      icon: Icons.person_search_outlined,
      color: Colors.orange,
      type: ErrorType.validation,
    ),

    'DuplicateFriendException': ErrorInfo(
      title: '이미 등록된 친구입니다',
      message: '이미 친구 목록에 있는 사용자입니다.',
      icon: Icons.person_add_disabled_outlined,
      color: Colors.amber,
      type: ErrorType.validation,
    ),

    // 일지 관련 에러
    'DiaryValidationException': ErrorInfo(
      title: '일지 정보 확인',
      message: '필수 정보를 모두 입력해주세요.',
      icon: Icons.edit_note_outlined,
      color: Colors.amber,
      type: ErrorType.validation,
    ),
  };

  /// 기본 에러 정보
  static const ErrorInfo _defaultError = ErrorInfo(
    title: '예상치 못한 오류',
    message: '알 수 없는 문제가 발생했습니다.\n잠시 후 다시 시도해주세요.',
    icon: Icons.error_outline,
    color: Colors.red,
    type: ErrorType.unknown,
    actionText: '다시 시도',
  );

  /// 에러 객체를 사용자 친화적 정보로 변환
  static ErrorInfo parseError(dynamic error) {
    if (kDebugMode) {
      print('🔍 Error parsing: ${error.runtimeType} - $error');
    }

    // 에러 타입 및 메시지 추출
    String errorType = error.runtimeType.toString();
    String errorMessage = error.toString().toLowerCase();

    // 특정 키워드로 에러 유형 판별
    for (var entry in _errorMappings.entries) {
      if (errorType.contains(entry.key) || 
          errorMessage.contains(entry.key.toLowerCase()) ||
          _containsErrorKeyword(errorMessage, entry.key)) {
        return entry.value;
      }
    }

    // 에러 메시지 내용으로 유형 추론
    if (errorMessage.contains('network') || 
        errorMessage.contains('internet') ||
        errorMessage.contains('connection')) {
      return _errorMappings['SocketException']!;
    }

    if (errorMessage.contains('timeout') || 
        errorMessage.contains('시간') ||
        errorMessage.contains('time out')) {
      return _errorMappings['TimeoutException']!;
    }

    if (errorMessage.contains('auth') || 
        errorMessage.contains('login') ||
        errorMessage.contains('로그인')) {
      return _errorMappings['AuthException']!;
    }

    if (errorMessage.contains('permission') || 
        errorMessage.contains('권한')) {
      return _errorMappings['PermissionException']!;
    }

    if (errorMessage.contains('validation') || 
        errorMessage.contains('format') ||
        errorMessage.contains('형식')) {
      return _errorMappings['ValidationException']!;
    }

    // 기본 에러 반환
    return _defaultError;
  }

  /// 에러 키워드 포함 여부 확인
  static bool _containsErrorKeyword(String message, String keyword) {
    final keywords = {
      'SocketException': ['socket', 'network', '네트워크', '연결'],
      'TimeoutException': ['timeout', '시간초과', '응답없음'],
      'AuthException': ['authentication', 'unauthorized', '인증', '권한없음'],
      'ValidationException': ['invalid', 'required', '필수', '잘못된'],
      'PermissionException': ['permission', 'access denied', '접근거부'],
    };

    final keywordList = keywords[keyword] ?? [];
    return keywordList.any((kw) => message.contains(kw));
  }

  /// 통합 에러 다이얼로그 표시
  static void showErrorDialog(
    BuildContext context, 
    dynamic error, {
    VoidCallback? onRetry,
    String? customTitle,
    String? customMessage,
  }) {
    final errorInfo = parseError(error);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              errorInfo.icon,
              color: errorInfo.color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                customTitle ?? errorInfo.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          customMessage ?? errorInfo.message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
          if (errorInfo.actionText != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (onRetry != null) {
                  onRetry();
                } else if (errorInfo.action != null) {
                  errorInfo.action!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorInfo.color,
              ),
              child: Text(errorInfo.actionText!),
            ),
        ],
      ),
    );
  }

  /// 에러 SnackBar 표시
  static void showErrorSnackBar(
    BuildContext context, 
    dynamic error, {
    String? customMessage,
    VoidCallback? onAction,
  }) {
    final errorInfo = parseError(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              errorInfo.icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                customMessage ?? errorInfo.message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: errorInfo.color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: errorInfo.actionText != null
            ? SnackBarAction(
                label: errorInfo.actionText!,
                textColor: Colors.white,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }

  /// 성공 메시지 표시
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_outline,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 로딩 인디케이터와 함께 에러 안전 실행
  static Future<T?> executeWithErrorHandling<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool showSuccessMessage = true,
  }) async {
    // 로딩 인디케이터 표시
    if (loadingMessage != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(loadingMessage)),
            ],
          ),
        ),
      );
    }

    try {
      final result = await operation();
      
      if (loadingMessage != null && context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
      }
      
      if (showSuccessMessage && successMessage != null && context.mounted) {
        showSuccessSnackBar(context, successMessage);
      }
      
      return result;
    } catch (error) {
      if (loadingMessage != null && context.mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
      }
      
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
      
      if (kDebugMode) {
        print('❌ Operation failed: $error');
      }
      
      return null;
    }
  }
}