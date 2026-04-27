# Phone Login Flow - Complete Validation ✅

## Overview
The phone login authentication flow has been **fully implemented and configured** from the Login screen through to the Home screen.

---

## 1. Login Screen → Send OTP
**File:** `lib/screens/auth/login_screen.dart`

### Flow:
1. User clicks "Phone" button on login screen
2. Dialog appears asking for phone number (10 digits only)
3. User enters phone number (e.g., `9876543210`)
4. Validation checks: exactly 10 digits ✅

### Code Flow:
```
LoginScreen._showPhoneInputDialog()
  → Validates phone with Validators.validatePhone()
  → Dispatches SendPhoneOtpEvent(phoneNumber: '+91$phone')
  → AuthBloc receives event
```

### Logging:
- 🔵 [LoginScreen] Phone Dialog - User entered: 9876543210
- 🔵 [LoginScreen] Phone Dialog - Sending to Firebase: +919876543210
- 🔵 [LoginScreen] Phone Dialog - SendPhoneOtpEvent dispatched

---

## 2. AuthBloc Handles SendPhoneOtpEvent
**File:** `lib/bloc/auth/auth_bloc.dart`

### Handler: `_onSendPhoneOtp()`
1. Emits `AuthLoading` state
2. Calls `SendPhoneOtpUseCase` with phone number
3. On success: Emits `AuthPhoneOtpSent(verificationId, phoneNumber)`
4. On failure: Emits `AuthError(message)`

### Logging:
- 🔵 [AuthBloc] _onSendPhoneOtp event received
- 🔵 [AuthBloc] Emitted AuthLoading state
- 🟢 [AuthBloc] SendPhoneOtp succeeded - VerificationId: xxxxx
- 🔴 [AuthBloc] SendPhoneOtp failed - Error: [message]

---

## 3. Firebase Auth Sends OTP
**File:** `lib/data/datasources/firebase_auth_datasource.dart`

### Method: `sendPhoneOtp(phoneNumber)`
- Uses `Completer<String>` to properly wait for Firebase callbacks
- Handles 4 Firebase callbacks:
  - ✅ `codeSent`: OTP code sent successfully
  - ✅ `codeAutoRetrievalTimeout`: Auto-retrieve timed out
  - ❌ `verificationFailed`: Firebase rejected the number
  - ✅ `verificationCompleted`: Auto-sign in (rare)

### Logging:
- 🟡 [FirebaseAuthDataSource] sendPhoneOtp called with: +919876543210
- 🟢 [FirebaseAuthDataSource] codeSent - Verification ID: xxxxx
- 🟠 [FirebaseAuthDataSource] codeAutoRetrievalTimeout - Verification ID: xxxxx
- 🔴 [FirebaseAuthDataSource] verificationFailed - Error: [code]

### Verification ID:
- 64-character string from Firebase
- Expires in 60 seconds
- Required for OTP verification

---

## 4. Navigation to OTP Verification Screen
**File:** `lib/routes/app_routes.dart`

### Trigger: LoginScreen BlocListener
When `AuthPhoneOtpSent` state received:
```dart
AppRoutes.push(context, AppRoutes.otpVerification, arguments: {
  'verificationId': state.verificationId,
  'phoneNumber': state.phoneNumber,
});
```

### Route Configuration:
- Route name: `/otp-verification`
- Screen: `OtpVerificationScreen`
- AuthBloc provided via `BlocProvider.value`
- Arguments passed to screen

---

## 5. OTP Verification Screen
**File:** `lib/screens/auth/otp_verification_screen.dart`

### Features:
✅ **6 individual digit input boxes** (Firebase sends 6-digit OTP)
✅ **Auto-focus navigation** - Tab between boxes
✅ **45-second countdown timer** - Shows "Resend code in X seconds"
✅ **Resend OTP button** - Available after countdown
✅ **Validation** - Must enter exactly 6 digits

### OTP Input:
- Box 1: First digit
- Box 2: Second digit
- Box 3: Third digit
- Box 4: Fourth digit
- Box 5: Fifth digit
- Box 6: Sixth digit

### Auto-Focus Flow:
```
User types digit → Focus moves to next box automatically
User deletes digit → Focus moves to previous box
```

### Logging:
- 🔵 [OtpVerificationScreen] OTP entered: 123456 (length: 6)
- 🔵 [OtpVerificationScreen] Dispatching VerifyPhoneOtpEvent

---

