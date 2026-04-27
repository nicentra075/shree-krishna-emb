# AppAppBar Usage Guide

## Overview

`AppAppBar` is a reusable, themeable AppBar component for consistent navigation and header styling across all screens in the Shree Krishna Embroidery app.

## Features

- ✅ Automatic dark/light mode support via theme config
- ✅ Customizable title and subtitle
- ✅ Built-in back button handling
- ✅ Flexible leading and action widgets
- ✅ Elevation and border customization
- ✅ Bottom border divider support
- ✅ Responsive height configuration

## Basic Usage

### Simple AppBar with Title

```dart
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';

Scaffold(
  appBar: AppAppBar(
    title: 'Home',
  ),
  body: Center(child: Text('Your content here')),
)
```

### AppBar with Back Button

```dart
Scaffold(
  appBar: AppAppBar(
    title: 'Product Details',
    onBack: () => Navigator.pop(context),
  ),
  body: Center(child: Text('Your content here')),
)
```

### AppBar with Title and Subtitle

```dart
Scaffold(
  appBar: AppAppBar(
    title: 'Orders',
    subtitle: '5 active orders',
    onBack: () => Navigator.pop(context),
  ),
  body: Center(child: Text('Your content here')),
)
```

### AppBar with Action Buttons

```dart
Scaffold(
  appBar: AppAppBar(
    title: 'Messages',
    onBack: () => Navigator.pop(context),
    actions: [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => print('Search pressed'),
      ),
      IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => print('More pressed'),
      ),
    ],
  ),
  body: Center(child: Text('Your content here')),
)
```

### AppBar with Custom Leading Widget

```dart
Scaffold(
  appBar: AppAppBar(
    title: 'Profile',
    leading: Container(
      margin: const EdgeInsets.all(8),
      child: const CircleAvatar(
        backgroundImage: NetworkImage('https://...'),
      ),
    ),
  ),
  body: Center(child: Text('Your content here')),
)
```

### AppBar with Custom Background Color

```dart
Scaffold(
  appBar: AppAppBar(
    title: 'Special Screen',
    backgroundColor: Colors.blue.shade100,
    onBack: () => Navigator.pop(context),
  ),
  body: Center(child: Text('Your content here')),
)
```

### AppBar Centered Title

```dart
Scaffold(
  appBar: AppAppBar(
    title: 'My App',
    centerTitle: true,
    onBack: () => Navigator.pop(context),
  ),
  body: Center(child: Text('Your content here')),
)
```

## API Reference

### Constructor Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `title` | `String` | Required | Title text displayed in the AppBar |
| `subtitle` | `String?` | `null` | Optional subtitle displayed below title |
| `leading` | `Widget?` | `null` | Custom leading widget (overrides auto back button) |
| `onBack` | `VoidCallback?` | `null` | Callback when back button is pressed |
| `actions` | `List<Widget>?` | `null` | Action widgets displayed on the right |
| `centerTitle` | `bool` | `false` | Center the title horizontally |
| `backgroundColor` | `Color?` | `null` | Custom background color |
| `elevation` | `double` | `1` | Elevation/shadow depth |
| `themeConfig` | `AppThemeConfig?` | `null` | Theme configuration for colors |
| `showBottomBorder` | `bool` | `true` | Show bottom border divider |
| `bottomBorderColor` | `Color?` | `null` | Custom border color |
| `titlePadding` | `EdgeInsets` | `EdgeInsets.symmetric(horizontal: 16, vertical: 12)` | Padding around title |
| `appBarHeight` | `double` | `56` | Custom height for the AppBar |

## Common Patterns

### AppBar with Search Action

```dart
Scaffold(
  appBar: AppAppBar(
    title: 'Designs',
    actions: [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          // Show search dialog or navigate to search screen
        },
      ),
    ],
  ),
  body: // ...
)
```

### AppBar with Cart Badge

```dart
Scaffold(
  appBar: AppAppBar(
    title: 'Shop',
    actions: [
      Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart
            },
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '5',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
  body: // ...
)
```

### AppBar with Multiple Actions

```dart
Scaffold(
  appBar: AppAppBar(
    title: 'Settings',
    onBack: () => Navigator.pop(context),
    actions: [
      IconButton(
        icon: const Icon(Icons.help_outline),
        onPressed: () => _showHelp(context),
      ),
      IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () => _showInfo(context),
      ),
    ],
  ),
  body: // ...
)
```

## Styling Notes

- The AppBar uses your design system's primary dark color by default
- Text styles are automatically applied from `AppTextStyles`
- Dark/light mode support is automatic via `AppThemeConfig`
- Bottom border color defaults to primary color with 10% opacity
- All icon colors match the primary color theme

## Migration from Flutter's AppBar

### Before (Standard Flutter AppBar)
```dart
AppBar(
  title: const Text('Title'),
  backgroundColor: Colors.white,
  elevation: 1,
)
```

### After (Using AppAppBar)
```dart
AppAppBar(
  title: 'Title',
)
```

The `AppAppBar` handles all styling, theming, and consistency automatically!

## Best Practices

1. **Always use for consistency** - Replace all custom AppBar implementations with `AppAppBar`
2. **Localize titles** - Pass localized strings from `AppLocalization.strings`
3. **Handle back correctly** - Provide `onBack` callback instead of relying on default behavior
4. **Keep titles concise** - Keep titles short for better mobile experience
5. **Use actions sparingly** - Limit to 2-3 actions maximum
6. **Test theme switching** - Verify AppBar looks good in both light and dark modes

## Example: Full Screen with AppAppBar

```dart
class ProductScreen extends StatelessWidget {
  const ProductScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Product Details',
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareProduct(context),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => _toggleLike(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Product image
            Image.network('https://...'),
            // Product details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Name',
                    style: AppTextStyles.headlineMedium(),
                  ),
                  // More details
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

For questions or issues, refer to the main CLAUDE.md documentation or check existing screen implementations.
