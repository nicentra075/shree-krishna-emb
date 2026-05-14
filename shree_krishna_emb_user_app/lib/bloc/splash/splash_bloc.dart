import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shree_krishna_emb/data/datasources/local_user_datasource.dart';

part 'splash_event.dart';
part 'splash_state.dart';

/// Splash BLoC - Business Logic Component for Splash Screen
///
/// QUBIT ARCHITECTURE GUIDE:
/// ========================
/// Qubit (or BLoC) is a state management pattern that separates business logic
/// from UI. It follows these principles:
///
/// 1. **Events** (Input): User actions or system triggers
/// 2. **BLoC** (Processing): Business logic and state transitions
/// 3. **States** (Output): UI representation of current data
///
/// FLOW DIAGRAM:
/// ```
///    Event (User Action)
///       ↓
///    BLoC (on<EventName> handler)
///       ↓
///    emit(NewState)
///       ↓
///    UI Rebuilds (BlocBuilder/BlocListener)
/// ```
///
/// EXAMPLE FLOW IN THIS APP:
/// ```
/// 1. App starts → InitializeSplashEvent
/// 2. BLoC receives event → _onInitialize handler
/// 3. Handler emits SplashLoading state
/// 4. After 3 seconds → emit SplashComplete
/// 5. UI navigates to Walkthrough when SplashComplete is received
/// ```

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  /// Timer for splash screen duration
  Timer? _splashTimer;

  /// Local data source for persistent storage
  final LocalUserDataSource _localDataSource;

  /// Duration to show splash screen before transitioning
  static const Duration splashDuration = Duration(seconds: 3);

  /// Constructor - Initialize BLoC with SplashInitial state
  ///
  /// QUBIT GUIDE:
  /// The constructor sets the initial state and registers event handlers.
  /// Each event type has its own handler method (`on<EventName>`).
  SplashBloc({required LocalUserDataSource localDataSource})
      : _localDataSource = localDataSource,
        super(const SplashInitial()) {
    // Register event handlers
    // This tells the BLoC: "When you receive this event, call this handler"
    on<InitializeSplashEvent>(_onInitialize);
    on<SplashDurationCompleteEvent>(_onSplashComplete);
    on<SkipSplashEvent>(_onSkipSplash);
  }

  /// Handler for InitializeSplashEvent
  ///
  /// QUBIT GUIDE:
  /// Event handlers are async functions that:
  /// 1. Receive the event
  /// 2. Process business logic
  /// 3. Emit new states via the emitter
  ///
  /// The `emit()` function sends a new state, which triggers UI rebuild.
  /// Think of it like: "Hey UI, here's your new state!"
  ///
  /// Parameters:
  /// - event: The InitializeSplashEvent that triggered this handler
  /// - emit: Function to emit new states
  Future<void> _onInitialize(
    InitializeSplashEvent event,
    Emitter<SplashState> emit,
  ) async {
    // Check if user has seen walkthrough before
    final walkthroughSeen = await _localDataSource.getWalkthroughSeen();

    // Emit loading state - tells UI to show splash screen
    emit(SplashLoading(elapsed: Duration.zero, skipWalkthrough: walkthroughSeen));

    // Start a timer for the splash duration
    // After 3 seconds, we'll emit SplashComplete
    _splashTimer = Timer(splashDuration, () {
      // Add event to trigger completion
      add(const SplashDurationCompleteEvent());
    });
  }

  /// Handler for SplashDurationCompleteEvent
  ///
  /// QUBIT GUIDE:
  /// This handler is called when the splash timer completes.
  /// It emits SplashComplete state, which tells the UI to navigate.
  Future<void> _onSplashComplete(
    SplashDurationCompleteEvent event,
    Emitter<SplashState> emit,
  ) async {
    // Cancel timer if still running
    _splashTimer?.cancel();

    // Emit complete state - this triggers navigation in UI
    emit(const SplashComplete());
  }

  /// Handler for SkipSplashEvent
  ///
  /// QUBIT GUIDE:
  /// Users can skip the splash by tapping. This handler handles that action.
  /// It immediately emits SplashComplete without waiting for the timer.
  Future<void> _onSkipSplash(
    SkipSplashEvent event,
    Emitter<SplashState> emit,
  ) async {
    // Cancel the timer
    _splashTimer?.cancel();

    // Immediately emit complete state
    emit(const SplashComplete());
  }

  /// Cleanup
  ///
  /// QUBIT GUIDE:
  /// Always clean up resources in close(). This is called when the BLoC
  /// is destroyed (e.g., when user navigates away).
  @override
  Future<void> close() {
    _splashTimer?.cancel();
    return super.close();
  }
}

/// HOW TO USE THIS BLOC IN YOUR SCREEN:
///
/// ```dart
/// class SplashScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return BlocProvider(
///       create: (context) => SplashBloc()..add(const InitializeSplashEvent()),
///       child: BlocListener<SplashBloc, SplashState>(
///         listener: (context, state) {
///           if (state is SplashComplete) {
///             // Navigate to next screen
///             Navigator.of(context).pushReplacementNamed('/walkthrough');
///           }
///         },
///         child: BlocBuilder<SplashBloc, SplashState>(
///           builder: (context, state) {
///             if (state is SplashLoading) {
///               return Center(child: CircularProgressIndicator());
///             }
///             return Container(); // Empty while transitioning
///           },
///         ),
///       ),
///     );
///   }
/// }
/// ```