## 6. AuthBloc Handles VerifyPhoneOtpEvent
**File:** `lib/bloc/auth/auth_bloc.dart`

### Handler: `_onVerifyPhoneOtp()`
1. Emits `AuthLoading` state
2. Calls `VerifyPhoneOtpUseCase` with:
   - `verificationId`: From Firebase
   - `smsCode`: 6 digits user entered
   - `phoneNumber`: User's phone number
3. On success (new user): Emits `AuthNewPhoneUser`
4. On success (existing user): Emits `AuthAuthenticated`
5. On failure: Emits `AuthError`

---

## 7. Firebase Verifies OTP
**File:** `lib/data/datasources/firebase_auth_datasource.dart`

### Method: `verifyPhoneOtp()`
1. Creates `PhoneAuthCredential` from verification ID + OTP code
2. Signs in user: `firebaseAuth.signInWithCredential(credential)`
3. Checks if user exists in Firestore
4. **If new user:**
   - Creates `UserModel` with:
     - Sequential `userId` (from counter)
     - `loginMethod: 'phone'`
     - `phoneNumber` from event
     - `email: ''` (empty, to be filled later)
     - `name: null` (null, to be filled later)
   - Creates Firestore doc
   - Returns `AuthResult(user, isNewUser: true)`
5. **If existing user:**
   - Updates `loginAt` timestamp
   - Returns `AuthResult(user, isNewUser: false)`

---

## 8. Complete Profile Screen (New Phone Users Only)
**File:** `lib/screens/auth/complete_profile_screen.dart`

### When Triggered:
User verified OTP and is a **new phone user** → Must complete profile

### Phone Flow Layout:
- ✅ Read-only: Phone number (pre-filled from verification)
- ✅ Editable: Full Name (default: empty)
- ✅ Editable: Email Address (default: empty)

### Validation:
- Full Name: 2+ characters required
- Email: Valid RFC 5322 format required

### On Continue:
```dart
CompletePhoneProfileEvent(
  uid: firebaseUID,
  name: 'John Doe',
  email: 'john@example.com',
)
```

### AuthBloc Handler:
Calls `CompletePhoneProfileUseCase` → Updates Firestore doc with name & email

---

## 9. Final Navigation to Home
**File:** `lib/routes/app_routes.dart`

### Triggers for Navigation to Home:

**Case 1: Existing Phone User**
```
SendPhoneOtp → VerifyPhoneOtp → AuthAuthenticated → Home
(No complete profile screen)
```

**Case 2: New Phone User**
```
SendPhoneOtp → VerifyPhoneOtp → AuthNewPhoneUser 
  → CompleteProfile Screen → CompletePhoneProfileEvent 
  → AuthAuthenticated → Home
```

### Navigation Method:
```dart
AppRoutes.navigateToHome(context)
  → pushNamedAndRemoveUntil('/home')
  → Removes all previous routes (no back button)
```

---

## 10. Data Storage (Firestore)
**Collection:** `users/{firebase_uid}`

### Fields Created:
```dart
{
  "uid": "firebase_auth_uid",           // Firebase UID
  "userId": 12345,                      // Sequential unique ID
  "email": "john@example.com",          // Updated by complete profile
  "name": "John Doe",                   // Updated by complete profile
  "phoneNumber": "+919876543210",       // From verification
  "loginMethod": "phone",               // Identifies auth method
  "createdAt": "2026-04-27T10:30:00",  // Timestamp
  "loginAt": "2026-04-27T10:30:00",    // Latest login
  "logoutAt": null,                     // On logout
  "isActive": true                      // User status
}
```

### Counter Document:
**Collection:** `counters/user_id_counter`
```dart
{
  "count": 12345  // Incremented for each new user
}
```

---

## 11. Error Handling

### OTP Sending Errors:
| Error | Cause | Solution |
|-------|-------|----------|
| `verificationFailed` | Invalid phone number format | Check number starts with +91 and is 10 digits |
| `codeAutoRetrievalTimeout` | SMS not received in 60 seconds | User can resend OTP |
| `No AppCheckProvider` | Firebase App Check not configured | Warning only, doesn't block |
| `No Recaptcha siteKey` | reCAPTCHA not configured | Warning only, doesn't block |

### OTP Verification Errors:
| Error | Cause | Solution |
|-------|-------|----------|
| `invalid-verification-code` | Wrong OTP entered | User can request new OTP |
| `session-expired` | Verification ID expired (60s) | User must request new OTP |
| `verificationId is null` | Verification ID missing | Go back to send OTP again |

