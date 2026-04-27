---
name: security-skill
description: Use when implementing Firebase security rules, input validation, authentication, data encryption, API key management, OWASP protection, XSS/injection prevention, and privacy compliance for Flutter apps.
argument-hint: [security feature: rules, validation, auth, encryption, or privacy]
disable-model-invocation: true
---

## What This Skill Does

Generates complete security implementation: Firestore rules, input validation, token management, encryption, API security, OWASP top 10 prevention, and data privacy/compliance.

**Features:**
- ✅ Firestore security rules (role-based, document-level)
- ✅ Input validation & sanitization
- ✅ Authentication token handling
- ✅ Data encryption (at-rest & in-transit)
- ✅ API key management (environment variables)
- ✅ OWASP top 10 protection
- ✅ XSS prevention (web)
- ✅ SQL injection prevention
- ✅ Rate limiting & abuse prevention
- ✅ Privacy compliance (GDPR, data deletion)

## Security Checklist

```
Before Deployment:
- [ ] All Firebase rules reviewed & tested
- [ ] No hardcoded secrets (API keys, tokens)
- [ ] Input validation on all user inputs
- [ ] Authentication required for sensitive actions
- [ ] HTTPS/TLS enforced everywhere
- [ ] Sensitive data not logged
- [ ] Rate limiting implemented
- [ ] No debug symbols in release build
- [ ] Privacy policy accessible
- [ ] Data deletion mechanism working

Production:
- [ ] HTTPS verified on all endpoints
- [ ] Firestore rules in production mode (not test)
- [ ] API keys restricted by domain/app
- [ ] Monitoring for suspicious activity
- [ ] Incident response plan ready
```

## Step-by-Step Workflow

### 1. Firestore Security Rules (Most Critical)

**File:** `firestore.rules`

Always start with **DENY ALL**, then allow specific operations:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Default: deny all
    match /{document=**} {
      allow read, write: if false;
    }
    
    // Users collection
    match /users/{userId} {
      // Users can read their own document
      allow read: if request.auth.uid == userId;
      
      // Users can update their own document
      allow update: if request.auth.uid == userId;
      
      // Only server can create (via Cloud Function)
      allow create: if false;
      allow delete: if false;
    }
    
    // Designs collection (public read, creator write)
    match /designs/{designId} {
      // Anyone can read published designs
      allow read: if resource.data.isPublished == true;
      
      // Creator can write
      allow write: if request.auth.uid == resource.data.createdBy;
      
      // Creators can create designs
      allow create: if request.auth.uid == request.resource.data.createdBy;
    }
    
    // Chat (only participants)
    match /chats/{chatId} {
      allow read: if request.auth.uid in resource.data.participantIds;
      allow update: if request.auth.uid in resource.data.participantIds;
    }
    
    // Messages in chats
    match /chats/{chatId}/messages/{messageId} {
      allow read: if request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participantIds;
      allow create: if request.auth.uid == request.resource.data.senderId;
      allow update, delete: if request.auth.uid == resource.data.senderId;
    }
    
    // Admin-only collections
    match /admin/{docId=**} {
      allow read, write: if hasRole(request.auth.uid, 'admin');
    }
    
    // Helper function: check user role
    function hasRole(userId, role) {
      return exists(/databases/$(database)/documents/users/$(userId))
        && get(/databases/$(database)/documents/users/$(userId)).data.role == role;
    }
  }
}
```

**Deploy rules:**
```bash
firebase deploy --only firestore:rules
```

**Test rules locally:**
```bash
firebase emulators:start
# Use Firebase Emulator UI to test rules
```

### 2. Input Validation (Prevent Injection Attacks)

**File:** `lib/core/utils/input_validator.dart`

```dart
class InputValidator {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }
  
  // Password validation (strong)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain number';
    }
    return null;
  }
  
  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone is required';
    }
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[^0-9]'), ''))) {
      return 'Phone must be valid 10-digit number';
    }
    return null;
  }
  
  // Sanitize text input (prevent XSS in web)
  static String sanitize(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }
  
  // Validate text length (prevent long strings)
  static String? validateLength(String? value, {int maxLength = 1000}) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    if (value.length > maxLength) {
      return 'Must be under $maxLength characters';
    }
    return null;
  }
}
```

**Use in AppTextField:**
```dart
AppTextField(
  label: 'Email',
  controller: emailController,
  validator: InputValidator.validateEmail,
)
```

### 3. Authentication & Token Management

**NEVER store tokens in SharedPreferences alone** (vulnerable to device theft).

**Secure storage hierarchy:**
```
1. iOS KeyChain (most secure)
2. Android Keystore (hardware-backed if available)
3. Flutter Secure Storage (lib: flutter_secure_storage)
4. Last resort: SharedPreferences (for non-sensitive data only)
```

**File:** `lib/core/utils/secure_token_storage.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  static const _authTokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  
  final _storage = const FlutterSecureStorage();
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: _authTokenKey);
  }
  
  Future<void> deleteToken() async {
    await _storage.delete(key: _authTokenKey);
  }
  
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }
  
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

