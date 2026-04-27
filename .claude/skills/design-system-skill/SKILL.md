---
name: design-system-skill
description: Use when someone asks to create a new screen, generate a login screen, build a product listing page, convert a Stitch design to code, create a screen from Figma or Stitch selection, or create a UI or screen from pasted design.
argument-hint: [screen description or design details]
disable-model-invocation: true
---

## What This Skill Does

Generates complete, production-ready screens that always follow your design system, include proper localization, BLoC state management, and integrate with your clean architecture (clean architecture with datasources, repositories, entities, models).

The skill handles:
- ✅ Design system components (AppAppBar, AppTextField, AppButton, AppTheme, etc.)
- ✅ Dark & light mode support with proper theme data
- ✅ BLoC state management
- ✅ Localization for all user-visible strings (en_US, hi_IN)
- ✅ Clean architecture layer generation (screens, BLoCs, models, repositories)
- ✅ Firestore integration (if applicable)
- ✅ Beautiful animations and UI polish

## Step-by-Step Workflow

### Step 1: Gather Initial Information
1. Ask the user which app: **Admin App** or **User App**?
2. Ask for screen details:
   - Option A: Describe the screen in words
   - Option B: Paste Stitch/Figma design (JSON or screenshot)
   - Option C: Paste UI design code

### Step 2: Ask Clarifying Questions
If any of these are unclear, ask the user:
- **What is the main purpose of this screen?** (login, profile, product listing, etc.)
- **Does this screen need data from the backend?** (forms, API calls, Firestore queries, etc.)
- **What state does this screen need to manage?** (loading, error, success states?)
- **Are there any custom widgets needed beyond the design system?**
- **Any specific animations or interactions?**

### Step 3: Design System Component Validation
Before generating code:
1. **Read** the design system components from: `/Applications/Documents/dev/shree-krishna-emb/design_system`
2. **Map** the Stitch/Figma design to design system components:
   - Use `AppTextField` for all text inputs
   - Use `AppButton` for buttons
   - Use `AppTheme` colors and text styles
   - Use design system spacing, typography, corner radius
3. If the user requests custom widgets:
   - Ask: **Is this widget useful for other screens in your apps?**
   - If yes: Ask **Should we add this to the design system for reuse?**
   - If custom widget is needed: Generate it separately with a note to add it to design system

### Step 4: Localization Check
1. **Read** existing localization files:
   - `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/localisations/locales/en_us.dart`
   - `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/localisations/locales/hi_in.dart`
   - Do the same for Admin App if applicable

2. **Identify all user-visible strings** from the screen (labels, hints, button text, error messages, etc.)
3. **Check if strings exist** in localization:
   - If yes: Use them from `AppLocalization.strings.stringKey`
   - If no: Add new getter to base class and implement in both en_us.dart and hi_in.dart
   - If localization not possible yet: Add English text with `// TODO: Add localisation for this string`

### Step 5: Determine Data Layer Needs
Ask the user if the screen needs:
- **Models/Entities?** (data structures for products, users, etc.)
- **BLoC?** (state management - usually yes)
- **Repositories?** (data access layer)
- **Data sources?** (Firebase, API, local storage)
- **Use cases?** (business logic)
- **Firestore changes?** (new collections, security rules)
- **API calls?** (backend endpoints)

If user is unsure: **Explain what each layer does and ask which ones to include**

### Step 6: Generate Complete Code

#### Generate Screen File
**Path:** `lib/screens/[category]/[screen_name]_screen.dart`

Template:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_user_app/localisations/localisation.dart';

class [ScreenName]Screen extends StatefulWidget {
  const [ScreenName]Screen({Key? key}) : super(key: key);

  @override
  State<[ScreenName]Screen> createState() => _[ScreenName]ScreenState();
}

