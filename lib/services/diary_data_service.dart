import 'package:jiyong_in_the_room/models/diary.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/local_storage_service.dart';

/// 로그인 상태에 따라 로컬 저장소와 DB를 자동으로 선택하는 통합 데이터 서비스
class DiaryDataService {
  
  /// 일지 저장 (로그인 상태에 따라 로컬/DB 자동 선택)
  static Future<DiaryEntry> saveDiary(DiaryEntry entry) async {
    if (AuthService.isLoggedIn) {
      // 로그인된 경우: DB에 저장
      // friends 필드를 friendIds로 변환
      final friendIds = entry.friends?.map((friend) => friend.id.toString()).toList() ?? [];
      return await DatabaseService.addDiaryEntry(entry, friendIds: friendIds);
    } else {
      // 비로그인된 경우: 로컬에 저장
      await LocalStorageService.saveDiary(entry);
      return entry;
    }
  }

  /// 모든 일지 가져오기 (로그인 상태에 따라 로컬/DB 자동 선택)
  static Future<List<DiaryEntry>> getAllDiaries() async {
    if (AuthService.isLoggedIn) {
      // 로그인된 경우: DB에서 가져오기
      return await DatabaseService.getMyDiaryEntries();
    } else {
      // 비로그인된 경우: 로컬에서 가져오기
      return await LocalStorageService.getAllDiaries();
    }
  }

  /// 일지 업데이트 (로그인 상태에 따라 로컬/DB 자동 선택)
  static Future<DiaryEntry> updateDiary(DiaryEntry entry) async {
    if (AuthService.isLoggedIn) {
      // 로그인된 경우: DB에서 업데이트
      // friends 필드를 friendIds로 변환
      final friendIds = entry.friends?.map((friend) => friend.id.toString()).toList() ?? [];
      return await DatabaseService.updateDiaryEntry(entry, friendIds: friendIds);
    } else {
      // 비로그인된 경우: 로컬에서 업데이트
      await LocalStorageService.updateDiary(entry);
      return entry;
    }
  }

  /// 일지 삭제 (로그인 상태에 따라 로컬/DB 자동 선택)
  static Future<void> deleteDiary(String entryId) async {
    if (AuthService.isLoggedIn) {
      // 로그인된 경우: DB에서 삭제 (int ID로 변환 필요)
      final intId = int.tryParse(entryId);
      if (intId != null) {
        await DatabaseService.deleteDiaryEntry(intId);
      } else {
        throw Exception('Invalid diary ID format for database');
      }
    } else {
      // 비로그인된 경우: 로컬에서 삭제
      await LocalStorageService.deleteDiary(entryId);
    }
  }

  /// 로컬 데이터를 DB로 마이그레이션
  static Future<int> migrateLocalDataToDatabase() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('마이그레이션하려면 로그인이 필요합니다');
    }

    // 마이그레이션이 이미 완료된 경우 건너뛰기
    if (await LocalStorageService.isMigrationCompleted()) {
      print('🔄 마이그레이션이 이미 완료됨');
      return 0;
    }

    try {
      print('🔍 마이그레이션 시작 - 로컬 데이터 확인...');
      
      // 로컬 일지 데이터 가져오기
      final localDiaries = await LocalStorageService.getAllDiaries();
      
      print('📋 로컬 일지 개수: ${localDiaries.length}');
      
      if (localDiaries.isEmpty) {
        print('📭 마이그레이션할 로컬 데이터가 없음');
        await LocalStorageService.setMigrationCompleted(true);
        return 0;
      }
      
      // 로컬 일지 목록 출력
      for (final diary in localDiaries) {
        print('📖 로컬 일지: ${diary.id} - ${diary.theme?.name ?? "테마 없음"} - ${diary.date}');
      }

      int migratedCount = 0;
      
      // 각 일지를 DB로 이전
      for (final diary in localDiaries) {
        try {
          print('📝 마이그레이션 중: ${diary.id} - ${diary.theme?.name ?? "테마 없음"}');
          
          // 비회원 상태에서 저장된 일지 마이그레이션
          final migratedDiary = DiaryEntry(
            id: diary.id,
            userId: AuthService.currentUser!.id, // 현재 사용자 ID로 설정
            themeId: diary.themeId,
            theme: diary.theme,
            date: diary.date,
            friends: null, // DB 저장 시에는 별도로 관리
            memo: diary.memo,
            rating: diary.rating,
            escaped: diary.escaped,
            hintUsedCount: diary.hintUsedCount,
            timeTaken: diary.timeTaken,
            createdAt: diary.createdAt,
            updatedAt: DateTime.now(),
          );
          
          print('🔄 DB 저장 시도: themeId=${diary.themeId}, userId=${AuthService.currentUser!.id}');
          
          // DB에 저장 (본인은 자동으로 추가됨, friendIds는 빈 배열)
          final savedEntry = await DatabaseService.addDiaryEntry(migratedDiary, friendIds: []);
          migratedCount++;
          
          print('✅ DB 저장 성공: ${savedEntry.id}');
          
        } catch (e) {
          print('❌ 일지 마이그레이션 실패 (${diary.id}): $e');
          print('❌ 상세 오류: ${e.toString()}');
          // 개별 일지 실패는 전체 마이그레이션을 중단하지 않음
        }
      }

      // 마이그레이션 완료 표시
      await LocalStorageService.setMigrationCompleted(true);
      
      // 로컬 데이터 정리 (마이그레이션 후 중복 방지)
      await LocalStorageService.clearAllDiaries();
      
      print('✅ 마이그레이션 완료: $migratedCount개 일지 이전');
      return migratedCount;
      
    } catch (e) {
      print('❌ 마이그레이션 실패: $e');
      throw Exception('데이터 마이그레이션 실패: $e');
    }
  }

  /// 로컬 일지 개수 확인
  static Future<int> getLocalDiaryCount() async {
    return await LocalStorageService.getDiaryCount();
  }

  /// 마이그레이션 상태 확인
  static Future<bool> isMigrationNeeded() async {
    if (AuthService.isLoggedIn) {
      final hasLocalData = await LocalStorageService.getDiaryCount() > 0;
      final migrationCompleted = await LocalStorageService.isMigrationCompleted();
      print('🔍 마이그레이션 체크: hasLocalData=$hasLocalData, migrationCompleted=$migrationCompleted');
      return hasLocalData && !migrationCompleted;
    }
    return false;
  }
  
  /// 마이그레이션 상태 재설정 (테스트/디버깅용)
  static Future<void> resetMigrationStatus() async {
    await LocalStorageService.setMigrationCompleted(false);
  }
}