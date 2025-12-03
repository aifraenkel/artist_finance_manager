/**
 * Cloud Functions for Art Finance Hub
 *
 * Functions:
 * - onUserCreated: Send welcome email when user is created
 * - onUserDeleted: Send account deletion confirmation email
 * - cleanupDeletedUsers: Scheduled function to permanently delete old soft-deleted users
 */

import functions from '@google-cloud/functions-framework';
import { Firestore } from '@google-cloud/firestore';
import admin from 'firebase-admin';
import { sendWelcomeEmail, sendAccountDeletionEmail, sendLoginNotificationEmail } from './email_service.js';
import {
  createPendingRegistration,
  verifyRegistrationToken,
  cleanupExpiredRegistrations,
  hasPendingRegistration,
  cancelPendingRegistration
} from './registration_service.js';
import { generateRegistrationEmail, generateSignInEmail } from './email_templates.js';
import { sendEmail } from './email_service_sendgrid.js';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = new Firestore();

/**
 * Send welcome email when a new user is created
 * Triggered by Firestore onCreate event on /users/{userId}
 */
functions.cloudEvent('onUserCreated', async (cloudEvent) => {
  const data = cloudEvent.data;

  if (!data || !data.value) {
    console.log('No user data found');
    return;
  }

  const userData = data.value.fields;
  const email = userData.email?.stringValue;
  const name = userData.name?.stringValue;

  if (!email || !name) {
    console.log('Missing email or name');
    return;
  }

  console.log(`Sending welcome email to ${email}`);

  try {
    await sendWelcomeEmail(email, name);
    console.log('Welcome email sent successfully');
    return { success: true };
  } catch (error) {
    console.error('Failed to send welcome email:', error);
    // Don't fail the function if email fails
    return { success: false, error: error.message };
  }
});

/**
 * Send account deletion confirmation email
 * Triggered by Firestore onUpdate event on /users/{userId} when deletedAt is set
 */
functions.cloudEvent('onUserDeleted', async (cloudEvent) => {
  const data = cloudEvent.data;

  if (!data || !data.value || !data.oldValue) {
    console.log('No user data found');
    return;
  }

  const newData = data.value.fields;
  const oldData = data.oldValue.fields;

  // Check if deletedAt was just set (wasn't set before, is set now)
  const wasDeleted = !oldData.deletedAt && newData.deletedAt;

  if (!wasDeleted) {
    console.log('User not deleted, skipping email');
    return;
  }

  const email = newData.email?.stringValue;
  const name = newData.name?.stringValue;

  if (!email || !name) {
    console.log('Missing email or name');
    return;
  }

  console.log(`Sending account deletion email to ${email}`);

  try {
    await sendAccountDeletionEmail(email, name);
    console.log('Account deletion email sent successfully');
    return { success: true };
  } catch (error) {
    console.error('Failed to send deletion email:', error);
    // Don't fail the function if email fails
    return { success: false, error: error.message };
  }
});

/**
 * Cleanup old soft-deleted users
 * Scheduled to run daily via Cloud Scheduler
 * Permanently deletes users who were soft-deleted more than 90 days ago
 */
