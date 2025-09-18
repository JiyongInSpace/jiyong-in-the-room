import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/screens/friends/friends_screen.dart';

/// 친구 필터 설정 다이얼로그
class FriendFilterDialog extends StatefulWidget {
  final String? initialSearchQuery;
  final FriendSortOption initialSortOption;
  
  const FriendFilterDialog({
    super.key,
    this.initialSearchQuery,
    required this.initialSortOption,
  });

  @override
  State<FriendFilterDialog> createState() => _FriendFilterDialogState();
}

class _FriendFilterDialogState extends State<FriendFilterDialog> {
  late TextEditingController _searchController;
  late FriendSortOption _selectedSortOption;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery);
    _selectedSortOption = widget.initialSortOption;
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // 정렬 옵션 선택
  void _selectSortOption(FriendSortOption option) {
    setState(() {
      _selectedSortOption = option;
    });
  }
  
  // 필터 초기화
  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedSortOption = FriendSortOption.name;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('필터 설정'),
          if (_searchController.text.isNotEmpty || 
              _selectedSortOption != FriendSortOption.name)
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
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '친구 이름 검색',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 정렬 옵션
            Row(
              children: [
                const Icon(Icons.sort, size: 20),
                const SizedBox(width: 12),
                const Text(
                  '정렬 기준',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 정렬 옵션 목록
            Column(
              children: FriendSortOption.values.map((option) {
                final isSelected = _selectedSortOption == option;
                return InkWell(
                  onTap: () => _selectSortOption(option),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.blue[100] 
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.blue[400]! 
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color: isSelected 
                              ? Colors.blue[700] 
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: isSelected 
                                ? Colors.blue[700] 
                                : Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.blue[700],
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
              'sortOption': _selectedSortOption,
            });
          },
          child: const Text('적용'),
        ),
      ],
    );
  }
}