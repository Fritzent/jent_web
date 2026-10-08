import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'ignite_event.dart';
import 'ignite_state.dart';

@injectable
class IgniteBloc extends Bloc<IgniteEvent, IgniteState> {
  Timer? _timer;
  double _progress = 0.0;

  IgniteBloc()
      : super(
          IgniteState(
            isLoading: true,
            canMoveNextScreen: false,
            progress: 0.0,
          ),
        ) {
    on<IgniteStarted>(_onStart);
    on<IgniteProgressUpdated>(_onProgressUpdated);
  }

  void _onStart(
    IgniteStarted event,
    Emitter<IgniteState> emit,
  ) {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(milliseconds: 25),
      (_) {
        _progress += 0.01;

        if (_progress >= 1.0) {
          _progress = 1.0;
          _timer?.cancel();
        }

        add(IgniteProgressUpdated(_progress));
      },
    );
  }

  void _onProgressUpdated(
    IgniteProgressUpdated event,
    Emitter<IgniteState> emit,
  ) {
    emit(
      state.copyWith(
        progress: event.progress,
        isLoading: event.progress < 1.0,
        canMoveNextScreen: event.progress >= 1.0,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}