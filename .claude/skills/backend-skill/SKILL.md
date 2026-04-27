---
name: backend-skill
description: Use when someone asks to setup Firestore collections, create user authentication, generate API datasources, set up security rules, create backend for a data model, add backend support to a screen, or update backend code.
argument-hint: [data model description or screen reference]
disable-model-invocation: true
---

## What This Skill Does

Generates complete Firebase backend integration (with migration path to Supabase/Node.js) for CRUD operations, handles data models, security rules, caching strategies, offline mode, and seamlessly connects UI with backend through BLoCs.

The skill handles:
- ✅ Firestore collection structure and queries
- ✅ Security rules generation (user reviews first)
- ✅ Entity/Model with dual serialization (Firebase + API ready)
- ✅ DataSource implementation (Firebase, future: API, Supabase)
- ✅ Repository pattern implementation
- ✅ Use case creation if needed
- ✅ Service locator registration
- ✅ **Caching strategies** (BLoC/state, Hive, SharedPreferences)
- ✅ **Offline mode support** (queued mutations, sync when online)
- ✅ **Offline detection** with UI indicators
- ✅ BLoC integration with UI
- ✅ Error handling (Either<Failure, Data>)
- ✅ Cost optimization warnings
- ✅ Pagination, filtering, real-time updates support

## Step-by-Step Workflow

### Step 1: Understand Requirements
1. Ask user to describe what data needs backend support:
   - What is the data model? (user profile, product, order, etc.)
   - What operations? (Create, Read, Update, Delete, List, Search, Filter, Paginate)
   - Real-time updates needed?
   - File uploads needed?
   - Complex queries or relationships?

2. **Ask about Offline & Caching Needs:**
   - Will users access this data offline?
   - Should data be cached locally for faster loads?
   - Should mutations be queued if offline and synced when online?
   - How critical is this feature? (Should it work offline?)

   **Recommendations:**
   - ✅ **Cache if:** Lists, profiles, frequently accessed data, slow network
   - ✅ **Offline mode if:** Forms, critical operations (orders, payments), users have poor connectivity
   - ❌ **Don't cache if:** Real-time sensitive data, payment info, or rarely accessed

3. Ask scope:
   - **Shared backend** (core folder, used by both Admin & User apps)?
   - **App-specific backend** (only for User App or Admin App)?

4. Ask about integration:
   - Is this for a new screen (created by design-system-skill)?
   - Updating existing functionality?
   - Standalone backend feature?

### Step 2: Ask Backend Target
```
Current: Firebase (Firestore + Auth + Storage)
Future: Supabase? Node.js API? (Ask when adding new backends)
```

For now, assume Firebase unless user specifies otherwise. When user adds other backends, ask which backend to use.

### Step 3: Decide Caching & Offline Strategy

Based on requirements, decide:

**Option A: No Caching**
- Simple queries, real-time critical data
- Users always online
- Example: Admin dashboard, real-time notifications

**Option B: BLoC/State Caching**
- Cache in memory during app session
- Lightweight, no external dependencies
- Best for: Lists, profiles, medium-complexity data
- Persists only during app session

**Option C: Persistent Caching (Hive or SharedPreferences)**
- Cache survives app restart
- Good for: User profiles, preferences, large lists
- Hive: Structured data, better performance
- SharedPreferences: Simple key-value data

**Option D: Full Offline Mode**
- Cache all data locally
- Queue mutations (create/update/delete) when offline
- Sync when online
- Show offline indicator
- Best for: Critical features, poor network areas
- Example: Order placement, user forms

**Option E: Hybrid (Cache + Offline)**
- Combine persistent caching with queued mutations
- Best for: E-commerce, forms, critical operations

### Step 4: Read Existing Project Code

Read and analyze:

**Service Locator:**
- `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/core/di/service_locator.dart`
- Check what's already registered
- Understand current dependency structure
- Check if Hive or SharedPreferences already registered

**Existing Models:**
- Check `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/models/`
- Check `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/data/models/`
- Look for naming patterns and structure

**Existing DataSources:**
- Check `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/data/datasources/`
- Understand interface patterns and Firebase implementation
- Check if any caching datasources already exist

**Existing Repositories:**
- Check `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/data/repositories/`
- Check `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/domain/repositories/`
- Understand Either<Failure, Data> pattern usage

