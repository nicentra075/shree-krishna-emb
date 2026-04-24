# Shared Core Package Guide

## Overview

The **Shared Core Package** (`core/`) contains models, entities, errors, and utilities shared between both Admin and User apps. This monorepo structure allows:

- ✅ Single source of truth for models and errors
- ✅ Easy backend migrations (Firebase → Supabase → Node.js)
- ✅ One commit updates both apps
- ✅ Simple debugging and testing
- ✅ Zero package versioning overhead

---

## Project Structure

```
shree-krishna-emb/
├── core/                              ← SHARED PACKAGE
│   ├── lib/
│   │   ├── shree_krishna_core.dart   ← Barrel export (use this!)
│   │   ├── errors/
│   │   │   ├── exceptions.dart       ← Custom exceptions
│   │   │   └── failures.dart         ← Failure types
│   │   ├── models/
│   │   │   └── user_model.dart       ← Data models with Firebase & API conversions
│   │   ├── entities/
│   │   │   └── user_entity.dart      ← Pure business objects
│   │   └── utils/
│   │       └── either.dart           ← Either<Left, Right> type
│   └── pubspec.yaml
│
├── shree_krishna_emb_user_app/        ← USER APP
│   ├── lib/
│   │   ├── data/
│   │   │   ├── datasources/          ← Firebase/API implementations
│   │   │   └── repositories/         ← Repository implementations
│   │   ├── domain/
│   │   │   ├── repositories/         ← Abstract repository interfaces
│   │   │   └── usecases/             ← Business logic
│   │   ├── presentation/
│   │   │   ├── bloc/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── main.dart
│   └── pubspec.yaml                  ← Depends on ../core
│
└── shree_krishna_emb_admin/           ← ADMIN APP (same structure)
    ├── lib/
    │   ├── data/
    │   ├── domain/
    │   ├── presentation/
    │   └── main.dart
    └── pubspec.yaml                  ← Depends on ../core
```

---

## How to Use the Shared Core

### **1. Importing from Core**

In both apps, import from the shared core package:

```dart
// Instead of:
// import 'package:shree_krishna_emb/data/models/user_model.dart';
// import 'package:shree_krishna_emb/core/errors/failures.dart';

// Do this:
import 'package:shree_krishna_core/shree_krishna_core.dart';

// Now you can use:
// UserModel, UserEntity, Failure, Either, ServerException, etc.
```

### **2. In Repository Implementations**

```dart
// lib/data/repositories/user_repository_impl.dart
import 'package:shree_krishna_core/shree_krishna_core.dart';
import '../datasources/firebase_user_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDataSource _dataSource;

  UserRepositoryImpl({required UserDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, UserModel>> getUserById(String userId) async {
    try {
      final user = await _dataSource.getUserById(userId);
      return Right(user);  // From core package!
    } on ServerException catch (e) {  // From core package!
      return Left(ServerFailure(e.message));  // From core package!
    }
  }
}
```

### **3. In Data Sources**

```dart
// lib/data/datasources/firebase_user_datasource.dart
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class UserDataSource {
  Future<UserModel> getUserById(String userId);  // UserModel from core!
}

class FirebaseUserDataSource implements UserDataSource {
  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw ServerException(message: 'User not found');  // From core!
      }
      return UserModel.fromFirebaseJson(doc.data()!);  // From core!
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error');  // From core!
    }
  }
}
```

### **4. In BLoCs**

```dart
// lib/presentation/bloc/user_bloc.dart
import 'package:shree_krishna_core/shree_krishna_core.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase getUser;

  UserBloc(this.getUser) : super(UserInitial()) {
    on<GetUserEvent>((event, emit) async {
      emit(UserLoading());

      final result = await getUser(event.userId);

      result.fold(  // Either from core package!
        (failure) => emit(UserError(failure.message)),  // Failure from core!
        (user) => emit(UserLoaded(user)),  // UserModel from core!
      );
    });
  }
}
```

---

## Adding New Models

When you add a new model to the system:

### **Step 1: Create in `core/lib/models/`**

