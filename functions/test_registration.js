/**
 * Test script for registration flow
 * 
 * Usage: node test_registration.js
 */

import { Firestore } from '@google-cloud/firestore';
import { createPendingRegistration } from './registration_service.js';

const firestore = new Firestore();

async function testRegistrationFlow() {
  try {
    console.log('Creating pending registration for aifraenkel@gmail.com...');
    
    const { token, expiresAt } = await createPendingRegistration(
      'aifraenkel@gmail.com',
      'Test User',
      'https://artist-manager-479514.web.app'
    );
    
    console.log('\n✅ Registration created successfully!');
    console.log('Token:', token);
    console.log('Expires at:', expiresAt.toISOString());
    console.log('\nNow test with curl:');
    console.log(`
curl -X POST https://us-central1-artist-manager-479514.cloudfunctions.net/verifyRegistrationToken \\
  -H "Content-Type: application/json" \\
  -d '{"token": "${token}"}' | jq .
    `);
    
  } catch (error) {
    console.error('Error:', error);
  }
}

testRegistrationFlow();
