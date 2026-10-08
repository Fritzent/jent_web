import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:jent_web/core/constants/vault_pin.dart';
import 'package:jent_web/features/photos/bloc/photos_event.dart';
import 'package:jent_web/features/photos/bloc/photos_state.dart';

@injectable
class PhotosBloc extends Bloc<PhotosEvent, PhotosState> {
  PhotosBloc() : super(const PhotosState()) {
    on<TogglePhotosWindow>(_onTogglePhotosWindow);
    on<SubmitPhotosPin>(_onSubmitPhotosPin);
    on<DismissPhotosPin>(_onDismissPhotosPin);
    on<DismissPhotosDenied>(_onDismissPhotosDenied);
    on<ViewGeneralPhotos>(_onViewGeneralPhotos);
    on<ClosePhotosWindow>(_onClosePhotosWindow);
    on<MinimizePhotosWindow>(_onMinimizePhotosWindow);
    on<TogglePhotosExpanded>(_onTogglePhotosExpanded);
    on<SelectPhoto>(_onSelectPhoto);
    on<ClosePhotoViewer>(_onClosePhotoViewer);
  }

  void _onTogglePhotosWindow(
    TogglePhotosWindow event,
    Emitter<PhotosState> emit,
  ) {
    // Window open: lock it again and hide it. Next open must go
    // through the PIN gate.
    if (state.isShowPhotosWindow) {
      emit(
        state.copyWith(
          isShowPhotosWindow: false,
          isPhotosMinimized: false,
          isPhotosExpanded: false,
          photosViewerIndex: -1,
          isPhotosLocked: true,
          isPhotosPinVisible: false,
          isPhotosDeniedVisible: false,
          isPhotosGeneralMode: false,
        ),
      );
      return;
    }
    // Restoring a minimized guest album needs no PIN: the general
    // album is public. Anything else goes through the PIN gate.
    if (state.isPhotosMinimized && state.isPhotosGeneralMode) {
      emit(
        state.copyWith(
          isShowPhotosWindow: true,
          isPhotosMinimized: false,
          isPhotosExpanded: false,
          photosViewerIndex: -1,
          isPhotosLocked: true,
          isPhotosPinVisible: false,
          isPhotosDeniedVisible: false,
          isPhotosGeneralMode: true,
        ),
      );
      return;
    }
    // Opening (fresh or from minimize) always requires the PIN.
    // Keep the window hidden until the correct PIN is submitted.
    emit(
      state.copyWith(
        isShowPhotosWindow: false,
        isPhotosLocked: true,
        isPhotosPinVisible: true,
        isPhotosDeniedVisible: false,
        isPhotosGeneralMode: false,
      ),
    );
  }

  void _onSubmitPhotosPin(
    SubmitPhotosPin event,
    Emitter<PhotosState> emit,
  ) {
    if (event.pin == vaultPin) {
      emit(
        state.copyWith(
          isPhotosPinVisible: false,
          isPhotosDeniedVisible: false,
          isPhotosLocked: false,
          isShowPhotosWindow: true,
          isPhotosMinimized: false,
          isPhotosExpanded: false,
          photosViewerIndex: -1,
          isPhotosGeneralMode: false,
        ),
      );
    } else {
      emit(
        state.copyWith(
          isPhotosPinVisible: false,
          isPhotosDeniedVisible: true,
          isPhotosLocked: true,
        ),
      );
    }
  }

  void _onDismissPhotosPin(DismissPhotosPin event, Emitter<PhotosState> emit) {
    emit(
      state.copyWith(
        isPhotosPinVisible: false,
        isPhotosLocked: true,
        isPhotosGeneralMode: false,
      ),
    );
  }

  void _onDismissPhotosDenied(
    DismissPhotosDenied event,
    Emitter<PhotosState> emit,
  ) {
    // Return to the PIN prompt so the user can retry immediately.
    emit(
      state.copyWith(
        isPhotosDeniedVisible: false,
        isPhotosPinVisible: true,
        isPhotosLocked: true,
      ),
    );
  }

  void _onViewGeneralPhotos(
    ViewGeneralPhotos event,
    Emitter<PhotosState> emit,
  ) {
    // Guest mode: show the general album. The private album stays
    // locked, so a later dock tap still asks for the PIN.
    emit(
      state.copyWith(
        isPhotosDeniedVisible: false,
        isPhotosPinVisible: false,
        isPhotosLocked: true,
        isShowPhotosWindow: true,
        isPhotosMinimized: false,
        isPhotosExpanded: false,
        photosViewerIndex: -1,
        isPhotosGeneralMode: true,
      ),
    );
  }

  void _onClosePhotosWindow(
    ClosePhotosWindow event,
    Emitter<PhotosState> emit,
  ) {
    emit(
      state.copyWith(
        isShowPhotosWindow: false,
        isPhotosMinimized: false,
        isPhotosExpanded: false,
        photosViewerIndex: -1,
        isPhotosLocked: true,
        isPhotosPinVisible: false,
        isPhotosDeniedVisible: false,
        isPhotosGeneralMode: false,
      ),
    );
  }

  void _onMinimizePhotosWindow(
    MinimizePhotosWindow event,
    Emitter<PhotosState> emit,
  ) {
    // Guest mode survives minimizing (the general album is public), so
    // restoring from the dock reopens it without a PIN.
    emit(
      state.copyWith(
        isShowPhotosWindow: false,
        isPhotosMinimized: true,
        isPhotosExpanded: false,
        isPhotosLocked: true,
        isPhotosPinVisible: false,
        isPhotosDeniedVisible: false,
      ),
    );
  }

  void _onTogglePhotosExpanded(
    TogglePhotosExpanded event,
    Emitter<PhotosState> emit,
  ) {
    emit(state.copyWith(isPhotosExpanded: !state.isPhotosExpanded));
  }

  void _onSelectPhoto(SelectPhoto event, Emitter<PhotosState> emit) {
    if (event.index < 0 || event.index >= state.visiblePhotos.length) {
      return;
    }
    // The private gallery is PIN-gated: viewer navigation is allowed
    // while the unlocked window is open, or in guest (general) mode.
    // This prevents reopening a locked/closed window without going
    // through the PIN prompt.
    if (!state.isShowPhotosWindow) return;
    if (state.isPhotosLocked && !state.isPhotosGeneralMode) return;
    emit(
      state.copyWith(
        photosViewerIndex: event.index,
        isShowPhotosWindow: true,
        isPhotosMinimized: false,
      ),
    );
  }

  void _onClosePhotoViewer(ClosePhotoViewer event, Emitter<PhotosState> emit) {
    emit(state.copyWith(photosViewerIndex: -1));
  }
}
