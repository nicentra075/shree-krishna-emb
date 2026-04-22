part of 'splash_bloc.dart';

/// Splash Events - These are actions/triggers that the user or system initiates
///
/// In Qubit (BLoC) architecture, events are the "input" to your state machine.
/// When something happens (user taps, timer fires, data loads), you emit an event.
///
/// QUBIT GUIDE:
/// Events are typically immutable classes that extend the base event class.
/// Use sealed class + subclasses for type-safe pattern matching.

abstract class SplashEvent {
  const SplashEvent();
}

/// Initialize Splash Screen
///
/// Triggered when the app starts and the splash screen first loads.
/// This event signals that splash screen initialization should begin:
/// - Duration timers
/// - Asset preloading
/// - Initial state setup
class InitializeSplashEvent extends SplashEvent {
  const InitializeSplashEvent();
}

/// Splash Duration Completed
///
/// Fired after the splash screen display duration expires (e.g., 3 seconds).
/// This tells the BLoC that it's time to transition to the next screen.
class SplashDurationCompleteEvent extends SplashEvent {
  const SplashDurationCompleteEvent();
}

/// Skip Splash Screen
///
/// Allows users to tap to skip the splash and proceed immediately.
/// This event can be triggered by a user interaction (long press or tap).
class SkipSplashEvent extends SplashEvent {
  const SkipSplashEvent();
}
