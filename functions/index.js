/**
 * Cloud Functions for Artist Finance Manager
 *
 * Functions:
 * - onUserCreated: Send welcome email when user is created
 * - onUserDeleted: Send account deletion confirmation email
 * - cleanupDeletedUsers: Scheduled function to permanently delete old soft-deleted users
 */

import functions from '@google-cloud/functions-framework';
import { Firestore } from '@google-cloud/firestore';
import { sendWelcomeEmail, sendAccountDeletionEmail, sendLoginNotificationEmail } from './email_service.js';

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
  try {
    const { email, name, deviceInfo, ipAddress } = req.body;

    if (!email || !name) {
      res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
      return;
    }

    console.log(`Sending login notification to ${email}`);

    await sendLoginNotificationEmail(email, name, deviceInfo, ipAddress);
    console.log('Login notification sent successfully');

    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error sending login notification:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
