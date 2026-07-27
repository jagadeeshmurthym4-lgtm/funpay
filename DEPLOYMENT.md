# Fun Pay Deployment Guide

## Prerequisites
- Flutter SDK 3.5.4+
- Firebase CLI
- Android Studio / Xcode
- Firebase project created

## Step 1: Firebase Configuration

### Android
1. Place `google-services.json` in `android/app/`
2. Ensure `android/app/build.gradle` has:
```gradle
defaultConfig {
    applicationId "com.funpay.app"
    minSdk 23
    targetSdk 34
}
```

### iOS
1. Place `GoogleService-Info.plist` in `ios/Runner/`
2. Update bundle identifier in Xcode

## Step 2: Environment Configuration

### Create .env or configure constants:
- Update `lib/core/constants/app_constants.dart` with your app name (already set to 'Fun Pay')
- Configure Firebase project settings

## Step 3: Build Release

### Android APK
```bash
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS (App Store)
```bash
flutter build ios --release --no-codesign
# Open ios/Runner.xcworkspace in Xcode
# Configure signing & upload
```

## Step 4: Firebase Deploy (Spark Free Plan)

### Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```

### Hosting
```bash
flutter build web --release

# Copy .well-known files for deep linking verification before deploying hosting
cp -r hosting/.well-known build/web/.well-known

firebase deploy --only hosting
```

**Notes:**
- The app runs entirely on Firestore (50k reads/day free), Firebase Auth, and Hosting on Spark plan.
- Custom tasks with admin review are handled via Firestore collections (`custom_tasks`, `task_submissions`).

## Deep Linking Setup (Password Reset & Email Verification)

Deep linking allows password reset and email verification links to open the app directly on mobile instead of a browser.

### Android Configuration
1. **Get your SHA-256 fingerprint** from your release keystore:
   ```bash
   keytool -list -v -keystore <path-to-keystore> -alias <key-alias> | grep "SHA256:"
   ```
2. **Add the fingerprint** to Firebase Console:
   - Go to **Project Settings > Your apps > Android app**
   - Click **Add fingerprint** and paste your SHA-256
3. **Update `hosting/.well-known/assetlinks.json`** with your SHA-256 fingerprint
4. **Deploy hosting** (see steps above)
5. **Verify** the file is accessible:
   ```bash
   curl https://cashspark-c15bd.firebaseapp.com/.well-known/assetlinks.json
   ```

### iOS Configuration
1. **Find your Apple Team ID** (Apple Developer account > Membership > Team ID)
2. **Update `hosting/.well-known/apple-app-site-association`**:
   - Replace `YOUR_TEAM_ID` with your actual Apple Team ID
   - The `appID` should be `TEAM_ID.com.spydev.funpay`
3. **Deploy hosting** (see steps above)
4. **Open in Xcode**: The entitlements file (`ios/Runner/Runner.entitlements`) will be automatically picked up when you open `ios/Runner.xcworkspace` in Xcode
5. **Verify Associated Domains**: Go to Xcode > Runner target > Signing & Capabilities > Associated Domains
   - Should show `applinks:cashspark-c15bd.firebaseapp.com`
6. **Verify** the file is accessible:
   ```bash
   curl https://cashspark-c15bd.firebaseapp.com/.well-known/apple-app-site-association
   ```

### How It Works
1. User requests password reset → Firebase sends email with link to `https://cashspark-c15bd.firebaseapp.com/__/auth/action?...`
2. On Android: The intent filter catches the URL → app opens → Firebase Auth SDK processes the OOB code
3. On iOS: Universal Links catches the URL → app opens → Firebase Auth SDK processes the OOB code
4. The `ActionCodeSettings` configured with `handleCodeInApp: true` + package names enables this behavior

## Step 5: Play Store Preparation

### Checklist
- [ ] Privacy Policy added to app and Play Store listing
- [ ] Account deletion option available in app
- [ ] Data safety section filled in Play Console
- [ ] App content rating completed
- [ ] Test accounts provided for review
- [ ] In-app purchases configured (if applicable)

### Data Safety (Play Console)
Declare data collected:
- Personal info (name, email, phone)
- Financial info (transaction data)
- Device ID (for fraud prevention)
- App activity (rewards, referrals)

## Step 6: Post-Launch Monitoring
- Monitor Firebase Crashlytics for issues
- Review Firebase Performance for bottlenecks
- Monitor Cloud Functions logs
- Track user growth via Firestore analytics

## Troubleshooting

### Build Errors
- Run `flutter clean && flutter pub get`
- Check Java version (JDK 17+)
- Verify all Firebase config files exist

### Runtime Errors
- Check Firebase Console > Crashlytics
- Review Cloud Functions logs
- Verify Firestore Security Rules are deployed

### Authentication Issues
- Check Firebase Auth is enabled
- Verify email/password sign-in is enabled
- Check for domain blocking (if using email)
