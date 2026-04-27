# Shree Krishna Embroidery App - Development Guide for Claude

## Project Overview

**Apps:** Admin App (Flutter Web + Mobile) + User App (Shree Krishna EMB User App)  
**Backend:** Firebase (MVP), future migration to Supabase or Node.js  
**Architecture:** Clean Architecture with migration-ready pattern  
**State Management:** BLoC (flutter_bloc)  
**Budget:** Low-cost, scalable  

---

## Architecture Rules (CRITICAL)

### Rule 1: Three-Layer Separation
```
Presentation (UI)    → Never imports Firebase/API classes
    ↓
Domain (Business)    → Backend-agnostic, pure Dart
    ↓
Data (Backend)       → Firebase/Supabase/Node.js implementations
```

**Check:** `grep -r "firebase_core\|cloud_firestore\|firebase_auth" lib/presentation/`  
Should return NOTHING. If it does, refactor immediately.

### Rule 2: Models Must Support Multiple Backends

Every `Model` must have conversion methods for current AND future backends:

```dart
class UserModel extends UserEntity {
  // Current: Firebase
  factory UserModel.fromFirebaseJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toFirebaseJson() { ... }
  
  // Future: API/Supabase/Node.js
  factory UserModel.fromApiJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toApiJson() { ... }
}
```

**Why:** When migrating backends, only `lib/core/di/service_locator.dart` changes.

### Rule 3: Repository Interface = Contract

The abstract repository in `domain/repositories/` is the contract. Data layer must implement it. Presentation doesn't care about implementation.

```dart
// domain/repositories/user_repository.dart - NEVER CHANGES
abstract class UserRepository {
  Future<Either<Failure, UserModel>> getUserById(String userId);
}

// data/repositories/user_repository_impl.dart - Changes backend, not interface
class UserRepositoryImpl implements UserRepository { ... }
```

### Rule 4: Error Handling with Either Type

All repository methods return `Either<Failure, Data>`:

```dart
// ✅ Good
Future<Either<Failure, UserModel>> getUserById(String userId) async {
  try {
    final user = await _dataSource.getUserById(userId);
    return Right(user);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  }
}

// ❌ Bad
Future<UserModel> getUserById(String userId) async {
  return await _dataSource.getUserById(userId); // Throws on error
}
```

### Rule 5: Service Locator Controls Backend

Only `lib/core/di/service_locator.dart` knows which backend is active:

```dart
void setupServiceLocator() {
  // CHANGE THIS TO SWITCH BACKENDS
  getIt.registerSingleton<UserDataSource>(
    FirebaseUserDataSource(firestore: getIt()), // ← Change this line only
  );
  
  // Everything else stays the same
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(dataSource: getIt()),
  );
}
```

---

## When Adding a New Feature

Follow these 6 steps EXACTLY. This ensures future migration works.

### Step 1: Create Entity (Domain)
```dart
// lib/domain/entities/product.dart
class ProductEntity extends Equatable {
  final String id;
  final String name;
  final double price;
  
  const ProductEntity({required this.id, required this.name, required this.price});
  
  @override
  List<Object?> get props => [id, name, price];
}
```

### Step 2: Create Model (Data)
```dart
// lib/data/models/product_model.dart
class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
  });
  
  // Firebase conversion
  factory ProductModel.fromFirebaseJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toFirebaseJson() {
    return {'id': id, 'name': name, 'price': price};
  }
  
  // API conversion (for future migration)
  factory ProductModel.fromApiJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toApiJson() {
    return {'id': id, 'name': name, 'price': price};
  }
}
```

### Step 3: Create DataSource (Data Layer Implementation)
```dart
// lib/data/datasources/firebase_product_datasource.dart
abstract class ProductDataSource {
  Future<ProductModel> getProduct(String id);
  Future<List<ProductModel>> getAllProducts({int? limit});
  Future<ProductModel> createProduct(ProductModel product);
  Future<ProductModel> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
}

class FirebaseProductDataSource implements ProductDataSource {
  final FirebaseFirestore _firestore;
  
  FirebaseProductDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;
  
  @override
  Future<ProductModel> getProduct(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (!doc.exists) {
        throw ServerException(message: 'Product not found');
      }
      return ProductModel.fromFirebaseJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error');
    }
  }
  
  // ... implement other methods
}
```

