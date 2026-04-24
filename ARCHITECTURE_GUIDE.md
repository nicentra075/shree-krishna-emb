# Migration-Ready Architecture Guide

## Overview

This guide explains the clean architecture pattern used in both the **Admin App** and **User App**. This architecture is designed to allow **easy migration from Firebase to Supabase or Node.js** later without changing your UI code.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│              (BLoCs, Screens, Widgets)                       │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────┴───────────────────────────────────────────┐
│                   DOMAIN LAYER                               │
│        (Entities, Repositories, Use Cases)                   │
│                (Backend Agnostic)                            │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────┴───────────────────────────────────────────┐
│                    DATA LAYER                                │
│         (Models, DataSources, Repositories)                  │
│        (Firebase, API, or future backends)                   │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────┴───────────────────────────────────────────┐
│              Backend Implementations                         │
│        Firebase | Supabase | Node.js API                    │
└──────────────────────────────────────────────────────────────┘
```

## Folder Structure

```
lib/
├── core/                          # Core functionality
│   ├── errors/
│   │   ├── exceptions.dart        # Custom exceptions
│   │   └── failures.dart          # Failure types
│   ├── utils/
│   │   └── either.dart            # Either type for error handling
│   └── di/
│       └── service_locator.dart   # Dependency injection setup
│
├── data/                          # Data layer
│   ├── datasources/
│   │   ├── firebase_user_datasource.dart    # Firebase implementation
│   │   └── api_user_datasource.dart         # API implementation (future)
│   ├── models/
│   │   └── user_model.dart        # Data models with conversions
│   └── repositories/
│       └── user_repository_impl.dart        # Repository implementation
│
├── domain/                        # Domain layer (backend agnostic)
│   ├── entities/                  # Pure Dart entities
│   ├── repositories/
│   │   └── user_repository.dart   # Abstract repository interface
│   └── usecases/
│       └── get_user_usecase.dart  # Business logic
│
├── presentation/                  # Presentation layer
│   ├── bloc/                      # State management
│   ├── screens/                   # UI screens
│   └── widgets/                   # Reusable widgets
│
└── main.dart                      # App entry point
```

## Data Flow Example: Get User

```
┌──────────────────┐
│   UI (Screen)    │  1. User taps button
└────────┬─────────┘
         │
         v
┌──────────────────┐
│   BLoC           │  2. Add event: GetUserEvent(userId)
└────────┬─────────┘
         │
         v
┌──────────────────┐
│   Use Case       │  3. Call: GetUserUseCase(userId)
│ GetUserUseCase   │
└────────┬─────────┘
         │
         v
┌──────────────────┐
│  Repository      │  4. Call: getUserById(userId)
│  (Abstract)      │     Returns Either<Failure, User>
└────────┬─────────┘
         │
         v
┌──────────────────┐
│  Data Source     │  5. Call: FirebaseUserDataSource.getUserById()
│  (Firebase)      │     OR: ApiUserDataSource.getUserById()
└────────┬─────────┘
         │
         v
┌──────────────────┐
│  Backend         │  6. Fetch data from Firebase/API
│ (Firebase/API)   │     Convert to UserModel
└──────────────────┘
```

## Key Concepts

### 1. **Entity** (Domain Layer)
- Pure Dart class, no external dependencies
- Represents business logic object
- Example: `UserEntity` with business properties

```dart
class UserEntity {
  final String id;
  final String email;
  final String name;
  // ... business properties
}
```

### 2. **Model** (Data Layer)
- Extends Entity
- Knows how to convert from/to different backends
- Handles serialization/deserialization

```dart
class UserModel extends UserEntity {
  // Convert from Firebase
  factory UserModel.fromFirebaseJson(Map<String, dynamic> json) { ... }
  
  // Convert to Firebase
  Map<String, dynamic> toFirebaseJson() { ... }
  
  // Convert from API
  factory UserModel.fromApiJson(Map<String, dynamic> json) { ... }
  
  // Convert to API
  Map<String, dynamic> toApiJson() { ... }
}
```

### 3. **Data Source** (Implementation)
- Handles actual backend communication
- Can be Firebase, API, local database, etc.
- Abstract interface ensures swappability

```dart
// Abstract interface
abstract class UserDataSource {
  Future<UserModel> getUserById(String userId);
  // ... other methods
}

// Firebase implementation
class FirebaseUserDataSource implements UserDataSource {
  @override
  Future<UserModel> getUserById(String userId) async {
    // Firebase logic
  }
}

// API implementation (for future migration)
class ApiUserDataSource implements UserDataSource {
  @override
  Future<UserModel> getUserById(String userId) async {
    // API logic
  }
}
```

### 4. **Repository** (Implementation)
- Bridges domain and data layers
- Handles error conversion (exceptions → failures)
- Returns `Either<Failure, Data>` for functional error handling

```dart
class UserRepositoryImpl implements UserRepository {
  final UserDataSource _dataSource;

  @override
  Future<Either<Failure, UserModel>> getUserById(String userId) async {
    try {
      final user = await _dataSource.getUserById(userId);
      return Right(user);  // Success
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));  // Error
    }
  }
}
```

### 5. **Either Type** (Functional Programming)
- Represents success or failure
- `Right<Data>` = success
- `Left<Failure>` = error

```dart
Either<Failure, UserModel> result = await getUserById('123');

