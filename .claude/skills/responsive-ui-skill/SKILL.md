---
name: responsive-ui-skill
description: Use when implementing responsive layouts, breakpoint-aware designs, mobile-first UI, tablet/web adaptations, navigation patterns, and cross-device compatibility for Admin and User apps.
argument-hint: [screen type: list, detail, form, or dashboard]
disable-model-invocation: true
---

## What This Skill Does

Generates responsive Flutter UI that adapts seamlessly across mobile (< 768px), tablet (768-1199px), and desktop (1200px+) with proper navigation patterns, input handling, and accessibility.

**Features:**
- ✅ Mobile-first responsive design
- ✅ Tablet & desktop adaptations
- ✅ Responsive navigation (drawer ↔ sidebar)
- ✅ Touch vs mouse/keyboard input handling
- ✅ Orientation awareness
- ✅ Screen size breakpoints
- ✅ Adaptive grid layouts
- ✅ Responsive dialogs & bottom sheets
- ✅ Web-specific input patterns (focus, keyboard)
- ✅ Dark/light mode responsive colors

## Responsive Breakpoints

```dart
class ResponsiveBreakpoints {
  static const mobile = 0;      // < 768px
  static const tablet = 768;    // 768 - 1199px
  static const desktop = 1200;  // >= 1200px
  
  static const mobileMax = 767;
  static const tabletMax = 1199;
}

// Usage
bool isMobile = MediaQuery.of(context).size.width < 768;
bool isTablet = MediaQuery.of(context).size.width >= 768 && 
                MediaQuery.of(context).size.width < 1200;
bool isDesktop = MediaQuery.of(context).size.width >= 1200;
```

## Step-by-Step Workflow

### 1. Define Screen Size Helper Utility
Create `lib/core/utils/responsive_helper.dart`:
- `isMobile(BuildContext)` → bool
- `isTablet(BuildContext)` → bool
- `isDesktop(BuildContext)` → bool
- `screenWidth(BuildContext)` → double
- `screenHeight(BuildContext)` → double
- `isSmallerThan(BuildContext, breakpoint)` → bool

### 2. Create Base Responsive Widget

**Path:** `lib/presentation/widgets/responsive_scaffold.dart`

```dart
class ResponsiveScaffold extends StatelessWidget {
  final Widget mobileBody;
  final Widget? tabletBody;  // Falls back to mobileBody if null
  final Widget? desktopBody; // Falls back to tabletBody/mobileBody
  final PreferredSizeWidget? appBar;
  final Widget? mobileDrawer;
  final Widget? desktopSidebar;
  
  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            desktopSidebar ?? const SizedBox.shrink(),
            Expanded(child: desktopBody ?? tabletBody ?? mobileBody),
          ],
        ),
      );
    } else if (isTablet(context)) {
      return Scaffold(
        appBar: appBar,
        drawer: mobileDrawer,
        body: tabletBody ?? mobileBody,
      );
    } else {
      return Scaffold(
        appBar: appBar,
        drawer: mobileDrawer,
        body: mobileBody,
      );
    }
  }
}
```

### 3. Mobile-First Layout Pattern

Build mobile first, then extend:
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(title: Text('Title')),
      
      // Mobile: vertical stack
      mobileBody: ListView(
        children: [
          ProductCard(...),
          ProductCard(...),
        ],
      ),
      
      // Tablet: 2-column grid
      tabletBody: GridView.count(
        crossAxisCount: 2,
        children: [ProductCard(...), ProductCard(...)],
      ),
      
      // Desktop: 3-column with sidebar
      desktopBody: GridView.count(
        crossAxisCount: 3,
        children: [ProductCard(...), ProductCard(...)],
      ),
      
      // Desktop sidebar
      desktopSidebar: DesktopSidebar(),
    );
  }
}
```

### 4. Navigation Pattern Adaptation

**Mobile:**
- Hamburger menu → drawer
- Bottom nav for primary actions
- Tab navigation for secondary

**Tablet:**
- Hamburger menu → drawer (or split-view)
- Side nav optional

**Desktop:**
- Persistent sidebar
- Top nav for secondary
- Breadcrumbs for hierarchy

Example:
```dart
// Admin Navigation
class AdminNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      // Persistent sidebar
      return NavigationRail(
        destinations: [...],
        selectedIndex: 0,
      );
    } else {
      // Drawer
      return Drawer(
        child: ListView(children: [...]),
      );
    }
  }
}
```

### 5. Input Handling Differences

**Mobile:** Touch-only
```dart
GestureDetector(
  onTap: () => action(),
  child: Card(...),
)
```

**Web/Desktop:** Mouse + Keyboard
```dart
MouseRegion(
  cursor: SystemMouseCursors.click,
  child: GestureDetector(
    onTap: () => action(),
    child: Focus(
      onKey: (node, event) {
        if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
          action();
        }
        return KeyEventResult.handled;
      },
      child: Card(...),
    ),
  ),
)
```

### 6. Responsive Grid & Layout

Use `GridView` with `MediaQuery`:
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: isMobile(context) ? 1 : isTablet(context) ? 2 : 3,
    childAspectRatio: isDesktop(context) ? 1.5 : 1,
  ),
  itemBuilder: (context, index) => ProductCard(),
)
```

