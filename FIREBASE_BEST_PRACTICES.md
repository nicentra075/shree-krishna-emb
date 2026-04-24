# Firebase Best Practices & Optimization Guide

## 1. Cost Optimization

### ❌ What Wastes Money

```dart
// BAD: Fetches entire document every time
final doc = await firestore.collection('users').doc(userId).get();
print(doc['name']); // Only needed field

// BAD: N+1 problem - multiple queries
for (var user in users) {
  final prefs = await firestore
      .collection('users')
      .doc(user.id)
      .collection('preferences')
      .get(); // 1 query per user!
}

// BAD: No pagination - fetches thousands of documents
final allProducts = await firestore.collection('products').get();

// BAD: Listening to all documents
final subscription = firestore
    .collection('users')
    .snapshots() // Every user change triggers update
    .listen((snapshot) { ... });
```

### ✅ Cost-Saving Patterns

```dart
// GOOD: Select only needed fields
final doc = await firestore
    .collection('users')
    .doc(userId)
    .get(GetOptions(source: Source.serverAndCache));

// Optimized: Use collection group queries
final prefs = await firestore
    .collectionGroup('preferences')
    .where('userId', isEqualTo: userId)
    .get(); // Single query for all preferences

// GOOD: Implement pagination
final query = firestore
    .collection('products')
    .orderBy('createdAt', descending: true)
    .limit(20); // Only fetch 20 at a time

// GOOD: Watch specific documents only
final subscription = firestore
    .collection('users')
    .doc(userId)
    .snapshots() // Only one user
    .listen((snapshot) { ... });

// GOOD: Use offline cache
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
);
// Cached queries don't count towards usage quota!
```

### Cost Estimation

```
Free tier covers:
- 1 GB storage
- 50,000 reads/day
- 20,000 writes/day
- 20,000 deletes/day

For 1,000 users:
- ~30,000 reads/day
- ~5,000 writes/day
- Cost: ~$25/month

For 10,000 users:
- ~300,000 reads/day
- ~50,000 writes/day
- Cost: ~$300/month
```

## 2. Security

### ✅ Good Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users: own data only
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
      allow read: if request.auth.token.admin == true;
    }
    
    // Posts: public read, owner write
    match /posts/{document=**} {
      allow read: if true;
      allow write: if request.auth.uid == resource.data.authorId;
      allow delete: if request.auth.uid == resource.data.authorId || 
                       request.auth.token.admin == true;
    }
    
    // Admin only
    match /admin/{document=**} {
      allow read, write: if request.auth.token.admin == true;
    }
  }
}
```

### ❌ Bad Security Rules

```javascript
// DANGER: Public write access
match /users/{userId} {
  allow read, write: if true; // Anyone can read/write!
}

// DANGER: No validation
match /posts/{postId} {
  allow write: if request.auth != null; // Anyone logged in can edit!
}
```

## 3. Data Structure

### ✅ Good Data Structure

```javascript
// Organize by access patterns
users/
├── user1/
│   ├── email: "user1@example.com"
│   ├── name: "User One"
│   └── profile/ (subcollection for extra data)
│       ├── bio: "..."
│       └── interests: [...]
│
posts/
├── post1/
│   ├── title: "..."
│   ├── content: "..."
│   ├── authorId: "user1"
│   ├── createdAt: timestamp
│   └── stats: {
│       "likes": 100,
│       "views": 500
│     }
│
users/{userId}/likes/
├── post1: true
├── post2: true
// For efficient "user liked this?" queries
```

### ❌ Bad Data Structure

```javascript
// Too deeply nested (slow queries)
users/
└── user1/
    └── profile/
        └── details/
            └── settings/
                └── privacy/
                    └── allowMessages: true

// Storing computed values (gets out of sync)
user {
  "name": "John",
  "totalPostsCount": 42, // ❌ Gets stale when posts change!
}

// Duplicating data (hard to keep consistent)
users/user1 {
  "name": "John",
  "posts": [post1, post2, ...] // ❌ Duplicates
}
```

## 4. Query Optimization

### ✅ Efficient Queries

```dart
// GOOD: Specific queries with indexes
final query = firestore
    .collection('posts')
    .where('authorId', isEqualTo: userId)
    .where('status', isEqualTo: 'published')
    .orderBy('createdAt', descending: true)
    .limit(20);

