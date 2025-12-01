/**
 * End-to-End Tests for Authentication Flows
 *
 * These tests simulate the complete user journey from registration/sign-in
 * through email link verification, testing the actual Cloud Functions endpoints.
 *
 * Prerequisites:
 * - Cloud Functions must be deployed or running locally
 * - Firestore must be available (production or emulator)
 * - Set FUNCTIONS_BASE_URL environment variable (defaults to deployed functions)
 *
 * Usage:
 *   npm run test:e2e
 *
 *   # Against local emulator:
 *   FUNCTIONS_BASE_URL=http://localhost:8080 npm run test:e2e
 *
 *   # Against deployed functions:
 *   FUNCTIONS_BASE_URL=https://us-central1-artist-manager-479514.cloudfunctions.net npm run test:e2e
 */

import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import { Firestore } from '@google-cloud/firestore';
import admin from 'firebase-admin';

// Initialize Firebase Admin SDK for cleanup
if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = new Firestore();

// Base URL for Cloud Functions (can be overridden with env var)
const FUNCTIONS_BASE_URL = process.env.FUNCTIONS_BASE_URL ||
  'https://us-central1-artist-manager-479514.cloudfunctions.net';

const TEST_APP_URL = 'https://artist-manager-479514.web.app';

// Test user data
const TEST_USERS = {
  registration: {
    email: `e2e-test-registration-${Date.now()}@example.com`,
    name: 'E2E Test User Registration'
  },
  signIn: {
    email: `e2e-test-signin-${Date.now()}@example.com`,
    name: 'E2E Test User SignIn'
  }
};

/**
 * Helper function to call a Cloud Function endpoint
 */
async function callCloudFunction(functionName, body) {
  const url = `${FUNCTIONS_BASE_URL}/${functionName}`;

  console.log(`📤 Calling ${functionName}:`, { url, body });

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  const data = await response.json();

  console.log(`📥 Response from ${functionName}:`, {
    status: response.status,
    data
  });

  return { status: response.status, data };
}

/**
 * Helper to extract token from Firestore
 * This simulates getting the token from the email link
 */
async function getTokenForEmail(email) {
  console.log(`🔍 Looking for pending registration token for ${email}...`);

  const snapshot = await firestore
    .collection('pendingRegistrations')
    .where('email', '==', email)
    .where('status', '==', 'pending')
    .limit(1)
    .get();

  if (snapshot.empty) {
    throw new Error(`No pending registration found for ${email}`);
  }

  const doc = snapshot.docs[0];
  const token = doc.id; // Token is the document ID

  console.log(`✅ Found token: ${token.substring(0, 20)}...`);

  return token;
}

/**
 * Helper to cleanup test data
 */
async function cleanupTestUser(email) {
  try {
    console.log(`🧹 Cleaning up test user: ${email}`);

    // Delete from Firebase Auth
    try {
      const user = await admin.auth().getUserByEmail(email);
      await admin.auth().deleteUser(user.uid);
      console.log(`  ✓ Deleted from Firebase Auth`);

      // Delete from Firestore users collection
      await firestore.collection('users').doc(user.uid).delete();
      console.log(`  ✓ Deleted from Firestore users collection`);
    } catch (error) {
      if (error.code !== 'auth/user-not-found') {
        console.log(`  ⚠️  Auth cleanup: ${error.message}`);
      }
    }

    // Delete pending registrations
    const pendingSnapshot = await firestore
      .collection('pendingRegistrations')
      .where('email', '==', email)
      .get();

    const batch = firestore.batch();
    pendingSnapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();

    if (pendingSnapshot.size > 0) {
      console.log(`  ✓ Deleted ${pendingSnapshot.size} pending registration(s)`);
    }

    console.log(`✅ Cleanup complete for ${email}`);
  } catch (error) {
    console.error(`❌ Cleanup error for ${email}:`, error.message);
  }
}

