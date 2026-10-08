abstract class AppImages {
  static const homeBackground =  [
    'assets/il_home_1.jpg',
    'assets/il_home_3.jpg',
    'assets/il_home_2.jpg',
    'assets/il_home_4.jpg',
    'assets/il_home_5.jpg',
  ];

  /// Gallery photos (asset paths) shown in the Photos window.
  ///
  /// - [generalPhotos]: shown to everyone, no PIN needed. Add files under
  ///   `assets/photos_general/` and list them here.
  /// - [privatePhotos]: shown only after entering the correct PIN. Add
  ///   files under `assets/photos_private/` and list them here.
  static const photos = privatePhotos;

  static const generalPhotos = [
    'assets/photos_general/il_home_1.jpg',
    'assets/photos_general/il_home_2.jpg',
  ];

  static const privatePhotos = [
    'assets/photos_private/il_home_1.jpg',
    'assets/photos_private/il_home_2.jpg',
    'assets/photos_private/il_home_3.jpg',
    'assets/photos_private/il_home_4.jpg',
    'assets/photos_private/il_home_5.jpg',
  ];
}