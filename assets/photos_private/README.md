# Private photos (correct PIN required)

Put the images visible **only after entering the correct PIN**
in this folder.

- Shown in the Photos window after a successful PIN unlock.
- Supported formats: `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`.

After adding/removing files, register them in
`lib/core/constants/app_images.dart` → `AppImages.privatePhotos`,
e.g. `'assets/photos_private/my-photo.jpg'`.

(`assets/` is bundled wholesale via `pubspec.yaml`, so no pubspec
change is needed — just list the new path in code.)
