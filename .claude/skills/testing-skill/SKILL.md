---
name: testing-skill
description: Use when implementing unit tests, widget tests, integration tests, BLoC tests, Firebase emulator setup, test coverage, and test fixtures for Flutter clean architecture.
argument-hint: [test type: unit, widget, integration, or bloc]
disable-model-invocation: true
---

## What This Skill Does

Generates comprehensive test suites for Flutter clean architecture with unit tests (domain & data), widget tests (UI), integration tests (Firebase emulator), BLoC tests, mocking, and fixtures.

**Features:**
- ✅ Unit tests for repositories, use cases, entities
- ✅ Widget tests for screens & UI components
- ✅ BLoC tests with state verification
- ✅ Integration tests with Firebase Emulator
- ✅ Mocking with mockito
- ✅ Test fixtures & factory patterns
- ✅ Firebase Emulator setup & teardown
- ✅ Test data builders
- ✅ Coverage reporting
- ✅ CI/CD test execution

## Test Structure

```
test/
├── unit/
│   ├── domain/
│   │   ├── usecases/
│   │   │   └── get_user_usecase_test.dart
│   │   └── repositories/
│   │       └── user_repository_test.dart
│   └── data/
│       ├── datasources/
│       │   └── firebase_user_datasource_test.dart
│       └── repositories/
│           └── user_repository_impl_test.dart
├── widget/
│   └── screens/
│       └── login_screen_test.dart
├── bloc/
│   └── user_bloc_test.dart
├── integration/
│   └── user_workflow_test.dart
└── fixtures/
    ├── user_fixtures.dart
    └── mock_providers.dart
```

## Step-by-Step Workflow

### 1. Set Up Test Dependencies

**File:** `pubspec.yaml`

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^6.1.5
  mocktail: ^1.0.0          # Better than mockito for Dart 3
  bloc_test: ^9.1.0
  firebase_core_platform_interface: ^4.8.0
  fake_cloud_firestore: ^1.3.0
  firebase_auth_mocks: ^0.12.0
```

Install:
```bash
flutter pub get
flutter pub global activate coverage
```

### 2. Create Test Fixtures (Factory Pattern)

**Path:** `test/fixtures/user_fixtures.dart`

```dart
// User test data
final testUser = UserModel(
  id: 'test-id',
  email: 'test@example.com',
  name: 'Test User',
  createdAt: DateTime(2026, 1, 1),
);

