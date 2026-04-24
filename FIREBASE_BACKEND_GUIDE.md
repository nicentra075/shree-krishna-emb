# Firebase Backend Setup & Usage Guide

## Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

This installs:
- `firebase_core` - Core Firebase SDK
- `cloud_firestore` - Database
- `firebase_auth` - Authentication
- `firebase_storage` - File storage

### 2. Initialize Firebase in main.dart
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MainApp());
}
```

### 3. Set Up Dependency Injection
```dart
// In lib/core/di/service_locator.dart
void setupServiceLocator() {
  // Firebase instances
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  
  // Data sources
  getIt.registerSingleton<UserDataSource>(
    FirebaseUserDataSource(firestore: getIt()),
  );
  
  // Repositories
  getIt.registerSingleton<UserRepository>(
    UserRepositoryImpl(dataSource: getIt()),
  );
  
  // Use cases
  getIt.registerSingleton<GetUserUseCase>(
    GetUserUseCase(getIt()),
  );
}

// Call in main() before runApp()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  setupServiceLocator();  // Add this line
  
  runApp(const MainApp());
}
```

## Database Structure (Firestore)

### Users Collection
```
users/
├── userId1/
│   ├── email: "user@example.com"
│   ├── name: "John Doe"
│   ├── photoUrl: "https://..."
│   ├── createdAt: "2024-04-22T10:30:00Z"
│   └── isActive: true
└── userId2/
    └── ...
```

### Create Firestore Rules (Security)
```javascript
// Go to Firebase Console → Firestore → Rules

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      // Public read (adjust based on your needs)
      allow read: if request.auth != null;
      
      // Only own user can write
      allow write: if request.auth.uid == userId;
      
      // Admin can manage all users
      allow write: if request.auth.token.admin == true;
    }
    
    // Admin collection (admin only)
    match /admin/{document=**} {
      allow read, write: if request.auth.token.admin == true;
    }
  }
}
```

## Authentication

### Email & Password Authentication
```dart
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register
  Future<UserCredential> registerUser(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Login
  Future<UserCredential> loginUser(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Watch auth state
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}
```

### Using in BLoC
```dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(AuthInitial()) {
    on<LoginEvent>((event, emit) async {
      emit(AuthLoading());
      try {
        await authService.loginUser(event.email, event.password);
        emit(AuthSuccess());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}
```

## Database Operations

### Create Data
```dart
// Using repository (recommended)
final userRepo = getIt<UserRepository>();
final user = UserModel(
  id: 'user123',
  email: 'user@example.com',
  name: 'John Doe',
  createdAt: DateTime.now(),
  isActive: true,
);
final result = await userRepo.createUser(user);

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (user) => print('Created: ${user.name}'),
);
```

### Read Data
```dart
final userRepo = getIt<UserRepository>();
final result = await userRepo.getUserById('user123');

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (user) => print('User: ${user.name}'),
);
```

### Update Data
```dart
final userRepo = getIt<UserRepository>();
final updatedUser = user.copyWith(name: 'Jane Doe');
final result = await userRepo.updateUser(updatedUser);

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (user) => print('Updated: ${user.name}'),
);
```

### Delete Data
```dart
final userRepo = getIt<UserRepository>();
final result = await userRepo.deleteUser('user123');

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (_) => print('User deleted'),
);
```

### Real-time Updates (Streams)
```dart
// Watch single user changes
final userRepo = getIt<UserRepository>();

userRepo.watchUser('user123').listen(
  (result) {
    result.fold(
      (failure) => print('Error: ${failure.message}'),
      (user) => print('User updated: ${user.name}'),
    );
  },
);