**Existing BLoCs:**
- Check `/Applications/Documents/dev/shree-krishna-emb/shree_krishna_emb_user_app/lib/bloc/`
- Understand event/state patterns
- Check how repositories are injected

**Screens (if updating):**
- Read the screen file to understand what data is needed
- Check current BLoC usage
- Check if offline UI (indicator, disabled buttons) is needed

### Step 5: Resolve Data Model Conflicts

If data model conflicts with existing code:
- **Ask user:** "This conflicts with existing [feature]. How should we handle this?"
- **OR Auto-resolve:** If it's a small, non-breaking conflict, resolve and explain the change
- Examples:
  - Extra fields in existing model → add fields automatically
  - Renamed field → ask user
  - Duplicate collection name → ask user to clarify intent

### Step 6: Design Firestore Structure

Define collection structure with:
- Collection name (singular, lowercase: `users`, `products`, `orders`)
- Document fields with types: string, number, boolean, timestamp, array, map
- Relationships: parent/child collections, references
- Indexes needed for queries (pagination, sorting, filtering)
- Cost optimization notes
- Caching hint (cache for offline, don't cache for real-time, etc.)

Template:
```
Collection: products
├── {productId}
│   ├── name: string
│   ├── price: number
│   ├── description: string
│   ├── category: string
│   ├── imageUrls: array<string>
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
│   └── isActive: boolean

Indexes:
- category + createdAt (for filtered lists)
- isActive + createdAt (for active products)

Caching: Yes (good for product lists, category filters)
Offline Mode: Yes (important for browsing, ordering)
```

### Step 7: Generate Entity (Domain Layer)

**Path:** `lib/domain/entities/[feature].dart`

If shared backend, might go in core folder. If app-specific, use app folder.

```dart
import 'package:equatable/equatable.dart';

class [FeatureName]Entity extends Equatable {
  final String id;
  final String name;
  final double price;
  final String description;
  final DateTime createdAt;
  final bool isActive;

  const [FeatureName]Entity({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.createdAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, price, description, createdAt, isActive];
}
```

### Step 8: Generate Model (Data Layer)

**Path:** `lib/data/models/[feature]_model.dart` OR `lib/models/[feature]_model.dart`

Must have dual serialization (Firebase + API for future migration):

```dart
import '[feature]_entity.dart';

class [FeatureName]Model extends [FeatureName]Entity {
  const [FeatureName]Model({
    required super.id,
    required super.name,
    required super.price,
    required super.description,
    required super.createdAt,
    required super.isActive,
  });

  // Firebase Serialization
  factory [FeatureName]Model.fromFirebaseJson(Map<String, dynamic> json) {
    return [FeatureName]Model(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  // API Serialization (for future migration to Node.js/Supabase)
  factory [FeatureName]Model.fromApiJson(Map<String, dynamic> json) {
    return [FeatureName]Model(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
```

### Step 9: Generate DataSource Interface & Implementation

**Path:** `lib/data/datasources/firebase_[feature]_datasource.dart`

```dart
// Abstract interface (backend-agnostic)
abstract class [FeatureName]DataSource {
  Future<[FeatureName]Model> get[FeatureName](String id);
  Future<List<[FeatureName]Model>> getAll[FeatureName]s({
    int? limit,
    String? lastDocumentId,
  });
  Future<[FeatureName]Model> create[FeatureName]([FeatureName]Model model);
  Future<[FeatureName]Model> update[FeatureName]([FeatureName]Model model);
  Future<void> delete[FeatureName](String id);
  Stream<List<[FeatureName]Model>> watch[FeatureName]s();
  Stream<[FeatureName]Model> watch[FeatureName](String id);
}

// Firebase Implementation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shree_krishna_emb_user_app/core/errors/exceptions.dart';

class Firebase[FeatureName]DataSource implements [FeatureName]DataSource {
  final FirebaseFirestore _firestore;
  static const String _collectionName = '[featureName]'; // lowercase

  Firebase[FeatureName]DataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<[FeatureName]Model> get[FeatureName](String id) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (!doc.exists) {
        throw ServerException(message: '[FeatureName] not found');
      }

      return [FeatureName]Model.fromFirebaseJson({
        ...doc.data()!,
        'id': doc.id,
      });
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Firebase error');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<[FeatureName]Model>> getAll[FeatureName]s({
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true);

      // Pagination
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(_collectionName)
            .doc(lastDocumentId)
            .get();
        query = query.startAfterDocument(lastDoc);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => [FeatureName]Model.fromFirebaseJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Firebase error');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<[FeatureName]Model> create[FeatureName]([FeatureName]Model model) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(model.toFirebaseJson());

      return [FeatureName]Model.fromFirebaseJson({
        ...model.toFirebaseJson(),
        'id': docRef.id,
      });
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Firebase error');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<[FeatureName]Model> update[FeatureName]([FeatureName]Model model) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(model.id)
          .update({
            ...model.toFirebaseJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return model;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Firebase error');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> delete[FeatureName](String id) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .delete();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Firebase error');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<[FeatureName]Model>> watch[FeatureName]s() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => [FeatureName]Model.fromFirebaseJson({
                  ...doc.data(),
                  'id': doc.id,
                }))
            .toList());
  }

  @override
  Stream<[FeatureName]Model> watch[FeatureName](String id) {
    return _firestore
        .collection(_collectionName)
        .doc(id)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw ServerException(message: '[FeatureName] not found');
          }
          return [FeatureName]Model.fromFirebaseJson({
            ...doc.data()!,
            'id': doc.id,
          });
        });
  }
}
```

### Step 10: Generate Caching DataSource (if needed)

If caching is needed, generate a wrapper datasource:

**Path:** `lib/data/datasources/cached_[feature]_datasource.dart`

```dart
// Wrapper for persistent caching (Hive or SharedPreferences)
import 'package:hive/hive.dart';
import 'firebase_[feature]_datasource.dart';

class Cached[FeatureName]DataSource implements [FeatureName]DataSource {
  final [FeatureName]DataSource _remoteDataSource;
  final Box<[FeatureName]Model> _localCache;
  static const String _cacheKey = '[featureName]_list';
  static const String _offlineMutationsKey = '[featureName]_offline_mutations';

  Cached[FeatureName]DataSource({
    required [FeatureName]DataSource remoteDataSource,
    required Box<[FeatureName]Model> localCache,
  })  : _remoteDataSource = remoteDataSource,
        _localCache = localCache;

  // Try remote first, fallback to cache
  @override
  Future<[FeatureName]Model> get[FeatureName](String id) async {
    try {
      final model = await _remoteDataSource.get[FeatureName](id);
      await _localCache.put(id, model); // Update cache
      return model;
    } catch (e) {
      // Try cache on error (offline)
      final cached = _localCache.get(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  // Cache after fetching from remote
  @override
  Future<List<[FeatureName]Model>> getAll[FeatureName]s({
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      final models = await _remoteDataSource.getAll[FeatureName]s(
        limit: limit,
        lastDocumentId: lastDocumentId,
      );
      await _localCache.clear();
      for (var model in models) {
        await _localCache.put(model.id, model);
      }
      return models;
    } catch (e) {
      // Return cached data on error
      final cached = _localCache.values.toList();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  // Queue mutations offline, sync when online
  @override
  Future<[FeatureName]Model> create[FeatureName]([FeatureName]Model model) async {
    try {
      final created = await _remoteDataSource.create[FeatureName](model);
      await _localCache.put(created.id, created);
      return created;
    } catch (e) {
      // Queue for offline sync
      await _queueMutation('create', model);
      // Return locally for optimistic UI
      await _localCache.put(model.id, model);
      return model;
    }
  }

  @override
  Future<[FeatureName]Model> update[FeatureName]([FeatureName]Model model) async {
    try {
      final updated = await _remoteDataSource.update[FeatureName](model);
      await _localCache.put(updated.id, updated);
      return updated;
    } catch (e) {
      await _queueMutation('update', model);
      await _localCache.put(model.id, model);
      return model;
    }
  }

  @override
  Future<void> delete[FeatureName](String id) async {
    try {
      await _remoteDataSource.delete[FeatureName](id);
      await _localCache.delete(id);
    } catch (e) {
      await _queueMutation('delete', [FeatureName]Model(...)); // Store minimal data
      await _localCache.delete(id);
    }
  }

  // Queued mutations for offline sync
  Future<void> _queueMutation(String operation, [FeatureName]Model model) async {
    final box = await Hive.openBox(_offlineMutationsKey);
    final mutations = box.get('mutations', defaultValue: []);
    mutations.add({
      'operation': operation,
      'model': model.toFirebaseJson(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    await box.put('mutations', mutations);
  }

  // Sync queued mutations when online
  Future<void> syncOfflineMutations() async {
    final box = await Hive.openBox(_offlineMutationsKey);
    final mutations = box.get('mutations', defaultValue: []);

    for (var mutation in mutations) {
      try {
        final model = [FeatureName]Model.fromFirebaseJson(mutation['model']);
        switch (mutation['operation']) {
          case 'create':
            await _remoteDataSource.create[FeatureName](model);
            break;
          case 'update':
            await _remoteDataSource.update[FeatureName](model);
            break;
          case 'delete':
            await _remoteDataSource.delete[FeatureName](model.id);
            break;
        }
      } catch (e) {
        // Retry later
      }
    }

    await box.delete('mutations');
  }

  // Streams (pass through to remote, or cached if offline)
  @override
  Stream<List<[FeatureName]Model>> watch[FeatureName]s() {
    return _remoteDataSource.watch[FeatureName]s();
  }

  @override
  Stream<[FeatureName]Model> watch[FeatureName](String id) {
    return _remoteDataSource.watch[FeatureName](id);
  }
}
```

### Step 11: Generate Repository Interface (Domain Layer)

**Path:** `lib/domain/repositories/[feature]_repository.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:shree_krishna_emb_user_app/core/errors/failures.dart';
import 'package:shree_krishna_emb_user_app/data/models/[feature]_model.dart';

abstract class [FeatureName]Repository {
  Future<Either<Failure, [FeatureName]Model>> get[FeatureName](String id);
  Future<Either<Failure, List<[FeatureName]Model>>> getAll[FeatureName]s({
    int? limit,
    String? lastDocumentId,
  });
  Future<Either<Failure, [FeatureName]Model>> create[FeatureName]([FeatureName]Model model);
  Future<Either<Failure, [FeatureName]Model>> update[FeatureName]([FeatureName]Model model);
  Future<Either<Failure, void>> delete[FeatureName](String id);
  Stream<Either<Failure, List<[FeatureName]Model>>> watch[FeatureName]s();
  Stream<Either<Failure, [FeatureName]Model>> watch[FeatureName](String id);
  
  // Offline support
  Future<Either<Failure, void>> syncOfflineMutations();
}
```

### Step 12: Generate Repository Implementation (Data Layer)

**Path:** `lib/data/repositories/[feature]_repository_impl.dart`

```dart
import 'package:fpdart/fpdart.dart';
import 'package:shree_krishna_emb_user_app/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_user_app/core/errors/failures.dart';
import 'package:shree_krishna_emb_user_app/data/datasources/firebase_[feature]_datasource.dart';
import 'package:shree_krishna_emb_user_app/data/models/[feature]_model.dart';
import 'package:shree_krishna_emb_user_app/domain/repositories/[feature]_repository.dart';

class [FeatureName]RepositoryImpl implements [FeatureName]Repository {
  final [FeatureName]DataSource _dataSource;

  [FeatureName]RepositoryImpl({required [FeatureName]DataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, [FeatureName]Model>> get[FeatureName](String id) async {
    try {
      final model = await _dataSource.get[FeatureName](id);
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<[FeatureName]Model>>> getAll[FeatureName]s({
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      final models = await _dataSource.getAll[FeatureName]s(
        limit: limit,
        lastDocumentId: lastDocumentId,
      );
      return Right(models);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, [FeatureName]Model>> create[FeatureName]([FeatureName]Model model) async {
    try {
      final created = await _dataSource.create[FeatureName](model);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, [FeatureName]Model>> update[FeatureName]([FeatureName]Model model) async {
    try {
      final updated = await _dataSource.update[FeatureName](model);
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete[FeatureName](String id) async {
    try {
      await _dataSource.delete[FeatureName](id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<[FeatureName]Model>>> watch[FeatureName]s() {
    return _dataSource.watch[FeatureName]s().map(
      (models) => Right(models),
    ).handleError(
      (error) => Left(ServerFailure(error.toString())),
    );
  }

  @override
  Stream<Either<Failure, [FeatureName]Model>> watch[FeatureName](String id) {
    return _dataSource.watch[FeatureName](id).map(
      (model) => Right(model),
    ).handleError(
      (error) => Left(ServerFailure(error.toString())),
    );
  }

  @override
  Future<Either<Failure, void>> syncOfflineMutations() async {
    try {
      if (_dataSource is Cached[FeatureName]DataSource) {
        await (_dataSource as Cached[FeatureName]DataSource).syncOfflineMutations();
      }
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
```

### Step 13: Generate Use Cases (if needed)

**Path:** `lib/domain/usecases/get_[feature]_usecase.dart`

Only create if there's complex business logic. Simple CRUD can skip this.

```dart
import 'package:fpdart/fpdart.dart';
import 'package:shree_krishna_emb_user_app/core/errors/failures.dart';
import 'package:shree_krishna_emb_user_app/data/models/[feature]_model.dart';
import 'package:shree_krishna_emb_user_app/domain/repositories/[feature]_repository.dart';

class Get[FeatureName]UseCase {
  final [FeatureName]Repository repository;

  Get[FeatureName]UseCase(this.repository);

  Future<Either<Failure, [FeatureName]Model>> call(String id) {
    return repository.get[FeatureName](id);
  }
}
```

### Step 14: Register in Service Locator

**Path:** `lib/core/di/service_locator.dart`

Add to `setupServiceLocator()`:

```dart
// Setup Hive for caching (if caching enabled)
final box = await Hive.openBox<[FeatureName]Model>('[featureName]');

// Data sources
getIt.registerSingleton<[FeatureName]DataSource>(
  // Without caching:
  Firebase[FeatureName]DataSource(firestore: getIt()),
  
  // With caching:
  // Cached[FeatureName]DataSource(
  //   remoteDataSource: Firebase[FeatureName]DataSource(firestore: getIt()),
  //   localCache: box,
  // ),
);

// Repositories
getIt.registerSingleton<[FeatureName]Repository>(
  [FeatureName]RepositoryImpl(dataSource: getIt()),
);

// Use cases (if needed)
getIt.registerSingleton<Get[FeatureName]UseCase>(
  Get[FeatureName]UseCase(getIt()),
);
```

### Step 15: Generate Firestore Security Rules

**Create file:** `firestore_rules.js` or `firestore_rules_[feature].js` (for review only)

Ask user to review BEFORE creating in Firebase Console.

Template based on role (adjust as needed):

```javascript
// User's own data (e.g., profile, preferences)
match /[featureName]/{userId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId;
  allow read, write: if request.auth.token.admin == true;
}

// Public data (e.g., products, posts)
match /[featureName]/{document=**} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update: if request.auth.uid == resource.data.userId;
  allow delete: if request.auth.token.admin == true;
}

// Admin only data
match /[featureName]/{document=**} {
  allow read, write: if request.auth.token.admin == true;
}
```

### Step 16: Update Screen BLoC Integration

**If updating existing screen:**

1. Read screen BLoC file: `lib/bloc/[feature]/[feature]_bloc.dart`
2. Update to use new repository
3. Add events for new operations (create, update, delete if not present)
4. Add states for new operations
5. Handle Either<Failure, Data> properly
6. **If offline mode:** Add offline detection and sync events

Example BLoC event with offline support:

```dart
class Create[FeatureName]Event extends [FeatureName]Event {
  final [FeatureName]Model model;
  final bool offline; // true if created offline

  const Create[FeatureName]Event(this.model, {this.offline = false});

  @override
  List<Object?> get props => [model, offline];
}

// Sync offline mutations
class Sync[FeatureName]Event extends [FeatureName]Event {
  const Sync[FeatureName]Event();

  @override
  List<Object?> get props => [];
}
```

Example BLoC handler with offline support:

```dart
on<Create[FeatureName]Event>((event, emit) async {
  emit(const [FeatureName]Loading());

  final result = await _repository.create[FeatureName](event.model);

  result.fold(
    (failure) => emit([FeatureName]Error(failure.message, isOffline: event.offline)),
    (model) => emit([FeatureName]Loaded(model)),
  );
});

// Sync when online
on<Sync[FeatureName]Event>((event, emit) async {
  final result = await _repository.syncOfflineMutations();
  result.fold(
    (failure) => emit([FeatureName]SyncError(failure.message)),
    (_) => emit(const [FeatureName]SyncSuccess()),
  );
});
```

3. Update screen to:
   - Show loading/error states
   - Handle offline indicator
   - Show "sync pending" if offline mutations exist
   - Disable mutations if offline (optional)
4. Add offline detection using connectivity plugin

Example UI with offline support:

```dart
BlocBuilder<[FeatureName]Bloc, [FeatureName]State>(
  builder: (context, state) {
    return Scaffold(
      body: Column(
        children: [
          // Offline indicator
          if (state.isOffline)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange,
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You are offline. Changes will sync when online.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<[FeatureName]Bloc>().add(const Sync[FeatureName]Event());
                    },
                    child: const Text('Sync', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          
          // Content
          if (state is [FeatureName]Loaded)
            YourContent(model: state.model),
          if (state is [FeatureName]Loading)
            const Center(child: CircularProgressIndicator()),
          if (state is [FeatureName]Error)
            Center(child: Text(state.message)),
        ],
      ),
    );
  },
);
```

### Step 17: Warn About Potential Issues

Check for and warn about:

**N+1 Queries:**
```dart
// ❌ BAD: N+1 problem
for (var item in items) {
  await repo.get[FeatureName](item.id); // Query per item!
}

// ✅ GOOD: Batch fetch
await repo.getAll[FeatureName]s(limit: 100);
```

**Unoptimized Field Selection:**
```dart
// ❌ BAD: Fetches all fields
final doc = await _firestore.collection('[featureName]').doc(id).get();

// ✅ GOOD: Only needed fields
final doc = await _firestore
    .collection('[featureName]')
    .doc(id)
    .get(GetOptions(...));
```

**Caching Issues:**
- Warn if caching stale data without refresh mechanism
- Suggest cache expiration strategies
- Recommend periodic sync

**Offline Issues:**
- Warn if queued mutations could exceed local storage
- Suggest cleanup strategy for old mutations
- Recommend connection monitoring

**Cost Concerns:**
- Estimate monthly cost for expected usage
- Suggest optimizations if cost is high

### Step 18: Provide Summary

Output summary document with:

**Files Created:**
```
✓ lib/domain/entities/[feature].dart
✓ lib/data/models/[feature]_model.dart
✓ lib/data/datasources/firebase_[feature]_datasource.dart
✓ lib/data/datasources/cached_[feature]_datasource.dart (if caching)
✓ lib/domain/repositories/[feature]_repository.dart
✓ lib/data/repositories/[feature]_repository_impl.dart
✓ firestore_rules_[feature].js (for review)
```

**Files Updated:**
```
✓ lib/core/di/service_locator.dart (added registrations + Hive setup if caching)
✓ lib/bloc/[feature]/[feature]_bloc.dart (added events/states + offline sync)
✓ lib/screens/[feature]/[feature]_screen.dart (BLoC integration + offline UI)
```

**Caching & Offline Setup:**
```
✓ Caching Strategy: [BLoC/State | Hive | SharedPreferences | None]
✓ Offline Mode: [Enabled | Disabled]
✓ Mutation Queuing: [Enabled | Disabled]
✓ Cache Expiration: [None | TTL based | Manual refresh]
```

**Firestore Structure Created:**
```
Collection: [featureName]
├── {docId}
│   ├── field1: type
│   ├── field2: type
│   └── createdAt: timestamp

Indexes:
- field1 + createdAt (for filtered queries)

Cache Recommendation: [Yes/No - reason]
Offline Necessity: [Critical/Important/Optional]
```

**Security Rules (Awaiting Review):**
```
✓ Rules file: firestore_rules_[feature].js
⚠️ Please review and approve before deployment
```

**Dependencies Added:**
```
- hive: ^2.2.0 (for caching)
- hive_flutter: ^1.1.0 (for caching)
- connectivity_plus: ^5.0.0 (for offline detection)
```

**Next Steps:**
```
1. Review firestore_rules_[feature].js
2. Add Hive models if caching enabled
3. Copy rules to Firebase Console
4. Test with Firebase Emulator
5. Test offline mode (disconnect network)
6. Run your app and test the new features
7. Monitor Firestore usage in Firebase Console
```

**Cost Estimation:**
```
Expected monthly cost: $X
- Estimated reads: Y/day
- Estimated writes: Z/day
- Storage: Minimal
- Optimization tips: [list any suggestions]

With caching: Estimated reduction of X% reads
```

---

## Notes & Guardrails

### What This Skill DOES
✅ Generate complete backend for Firebase
✅ Update existing models and repositories
✅ Read existing code and understand context
✅ Smart placement (core vs app-specific)
✅ Ask for clarification on conflicts OR auto-resolve if safe
✅ Generate dual serialization (Firebase + API ready)
✅ **Generate caching strategies** (Hive, SharedPreferences, BLoC)
✅ **Implement offline mode** (mutation queuing, sync)
✅ **Detect and warn about offline issues**
✅ Warn about N+1 queries, costs, inefficiencies
✅ Ask user to review security rules before creating
✅ Integrate with UI through BLoCs
✅ Support delegation from design-system-skill
✅ Never violate clean architecture

### What This Skill DOES NOT DO
❌ Deploy to Firebase Console directly
❌ Update Firebase Console rules without asking
❌ Violate clean architecture layers
❌ Create hardcoded strings in models
❌ Skip error handling (Either type required)
❌ Generate code without reading existing patterns
❌ Add dependencies without noting them

### Architecture Enforcement
- ❌ No Firebase imports in presentation layer
- ✅ Enforce Either<Failure, Data> for error handling
- ✅ Enforce dependency injection through service_locator
- ✅ Enforce datasource → repository → usecase → BLoC flow
- ✅ Enforce dual serialization (Firebase + API)

### Naming Conventions
- Collections: lowercase, singular (`product`, not `products`)
- Documents: lowercase (userId, productId)
- Classes: PascalCase (ProductModel, ProductRepository)
- Methods: camelCase (getProduct, createProduct)
- Files: snake_case (product_model.dart)

### File Placement Rules
- **Shared (core):** If used by Admin & User apps
  - `shree_krishna_emb_user_app/lib/core/` AND
  - `shree_krishna_admin_app/lib/core/` (or symlink)
- **App-specific (user app):** If only for User App
  - `shree_krishna_emb_user_app/lib/`
- **App-specific (admin app):** If only for Admin App
  - `shree_krishna_admin_app/lib/`

---

## Reference: Firestore Best Practices

From your FIREBASE_BEST_PRACTICES.md:

### ✅ DO:
- Select only needed fields
- Use pagination (limit: 20)
- Watch specific documents, not whole collections
- Use offline cache (reduces quota usage)
- Create indexes for frequently queried fields
- Batch operations for multiple updates
- Use collection groups for subcollections

### ❌ DON'T:
- Fetch entire collection without limit
- N+1 queries (query per item)
- Listen to all documents (use document-specific listeners)
- Missing indexes for complex queries
- Unoptimized field selection

---

## Migration Path (Future)

When you're ready to migrate to Node.js or Supabase:

1. Read [MIGRATION_TO_NODEJS.md](MIGRATION_TO_NODEJS.md) or [MIGRATION_TO_SUPABASE.md](MIGRATION_TO_SUPABASE.md)
2. Create new API datasource: `lib/data/datasources/api_[feature]_datasource.dart`
3. Repository implementation stays the same (implements same interface)
4. Model already has `.fromApiJson()` and `.toApiJson()` methods
5. Only update `lib/core/di/service_locator.dart` to switch datasources
6. **Caching datasource works with any backend** (Firebase, API, Supabase)
7. No BLoC/UI changes needed!

This is why models have dual serialization and caching is backend-agnostic.

---

## Common Questions

**Q: Do I need to create entities separate from models?**
A: Yes! Entity is backend-agnostic (domain layer), Model extends Entity (data layer). This enables backend swapping.

**Q: Should I always create use cases?**
A: Not for simple CRUD. Use cases are useful for complex business logic. For basic get/create/update/delete, repository is enough.

**Q: When should I enable caching?**
A: Enable for frequently accessed data (products, profiles, lists). Disable for real-time critical data (notifications, live updates). Ask user if unsure.

**Q: What if offline mode causes mutations to pile up?**
A: Implement cleanup strategy - delete mutations older than 7 days, or limit queue size. Warn user about this.

**Q: Should streaming subscriptions be cached?**
A: No - streams should always pull fresh data. Cache only one-time queries (get, list).

**Q: How do I handle relationships?**
A: Options:
1. Store ID reference in document
2. Use subcollections for one-to-many
3. Denormalize data if reads >> writes
Choose based on access patterns.

**Q: What about user-specific data (my posts, my preferences)?**
A: Use document ID = userId:
```
users/{userId}/preferences/{preferenceId}
```
Security rule: `allow read, write: if request.auth.uid == userId`

---

**Ready to generate backend! Describe your data model or reference your screen.**
