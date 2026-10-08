# General photos (no PIN needed)

Put the images visible to **everyone** in this folder.

- Shown when a user enters the **wrong PIN** and taps
  **"View general photos"** on the access-denied card.
- Supported formats: `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`.

After adding/removing files, register them in
`lib/core/constants/app_images.dart` → `AppImages.generalPhotos`,
e.g. `'assets/photos_general/my-photo.jpg'`.

(`assets/` is bundled wholesale via `pubspec.yaml`, so no pubspec
change is needed — just list the new path in code.)