### Step 4: Create Repository Interface (Domain)
```dart
// lib/domain/repositories/product_repository.dart
abstract class ProductRepository {
  Future<Either<Failure, ProductModel>> getProduct(String id);
  Future<Either<Failure, List<ProductModel>>> getAllProducts({int? limit});
  Future<Either<Failure, ProductModel>> createProduct(ProductModel product);
  Future<Either<Failure, ProductModel>> updateProduct(ProductModel product);
  Future<Either<Failure, void>> deleteProduct(String id);
}
```

### Step 5: Create Repository Implementation (Data)
```dart
// lib/data/repositories/product_repository_impl.dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;
  
  ProductRepositoryImpl({required ProductDataSource dataSource})
      : _dataSource = dataSource;
  
  @override
  Future<Either<Failure, ProductModel>> getProduct(String id) async {
    try {
      final product = await _dataSource.getProduct(id);
      return Right(product);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
  
  // ... implement other methods
}
```

### Step 6: Create Use Cases & Register in Service Locator
```dart
// lib/domain/usecases/get_product_usecase.dart
class GetProductUseCase {
  final ProductRepository repository;
  
  GetProductUseCase(this.repository);
  
  Future<Either<Failure, ProductModel>> call(String productId) {
    return repository.getProduct(productId);
  }
}

// lib/core/di/service_locator.dart
void setupServiceLocator() {
  // ... existing code ...
  
  // Data sources
  getIt.registerSingleton<ProductDataSource>(
    FirebaseProductDataSource(firestore: getIt()),
  );
  
  // Repositories
  getIt.registerSingleton<ProductRepository>(
    ProductRepositoryImpl(dataSource: getIt()),
  );
  
  // Use cases
  getIt.registerSingleton<GetProductUseCase>(
    GetProductUseCase(getIt()),
  );
}
```

### Step 7: Use in BLoC (Presentation)
```dart
// lib/presentation/bloc/product_bloc.dart
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductUseCase getProduct;
  
  ProductBloc(this.getProduct) : super(ProductInitial()) {
    on<GetProductEvent>((event, emit) async {
      emit(ProductLoading());
      
      final result = await getProduct(event.productId);
      
      result.fold(
        (failure) => emit(ProductError(failure.message)),
        (product) => emit(ProductLoaded(product)),
      );
    });
  }
}
```

---

## Firestore Collections Structure

Define collections here when creating them:

```
users/
├── {userId}
│   ├── email: string
│   ├── name: string
│   ├── photoUrl: string
│   ├── createdAt: timestamp
│   ├── isActive: boolean

products/
├── {productId}
│   ├── name: string
│   ├── price: number
│   ├── description: string
│   ├── imageUrl: string
│   ├── createdAt: timestamp

// Add more collections and document structure here
```

**Update this when adding new collections.**

---

## Firebase Security Rules

Current rules are in [FIREBASE_BACKEND_GUIDE.md](FIREBASE_BACKEND_GUIDE.md)

Update rules in Firebase Console when:
- Adding new collections
- Changing access patterns
- Implementing new auth features

Test rules in Firebase Emulator before deploying.

---

## Project Structure for Both Apps

Both **Admin App** and **User App** should have identical folder structure:

```
lib/
├── core/
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── utils/
│   │   └── either.dart
│   └── di/
│       └── service_locator.dart
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── bloc/
│   ├── screens/
│   └── widgets/
└── main.dart
```

Only differences:
- BLoCs specific to each app's features
- Screens and widgets specific to each app's UI

Data layer should be shared or identical.

---

## Dependencies Management

### Core Dependencies (Keep Updated)
- `firebase_core: ^4.7.0`
- `cloud_firestore: ^6.3.0`
- `firebase_auth: ^4.14.0`
- `flutter_bloc: ^8.1.4`
- `get_it: ^7.6.0`
- `equatable: ^2.0.5`

### Never Add
- ❌ Duplicate packages for same functionality
- ❌ Outdated packages
- ❌ Packages with known security issues
- ❌ Too many analytics/tracking packages (costs & privacy)

### When Adding Package
Check:
- [ ] Not already in pubspec.yaml
- [ ] Actively maintained (recent commits)
- [ ] No security vulnerabilities
- [ ] Supports all platforms (mobile, web)
- [ ] Good alternative exists? (avoid bloat)

---

## Naming Conventions

