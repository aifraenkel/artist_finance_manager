# Session Persistence and Management

## Overview

Art Finance Hub implements robust session persistence that keeps users signed in across app restarts, following industry best practices and OWASP security guidelines. The session management works seamlessly across web browsers, iOS, and Android devices.

## How It Works

### Automatic Session Persistence

Firebase Authentication automatically handles session persistence:

- **Web**: Authentication tokens are stored in IndexedDB (browser's persistent storage)
- **iOS**: Tokens are stored in the iOS Keychain (hardware-encrypted)
- **Android**: Tokens are stored in Android Keystore (hardware-encrypted)

When users sign in, their session is automatically saved and restored on app restart.

### Session Restoration Flow

1. App launches and initializes Firebase
2. Firebase Auth checks for existing authentication token
3. If valid token exists, user is automatically signed in
4. `authStateChanges` stream emits the authenticated user
5. App loads user profile from Firestore
6. User is redirected to home screen

### Device Tracking

The app tracks devices for security monitoring and user convenience:

- Each device gets a unique persistent ID
- Device information (name, platform, browser) is recorded
- Sign-in events from each device are logged
- Users can see which devices they've used (future feature)

## Security Features

### OWASP Compliance

The session management implementation follows OWASP guidelines:

1. **Secure Token Storage**
   - Web: IndexedDB with browser encryption
   - Mobile: Hardware-backed secure storage (Keychain/Keystore)
   - Tokens never exposed to application code

2. **Session Fixation Prevention**
   - Firebase regenerates tokens on each sign-in
   - Old tokens are invalidated

3. **Session Timeout**
   - Firebase tokens automatically expire
   - Users must re-authenticate after expiration
   - Token refresh handled automatically while active

4. **Logout Security**
   - Sign-out clears all tokens immediately
   - Logged for security audit trail

### Logging and Monitoring

All authentication events are logged for security monitoring:

- **User Registration**: Email, device info, timestamp
- **User Sign-In**: Email, device info, login count, timestamp
- **Session Restoration**: User info, last login time
- **User Sign-Out**: User info, timestamp

Example log output (with email hashing for privacy):
```
INFO: User a1b2c3d4e5f6g7h8 signed in from Chrome on macOS (device: abc-123, login #5)
INFO: Session restored for user a1b2c3d4e5f6g7h8
INFO: User a1b2c3d4e5f6g7h8 signed out
```

**Note**: Email addresses are hashed using SHA-256 for OWASP compliance and PII protection. The hash is deterministic, so the same email always produces the same hash for tracking purposes.

### Device Information Tracking

Each sign-in records:
- **Device ID**: Unique identifier for the device
- **Device Name**: Human-readable device description
- **Platform**: web, ios, android, etc.
- **Browser/OS**: User agent information
- **Timestamps**: First seen and last seen dates

This information helps:
- Detect suspicious sign-ins from new devices
- Provide better user experience (recognize trusted devices)
- Debug authentication issues
- Meet compliance requirements

## Implementation Details

### Firebase Auth Persistence Configuration

```dart
// Explicitly configured in AuthService constructor
await _auth.setPersistence(Persistence.LOCAL);
```

This ensures sessions persist even after:
- Browser/app closure
- Device restart
- Network interruptions

### Device ID Management

```dart
// Device ID is generated once and persisted
final deviceId = await DeviceInfoService.getDeviceId();

// Same device ID returned on subsequent calls
final sameId = await DeviceInfoService.getDeviceId();
assert(deviceId == sameId);
```

### User Metadata Structure

```dart
{
  "uid": "firebase-user-id",
  "email": "user@example.com",
  "name": "User Name",
  "lastLoginAt": Timestamp,
  "metadata": {
    "loginCount": 5,
    "devices": [
      {
        "deviceId": "abc-123",
        "deviceName": "Chrome on macOS",
        "firstSeen": Timestamp,
        "lastSeen": Timestamp
      }
    ],
    "lastLoginUserAgent": "Mozilla/5.0..."
  }
}
```

## User Experience

### First Sign-In (New User)

1. User enters email and name
2. Receives sign-in link via email
3. Clicks link to complete registration
4. Session is saved automatically
5. User stays signed in

### Subsequent App Launches

1. User opens app
2. Session is automatically restored
3. No need to sign in again
4. Goes directly to home screen

### Multi-Device Usage

1. User signs in on desktop
2. Session saved on desktop
3. User opens app on mobile
4. Signs in on mobile (new device)
5. Both sessions remain active
6. Each device tracks login independently

### Sign-Out

1. User clicks "Sign Out"
2. Session is cleared immediately
3. Sign-out event is logged
4. User redirected to login screen
5. Must sign in again to access app

## Testing

### Unit Tests

```bash
flutter test test/services/device_info_service_test.dart
flutter test test/services/session_persistence_test.dart
```

Tests cover:
- Device ID generation and persistence
- Device information collection
- Session metadata structure

### Widget Tests

```bash
flutter test test/auth/session_persistence_widget_test.dart
```

Tests cover:
- AuthWrapper state transitions
- Session restoration UI flow
- Loading states
- Authenticated vs unauthenticated states

### Manual Testing

1. **Session Persistence**:
   - Sign in to the app
   - Close the app completely
   - Reopen the app
   - Verify you're still signed in

2. **Multi-Device**:
   - Sign in on browser
   - Sign in on mobile device
   - Check both devices work independently

3. **Sign-Out**:
   - Sign in to the app
   - Click sign out
   - Verify you're at login screen
   - Close and reopen app
   - Verify you're still logged out

## Privacy Considerations

### Data Collected

- Device ID (random UUID, not tied to hardware)
- Device name (browser/OS, no serial numbers)
- Platform (web/ios/android)
- Timestamps of sign-ins
- Login count

### Data NOT Collected

- IP addresses
- Physical device identifiers (IMEI, MAC address)
- Location data
- Browsing history
- Personal information beyond email/name

### GDPR Compliance

- Users can delete their account (soft delete with 90-day recovery)
- Device data deleted with account
- No data shared with third parties
- Data stored in Firebase (GDPR compliant)

## Troubleshooting

### Session Not Persisting on Web

**Symptoms**: User has to sign in every time they open the browser

**Solutions**:
1. Check browser settings allow IndexedDB
2. Verify not in private/incognito mode
3. Check browser's storage quota
4. Disable browser extensions that clear storage

### Session Not Persisting on Mobile

**Symptoms**: User has to sign in every app launch

**Solutions**:
1. Verify app has storage permissions
2. Check device storage space
3. Ensure app not in battery optimization list
4. Reinstall app if corrupted

### Device Not Tracked

**Symptoms**: Device info not appearing in user metadata

**Solutions**:
1. Check device_info_plus permissions
2. Verify Firestore update succeeded
3. Check network connectivity
4. Review error logs

## Configuration

### Enable/Disable Session Persistence

Session persistence is enabled by default. To disable for testing:

```dart
// For web only
await _auth.setPersistence(Persistence.SESSION); // Clears on browser close
await _auth.setPersistence(Persistence.NONE);    // No persistence
```

### Configure Session Timeout

Firebase handles token expiration automatically. To customize:

```dart
// This is handled by Firebase - tokens expire after 1 hour
// Refresh tokens valid for longer period (configurable in Firebase Console)
```

### Customize Device Tracking

To add more device information:

```dart
// Edit lib/services/device_info_service.dart
static Future<Map<String, dynamic>> getDeviceInfo() async {
  // Add custom fields here
  info['customField'] = 'customValue';
  return info;
}
```

## Best Practices

### For Developers

1. Always check `isAuthenticated` before accessing protected resources
2. Handle loading states during session restoration
3. Log significant auth events for debugging
4. Test session persistence on all platforms
5. Monitor device tracking data for anomalies

### For Users

1. Sign out on shared devices
2. Review device list periodically (when feature added)
3. Report suspicious sign-ins
4. Use secure networks for authentication
5. Keep app updated for security patches

## Future Enhancements

Planned improvements:

- [ ] UI to view and manage trusted devices
- [ ] Email notifications for new device sign-ins
- [ ] Biometric authentication (Face ID, Touch ID)
- [ ] Two-factor authentication (2FA)
- [ ] Session activity timeline
- [ ] Suspicious activity detection
- [ ] Force sign-out from all devices

## Related Documentation

- [AUTH_SETUP.md](./AUTH_SETUP.md) - Authentication setup guide
- [REGISTRATION_FLOW.md](./REGISTRATION_FLOW.md) - Registration details
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Overall architecture
- [TEST_GUIDE.md](./TEST_GUIDE.md) - Testing documentation

## Support

For issues with session persistence:

1. Check browser console (web) or device logs (mobile)
2. Verify Firebase configuration
3. Review Firestore security rules
4. Check network connectivity
5. Open GitHub issue with reproduction steps

## References

- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [OWASP Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
- [Flutter Secure Storage Best Practices](https://flutter.dev/docs/cookbook/persistence)