```dart
// core/lib/models/product_model.dart
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final double price;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
  });

  @override
  List<Object?> get props => [id, name, price];
}

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

  // API conversion (for future Supabase/Node.js)
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

### **Step 2: Export from barrel file**

```dart
// core/lib/shree_krishna_core.dart
export 'errors/exceptions.dart';
export 'errors/failures.dart';
export 'utils/either.dart';
export 'models/user_model.dart';
export 'models/product_model.dart';  // ← Add here
```

### **Step 3: Use in apps**

```dart
// In both user and admin apps:
import 'package:shree_krishna_core/shree_krishna_core.dart';

// ProductModel, ProductEntity are now available!
final product = ProductModel(...);
```

---

## Adding New Data Sources

### **In User App** (`shree_krishna_emb_user_app/lib/data/datasources/`)

```dart
// lib/data/datasources/firebase_product_datasource.dart
import 'package:shree_krishna_core/shree_krishna_core.dart';

abstract class ProductDataSource {
  Future<ProductModel> getProduct(String id);
}

class FirebaseProductDataSource implements ProductDataSource {
  @override
  Future<ProductModel> getProduct(String id) async {
    // Firebase implementation using ProductModel from core!
  }
}
```

### **For Future API Migration** (`when migrating to Node.js/Supabase`)

```dart
// lib/data/datasources/api_product_datasource.dart
import 'package:shree_krishna_core/shree_krishna_core.dart';

class ApiProductDataSource implements ProductDataSource {
  @override
  Future<ProductModel> getProduct(String id) async {
    final response = await _dio.get('/api/products/$id');
    return ProductModel.fromApiJson(response.data);  // Uses conversion from core!
  }
}
```

---

## Adding New API Endpoints

### **Pattern for Backend-Agnostic API Calls**

When adding a new API endpoint:

1. **Define in core package** - Create model with Firebase & API conversions
2. **Implement DataSource** - Firebase implementation in app
3. **Create Repository** - Handles error conversion
4. **Create UseCase** - Business logic
5. **Use in BLoC** - Presentation logic

**Example: Adding Orders endpoint**

```dart
// 1. Create model in core/lib/models/order_model.dart
class OrderModel extends OrderEntity {
  factory OrderModel.fromFirebaseJson(Map<String, dynamic> json) { ... }
  factory OrderModel.fromApiJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toFirebaseJson() { ... }
  Map<String, dynamic> toApiJson() { ... }
}

// 2. Create DataSource in user_app/lib/data/datasources/firebase_order_datasource.dart
abstract class OrderDataSource {
  Future<OrderModel> getOrder(String id);
}

class FirebaseOrderDataSource implements OrderDataSource {
  @override
  Future<OrderModel> getOrder(String id) async { ... }
}

// 3. Create Repository in user_app/lib/data/repositories/order_repository_impl.dart
class OrderRepositoryImpl implements OrderRepository {
  @override
  Future<Either<Failure, OrderModel>> getOrder(String id) async { ... }
}

// 4. Create UseCase in user_app/lib/domain/usecases/get_order_usecase.dart
class GetOrderUseCase {
  final OrderRepository repository;
  Future<Either<Failure, OrderModel>> call(String id) {
    return repository.getOrder(id);
  }
}

