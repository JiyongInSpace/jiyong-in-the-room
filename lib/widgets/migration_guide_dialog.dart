import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/widgets/skeleton_widgets.dart';

/// 로그인 후 로컬 데이터 마이그레이션 안내 다이얼로그
class MigrationGuideDialog extends StatefulWidget {
  final VoidCallback? onMigrationComplete;
  
  const MigrationGuideDialog({
    super.key,
    this.onMigrationComplete,
  });

  @override
  State<MigrationGuideDialog> createState() => _MigrationGuideDialogState();
}

class _MigrationGuideDialogState extends State<MigrationGuideDialog> {
  bool _isLoading = false;
  int _localDiaryCount = 0;
  int _localFriendCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadLocalDiaryCount();
  }
  
  void _loadLocalDiaryCount() {
    final localDiaries = LocalStorageService.getLocalDiaries();
    final localFriends = LocalStorageService.getLocalFriends();
    setState(() {
      _localDiaryCount = localDiaries.length;
      _localFriendCount = localFriends.length;
    });
  }
  
  // 마이그레이션 실행
  Future<void> _performMigration() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 로컬 데이터 가져오기
      final localDiaries = LocalStorageService.getLocalDiaries();
      final localFriends = LocalStorageService.getLocalFriends();
      
      if (localDiaries.isEmpty && localFriends.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('가져올 데이터가 없습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // 마이그레이션 실행 (친구 포함)
      final result = await DatabaseService.migrateLocalDataToDatabase(
        localDiaries,
        localFriends,
      );
      
      // 마이그레이션 성공한 로컬 데이터 삭제
      if (result['diarySuccessCount'] > 0 || result['friendSuccessCount'] > 0) {
        // 성공한 항목들만 삭제
        for (final localId in result['migratedDiaryLocalIds'] ?? []) {
          await LocalStorageService.deleteDiary(localId);
        }
        for (final localId in result['migratedFriendLocalIds'] ?? []) {
          await LocalStorageService.deleteFriend(localId);
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '친구 ${result['friendSuccessCount']}명, 일지 ${result['diarySuccessCount']}개를 성공적으로 가져왔습니다!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // 마이그레이션 완료 콜백 호출
        widget.onMigrationComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일지 가져오기에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cloud_upload, color: Colors.blue[600]),
          const SizedBox(width: 8),
          const Text('일지 가져오기'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 120,
              child: LoadingOverlay(
                isLoading: true,
                message: '일지를 가져오는 중...',
                child: SizedBox(),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, 
                            color: Colors.blue[700], 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '기기에 저장된 일지가 있어요!',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '로그인 전에 저장한 데이터를 계정에 연결할 수 있습니다.\n'
                        '친구 $_localFriendCount명, 일지 $_localDiaryCount개',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  '📝 포함되는 내용:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• 작성한 일지 ($_localDiaryCount개)',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (_localFriendCount > 0)
                  Text(
                    '• 등록한 친구 ($_localFriendCount명)',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, 
                        color: Colors.orange[700], 
                        size: 16
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '지금 하지 않아도 설정에서 언제든 가져올 수 있어요',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      actions: _isLoading
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('나중에'),
              ),
              ElevatedButton.icon(
                onPressed: _performMigration,
                icon: const Icon(Icons.cloud_upload, size: 18),
                label: const Text('지금 가져오기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
    );
  }
}