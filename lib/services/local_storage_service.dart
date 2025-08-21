import 'package:hive_flutter/hive_flutter.dart';
import 'package:jiyong_in_the_room/models/diary.dart';

class LocalStorageService {
  static const String _diaryBoxName = 'diary_entries';
  static const String _settingsBoxName = 'app_settings';
  
  static Box<Map>? _diaryBox;
  static Box<Map>? _settingsBox;

  /// 로컬 저장소 초기화
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // 박스 열기
    _diaryBox = await Hive.openBox<Map>(_diaryBoxName);
    _settingsBox = await Hive.openBox<Map>(_settingsBoxName);
  }

  /// 로컬에 일지 저장
  static Future<void> saveDiary(DiaryEntry entry) async {
    if (_diaryBox == null) await init();
    
    final data = entry.toJsonForLocal(); // 로컬 저장용 메서드 사용
    await _diaryBox!.put(entry.id, data);
  }

  /// 로컬에서 모든 일지 가져오기
  static Future<List<DiaryEntry>> getAllDiaries() async {
    if (_diaryBox == null) await init();
    
    final List<DiaryEntry> diaries = [];
    
    for (var data in _diaryBox!.values) {
      try {
        // Map을 Map<String, dynamic>으로 변환
        final Map<String, dynamic> entryData = Map<String, dynamic>.from(data);
        final entry = DiaryEntry.fromJson(entryData);
        diaries.add(entry);
      } catch (e) {
        // 잘못된 데이터는 무시
        print('로컬 일지 파싱 실패: $e');
      }
    }
    
    // 날짜순으로 정렬 (최신순)
    diaries.sort((a, b) => b.date.compareTo(a.date));
    
    return diaries;
  }

  /// 로컬에서 일지 업데이트
  static Future<void> updateDiary(DiaryEntry entry) async {
    if (_diaryBox == null) await init();
    
    final data = entry.toJsonForLocal(); // 로컬 저장용 메서드 사용
    await _diaryBox!.put(entry.id, data);
  }

  /// 로컬에서 일지 삭제
  static Future<void> deleteDiary(String entryId) async {
    if (_diaryBox == null) await init();
    
    await _diaryBox!.delete(entryId);
  }

  /// 모든 로컬 일지 삭제 (마이그레이션 후 정리용)
  static Future<void> clearAllDiaries() async {
    if (_diaryBox == null) await init();
    
    await _diaryBox!.clear();
  }

  /// 로컬 일지 개수 확인
  static Future<int> getDiaryCount() async {
    if (_diaryBox == null) await init();
    
    return _diaryBox!.length;
  }

  /// 마이그레이션 완료 상태 저장
  static Future<void> setMigrationCompleted(bool completed) async {
    if (_settingsBox == null) await init();
    
    await _settingsBox!.put('migration_completed', {'value': completed});
  }

  /// 마이그레이션 완료 상태 확인
  static Future<bool> isMigrationCompleted() async {
    if (_settingsBox == null) await init();
    
    final data = _settingsBox!.get('migration_completed');
    return data?['value'] ?? false;
  }

  /// 앱 설정값 저장
  static Future<void> setSetting(String key, dynamic value) async {
    if (_settingsBox == null) await init();
    
    await _settingsBox!.put(key, {'value': value});
  }

  /// 앱 설정값 가져오기
  static Future<T?> getSetting<T>(String key) async {
    if (_settingsBox == null) await init();
    
    final data = _settingsBox!.get(key);
    return data?['value'] as T?;
  }

  /// 모든 로컬 데이터 초기화 (개발/테스트용)
  static Future<void> clearAll() async {
    if (_diaryBox == null) await init();
    
    await _diaryBox!.clear();
    await _settingsBox!.clear();
  }
}