class _[ScreenName]ScreenState extends State<[ScreenName]Screen> {
  late [FeatureName]Bloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<[FeatureName]Bloc>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalization.strings.screenTitle,
        onBack: () => Navigator.pop(context),
      ),
      body: BlocBuilder<[FeatureName]Bloc, [FeatureName]State>(
        builder: (context, state) {
          if (state is [FeatureName]Loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is [FeatureName]Error) {
            return Center(child: Text(state.message));
          }
          if (state is [FeatureName]Loaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Add widgets here using design system components
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }
}
```

Rules:
- ✅ Use **design system components only** (AppTextField, AppButton, AppTheme)
- ✅ **NO hardcoded strings** - use `AppLocalization.strings.keyName`
- ✅ **NO hardcoded colors/spacing** - use `AppTheme` tokens
- ✅ **Dark mode support** - use `AppTheme` which handles both modes
- ✅ **Proper BLoC integration** - use `BlocBuilder` and `BlocListener`
- ✅ **Memory management** - dispose BLoCs properly
- ✅ **Beautiful animations** - add smooth transitions, staggered animations if applicable

#### Generate BLoC Files (if state management needed)
**Path:** `lib/bloc/[feature]/`

Files to generate:
1. `[feature]_bloc.dart`
2. `[feature]_event.dart`
3. `[feature]_state.dart`

Example structure:
```dart
// [feature]_event.dart
abstract class [FeatureName]Event extends Equatable {
  const [FeatureName]Event();
  
  @override
  List<Object?> get props => [];
}

class Load[FeatureName]Event extends [FeatureName]Event {
  const Load[FeatureName]Event();
}

// [feature]_state.dart
abstract class [FeatureName]State extends Equatable {
  const [FeatureName]State();
  
  @override
  List<Object?> get props => [];
}

class [FeatureName]Initial extends [FeatureName]State {
  const [FeatureName]Initial();
}

class [FeatureName]Loading extends [FeatureName]State {
  const [FeatureName]Loading();
}

class [FeatureName]Loaded extends [FeatureName]State {
  final [Data] data;
  const [FeatureName]Loaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class [FeatureName]Error extends [FeatureName]State {
  final String message;
  const [FeatureName]Error(this.message);
  
  @override
  List<Object?> get props => [message];
}

// [feature]_bloc.dart
class [FeatureName]Bloc extends Bloc<[FeatureName]Event, [FeatureName]State> {
  final [UseCase] useCase;
  
  [FeatureName]Bloc(this.useCase) : super(const [FeatureName]Initial()) {
    on<Load[FeatureName]Event>(_onLoad);
  }
  
  Future<void> _onLoad(Load[FeatureName]Event event, Emitter<[FeatureName]State> emit) async {
    emit(const [FeatureName]Loading());
    
    final result = await useCase();
    
    result.fold(
      (failure) => emit([FeatureName]Error(failure.message)),
      (data) => emit([FeatureName]Loaded(data)),
    );
  }
}
```

#### Generate Data Layer (if needed)
**Domain layer** - `lib/domain/repositories/[feature]_repository.dart`
**Domain layer** - `lib/domain/usecases/[feature]_usecase.dart` (if needed)
**Data layer** - `lib/data/datasources/firebase_[feature]_datasource.dart` (or api_, local_)
**Data layer** - `lib/data/repositories/[feature]_repository_impl.dart`
**Models** - `lib/models/[feature]_model.dart` (if needed)

Follow the patterns from:
- `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/data/datasources/`
- `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/domain/repositories/`

#### Update Localization Files
**Path:** `lib/localisations/locales/`

For each new string, add getter to both files:

**en_us.dart:**
```dart
@override
String get newStringKey => 'Display Text in English';
```

**hi_in.dart:**
```dart
@override
String get newStringKey => 'प्रदर्शन पाठ हिंदी में';
```

If localization is pending: `// TODO: Add localisation for newStringKey`

### Step 7: Validate Against Checklist
Before outputting code, verify:
- [ ] **Use AppAppBar for navigation** - Replace all `AppBar(...)` with `AppAppBar(title: '...', onBack: () => Navigator.pop(context))`
  - AppAppBar provides: consistent styling, dark mode support, built-in back button, localized titles, bottom border
  - Features: title, subtitle (optional), leading widget (optional), actions (optional), custom background color
- [ ] **No custom TextField** - All text inputs use `AppTextField`
- [ ] **No custom buttons** - Use `AppButton` or design system buttons
- [ ] **No ScaffoldMessenger** - Use `AppSnackbar.show()` for toasts
- [ ] **No hardcoded colors** - Use `AppTheme` colors
- [ ] **No inline text styles** - Use `AppTextStyles`
- [ ] **Correct import** - Hide `AppTextField` from `flutter_ui_toolbox`:
  ```dart
  import 'package:flutter_ui_toolbox/flutter_ui_toolbox.dart' hide AppTextField;
  import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
  ```
- [ ] **All user text is localized** - No hardcoded strings visible to end user
- [ ] **BLoC properly integrated** - Using BlocBuilder/BlocListener with proper disposal
- [ ] **Dark mode support** - Using AppTheme tokens
- [ ] **Clean architecture layers** - Proper separation of presentation/domain/data

### Step 8: If Custom Widgets Requested
If user wants a custom widget that doesn't exist in design system:
1. Ask: **Is this widget useful for other screens in the admin or user app?**
2. If yes: Offer to add it to `/Applications/Documents/dev/shree-krishna-emb/design_system`
3. Ask confirmation before adding to design system
4. Generate the custom widget with proper documentation

### Step 9: If Backend Work Needed
If the screen requires:
- Firestore setup
- Firebase Security Rules
- API endpoint creation
- Database migrations

Then:
1. **Ask:** What backend work is needed?
2. **Check:** Does a backend skill exist in `.claude/skills/`?
3. **Delegate:** If backend skill exists, send request to it with this context
4. **OR:** Ask user if they want you to generate backend setup code

### Step 10: Output Complete Code
Generate all files in the correct folder structure (see "Outputs" section above).

For each file, provide:
- Full file path
- Complete code
- Instructions where to place it

---

## Notes & Guardrails

### What This Skill DOES
✅ Generate screens with design system components
✅ Handle localization (en_US, hi_IN)
✅ Create BLoCs with proper state management
✅ Generate data layer (repositories, datasources, models)
✅ Support dark/light mode
✅ Add animations and polish
✅ Follow clean architecture
✅ Ask questions when unclear

### What This Skill DOES NOT DO
❌ Modify Firebase Security Rules (ask user or delegate to backend skill)
❌ Set up databases or migrations (ask user or delegate)
❌ Create API endpoints (ask user or delegate to backend skill)
❌ Add tracking/analytics (outside scope)

### Guardrails

**Hardcoded Strings:** 
- If you can't localize a string immediately, add English text with `// TODO: Add localisation`
- Never output screens with hardcoded user-visible text

**Custom Widgets:**
- If user requests custom widget, ask if it's reusable across apps
- If yes, offer to add to design system with user confirmation

**Data Layer Complexity:**
- If data layer is complex, ask user: "This needs models, repositories, and datasources. Should I generate these?"
- Provide option to skip complex layers if user only wants the screen

**Scope Creep:**
- No limits on animation complexity or UI polish
- No limits on feature complexity
- If backend work is needed, delegate or ask user

**Dependencies:**
- Always check `lib/localisations/locales/` before saying a string doesn't exist
- Always check design system folder before saying a component doesn't exist
- Always validate correct folder structure for target app (Admin or User)

---

## Design System Reference

Common design system components available at `/Applications/Documents/dev/shree-krishna-emb/design_system`:

**AppBar:**
- `AppAppBar` - For all navigation headers (replaces Flutter's default AppBar)
- Properties:
  - `title` (String, required) - Header title
  - `subtitle` (String?) - Optional subtitle below title
  - `onBack` (VoidCallback?) - Back button callback (auto-shows if provided)
  - `leading` (Widget?) - Custom leading widget (overrides auto back button)
  - `actions` (List<Widget>?) - Action buttons on the right (search, menu, etc.)
  - `centerTitle` (bool) - Center the title
  - `backgroundColor` (Color?) - Custom background (defaults to theme)
  - `elevation` (double) - Shadow elevation (default: 1)
  - `showBottomBorder` (bool) - Show bottom divider (default: true)
- Example:
  ```dart
  AppAppBar(
    title: 'Products',
    onBack: () => Navigator.pop(context),
    actions: [IconButton(icon: Icon(Icons.search), onPressed: () {})],
  )
  ```

**Text Inputs:**
- `AppTextField` - For all text input fields
- Supports: label, hint, prefixIcon, suffixIcon, validator, keyboardType, obscureText

**Buttons:**
- `AppButton` - For primary buttons
- Other button variants from design system

**Theme:**
- `AppTheme` - Access colors, text styles, spacing
- Dark mode automatically handled

**Localization:**
- `AppLocalization.strings.keyName` - All user-visible text

**Loading/States:**
- `AppLoader` - Loading spinner
- `AppShimmer` - Skeleton loading
- `AppSnackbar.show()` - Toast notifications

---

## Localization File Locations

**User App:**
- Base: `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/localisations/locales/locale_base.dart`
- English: `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/localisations/locales/en_us.dart`
- Hindi: `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/localisations/locales/hi_in.dart`

**Admin App:**
- Check equivalent paths in Admin App folder

---

## Architecture Layers Reference

When generating data layer, follow:

**Domain Layer** (`lib/domain/`):
- Abstract repository interface
- Entities (pure Dart, backend-agnostic)
- Use cases (business logic)

**Data Layer** (`lib/data/`):
- Concrete repository implementation
- Data sources (Firebase, API, local)
- Models (with Firebase & API conversion methods)

**Presentation Layer** (`lib/presentation/` or `lib/screens/`):
- Screens (UI)
- BLoCs (state management)
- Widgets (reusable UI components)

Never import Firebase in presentation layer.

---

## Example Output

When user asks: *"Create a product listing screen for the user app with filtering by category"*

You would generate:
1. `lib/screens/products/product_listing_screen.dart` - Main screen
2. `lib/bloc/product/product_bloc.dart`, `product_event.dart`, `product_state.dart` - State management
3. `lib/domain/repositories/product_repository.dart` - Repository interface
4. `lib/data/repositories/product_repository_impl.dart` - Repository implementation
5. `lib/data/datasources/firebase_product_datasource.dart` - Firebase data source
6. `lib/models/product_model.dart` - Data model
7. Updated `en_us.dart` and `hi_in.dart` with localization strings
8. All using AppTextField, AppButton, AppTheme from design system
9. All user-visible strings from AppLocalization

---

**Ready to generate! Just describe your screen or paste a design.**