### Files
- Entities: `user_entity.dart`
- Models: `user_model.dart`
- DataSources: `firebase_user_datasource.dart`, `api_user_datasource.dart`
- Repositories: `user_repository.dart`, `user_repository_impl.dart`
- UseCases: `get_user_usecase.dart`, `create_user_usecase.dart`
- BLoCs: `user_bloc.dart`, `user_event.dart`, `user_state.dart`
- Screens: `user_screen.dart`
- Widgets: `user_card_widget.dart` or `user_card.dart`

### Classes
- Entities: `UserEntity`
- Models: `UserModel`
- DataSources: `FirebaseUserDataSource`, `ApiUserDataSource`
- Repositories: `UserRepository`, `UserRepositoryImpl`
- UseCases: `GetUserUseCase`, `CreateUserUseCase`
- BLoCs: `UserBloc`
- Events: `GetUserEvent`, `CreateUserEvent`
- States: `UserInitial`, `UserLoading`, `UserLoaded`, `UserError`

### Variables
- Private: `_privateVariable`
- Constants: `CONSTANT_VALUE` or `kConstantValue`

---

## Code Quality Checklist

Before committing:

- [ ] No Firebase imports in `lib/presentation/`
- [ ] All models have Firebase & API conversion methods
- [ ] Error handling uses Either type
- [ ] Repository implements abstract interface
- [ ] All streams are cancelled in BLoC.close()
- [ ] No hardcoded strings (use constants)
- [ ] Documentation for public methods
- [ ] Follows naming conventions above
- [ ] No commented-out code
- [ ] No debug prints (use logging)
- [ ] Formatted: `dart format lib/`
- [ ] No analysis issues: `flutter analyze`

---

## Testing Strategy

### Unit Tests (Data & Domain)
```dart
test('UserRepositoryImpl converts exceptions to failures', () async {
  final mockDataSource = MockUserDataSource();
  when(mockDataSource.getUserById(any))
      .thenThrow(ServerException(message: 'Error'));
  
  final repo = UserRepositoryImpl(dataSource: mockDataSource);
  final result = await repo.getUserById('123');
  
  expect(result, isA<Left>());
});
```

### Integration Tests (With Emulator)
```bash
firebase emulators:start
flutter test --dart-define=USE_FIRESTORE_EMULATOR=true
```

### Widget Tests (UI)
```dart
testWidgets('UserCard displays user name', (WidgetTester tester) async {
  await tester.pumpWidget(const UserCard(user: testUser));
  expect(find.text('John Doe'), findsOneWidget);
});
```

**Never test Firebase directly.** Test the DataSource interface instead.

---

## Migration Path

### When to Migrate (Cost Triggers)
- Firebase monthly cost > $150
- Need PostgreSQL features
- Need custom backend logic
- Want to self-host

### Migration Steps
1. Read [MIGRATION_TO_NODEJS.md](MIGRATION_TO_NODEJS.md) or [MIGRATION_TO_SUPABASE.md](MIGRATION_TO_SUPABASE.md)
2. Only `lib/core/di/service_locator.dart` needs significant changes
3. `lib/data/models/user_model.dart` already has API conversion methods
4. `lib/data/datasources/api_user_datasource.dart` template provided
5. No BLoC/Presentation code changes needed

---

## Documentation Files

- **[QUICK_START.md](QUICK_START.md)** - Start here, 30-minute setup
- **[ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md)** - Deep dive into pattern
- **[FIREBASE_BACKEND_GUIDE.md](FIREBASE_BACKEND_GUIDE.md)** - Firebase operations
- **[FIREBASE_BEST_PRACTICES.md](FIREBASE_BEST_PRACTICES.md)** - Optimization, security
- **[MIGRATION_TO_NODEJS.md](MIGRATION_TO_NODEJS.md)** - Custom backend
- **[MIGRATION_TO_SUPABASE.md](MIGRATION_TO_SUPABASE.md)** - Supabase migration

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Firebase not initialized | Call `Firebase.initializeApp()` in `main()` before `setupServiceLocator()` |
| Service locator errors | Check `getIt.registerSingleton()` order - no circular dependencies |
| Memory leaks from streams | Always cancel subscriptions in `BLoC.close()` |
| High Firebase costs | Read [FIREBASE_BEST_PRACTICES.md](FIREBASE_BEST_PRACTICES.md) section 1 |
| Firebase rules denying access | Test with Firebase Emulator, check rules in console |
| Model conversion errors | Check field names match Firestore exactly |
| BLoC state not updating | Make sure BLoCs extend `Bloc<Event, State>` and emit states |
| API call failures | Check error handling, use `Either<Failure, Data>` pattern |

