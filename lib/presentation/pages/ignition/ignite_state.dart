class IgniteState {
  final bool isLoading;
  final bool canMoveNextScreen;
  final double progress;

  const IgniteState({
    required this.isLoading,
    required this.canMoveNextScreen,
    required this.progress,
  });

  IgniteState copyWith({
    bool? isLoading,
    bool? canMoveNextScreen,
    double? progress,
  }) {
    return IgniteState(
      isLoading: isLoading ?? this.isLoading,
      canMoveNextScreen: canMoveNextScreen ?? this.canMoveNextScreen,
      progress: progress ?? this.progress,
    );
  }
}