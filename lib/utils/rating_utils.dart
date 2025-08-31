import 'package:flutter/material.dart';

/// 방탈출 은어 별점 표시 유틸리티
class RatingUtils {
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