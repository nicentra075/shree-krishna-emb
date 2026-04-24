# Enforce App Routing System

**Status**: Active
**Purpose**: Remind to always use centralized AppRoutes for navigation and screen management
**Last Updated**: 2026-04-22

## Rule

Whenever adding:
- ✅ New screens
- ✅ New routes
- ✅ Navigation logic
- ✅ Route arguments

**ALWAYS use the `AppRoutes` system** instead of hardcoding navigation.

## Location

`lib/routes/app_routes.dart` - This is the single source of truth for all routing.

## How to Use

### ❌ DON'T Do This (Hardcoded Navigation)
```dart
Navigator.of(context).pushNamed('/my-screen');
```

### ✅ DO This (Using AppRoutes)
```dart
// Option 1: Using AppRoutes directly
AppRoutes.navigateToMyScreen(context);

// Option 2: Using extension (shorter)
context.navigateToMyScreen();
```

## Adding a New Screen

**Step 1:** Add route name constant in `AppRoutes`
```dart
static const String myScreen = '/my-screen';
```

**Step 2:** Add case in `onGenerateRoute` method
```dart
case myScreen:
  return _buildRoute(
    settings: settings,
    builder: (context) => const MyScreen(),
    transitionType: _TransitionType.fadeInSlide,
  );
```

**Step 3:** Add navigation method in `AppRoutes`
```dart
static Future<void> navigateToMyScreen(BuildContext context) {
  return Navigator.of(context).pushNamed(myScreen);
}
```

**Step 4:** (Optional) Add extension method for shorter syntax
```dart
Future<void> navigateToMyScreen() => AppRoutes.navigateToMyScreen(this);
```

## Benefits

✅ All routes in one place
✅ No hardcoded route strings scattered across the app
✅ Type-safe argument passing
✅ Consistent navigation patterns
✅ Easy to add middleware (analytics, logging, etc.)
✅ Easy to debug routing issues
✅ Built-in transition animations

## Checklist Before Merging

- [ ] New screen added to `AppRoutes.onGenerateRoute`
- [ ] Route name constant defined in `AppRoutes`
- [ ] Navigation method created (if navigation from other screens)
- [ ] Extension method added (optional but recommended)
- [ ] No hardcoded `Navigator.pushNamed()` calls in code
- [ ] Arguments handled via argument classes (not dynamic)

## Files to Update

When adding a new screen, update ONLY:
1. `lib/routes/app_routes.dart` - Add route, navigation method, argument class
2. Screens that navigate TO this screen - Use `AppRoutes.navigateToXxx()` method

## Current Routes

- `/splash` → `SplashScreen`
- `/walkthrough` → `WalkthroughScreen`

Add more as you build the app!

---

**This file helps maintain consistent routing throughout the app.**
