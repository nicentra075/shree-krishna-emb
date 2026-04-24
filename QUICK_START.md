# Migration-Ready Architecture: Quick Start Guide

## What You Have Now

✅ **Migration-ready architecture** - You can now easily swap backends  
✅ **Firebase implementation** - Ready to use immediately  
✅ **Complete documentation** - All guides included  
✅ **Future-proof structure** - Node.js and Supabase code examples included  

## Getting Started (30 minutes)

### Step 1: Install Dependencies
```bash
cd shree_krishna_emb_user_app
flutter pub get
```

### Step 2: Set Up Firebase
1. Make sure Firebase is initialized in `main.dart` (already done)
2. Set up Firestore security rules in [Firebase Console](https://console.firebase.google.com)
3. Copy the rules from [FIREBASE_BACKEND_GUIDE.md](FIREBASE_BACKEND_GUIDE.md)

### Step 3: Initialize Service Locator

In `lib/core/di/service_locator.dart`, uncomment and complete:

```dart
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
  // Add more use cases as needed
}
```

Then call in `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  setupServiceLocator();  // Add this
  
  runApp(const MainApp());
}
```

### Step 4: Use in Your BLoC

```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase getUser;

  UserBloc(this.getUser) : super(UserInitial()) {
    on<GetUserEvent>((event, emit) async {
      emit(UserLoading());
      
      final result = await getUser(event.userId);
      
      result.fold(
        (failure) => emit(UserError(failure.message)),
        (user) => emit(UserLoaded(user)),
      );
    });
  }
}

// Register in service locator
getIt.registerSingleton<UserBloc>(
  UserBloc(getIt()),
);
```

### Step 5: Use in Your Widget

```dart
class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserBloc>()..add(GetUserEvent('user123')),
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const CircularProgressIndicator();
          }
          
          if (state is UserError) {
            return Text('Error: ${state.message}');
          }
          
          if (state is UserLoaded) {
            return Text('Welcome ${state.user.name}');
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

## Project Structure You Have

```
lib/
├── core/                      # Core, reusable code
│   ├── errors/
│   │   ├── exceptions.dart   # ServerException, NetworkException, etc.
│   │   └── failures.dart     # ServerFailure, NetworkFailure, etc.
│   ├── utils/
│   │   └── either.dart       # Either<Left, Right> for error handling
│   └── di/
│       └── service_locator.dart    # Dependency injection setup
│
├── data/                      # Backend communication layer
│   ├── datasources/
│   │   ├── firebase_user_datasource.dart     # ✅ Firebase (use now)
│   │   └── api_user_datasource.dart          # 🔮 Future migration
│   ├── models/
│   │   └── user_model.dart   # Has Firebase & API conversion methods
│   └── repositories/
│       └── user_repository_impl.dart         # Implements abstract repo
│
├── domain/                    # Business logic (backend agnostic)
│   ├── repositories/
│   │   └── user_repository.dart              # Abstract interface
│   └── usecases/
│       └── get_user_usecase.dart             # Business operations
│
├── presentation/              # UI code (never touches Firebase!)
│   ├── bloc/
│   │   └── user_bloc.dart    # State management
│   └── screens/
│       └── user_screen.dart  # UI widgets
│
└── main.dart                  # Entry point
```

## Key Files to Read

### 1. **Architecture Overview** (Start here)
📄 [ARCHITECTURE_GUIDE.md](ARCHITECTURE_GUIDE.md) - Full explanation of the pattern

### 2. **Firebase Setup** (For immediate use)
📄 [FIREBASE_BACKEND_GUIDE.md](FIREBASE_BACKEND_GUIDE.md) - All Firebase operations

### 3. **Cost Optimization** (As you scale)
📄 [FIREBASE_BEST_PRACTICES.md](FIREBASE_BEST_PRACTICES.md) - Save money, improve performance

### 4. **Migration Guides** (When ready to scale)
📄 [MIGRATION_TO_SUPABASE.md](MIGRATION_TO_SUPABASE.md) - 2-3 days to migrate  
📄 [MIGRATION_TO_NODEJS.md](MIGRATION_TO_NODEJS.md) - 3-5 days to migrate custom backend

## Adding a New Feature (e.g., Products)

### Step 1: Create Entity
```dart
// lib/domain/entities/product.dart
class ProductEntity {
  final String id;
  final String name;
  final double price;
  // ...
}
```

### Step 2: Create Model with Conversions
```dart
// lib/data/models/product_model.dart
class ProductModel extends ProductEntity {
  factory ProductModel.fromFirebaseJson(Map<String, dynamic> json) { ... }
  factory ProductModel.fromApiJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toFirebaseJson() { ... }
  Map<String, dynamic> toApiJson() { ... }
}
```

### Step 3: Create DataSource Interface & Firebase Implementation
```dart
// lib/data/datasources/firebase_product_datasource.dart
abstract class ProductDataSource {
  Future<ProductModel> getProduct(String id);
  Future<List<ProductModel>> getAllProducts();
  // ...
}

class FirebaseProductDataSource implements ProductDataSource {
  // Firebase implementation
}
```

### Step 4: Create Abstract Repository
```dart
// lib/domain/repositories/product_repository.dart
abstract class ProductRepository {
  Future<Either<Failure, ProductModel>> getProduct(String id);
  // ...
}
```

### Step 5: Create Repository Implementation
```dart
// lib/data/repositories/product_repository_impl.dart
class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;
  // Implementation
}
```

### Step 6: Register in Service Locator
```dart
getIt.registerSingleton<ProductDataSource>(
  FirebaseProductDataSource(firestore: getIt()),
);
getIt.registerSingleton<ProductRepository>(
  ProductRepositoryImpl(dataSource: getIt()),
);
```

### Step 7: Use in BLoC and UI
```dart
// In BLoC, use repository
final result = await productRepository.getProduct(id);

