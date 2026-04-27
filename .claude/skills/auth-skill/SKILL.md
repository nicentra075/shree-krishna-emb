---
name: auth-skill
description: Use when implementing authentication features like email/OTP sign-up, social login (Google/Apple), user role selection, token management, and session handling with Firebase Auth.
argument-hint: [auth flow type or user requirement]
disable-model-invocation: true
---

## What This Skill Does

Generates complete authentication flows for Shree Krishna EMB with Firebase Auth, supporting email/OTP login, social login (Google/Apple), role selection (Buyer/Seller), secure token management, and proper error handling.

**Features:**
- ✅ Email/Phone OTP authentication
- ✅ Google & Apple social login
- ✅ Role selection (End-User/Designer)
- ✅ Secure token refresh & storage
- ✅ Session management
- ✅ Error handling with proper UI feedback
- ✅ Offline support detection
- ✅ 2FA for admin login
- ✅ Firebase Auth integration
- ✅ BLoC state management

## Step-by-Step Workflow

### Step 1: Understand Auth Requirements
- Which auth method? (Email, Phone, Social, All)
- Role selection needed?
- Is this for End-User, Designer, or Admin?
- Token refresh strategy?
- Session timeout duration?

### Step 2: Design Auth Flow
- Define authentication method (email/OTP, Google/Apple, combined)
- Plan role selection screen (Step 2 of signup if needed)
- Define token storage (SharedPreferences or Hive)
- Plan logout & session expiry

### Step 3: Generate Firebase Auth Setup
```dart
// Authentication methods to implement
- EmailPasswordAuth (for admin login)
- PhoneOTPAuth (for user/designer signup)
- GoogleSignIn integration
- AppleSignIn integration
```

### Step 4: Generate Auth Service

**Path:** `lib/data/datasources/auth_datasource.dart`

Create abstract interface + Firebase implementation:
- `signupWithEmail(email, password)`
- `loginWithEmail(email, password)`
- `signupWithPhone(phoneNumber)`
- `verifyOTP(verificationId, smsCode)`
- `signupWithGoogle()`
- `signupWithApple()`
- `logout()`
- `refreshToken()`
- `getCurrentUser()`
- `updateUserRole(role)`
- Stream for auth state changes

### Step 5: Generate Auth Entities & Models

**Entity:** `lib/domain/entities/auth_user.dart`
- userId
- email/phoneNumber
- displayName
- photoUrl
- role (Buyer/Seller/Admin)
- isVerified
- createdAt

**Model:** `lib/data/models/auth_user_model.dart`
- Extends AuthUserEntity
- Firebase & API serialization

### Step 6: Generate Auth Repository

**Interface:** `lib/domain/repositories/auth_repository.dart`
- All auth methods returning `Either<Failure, AuthUser>`

**Implementation:** `lib/data/repositories/auth_repository_impl.dart`
- Wrap FirebaseAuthDataSource
- Handle exceptions → Failures
- Store auth state locally

### Step 7: Generate Auth BLoCs

Create:
- `AuthBloc` - Main auth state
- `PhoneAuthBloc` - OTP flow (phone signup)
- `SocialAuthBloc` - Google/Apple login
- `SessionBloc` - Session & token management

**States:**
- AuthInitial, AuthLoading, AuthSuccess, AuthError
- PhoneOTPSent, OTPVerifying, OTPVerified
- TokenValid, TokenExpired, TokenRefreshing
- LoggedOut

### Step 8: Generate Auth UI Screens

**Paths:**
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/signup_phone_screen.dart`
- `lib/screens/auth/otp_verification_screen.dart`
- `lib/screens/auth/signup_details_screen.dart`
- `lib/screens/auth/role_selection_screen.dart`
- `lib/screens/auth/admin_login_screen.dart` (2FA)

**Features:**
- Form validation
- Loading states
- Error messages with retry
- Social login buttons
- Localized UI (AppLocalization)
- Design system components

### Step 9: Implement Token Management

**Path:** `lib/core/utils/secure_token_storage.dart`

- Store accessToken + refreshToken securely
- Implement token refresh logic
- Handle token expiry
- Auto-refresh on API calls (via interceptor)

### Step 10: Add Firebase Auth Setup

**In `main.dart`:**
```dart
// Setup Firebase Auth
FirebaseAuth.instance.settings = const FirebaseAuthSettings(
  appVerificationDisabledForTesting: false,
);

