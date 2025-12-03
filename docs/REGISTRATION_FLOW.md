# Server-Side Registration Flow

## Overview

Art Finance Hub uses a server-side token-based registration system that eliminates the need for client-side storage (localStorage/SharedPreferences). This allows users to complete registration on any device, even if they click the email link on a different device than where they started registration.

## Architecture

### Components

1. **Flutter Client** (`lib/services/registration_api_service.dart`)
   - Calls Cloud Functions to initiate registration
   - Handles token verification
   - No local storage of registration data

2. **Cloud Functions** (`functions/`)
   - `createRegistration` - Creates pending registration with token
   - `verifyRegistrationToken` - Verifies token and returns user data
   - `createSignInRequest` - Creates sign-in tokens for existing users
   - `cleanupExpiredRegistrations` - Removes expired tokens

3. **Firestore Collection** (`pendingRegistrations`)
   - Stores registration data with secure tokens
   - 24-hour expiration
   - Client access denied (Cloud Functions only)

4. **Email Service** (`functions/email_templates.js`)
   - Beautiful HTML email templates
   - Includes registration token in URL
   - Works with SMTP (Mailpit, SendGrid, etc.)

## User Flow

### Registration Flow (New User)

```
1. User visits app → clicks "Create Account"
2. Enters name and email → submits form
3. Client calls createRegistration Cloud Function
4. Backend:
   - Generates secure random token
   - Stores {token, email, name, continueUrl, expiresAt} in Firestore
   - Sends verification email with token in URL
5. User checks email (on ANY device)
6. Clicks link → app extracts token from URL query parameter
7. Client calls verifyRegistrationToken with token
8. Backend:
   - Verifies token exists and not expired
   - Returns {email, name, continueUrl}
   - Marks token as used
9. Client authenticates user with Firebase Auth
10. Creates user profile in Firestore with correct name
11. User is signed in!
```

### Sign-In Flow (Existing User)

```
1. User visits app → enters email
2. Client calls createSignInRequest Cloud Function
3. Backend:
   - Checks user exists in Firestore
   - Generates secure token
   - Sends sign-in email with token
4. User clicks link (on ANY device)
5. Token verification → authentication → signed in!
```

## Key Improvements Over Old System

### ❌ Old System (localStorage-based)

- Registration data stored in browser localStorage
- Only works if user clicks link on same browser/device
- Name lost if localStorage cleared
- User had to re-enter email on different device
- No server-side validation
- Security: anyone with access to localStorage could see data

### ✅ New System (Server-side tokens)

- Registration data stored securely on server
- Works across ANY device/browser combination
- Name preserved and used to create profile
- No need to re-enter anything
- Server-side validation and business logic
- Tokens expire after 24 hours
- Tokens can only be used once
- Secure: data never exposed to client

## Data Structures

### Pending Registration Document

```javascript
{
  email: "user@example.com",
  name: "John Doe",
  token: "secure-random-token-here",
  continueUrl: "https://app.example.com",
  createdAt: Timestamp,
  expiresAt: Timestamp, // 24 hours from creation
  status: "pending", // pending | completed | expired
  verifiedAt: Timestamp | null,
  ipAddress: "1.2.3.4" | null
}
```

### Collection Structure

```
/pendingRegistrations/{token}
```

Token is used as document ID for fast lookups.

## Security

### Token Generation

- Uses `crypto.randomBytes(32)` for cryptographically secure tokens
- Base64URL encoding for URL-safe tokens
- 32 bytes = 256 bits of entropy = extremely secure

### Token Expiration

- Tokens expire after 24 hours
- Expired tokens automatically marked as `expired`
- Cleanup job runs daily to delete expired tokens
- Prevents token reuse attacks

### Firestore Security Rules

```javascript
// Pending registrations collection
match /pendingRegistrations/{token} {
  // Deny all client access
  // Cloud Functions have admin access and bypass these rules
  allow read, write: if false;
}
```

### CORS Configuration

All Cloud Functions include proper CORS headers:
```javascript
res.set('Access-Control-Allow-Origin', '*');
res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
res.set('Access-Control-Allow-Headers', 'Content-Type');
```

## API Reference

### POST /createRegistration

Creates a pending registration and sends verification email.