describe('E2E Authentication Flows', () => {
  // Cleanup before tests
  beforeAll(async () => {
    console.log('\n🧪 Starting E2E Authentication Tests');
    console.log(`📍 Functions URL: ${FUNCTIONS_BASE_URL}`);
    console.log(`📍 App URL: ${TEST_APP_URL}\n`);

    // Cleanup any existing test data
    await cleanupTestUser(TEST_USERS.registration.email);
    await cleanupTestUser(TEST_USERS.signIn.email);
  });

  // Cleanup after tests
  afterAll(async () => {
    console.log('\n🧹 Cleaning up test data...');
    await cleanupTestUser(TEST_USERS.registration.email);
    await cleanupTestUser(TEST_USERS.signIn.email);
    console.log('✅ E2E Tests Complete\n');
  });

  describe('Registration Flow (New User)', () => {
    let registrationToken;
    let verificationResponse;

    it('Step 1: Should create registration request and send email', async () => {
      const { status, data } = await callCloudFunction('createRegistration', {
        email: TEST_USERS.registration.email,
        name: TEST_USERS.registration.name,
        continueUrl: TEST_APP_URL
      });

      // Validate response
      expect(status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.message).toContain('email sent');
      expect(data.expiresAt).toBeDefined();

      // Verify expiration is ~24 hours in future
      const expiresAt = new Date(data.expiresAt);
      const expectedExpiration = new Date(Date.now() + 24 * 60 * 60 * 1000);
      const timeDiff = Math.abs(expiresAt - expectedExpiration);
      expect(timeDiff).toBeLessThan(5000); // Within 5 seconds

      console.log('✅ Step 1 Complete: Registration request created');
    });

    it('Step 2: Should store pending registration in Firestore with token', async () => {
      // Simulate user clicking email link by retrieving the token
      registrationToken = await getTokenForEmail(TEST_USERS.registration.email);

      expect(registrationToken).toBeDefined();
      expect(registrationToken.length).toBeGreaterThan(20); // Token should be substantial

      // Verify token document structure
      const tokenDoc = await firestore
        .collection('pendingRegistrations')
        .doc(registrationToken)
        .get();

      expect(tokenDoc.exists).toBe(true);

      const data = tokenDoc.data();
      expect(data.email).toBe(TEST_USERS.registration.email);
      expect(data.name).toBe(TEST_USERS.registration.name);
      expect(data.status).toBe('pending');
      expect(data.token).toBe(registrationToken);
      expect(data.continueUrl).toBe(TEST_APP_URL);
      expect(data.expiresAt).toBeDefined();
      expect(data.createdAt).toBeDefined();

      console.log('✅ Step 2 Complete: Token stored in Firestore');
    });

    it('Step 3: Should verify token and create Firebase user with sign-in link', async () => {
      // Simulate user clicking the email link
      const { status, data } = await callCloudFunction('verifyRegistrationToken', {
        token: registrationToken
      });

      verificationResponse = data;

      // Validate response
      expect(status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.email).toBe(TEST_USERS.registration.email);
      expect(data.name).toBe(TEST_USERS.registration.name);
      expect(data.signInLink).toBeDefined();
      expect(data.signInLink).toContain('apiKey');
      expect(data.signInLink).toContain('oobCode');
      expect(data.continueUrl).toBe(TEST_APP_URL);

      console.log('✅ Step 3 Complete: Token verified, Firebase user created');
    });

    it('Step 4: Should have created Firebase Auth user', async () => {
      // Verify Firebase Auth user was created
      const user = await admin.auth().getUserByEmail(TEST_USERS.registration.email);

      expect(user).toBeDefined();
      expect(user.email).toBe(TEST_USERS.registration.email);
      expect(user.displayName).toBe(TEST_USERS.registration.name);
      expect(user.emailVerified).toBe(true); // Email verified via token

      console.log('✅ Step 4 Complete: Firebase Auth user created');
    });

    it('Step 5: Should have created Firestore user profile', async () => {
      // Get the user from Firebase Auth to get UID
      const authUser = await admin.auth().getUserByEmail(TEST_USERS.registration.email);

      // Verify Firestore user document
      const userDoc = await firestore
        .collection('users')
        .doc(authUser.uid)
        .get();

      expect(userDoc.exists).toBe(true);

      const userData = userDoc.data();
      expect(userData.uid).toBe(authUser.uid);
      expect(userData.email).toBe(TEST_USERS.registration.email);
      expect(userData.name).toBe(TEST_USERS.registration.name);
      expect(userData.createdAt).toBeDefined();
      expect(userData.lastLoginAt).toBeDefined();
      expect(userData.metadata.loginCount).toBe(1);

      console.log('✅ Step 5 Complete: Firestore user profile created');
    });

    it('Step 6: Should have marked token as completed', async () => {
      const tokenDoc = await firestore
        .collection('pendingRegistrations')
        .doc(registrationToken)
        .get();

      expect(tokenDoc.exists).toBe(true);

      const data = tokenDoc.data();
      expect(data.status).toBe('completed');
      expect(data.verifiedAt).toBeDefined();

      console.log('✅ Step 6 Complete: Token marked as completed');
    });

    it('Step 7: Should reject reusing the same token', async () => {
      // Try to verify the token again
      const { status, data } = await callCloudFunction('verifyRegistrationToken', {
        token: registrationToken
      });

      // Should fail with TOKEN_ALREADY_USED error
      expect(status).toBe(409);
      expect(data.success).toBe(false);
      expect(data.error).toBe('TOKEN_ALREADY_USED');

      console.log('✅ Step 7 Complete: Token reuse rejected');
    });

    it('Step 8: Should reject registering same email again', async () => {
      const { status, data } = await callCloudFunction('createRegistration', {
        email: TEST_USERS.registration.email,
        name: 'Different Name',
        continueUrl: TEST_APP_URL
      });

      // Should fail with USER_EXISTS error
      expect(status).toBe(409);
      expect(data.success).toBe(false);
      expect(data.error).toBe('USER_EXISTS');
      expect(data.message).toContain('already exists');

      console.log('✅ Step 8 Complete: Duplicate registration rejected');
    });
  });

  describe('Sign-In Flow (Existing User)', () => {
    let signInToken;

    // First, create a user for sign-in testing
    beforeAll(async () => {
      console.log('\n📝 Setting up existing user for sign-in test...');

      // Create registration
      await callCloudFunction('createRegistration', {
        email: TEST_USERS.signIn.email,
        name: TEST_USERS.signIn.name,
        continueUrl: TEST_APP_URL
      });

      // Get token and verify to create the user
      const token = await getTokenForEmail(TEST_USERS.signIn.email);
      await callCloudFunction('verifyRegistrationToken', { token });

      console.log('✅ Existing user created for sign-in test\n');
    });

    it('Step 1: Should create sign-in request for existing user', async () => {
      const { status, data } = await callCloudFunction('createSignInRequest', {
        email: TEST_USERS.signIn.email,
        continueUrl: TEST_APP_URL
      });

      // Validate response
      expect(status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.message).toContain('email sent');
      expect(data.expiresAt).toBeDefined();

      console.log('✅ Step 1 Complete: Sign-in request created');
    });

    it('Step 2: Should store sign-in token in Firestore', async () => {
      // Get the sign-in token (simulating user clicking email link)
      signInToken = await getTokenForEmail(TEST_USERS.signIn.email);

      expect(signInToken).toBeDefined();

      // Verify token document
      const tokenDoc = await firestore
        .collection('pendingRegistrations')
        .doc(signInToken)
        .get();

      expect(tokenDoc.exists).toBe(true);
      const data = tokenDoc.data();
      expect(data.email).toBe(TEST_USERS.signIn.email);
      expect(data.name).toBe(TEST_USERS.signIn.name); // Should have user's name
      expect(data.status).toBe('pending');

      console.log('✅ Step 2 Complete: Sign-in token stored');
    });

    it('Step 3: Should verify sign-in token and return sign-in link', async () => {
      // Simulate user clicking the sign-in link
      const { status, data } = await callCloudFunction('verifyRegistrationToken', {
        token: signInToken
      });

      // Validate response
      expect(status).toBe(200);
      expect(data.success).toBe(true);
      expect(data.email).toBe(TEST_USERS.signIn.email);
      expect(data.name).toBe(TEST_USERS.signIn.name);
      expect(data.signInLink).toBeDefined();
      expect(data.signInLink).toContain('apiKey');
      expect(data.signInLink).toContain('oobCode');

      console.log('✅ Step 3 Complete: Sign-in token verified');
    });

    it('Step 4: Should have updated lastLoginAt timestamp', async () => {
      // Get the user from Firebase Auth
      const authUser = await admin.auth().getUserByEmail(TEST_USERS.signIn.email);

      // Check Firestore user document
      const userDoc = await firestore
        .collection('users')
        .doc(authUser.uid)
        .get();

      expect(userDoc.exists).toBe(true);

      const userData = userDoc.data();
      expect(userData.lastLoginAt).toBeDefined();

      // lastLoginAt should be very recent (within last few seconds)
      const lastLogin = userData.lastLoginAt.toDate();
      const now = new Date();
      const timeDiff = now - lastLogin;
      expect(timeDiff).toBeLessThan(10000); // Within 10 seconds

      console.log('✅ Step 4 Complete: lastLoginAt updated');
    });

    it('Step 5: Should NOT have created duplicate user', async () => {
      // Verify there's still only one user with this email
      const usersSnapshot = await firestore
        .collection('users')
        .where('email', '==', TEST_USERS.signIn.email)
        .get();

      expect(usersSnapshot.size).toBe(1);

      console.log('✅ Step 5 Complete: No duplicate user created');
    });

    it('Step 6: Should reject sign-in for non-existent user', async () => {
      const nonExistentEmail = `non-existent-${Date.now()}@example.com`;

      const { status, data } = await callCloudFunction('createSignInRequest', {
        email: nonExistentEmail,
        continueUrl: TEST_APP_URL
      });

      // Should fail with USER_NOT_FOUND error
      expect(status).toBe(404);
      expect(data.success).toBe(false);
      expect(data.error).toBe('USER_NOT_FOUND');
      expect(data.message).toContain('No account found');

      console.log('✅ Step 6 Complete: Non-existent user rejected');
    });
  });

  describe('Token Security and Validation', () => {
    it('Should reject invalid token format', async () => {
      const { status, data } = await callCloudFunction('verifyRegistrationToken', {
        token: 'invalid-token-123'
      });

      expect(status).toBe(404);
      expect(data.success).toBe(false);
      expect(data.error).toBe('INVALID_TOKEN');
    });

    it('Should reject expired token', async () => {
      // Create a registration
      const testEmail = `expired-test-${Date.now()}@example.com`;
      await callCloudFunction('createRegistration', {
        email: testEmail,
        name: 'Expired Test',
        continueUrl: TEST_APP_URL
      });

      // Get the token
      const token = await getTokenForEmail(testEmail);

      // Manually expire the token in Firestore
      await firestore
        .collection('pendingRegistrations')
        .doc(token)
        .update({
          expiresAt: new Date(Date.now() - 1000) // Expired 1 second ago
        });

      // Try to verify expired token
      const { status, data } = await callCloudFunction('verifyRegistrationToken', {
        token
      });

      expect(status).toBe(410);
      expect(data.success).toBe(false);
      expect(data.error).toBe('TOKEN_EXPIRED');

      // Cleanup
      await cleanupTestUser(testEmail);
    });

    it('Should validate required fields in createRegistration', async () => {
      const { status, data } = await callCloudFunction('createRegistration', {
        email: 'test@example.com'
        // Missing name and continueUrl
      });

      expect(status).toBe(400);
      expect(data.success).toBe(false);
      expect(data.error).toContain('Missing required fields');
    });

    it('Should validate email format', async () => {
      const { status, data } = await callCloudFunction('createRegistration', {
        email: 'invalid-email',
        name: 'Test User',
        continueUrl: TEST_APP_URL
      });

      expect(status).toBe(400);
      expect(data.success).toBe(false);
      expect(data.error).toContain('Invalid email');
    });

    it('Should validate name length', async () => {
      const { status, data } = await callCloudFunction('createRegistration', {
        email: 'test@example.com',
        name: 'A', // Too short
        continueUrl: TEST_APP_URL
      });

      expect(status).toBe(400);
      expect(data.success).toBe(false);
      expect(data.error).toContain('at least 2 characters');
    });
  });
});
