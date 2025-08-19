// 플러터의 기본 Material Design 위젯들을 사용하기 위한 import
import 'package:flutter/material.dart';
// 일지 작성 화면 import
import 'package:jiyong_in_the_room/screens/write_diary_screen.dart';
// 일지 상세 화면 import
import 'package:jiyong_in_the_room/screens/diary_detail_screen.dart';
// 친구 관리 화면 import
import 'package:jiyong_in_the_room/screens/friends_screen.dart';
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
                itemCount: diaryList.length, // 리스트 아이템 개수
                // itemBuilder: 각 인덱스에 대한 위젯을 생성하는 함수
                itemBuilder: (context, index) {
                  final entry = diaryList[index]; // 해당 인덱스의 일지 엔트리
                  // Card: 그림자가 있는 둘근 모서리 컨테이너
                  return Card(
                    // margin: 카드 주변의 여백
                    // EdgeInsets.symmetric(): 세로와 가로에 각각 다른 여백 적용
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,   // 위아래 여백
                      horizontal: 16, // 좌우 여백
                    ),
                    // InkWell: 터치 시 물결 효과를 주는 위젯
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          // crossAxisAlignment: 가로 방향 정렬 (왼쪽 정렬)
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 카페와 테마 이름을 표시하는 로우
                            Row(
                              children: [
                                // 자물쇠 시계 아이콘
                                const Icon(Icons.lock_clock, size: 18),
                                const SizedBox(width: 8), // 아이콘과 텍스트 사이 간격
                                Expanded(
                                  // 문자열 보간법: ${}로 변수 값을 문자열에 삽입
                                  child: Text(
                                    '${entry.cafe?.name ?? '알 수 없음'} - ${entry.theme?.name ?? '알 수 없는 테마'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold, // 굵은 글씨
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4), // 수직 간격
                            // 날짜 표시
                            Text(
                              formatDate(entry.date), // 위에서 정의한 formatDate 함수 사용
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600], // 회색 계열의 색상
                              ),
                            ),
                            // if 문: 친구가 있을 때만 친구 목록 표시
                            // ...[]: 스프레드 연산자 - 리스트의 요소들을 풍어서 추가
                            if (entry.friends != null && entry.friends!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              // Wrap: 자식 위젯들이 한 줄에 다 들어가지 않으면 다음 줄로 넘어감
                              Wrap(
                                spacing: 6,    // 가로 간격
                                runSpacing: 2, // 세로 간격
                                // map(): 각 친구를 Chip 위젯으로 변환
                                children: entry.friends!
                                    .map((friend) => Chip(
                                          label: Text(
                                            friend.displayName,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          backgroundColor: Colors.blue[50], // 연한 파란색 배경
                                          visualDensity: VisualDensity.compact, // 컴팩트한 크기
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
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
