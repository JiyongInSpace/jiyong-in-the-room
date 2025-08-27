import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 네트워크 연결 상태를 관리하는 서비스
/// 
/// 주요 기능:
/// - 실시간 네트워크 연결 상태 모니터링
/// - Supabase 연결 상태 확인
/// - 오프라인/온라인 상태 변경 이벤트 제공
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectionTestTimer;

  /// 현재 연결 상태
  bool get isConnected => _isConnected;
  
  /// 연결 상태 변경 스트림
  Stream<bool> get connectionStream => _connectionController.stream;

  /// 서비스 초기화
  Future<void> initialize() async {
    // 초기 연결 상태 확인
    await _checkInitialConnection();
    
    // 연결 상태 모니터링 시작
    _startMonitoring();
    
    if (kDebugMode) {
      print('🌐 ConnectivityService 초기화 완료 - 현재 상태: ${_isConnected ? "온라인" : "오프라인"}');
    }
  }

  /// 초기 연결 상태 확인
  Future<void> _checkInitialConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final hasNetworkConnection = !connectivityResults.contains(ConnectivityResult.none);
      
      if (hasNetworkConnection) {
        // 네트워크는 연결되어 있지만 실제 인터넷 연결 확인
        final isActuallyConnected = await _testSupabaseConnection();
        _updateConnectionStatus(isActuallyConnected);
      } else {
        _updateConnectionStatus(false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ 초기 연결 상태 확인 실패: $e');
      }
      _updateConnectionStatus(false);
    }
  }

  /// 네트워크 연결 모니터링 시작
  void _startMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final hasNetworkConnection = !results.contains(ConnectivityResult.none);
        
        if (hasNetworkConnection) {
          // 네트워크 연결이 있을 때만 실제 연결 테스트
          final isActuallyConnected = await _testSupabaseConnection();
          _updateConnectionStatus(isActuallyConnected);
        } else {
          _updateConnectionStatus(false);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ 연결 모니터링 에러: $error');
        }
        _updateConnectionStatus(false);
      },
    );

    // 주기적으로 실제 연결 상태 확인 (30초마다)
    _startPeriodicConnectionTest();
  }

  /// 주기적 연결 테스트 시작
  void _startPeriodicConnectionTest() {
    _connectionTestTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (_isConnected) {
          // 현재 연결 상태일 때만 테스트 (불필요한 요청 방지)
          final isStillConnected = await _testSupabaseConnection();
          if (!isStillConnected) {
            _updateConnectionStatus(false);
          }
        }
      },
    );
  }

  /// Supabase 연결 상태 테스트
  Future<bool> _testSupabaseConnection() async {
    try {
      // Supabase에 간단한 쿼리 실행으로 연결 테스트
      await Supabase.instance.client
          .from('profiles')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('🔍 Supabase 연결 테스트 실패: $e');
      }
      return false;
    }
  }

  /// 연결 상태 업데이트
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(isConnected);
      
      if (kDebugMode) {
        print('🌐 연결 상태 변경: ${isConnected ? "온라인" : "오프라인"}');
      }
    }
  }

  /// 수동 연결 상태 재확인
  Future<bool> refreshConnectionStatus() async {
    await _checkInitialConnection();
    return _isConnected;
  }

  /// 오프라인 모드에서 사용할 수 있는 기능들 확인
  Map<String, bool> getOfflineCapabilities() {
    return {
      '일지 목록 보기': true,  // 로컬에 캐시된 데이터
      '친구 목록 보기': true,  // 로컬에 캐시된 데이터
      '새 일지 작성': false,   // 온라인 필요
      '친구 추가': false,      // 온라인 필요
      '프로필 수정': false,    // 온라인 필요
      '검색 기능': false,      // 서버 데이터 필요
    };
  }

  /// 서비스 정리
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionTestTimer?.cancel();
    _connectionController.close();
    
    if (kDebugMode) {
      print('🌐 ConnectivityService 정리 완료');
    }
  }
}