---

## Git Workflow

### Branch Naming
- Feature: `feature/user-authentication`
- Bug fix: `fix/firebase-initialization`
- Refactor: `refactor/repository-pattern`

### Commit Messages
```
feature: add user authentication with Firebase
fix: handle Firebase offline errors properly
docs: update QUICK_START guide
refactor: clean up service locator setup
```

### Before Pushing
```bash
# Format
dart format lib/

# Analyze
flutter analyze

# Test
flutter test

# Build
flutter build apk/ios/web (depending on platform)
```

---

## When Claude Adds Features

When asking Claude to add features:

1. **Provide context:** What feature? What's the data model?
2. **Check architecture:** Is migration-ready pattern followed?
3. **Verify conversions:** Do models have Firebase & API conversion methods?
4. **Test:** Does it work? Are errors handled?
5. **Security:** Are Firestore rules updated?
6. **Performance:** Any N+1 queries or memory leaks?

---

## Useful Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Run tests
flutter test

# Format code
dart format lib/

# Analyze code
flutter analyze

# Build for production
flutter build apk
flutter build ios
flutter build web

# Clean
flutter clean

# Get Firebase setup
flutterfire configure

# Generate code (if using build_runner)
dart run build_runner build
```

---

## Claude Code Skills

Available skills for this project:

### `/design-system-skill`
**Purpose:** Generate complete, production-ready screens that always follow your design system, include proper localization, BLoC state management, and integrate with your clean architecture.

**Use when:** 
- "Create a new screen for user profile"
- "Generate a login screen"
- "Build a product listing page"
- "I have a Stitch design, convert it to code"
- "Create the screen that I have selected in Figma or Stitch"
- "Create this UI or screen that I have pasted"

**What it does:**
1. Asks which app (Admin or User)
2. Accepts text description or Stitch/Figma design details
3. Generates complete screen code with:
   - Design system components (AppTextField, AppButton, AppTheme, etc.)
   - Dark & light mode support
   - BLoC state management
   - Localization for all user-visible strings (en_US, hi_IN)
   - Clean architecture integration (screens, BLoCs, models, repositories if needed)
   - Firestore integration (if applicable)
   - Beautiful animations and UI polish

**Output:** Complete file structure ready to use:
- `lib/screens/[category]/[screen_name]_screen.dart`
- `lib/bloc/[feature]/` (BLoC files if needed)
- `lib/domain/repositories/` and `lib/data/` layers (if data needed)
- Updated localization files (en_us.dart, hi_in.dart)

**Guardrails:**
- All user-visible strings are localized (with `// TODO: Add localisation` if pending)
- All UI uses design system components
- Asks about custom widgets and backend needs
- Delegates backend work to existing skills if applicable
- No scope limits on animation/polish complexity

### `/backend-skill`
**Purpose:** Generate complete Firebase backend integration with caching, offline mode, security rules, data models, repositories, and seamless UI integration through BLoCs.

**Use when:**
- "Setup Firestore collection for products"
- "Create user authentication with Firebase"
- "Generate API datasource for product listing"
- "Set up Firestore security rules for users"
- "Create the backend for this data model"
- "I need to store products with filtering and pagination"
- "Can you add the backend support as well for this screen"
- "Can you update that in the backend code"
- "Update the backend as well"

**What it does:**
1. Asks what data needs CRUD operations
2. Recommends caching/offline mode based on use case
3. Reads existing code to understand patterns
4. Generates complete backend with:
   - Firestore collection structure
   - Security rules (for user review)
   - Entities and Models (dual serialization: Firebase + API)
   - DataSources (Firebase + optional Cached wrapper)
   - Repositories (with Either<Failure, Data> error handling)
   - Use cases (if complex logic needed)
   - Service locator registrations
   - **Caching** (Hive, SharedPreferences, or BLoC-level)
   - **Offline mode** (mutation queuing, sync when online)
   - BLoC integration with offline detection
5. Warns about N+1 queries, costs, inefficiencies

