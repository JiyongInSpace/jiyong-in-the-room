import 'package:flutter/material.dart';

/// 방탈출 은어 별점 표시 유틸리티
class RatingUtils {
  /// 필터링을 위한 평점 범위 정의
  static const List<RatingFilter> ratingFilters = [
    RatingFilter('인생테마', 5.0, 5.0, '👑'),
    RatingFilter('꽃밭길', 4.5, 4.9, '🌸'),
    RatingFilter('꽃길', 4.0, 4.4, '🌺'),
    RatingFilter('풀꽃길', 3.5, 3.9, '🌿'),
    RatingFilter('풀길', 3.0, 3.4, '🌱'),
    RatingFilter('풀흙길', 2.5, 2.9, '🌾'),
    RatingFilter('흙길', 2.0, 2.4, '🏔️'),
    RatingFilter('진흙길', 1.5, 1.9, '🕳️'),
    RatingFilter('똥길', 1.0, 1.4, '💩'),
    RatingFilter('왜했지', 0.5, 0.9, '😭'),
    RatingFilter('미평가', null, null, '❓'),
  ];
  /// 숫자 별점을 방탈출 은어로 변환
  static String getRatingText(double? rating) {
    if (rating == null) return '미평가';
    
    // 0.5 단위로 구분
    if (rating >= 5.0) return '인생테마';
    if (rating >= 4.5) return '꽃밭길';
    if (rating >= 4.0) return '꽃길';
    if (rating >= 3.5) return '풀꽃길';
    if (rating >= 3.0) return '풀길';
    if (rating >= 2.5) return '풀흙길';
    if (rating >= 2.0) return '흙길';
    if (rating >= 1.5) return '진흙길';
    if (rating >= 1.0) return '똥길';
    return '왜했지';
  }
  
  /// 방탈출 은어에 맞는 색상 반환
  static Color getRatingColor(double? rating) {
    if (rating == null) return Colors.grey;
    
    if (rating >= 5.0) return const Color(0xFFFFD700); // 금색 (인생테마)
    if (rating >= 4.5) return const Color(0xFFFF69B4); // 핑크 (꽃밭길)
    if (rating >= 4.0) return const Color(0xFFFF1493); // 진한 핑크 (꽃길)
    if (rating >= 3.5) return const Color(0xFF9ACD32); // 연두색 (풀꽃길)
    if (rating >= 3.0) return const Color(0xFF228B22); // 초록색 (풀길)
    if (rating >= 2.5) return const Color(0xFF8B4513); // 갈색 (풀흙길)
    if (rating >= 2.0) return const Color(0xFFA0522D); // 진한 갈색 (흙길)
    if (rating >= 1.5) return const Color(0xFF654321); // 어두운 갈색 (진흙길)
    if (rating >= 1.0) return const Color(0xFF8B4513); // 똥색 (똥길)
    return const Color(0xFF696969); // 어두운 회색 (왜했지)
  }
  
  /// 방탈출 은어 별점을 위젯으로 반환
  static Widget getRatingWidget(double? rating, {double fontSize = 14}) {
    return Text(
      getRatingText(rating),
      style: TextStyle(
        color: getRatingColor(rating),
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    );
  }
  
  /// 별점과 함께 이모지 아이콘도 반환
  static Widget getRatingWithIcon(double? rating, {double fontSize = 14}) {
    String icon = '⭐';
    
    if (rating == null) {
      icon = '❓';
    } else if (rating >= 5.0) {
      icon = '👑'; // 인생테마
    } else if (rating >= 4.5) {
      icon = '🌸'; // 꽃밭길
    } else if (rating >= 4.0) {
      icon = '🌺'; // 꽃길
    } else if (rating >= 3.5) {
      icon = '🌿'; // 풀꽃길
    } else if (rating >= 3.0) {
      icon = '🌱'; // 풀길
    } else if (rating >= 2.5) {
      icon = '🌾'; // 풀흙길
    } else if (rating >= 2.0) {
      icon = '🏔️'; // 흙길
    } else if (rating >= 1.5) {
      icon = '🕳️'; // 진흙길
    } else if (rating >= 1.0) {
      icon = '💩'; // 똥길
    } else {
      icon = '😭'; // 왜했지
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: fontSize),
        ),
        const SizedBox(width: 4),
        Text(
          getRatingText(rating),
          style: TextStyle(
            color: getRatingColor(rating),
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}

/// 평점 필터를 위한 데이터 클래스
class RatingFilter {
  final String name;
  final double? minRating;
  final double? maxRating;
  final String icon;

  const RatingFilter(this.name, this.minRating, this.maxRating, this.icon);

  /// 주어진 평점이 이 필터 범위에 포함되는지 확인
  bool matches(double? rating) {
    // 미평가 필터
    if (name == '미평가') {
      return rating == null;
    }
    
    // 평점이 null인 경우
    if (rating == null) {
      return false;
    }
    
    // 범위 체크
    if (minRating != null && rating < minRating!) {
      return false;
    }
    if (maxRating != null && rating > maxRating!) {
      return false;
    }
    
    return true;
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingFilter &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}