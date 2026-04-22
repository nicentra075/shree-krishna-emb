# Design System & Architecture Guide

## 📋 Table of Contents
1. [Design System Overview](#design-system-overview)
2. [Theme Implementation](#theme-implementation)
3. [BLoC/Qubit Architecture Guide](#blocqubit-architecture-guide)
4. [Using the Theme](#using-the-theme)
5. [Creating New BLoCs](#creating-new-blocs)
6. [Dark Mode Support](#dark-mode-support)

---

## Design System Overview

### The Creative North Star: "The Modern Heirloom"

This app uses a design system that bridges ancient Indian embroidery craftsmanship with modern digital interfaces.

#### Key Design Principles

1. **Intentional Asymmetry**: Breaking rigid grids with staggered layouts
2. **Organic Breathability**: Using whitespace as a functional design element
3. **Cultural Modernism**: Subtle integration of traditional motifs

#### Color Palette

- **Primary (Royal Saffron)**
  - Dark: `#8f4e00` - Used for main actions
  - Light: `#ff9933` - Used for highlights and CTAs

- **Secondary (Deep Blue)**
  - Dark: `#4059aa` - Used for navigation and headers
  - Light: `#8fa7fe` - Used for secondary actions

- **Neutrals**
  - Surface: `#FFFBFe` (light) / `#1a1c19` (dark)
  - On Surface: `#1a1c19` (light) / `#f5f5f1` (dark)

#### Typography

- **Headlines (Plus Jakarta Sans)**: Display, Headline styles
  - Modern, geometric feel for editorial content
  - Use for marketing sections and titles

- **Body (Manrope)**: Body and Label styles
  - Highly readable at all scales
  - Maintains premium "tech" feel
  - Use for descriptions and technical details

#### Design Rules (The "No-Line" Rule)

❌ **Don't Use**: 1px solid borders to divide content
✅ **Do Use**: Background color shifts and tonal transitions

Example:
```dart
// Bad - using borders
Container(
  decoration: BoxDecoration(
    border: Border(bottom: BorderSide(color: Colors.black))
  ),
)

// Good - using background color
Container(
  color: AppTheme.surfaceContainerLow,
  child: ...
)
```

---

## Theme Implementation

### File Structure

```
lib/
├── theme/
│   └── app_theme.dart          # Main theme configuration
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart  # Splash screen using theme
│   └── walkthrough/
│       └── walkthrough_screen.dart
└── main.dart                    # App root with theme setup
```

### AppTheme Class

The `AppTheme` class provides two complete themes:

```dart
// Light theme
ThemeData lightTheme = AppTheme.lightTheme;

// Dark theme
ThemeData darkTheme = AppTheme.darkTheme;
```

### Using Colors from the Theme

```dart
import 'package:shree_krishna_emb/theme/app_theme.dart';

// Access colors
Container(
  color: AppTheme.primaryDark,      // #8f4e00
  child: Text(
    'Hello',
    style: TextStyle(
      color: AppTheme.onSurfaceLight,  // Text color
    ),
  ),
)

// Or use context theme
Container(
  color: Theme.of(context).colorScheme.primary,
  child: ...
)
```

### Using Typography from the Theme

```dart
// Use Theme text styles
Text(
  'Main Title',
  style: Theme.of(context).textTheme.displayLarge,
)

// Use specific sizes
Text(
  'Subtitle',
  style: Theme.of(context).textTheme.headlineMedium,
)

// Available styles:
// Display: displayLarge, displayMedium, displaySmall
// Headline: headlineLarge, headlineMedium, headlineSmall
// Title: titleLarge, titleMedium, titleSmall
// Body: bodyLarge, bodyMedium, bodySmall
// Label: labelLarge, labelMedium, labelSmall
```

### Special Effects

#### Ambient Shadow (for floating elements)

```dart
Container(
  decoration: BoxDecoration(
    boxShadow: AppTheme.ambientShadow,  // 32px blur, 8px offset, 6% opacity
  ),
)
```

#### Glass Morphism (for floating headers)

```dart
Container(
  decoration: AppTheme.glassMorphism,  // 80% opacity surface with backdrop blur
)
```

---

## BLoC/Qubit Architecture Guide

### What is BLoC?

**BLoC** (Business Logic Component) or **Qubit** is a state management pattern that separates business logic from UI:

```
┌─────────────────────────────────────────┐
│             USER INTERACTION            │
│    (tap, swipe, lifecycle event)        │
└────────────────┬────────────────────────┘
                 │
                 ▼
         ┌───────────────┐
         │  Emit Event   │
         └───────┬───────┘
                 │
                 ▼
    ┌────────────────────────┐
    │    BLoC (Business      │
    │    Logic Component)    │
    │  - Process event       │
    │  - Apply logic         │
    │  - Calculate new state │
    └────────────┬───────────┘
                 │
                 ▼
         ┌──────────────────┐
         │   Emit State     │
         └──────────┬───────┘
                    │
                    ▼
         ┌──────────────────┐
         │  BlocBuilder or  │
         │ BlocListener     │
         └──────────┬───────┘
                    │
                    ▼
        ┌──────────────────────┐
        │   UI Rebuilds with   │
        │    New State         │
        └──────────────────────┘
```

### Core Concepts

#### 1. **Events** (Input)

Events are user actions or system triggers:

```dart
abstract class SplashEvent {
  const SplashEvent();
}

class InitializeSplashEvent extends SplashEvent {
  const InitializeSplashEvent();
}
```

#### 2. **States** (Output)

States represent the UI condition at any point in time:

```dart
sealed class SplashState extends Equatable {
  const SplashState();
}

class SplashLoading extends SplashState {
  const SplashLoading();
}

class SplashComplete extends SplashState {
  const SplashComplete();
}
```

#### 3. **BLoC** (Business Logic)

The BLoC processes events and emits states:

```dart
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(const SplashInitial()) {
    on<InitializeSplashEvent>(_onInitialize);
  }

  Future<void> _onInitialize(
    InitializeSplashEvent event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());
    // Do work here
    emit(const SplashComplete());
  }
}
```

### Example: SplashBloc Walkthrough

The `SplashBloc` handles the splash screen flow:

1. **Initialization**
   ```dart
   SplashBloc() : super(const SplashInitial())
   ```
   - Starts in `SplashInitial` state
   - No UI rendered yet

2. **Event Trigger**
   ```dart
   context.read<SplashBloc>().add(const InitializeSplashEvent());
   ```
   - User/system adds an event
   - BLoC receives it

3. **Event Handler**
   ```dart
   Future<void> _onInitialize(
     InitializeSplashEvent event,
     Emitter<SplashState> emit,
   ) async {
     emit(const SplashLoading());
     await Future.delayed(Duration(seconds: 3));
     emit(const SplashComplete());
   }
   ```
   - Handler is called
   - Emits `SplashLoading` state (shows spinner)
   - Waits 3 seconds
   - Emits `SplashComplete` state (triggers navigation)

4. **UI Rebuild**
   ```dart
   BlocBuilder<SplashBloc, SplashState>(
     builder: (context, state) {
       if (state is SplashLoading) {
         return CircularProgressIndicator();
       }
       if (state is SplashComplete) {
         // Navigate
       }
     },
   )
   ```

---

## Using the Theme

### In main.dart

```dart
class _MainAppState extends State<MainApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }
}
```

### In Screens

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Screen',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ElevatedButton(
          onPressed: () {},
          child: Text('Click Me'),
        ),
      ),
    );
  }
}
```

---

## Creating New BLoCs

### Step-by-Step Guide

#### 1. Create Event Class

File: `lib/bloc/my_feature/my_feature_event.dart`

```dart
abstract class MyFeatureEvent {
  const MyFeatureEvent();
}

class LoadDataEvent extends MyFeatureEvent {
  const LoadDataEvent();
}

class UpdateDataEvent extends MyFeatureEvent {
  final String newData;
  const UpdateDataEvent(this.newData);
}
```

#### 2. Create State Class

File: `lib/bloc/my_feature/my_feature_state.dart`

```dart
import 'package:equatable/equatable.dart';

sealed class MyFeatureState extends Equatable {
  const MyFeatureState();
  
  @override
  List<Object?> get props => [];
}

class MyFeatureInitial extends MyFeatureState {
  const MyFeatureInitial();
}

class MyFeatureLoading extends MyFeatureState {
  const MyFeatureLoading();
}

class MyFeatureLoaded extends MyFeatureState {
  final String data;
  const MyFeatureLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class MyFeatureError extends MyFeatureState {
  final String message;
  const MyFeatureError(this.message);
  
  @override
  List<Object?> get props => [message];
}
```

#### 3. Create BLoC Class

File: `lib/bloc/my_feature/my_feature_bloc.dart`

```dart
import 'package:bloc/bloc.dart';
import 'my_feature_event.dart';
import 'my_feature_state.dart';

class MyFeatureBloc extends Bloc<MyFeatureEvent, MyFeatureState> {
  MyFeatureBloc() : super(const MyFeatureInitial()) {
    on<LoadDataEvent>(_onLoadData);
    on<UpdateDataEvent>(_onUpdateData);
  }

  Future<void> _onLoadData(
    LoadDataEvent event,
    Emitter<MyFeatureState> emit,
  ) async {
    emit(const MyFeatureLoading());
    try {
      // Load data from API or database
      final data = await _loadData();
      emit(MyFeatureLoaded(data));
    } catch (e) {
      emit(MyFeatureError(e.toString()));
    }
  }

  Future<void> _onUpdateData(
    UpdateDataEvent event,
    Emitter<MyFeatureState> emit,
  ) async {
    // Update logic
  }

  Future<String> _loadData() async {
    // Simulate network call
    await Future.delayed(const Duration(seconds: 2));
    return 'Loaded Data';
  }
}
```

#### 4. Use in Screen

```dart
class MyFeatureScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MyFeatureBloc()..add(const LoadDataEvent()),
      child: BlocListener<MyFeatureBloc, MyFeatureState>(
        listener: (context, state) {
          if (state is MyFeatureError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<MyFeatureBloc, MyFeatureState>(
          builder: (context, state) {
            if (state is MyFeatureLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MyFeatureLoaded) {
              return Column(
                children: [
                  Text(state.data),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MyFeatureBloc>().add(
                        UpdateDataEvent('new data'),
                      );
                    },
                    child: const Text('Update'),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
```

---

## Dark Mode Support

### How It Works

The theme automatically switches based on system settings or explicit user choice:

```dart
// Automatic (follows system)
themeMode: ThemeMode.system

// Light mode only
themeMode: ThemeMode.light

// Dark mode only
themeMode: ThemeMode.dark
```

### Toggling Dark Mode

```dart
// In a settings screen
ElevatedButton(
  onPressed: () {
    // Get the MainApp state and toggle
    final mainAppState = context.findAncestorStateOfType<_MainAppState>();
    mainAppState?.toggleDarkMode();
  },
  child: const Text('Toggle Dark Mode'),
)
```

### Getting Current Theme

```dart
final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

if (isDarkMode) {
  // Use dark-specific colors
} else {
  // Use light-specific colors
}
```

---

## Best Practices

### 1. Theme Usage

✅ **Do**
```dart
Color primaryColor = Theme.of(context).colorScheme.primary;
TextStyle headingStyle = Theme.of(context).textTheme.headlineMedium!;
```

❌ **Don't**
```dart
Color primaryColor = const Color(0xFF8f4e00);  // Hardcoded color
TextStyle headingStyle = TextStyle(fontSize: 28, fontWeight: FontWeight.bold);
```

### 2. BLoC Event Handling

✅ **Do**
```dart
on<MyEvent>((event, emit) async {
  emit(LoadingState());
  try {
    final result = await _doWork();
    emit(SuccessState(result));
  } catch (e) {
    emit(ErrorState(e.toString()));
  }
});
```

❌ **Don't**
```dart
on<MyEvent>((event, emit) {
  // No loading state
  final result = _doWork();  // Not async
  emit(SuccessState(result));
});
```

### 3. Widget Composition

✅ **Do**
```dart
BlocProvider(
  create: (context) => MyBloc(),
  child: BlocListener<MyBloc, MyState>(
    listener: (context, state) { /* side effects */ },
    child: BlocBuilder<MyBloc, MyState>(
      builder: (context, state) { /* UI */ },
    ),
  ),
)
```

❌ **Don't**
```dart
// Mixing BlocListener and BlocBuilder logic
BlocBuilder(
  builder: (context, state) {
    if (state is Error) {
      Navigator.pop(context);  // Side effect in builder!
    }
    return UI();
  },
)
```

---

## Resources

- [Flutter BLoC Documentation](https://bloclibrary.dev/)
- [Material Design 3](https://m3.material.io/)
- [Flutter Theme Documentation](https://flutter.dev/docs/cookbook/design/themes)

---

**Happy Building! 🚀**
