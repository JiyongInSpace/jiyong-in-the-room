import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/escape_cafe.dart';

class EscapeRoomService {
  static final _client = Supabase.instance.client;

  static Future<List<EscapeCafe>> getAllCafes() async {
    try {
      final response = await _client
          .from('escape_cafes')
          .select('*')
          .order('name', ascending: true);
      
      return (response as List)
          .map((cafe) => EscapeCafe.fromJson(cafe))
          .toList();
    } catch (e) {
      throw Exception('카페 목록을 불러오는데 실패했습니다: $e');
    }
  }

  static Future<List<EscapeTheme>> getThemesByCafe(int cafeId) async {
    try {
      final response = await _client
          .from('escape_themes')
          .select('''
            *,
            escape_cafes (
              id,
              name,
              address,
              contact,
              logo_url,
              created_at,
              updated_at
            )
          ''')
          .eq('cafe_id', cafeId)
          .order('name', ascending: true);
      
      return (response as List)
          .map((theme) => EscapeTheme.fromJson(theme))
          .toList();
    } catch (e) {
      throw Exception('테마 목록을 불러오는데 실패했습니다: $e');
    }
  }

  static Future<List<EscapeTheme>> getAllThemes() async {
    try {
      final response = await _client
          .from('escape_themes')
          .select('''
            *,
            escape_cafes (
              id,
              name,
              address,
              contact,
              logo_url,
              created_at,
              updated_at
            )
          ''')
          .order('cafe_id', ascending: true)
          .order('name', ascending: true);
      
      return (response as List)
          .map((theme) => EscapeTheme.fromJson(theme))
          .toList();
    } catch (e) {
      throw Exception('전체 테마 목록을 불러오는데 실패했습니다: $e');
    }
  }

  static Future<Map<int, List<EscapeTheme>>> getThemesGroupedByCafe() async {
    try {
      final themes = await getAllThemes();
      final Map<int, List<EscapeTheme>> groupedThemes = {};
      
      for (final theme in themes) {
        final cafeId = theme.cafe?.id ?? theme.cafeId;
        if (!groupedThemes.containsKey(cafeId)) {
          groupedThemes[cafeId] = [];
        }
        groupedThemes[cafeId]!.add(theme);
      }
      
      return groupedThemes;
    } catch (e) {
      throw Exception('카페별 테마 그룹을 불러오는데 실패했습니다: $e');
    }
  }
}