abstract class IgniteEvent {}

class IgniteStarted extends IgniteEvent {}

class IgniteProgressUpdated extends IgniteEvent {
  final double progress;

  IgniteProgressUpdated(this.progress);
}