**Output:** Complete backend files:
- `lib/domain/entities/[feature].dart`
- `lib/data/models/[feature]_model.dart`
- `lib/data/datasources/firebase_[feature]_datasource.dart`
- `lib/data/datasources/cached_[feature]_datasource.dart` (if caching)
- `lib/domain/repositories/[feature]_repository.dart`
- `lib/data/repositories/[feature]_repository_impl.dart`
- `firestore_rules_[feature].js` (awaiting user review)
- Updated `lib/core/di/service_locator.dart`
- Updated BLoC with offline sync support
- Updated screen with offline UI indicators

**Caching & Offline:**
- Automatically recommends caching for lists, profiles, frequently accessed data
- Automatically recommends offline mode for critical features, forms
- Queues mutations (create/update/delete) when offline
- Syncs automatically when online
- Shows offline indicator to user
- Cache-ready for future backend migration (dual serialization)

**Guardrails:**
- Never violates clean architecture (enforces layers)
- Asks for clarification on data conflicts OR auto-resolves safely
- Asks user to review security rules before creating
- Never deploys directly (user must review and confirm)
- Warns about cost inefficiencies and N+1 queries
- Migration-ready (models support Firebase + API serialization)

### `/auth-skill`
**Purpose:** Generate complete email/OTP authentication, social login (Google/Apple), role selection, and token management.

**Use when:**
- "Set up authentication for the app"
- "Add Google and Apple login"
- "Implement OTP-based signup"
- "Create role selection after signup"

**What it does:**
1. Generates Firebase Auth setup
2. Email/OTP flow (SendOTP → VerifyOTP → Role Selection)
3. Google/Apple social login integration
4. Secure token storage (flutter_secure_storage)
5. Rate limiting on OTP requests
6. BLoC with logout and session management

**Output:** Auth screens, BLoCs, Firebase Cloud Functions for OTP

### `/payment-skill`
**Purpose:** Generate complete payment integration (Razorpay + PhonePe), order management, and refund workflows.

**Use when:**
- "Set up payment processing"
- "Create checkout flow"
- "Add Razorpay integration"
- "Generate payment history screen"

**What it does:**
1. Cart & Checkout BLoCs
2. Razorpay/PhonePe integration
3. Payment verification via Cloud Functions
4. Refund workflow
5. Payment history with filtering
6. 12% platform fee + 18% GST calculation

**Output:** Payment screens, BLoCs, Cloud Functions for verification

### `/search-filter-skill`
**Purpose:** Generate full-text search, advanced filters, autocomplete, and sorting with Firestore optimization.

**Use when:**
- "Add search to the marketplace"
- "Create filters for designs (price, category, rating)"
- "Build autocomplete search suggestions"
- "Add sorting by price, popularity, rating"

**What it does:**
1. Full-text search on design titles/descriptions
2. Filters (price range, category, rating, technique)
3. Autocomplete suggestions
4. Sorting (newest, popular, price asc/desc, rating)
5. Firestore composite indexes required
6. Pagination with virtual scrolling

**Output:** Search screens, Search BLoC, filter dialogs

### `/image-processing-skill`
**Purpose:** Generate image upload, watermarking, compression, and pinch-to-zoom preview viewer.

**Use when:**
- "Add design image upload"
- "Create image preview viewer"
- "Implement watermarking for preview images"
- "Build high-res gallery for purchased designs"

**What it does:**
1. Firebase Storage upload with progress tracking
2. Automatic watermarking (semi-transparent overlay)
3. Image compression (preview 500px 80%, thumbnail 200px)
4. Pinch-to-zoom viewer (photo_view)
5. CachedNetworkImage for local caching
6. Lazy loading in galleries

**Output:** Image upload screens, viewers, compression utilities

### `/analytics-skill`
**Purpose:** Generate admin KPI dashboard, revenue charts, user metrics, and CSV/Excel export.

**Use when:**
- "Create admin dashboard with metrics"
- "Add revenue trend charts"
- "Generate user acquisition reports"
- "Add designer performance metrics"
- "Export analytics data"

**What it does:**
1. KPI cards (users, transactions, revenue, pending approvals)
2. Revenue trend charts (daily, weekly, monthly)
3. User acquisition analytics
4. Top designs and designer rankings
5. Real-time updates via Firestore snapshots
6. CSV/Excel export with date filtering

**Output:** Analytics BLoCs, dashboard screens, export utilities

### `/chat-skill`
**Purpose:** Generate real-time messaging, typing indicators, online status, and message read receipts.

**Use when:**
- "Add messaging between users and designers"
- "Create chat list and chat detail screens"
- "Implement typing indicators"
- "Add online/offline status"
- "Enable file sharing in chat"