// In UI, use BLoC
BlocBuilder<ProductBloc, ProductState>( ... )
```

**That's it! When you migrate to Node.js/Supabase later, only step 6 changes.**

## Firestore Security Rules Quick Setup

Go to [Firebase Console](https://console.firebase.google.com) → Firestore Database → Rules, and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      allow read: if request.auth.token.admin == true;
    }
  }
}
```

## Testing Your Setup

```bash
# Build and run
flutter run

# Run tests
flutter test

# Check no Firebase leaks in BLoCs
grep -r "FirebaseFirestore" lib/presentation/  # Should be empty!
grep -r "FirebaseAuth" lib/presentation/       # Should be empty!
```

## Cost Tracking

| Metric | Free Tier | Paid Tier |
|--------|-----------|-----------|
| **Storage** | 1 GB | Pay per GB |
| **Reads** | 50k/day | $0.06 per 100k |
| **Writes** | 20k/day | $0.18 per 100k |
| **Deletes** | 20k/day | $0.02 per 100k |

**At 1,000 users:** ~$25/month  
**At 10,000 users:** ~$300/month → Time to migrate!

## Migration Readiness Checklist

- [x] Architecture supports backend swapping
- [x] Models have Firebase & API conversion methods
- [x] Repository interface is backend-agnostic
- [x] Service locator controls backend choice
- [x] No Firebase classes in presentation layer
- [x] Error handling with Either type
- [x] Documentation for all migrations included
- [x] Example code for Node.js API provided

## What's Next?

1. **Immediate:** Read [FIREBASE_BACKEND_GUIDE.md](FIREBASE_BACKEND_GUIDE.md) and start using Firebase
2. **Week 1:** Build your features using the architecture
3. **Month 2:** Monitor costs in Firebase Console
4. **Month 3+:** If costs exceed budget, follow migration guides

## FAQ

**Q: Can I use this architecture for both Admin and User apps?**  
A: Yes! Both apps should use this same pattern.

**Q: What if I don't want to migrate later?**  
A: Great! You still have the best Firebase practices and can scale indefinitely.

**Q: How do I handle authentication?**  
A: See [FIREBASE_BACKEND_GUIDE.md](FIREBASE_BACKEND_GUIDE.md) → Authentication section

**Q: Can I deploy to production now?**  
A: Yes! Set up security rules first, then deploy.

**Q: What about the admin app?**  
A: Same architecture. Create `shree_krishna_emb_admin/lib/core`, `lib/data`, `lib/domain` folders with same structure.

## Need Help?

- 📖 Read the comprehensive guides (they have examples)
- 🔍 Check existing code in `lib/data/datasources/firebase_user_datasource.dart`
- 🧪 Look at example models in `lib/data/models/user_model.dart`
- 📋 See error handling patterns in `lib/core/errors/`

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Run tests
flutter test

# Check for Firebase leaks in code
grep -r "firebase_core\|cloud_firestore\|firebase_auth" lib/presentation/

# Format code
dart format lib/

# Analyze code
flutter analyze
```

---

**You now have everything you need to build with Firebase, with a clear path to scale to Supabase or Node.js later. Happy coding! 🚀**