**Request Body:**
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "continueUrl": "https://app.example.com"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Registration email sent successfully",
  "expiresAt": "2025-12-01T12:00:00.000Z"
}
```

**Error Responses:**
- `400` - Missing required fields
- `409` - User already exists (error: "USER_EXISTS")
- `500` - Server error

### POST /verifyRegistrationToken

Verifies a registration token and returns user data.

**Request Body:**
```json
{
  "token": "secure-token-from-email-link"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "email": "user@example.com",
  "name": "John Doe",
  "continueUrl": "https://app.example.com"
}
```

**Error Responses:**
- `400` - Missing token
- `404` - Invalid token (error: "INVALID_TOKEN")
- `409` - Token already used (error: "TOKEN_ALREADY_USED")
- `410` - Token expired (error: "TOKEN_EXPIRED")
- `500` - Server error

### POST /createSignInRequest

Creates a sign-in request for existing users.

**Request Body:**
```json
{
  "email": "user@example.com",
  "continueUrl": "https://app.example.com"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Sign-in email sent successfully",
  "expiresAt": "2025-12-01T12:00:00.000Z"
}
```

**Error Responses:**
- `400` - Missing required fields
- `404` - User not found (error: "USER_NOT_FOUND")
- `500` - Server error

### GET /cleanupExpiredRegistrations

Removes expired registration tokens. Called by Cloud Scheduler daily.

**Success Response (200):**
```json
{
  "success": true,
  "deletedCount": 5,
  "message": "Deleted 5 expired registrations"
}
```

## Deployment

### 1. Deploy Cloud Functions

```bash
./scripts/deploy_functions.sh
```

This will:
- Deploy all Cloud Functions
- Set up Cloud Scheduler for automatic cleanup
- Output function URLs

### 2. Update Client Configuration

After deployment, update `lib/services/registration_api_service.dart`:

```dart
static const String _functionsBaseUrl =
    'https://us-central1-artist-manager-479514.cloudfunctions.net';
```

Replace with your project ID.

### 3. Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### 4. Test the Flow

1. Register a new user on desktop
2. Check email on mobile device
3. Click registration link
4. Verify you're signed in with correct name

## Monitoring

### Cloud Function Logs

View logs in GCP Console:
```bash
gcloud functions logs read createRegistration --limit=50
gcloud functions logs read verifyRegistrationToken --limit=50
```

### Firestore Collection

Monitor pending registrations:
```bash
# In Firebase Console → Firestore → pendingRegistrations
# Check for:
# - Status distribution (pending/completed/expired)
# - Average time to completion
# - Expired tokens (should be cleaned up daily)
```

### Email Delivery

If using Mailpit:
- View emails at: https://mailpit-smtp-{project-id}.us-central1.run.app
- Check delivery rate and any failures

## Troubleshooting

### User clicks link but nothing happens

**Check:**
1. Token in URL query parameter: `?registrationToken=xxx` or `?signInToken=xxx`
2. Token not expired (< 24 hours old)
3. Cloud Function logs for errors
4. Network tab in browser dev tools for API call failures

### Email not received

**Check:**
1. Email service configuration (SMTP settings in functions/.env)
2. Cloud Function logs for email sending errors
3. Spam folder
4. Email service dashboard (SendGrid, Mailpit, etc.)

### "Invalid token" error

**Possible causes:**
1. Token expired (> 24 hours)
2. Token already used
3. Token doesn't exist in Firestore
4. Typo in token parameter

### "User already exists" error

**Expected behavior** when user tries to register with email that's already registered.

**Solution:** Direct user to sign-in flow instead.

## Future Enhancements

### Potential Improvements

1. **Rate Limiting**
   - Prevent spam registrations
   - Use Cloud Armor or custom middleware

2. **Email Verification Required**
   - Don't allow sign-in until email verified
   - Add `emailVerified` flag to user profile

3. **Invite System**
   - Generate invite codes
   - Track who invited whom

4. **Registration Analytics**
   - Track conversion rates
   - Time to complete registration
   - Device/browser used

5. **Multi-factor Authentication**
   - SMS verification
   - Authenticator app support

6. **Social Sign-In**
   - Google OAuth
   - Apple Sign-In
   - GitHub, etc.

## Migration from Old System

If you have users registered with the old localStorage-based system:

1. **No action needed** - existing users can still sign in
2. Old email links still work (Firebase Auth email links)
3. New registrations use new token-based system
4. Users never need to re-register

## Testing

### Manual Testing Checklist

- [ ] Register on desktop, verify on mobile
- [ ] Register on mobile, verify on desktop
- [ ] Register and verify on same device
- [ ] Try to use expired token (wait 24 hours or modify in Firestore)
- [ ] Try to use token twice
- [ ] Test with existing email (should show error)
- [ ] Test sign-in flow for existing user
- [ ] Clear browser data during registration (should still work)
- [ ] Test in private/incognito mode

### Automated Testing

Unit tests for Cloud Functions:
```bash
cd functions
npm test
```

(Note: Unit tests need to be implemented)

## Support

For issues or questions:
1. Check Cloud Function logs
2. Check Firestore data
3. Review this documentation
4. Open GitHub issue

## Related Documentation

- [AUTH_SETUP.md](./AUTH_SETUP.md) - Firebase Auth configuration
- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Complete setup guide
- [TEST_GUIDE.md](./TEST_GUIDE.md) - Testing documentation
