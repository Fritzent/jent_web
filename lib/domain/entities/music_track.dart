class MusicTrack {
  final String title;
  final String artist;
  final Duration duration;

  const MusicTrack({
    required this.title,
    required this.artist,
    required this.duration,
  });
}

abstract class MusicPlaylist {
  static const tracks = [
    MusicTrack(
      title: 'Ghibli No Umi',
      artist: 'Nanbaka',
      duration: Duration(minutes: 3, seconds: 5),
    ),
    MusicTrack(
      title: 'Midnight Reverie',
      artist: 'Pritjent Ensemble',
      duration: Duration(minutes: 4, seconds: 12),
    ),
    MusicTrack(
      title: 'Paper Lanterns',
      artist: 'Nanbaka',
      duration: Duration(minutes: 2, seconds: 48),
    ),
  ];
}