**What it does:**
1. Real-time Firestore message listeners
2. Typing indicators with 5-second auto-removal
3. Online/offline status tracking
4. Message read receipts
5. File sharing to Firebase Storage
6. Message search and pagination
7. Block users functionality

**Output:** Chat screens, Chat BLoC, Firestore structure

### `/wallet-payout-skill`
**Purpose:** Generate designer wallet system with earnings tracking, payout requests, bank verification, and Razorpay Payouts.

**Use when:**
- "Create designer wallet/earnings system"
- "Add payout request workflow"
- "Implement bank account verification"
- "Set up admin payout approval"
- "Track designer earnings and transactions"

**What it does:**
1. DesignerWallet with balance tracking
2. Earnings from design sales, job completion, referrals
3. Payout request workflow (pending→approved→processing→completed)
4. Bank account micro-deposit verification
5. Minimum payout threshold (₹100 default)
6. Razorpay Payouts integration via Cloud Functions
7. Transaction history with filtering

**Output:** Wallet screens, Payout BLoCs, Cloud Functions

### `/rating-review-skill`
**Purpose:** Generate star ratings (1-5), verified reviews, admin moderation, and designer badges.

**Use when:**
- "Add review and rating system"
- "Create design ratings from users"
- "Set up admin review moderation"
- "Add verified designer badges"
- "Track designer ratings and reviews"

**What it does:**
1. Star rating (1-5) with text reviews
2. Firestore trigger for approval workflow
3. Admin moderation queue
4. Rejection reason templates
5. Helpful votes on reviews
6. Verification badge for 5+ reviews with 4.5+ rating
7. Designer metrics (average rating, total reviews, distribution)

**Output:** Review screens, Moderation BLoCs, admin queue

### `/approval-workflow-skill`
**Purpose:** Generate designer verification, design approval queue, and admin moderation workflows.

**Use when:**
- "Set up designer onboarding/verification"
- "Create design approval queue for admins"
- "Generate moderation interface"
- "Implement bulk approval actions"

**What it does:**
1. **Designer Verification:** Portfolio, ID proof submission → Admin review → Approve/Reject
2. **Design Approval:** Designer upload → Admin queue → Approve for listing/Reject
3. Rejection reasons and templates
4. Bulk actions for admin
5. Audit trail of all approvals
6. Verification badge for approved designers

**Output:** Approval screens, Admin queues, BLoCs, Cloud Functions

### `/notification-skill`
**Purpose:** Generate push notifications, in-app notification center, email notifications, and user preferences.

**Use when:**
- "Add push notifications to the app"
- "Create notification preference settings"
- "Set up in-app notification center"
- "Send notifications for orders, payouts, messages"

**What it does:**
1. Firebase Cloud Messaging (FCM) push notifications
2. In-app notification center with history
3. Notification types: new bid, job awarded, milestone, message, review, approval, payout
4. User preferences (quiet hours, disable categories)
5. Firebase Cloud Functions for event triggers
6. Email notifications (Phase 3+)

**Output:** Notification center screens, preferences BLoC, Cloud Functions

### `/responsive-ui-skill`
**Purpose:** Generate responsive layouts for mobile (< 768px), tablet (768-1199px), and desktop (1200px+) with adaptive navigation.

**Use when:**
- "Make this screen responsive for web"
- "Build a layout that works on mobile and desktop"
- "Create adaptive navigation (drawer to sidebar)"
- "Ensure the admin app works on all screen sizes"

**What it does:**
1. Mobile-first responsive design
2. Tablet & desktop adaptations
3. Responsive navigation (drawer ↔ sidebar)
4. Touch vs mouse/keyboard input handling
5. Orientation awareness
6. Adaptive dialogs & bottom sheets
7. Responsive grid layouts
8. Safe area handling

**Output:** Responsive screens, breakpoint utilities, navigation components

### `/testing-skill`
**Purpose:** Generate unit tests, widget tests, BLoC tests, integration tests with Firebase Emulator, and test coverage.

**Use when:**
- "Write unit tests for repositories"
- "Add widget tests for screens"
- "Test BLoC state transitions"
- "Set up Firebase Emulator testing"
- "Generate test fixtures and mocks"

**What it does:**
1. Unit tests (repositories, use cases)
2. Widget tests (screens, components)
3. BLoC tests with bloc_test
4. Integration tests with fake Firestore
5. Mock providers and fixtures
6. Firebase Emulator setup
7. CI/CD test execution with coverage

