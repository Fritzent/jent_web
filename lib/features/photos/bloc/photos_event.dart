abstract class PhotosEvent {}

class TogglePhotosWindow extends PhotosEvent {}

class ClosePhotosWindow extends PhotosEvent {}

class MinimizePhotosWindow extends PhotosEvent {}

class TogglePhotosExpanded extends PhotosEvent {}

class SelectPhoto extends PhotosEvent {
  final int index;

  SelectPhoto(this.index);
}

class ClosePhotoViewer extends PhotosEvent {}

class SubmitPhotosPin extends PhotosEvent {
  final String pin;

  SubmitPhotosPin(this.pin);
}

class DismissPhotosPin extends PhotosEvent {}

class DismissPhotosDenied extends PhotosEvent {}

/// Opens the Photos window with the general album after a wrong PIN.
/// The private album stays locked.
class ViewGeneralPhotos extends PhotosEvent {}