**Use in BLoC:**
```dart
final token = await _tokenStorage.getToken();
if (token != null) {
  // Verify token is not expired
  final decoded = JwtDecoder.decode(token);
  final expiry = DateTime.fromMillisecondsSinceEpoch(decoded['exp'] * 1000);
  if (expiry.isBefore(DateTime.now())) {
    // Token expired, refresh
    await _refreshToken();
  }
}
```

### 4. API Key Management

**NEVER hardcode API keys.**

**File:** `.env` (NEVER commit to git)
```
RAZORPAY_KEY=rzp_live_1234567890
FIREBASE_API_KEY=AIzaSy...
MAPS_API_KEY=...
```

**File:** `.gitignore`
```
.env
.env.local
android/key.properties
ios/Certificates/
build/
```

**File:** `lib/core/config/app_config.dart`

```dart
class AppConfig {
  static const String razorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY',
    defaultValue: '', // Empty = app will fail gracefully
  );
  
  static const String mapsApiKey = String.fromEnvironment('MAPS_API_KEY');
  
  static bool get isProduction => String.fromEnvironment('ENV') == 'prod';
  
  static bool get isDevelopment => !isProduction;
}
```

**Build with environment variables:**
```bash
flutter build apk --release \
  --dart-define=RAZORPAY_KEY=rzp_live_... \
  --dart-define=ENV=prod

# Or use .env file with dart_dotenv
flutter pub add dotenv
```

### 5. Data Encryption at Rest

**For sensitive user data:**

```dart
import 'package:encrypt/encrypt.dart' as encrypt;

class DataEncryption {
  static final key = encrypt.Key.fromBase64(
    String.fromEnvironment('ENCRYPTION_KEY'),
  );
  static final iv = encrypt.IV.fromBase64(
    String.fromEnvironment('ENCRYPTION_IV'),
  );
  
  static String encryptData(String plaintext) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return encrypted.base64;
  }
  
  static String decryptData(String ciphertext) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt64(ciphertext, iv: iv);
    return decrypted;
  }
}
```

**Use for sensitive fields:**
```dart
// Encrypt before storing in Firestore
final encryptedPhone = DataEncryption.encryptData(phoneNumber);
await firestore.collection('users').doc(userId).set({
  'phone': encryptedPhone, // Stored encrypted
});

// Decrypt when reading
final decryptedPhone = DataEncryption.decryptData(doc['phone']);
```

### 6. Rate Limiting (Prevent Abuse)

**Firebase Cloud Function example:**

```javascript
// functions/src/rateLimiter.js
const admin = require('firebase-admin');

const RATE_LIMIT = 5; // 5 requests
const WINDOW_MS = 60 * 1000; // per minute

async function isRateLimited(userId) {
  const ref = admin.firestore()
    .collection('rate_limits')
    .doc(userId);
  
  const doc = await ref.get();
  const now = Date.now();
  
  if (!doc.exists) {
    await ref.set({ count: 1, resetAt: now + WINDOW_MS });
    return false;
  }
  
  const data = doc.data();
  if (now > data.resetAt) {
    // Window expired, reset
    await ref.set({ count: 1, resetAt: now + WINDOW_MS });
    return false;
  }
  
  if (data.count >= RATE_LIMIT) {
    return true; // Rate limited
  }
  
  // Increment
  await ref.update({ count: data.count + 1 });
  return false;
}

module.exports = { isRateLimited };
```

