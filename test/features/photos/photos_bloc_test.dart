import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/core/constants/app_images.dart';
import 'package:jent_web/features/photos/bloc/photos_bloc.dart';
import 'package:jent_web/features/photos/bloc/photos_event.dart';
import 'package:jent_web/features/photos/bloc/photos_state.dart';

void main() {
  PhotosBloc buildBloc() => PhotosBloc();

  group('photos window', () {
    blocTest<PhotosBloc, PhotosState>(
      'toggle always shows the PIN gate instead of opening directly',
      build: buildBloc,
      seed: () => PhotosState(
        isPhotosMinimized: true,
        isPhotosLocked: true,
        photosViewerIndex: 2,
      ),
      act: (bloc) => bloc.add(TogglePhotosWindow()),
      expect: () => [
        isA<PhotosState>()
            .having((s) => s.isShowPhotosWindow, 'shown', false)
            .having((s) => s.isPhotosPinVisible, 'pin', true)
            .having(
              (s) => s.isPhotosDeniedVisible,
              'denied',
              false,
            )
            .having((s) => s.isPhotosLocked, 'locked', true),
      ],
    );

    blocTest<PhotosBloc, PhotosState>(
      'correct PIN unlocks; closing re-locks so next toggle asks PIN again',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(TogglePhotosWindow());
        await Future<void>.delayed(Duration.zero);
        bloc.add(SubmitPhotosPin('1234'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(ClosePhotosWindow());
        await Future<void>.delayed(Duration.zero);
        bloc.add(TogglePhotosWindow());
      },
      expect: () => [
        isA<PhotosState>()
            .having((s) => s.isPhotosPinVisible, 'pin', true)
            .having((s) => s.isPhotosLocked, 'locked', true),
        isA<PhotosState>()
            .having((s) => s.isShowPhotosWindow, 'shown', true)
            .having((s) => s.isPhotosPinVisible, 'pin', false)
            .having((s) => s.isPhotosLocked, 'locked', false),
        isA<PhotosState>()
            .having((s) => s.isShowPhotosWindow, 'shown', false)
            .having((s) => s.isPhotosLocked, 'locked', true),
        isA<PhotosState>()
            .having((s) => s.isPhotosPinVisible, 'pin', true)
            .having((s) => s.isShowPhotosWindow, 'shown', false)
            .having((s) => s.isPhotosLocked, 'locked', true),
      ],
    );

    blocTest<PhotosBloc, PhotosState>(
      'wrong PIN shows denied; dismissing returns to the PIN prompt',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(TogglePhotosWindow());
        await Future<void>.delayed(Duration.zero);
        bloc.add(SubmitPhotosPin('9999'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DismissPhotosDenied());
      },
      expect: () => [
        isA<PhotosState>().having((s) => s.isPhotosPinVisible, 'pin', true),
        isA<PhotosState>()
            .having((s) => s.isPhotosDeniedVisible, 'denied', true)
            .having((s) => s.isPhotosPinVisible, 'pin', false),
        isA<PhotosState>()
            .having((s) => s.isPhotosDeniedVisible, 'denied', false)
            .having((s) => s.isPhotosPinVisible, 'pin', true),
      ],
    );

    blocTest<PhotosBloc, PhotosState>(
      'minimize hides the window, keeps the dock dot, and re-locks',
      build: buildBloc,
      seed: () => PhotosState(
        isShowPhotosWindow: true,
        isPhotosLocked: false,
      ),
      act: (bloc) => bloc.add(MinimizePhotosWindow()),
      expect: () => [
        isA<PhotosState>()
            .having((s) => s.isShowPhotosWindow, 'shown', false)
            .having((s) => s.isPhotosMinimized, 'minimized', true)
            .having((s) => s.isPhotosLocked, 'locked', true),
      ],
    );

    blocTest<PhotosBloc, PhotosState>(
      'select a photo opens the viewer when the window is unlocked',
      build: buildBloc,
      seed: () => PhotosState(
        isShowPhotosWindow: true,
        isPhotosLocked: false,
      ),
      act: (bloc) => bloc.add(SelectPhoto(2)),
      expect: () => [
        isA<PhotosState>()
            .having((s) => s.photosViewerIndex, 'viewer', 2)
            .having((s) => s.isShowPhotosWindow, 'shown', true),
      ],
    );

    blocTest<PhotosBloc, PhotosState>(
      'select is ignored while locked so it cannot bypass the PIN',
      build: buildBloc,
      act: (bloc) => bloc.add(SelectPhoto(2)),
      expect: () => [],
    );

    blocTest<PhotosBloc, PhotosState>(
      'select ignores out-of-range index',
      build: buildBloc,
      act: (bloc) => bloc.add(SelectPhoto(99)),
      expect: () => [],
    );

    blocTest<PhotosBloc, PhotosState>(
      'close resets window and viewer and re-locks',
      build: buildBloc,
      seed: () => PhotosState(
        isShowPhotosWindow: true,
        isPhotosExpanded: true,
        photosViewerIndex: 1,
        isPhotosLocked: false,
      ),
      act: (bloc) => bloc.add(ClosePhotosWindow()),
      expect: () => [
        isA<PhotosState>()
            .having((s) => s.isShowPhotosWindow, 'shown', false)
            .having((s) => s.isPhotosExpanded, 'expanded', false)
            .having((s) => s.photosViewerIndex, 'viewer', -1)
            .having((s) => s.isPhotosLocked, 'locked', true),
      ],
    );

    blocTest<PhotosBloc, PhotosState>(
      'viewing general photos opens the window while staying locked',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(TogglePhotosWindow());
        await Future<void>.delayed(Duration.zero);
        bloc.add(SubmitPhotosPin('9999'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(ViewGeneralPhotos());
      },
      expect: () => [
        isA<PhotosState>().having((s) => s.isPhotosPinVisible, 'pin', true),
        isA<PhotosState>()
            .having((s) => s.isPhotosDeniedVisible, 'denied', true)
            .having((s) => s.isPhotosPinVisible, 'pin', false),
        isA<PhotosState>()
            .having((s) => s.isShowPhotosWindow, 'shown', true)
            .having((s) => s.isPhotosDeniedVisible, 'denied', false)
            .having((s) => s.isPhotosLocked, 'locked', true)
            .having((s) => s.isPhotosGeneralMode, 'general', true)
            .having(
              (s) => s.visiblePhotos,
              'album',
              AppImages.generalPhotos,
            ),
      ],
    );

    blocTest<PhotosBloc, PhotosState>(
      'select a photo works in general mode without unlocking',
      build: buildBloc,
      seed: () => PhotosState(
        isShowPhotosWindow: true,
        isPhotosLocked: true,
        isPhotosGeneralMode: true,
      ),
      act: (bloc) => bloc.add(SelectPhoto(1)),
      expect: () => [
        isA<PhotosState>()
            .having((s) => s.photosViewerIndex, 'viewer', 1)
            .having((s) => s.isShowPhotosWindow, 'shown', true)
            .having((s) => s.isPhotosLocked, 'locked', true),
      ],
    );

    blocTest<PhotosBloc, PhotosState>(
      'toggle restores a minimized general album without asking PIN',
      build: buildBloc,
      seed: () => PhotosState(
        isPhotosMinimized: true,
        isPhotosLocked: true,
        isPhotosGeneralMode: true,
      ),
      act: (bloc) => bloc.add(TogglePhotosWindow()),
      expect: () => [
        isA<PhotosState>()
            .having((s) => s.isShowPhotosWindow, 'shown', true)
            .having((s) => s.isPhotosMinimized, 'minimized', false)
            .having((s) => s.isPhotosPinVisible, 'pin', false)
            .having((s) => s.isPhotosGeneralMode, 'general', true)
            .having((s) => s.isPhotosLocked, 'locked', true),
      ],
    );

    blocTest<PhotosBloc, PhotosState>(
      'close exits general mode so the private album stays gated',
      build: buildBloc,
      seed: () => PhotosState(
        isShowPhotosWindow: true,
        isPhotosLocked: true,
        isPhotosGeneralMode: true,
      ),
      act: (bloc) async {
        bloc.add(ClosePhotosWindow());
        await Future<void>.delayed(Duration.zero);
        bloc.add(TogglePhotosWindow());
      },
      expect: () => [
        isA<PhotosState>()
            .having((s) => s.isShowPhotosWindow, 'shown', false)
            .having((s) => s.isPhotosGeneralMode, 'general', false),
        isA<PhotosState>()
            .having((s) => s.isPhotosPinVisible, 'pin', true)
            .having((s) => s.isShowPhotosWindow, 'shown', false),
      ],
    );
  });

}
