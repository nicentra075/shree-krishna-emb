---
name: deployment-skill
description: Use when building and deploying Flutter apps to Android (Play Store), iOS (App Store), web (Firebase Hosting/Vercel), signing, versioning, CI/CD setup, and release management.
argument-hint: [deployment target: android, ios, web, or all]
disable-model-invocation: true
---

## What This Skill Does

Generates complete deployment pipeline for Flutter apps: signing, versioning, building APK/IPA/web, uploading to stores, CI/CD with GitHub Actions, and release management.

**Features:**
- ✅ App signing (Android keystore, iOS certificates)
- ✅ Version management (pubspec.yaml, Android/iOS native)
- ✅ APK/AAB builds for Play Store
- ✅ IPA builds for App Store
- ✅ Web builds for Firebase Hosting
- ✅ GitHub Actions CI/CD
- ✅ Store upload automation
- ✅ Beta testing (TestFlight, Play Console)
- ✅ Release notes generation
- ✅ Rollback procedures

## Deployment Checklist

```
Pre-Deployment:
- [ ] All tests passing (flutter test)
- [ ] Code analyzed (flutter analyze)
- [ ] No debug prints or hardcoded tokens
- [ ] Bump version in pubspec.yaml
- [ ] Update native versions (Android/iOS)
- [ ] Update CHANGELOG.md
- [ ] Tag git commit
- [ ] Perform manual testing on device

Deployment:
- [ ] Build APK/AAB (Android)
- [ ] Build IPA (iOS)
- [ ] Build web (if applicable)
- [ ] Sign releases
- [ ] Upload to stores
- [ ] Monitor for crashes

Post-Deployment:
- [ ] Verify on stores (view app listing)
- [ ] Monitor analytics
- [ ] Rollback plan ready
```

## Step-by-Step Workflow

### 1. Versioning Strategy

**File:** `pubspec.yaml`

```yaml
version: 1.0.0+1
# Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
# iOS: 1.0.0 (major.minor.patch)
# Android: build_number (incrementing)
```

**Semantic Versioning:**
- `1.0.0` — Initial release
- `1.1.0` — New features (Phase 2 MVP)
- `1.0.1` — Bug fix
- `2.0.0` — Breaking changes

**Update process:**
```bash
# Before release
# 1. Update pubspec.yaml
# 2. Update CHANGELOG.md
# 3. Commit: "chore: bump version to 1.0.0"
# 4. Tag: git tag v1.0.0
# 5. Push: git push origin main --tags
```

### 2. Android Signing Setup

**Generate keystore (one-time):**
```bash
keytool -genkey -v -keystore ~/shree-krishna-app-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias shree_krishna_key
```

Store safely (backup to password manager).

**File:** `android/key.properties`

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=shree_krishna_key
storeFile=/Users/YOUR_USERNAME/shree-krishna-app-key.jks
```

**Never commit `key.properties` to git.**

**File:** `android/app/build.gradle`

```gradle
android {
  signingConfigs {
    release {
      keyAlias keystoreProperties['keyAlias']
      keyPassword keystoreProperties['keyPassword']
      storeFile file(keystoreProperties['storeFile'])
      storePassword keystoreProperties['storePassword']
    }
  }
  
  buildTypes {
    release {
      signingConfig signingConfigs.release
      shrinkResources true
      minifyEnabled true
      proguardFiles getDefaultProguardFile(
        'proguard-android-optimize.txt'),
        'proguard-rules.pro'
    }
  }
}
```

### 3. iOS Signing Setup

Requires Apple Developer account ($99/year).

**Steps:**
1. Go to [developer.apple.com/account](https://developer.apple.com/account)
2. Create App ID for your app
3. Create provisioning profiles (development + distribution)
4. Download certificates (.p8)
5. Import to Xcode

**Xcode configuration:**
```bash
cd ios
open Runner.xcworkspace # Use workspace, not .xcodeproj

# In Xcode:
# Runner → Signing & Capabilities
# Team: Select your team
# Bundle ID: com.example.shreekrishna
# Provisioning Profile: Select distribution profile
```

### 4. Build for Android (APK for Testing)

```bash
flutter build apk --release

# Output: build/app/outputs/flutter-app.apk

# Test on device
adb install build/app/outputs/flutter-app.apk
```

### 5. Build for Android (AAB for Play Store)

App Bundle is required by Play Store:

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 6. Build for iOS

```bash
flutter build ios --release

# Output: build/ios/iphoneos/Runner.app

# Generate IPA
cd build/ios/iphoneos
mkdir -p Payload
mv Runner.app Payload/
zip -r -y app.ipa Payload
```

Or use Xcode directly:
```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -derivedDataPath build/ios \
  -archivePath build/ios/Runner.xcarchive \
  archive

# Export archive
xcodebuild -exportArchive \
  -archivePath build/ios/Runner.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath build/ios/ipa
```

### 7. Build for Web (Admin App)

```bash
# Build web version
flutter build web --release

