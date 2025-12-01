import admin from 'firebase-admin';

admin.initializeApp();

const email = process.argv[2] || 'alejandro@artfinhub.com';

try {
  const user = await admin.auth().getUserByEmail(email);
  console.log('✅ User found:');
  console.log('UID:', user.uid);
  console.log('Email:', user.email);
  console.log('Email Verified:', user.emailVerified);
  console.log('Display Name:', user.displayName);
  console.log('Created:', new Date(user.metadata.creationTime));
  console.log('Last Sign In:', user.metadata.lastSignInTime ? new Date(user.metadata.lastSignInTime) : 'Never');
} catch (error) {
  if (error.code === 'auth/user-not-found') {
    console.log('❌ User not found:', email);
  } else {
    console.error('Error:', error.message);
  }
}