// GOOD: Use compound indexes (Firestore creates automatically)
// For complex queries, Firestore suggests adding indexes in console

// GOOD: Cache and reuse queries
class CachedUserRepository {
  Map<String, UserModel> _cache = {};

  Future<UserModel?> getUser(String id) async {
    if (_cache.containsKey(id)) {
      return _cache[id]; // Return cached (free!)
    }

    final doc = await firestore.collection('users').doc(id).get();
    if (doc.exists) {
      final user = UserModel.fromJson(doc.data());
      _cache[id] = user;
      return user;
    }
    return null;
  }
}
```

### ❌ Inefficient Queries

```dart
// BAD: Complex filtering in code
final allUsers = await firestore.collection('users').get();
final activeUsers = allUsers.docs
    .map((doc) => UserModel.fromJson(doc.data()))
    .where((user) => user.isActive && user.region == 'US')
    .toList();

// BAD: Querying all data then sorting
final products = await firestore.collection('products').get();
final sorted = products.docs.sorted((a, b) => /* ... */);

// BAD: Multiple queries in loop
for (var user in users) {
  final settings = await firestore
      .collection('users')
      .doc(user.id)
      .collection('settings')
      .doc('preferences')
      .get(); // N queries!
}
```

## 5. Real-time Subscriptions

### ✅ Good Patterns

```dart
// GOOD: Listen only to what's needed
class UserBloc extends Bloc<UserEvent, UserState> {
  StreamSubscription? _userSubscription;