// Create custom user for tests
UserModel createTestUser({
  String id = 'test-id',
  String email = 'test@example.com',
  String name = 'Test User',
}) {
  return UserModel(
    id: id,
    email: email,
    name: name,
    createdAt: DateTime.now(),
  );
}
```

### 3. Create Mock Providers

**Path:** `test/fixtures/mock_providers.dart`

```dart
// Mocks for Firebase
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockDocumentReference extends Mock implements DocumentReference {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockQuerySnapshot extends Mock implements QuerySnapshot {}

// Mocks for repositories & use cases
class MockUserRepository extends Mock implements UserRepository {}
class MockGetUserUseCase extends Mock implements GetUserUseCase {}

// Mocks for auth
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
```

### 4. Unit Test Repository (Data Layer)

**Path:** `test/unit/data/repositories/user_repository_impl_test.dart`

```dart
void main() {
  late MockUserDataSource mockDataSource;
  late UserRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockUserDataSource();
    repository = UserRepositoryImpl(dataSource: mockDataSource);
  });

  group('UserRepositoryImpl', () {
    test('getUserById returns Right(UserModel) on success', () async {
      // Arrange
      when(mockDataSource.getUserById(any))
          .thenAnswer((_) async => testUser);

      // Act
      final result = await repository.getUserById('test-id');

      // Assert
      expect(result, Right(testUser));
      verify(mockDataSource.getUserById('test-id')).called(1);
    });

    test('getUserById returns Left(Failure) on ServerException', () async {
      // Arrange
      when(mockDataSource.getUserById(any))
          .thenThrow(ServerException(message: 'Error'));

      // Act
      final result = await repository.getUserById('test-id');

      // Assert
      expect(result, isA<Left<ServerFailure, UserModel>>());
      verify(mockDataSource.getUserById('test-id')).called(1);
    });
  });
}
```

### 5. Unit Test Use Case (Domain Layer)

**Path:** `test/unit/domain/usecases/get_user_usecase_test.dart`

```dart
void main() {
  late MockUserRepository mockRepository;
  late GetUserUseCase useCase;

  setUp(() {
    mockRepository = MockUserRepository();
    useCase = GetUserUseCase(mockRepository);
  });

  group('GetUserUseCase', () {
    test('calls repository.getUser with correct userId', () async {
      // Arrange
      when(mockRepository.getUserById(any))
          .thenAnswer((_) async => Right(testUser));

      // Act
      await useCase('test-id');

      // Assert
      verify(mockRepository.getUserById('test-id')).called(1);
    });

    test('returns Right(user) on success', () async {
      // Arrange
      when(mockRepository.getUserById(any))
          .thenAnswer((_) async => Right(testUser));

      // Act
      final result = await useCase('test-id');

      // Assert
      expect(result, Right(testUser));
    });
  });
}
```

### 6. BLoC Test

**Path:** `test/bloc/user_bloc_test.dart`

```dart
void main() {
  late MockGetUserUseCase mockGetUserUseCase;
  late UserBloc userBloc;

  setUp(() {
    mockGetUserUseCase = MockGetUserUseCase();
    userBloc = UserBloc(mockGetUserUseCase);
  });

  tearDown(() {
    userBloc.close();
  });

  group('UserBloc', () {
    blocTest<UserBloc, UserState>(
      'emits [UserLoading, UserLoaded] on GetUserEvent',
      build: () {
        when(mockGetUserUseCase(any))
            .thenAnswer((_) async => Right(testUser));
        return userBloc;
      },
      act: (bloc) => bloc.add(GetUserEvent('test-id')),
      expect: () => [
        UserLoading(),
        UserLoaded(testUser),
      ],
      verify: (_) {
        verify(mockGetUserUseCase('test-id')).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'emits [UserLoading, UserError] on exception',
      build: () {
        when(mockGetUserUseCase(any)).thenThrow(Exception('Error'));
        return userBloc;
      },
      act: (bloc) => bloc.add(GetUserEvent('test-id')),
      expect: () => [
        UserLoading(),
        isA<UserError>(),
      ],
    );
  });
}
```

### 7. Widget Test (UI Components)

**Path:** `test/widget/screens/login_screen_test.dart`

```dart
void main() {
  group('LoginScreen', () {
    testWidgets('displays email and password fields', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Find widgets
      expect(find.byType(AppTextField), findsWidgets);
      expect(find.byType(AppButton), findsWidgets);
    });

    testWidgets('shows loading indicator when submitting',
        (WidgetTester tester) async {
      // Create mock BLoC
      final mockAuthBloc = MockAuthBloc();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>(
            create: (_) => mockAuthBloc,
            child: LoginScreen(),
          ),
        ),
      );

      // Find and tap login button
      await tester.tap(find.byType(AppButton));
      await tester.pump(); // Rebuild after tap

      // Verify loading shown
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('validates email on submit', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginScreen(),
          ),
        ),
      );

      // Tap submit without entering email
      final submitButton = find.byType(AppButton);
      await tester.tap(submitButton);
      await tester.pump();

      // Verify error shown
      expect(find.text('Email is required'), findsWidgets);
    });
  });
}
```

### 8. Firebase Integration Test (With Emulator)

**Path:** `test/integration/user_workflow_test.dart`

```dart
void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserRepositoryImpl repository;

  setUpAll(() async {
    // Initialize fake Firestore
    fakeFirestore = FakeFirebaseFirestore();
    
    // Create repository with fake
    repository = UserRepositoryImpl(
      dataSource: FirebaseUserDataSource(firestore: fakeFirestore),
    );
  });

  group('User Integration Tests', () {
    test('can create and retrieve user', () async {
      // Arrange
      final newUser = createTestUser(id: 'new-id', email: 'new@example.com');

      // Act - Create user
      final createResult = await repository.createUser(newUser);
      expect(createResult, isA<Right>());

      // Act - Retrieve user
      final getResult = await repository.getUserById('new-id');

      // Assert
      expect(getResult, Right(newUser));
    });

    test('user data persists in Firestore', () async {
      // Use fake Firestore directly
      await fakeFirestore
          .collection('users')
          .doc('test-id')
          .set({'email': 'test@example.com', 'name': 'Test'});

      final doc = await fakeFirestore
          .collection('users')
          .doc('test-id')
          .get();

      expect(doc.exists, true);
      expect(doc['email'], 'test@example.com');
    });
  });
}
```

### 9. Set Up Real Firebase Emulator (Dev Testing)

**File:** `.firebaserc` or `firebase.json`

```json
{
  "projects": {
    "dev": "shree-krishna-emb-dev"
  },
  "emulators": {
    "firestore": {
      "port": 8080
    },
    "auth": {
      "port": 9099
    }
  }
}
```

**Run emulator:**
```bash
# First install Firebase CLI
curl -sL https://firebase.tools | bash

# Start emulators
firebase emulators:start

# In another terminal, run tests
flutter test --dart-define=USE_FIRESTORE_EMULATOR=true
```

### 10. Test Code That Uses Emulator

```dart
// lib/core/di/service_locator.dart
void setupServiceLocator() {
  const useEmulator = bool.fromEnvironment('USE_FIRESTORE_EMULATOR');
  
  final firestore = FirebaseFirestore.instance;
  
  if (useEmulator) {
    firestore.useFirestoreEmulator('localhost', 8080);
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }
  
  // Register normally
  getIt.registerSingleton<FirebaseFirestore>(firestore);
}
```

### 11. Run Tests & Generate Coverage

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/data/repositories/user_repository_impl_test.dart

# Run tests with coverage
flutter test --coverage

# Generate coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 12. Test Coverage Target

Aim for:
- **Unit tests:** 80%+ coverage on repositories, use cases
- **Widget tests:** 70%+ coverage on screens
- **Integration tests:** Key workflows (login, payment, payout)
- **Overall:** 70%+ coverage minimum

**In CI/CD:**
```bash
flutter test --coverage
lcov --list coverage/lcov.info
# Fail if coverage < 70%
```

### 13. CI/CD Integration (GitHub Actions)

**File:** `.github/workflows/test.yml`

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage/lcov.info
```

### 14. Test Best Practices

**Do:**
- ✅ Test at the layer closest to the feature (test repositories, not Firebase)
- ✅ Use fake/mock implementations for external services
- ✅ Name tests descriptively: `test('getUserById returns Right(user) on success')`
- ✅ Follow Arrange-Act-Assert pattern
- ✅ Use fixtures for repeated test data
- ✅ Test error paths, not just happy paths
- ✅ Cancel streams/subscriptions in tearDown
- ✅ Run tests before committing

**Don't:**
- ❌ Test framework code (don't test Flutter itself)
- ❌ Hit real APIs in tests (mock everything external)
- ❌ Test private methods directly
- ❌ Create data in tests (use fixtures)
- ❌ Make tests interdependent (each test standalone)
- ❌ Test UI colors/fonts (test behavior)

---

**Phase 1 MVP:** Unit + widget tests  
**Phase 2+:** Full integration tests, emulator setup, CI/CD

---

**Ready for test coverage!**