Or use `LayoutBuilder` for dynamic widths:
```dart
LayoutBuilder(
  builder: (context, constraints) {
    int columns = constraints.maxWidth < 768 ? 1 : 
                  constraints.maxWidth < 1200 ? 2 : 3;
    return GridView.count(
      crossAxisCount: columns,
      children: [...],
    );
  },
)
```

### 7. Adaptive Dialog & Bottom Sheets

**Mobile:** Bottom sheet (full-screen modal)
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => MyForm(),
)
```

**Desktop:** Dialog (centered popup)
```dart
if (isDesktop(context)) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(width: 600, child: MyForm()),
    ),
  );
} else {
  showModalBottomSheet(
    context: context,
    builder: (context) => MyForm(),
  );
}
```

### 8. AppTextField & AppButton Responsive Sizing

**Mobile:** Full width
```dart
AppTextField(
  label: 'Email',
  controller: controller,
  // Fills available space
)
```

**Desktop:** Constrained width
```dart
SizedBox(
  width: 400,
  child: AppTextField(
    label: 'Email',
    controller: controller,
  ),
)
```

### 9. AppBar Customization by Screen Size

**Mobile:** Title only
```dart
AppBar(title: Text('Title'))
```

**Tablet:** Title + actions
```dart
AppBar(
  title: Text('Title'),
  actions: [IconButton(...), IconButton(...)],
)
```

**Desktop:** Logo + search + actions
```dart
AppBar(
  leading: Image.asset('logo.png'),
  title: AppTextField(hint: 'Search...'),
  actions: [...],
)
```

### 10. Orientation Awareness

Handle landscape:
```dart
@override
Widget build(BuildContext context) {
  final orientation = MediaQuery.of(context).orientation;
  
  if (orientation == Orientation.landscape) {
    return Row(children: [ProductList(), ProductDetail()]);
  } else {
    return Column(children: [ProductList(), ProductDetail()]);
  }
}
```

### 11. Safe Area & Notch Handling

Always use `SafeArea` for status bar & notch:
```dart
SafeArea(
  child: Scaffold(
    appBar: AppBar(...),
    body: ListView(...),
  ),
)
```

### 12. Padding & Spacing by Screen Size

Use responsive padding:
```dart
Padding(
  padding: EdgeInsets.all(
    isMobile(context) ? 16 : isTablet(context) ? 24 : 32,
  ),
  child: MyWidget(),
)
```

### 13. Font Sizes & Typography Scaling

Use design system (AppTextStyles) which handles responsive sizing:
```dart
Text(
  'Heading',
  style: AppTextStyles.displayLarge, // Scales based on screen
)
```

### 14. Testing Responsive Layouts

In `flutter test`:
```dart
testWidgets('Mobile layout shows single column', (WidgetTester tester) async {
  await tester.binding.window.physicalSizeTestValue = Size(400, 800);
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  
  await tester.pumpWidget(MyApp());
  expect(find.byType(GridView), findsNothing); // Mobile uses ListView
});

testWidgets('Desktop layout shows 3-column grid', (WidgetTester tester) async {
  await tester.binding.window.physicalSizeTestValue = Size(1920, 1080);
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  
  await tester.pumpWidget(MyApp());
  expect(find.byType(GridView), findsOneWidget); // Desktop uses GridView
  // Verify 3 columns
  expect(find.byType(ProductCard), findsWidgets); // Multiple items
});
```

## Implementation for Admin App First

**Phase 1:** Admin web (desktop focus)
- Persistent sidebar navigation
- 2-3 column dashboard layouts
- Responsive data tables
- Modal dialogs for forms

**Later:** Extend to User App
- Mobile-first for end-users
- Bottom nav for primary actions
- Full-screen modals for forms

## Key Considerations

- **Build mobile first,** then enhance for tablet/desktop
- **Test on actual devices** — emulators don't match all screen sizes
- **Use AppTextField/AppButton** from design system (already responsive)
- **Avoid hardcoded pixel values** — use MediaQuery or LayoutBuilder
- **Dark mode:** AppTheme handles responsive colors automatically
- **Performance:** Avoid rebuilds on orientation changes — use `MediaQuery.of()` in build, not in widget tree construction

---

**Phase 1 MVP:** Mobile & tablet layouts  
**Phase 2+:** Desktop web, web-specific interactions

---

**Ready for multi-device UI!**