**Output:** Test files, fixtures, mock providers, GitHub Actions workflows

### `/deployment-skill`
**Purpose:** Generate build and deployment pipeline for Android (Play Store), iOS (App Store), and web (Firebase Hosting).

**Use when:**
- "Build app for production"
- "Set up App Store and Play Store uploads"
- "Create CI/CD pipeline for releases"
- "Deploy web admin app"
- "Set up automated testing before deployment"

**What it does:**
1. Android signing (keystore setup)
2. iOS signing (certificates, provisioning profiles)
3. APK/AAB builds for Play Store
4. IPA builds for App Store
5. Web builds for Firebase Hosting
6. GitHub Actions CI/CD workflows
7. Store upload automation
8. Version management and release notes

**Output:** Build scripts, GitHub Actions workflows, deployment guides

### `/security-skill`
**Purpose:** Generate Firestore security rules, input validation, encryption, API key management, and OWASP protection.

**Use when:**
- "Set up Firestore security rules"
- "Add input validation"
- "Implement data encryption"
- "Secure API key storage"
- "Audit security vulnerabilities"

**What it does:**
1. Firestore security rules (role-based, document-level)
2. Input validation & sanitization
3. Secure token storage (flutter_secure_storage)
4. Data encryption (AES for sensitive fields)
5. API key management (environment variables)
6. Rate limiting (prevent abuse)
7. OWASP top 10 protection
8. Privacy compliance (GDPR, data deletion)

**Output:** Security rules, validation utilities, encryption helpers, security checklist

### `/performance-optimization-skill`
**Purpose:** Generate BLoC caching, Firestore query optimization, lazy loading, virtual scrolling, memory fixes, and profiling.

**Use when:**
- "Optimize list performance"
- "Reduce Firestore costs"
- "Fix memory leaks"
- "Reduce app bundle size"
- "Profile and improve app speed"

**What it does:**
1. BLoC caching (avoid redundant API calls)
2. Persistent caching with Hive
3. Firestore query optimization (indexes, limits, pagination)
4. Lazy loading & pagination for large lists
5. Virtual scrolling (only render visible items)
6. Image optimization & caching
7. Memory leak detection and fixes
8. Bundle size reduction
9. Firebase Performance Monitoring setup
10. DevTools profiling guidance

**Output:** Caching utilities, optimized repositories, performance monitoring

---

## Localization Rules (CRITICAL)

**NO hardcoded strings in UI. ALL user-visible text must come from `AppLocalization.strings`.**

The app supports multiple languages (en_US, hi_IN). Every visible string must be localized.

### Rule: Use AppLocalization for ALL User-Visible Text

❌ **Bad** - Hardcoded:
```dart
Text('Full Name'),
TextField(
  decoration: InputDecoration(hintText: 'John Doe'),
)
```

✅ **Good** - Localized:
```dart
Text(AppLocalization.strings.fullName),
AppTextField(
  label: AppLocalization.strings.fullName,
  hint: AppLocalization.strings.fullNameHint,
)
```

### Adding New Strings

1. Add getter to `LocaleStrings` abstract class in `lib/localisations/locales/locale_base.dart`:
```dart
String get fullName;
String get emailAddress;
```

2. Implement in `lib/localisations/locales/en_us.dart`:
```dart
@override
String get fullName => 'Full Name';
@override
String get emailAddress => 'Email Address';
```

3. Implement in `lib/localisations/locales/hi_in.dart`:
```dart
@override
String get fullName => 'पूरा नाम';
@override
String get emailAddress => 'ईमेल पता';
```

4. Use in screens:
```dart
AppTextField(
  label: AppLocalization.strings.fullName,
)
```

### Common Strings Already Available
- `strings.appName`
- `strings.confirm`, `strings.cancel`, `strings.ok`
- `strings.done`, `strings.save`, `strings.edit`
- `strings.loading`, `strings.error`, `strings.success`

### Localization Validation Checklist

- [ ] No hardcoded strings in `Text()` widgets
- [ ] All labels use `AppLocalization.strings`
- [ ] All hints use `AppLocalization.strings`
- [ ] All button text use `AppLocalization.strings`
- [ ] All error messages use `AppLocalization.strings`
- [ ] New strings added to both en_us.dart and hi_in.dart

---

## Design System Usage Rules (CRITICAL)

