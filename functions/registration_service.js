/**
 * Registration Service
 *
 * Handles server-side registration flow with token-based verification.
 * This eliminates the need for localStorage and allows cross-device registration.
 */

import { Firestore } from '@google-cloud/firestore';
import crypto from 'crypto';

const firestore = new Firestore();

/**
 * Generate a secure random token for registration
 */
function generateToken() {
  return crypto.randomBytes(32).toString('base64url');
}

/**
 * Create a pending registration record
 *
 * @param {string} email - User's email address
 * @param {string} name - User's display name
 * @param {string} continueUrl - URL to redirect to after verification
 * @returns {Promise<{token: string, expiresAt: Date}>}
 */
export async function createPendingRegistration(email, name, continueUrl) {
  const token = generateToken();
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000); // 24 hours

  const registrationData = {
    email,
    name,
    token,
    continueUrl,
    createdAt: now,
    expiresAt,
    status: 'pending', // pending, completed, expired
    verifiedAt: null,
    ipAddress: null, // Will be set when token is verified
  };

  // Store in Firestore
  await firestore
    .collection('pendingRegistrations')
    .doc(token)
    .set(registrationData);

  console.log(`Created pending registration for ${email} with token ${token.substring(0, 10)}...`);

  return { token, expiresAt };
}

/**
 * Verify a registration token and retrieve the registration data
 *
 * @param {string} token - Registration token to verify
 * @param {string} ipAddress - IP address of the requester (optional)
 * @returns {Promise<{email: string, name: string, continueUrl: string}>}
 * @throws {Error} if token is invalid, expired, or already used
 */
export async function verifyRegistrationToken(token, ipAddress = null) {
  const docRef = firestore.collection('pendingRegistrations').doc(token);
  const doc = await docRef.get();

  if (!doc.exists) {
    throw new Error('INVALID_TOKEN: Registration token not found');
  }

  const data = doc.data();

  // Check if already used
  if (data.status === 'completed') {
    throw new Error('TOKEN_ALREADY_USED: This registration has already been completed');
  }

  // Check if expired
  const now = new Date();
  if (data.expiresAt.toDate() < now) {
    await docRef.update({ status: 'expired' });
    throw new Error('TOKEN_EXPIRED: Registration token has expired');
  }

  // Mark as completed
  await docRef.update({
    status: 'completed',
    verifiedAt: now,
    ipAddress: ipAddress || null,
  });

  console.log(`Verified registration token for ${data.email}`);

  return {
    email: data.email,
    name: data.name,
    continueUrl: data.continueUrl,
  };
}

/**
 * Clean up expired registration tokens
 * Should be called by a scheduled Cloud Function
 *
 * @returns {Promise<number>} Number of tokens deleted
 */
export async function cleanupExpiredRegistrations() {
  const now = new Date();

  console.log(`Starting cleanup of registrations expired before ${now.toISOString()}`);

  // Avoid composite index by querying status first, then filtering by expiresAt
  const statusSnapshot = await firestore
    .collection('pendingRegistrations')
    .where('status', '==', 'pending')
    .get();

  if (statusSnapshot.empty) {
    console.log('No pending registrations to clean up');
    return 0;
  }

  const expiredDocs = statusSnapshot.docs.filter((doc) => {
    const data = doc.data();
    const expiresAt = data.expiresAt instanceof Date ? data.expiresAt : data.expiresAt?.toDate?.();
    return expiresAt && expiresAt < now;
  });

  if (expiredDocs.length === 0) {
    console.log('No expired registrations to clean up');
    return 0;
  }

  console.log(`Found ${expiredDocs.length} expired registrations to delete`);

  const batch = firestore.batch();
  expiredDocs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  console.log(`Deleted ${expiredDocs.length} expired registrations`);

  return expiredDocs.length;
}

/**
 * Check if an email already has a pending registration
 *
 * @param {string} email - Email address to check
 * @returns {Promise<boolean>}
 */
export async function hasPendingRegistration(email) {
  const snapshot = await firestore
    .collection('pendingRegistrations')
    .where('email', '==', email)
    .where('status', '==', 'pending')
    .get();

  return !snapshot.empty;
}

/**
 * Cancel a pending registration
 *
 * @param {string} email - Email address
 * @returns {Promise<void>}
 */
export async function cancelPendingRegistration(email) {
  const snapshot = await firestore
    .collection('pendingRegistrations')
    .where('email', '==', email)
    .where('status', '==', 'pending')
    .get();

  if (snapshot.empty) {
    return;
  }

  const batch = firestore.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();

  console.log(`Cancelled pending registration for ${email}`);
}
