import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 네트워크 연결 상태를 관리하는 서비스
/// 
/// 주요 기능:
/// - 실시간 네트워크 연결 상태 모니터링
/// - Supabase 연결 상태 확인
/// - 자동 재시도 메커니즘
/// - 오프라인/온라인 상태 변경 이벤트 제공
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  bool _showingDisconnectedState = false; // UI에 연결 끊김 상태를 표시 중인지
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectionTestTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  /// 현재 연결 상태
  bool get isConnected => _isConnected;
  
  /// UI에 표시할 연결 끊김 상태 (짧은 연결 끊김은 표시하지 않음)
  bool get shouldShowDisconnectedState => _showingDisconnectedState;
  
  /// 연결 상태 변경 스트림 (UI 표시용 - 짧은 끊김은 필터링)
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
          // 네트워크 연결이 있을 때는 재시도 로직 시작
          _startReconnectAttempts();
        } else {
          _handleConnectionLoss();
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ 연결 모니터링 에러: $error');
        }
        _handleConnectionLoss();
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
            _handleConnectionLoss();
          }
        }
      },
    );
  }

  /// 연결 끊김 처리 (재시도 로직 포함)
  void _handleConnectionLoss() {
    _isConnected = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    
    // 즉시 재시도 시작 (UI 표시는 지연)
    _startReconnectAttempts();
  }

  /// 재시도 로직 시작
  void _startReconnectAttempts() {
    _reconnectTimer?.cancel();
    
    if (kDebugMode) {
      print('🔄 연결 재시도 시작 (${_reconnectAttempts + 1}/$_maxReconnectAttempts)');
    }
    
    // 첫 번째 재시도는 즉시, 이후는 2초 간격
    final delay = _reconnectAttempts == 0 ? Duration.zero : _reconnectDelay;
    
    _reconnectTimer = Timer(delay, () async {
      final isReconnected = await _testSupabaseConnection();
      
      if (isReconnected) {
        // 재연결 성공
        _handleReconnectionSuccess();
      } else {
        _reconnectAttempts++;
        
        if (_reconnectAttempts < _maxReconnectAttempts) {
          // 더 재시도
          _startReconnectAttempts();
        } else {
          // 모든 재시도 실패 - 이제야 UI에 오프라인 표시
          _handleReconnectionFailure();
        }
      }
    });
  }

  /// 재연결 성공 처리
  void _handleReconnectionSuccess() {
    if (kDebugMode) {
      print('✅ 재연결 성공! (${_reconnectAttempts + 1}번째 시도에서 성공)');
    }
    
    _isConnected = true;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    
    // UI에 오프라인 표시를 하고 있었다면 온라인으로 복구
    if (_showingDisconnectedState) {
      _showingDisconnectedState = false;
      _connectionController.add(true);
    }
  }

  /// 재연결 실패 처리 (모든 시도 완료 후)
  void _handleReconnectionFailure() {
    if (kDebugMode) {
      print('❌ 재연결 실패 - UI에 오프라인 상태 표시');
    }
    
    _showingDisconnectedState = true;
    _connectionController.add(false);
    
    // 계속해서 주기적으로 재시도 (더 긴 간격으로)
    _startLongTermReconnectAttempts();
  }

  /// 장기 재연결 시도 (10초 간격)
  void _startLongTermReconnectAttempts() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (kDebugMode) {
        print('🔄 장기 재연결 시도...');
      }
      
      final isReconnected = await _testSupabaseConnection();
      if (isReconnected) {
        timer.cancel();
        _handleReconnectionSuccess();
      }
    });
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

  /// 연결 상태 업데이트 (내부용 - 직접 호출하지 말 것)
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      
      // 오프라인이 되었을 때는 재시도 로직을 통해 처리
      if (!isConnected) {
        _handleConnectionLoss();
      } else if (_showingDisconnectedState) {
        // 온라인이 되었을 때는 즉시 UI 업데이트
        _showingDisconnectedState = false;
        _connectionController.add(true);
      }
      
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
    _reconnectTimer?.cancel();
    _connectionController.close();
    
    if (kDebugMode) {
      print('🌐 ConnectivityService 정리 완료');
    }
  }
}