# App Routing System Guide

## Overview

The app uses a **centralized routing system** in `lib/routes/app_routes.dart`. This means all routes, navigation, and arguments are managed in one place.

### Benefits

✅ Single source of truth for all routes
✅ No hardcoded navigation strings
✅ Type-safe argument passing
✅ Consistent navigation patterns
✅ Easy to add animations
✅ Easy to debug
✅ Scalable for large apps

---

## Quick Start

### Basic Navigation

**Old Way (Don't Do This)**
```dart
Navigator.of(context).pushNamed('/my-screen');
```

**New Way (Do This)**
```dart
context.navigateToMyScreen();
```

### Navigation with Arguments

**Old Way**
```dart
Navigator.of(context).pushNamed(
  '/profile',
  arguments: {'userId': '123'},
);
```

**New Way**
```dart
context.navigateToProfile('123');
```

---

## File Structure

```
lib/
├── routes/
│   └── app_routes.dart          [MAIN] Centralized routing
├── main.dart                     [UPDATED] Uses AppRoutes
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart   [UPDATED] Uses navigation
│   └── walkthrough/
│       └── walkthrough_screen.dart
└── ROUTING_GUIDE.md             [THIS FILE]
```

---

## How AppRoutes Works

### 1. Route Names (Constants)

All route names are defined as constants:

```dart
class AppRoutes {
  static const String splash = '/splash';
  static const String walkthrough = '/walkthrough';
  static const String home = '/home';
  // Add more routes here
}
```

### 2. Route Arguments (Type-Safe)

Arguments are passed via dedicated classes:

```dart
// Define argument class
class ProfileArgs {
  final String userId;
  ProfileArgs({required this.userId});
}

// Pass arguments
AppRoutes.navigateToProfile(context, userId: '123');
```

### 3. Route Generation

`onGenerateRoute` is the central method that creates screens:

```dart
static Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case splash:
      return _buildRoute(
        settings: settings,
        builder: (context) => const SplashScreen(),
        transitionType: _TransitionType.none,
      );
    
    case home:
      final args = settings.arguments as ProfileArgs?;
      return _buildRoute(
        settings: settings,
        builder: (context) => ProfileScreen(userId: args?.userId ?? ''),
      );
    
    // Add more cases here...
  }
}
```

### 4. Navigation Methods

Dedicated methods for each navigation:

```dart
class AppRoutes {
  // Navigate to splash
  static Future<void> navigateToSplash(BuildContext context) {
    return Navigator.of(context).pushNamedAndRemoveUntil(
      splash,
      (route) => false,
    );
  }

  // Navigate to home with arguments
  static Future<void> navigateToHome(
    BuildContext context,
    String userId,
  ) {
    return Navigator.of(context).pushNamed(
      home,
      arguments: ProfileArgs(userId: userId),
    );
  }
}
```

### 5. Extension Methods (Optional)

Extensions make navigation shorter:

```dart
extension AppNavigationExtension on BuildContext {
  Future<void> navigateToSplash() {
    return AppRoutes.navigateToSplash(this);
  }

  Future<void> navigateToHome(String userId) {
    return AppRoutes.navigateToHome(this, userId);
  }
}
```

---

## How to Add a New Screen

### Step 1: Create the Screen

Create your screen file:
```dart
// lib/screens/my_feature/my_screen.dart
class MyScreen extends StatelessWidget {
  final String? data;
  
  const MyScreen({this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: Center(child: Text(data ?? 'No data')),
    );
  }
}
```

### Step 2: Define Arguments Class (if needed)

In `lib/routes/app_routes.dart`, add:
```dart
class MyScreenArgs {
  final String data;
  MyScreenArgs({required this.data});
}
```

### Step 3: Add Route Name

In `AppRoutes` class:
```dart
static const String myScreen = '/my-screen';
```

### Step 4: Add Route Case

In `onGenerateRoute` method:
```dart
case myScreen:
  final args = settings.arguments as MyScreenArgs?;
  return _buildRoute(
    settings: settings,
    builder: (context) => MyScreen(data: args?.data),
    transitionType: _TransitionType.fadeInSlide,
  );
```

### Step 5: Add Navigation Method

```dart
static Future<void> navigateToMyScreen(
  BuildContext context, {
  required String data,
}) {
  return Navigator.of(context).pushNamed(
    myScreen,
    arguments: MyScreenArgs(data: data),
  );
}
```

### Step 6: Add Extension Method (Optional)

```dart
extension AppNavigationExtension on BuildContext {
  Future<void> navigateToMyScreen({required String data}) {
    return AppRoutes.navigateToMyScreen(this, data: data);
  }
}
```

### Step 7: Use Navigation

In any screen:
```dart
// Option 1: Using AppRoutes directly
AppRoutes.navigateToMyScreen(context, data: 'Hello');

// Option 2: Using extension (shorter)
context.navigateToMyScreen(data: 'Hello');
```

---

## Navigation Types

### 1. Push (Go forward, can go back)

```dart
AppRoutes.push(
  context,
  AppRoutes.myScreen,
  arguments: MyScreenArgs(data: 'Hello'),
);
```

**When to use:**
- Opening detail pages from lists
- Opening dialogs/modals
- User might want to go back

### 2. Push Replacement All (Go forward, no back button)

```dart
AppRoutes.pushReplacementAll(
  context,
  AppRoutes.splash,
);
```

**When to use:**
- After login/logout
- Navigating to new major section
- User shouldn't go back

### 3. Navigation Methods (Recommended)

```dart
AppRoutes.navigateToSplash(context);
// or
context.navigateToSplash();
```

**When to use:**
- Most common pattern
- Type-safe and documented
- Easy to understand

---

## Transition Animations

Available transition types:

```dart
enum _TransitionType {
  none,                 // No animation
  fadeInSlide,         // Fade + slide from right
  fadeOnly,            // Just fade in
  slideFromBottom,     // Slide from bottom
  scale,               // Scale animation
}
```

Use when building routes:

```dart
return _buildRoute(
  settings: settings,
  builder: (context) => const MyScreen(),
  transitionType: _TransitionType.slideFromBottom,  // Choose animation
);
```

---

## Current Routes

| Route | Screen | Arguments | Purpose |
|-------|--------|-----------|---------|
| `/splash` | `SplashScreen` | None | App entry point |
| `/walkthrough` | `WalkthroughScreen` | `WalkthroughArgs` | Onboarding flow |

**Add more routes here as you build!**

---

## Best Practices

### ✅ DO

```dart
// ✅ Use AppRoutes constants
context.navigateToHome();

// ✅ Use dedicated argument classes
AppRoutes.navigateToProfile(context, userId: userId);

// ✅ Use extension methods for cleaner code
context.navigateToMyScreen(data: 'Hello');

// ✅ Document navigation methods
/// Navigate to home screen with user ID
static Future<void> navigateToHome(BuildContext context, String userId)

// ✅ Type-safe arguments
class ProfileArgs {
  final String userId;
  ProfileArgs({required this.userId});
}
```

### ❌ DON'T

```dart
// ❌ Hardcoded route strings
Navigator.of(context).pushNamed('/home');

// ❌ Passing dynamic/untyped arguments
Navigator.of(context).pushNamed('/home', arguments: {'userId': '123'});

// ❌ Scattered navigation logic
// Navigation logic should be in AppRoutes only

// ❌ Mixing different navigation patterns
// Use consistent patterns throughout the app
```

---

## Debugging

### View All Routes

Check `AppRoutes` class in `lib/routes/app_routes.dart` to see all available routes.

### Add Route but Forgot to Add Case?

You'll get:
```
Route not found: /my-route
```

**Fix:** Add the case in `onGenerateRoute` method.

### Arguments Not Being Passed?

Check:
1. Argument class defined?
2. Arguments passed in navigation method?
3. Cast to correct type in `onGenerateRoute`?

```dart
// Make sure types match
case myScreen:
  final args = settings.arguments as MyScreenArgs?;  // Correct type!
  return _buildRoute(...);
```

---

## Migration from Old System

If you see old navigation code:

### Old Code
```dart
Navigator.of(context).pushNamed('/my-screen');
```

### New Code
```dart
context.navigateToMyScreen();
```

**Migration steps:**
1. Add route to `AppRoutes` (follow "How to Add a New Screen" section)
2. Replace old navigation with new method
3. Remove any hardcoded route strings

---

## Future Enhancements

This routing system supports:
- 🎯 Route guards (authentication checks)
- 📊 Analytics tracking (page views)
- 🔐 Deep linking (open app from links)
- 🎬 Advanced animations
- 📱 Platform-specific routes

All can be added without changing existing navigation code!

---

## Questions?

Refer to:
1. `lib/routes/app_routes.dart` - Implementation details
2. `DESIGN_SYSTEM_GUIDE.md` - General architecture
3. `IMPLEMENTATION_SUMMARY.md` - What was created

---

**Happy routing! 🚀**
