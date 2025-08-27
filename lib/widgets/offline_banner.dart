import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiyong_in_the_room/services/connectivity_service.dart';

/// 오프라인 상태를 사용자에게 알리는 배너 위젯
/// 
/// 주요 기능:
/// - 네트워크 연결이 끊어졌을 때 상단에 경고 배너 표시
/// - 오프라인 모드에서 사용 가능한 기능 안내
/// - 연결 재시도 버튼 제공
class OfflineBanner extends StatefulWidget {
  final Widget child;
  
  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with TickerProviderStateMixin {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;
  bool _showBanner = false;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 연결 상태 모니터링
    _connectivityService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
        
        if (!isConnected && !_showBanner) {
          // 오프라인이 되면 배너 표시
          _showOfflineBanner();
        } else if (isConnected && _showBanner) {
          // 온라인이 되면 배너 숨김
          _hideOfflineBanner();
        }
      }
    });
    
    // 현재 연결 상태 확인
    _isConnected = _connectivityService.isConnected;
    if (!_isConnected) {
      _showOfflineBanner();
    }
  }

  void _showOfflineBanner() {
    setState(() {
      _showBanner = true;
    });
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _hideOfflineBanner() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showBanner = false;
        });
      }
    });
    _pulseController.stop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // 오프라인 배너
        if (_showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value * 100),
                  child: child,
                );
              },
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade600,
                        Colors.orange.shade700,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // 오프라인 아이콘 (펄스 애니메이션)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: const Icon(
                                  Icons.wifi_off_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          
                          // 오프라인 메시지
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '인터넷 연결이 끊어졌습니다',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '일부 기능이 제한됩니다',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 다시 시도 버튼
                          TextButton.icon(
                            onPressed: _handleRetryConnection,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text(
                              '다시 시도',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 연결 재시도 처리
  Future<void> _handleRetryConnection() async {
    // 버튼 피드백
    HapticFeedback.lightImpact();
    
    try {
      // 연결 상태 새로고침
      final isConnected = await _connectivityService.refreshConnectionStatus();
      
      if (isConnected) {
        // 연결되면 성공 메시지 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.wifi, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('인터넷에 다시 연결되었습니다'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        // 여전히 오프라인이면 안내 메시지
        if (mounted) {
          _showOfflineCapabilitiesDialog();
        }
      }
    } catch (e) {
      // 에러 시 안내 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('연결 확인 중 문제가 발생했습니다'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 오프라인 모드에서 사용 가능한 기능 안내 다이얼로그
  void _showOfflineCapabilitiesDialog() {
    final capabilities = _connectivityService.getOfflineCapabilities();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text(
              '오프라인 모드',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '인터넷 연결이 없어도 다음 기능을 사용할 수 있습니다:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ...capabilities.entries.map((entry) {
              final isAvailable = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.cancel,
                      color: isAvailable ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: isAvailable ? Colors.black87 : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            const Text(
              '인터넷에 연결되면 모든 기능을 사용할 수 있습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}