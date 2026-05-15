part of 'splash_bloc.dart';

abstract class SplashEvent {
  const SplashEvent();
}

class InitializeSplashEvent extends SplashEvent {
  const InitializeSplashEvent();
}

class SplashDurationCompleteEvent extends SplashEvent {
  const SplashDurationCompleteEvent();
}

class SkipSplashEvent extends SplashEvent {
  const SkipSplashEvent();
}
