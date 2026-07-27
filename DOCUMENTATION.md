# Fun Pay - Production Documentation

## Overview
Fun Pay is a reward-based mobile application built with Flutter and Firebase.
Users earn rewards through daily check-ins, ad watching, referrals, and tasks.

## Architecture
- **Frontend**: Flutter (Material 3, Provider state management)
- **Backend**: Firebase (Auth, Firestore, Cloud Functions, FCM, Crashlytics)
- **Modules**: Auth, Wallet, Referral, Rewards, Withdrawals, Admin, Notifications, Fraud Detection

## Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project (or use existing)
3. Register iOS and Android apps
4. Download google-services.json (Android) and GoogleService-Info.plist (iOS)

### 2. Enable Services
- **Authentication**: Email/Password, Google Sign-In
- **Firestore Database**: Create in production mode
- **Cloud Messaging**: Enable for push notifications
- **Crashlytics**: Enable for crash reporting
- **Cloud Functions**: Deploy functions/index.js

### 3. Firestore Indexes
Deploy these composite indexes:
- `fraud_reports`: status ASC, fraudScore DESC
- `login_attempts`: userId ASC, createdAt DESC
- `notifications`: userId ASC, createdAt DESC
- `transactions`: userId ASC, createdAt DESC

### 4. Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 5. Firestore Security Rules
Deploy firestore.rules from project root:
```bash
firebase deploy --only firestore:rules
```

## Build Instructions

### Android (APK)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android (AAB - Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Then archive via Xcode
```

## Admin Setup

### Creating an Admin
1. Create a regular user account through the app
2. In Firestore, create document: `admins/{userUid}`
```json
{
  "uid": "user_uid_here",
  "email": "admin@example.com",
  "fullName": "Admin Name",
  "role": "superAdmin",
  "isActive": true,
  "createdAt": Timestamp
}
```
3. Create `app_settings/settings` document

### Admin Roles
- `superAdmin`: Full access to all features
- `admin`: Access to user management, withdrawals, settings
- `moderator`: Access to user management and withdrawals only

## App Settings Configuration

Create document: `app_settings/settings`
```json
{
  "referralBonusAmount": 1.0,
  "referralRewardedThreshold": 1.0,
  "dailyRewardAmount": 0.1,
  "adRewardAmount": 0.05,
  "streakBonusAmount": 0.5,
  "minWithdrawalAmount": 1.0,
  "maxWithdrawalAmount": 500.0,
  "dailyWithdrawalLimit": 1000.0,
  "isReferralActive": true,
  "announcement": "",
  "updatedAt": Timestamp
}
```

## Key Features

### Wallet System
- Real-time balance tracking
- Transaction history with types (credit/debit)
- Admin credit/debit capabilities

### Referral Program
- Unique referral code per user
- Tiered reward system
- Fraud detection (self-referral prevention, duplicate detection)

### Reward System
- Daily check-in rewards
- Ad reward integration
- Streak bonuses
- Configurable reward amounts via admin

### Withdrawal System
- Multiple payment methods (UPI, Paytm, Bank Transfer)
- Admin approval workflow
- Daily limits and fraud prevention

### Admin Panel
- Dashboard with user/revenue analytics
- User management (search, block, delete)
- Withdrawal management (approve/reject)
- Wallet credit/debit
- App settings configuration
- Admin action logs

### Notification System
- FCM push notifications
- In-app notification center
- Automated notifications for rewards, withdrawals, referrals
- Admin announcement system

### Fraud Detection
- Device fingerprinting
- Multi-account detection
- Self-referral prevention
- Suspicious login monitoring
- Reward abuse detection
- Risk scoring system

## Security
- Firebase Authentication for user management
- Firestore Security Rules for data access control
- Cloud Function validation for sensitive operations
- Device-level fraud detection
- Account lockout on suspicious activity
- Admin-only operations protected by role validation

## Support
For issues or questions, contact: support@funpay.com
