import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/models/user.dart';
import 'package:jiyong_in_the_room/utils/rating_utils.dart';
import 'package:jiyong_in_the_room/widgets/common_input_fields.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';

/// 일지 필터 설정 다이얼로그
class DiaryFilterDialog extends StatefulWidget {
  final String? initialSearchQuery;
  final List<Friend> initialSelectedFriends;
  final List<RatingFilter> initialSelectedRatings;
  final List<Friend> availableFriends;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  
  const DiaryFilterDialog({
    super.key,
    this.initialSearchQuery,
    required this.initialSelectedFriends,
    required this.initialSelectedRatings,
    required this.availableFriends,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<DiaryFilterDialog> createState() => _DiaryFilterDialogState();
}

class _DiaryFilterDialogState extends State<DiaryFilterDialog> {
  late TextEditingController _searchController;
  late List<Friend> _selectedFriends;
  late List<RatingFilter> _selectedRatings;
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    _selectedFriends = List.from(widget.initialSelectedFriends);
    _selectedRatings = List.from(widget.initialSelectedRatings);
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // 친구 추가
  void _addFriend(Friend friend) {
    if (!_selectedFriends.contains(friend)) {
      setState(() {
        _selectedFriends.add(friend);
      });
    }
  }
  
  // 친구 제거
  void _removeFriend(Friend friend) {
    setState(() {
      _selectedFriends.remove(friend);
    });
  }
  
  // 만족도 토글
  void _toggleRating(RatingFilter rating) {
    setState(() {
      if (_selectedRatings.contains(rating)) {
        _selectedRatings.remove(rating);
      } else {
        _selectedRatings.add(rating);
      }
    });
  }
  
  // 필터 초기화
  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedFriends.clear();
      _selectedRatings.clear();
      _startDate = null;
      _endDate = null;
    });
  }
  
  // 날짜 선택
  Future<void> _selectDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
          // 시작일이 종료일보다 늦으면 종료일을 시작일로 설정
          if (_endDate != null && pickedDate.isAfter(_endDate!)) {
            _endDate = pickedDate;
          }
        } else {
          _endDate = pickedDate;
          // 종료일이 시작일보다 빠르면 시작일을 종료일로 설정
          if (_startDate != null && pickedDate.isBefore(_startDate!)) {
            _startDate = pickedDate;
          }
        }
      });
    }
  }
  
  // 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('필터 설정'),
          if (_searchController.text.isNotEmpty || 
              _selectedFriends.isNotEmpty || 
              _selectedRatings.isNotEmpty ||
              _startDate != null ||
              _endDate != null)
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text(
                '초기화',
                style: TextStyle(fontSize: 14),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 검색어 입력
              Row(
                children: [
                  const Icon(Icons.search, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CommonTextField(
                      controller: _searchController,
                      labelText: '',
                      hintText: '테마명, 카페명 검색',
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // 친구 필터 (회원만)
              if (AuthService.isLoggedIn) ...[
                Row(
                  children: [
                    const Icon(Icons.people, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      '함께한 친구',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 친구 선택 드롭다운
                CommonDropdownField<Friend?>(
                  key: ValueKey(_selectedFriends.length),
                  value: null,
                  labelText: '',
                  hintText: '친구 선택',
                  items: widget.availableFriends
                      .where((friend) => !_selectedFriends.contains(friend))
                      .map((friend) => DropdownMenuItem<Friend?>(
                        value: friend,
                        child: Text(friend.displayName),
                      ))
                      .toList(),
                  onChanged: (Friend? friend) {
                    if (friend != null) {
                      _addFriend(friend);
                    }
                  },
                ),
                // 선택된 친구 칩들
                if (_selectedFriends.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedFriends.map((friend) {
                      return Chip(
                        label: Text(friend.displayName),
                        onDeleted: () => _removeFriend(friend),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        backgroundColor: Colors.blue[50],
                        deleteIconColor: Colors.blue[700],
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 20),
              ],
              
              // 만족도 필터
              Row(
                children: [
                  const Icon(Icons.sentiment_very_satisfied, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    '만족도',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 만족도 그리드
              SizedBox(
                height: 200,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: RatingUtils.ratingFilters.length,
                  itemBuilder: (context, index) {
                    final rating = RatingUtils.ratingFilters[index];
                    final isSelected = _selectedRatings.contains(rating);
                    
                    return InkWell(
                      onTap: () => _toggleRating(rating),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.orange[100] 
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected 
                                ? Colors.orange[400]! 
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rating.icon,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  rating.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected 
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // 날짜 필터
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    '기간',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 날짜 범위 선택
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              _startDate != null 
                                  ? _formatDate(_startDate!) 
                                  : '시작일',
                              style: TextStyle(
                                fontSize: 14,
                                color: _startDate != null 
                                    ? Colors.black 
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('~'),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              _endDate != null 
                                  ? _formatDate(_endDate!) 
                                  : '종료일',
                              style: TextStyle(
                                fontSize: 14,
                                color: _endDate != null 
                                    ? Colors.black 
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'searchQuery': _searchController.text.trim().isEmpty 
                  ? null 
                  : _searchController.text.trim(),
              'selectedFriends': _selectedFriends,
              'selectedRatings': _selectedRatings,
              'startDate': _startDate,
              'endDate': _endDate,
            });
          },
          child: const Text('적용'),
        ),
      ],
    );
  }
}