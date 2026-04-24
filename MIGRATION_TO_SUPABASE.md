# Migration Guide: Firebase → Supabase

**Estimated Time:** 2-3 days  
**Effort Level:** Medium  
**Risk Level:** Low (if you followed the architecture)

## Overview

Supabase is an open-source Firebase alternative with PostgreSQL backend. It's cheaper at scale and gives you more control.

### Why Migrate to Supabase?

| Factor | Firebase | Supabase |
|--------|----------|----------|
| **Cost at 10k users** | $300-500/month | $100-150/month |
| **Database** | NoSQL | PostgreSQL (relational) |
| **Flexibility** | Limited | High |
| **Lock-in** | High | Low (can self-host) |
| **Real-time** | Yes | Yes |
| **Auth** | Built-in | Built-in |

## Phase 1: Prepare (Day 1)

### 1.1 Export Firebase Data
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# Export Firestore
firebase firestore:export gs://YOUR_BUCKET_NAME/backup
```

### 1.2 Create Supabase Project
1. Go to https://supabase.com
2. Sign up (free tier available)
3. Create new project
4. Wait for initialization (~5 minutes)
5. Get connection string from Settings → Database

### 1.3 Create Database Schema

In Supabase SQL Editor:

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255),
  photo_url VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on email
CREATE INDEX idx_users_email ON users(email);

-- Create RLS (Row Level Security) policy
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Admin policy (adjust based on your auth)
CREATE POLICY "Admins can manage all users"
  ON users FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');
```

### 1.4 Migrate Data

Create migration script:

```dart
// lib/scripts/migrate_firebase_to_supabase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

void main() async {
  // Firebase
  final firestore = FirebaseFirestore.instance;
  
  // Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_KEY',
  );
  final supabase = Supabase.instance.client;

  try {
    // Fetch all Firebase users
    final firebaseUsers = await firestore.collection('users').get();
    
    print('Migrating ${firebaseUsers.docs.length} users...');

    for (final doc in firebaseUsers.docs) {
      final data = doc.data();
      
      // Insert into Supabase
      await supabase.from('users').insert({
        'id': doc.id,
        'email': data['email'],
        'name': data['name'],
        'photo_url': data['photoUrl'],
        'created_at': data['createdAt'],
        'is_active': data['isActive'] ?? true,
      });
      
      print('✓ Migrated: ${data['email']}');
    }

    print('\n✅ Migration complete!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

Run migration:
```bash
dart lib/scripts/migrate_firebase_to_supabase.dart
```

## Phase 2: Update Code (Day 2)

### 2.1 Add Supabase Dependency

```yaml
dependencies:
  supabase_flutter: ^2.0.0
```

### 2.2 Create Supabase DataSource

```dart
// lib/data/datasources/supabase_user_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shree_krishna_emb/core/errors/exceptions.dart';
import 'package:shree_krishna_emb/data/models/user_model.dart';

class SupabaseUserDataSource implements UserDataSource {
  final SupabaseClient _client;
  static const String _tableName = 'users';

