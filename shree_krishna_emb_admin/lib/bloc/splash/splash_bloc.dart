import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  Timer? _splashTimer;

  static const Duration splashDuration = Duration(seconds: 2);

  SplashBloc() : super(const SplashInitial()) {
    on<InitializeSplashEvent>(_onInitialize);
    on<SplashDurationCompleteEvent>(_onSplashComplete);
    on<SkipSplashEvent>(_onSkipSplash);
  }

  Future<void> _onInitialize(
    InitializeSplashEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading(elapsed: Duration.zero));

    _splashTimer = Timer(splashDuration, () {
      add(const SplashDurationCompleteEvent());
    });
  }

  Future<void> _onSplashComplete(
    SplashDurationCompleteEvent event,
    Emitter<SplashState> emit,
  ) async {
    _splashTimer?.cancel();
    emit(const SplashComplete());
  }

  Future<void> _onSkipSplash(
    SkipSplashEvent event,
    Emitter<SplashState> emit,
  ) async {
    _splashTimer?.cancel();
    emit(const SplashComplete());
  }

  @override
  Future<void> close() {
    _splashTimer?.cancel();
    return super.close();
  }
}