// Enable app linking for social auth
```

### Step 11: Generate Auth BLoC Handlers

**Phone OTP Flow:**
1. User enters phone → `SendOTPEvent`
2. Firebase sends OTP → Show OTP input screen
3. User enters OTP → `VerifyOTPEvent`
4. Firebase verifies → Create user account
5. Show role selection screen

**Social Login:**
1. User taps Google/Apple → `SignupWithGoogleEvent`
2. Firebase social login → Get user data
3. Show role selection screen
4. Create user document in Firestore

### Step 12: Setup Service Locator

```dart
// Auth sources
getIt.registerSingleton<AuthDataSource>(
  FirebaseAuthDataSource(auth: getIt()),
);

// Auth repositories
getIt.registerSingleton<AuthRepository>(
  AuthRepositoryImpl(dataSource: getIt()),
);

// Auth BLoCs
getIt.registerSingleton<AuthBloc>(AuthBloc(getIt()));
getIt.registerSingleton<PhoneAuthBloc>(PhoneAuthBloc(getIt()));
getIt.registerSingleton<SocialAuthBloc>(SocialAuthBloc(getIt()));
getIt.registerSingleton<SessionBloc>(SessionBloc(getIt()));
```

### Step 13: Add Security Measures

- Rate limiting on OTP requests
- OTP expiry (5-10 minutes)
- Password validation rules
- Secure password storage (Firebase handles this)
- Prevent brute-force attacks
- Add CAPTCHA if needed

### Step 14: Generate Authentication Routes

**Path:** `lib/routes/auth_routes.dart`

Define:
- `/login` → LoginScreen
- `/signup/phone` → SignupPhoneScreen
- `/otp-verify` → OTPVerificationScreen
- `/signup/details` → SignupDetailsScreen
- `/role-select` → RoleSelectionScreen
- `/admin-login` → AdminLoginScreen

### Step 15: Add Auth Guards

Create route guards to protect routes:
- Require authentication
- Require specific role (Admin, Designer, User)
- Handle unauthenticated access

### Step 16: Implement Logout & Session Cleanup

**On Logout:**
- Clear stored tokens
- Sign out from Firebase
- Clear user data from BLoCs
- Navigate to login screen
- Clear any sensitive data

### Step 17: Generate Use Cases

- `SignupWithPhoneUseCase`
- `LoginWithEmailUseCase`
- `SignupWithGoogleUseCase`
- `VerifyOTPUseCase`
- `SelectRoleUseCase`
- `LogoutUseCase`
- `RefreshTokenUseCase`

### Step 18: Provide Documentation

Output summary with:
- Auth flow diagrams (phone, email, social)
- Firebase setup required
- iOS/Android specific setup (for social login)
- Environment variables needed
- Testing recommendations

---

## Guardrails & Best Practices

**MUST:**
- ✅ Never store passwords in plain text
- ✅ Always validate email format & phone number
- ✅ Rate limit OTP attempts (max 3 per hour per phone)
- ✅ Use HTTPS for all auth requests
- ✅ Validate tokens on backend (Firebase)
- ✅ Handle token refresh transparently
- ✅ Log auth errors for security monitoring

**NEVER:**
- ❌ Expose refresh tokens in logs
- ❌ Send passwords in URLs
- ❌ Store tokens in SharedPreferences unencrypted (use Secure Storage)
- ❌ Trust client-side token validation alone
- ❌ Skip Firebase security rules

**Warn About:**
- Firebase social auth setup (iOS/Android needs special config)
- APK signing required for Google Sign-In
- Apple Sign-In certificate setup needed

---

## Phase 1 MVP Checklist

For Phase 1, implement:
- ✅ Email/OTP signup
- ✅ Google/Apple social login
- ✅ Role selection (Buyer vs Seller toggle)
- ✅ Basic token management
- ✅ Session handling
- ⏭️ 2FA admin login (Phase 2)

---

**Ready! Describe your auth needs or ask about specific flows.**
