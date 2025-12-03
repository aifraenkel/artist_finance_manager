# Authentication Setup Guide

This guide explains how to set up and configure authentication for the Art Finance Hub application.

## Overview

The application uses Firebase Authentication with email link (passwordless) authentication. Users receive a secure sign-in link via email to access their account.

## Features

- **Email Link Authentication**: Secure, passwordless sign-in
- **User Registration**: Name and email collection
- **User Profiles**: Manage account settings and preferences
- **Soft Delete**: Account deletion with 90-day recovery period
- **Email Notifications**: Welcome emails, deletion confirmations, and security alerts
- **Session Management**: Automatic authentication state management

## Architecture

### Frontend (Flutter)
- **Models**: `lib/models/app_user.dart` - User data model
- **Services**: `lib/services/auth_service.dart` - Authentication operations
- **Providers**: `lib/providers/auth_provider.dart` - State management
- **Screens**:
  - `lib/screens/auth/login_screen.dart` - Email entry
  - `lib/screens/auth/registration_screen.dart` - New user registration
  - `lib/screens/auth/email_verification_screen.dart` - Email link waiting screen
  - `lib/screens/profile/profile_screen.dart` - User profile and settings

### Backend (Firebase/GCP)
- **Firebase Authentication**: Email link authentication
- **Cloud Firestore**: User profile storage
- **Cloud Functions**: Email notifications and cleanup jobs
- **Cloud Scheduler**: Automated cleanup of old deleted accounts

## Setup Instructions

### 1. Initialize Firebase

```bash
# Run the Firebase setup script
./scripts/setup_firebase.sh
```

### 2. Configure Firebase Web App

1. Visit [Firebase Console](https://console.firebase.google.com/project/artist-manager-479514/settings/general)
2. Add a Web app if not exists
3. Copy the Firebase configuration
4. Update `lib/firebase_options.dart` with your configuration values

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'artist-manager-479514',
  authDomain: 'artist-manager-479514.firebaseapp.com',
  storageBucket: 'artist-manager-479514.appspot.com',
  measurementId: 'YOUR_MEASUREMENT_ID',
);
```

### 3. Enable Authentication Methods

1. Visit [Firebase Authentication](https://console.firebase.google.com/project/artist-manager-479514/authentication/providers)
2. Enable **Email/Password** provider
3. Enable **Email link (passwordless sign-in)**
4. Set action URL to: `https://artist-manager-479514.firebaseapp.com/__/auth/action`

### 4. Configure Authorized Domains

1. Go to [Authentication Settings](https://console.firebase.google.com/project/artist-manager-479514/authentication/settings)
2. Add authorized domains:
   - `localhost` (for development)
   - `artist-finance-manager-456648586026.us-central1.run.app` (your Cloud Run URL)
   - Any custom domains you use

### 5. Deploy Firestore Security Rules

Deploy the security rules to protect user data:

```bash
# Create firestore.rules file
cat > firestore.rules <<'EOF'
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if isOwner(userId)
        && request.resource.data.email == request.auth.token.email;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }
  }
}
EOF

# Deploy rules
firebase deploy --only firestore:rules
```

### 6. Deploy Cloud Functions

Deploy the Cloud Functions for email notifications and cleanup:

```bash
chmod +x scripts/deploy_functions.sh
./scripts/deploy_functions.sh
```

### 7. Configure Email Service (Optional but Recommended)

The Cloud Functions log email events but don't actually send emails. To enable email sending:

1. Choose an email service provider:
   - [SendGrid](https://sendgrid.com/)
   - [Mailgun](https://www.mailgun.com/)
   - [AWS SES](https://aws.amazon.com/ses/)

2. Update `functions/index.js` with your email service integration

3. Add environment variables for email service credentials:

```bash
gcloud functions deploy onUserCreated \
  --set-env-vars SENDGRID_API_KEY=your_api_key
```

## User Flow

### Registration Flow

1. User enters name and email on registration screen
2. System sends email verification link
3. User clicks link in email
4. System authenticates user and creates profile
5. User is redirected to home screen

### Login Flow

1. User enters email on login screen
2. System sends sign-in link
3. User clicks link in email
4. System authenticates user
5. User is redirected to home screen

### Account Management

1. User clicks profile icon in app bar
2. Can view and edit profile information
3. Can sign out
4. Can delete account (soft delete with 90-day recovery)

## Data Models

### AppUser

```dart
{
  uid: string,
  email: string,
  name: string,
  createdAt: DateTime,
  lastLoginAt: DateTime,
  deletedAt: DateTime?,
  metadata: {
    loginCount: int,
    devices: [],
    lastLoginIp: string?,
    lastLoginUserAgent: string?
  }
}
```

## Security Features

### Authentication
- Email link authentication (no passwords to steal)
- Links expire after 15 minutes
- Links are single-use

### Authorization
- Firestore security rules enforce user-level access control
- Users can only read/write their own data
- Server-side validation of all operations

### Privacy
- User data encrypted in transit and at rest
- No PII in logs or analytics
- Soft delete with recovery period
- Automatic cleanup after retention period

## Testing

### Manual Testing

1. **Registration**:
   ```bash
   flutter run -d chrome
   # Click "Create Account"
   # Enter name and email
   # Check email for verification link
   # Click link to complete registration
   ```

2. **Login**:
   ```bash
   # Click "Send Sign-In Link"
   # Enter email
   # Check email for sign-in link
   # Click link to sign in
   ```

3. **Profile Management**:
   ```bash
   # Click profile icon in app bar
   # Update name
   # Test logout
   # Test account deletion
   ```

### Automated Testing

```bash
# Run unit tests
flutter test

# Run integration tests
cd test/e2e_web && npm test
```

## Troubleshooting

### Email links not working

1. Check authorized domains in Firebase Console
2. Verify action URL is configured correctly
3. Check browser console for errors
4. Ensure `handleCodeInApp: true` in ActionCodeSettings

### Users can't sign in

1. Verify Firebase Authentication is enabled
2. Check Firestore security rules
3. Verify user exists in Firestore
4. Check for soft-deleted accounts

### Functions not deploying

1. Ensure Cloud Functions API is enabled
2. Check IAM permissions
3. Verify Node.js version (20+)
4. Review function logs: `gcloud functions logs read`

## Monitoring

### View Authentication Events

```bash
# View Cloud Function logs
gcloud functions logs read --region=us-central1

# View Firestore activity
# Visit Firebase Console > Firestore > Usage
```

### Monitor User Activity

```bash
# Query active users
gcloud firestore export gs://backup-bucket --collection-ids=users

# Check deleted users pending cleanup
# Use Firestore console to query deletedAt field
```

## Cost Estimation

### Firebase Authentication
- Free tier: 10,000 verifications/month
- $0.01 per verification after free tier

### Cloud Firestore
- Free tier: 50,000 reads, 20,000 writes, 20,000 deletes per day
- 1 GB storage included

### Cloud Functions
- Free tier: 2 million invocations/month
- $0.40 per million invocations after free tier

### Cloud Scheduler
- First 3 jobs free
- $0.10 per job per month after

## Next Steps

1. **Customize Email Templates**: Update Cloud Functions with branded email templates
2. **Add Social Auth**: Extend to support Google, Apple, etc.
3. **Implement Rate Limiting**: Add Firestore-based rate limiting
4. **Add 2FA**: Optional two-factor authentication
5. **Session Management**: Implement "remember me" functionality
6. **Account Recovery**: Build UI for recovering soft-deleted accounts

## References

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Cloud Functions for Firebase](https://firebase.google.com/docs/functions)
- [Flutter Firebase Integration](https://firebase.flutter.dev/)
