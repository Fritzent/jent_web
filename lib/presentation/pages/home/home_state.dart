enum EmailStatus { idle, sending, sent, error }

class HomeState {
  final int currentIndex;
  final String imagePath;
  final bool isShowWindow;
  final bool isMinimizedWindow;
  final bool isExpandedWindow;
  final EmailStatus emailStatus;
  final bool isShowMusicPlayer;
  final bool isMusicMinimized;
  final bool isMusicExpanded;
  final bool isMusicPlaying;
  final int musicTrackIndex;
  final Duration musicPosition;

  const HomeState({
    required this.currentIndex,
    required this.imagePath,
    this.isShowWindow = false,
    this.isMinimizedWindow = false,
    this.isExpandedWindow = false,
    this.emailStatus = EmailStatus.idle,
    this.isShowMusicPlayer = false,
    this.isMusicMinimized = false,
    this.isMusicExpanded = false,
    this.isMusicPlaying = false,
    this.musicTrackIndex = 0,
    this.musicPosition = Duration.zero,
  });

  HomeState copyWith({
    int? currentIndex,
    String? imagePath,
    bool? isShowWindow,
    bool? isMinimizedWindow,
    bool? isExpandedWindow,
    EmailStatus? emailStatus,
    bool? isShowMusicPlayer,
    bool? isMusicMinimized,
    bool? isMusicExpanded,
    bool? isMusicPlaying,
    int? musicTrackIndex,
    Duration? musicPosition,
  }) {
    return HomeState(
      currentIndex: currentIndex ?? this.currentIndex,
      imagePath: imagePath ?? this.imagePath,
      isShowWindow: isShowWindow ?? this.isShowWindow,
      isMinimizedWindow: isMinimizedWindow ?? this.isMinimizedWindow,
      isExpandedWindow: isExpandedWindow ?? this.isExpandedWindow,
      emailStatus: emailStatus ?? this.emailStatus,
      isShowMusicPlayer: isShowMusicPlayer ?? this.isShowMusicPlayer,
      isMusicMinimized: isMusicMinimized ?? this.isMusicMinimized,
      isMusicExpanded: isMusicExpanded ?? this.isMusicExpanded,
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      musicTrackIndex: musicTrackIndex ?? this.musicTrackIndex,
      musicPosition: musicPosition ?? this.musicPosition,
    );
  }
}