functions.http('cleanupDeletedUsers', async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const now = new Date();
    const retentionPeriod = 90 * 24 * 60 * 60 * 1000; // 90 days in milliseconds
    const cutoffDate = new Date(now.getTime() - retentionPeriod);

    console.log(`Starting cleanup of users deleted before ${cutoffDate.toISOString()}`);

    // Query for users deleted before the cutoff date
    const usersRef = firestore.collection('users');
    const snapshot = await usersRef
      .where('deletedAt', '!=', null)
      .where('deletedAt', '<', cutoffDate)
      .get();

    if (snapshot.empty) {
      console.log('No users to clean up');
      res.status(200).json({
        success: true,
        deleted: 0,
        message: 'No users to clean up'
      });
      return;
    }

    console.log(`Found ${snapshot.size} users to permanently delete`);

    // Delete users in batch
    const batch = firestore.batch();
    const deletedUsers = [];

    snapshot.docs.forEach((doc) => {
      const userData = doc.data();
      deletedUsers.push({
        uid: doc.id,
        email: userData.email,
        deletedAt: userData.deletedAt,
      });
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log(`Successfully deleted ${deletedUsers.length} users:`, deletedUsers);

    // TODO: Also delete from Firebase Auth using Admin SDK
    // This requires Firebase Admin SDK which should be configured separately

    res.status(200).json({
      success: true,
      deleted: deletedUsers.length,
      users: deletedUsers,
    });
  } catch (error) {
    console.error('Error cleaning up deleted users:', error);
    // Ensure CORS headers on error
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Send login notification email
 * Triggered by HTTP request when user logs in from a new device
 */
functions.http('sendLoginNotification', async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { email } = req.body;
    let { name, deviceInfo, ipAddress, userAgent, ip, timestamp } = req.body;

    if (!email) {
      res.status(400).json({
        success: false,
        error: 'Missing required field: email'
      });
      return;
    }

    // Derive missing fields
    const forwarded = req.headers['x-forwarded-for'];
    const derivedIp = forwarded ? String(forwarded).split(',')[0].trim() : req.connection?.remoteAddress || req.socket?.remoteAddress || ipAddress || ip || 'Unknown IP';
    ipAddress = ipAddress || ip || derivedIp;
    deviceInfo = deviceInfo || userAgent || req.headers['user-agent'] || 'Unknown device';

    if (!name) {
      // Try to resolve name from users collection
      try {
        const snapshot = await firestore.collection('users').where('email', '==', email).limit(1).get();
        if (!snapshot.empty) {
          name = snapshot.docs[0].data().name || 'User';
        } else {
          name = 'User';
        }
      } catch (lookupErr) {
        console.warn('Name lookup failed, defaulting to "User"', lookupErr);
        name = 'User';
      }
    }

    console.log(`Sending login notification to ${email}`);

    await sendLoginNotificationEmail(email, name, deviceInfo, ipAddress);
    console.log('Login notification sent successfully');

    res.status(200).json({ success: true, timestamp: timestamp || new Date().toISOString() });
  } catch (error) {
    console.error('Error sending login notification:', error);
    // Ensure CORS headers on error
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Create a registration request
 * HTTP endpoint called by the client to initiate registration
 *
 * POST /createRegistration
 * Body: { email, name, continueUrl }
 * Returns: { success, message }
 */
functions.http('createRegistration', async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { email, name, continueUrl } = req.body;

    // Validate input
    if (!email || !name || !continueUrl) {
      res.status(400).json({
        success: false,
        error: 'Missing required fields: email, name, continueUrl'
      });
      return;
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
      return;
    }

    // Validate name length
    if (name.trim().length < 2) {
      res.status(400).json({
        success: false,
        error: 'Name must be at least 2 characters'
      });
      return;
    }

    console.log(`Creating registration for ${email}`);

    // Check if user already exists
    const usersSnapshot = await firestore
      .collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (!usersSnapshot.empty) {
      res.status(409).json({
        success: false,
        error: 'USER_EXISTS',
        message: 'A user with this email already exists. Please sign in instead.'
      });
      return;
    }

    // Cancel any existing pending registrations for this email
    await cancelPendingRegistration(email);

    // Create pending registration
    const { token, expiresAt } = await createPendingRegistration(email, name, continueUrl);

    // Build verification URL with token
    const verificationUrl = `${continueUrl}?registrationToken=${token}`;

    // Generate email content
    const { html, text } = generateRegistrationEmail(name, verificationUrl);

    // Send email
    await sendEmail(
      email,
      'Complete Your Registration - Art Finance Hub',
      html,
      text
    );

    console.log(`Registration email sent to ${email}`);

    res.status(200).json({
      success: true,
      message: 'Registration email sent successfully',
      expiresAt: expiresAt.toISOString()
    });
  } catch (error) {
    console.error('Error creating registration:', error);
    // Ensure CORS headers are set even on error
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(500).json({
      success: false,
      error: 'Failed to create registration',
      details: error.message
    });
  }
});

/**
 * Verify a registration token
 * HTTP endpoint called by the client when user clicks the email link
 *
 * POST /verifyRegistrationToken
 * Body: { token }
 * Returns: { success, email, name, continueUrl }
 */
functions.http('verifyRegistrationToken', async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { token } = req.body;

    if (!token) {
      res.status(400).json({
        success: false,
        error: 'Missing registration token'
      });
      return;
    }

    // Get IP address for logging
    const ipAddress = req.headers['x-forwarded-for'] || req.connection.remoteAddress;

    console.log(`Verifying registration token from IP: ${ipAddress}`);

    // Verify token and get registration data
    const registrationData = await verifyRegistrationToken(token, ipAddress);

    console.log(`Token verified successfully for ${registrationData.email}`);

    const { email, name } = registrationData;

    // Create or get Firebase Auth user
    let firebaseUser;
    try {
      firebaseUser = await admin.auth().getUserByEmail(email);
      console.log(`Existing Firebase user found: ${firebaseUser.uid}`);
      
      // Update last login in Firestore
      const userRef = firestore.collection('users').doc(firebaseUser.uid);
      const userDoc = await userRef.get();
      if (userDoc.exists) {
        await userRef.update({
          lastLoginAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`Updated lastLoginAt for ${email}`);
      }
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        // Create new Firebase user
        firebaseUser = await admin.auth().createUser({
          email: email,
          emailVerified: true, // Email is verified via token
          displayName: name,
        });
        console.log(`Created new Firebase user: ${firebaseUser.uid}`);

        // Create Firestore user profile
        await firestore.collection('users').doc(firebaseUser.uid).set({
          uid: firebaseUser.uid,
          email: email,
          name: name,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
          metadata: {
            loginCount: 1
          }
        });
        console.log(`Created Firestore profile for ${email}`);
      } else {
        throw error;
      }
    }

    // Generate a passwordless sign-in link for the user
    const actionCodeSettings = {
      url: registrationData.continueUrl,
      handleCodeInApp: true,
    };

    const signInLink = await admin.auth().generateSignInWithEmailLink(email, actionCodeSettings);
    console.log(`Generated sign-in link for ${email}`);

    res.status(200).json({
      success: true,
      email: email,
      name: name,
      signInLink: signInLink,
      continueUrl: registrationData.continueUrl
    });
  } catch (error) {
    console.error('Error verifying registration token:', error);

    // Ensure CORS headers are set even on error
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    // Extract error type from message
    const errorMessage = error.message;
    let statusCode = 500;
    let errorCode = 'VERIFICATION_FAILED';

    if (errorMessage.includes('INVALID_TOKEN')) {
      statusCode = 404;
      errorCode = 'INVALID_TOKEN';
    } else if (errorMessage.includes('TOKEN_EXPIRED')) {
      statusCode = 410;
      errorCode = 'TOKEN_EXPIRED';
    } else if (errorMessage.includes('TOKEN_ALREADY_USED')) {
      statusCode = 409;
      errorCode = 'TOKEN_ALREADY_USED';
    }

    res.status(statusCode).json({
      success: false,
      error: errorCode,
      message: errorMessage
    });
  }
});

