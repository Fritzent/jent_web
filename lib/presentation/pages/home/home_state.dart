class HomeState {
  final int currentIndex;
  final String imagePath;
  final bool isShowWindow;
  final bool isMinimizedWindow;
  final bool isExpandedWindow;

  const HomeState({
    required this.currentIndex,
    required this.imagePath,
    this.isShowWindow = false,
    this.isMinimizedWindow = false,
    this.isExpandedWindow = false,
  });

  HomeState copyWith({
    int? currentIndex,
    String? imagePath,
    bool? isShowWindow,
    bool? isMinimizedWindow,
    bool? isExpandedWindow,
  }) {
    return HomeState(
      currentIndex: currentIndex ?? this.currentIndex,
      imagePath: imagePath ?? this.imagePath,
      isShowWindow: isShowWindow ?? this.isShowWindow,
      isMinimizedWindow: isMinimizedWindow ?? this.isMinimizedWindow,
      isExpandedWindow: isExpandedWindow ?? this.isExpandedWindow,
    );
  }
}