### 7. OWASP Top 10 Protection

| Threat | Solution |
|--------|----------|
| A01: Broken Auth | Use Firebase Auth, MFA, secure token storage |
| A02: Injection | Input validation, parameterized queries, sanitization |
| A03: Broken Access | Firestore rules (role-based), BLoC auth checks |
| A04: Insecure Design | Security by design, threat modeling |
| A05: Crypto Failures | TLS/HTTPS always, encrypt sensitive data |
| A06: Broken Auth (continued) | Rate limiting, account lockout |
| A07: Injection (continued) | Never concatenate SQL/queries, use APIs |
| A08: SAST/DAST | Use `flutter analyze`, security scanning |
| A09: Logging/Monitoring | Log security events, monitor for attacks |
| A10: SSRF/Untrusted Data | Validate API responses, use VPN for Firebase |

### 8. XSS Prevention (Web Admin App)

**In web, sanitize all user input:**

```dart
// Don't do this:
Html.div()..innerHtml = userInput; // XSS vulnerability

// Do this:
Html.div()..text = userInput; // Text only, no HTML
```

**For rich text, use a safe library:**
```dart
import 'package:flutter_markdown/flutter_markdown.dart';

MarkdownBody(
  data: userMarkdown, // Use markdown, not HTML
)
```

### 9. Logging Security Best Practices

**DO log:**
- Authentication attempts (with hashed user ID)
- Failed access attempts
- Admin actions

**DON'T log:**
- Passwords, tokens, API keys
- Sensitive user data (phone, email for non-admins)
- Full error messages (might leak info)

```dart
// ✅ Good
FirebaseCrashlytics.instance.log('User authentication attempt for ID: $hashedUserId');
FirebaseCrashlytics.instance.log('Payout request created for amount: \$500');

// ❌ Bad
FirebaseCrashlytics.instance.log('User password: $password');
FirebaseCrashlytics.instance.log('API key: $apiKey');
print('User $email signed in'); // Never print sensitive data
```

### 10. Privacy & GDPR Compliance

**Provide user controls:**
1. View their data
2. Download their data (right to data portability)
3. Delete their data (right to deletion)

**File:** `lib/domain/usecases/delete_user_usecase.dart`

```dart
class DeleteUserUseCase {
  final UserRepository userRepo;
  final ChatRepository chatRepo;
  
  DeleteUserUseCase(this.userRepo, this.chatRepo);
  
  Future<Either<Failure, void>> call(String userId) async {
    try {
      // Delete all user data
      await userRepo.deleteUser(userId);
      await chatRepo.deleteUserChats(userId);
      // Delete from Firebase Auth
      await FirebaseAuth.instance.currentUser?.delete();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
```

**Privacy Policy:**
- Link in app settings
- Describe data collection
- Explain Firebase/Third-party usage
- Provide deletion/export mechanism

### 11. Third-Party Security Audits

For Phase 2+, conduct:
- **Code audit:** Security review of critical paths
- **Penetration testing:** Professional testing
- **Dependency scanning:** Check packages for vulnerabilities

```bash
# Scan Flutter packages for vulnerabilities
dart pub global activate dart_code_checker
dart_code_checker --fail-on-issues lib/

# Check Android/iOS dependencies
./gradlew dependencyCheck  # Android
pod audit  # iOS
```

### 12. Secure Development Practices

- Use signed git commits: `git commit -S`
- Never commit secrets: Use `.gitignore` + `git-secrets`
- Code review all changes: PR required
- Use branch protection: Require reviews before merge
- Automated security scanning: GitHub Actions

**GitHub Actions Security Scan:**
```yaml
name: Security Scan
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart analyze lib/ --fatal-infos
      - name: Check for hardcoded secrets
        run: |
          if grep -r "const.*=.*['\"]rzp_live\|AIza\|firebase_key" lib/; then
            echo "ERROR: Hardcoded secrets found!"; exit 1
          fi
```

---

**Phase 1 MVP:**
- Basic Firestore rules
- Input validation
- Token management
- API key environment variables

**Phase 2+:**
- Full encryption
- Rate limiting
- Privacy controls
- Security audit

---

**Ready to secure the app!**
