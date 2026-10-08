import 'package:jent_web/core/constants/app_images.dart';

class PhotosState {
  final bool isShowPhotosWindow;
  final bool isPhotosMinimized;
  final bool isPhotosExpanded;
  final int photosViewerIndex;
  final bool isPhotosLocked;
  final bool isPhotosPinVisible;
  final bool isPhotosDeniedVisible;

  /// When true, the Photos window shows the general album without
  /// unlocking (opened from the access-denied card). The private album
  /// stays locked.
  final bool isPhotosGeneralMode;

  const PhotosState({
    this.isShowPhotosWindow = false,
    this.isPhotosMinimized = false,
    this.isPhotosExpanded = false,
    this.photosViewerIndex = -1,
    this.isPhotosLocked = true,
    this.isPhotosPinVisible = false,
    this.isPhotosDeniedVisible = false,
    this.isPhotosGeneralMode = false,
  });

  PhotosState copyWith({
    bool? isShowPhotosWindow,
    bool? isPhotosMinimized,
    bool? isPhotosExpanded,
    int? photosViewerIndex,
    bool? isPhotosLocked,
    bool? isPhotosPinVisible,
    bool? isPhotosDeniedVisible,
    bool? isPhotosGeneralMode,
  }) {
    return PhotosState(
      isShowPhotosWindow: isShowPhotosWindow ?? this.isShowPhotosWindow,
      isPhotosMinimized: isPhotosMinimized ?? this.isPhotosMinimized,
      isPhotosExpanded: isPhotosExpanded ?? this.isPhotosExpanded,
      photosViewerIndex: photosViewerIndex ?? this.photosViewerIndex,
      isPhotosLocked: isPhotosLocked ?? this.isPhotosLocked,
      isPhotosPinVisible: isPhotosPinVisible ?? this.isPhotosPinVisible,
      isPhotosDeniedVisible:
          isPhotosDeniedVisible ?? this.isPhotosDeniedVisible,
      isPhotosGeneralMode:
          isPhotosGeneralMode ?? this.isPhotosGeneralMode,
    );
  }

  /// Album currently displayed in the Photos window: the general album
  /// in guest mode, the private album once unlocked.
  List<String> get visiblePhotos =>
      isPhotosGeneralMode ? AppImages.generalPhotos : AppImages.privatePhotos;
}
