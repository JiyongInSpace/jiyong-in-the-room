// 플러터의 기본 Material Design 위젯들을 사용하기 위한 import
import 'package:flutter/material.dart';
// 일지 작성 화면 import
import 'package:jiyong_in_the_room/screens/diary/write_diary_screen.dart';
// 일지 상세 화면 import
import 'package:jiyong_in_the_room/screens/diary/diary_detail_screen.dart';
// 다이어리 엔트리 모델 import
import 'package:jiyong_in_the_room/models/diary.dart';
// 카페와 테마 모델 import
// 사용자와 친구 모델 import
import 'package:jiyong_in_the_room/models/user.dart';
// 인증 서비스를 사용하기 위한 import
import 'package:jiyong_in_the_room/services/auth_service.dart';

// 다이어리 목록 화면 - 메인 화면으로 작성된 일지들을 목록으로 표시
// StatelessWidget: 상태가 변하지 않는 위젯 (데이터는 부모에서 관리)
class DiaryListScreen extends StatelessWidget {
  // 표시할 다이어리 엔트리 목록
  final List<DiaryEntry> diaryList;
  // 새 일지 추가 시 호출될 콜백 함수
  final void Function(DiaryEntry) onAdd;
  // 일지 수정 시 호출될 콜백 함수 (nullable - 수정 기능이 없을 수도 있음)
  final void Function(DiaryEntry, DiaryEntry)? onUpdate;
  // 일지 삭제 시 호출될 콜백 함수 (nullable - 삭제 기능이 없을 수도 있음)
  final void Function(DiaryEntry)? onDelete;
  // 친구 목록
  final List<Friend> friends;
  // 친구 추가 콜백 함수
  final void Function(Friend) onAddFriend;
  // 친구 삭제 콜백 함수
  final void Function(Friend) onRemoveFriend;
  // 친구 수정 콜백 함수
  final void Function(Friend, Friend) onUpdateFriend;

  // 생성자: 다이어리 목록과 다양한 콜백 함수들을 받음
  const DiaryListScreen({
    super.key,
    required this.diaryList,
    required this.onAdd,
    this.onUpdate, // 선택사항: onUpdate는 null이 될 수 있음
    this.onDelete, // 선택사항: onDelete는 null이 될 수 있음
    required this.friends,
    required this.onAddFriend,
    required this.onRemoveFriend,
    required this.onUpdateFriend,
  });

  // StatelessWidget의 build 메서드: UI를 구성하는 메서드
  @override
  Widget build(BuildContext context) {
    // 날짜를 YYYY.MM.DD 형식으로 포맷팅하는 로컬 함수
    // padLeft(): 문자열을 지정된 길이로 만들고 왼쪽에 지정된 문자 추가
    String formatDate(DateTime date) {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('탈출일지'),
        // actions: AppBar 오른쪽에 표시될 액션 버튼들
        actions: [
          // IconButton: 아이콘만 있는 버튼
        ],
      ),
      // body: 화면의 주요 내용 영역
      // 삼항연산자로 일지가 없으면 안내 메시지, 있으면 목록 표시
      body:
          diaryList.isEmpty
              // Center: 자식 위젯을 중앙에 배치하는 위젯
              ? const Center(child: Text('작성된 일지가 없습니다.'))
              // ListView.builder: 효율적인 리스트 위젯 (필요한 아이템만 렌더링)
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // 하단 80px + 기본 16px 여백
                itemCount: diaryList.length, // 리스트 아이템 개수
                // itemBuilder: 각 인덱스에 대한 위젯을 생성하는 함수
                itemBuilder: (context, index) {
                  final entry = diaryList[index]; // 해당 인덱스의 일지 엔트리
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        // onTap: 카드를 터치했을 때 실행될 함수
                        // async: 비동기 함수임을 표시
                        onTap: () async {
                          // await: 비동기 작업의 결과를 기다림
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              // 일지 상세 화면으로 이동
                              builder: (context) => DiaryDetailScreen(
                                entry: entry,
                                friends: friends,
                                // onUpdate: 일지가 수정됐 때 호출될 콜백
                                onUpdate: (updatedEntry) {
                                  if (onUpdate != null) {
                                    // !: null이 아님을 확신할 때 사용하는 연산자
                                    onUpdate!(entry, updatedEntry);
                                  }
                                },
                              ),
                            ),
                          );
                          
                          // 상세 화면에서 돌아온 결과 처리
                          if (result != null) {
                            if (result == 'deleted' && onDelete != null) {
                              // 일지가 삭제된 경우
                              onDelete!(entry);
                            } else if (result is DiaryEntry && onUpdate != null) {
                              // 일지가 수정된 경우
                              onUpdate!(entry, result);
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: entry.escaped == true 
                                        ? Colors.green 
                                        : entry.escaped == false 
                                            ? Colors.red 
                                            : Colors.grey,
                                    child: Icon(
                                      entry.escaped == true 
                                          ? Icons.check 
                                          : entry.escaped == false 
                                              ? Icons.close 
                                              : Icons.question_mark,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.theme?.name ?? '알 수 없는 테마',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${entry.cafe?.name ?? '알 수 없음'} • ${formatDate(entry.date)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (entry.rating != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          entry.rating!.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              // 친구 정보 표시
                              if (entry.friends != null && entry.friends!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: entry.friends!
                                      .map((friend) => Chip(
                                            label: Text(
                                              friend.displayName,
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                            backgroundColor: Colors.blue[50],
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      // 일지 작성 버튼 (화면 우하단의 둥근 버튼)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 로그인 확인
          if (!AuthService.isLoggedIn) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('일지 작성 기능을 사용하려면 로그인이 필요합니다'),
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }
          
          // 일지 작성 화면으로 이동하고 결과를 기다림
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => WriteDiaryScreen(friends: friends)),
          );

          // WriteDiaryScreen에서 저장된 DiaryEntry 객체 확인
          if (result != null && result is DiaryEntry) {
            // DB에서 저장된 일지 객체를 받아서 목록에 추가
            onAdd(result);
          }
        },
        child: const Icon(Icons.add), // 더하기 아이콘
      ),
    );
  }
}