  UserBloc(this.userRepo) : super(UserInitial()) {
    on<WatchUserEvent>((event, emit) {
      _userSubscription = userRepo.watchUser(event.userId).listen(
        (result) => result.fold(
          (failure) => emit(UserError(failure.message)),
          (user) => emit(UserLoaded(user)),
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    await _userSubscription?.cancel(); // Always clean up!
    return super.close();
  }
}

// GOOD: Use StreamBuilder with proper cleanup
StreamBuilder<UserModel>(
  stream: userRepo.watchUser(userId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LoadingWidget();
    }

    final result = snapshot.data;
    // Handle result...
  },
)
```

### ❌ Bad Patterns

```dart
// BAD: Not cleaning up subscriptions
_userSubscription = userRepo.watchUser(userId).listen((result) { ... });
// BLoC closed, but subscription still active (memory leak!)

// BAD: Listening to everything
stream: firestore.collection('users').snapshots(), // Every user change!

// BAD: Creating new subscription repeatedly
onPressed: () {
  firestore.collection('users').snapshots().listen((snapshot) { ... });
  // Creates new listener every tap!
}
```

## 6. Error Handling

### ✅ Good Error Handling

```dart
Future<Either<Failure, UserModel>> getUserById(String userId) async {
  try {
    final doc = await firestore.collection('users').doc(userId).get();
    
    if (!doc.exists) {
      return const Left(ServerFailure('User not found', code: 'NOT_FOUND'));
    }

    return Right(UserModel.fromJson(doc.data()!));
  } on FirebaseException catch (e) {
    return Left(ServerFailure(e.message ?? 'Firebase error', code: e.code));
  } on SocketException catch (e) {
    return Left(NetworkFailure('Network error: $e'));
  } catch (e) {
    return Left(UnknownFailure('Unexpected error: $e'));
  }
}
```

### ❌ Bad Error Handling

```dart
// BAD: No error handling
final doc = await firestore.collection('users').doc(userId).get();
final user = UserModel.fromJson(doc.data()); // Crashes if null!

// BAD: Generic error messages
catch (e) {
  return Left(ServerFailure('Error')); // Not helpful!
}

// BAD: Swallowing errors
try {
  // ...
} catch (e) {
  // Silently ignore
}
```

## 7. Performance Monitoring

### Setup Performance Monitoring

```dart
import 'package:firebase_performance/firebase_performance.dart';

final performance = FirebasePerformance.instance;

// Trace custom operations
Future<void> fetchUserData(String userId) async {
  final trace = performance.newTrace('fetch_user_data');
  trace.putAttribute('userId', userId);

  await trace.start();
  try {
    final doc = await firestore.collection('users').doc(userId).get();
    trace.putAttribute('success', 'true');
  } catch (e) {
    trace.putAttribute('error', e.toString());
  } finally {
    await trace.stop();
  }
}

// Monitor network requests
final httpMetric = performance.newHttpMetric(
  'https://api.example.com/users',
  HttpMethod.Get,
);

await httpMetric.start();
try {
  final response = await http.get(Uri.parse('https://api.example.com/users'));
  httpMetric.setHttpResponseCode(response.statusCode);
  httpMetric.setResponsePayloadSize(response.bodyBytes.length);
} finally {
  await httpMetric.stop();
}
```

### View Metrics in Console

1. Firebase Console
2. Performance
3. Monitor your traces

## 8. Authentication Best Practices

### ✅ Good Auth Implementation

```dart
// GOOD: Store tokens securely
class AuthService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // GOOD: Refresh tokens automatically
  Future<String> getValidToken() async {
    var token = await getToken();
    
    if (_isTokenExpired(token)) {
      token = await _refreshToken();
      await saveToken(token);
    }
    
    return token!;
  }
}

// GOOD: Use Firebase custom claims for admin roles
Future<void> makeUserAdmin(String userId) async {
  await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
  // In Cloud Function:
  // await admin.auth().setCustomUserClaims(userId, { admin: true });
}
```

### ❌ Bad Auth Implementation

```dart
// BAD: Storing tokens in plain SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('token', token); // Not secure!

// BAD: Not refreshing tokens
// Token expires, user gets logged out

// BAD: Hardcoding credentials
const apiKey = 'sk-1234567890'; // Exposed in code!
```

## 9. Database Maintenance

### Regular Backups

```bash
# Monthly export
firebase firestore:export gs://your-bucket/backups/backup-2024-04
```

### Delete Old Data

```javascript
// Firestore rules: auto-delete old documents
match /logs/{document=**} {
  allow read: if request.time < resource.data.createdAt + duration.value(30, 'd');
  allow delete: if request.time >= resource.data.createdAt + duration.value(30, 'd');
}
```

### Monitor Storage

1. Firebase Console → Firestore
2. Storage tab
3. Check document count and size

## 10. Testing

### Unit Tests (No Firebase)

```dart
test('UserRepositoryImpl converts exceptions to failures', () async {
  final mockDataSource = MockUserDataSource();
  
  when(mockDataSource.getUserById(any))
      .thenThrow(ServerException(message: 'Test error'));

  final repo = UserRepositoryImpl(dataSource: mockDataSource);
  final result = await repo.getUserById('123');

  expect(result, isA<Left>());
});
```

### Integration Tests (With Firebase Emulator)

```bash
# Install emulator
firebase emulators:start

# Run tests against emulator
flutter test --dart-define=USE_FIRESTORE_EMULATOR=true
```

## Checklist Before Going Live

- [ ] Security rules validated
- [ ] Cost estimated and acceptable
- [ ] Indexes created for all queries
- [ ] Offline mode tested
- [ ] Error handling implemented
- [ ] Performance monitoring enabled
- [ ] Backup strategy defined
- [ ] Authentication tested
- [ ] Load tested (expected peak users)
- [ ] Rate limiting configured if needed

## Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| High costs | N+1 queries | Use batch reads, pagination |
| Slow reads | No indexes | Check console suggestions |
| Auth fails | Expired token | Implement token refresh |
| Offline broken | Cache disabled | Enable persistence |
| Data out of sync | Duplicate data | Single source of truth |
| Memory leaks | Unclosed streams | Cancel subscriptions in close() |

## Resources

- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Firestore Pricing Calculator](https://firebase.google.com/pricing/calculator)
- [Security Rules Guide](https://firebase.google.com/docs/firestore/security/get-started)
- [Performance Monitoring](https://firebase.google.com/docs/perf-mod)
