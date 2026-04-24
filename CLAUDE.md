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

## Contact & Questions

If unclear:
1. Check relevant documentation file
2. Look at existing implementation (e.g., UserModel, UserRepository)
3. Check QUICK_START.md for step-by-step guide
4. Review ARCHITECTURE_GUIDE.md for pattern explanation

---

**Last Updated:** April 2024  
**Maintained By:** Claude  
**Architecture Pattern:** Clean Architecture with Backend-Agnostic Layer