// 5. Use in BLoC
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final GetOrderUseCase getOrder;
  // ...
}
```

---

## Migrating Backend (Firebase → Supabase/Node.js)

The shared core makes migration **super easy**!

### **Migration Steps (2-5 days)**

1. **Data already prepared** ✅
   - Models have `.fromApiJson()` and `.toApiJson()` methods
   - Failures and error handling already in place

2. **Only change DataSource implementation**
   ```dart
   // In service_locator.dart:
   
   // Before (Firebase):
   getIt.registerSingleton<OrderDataSource>(
     FirebaseOrderDataSource(firestore: getIt()),
   );
   
   // After (Node.js/Supabase):
   getIt.registerSingleton<OrderDataSource>(
     ApiOrderDataSource(dio: getIt()),  // Same interface!
   );
   ```

3. **Repositories, UseCases, BLoCs - NO CHANGES** 🎉
   - They only depend on abstract interfaces
   - DataSource implementation is swapped behind the scenes

4. **UI/Presentation - NO CHANGES** 🎉
   - BLoCs still emit same states
   - Widgets still work identically

---

## Best Practices

### ✅ DO:
- ✅ Add all models to `core/lib/models/`
- ✅ Import from `package:shree_krishna_core/shree_krishna_core.dart`
- ✅ Keep models with both Firebase & API conversions
- ✅ Use Either type for error handling
- ✅ Share code between admin and user apps

### ❌ DON'T:
- ❌ Add app-specific code to core (core should be reusable)
- ❌ Import core files directly (use barrel export)
- ❌ Add Firebase imports to core
- ❌ Create app-specific models in core
- ❌ Mix presentation logic in core

---

## Running Tests

Both apps can test against the shared core:

```bash
# Run tests in core package
cd core
flutter test

# Run tests in user app (which uses core)
cd ../shree_krishna_emb_user_app
flutter test

# Run tests in admin app (which uses core)
cd ../shree_krishna_emb_admin
flutter test
```

---

## Getting Dependencies

When you first use the shared core:

```bash
# In user app
cd shree_krishna_emb_user_app
flutter pub get

# In admin app
cd shree_krishna_emb_admin
flutter pub get

# Or from root (works for both)
flutter pub get
```

---

## Common Issues & Solutions

### **Issue: "Package not found: shree_krishna_core"**
**Solution:** 
```bash
flutter pub get
# or
flutter clean && flutter pub get
```

### **Issue: Models appear in multiple places**
**Solution:** Import only from `core/`, delete from app directories

### **Issue: Can't see core package in IDE**
**Solution:** 
- Close and reopen IDE
- Run `flutter pub get`
- Invalidate IDE cache

### **Issue: Import conflicts between apps**
**Solution:** Always import from core:
```dart
// Not:
import 'package:shree_krishna_emb/models/user_model.dart';

// Do:
import 'package:shree_krishna_core/shree_krishna_core.dart';
```

---

## File Checklist

### **What's in core/ (shared)**
- ✅ Models (with Firebase & API conversions)
- ✅ Entities (pure business objects)
- ✅ Exceptions & Failures
- ✅ Either type (error handling)
- ✅ pubspec.yaml (dependencies shared by all)

### **What's in each app (NOT in core)**
- ✅ DataSources (Firebase implementation)
- ✅ Repositories (concrete implementations)
- ✅ UseCases
- ✅ BLoCs
- ✅ Screens & Widgets
- ✅ Service Locator (app-specific setup)

---

## Next Steps

1. ✅ Run `flutter pub get` in both apps
2. ✅ Update imports to use `package:shree_krishna_core`
3. ✅ When adding models, create in `core/lib/models/`
4. ✅ Export in `core/lib/shree_krishna_core.dart`
5. ✅ When migrating backend, only swap DataSource implementation

---

## Quick Reference

| Task | Location | Notes |
|------|----------|-------|
| Add Model | `core/lib/models/` | Needs Firebase & API conversion |
| Add Exception | `core/lib/errors/exceptions.dart` | For data layer errors |
| Add Failure | `core/lib/errors/failures.dart` | For domain layer errors |
| Add DataSource | `app/lib/data/datasources/` | App-specific (Firebase now, API later) |
| Add Repository | `app/lib/data/repositories/` | App-specific implementation |
| Add UseCase | `app/lib/domain/usecases/` | App-specific business logic |
| Add BLoC | `app/lib/presentation/bloc/` | App-specific presentation |

---

## Architecture Advantage

This setup enables seamless backend migration:

```
Firebase (Current)
    ↓
Update DataSource Implementation
    ↓
Everything else stays the same
    ↓
Supabase or Node.js (Future)
```

No need to change models, repositories, use cases, BLoCs, or UI! 🚀

---

**Last Updated:** April 2024
**Status:** Production Ready
**Migration Ready:** Yes