// In BLoC with StreamSubscription
class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepo;
  StreamSubscription? _userSubscription;

  UserBloc(this.userRepo) : super(UserInitial()) {
    on<WatchUserEvent>((event, emit) {
      _userSubscription = userRepo.watchUser(event.userId).listen(
        (result) {
          result.fold(
            (failure) => emit(UserError(failure.message)),
            (user) => emit(UserLoaded(user)),
          );
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await _userSubscription?.cancel();
    return super.close();
  }
}
```

## File Storage

### Upload File
```dart
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(File file, String path) async {
    try {
      final task = await _storage.ref(path).putFile(file);
      final url = await task.ref.getDownloadURL();
      return url;
    } catch (e) {
      throw ServerException(message: 'Upload failed: $e');
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (e) {
      throw ServerException(message: 'Delete failed: $e');
    }
  }
}
```

### Usage
```dart
final file = File('/path/to/image.jpg');
final url = await storageService.uploadFile(file, 'users/profile_pics/user123.jpg');
print('Upload URL: $url');
```

## Pagination

### Fetching with Pagination
```dart
class PaginationService {
  final UserRepository userRepo;
  
  Future<({List<UserModel> users, String? lastId})> fetchUsers({
    required int limit,
    String? lastDocumentId,
  }) async {
    final result = await userRepo.getAllUsers(
      limit: limit,
      lastDocumentId: lastDocumentId,
    );

    return result.fold(
      (failure) => throw failure,
      (users) => (
        users: users.take(limit).toList(),
        lastId: users.isNotEmpty ? users.last.id : null,
      ),
    );
  }
}
```

### In BLoC
```dart
class UserListBloc extends Bloc<UserListEvent, UserListState> {
  final UserRepository userRepo;
  List<UserModel> _allUsers = [];
  String? _lastDocumentId;

  UserListBloc(this.userRepo) : super(UserListInitial()) {
    on<FetchUsersEvent>((event, emit) async {
      emit(UserListLoading());
      
      final result = await userRepo.getAllUsers(
        limit: 20,
        lastDocumentId: _lastDocumentId,
      );

      result.fold(
        (failure) => emit(UserListError(failure.message)),
        (users) {
          _allUsers.addAll(users);
          if (users.isNotEmpty) {
            _lastDocumentId = users.last.id;
          }
          emit(UserListLoaded(_allUsers));
        },
      );
    });
  }
}
```

## Search

### Simple Search
```dart
final userRepo = getIt<UserRepository>();
final result = await userRepo.searchUsers('John');

result.fold(
  (failure) => print('Error: ${failure.message}'),
  (users) => print('Found: ${users.length} users'),
);
```

### In TextField
```dart
TextField(
  onChanged: (query) {
    context.read<SearchBloc>().add(SearchUsersEvent(query));
  },
  hintText: 'Search users...',
)
```

## Cloud Functions (Optional)

For complex backend logic, use Firebase Cloud Functions:

```javascript
// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.createUserProfile = functions.auth.user().onCreate(async (user) => {
  await admin.firestore().collection("users").doc(user.uid).set({
    email: user.email,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isActive: true,
  });
});
```

## Cost Optimization Tips

### 1. Use Indexes
```javascript
// Firestore creates indexes automatically, but you can optimize:
// - Index only queried fields
// - Use collection groups wisely
```

### 2. Limit Data Transfers
```dart
// ❌ Bad: Fetches all fields
final snapshot = await _firestore.collection('users').get();

// ✅ Good: Only needed fields
final snapshot = await _firestore
    .collection('users')
    .select(['name', 'email'])
    .get();
```

### 3. Batch Operations
```dart
// ❌ Bad: N+1 queries
for (var user in users) {
  await _firestore.collection('users').doc(user.id).update({'active': true});
}

// ✅ Good: Single batch
final batch = _firestore.batch();
for (var user in users) {
  batch.update(
    _firestore.collection('users').doc(user.id),
    {'active': true},
  );
}
await batch.commit();
```

### 4. Offline Persistence
```dart
final firestore = FirebaseFirestore.instance;

// Enable offline caching (cached queries don't count towards quota)
await firestore.enableNetwork();

// Disable if not needed
await firestore.disableNetwork();
```

### 5. Set Retention Policy
```javascript
// In Firebase Console → Firestore → Overwrite Settings
// Enable: Delete old documents (e.g., logs after 30 days)
```

## Monitoring & Debugging

### Enable Debug Logging
```dart
// In main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
);

// In release build, disable for performance
if (!kReleaseMode) {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
```

### Monitor Usage in Console
1. Go to Firebase Console
2. Click "Firestore Database"
3. Go to "Usage" tab
4. Monitor:
   - Reads/writes/deletes
   - Data stored
   - Network usage

## Troubleshooting

**Q: "Permission denied" error**
A: Check Firestore security rules. Allow reads for authenticated users.

**Q: "Document not found" error**
A: Document doesn't exist. Create it first with `.set()` or `.doc().create()`.

**Q: "Slow queries"**
A: Create indexes for frequently queried fields. Firestore suggests this automatically.

**Q: "High costs"**
A: Check for N+1 queries, batch operations, use pagination, enable offline caching.

## Next Steps

- [Read ARCHITECTURE_GUIDE.md for system architecture](ARCHITECTURE_GUIDE.md)
- [Read FIREBASE_BEST_PRACTICES.md for optimization](FIREBASE_BEST_PRACTICES.md)
- [Read MIGRATION_TO_NODEJS.md when ready to scale](MIGRATION_TO_NODEJS.md)

## Resources

- [Firebase Official Docs](https://firebase.google.com/docs/firestore)
- [Firebase Pricing Calculator](https://firebase.google.com/pricing/calculator)
- [Firestore Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