/**
 * Clean up expired registration tokens
 * Scheduled function to run daily
 * Can also be triggered manually via HTTP
 */
functions.http('cleanupExpiredRegistrations', async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    console.log('Starting cleanup of expired registrations');

    const deletedCount = await cleanupExpiredRegistrations();

    console.log(`Cleanup completed: ${deletedCount} registrations deleted`);

    res.status(200).json({
      success: true,
      deletedCount,
      message: `Deleted ${deletedCount} expired registrations`
    });
  } catch (error) {
    console.error('Error cleaning up expired registrations:', error);
    // Ensure CORS headers on error
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Create a sign-in request (for existing users)
 * HTTP endpoint called by the client to send sign-in link
 *
 * POST /createSignInRequest
 * Body: { email, continueUrl }
 * Returns: { success, message }
 */
functions.http('createSignInRequest', async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { email, continueUrl } = req.body;

    // Validate input
    if (!email || !continueUrl) {
      res.status(400).json({
        success: false,
        error: 'Missing required fields: email, continueUrl'
      });
      return;
    }

    console.log(`Creating sign-in request for ${email}`);

    // Check if user exists
    const usersSnapshot = await firestore
      .collection('users')
      .where('email', '==', email)
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      res.status(404).json({
        success: false,
        error: 'USER_NOT_FOUND',
        message: 'No account found with this email. Please register first.'
      });
      return;
    }

    const userData = usersSnapshot.docs[0].data();
    const userName = userData.name;

    // Cancel any existing pending sign-in requests for this email
    await cancelPendingRegistration(email);

    // Create pending sign-in (reuse registration system)
    const { token, expiresAt } = await createPendingRegistration(email, userName, continueUrl);

    // Build sign-in URL with token
    const signInUrl = `${continueUrl}?signInToken=${token}`;

    // Generate email content
    const { html, text } = generateSignInEmail(userName, signInUrl);

    // Send email
    await sendEmail(
      email,
      'Sign In to Your Account - Art Finance Hub',
      html,
      text
    );

    console.log(`Sign-in email sent to ${email}`);

    res.status(200).json({
      success: true,
      message: 'Sign-in email sent successfully',
      expiresAt: expiresAt.toISOString()
    });
  } catch (error) {
    console.error('Error creating sign-in request:', error);
    // Ensure CORS headers are set even on error
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(500).json({
      success: false,
      error: 'Failed to create sign-in request',
      details: error.message
    });
  }
});