result.fold(
  (failure) => print('Error: ${failure.message}'),  // Left case
  (user) => print('User: ${user.name}'),             // Right case
);
```

## Backend Switching

### Current: Firebase (MVP Phase)

**Service Locator Setup:**
```dart
void setupServiceLocator() {
  // Register Firebase datasources
  getIt.registerSingleton<UserDataSource>(
    FirebaseUserDataSource(firestore: getIt()),
  );
  
  // Register repository
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(dataSource: getIt()),
  );
}
```

**How to Use:**
```dart
// Anywhere in app
final repository = getIt<UserRepository>();
final result = await repository.getUserById('123');
```

### Future: Supabase or Node.js (Scale Phase)

**Only this changes:**
```dart
void setupServiceLocator() {
  // Register API datasources (no other changes!)
  getIt.registerSingleton<UserDataSource>(
    ApiUserDataSource(dio: getIt()),  // Same interface!
  );
  
  // Everything else stays the same
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(dataSource: getIt()),
  );
}
```

**All UI code remains unchanged!**

## Adding New Features

### Step 1: Create Entity
```dart
// lib/domain/entities/product.dart
class ProductEntity {
  final String id;
  final String name;
  final double price;
}
```

### Step 2: Create Model
```dart
// lib/data/models/product_model.dart
class ProductModel extends ProductEntity {
  factory ProductModel.fromFirebaseJson(Map<String, dynamic> json) { ... }
  factory ProductModel.fromApiJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toFirebaseJson() { ... }
  Map<String, dynamic> toApiJson() { ... }
}
```

### Step 3: Create Data Source
```dart
// lib/data/datasources/firebase_product_datasource.dart
class FirebaseProductDataSource implements ProductDataSource {
  Future<ProductModel> getProduct(String id) async { ... }
}
```

### Step 4: Create Repository
```dart
// lib/domain/repositories/product_repository.dart
abstract class ProductRepository {
  Future<Either<Failure, ProductModel>> getProduct(String id);
}

// lib/data/repositories/product_repository_impl.dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;
  @override
  Future<Either<Failure, ProductModel>> getProduct(String id) async { ... }
}
```

### Step 5: Create Use Cases
```dart
// lib/domain/usecases/get_product_usecase.dart
class GetProductUseCase {
  final ProductRepository repository;
  Future<Either<Failure, ProductModel>> call(String id) {
    return repository.getProduct(id);
  }
}
```

### Step 6: Use in BLoC/UI
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

## Error Handling

### Exception Types
- `ServerException` - Backend errors
- `NetworkException` - Network issues
- `AuthenticationException` - Auth failures
- `ValidationException` - Input validation
- `CacheException` - Cache issues

### Failure Types
- `ServerFailure` - Server returned error
- `NetworkFailure` - No internet/timeout
- `AuthenticationFailure` - Auth failed
- `ValidationFailure` - Validation failed
- `CacheFailure` - Cache error
- `UnknownFailure` - Unknown error

## Best Practices

✅ **DO:**
- Keep domain layer backend-agnostic
- Use Either for error handling
- Convert exceptions to failures in repository
- Use dependency injection (GetIt)
- Keep entities immutable
- Write tests for each layer

❌ **DON'T:**
- Expose Firebase/API classes outside data layer
- Use Firebase classes in BLoCs
- Mix exceptions and failures
- Create circular dependencies
- Tightly couple UI to backend

## Testing Strategy

```dart
// Test domain layer (no mocks needed - pure logic)
test('GetUserUseCase returns user', () async {
  // ...
});

// Test repositories (mock data source)
test('UserRepositoryImpl converts exceptions to failures', () async {
  final mockDataSource = MockUserDataSource();
  // ...
});

// Test BLoCs (mock repositories)
test('ProductBloc emits correct states', () async {
  final mockRepository = MockProductRepository();
  // ...
});
```

## Troubleshooting

**Q: "I need to add Firebase feature X"**
A: Add it in the DataSource layer only. Don't expose Firebase classes to domain/presentation.

**Q: "How do I handle real-time updates?"**
A: Use `Stream<Either<Failure, Data>>` in repository. See `watchUser` example.

**Q: "Can I skip the Either type?"**
A: You can use `try/catch`, but Either is cleaner and more functional.

**Q: "When should I migrate from Firebase?"**
A: When monthly Firebase costs exceed $100 or you need custom logic Firebase can't handle.

## Next Steps

1. Read [FIREBASE_BACKEND_GUIDE.md](FIREBASE_BACKEND_GUIDE.md) for Firebase setup
2. Read [MIGRATION_TO_SUPABASE.md](MIGRATION_TO_SUPABASE.md) for Supabase migration
3. Read [MIGRATION_TO_NODEJS.md](MIGRATION_TO_NODEJS.md) for Node.js migration
4. Check [FIREBASE_BEST_PRACTICES.md](FIREBASE_BEST_PRACTICES.md) for optimization tips
