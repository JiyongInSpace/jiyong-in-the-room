import 'package:flutter/material.dart';

/// 페이지별 맞춤형 Skeleton UI 위젯들
/// 
/// 각 화면의 실제 UI 구조에 맞춰 설계된 로딩 스켈레톤

/// 기본 스켈레톤 애니메이션 기능을 제공하는 클래스
class SkeletonAnimationHelper {
  late AnimationController _skeletonController;
  late Animation<double> _skeletonAnimation;

  void initializeSkeletonAnimation(TickerProvider vsync) {
    _skeletonController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: vsync,
    );
    
    _skeletonAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _skeletonController,
      curve: Curves.easeInOut,
    ));

    _skeletonController.repeat(reverse: true);
  }

  void disposeSkeletonAnimation() {
    _skeletonController.dispose();
  }

  Animation<double> get skeletonAnimation => _skeletonAnimation;
}

/// 기본 스켈레톤 컨테이너
class SkeletonContainer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer>
    with TickerProviderStateMixin {

  late SkeletonAnimationHelper _animationHelper;

  @override
  void initState() {
    super.initState();
    _animationHelper = SkeletonAnimationHelper();
    _animationHelper.initializeSkeletonAnimation(this);
  }

  @override
  void dispose() {
    _animationHelper.disposeSkeletonAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationHelper.skeletonAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(_animationHelper.skeletonAnimation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

/// 홈 화면용 스켈레톤
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 인사말 섹션
          const SkeletonContainer(width: 200, height: 24),
          const SizedBox(height: 8),
          const SkeletonContainer(width: 150, height: 16),
          const SizedBox(height: 24),
          
          // 통계 카드들
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonContainer(width: 80, height: 16),
                        SizedBox(height: 8),
                        SkeletonContainer(width: 40, height: 24),
                        SizedBox(height: 4),
                        SkeletonContainer(width: 60, height: 12),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonContainer(width: 80, height: 16),
                        SizedBox(height: 8),
                        SkeletonContainer(width: 40, height: 24),
                        SizedBox(height: 4),
                        SkeletonContainer(width: 60, height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 섹션 제목
          const SkeletonContainer(width: 150, height: 20),
          const SizedBox(height: 16),
          
          // 최근 일지 리스트
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) => const DiaryCardSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 일지 카드용 스켈레톤
class DiaryCardSkeleton extends StatelessWidget {
  const DiaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 카페 로고
                SkeletonContainer(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                
                // 카페명과 테마명
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer(width: 100, height: 16),
                      SizedBox(height: 4),
                      SkeletonContainer(width: 150, height: 20),
                    ],
                  ),
                ),
                
                // 날짜
                const SkeletonContainer(width: 70, height: 14),
              ],
            ),
            const SizedBox(height: 12),
            
            // 만족도와 결과
            const Row(
              children: [
                SkeletonContainer(width: 80, height: 16),
                SizedBox(width: 16),
                SkeletonContainer(width: 60, height: 16),
              ],
            ),
            const SizedBox(height: 8),
            
            // 친구들
            Row(
              children: [
                const SkeletonContainer(width: 40, height: 14),
                const SizedBox(width: 8),
                // 친구 아바타들
                ...List.generate(3, (index) => Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: SkeletonContainer(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 친구 리스트용 스켈레톤
class FriendsListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const FriendsListSkeleton({
    super.key,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const FriendCardSkeleton(),
    );
  }
}

/// 친구 카드용 스켈레톤
class FriendCardSkeleton extends StatelessWidget {
  const FriendCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 프로필 아바타
            SkeletonContainer(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(24),
            ),
            const SizedBox(width: 16),
            
            // 친구 정보
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonContainer(width: 120, height: 16),
                  SizedBox(height: 4),
                  SkeletonContainer(width: 80, height: 12),
                  SizedBox(height: 4),
                  SkeletonContainer(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 일지 작성 폼용 스켈레톤
class DiaryFormSkeleton extends StatelessWidget {
  const DiaryFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카페 선택 필드
          const SkeletonContainer(width: double.infinity, height: 56),
          const SizedBox(height: 16),
          
          // 테마 선택 필드
          const SkeletonContainer(width: double.infinity, height: 56),
          const SizedBox(height: 16),
          
          // 날짜와 시간
          const Row(
            children: [
              Expanded(
                child: SkeletonContainer(width: double.infinity, height: 56),
              ),
              SizedBox(width: 12),
              Expanded(
                child: SkeletonContainer(width: double.infinity, height: 56),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 만족도 섹션
          const SkeletonContainer(width: 100, height: 20),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) => Container(
              margin: const EdgeInsets.only(right: 8),
              child: const SkeletonContainer(width: 32, height: 32),
            )),
          ),
          const SizedBox(height: 24),
          
          // 결과 섹션
          const SkeletonContainer(width: 80, height: 20),
          const SizedBox(height: 8),
          const Row(
            children: [
              SkeletonContainer(width: 80, height: 40),
              SizedBox(width: 12),
              SkeletonContainer(width: 80, height: 40),
            ],
          ),
          const SizedBox(height: 24),
          
          // 친구 선택 섹션
          const SkeletonContainer(width: 120, height: 20),
          const SizedBox(height: 8),
          const SkeletonContainer(width: double.infinity, height: 100),
        ],
      ),
    );
  }
}

/// 설정 화면용 스켈레톤
class SettingsScreenSkeleton extends StatelessWidget {
  const SettingsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 프로필 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // 프로필 이미지
                SkeletonContainer(
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(40),
                ),
                const SizedBox(height: 16),
                
                // 이름과 이메일
                const SkeletonContainer(width: 120, height: 20),
                const SizedBox(height: 8),
                const SkeletonContainer(width: 180, height: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // 메뉴 항목들
          ...List.generate(5, (index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: const Card(
              child: ListTile(
                leading: SkeletonContainer(width: 24, height: 24),
                title: SkeletonContainer(width: 100, height: 16),
                trailing: SkeletonContainer(width: 20, height: 20),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// 검색 결과용 스켈레톤
class SearchResultSkeleton extends StatelessWidget {
  final int itemCount;
  
  const SearchResultSkeleton({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: const Card(
          child: ListTile(
            leading: SkeletonContainer(width: 40, height: 40),
            title: SkeletonContainer(width: 150, height: 16),
            subtitle: SkeletonContainer(width: 100, height: 14),
          ),
        ),
      )),
    );
  }
}

/// 로딩 오버레이 (전체 화면)
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Widget child;
  final bool isLoading;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}