  SupabaseUserDataSource({required SupabaseClient client})
      : _client = client;

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromSupabaseJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        message: e.message,
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch user',
        originalError: e,
      );
    }
  }

  @override
  Future<List<UserModel>> getAllUsers({
    int? limit,
    String? lastDocumentId,
  }) async {
    try {
      var query = _client.from(_tableName).select();

      if (limit != null) {
        query = query.limit(limit + 1);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserModel.fromSupabaseJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        message: e.message,
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to fetch users',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert(user.toSupabaseJson())
          .select()
          .single();

      return UserModel.fromSupabaseJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        message: e.message,
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to create user',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await _client
          .from(_tableName)
          .update(user.toSupabaseJson())
          .eq('id', user.id)
          .select()
          .single();

      return UserModel.fromSupabaseJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(
        message: e.message,
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to update user',
        originalError: e,
      );
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _client.from(_tableName).delete().eq('id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(
        message: e.message,
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to delete user',
        originalError: e,
      );
    }
  }

  @override
  Stream<UserModel> watchUser(String userId) {
    return _client
        .from(_tableName)
        .on(PostgresChangeEvent.all, filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ))
        .map((payload) {
      try {
        return UserModel.fromSupabaseJson(
          payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord,
        );
      } catch (e) {
        throw ServerException(
          message: 'Failed to watch user',
          originalError: e,
        );
      }
    });
  }

  @override
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .ilike('name', '%$query%')
          .limit(20);

      return (response as List)
          .map((json) => UserModel.fromSupabaseJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(
        message: e.message,
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(
        message: 'Failed to search users',
        originalError: e,
      );
    }
  }
}
```

### 2.3 Update UserModel Conversions

Add to `lib/data/models/user_model.dart`:

```dart
// Supabase conversion
factory UserModel.fromSupabaseJson(Map<String, dynamic> json) {
  return UserModel(
    id: json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    name: json['name'] as String?,
    photoUrl: json['photo_url'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    isActive: json['is_active'] as bool? ?? true,
  );
}

Map<String, dynamic> toSupabaseJson() {
  return {
    'email': email,
    'name': name,
    'photo_url': photoUrl,
    'created_at': createdAt.toIso8601String(),
    'is_active': isActive,
  };
}
```

### 2.4 Switch Dependency Injection

In `lib/core/di/service_locator.dart`:

```dart
// BEFORE: Firebase
// getIt.registerSingleton<UserDataSource>(
//   FirebaseUserDataSource(firestore: getIt()),
// );

// AFTER: Supabase
getIt.registerSingleton<UserDataSource>(
  SupabaseUserDataSource(client: Supabase.instance.client),
);
```

### 2.5 Initialize Supabase in main.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  setupServiceLocator();
  
  runApp(const MainApp());
}
```

## Phase 3: Test & Deploy (Day 3)

### 3.1 Test All Features

```dart
// Test user creation
test('Create user in Supabase', () async {
  final repo = getIt<UserRepository>();
  final user = UserModel(
    id: 'test-user-123',
    email: 'test@example.com',
    name: 'Test User',
    createdAt: DateTime.now(),
    isActive: true,
  );
  
  final result = await repo.createUser(user);
  
  result.fold(
    (failure) => fail('Failed: ${failure.message}'),
    (user) => expect(user.email, 'test@example.com'),
  );
});
```

### 3.2 Run All Tests
```bash
flutter test
```

### 3.3 Stage Rollout

1. Deploy to beta testers first
2. Monitor for errors
3. Gradually roll out to production

### 3.4 Verify Performance

Compare before/after:
- Query speed: Usually faster with Supabase
- Cost: Should be 60-70% cheaper
- Reliability: Should be same or better

## Phase 4: Cleanup (After 2 weeks)

Once everything is stable:

1. Delete Firebase project
2. Stop paying for Firebase
3. Keep backups of data
4. Monitor Supabase usage

## Supabase Authentication

Unlike Firebase, Supabase uses JWT tokens:

```dart
class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> loginWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange;
  }
}
```

## Supabase Real-time

```dart
// Listen to real-time changes
final subscription = _client
    .from('users')
    .on(PostgresChangeEvent.all, filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: userId,
    ))
    .listen((payload) {
      // Handle changes
      final user = UserModel.fromSupabaseJson(payload.newRecord);
      print('User updated: ${user.name}');
    });

// Clean up
await subscription.cancel();
```

## Troubleshooting

**Q: "RLS policy prevents insert"**
A: Check RLS policies. Make sure authenticated user has insert permission.

**Q: "Column names don't match"**
A: Supabase uses snake_case. Convert: `photoUrl` → `photo_url`, `createdAt` → `created_at`.

**Q: "Realtime not working"**
A: Enable realtime for the table in Supabase dashboard. Table → Realtime → Enable.

**Q: "Migration failed halfway"**
A: Data is partially migrated. You can:
1. Delete all Supabase data and restart
2. Or manually fix the remaining records

## Cost Comparison

| Metric | Firebase | Supabase |
|--------|----------|----------|
| 1000 users | $25 | $0 (free tier) |
| 10k users | $300 | $100 |
| 100k users | $2000+ | $500 |
| Self-host | ❌ | ✅ |

## Next Steps

After successful migration:
1. Monitor Supabase dashboard
2. Optimize queries with indexes
3. Consider self-hosting for cost savings
4. Plan for scaling beyond Supabase

## Resources

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Pricing](https://supabase.com/pricing)
- [PostgreSQL Best Practices](https://www.postgresql.org/docs/current/plpgsql-best-practices.html)
- [RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