### Firebase Errors:
Caught by `_handleAuthException()` method and converted to user-friendly messages

---

## 12. Debug Logging Checklist

When testing, you should see these logs in order:

### ✅ Successful Flow:
```
🔵 [LoginScreen] Phone Dialog - User entered: 9876543210
🔵 [LoginScreen] Phone Dialog - Sending to Firebase: +919876543210
🔵 [LoginScreen] Phone Dialog - SendPhoneOtpEvent dispatched

🔵 [AuthBloc] _onSendPhoneOtp event received
🔵 [AuthBloc] Emitted AuthLoading state
🟣 [SendPhoneOtpUseCase] call() invoked with phoneNumber: +919876543210

🟡 [FirebaseAuthDataSource] sendPhoneOtp called with: +919876543210
🟢 [FirebaseAuthDataSource] codeSent - Verification ID: AD8T5Itmi7QA...
🟢 [FirebaseAuthDataSource] sendPhoneOtp completed successfully

🟢 [SendPhoneOtpUseCase] Repository returned verificationId: AD8T5Itmi7QA...
🟢 [AuthBloc] SendPhoneOtp succeeded - VerificationId: AD8T5Itmi7QA...
🟢 [AuthBloc] Emitted AuthPhoneOtpSent state

[Navigation to OTP Verification Screen]

🔵 [OtpVerificationScreen] OTP entered: 123456
🔵 [OtpVerificationScreen] Dispatching VerifyPhoneOtpEvent

[AuthBloc processes VerifyPhoneOtpEvent]

[If new user: Navigate to Complete Profile Screen]
[If existing user: Navigate to Home Screen]
```

### ❌ If OTP fails:
Look for 🔴 logs to identify exactly where it failed

---

## 13. Testing Checklist

- [ ] Enter valid phone number (10 digits)
- [ ] Receive OTP notification (or check Firebase Console)
- [ ] Enter 6 digits in OTP screen
- [ ] For new users: Complete name and email
- [ ] Verify navigated to Home screen
- [ ] Check Firestore user document created with correct data
- [ ] Test resend OTP (after countdown)
- [ ] Test existing user login (no complete profile screen)

---

## 14. Configuration Summary

| Component | Status | File |
|-----------|--------|------|
| Phone Number Input | ✅ Configured | login_screen.dart |
| SendPhoneOtpEvent | ✅ Configured | auth_event.dart |
| AuthPhoneOtpSent State | ✅ Configured | auth_state.dart |
| _onSendPhoneOtp Handler | ✅ Configured | auth_bloc.dart |
| SendPhoneOtpUseCase | ✅ Configured | auth_usecases.dart |
| sendPhoneOtp() DataSource | ✅ Configured | firebase_auth_datasource.dart |
| OTP Verification Screen | ✅ Configured (6 digits) | otp_verification_screen.dart |
| VerifyPhoneOtpEvent | ✅ Configured | auth_event.dart |
| _onVerifyPhoneOtp Handler | ✅ Configured | auth_bloc.dart |
| verifyPhoneOtp() DataSource | ✅ Configured | firebase_auth_datasource.dart |
| Complete Profile Screen | ✅ Configured | complete_profile_screen.dart |
| CompletePhoneProfileEvent | ✅ Configured | auth_event.dart |
| Navigation Routes | ✅ Configured | app_routes.dart |
| Service Locator | ✅ Configured | service_locator.dart |

---

## 15. Next Steps

1. **Enable Phone Authentication** in Firebase Console:
   - Go to Authentication → Sign-in method
   - Enable "Phone" provider
   - Save

2. **Test on Real Device** (optional):
   - Phone auth works best on real devices
   - Android emulator may not receive SMS

3. **Handle Errors**:
   - If "Failed to send OTP", check Firebase Console logs
   - Check phone number format: `+91` + 10 digits

4. **Production Setup**:
   - Configure Firebase App Check
   - Set up reCAPTCHA for phone auth
   - Test with multiple phone numbers

---

## Summary

✅ **Phone login flow is FULLY CONFIGURED and READY TO TEST**

All components are properly connected:
- LoginScreen → AuthBloc → FirebaseAuthDataSource → Firebase
- OTP Verification → AuthBloc → Firebase Verification
- Complete Profile → AuthBloc → Firestore Update
- Navigation flows to Home screen

The entire flow includes comprehensive logging at each step to help debug any issues.
