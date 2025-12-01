/**
 * Delete test user account
 * 
 * Usage: node delete_test_user.js aifraenkel@gmail.com
 */

import admin from 'firebase-admin';
import { Firestore } from '@google-cloud/firestore';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'artist-manager-479514'
  });
}

const firestore = new Firestore();

async function deleteUser(email) {
  try {
    console.log(`Looking up user: ${email}...`);
    
    // Get user by email
    const user = await admin.auth().getUserByEmail(email);
    console.log(`Found user: ${user.uid}`);
    
    // Delete Firestore document
    console.log('Deleting Firestore document...');
    await firestore.collection('users').doc(user.uid).delete();
    console.log('✅ Firestore document deleted');
    
    // Delete Firebase Auth user
    console.log('Deleting Firebase Auth user...');
    await admin.auth().deleteUser(user.uid);
    console.log('✅ Firebase Auth user deleted');
    
    console.log(`\n✅ Successfully deleted user: ${email}`);
    
  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.log(`User ${email} not found in Firebase Auth`);
    } else {
      console.error('Error:', error.message);
    }
  }
}

const email = process.argv[2] || 'aifraenkel@gmail.com';
deleteUser(email);
