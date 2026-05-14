part of 'splash_bloc.dart';

/// Splash States - These represent the different UI states the splash screen can be in
///
/// In Qubit (BLoC) architecture, states are the "output" - they tell the UI what to render.
/// States should be immutable and represent a single point-in-time condition.
///
/// QUBIT GUIDE:
/// - States are immutable snapshots of your data
/// - Each state represents one possible UI condition
/// - The UI listens to state changes via BlocBuilder/BlocListener
/// - Use equality checks (override `List<Object?>` get props) for state comparison

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

/// Initial Splash State
///
/// This is the very first state when the app starts, before any initialization.
/// The splash screen shows a loading indicator and starts the initialization timer.
class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Splash Loading State
///
/// The splash screen is displaying and counting down to transition.
/// This state includes the duration elapsed for animation purposes and
/// whether to skip the walkthrough based on previous user interaction.
///
/// Example usage:
/// ```dart
/// final splashDuration = Duration(seconds: 3);
/// emit(SplashLoading(elapsed: Duration(seconds: 1), skipWalkthrough: false));
/// ```
class SplashLoading extends SplashState {
  final Duration elapsed;
  final bool skipWalkthrough;

  const SplashLoading({
    required this.elapsed,
    this.skipWalkthrough = false,
  });

  @override
  List<Object?> get props => [elapsed, skipWalkthrough];
}

/// Splash Complete State
///
/// The splash screen has finished displaying and is ready to navigate away.
/// This state triggers the navigation to the next screen (e.g., Walkthrough).
///
/// QUBIT GUIDE:
/// When you emit this state, the UI should navigate using:
/// ```dart
/// context.read<SplashBloc>()
///     .stream
///     .listen((state) {
///       if (state is SplashComplete) {
///         Navigator.of(context).pushReplacementNamed('/walkthrough');
///       }
///     });
/// ```
class SplashComplete extends SplashState {
  const SplashComplete();
}

/// Splash Error State (Optional)
///
/// If there's an error loading assets or initializing, emit this state.
/// The UI can then show an error message and retry option.
class SplashError extends SplashState {
  final String message;

  const SplashError(this.message);

  @override
  List<Object?> get props => [message];
}
