abstract class HomeEvent {}

class StartWallpaperRotation extends HomeEvent {}

class NextWallpaper extends HomeEvent {}

class ToggleOpenEmailMenu extends HomeEvent {}

class ToggleCloseEmailMenu extends HomeEvent {}

class ToggleMinimizeEmailMenu extends HomeEvent {}

class ToggleExpandEmailMenu extends HomeEvent {}

class ToggleMusicPlayer extends HomeEvent {}

class CloseMusicPlayer extends HomeEvent {}

class MinimizeMusicPlayer extends HomeEvent {}

class ExpandMusicPlayer extends HomeEvent {}

class SelectMusicTrack extends HomeEvent {
  final int index;

  SelectMusicTrack(this.index);
}

class ToggleMusicPlayback extends HomeEvent {}

class NextMusicTrack extends HomeEvent {}

class PreviousMusicTrack extends HomeEvent {}

class MusicProgressTicked extends HomeEvent {
  final Duration position;

  MusicProgressTicked(this.position);
}

class SendEmail extends HomeEvent {
  final String name;
  final String from;
  final String subject;
  final String body;

  SendEmail({
    required this.name,
    required this.from,
    required this.subject,
    required this.body,
  });
}