**ALL UI components MUST use design system components from `shree_krishna_design_system` package.**

### Core Rule: Never Build Custom UI When Design System Component Exists

❌ **Bad** - Custom TextField:
```dart
TextField(
  controller: controller,
  decoration: InputDecoration(...),
)
```

✅ **Good** - Design System Component:
```dart
AppTextField(
  controller: controller,
  hint: 'Enter email',
)
```

### Common Design System Components

#### AppAppBar (for all navigation headers)
**REQUIRED for every screen with navigation. Replaces Flutter's default AppBar.**

Properties:
- `title` (String, required) - Header title text
- `onBack` (VoidCallback?) - Callback for back button (auto-shows if provided)
- `subtitle` (String?) - Optional subtitle below title
- `leading` (Widget?) - Custom leading widget (overrides auto back button)
- `actions` (List<Widget>?) - Action buttons on the right (search, menu, etc.)
- `centerTitle` (bool) - Center the title (default: false)
- `backgroundColor` (Color?) - Custom background color (default: theme)
- `showBottomBorder` (bool) - Show bottom divider (default: true)

```dart
// Simple screen with title and back button
Scaffold(
  appBar: AppAppBar(
    title: 'Products',
    onBack: () => Navigator.pop(context),
  ),
  body: // ...
)

// Screen with subtitle and actions
Scaffold(
  appBar: AppAppBar(
    title: 'Orders',
    subtitle: '5 active',
    onBack: () => Navigator.pop(context),
    actions: [
      IconButton(icon: Icon(Icons.search), onPressed: () {}),
      IconButton(icon: Icon(Icons.filter_list), onPressed: () {}),
    ],
  ),
  body: // ...
)

// Screen with custom background
Scaffold(
  appBar: AppAppBar(
    title: 'Special Screen',
    backgroundColor: Colors.blue.shade100,
    onBack: () => Navigator.pop(context),
  ),
  body: // ...
)
```

#### AppTextField (for all text inputs)
Required parameters: controller, label, hint
Optional: validator, keyboardType, obscureText, prefixIcon, suffixIcon

```dart
// Email field
AppTextField(
  label: 'Email Address',
  hint: 'you@example.com',
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icon(Icons.mail_outline),
)

// Password field with visibility toggle
AppTextField(
  label: 'Password',
  hint: 'Enter password',
  controller: _passwordController,
  obscureText: _obscurePassword,
  prefixIcon: Icon(Icons.lock_outline),
  suffixIcon: GestureDetector(
    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
    child: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
  ),
)

// Phone field
AppTextField(
  label: 'Phone Number',
  hint: '+91 98765 43210',
  controller: _phoneController,
  keyboardType: TextInputType.phone,
  prefixIcon: Icon(Icons.phone_outlined),
)
```

#### Other Components (when available)
- `AppButton` - for buttons
- `AppSnackbar.show()` - for notifications (NOT ScaffoldMessenger)
- `AppDialog` - for dialogs
- `AppLoader` - for loading spinners
- `AppShimmer` - for skeleton loading
- `AppEmptyState` - for empty/no data states
- `AppConnectivityBanner` - for offline/online status

### Design System Validation Checklist

When adding/updating any UI screen, validate:

- [ ] **Use AppAppBar for all navigation** - Replace all `AppBar(...)` with `AppAppBar(title: '...', onBack: ...)`
  - AppAppBar provides consistent styling, dark mode, built-in back button, localization support
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

### When Claude Updates Screens

Before submitting code:

1. Search for `AppBar(` - should be ZERO results (use AppAppBar instead)
2. Search for `TextField(` - should be ZERO results (use AppTextField)
3. Search for `ScaffoldMessenger` - should be ZERO results (use AppSnackbar)
4. Verify imports use the hide pattern above
5. Check that all AppAppBar instances have proper localization (no hardcoded titles)
6. Verify all text inputs follow the AppTextField pattern

---

## Contact & Questions

If unclear:
1. Check DESIGN_SYSTEM_GUIDE.md for component usage
2. Look at existing screens (login_screen.dart, signup_screen.dart)
3. Check relevant documentation file
4. Review ARCHITECTURE_GUIDE.md for patterns

---

**Last Updated:** April 2026  
**Maintained By:** Claude  
**Architecture Pattern:** Clean Architecture with Backend-Agnostic Layer  
**UI Pattern:** Design System Component-Driven Approach