# Output: build/web/

# Test locally
python -m http.server -d build/web 8080
# Open http://localhost:8080
```

### 8. Deploy Web to Firebase Hosting

**Setup (one-time):**
```bash
npm install -g firebase-tools
firebase login
firebase init hosting

# When prompted, configure:
# Public directory: build/web
# SPA: yes (rewrite all to index.html)
```

**File:** `firebase.json`

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

**Deploy:**
```bash
flutter build web --release
firebase deploy --only hosting
```

### 9. Upload to Google Play Store

**Setup (one-time):**
1. Create Google Play Developer account ($25)
2. Set up billing
3. Create app in Play Console
4. Fill out app information, privacy policy, screenshots
5. Generate Play Store API key

**Upload AAB:**
```bash
flutter build appbundle --release

# Then in Play Console:
# Internal Testing → Upload AAB → Test → Release to Production
```

**Or via command line (fastlane):**
```bash
# Install fastlane
sudo gem install fastlane

# Setup
cd android
fastlane init

# Deploy
fastlane deploy
```

### 10. Upload to Apple App Store

**Setup (one-time):**
1. Create Apple Developer account ($99/year)
2. Create App ID in App Store Connect
3. Create provisioning profiles
4. Generate App Store API key

**Upload IPA:**
```bash
# Build IPA
flutter build ios --release

# Use Xcode or Transporter
# Xcode: Product → Archive → Distribute App
# Or via CLI with fastlane:

cd ios
fastlane deploy_to_testflight
fastlane deploy_to_appstore
```

### 11. CI/CD with GitHub Actions

**File:** `.github/workflows/build-and-deploy.yml`

```yaml
name: Build & Deploy
on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3

  build-android:
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - name: Build APK
        run: flutter build apk --release
      - name: Build AAB
        run: flutter build appbundle --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-builds
          path: build/app/outputs/

  build-ios:
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ios --release
      - uses: actions/upload-artifact@v3
        with:
          name: ios-build
          path: build/ios/iphoneos/

  build-web:
    if: startsWith(github.ref, 'refs/tags/v')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build web --release
      - name: Deploy to Firebase
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only hosting
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

### 12. Release Notes Generation

**File:** `CHANGELOG.md`

```markdown
## [1.0.0] - 2026-01-15

### Added
- User app marketplace
- Designer onboarding
- Payment integration (Razorpay)
- Real-time chat
- Admin dashboard

### Fixed
- Login error handling
- Image upload timeout

### Changed
- Updated design system colors
- Improved search performance

### Deprecated
- Email login (use OTP instead)

## [0.9.0-beta] - 2026-01-01
- Beta release for testing
```

When releasing:
```bash
# Generate from commit history
git log --oneline v0.9.0..HEAD > release_notes.txt

# Edit, then:
git tag -a v1.0.0 -m "Release v1.0.0

Features:
- Marketplace redesign
- Mobile payments

Bug fixes:
- Fixed image upload
- Improved performance"
```

### 13. Environment Variables & Secrets

Store sensitive data in environment variables, NOT in code:

```bash
# Don't do this:
const RAZORPAY_KEY = "rzp_live_1234567890";

# Do this:
const RAZORPAY_KEY = String.fromEnvironment('RAZORPAY_KEY');

# Build with:
flutter build apk --release \
  -dart-define=RAZORPAY_KEY=rzp_live_1234567890
```

**GitHub Secrets (for CI/CD):**
```bash
# In GitHub repo:
# Settings → Secrets → New repository secret
# FIREBASE_TOKEN=...
# PLAY_STORE_KEY=...
# APPLE_API_KEY=...
```

### 14. Rollback Procedure

If critical bug found post-deployment:

**Android:**
1. Go to Play Console → Release → App Releases → Production
2. Click "Manage" → Select version
3. "Pause rollout" or "Halt rollout"
4. Fix bug, bump version
5. Build & upload new AAB

**iOS:**
1. Go to App Store Connect → TestFlight
2. Remove current build from External Testers
3. Fix bug, bump version
4. Build & upload to TestFlight
5. Test, then submit to App Store

**Web:**
```bash
# Redeploy previous version
firebase hosting:channel:deploy prev-version \
  --expires 24h
# Then rollback in Firebase Console
```

### 15. Monitoring Post-Deployment

**Firebase Crashlytics:**
```dart
// Log errors automatically
FirebaseCrashlytics.instance.recordError(error, stackTrace);
```

**Google Analytics:**
```dart
// Track app opens
FirebaseAnalytics.instance.logAppOpen();

// Track user actions
FirebaseAnalytics.instance.logEvent(
  name: 'design_viewed',
  parameters: {'design_id': designId},
);
```

---

**Phase 1 MVP:**
- Android & iOS builds (internal testing)
- Basic store listings
- Manual deployment

**Phase 2+:**
- Full CI/CD automation
- TestFlight beta testing
- Play Store staged rollout
- Web deployment

---

**Ready to ship!**
