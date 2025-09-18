import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jiyong_in_the_room/services/profile_service.dart';
import 'package:jiyong_in_the_room/services/database_service.dart';
import 'package:jiyong_in_the_room/services/auth_service.dart';
import 'package:jiyong_in_the_room/widgets/common_input_fields.dart';
import 'dart:io';

class ProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const ProfileEditScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  
  String? _avatarUrl;
  File? _selectedImage;
  bool _isLoading = false;
  String? _myUserCode;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.userProfile['display_name'] ?? '';
    _avatarUrl = widget.userProfile['avatar_url'];
    _loadMyUserCode();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      
      // 이미지 소스 선택 다이얼로그
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('프로필 사진 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 80,
        );
        
        if (pickedFile != null) {
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 내 사용자 코드 로드
  Future<void> _loadMyUserCode() async {
    try {
      final code = await DatabaseService.getMyUserCode();
      if (mounted) {
        setState(() {
          _myUserCode = code;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 코드 로드 실패: $e')),
        );
      }
    }
  }


  // 코드를 클립보드에 복사
  void _copyCodeToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('코드가 복사되었습니다')),
    );
  }

  // 로그아웃 처리
  Future<void> _signOut() async {
    try {
      // 확인 다이얼로그
      final bool? shouldSignOut = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      );

      if (shouldSignOut == true) {
        await AuthService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그아웃되었습니다'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop(true); // 로그아웃 시 true 반환하여 홈 화면 새로고침
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      String? newAvatarUrl = _avatarUrl;
      
      // 새 이미지가 선택된 경우 업로드
      if (_selectedImage != null) {
        newAvatarUrl = await ProfileService.uploadProfileImage(_selectedImage!);
      }

      // 프로필 업데이트
      await ProfileService.updateProfile(
        displayName: _displayNameController.text.trim(),
        avatarUrl: newAvatarUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 업데이트되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 업데이트 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAvatarSection() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null),
              child: (_selectedImage == null && _avatarUrl == null)
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8B4513), // 갈색 - AppBar 텍스트/아이콘과 동일한 색상
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B4513), // 갈색 로딩 인디케이터
                      ),
                    ),
                  )
                : const Text(
                    '저장',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // 하단 80px + 기본 16px 여백
          children: [
            const SizedBox(height: 20),
            
            _buildAvatarSection(),
            
            const SizedBox(height: 8),
            Text(
              '프로필 사진을 탭하여 변경',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            CommonTextField(
              controller: _displayNameController,
              labelText: '표시 이름',
              hintText: '다른 사용자에게 표시될 이름을 입력하세요',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '표시 이름을 입력해주세요';
                }
                if (value.trim().length < 2) {
                  return '표시 이름은 2글자 이상이어야 합니다';
                }
                if (value.trim().length > 20) {
                  return '표시 이름은 20글자 이하여야 합니다';
                }
                return null;
              },
              maxLength: 20,
            ),
            
            const SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '계정 정보',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('이메일: ${widget.userProfile['email'] ?? ''}'),
                    const SizedBox(height: 4),
                    const Text(
                      '* 이메일은 변경할 수 없습니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 친구 코드 카드
            if (_myUserCode != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '친구 코드',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _myUserCode!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _copyCodeToClipboard(_myUserCode!),
                            icon: const Icon(Icons.copy),
                            tooltip: '코드 복사',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '이 코드를 친구에게 공유하여 친구 추가를 할 수 있어요',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // 로그아웃 버튼 (오른쪽 정렬, 빨간색, 작은 글씨)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _signOut,
                child: const Text(
                  '로그아웃',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}