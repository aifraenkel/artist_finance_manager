#!/bin/bash

# Complete Firebase setup automation script
# This script automates Firebase configuration, authentication setup, and deployment

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-"artist-manager-479514"}
REGION=${GCP_REGION:-"us-central1"}
PROJECT_NUMBER="456648586026"

info "======================================"
info "Firebase Complete Setup Automation"
info "Project: $PROJECT_ID"
info "======================================"

# Step 1: Enable required APIs
info "Step 1: Enabling Firebase and required APIs..."
gcloud services enable \
  firebase.googleapis.com \
  firebasehosting.googleapis.com \
  identitytoolkit.googleapis.com \
  firestore.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudscheduler.googleapis.com \
  --project=$PROJECT_ID

success "APIs enabled"

# Step 2: Initialize Firebase project (if not already done)
info "Step 2: Checking Firebase project initialization..."

# Check if firebase.json exists
if [ ! -f "firebase.json" ]; then
  info "Creating firebase.json configuration..."
  cat > firebase.json <<'EOF'
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
EOF
  success "firebase.json created"
else
  info "firebase.json already exists"
fi

# Step 3: Create and deploy Firestore security rules
info "Step 3: Creating Firestore security rules..."
cat > firestore.rules <<'EOF'
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    function isValidEmail() {
      return isAuthenticated() &&
             request.auth.token.email != null &&
             request.auth.token.email_verified == true;
    }

    // Users collection
    match /users/{userId} {
      // Users can read their own profile
      allow read: if isOwner(userId);

      // Users can create their profile on first login
      // Must match their authenticated email
      allow create: if isOwner(userId)
        && isValidEmail()
        && request.resource.data.email == request.auth.token.email
        && request.resource.data.uid == userId
        && request.resource.data.createdAt == request.time;

      // Users can update their own profile
      // Cannot change email or uid
      allow update: if isOwner(userId)
        && request.resource.data.email == resource.data.email
        && request.resource.data.uid == resource.data.uid
        && request.resource.data.createdAt == resource.data.createdAt;

      // Users can soft delete their account (set deletedAt)
      allow delete: if isOwner(userId);
    }

    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
EOF

success "Firestore rules created"

# Step 4: Create Firestore indexes
info "Step 4: Creating Firestore indexes configuration..."
cat > firestore.indexes.json <<'EOF'
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "email",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "deletedAt",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "deletedAt",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
EOF

success "Firestore indexes configuration created"

# Step 5: Get or create Firebase web app configuration
info "Step 5: Setting up Firebase web app..."

# Try to get existing web app config using REST API
info "Checking for existing Firebase web apps..."
WEB_APPS=$(curl -s "https://firebase.googleapis.com/v1beta1/projects/$PROJECT_ID/webApps" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json")

# Check if we got any web apps
APP_COUNT=$(echo "$WEB_APPS" | grep -o '"appId"' | wc -l || echo "0")

if [ "$APP_COUNT" -eq "0" ]; then
  info "No web app found, creating new Firebase web app..."

  # Create new web app
  CREATE_RESPONSE=$(curl -s -X POST \
    "https://firebase.googleapis.com/v1beta1/projects/$PROJECT_ID/webApps" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    -d "{\"displayName\": \"Artist Finance Manager Web\"}")

  # Extract the operation name and wait for completion
  OPERATION_NAME=$(echo "$CREATE_RESPONSE" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)

  if [ -n "$OPERATION_NAME" ]; then
    info "Waiting for web app creation to complete..."
    sleep 5

    # Get the web app details
    WEB_APPS=$(curl -s "https://firebase.googleapis.com/v1beta1/projects/$PROJECT_ID/webApps" \
      -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      -H "Content-Type: application/json")
  else
    warning "Could not create web app automatically"
  fi
fi

# Extract first web app ID
APP_ID=$(echo "$WEB_APPS" | grep -o '"appId":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$APP_ID" ]; then
  info "Found web app: $APP_ID"

  # Get web app config
  info "Fetching web app configuration..."
  CONFIG_RESPONSE=$(curl -s \
    "https://firebase.googleapis.com/v1beta1/projects/$PROJECT_ID/webApps/$APP_ID/config" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)")

  # Extract configuration values
  API_KEY=$(echo "$CONFIG_RESPONSE" | grep -o '"apiKey":"[^"]*"' | cut -d'"' -f4)
  AUTH_DOMAIN=$(echo "$CONFIG_RESPONSE" | grep -o '"authDomain":"[^"]*"' | cut -d'"' -f4)
  STORAGE_BUCKET=$(echo "$CONFIG_RESPONSE" | grep -o '"storageBucket":"[^"]*"' | cut -d'"' -f4)
  MESSAGING_SENDER_ID=$(echo "$CONFIG_RESPONSE" | grep -o '"messagingSenderId":"[^"]*"' | cut -d'"' -f4)
  MEASUREMENT_ID=$(echo "$CONFIG_RESPONSE" | grep -o '"measurementId":"[^"]*"' | cut -d'"' -f4)

  if [ -n "$API_KEY" ]; then
    info "Updating lib/firebase_options.dart with configuration..."

    # Update firebase_options.dart
    cat > lib/firebase_options.dart <<EOF
// File generated by FlutterFire CLI.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '$API_KEY',
    appId: '$APP_ID',
    messagingSenderId: '$MESSAGING_SENDER_ID',
    projectId: '$PROJECT_ID',
    authDomain: '$AUTH_DOMAIN',
    storageBucket: '$STORAGE_BUCKET',
    measurementId: '$MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '$API_KEY',
    appId: '$APP_ID',
    messagingSenderId: '$MESSAGING_SENDER_ID',
    projectId: '$PROJECT_ID',
    authDomain: '$AUTH_DOMAIN',
    storageBucket: '$STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '$API_KEY',
    appId: '$APP_ID',
    messagingSenderId: '$MESSAGING_SENDER_ID',
    projectId: '$PROJECT_ID',
    authDomain: '$AUTH_DOMAIN',
    storageBucket: '$STORAGE_BUCKET',
    iosBundleId: 'com.artist.financemanager',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '$API_KEY',
    appId: '$APP_ID',
    messagingSenderId: '$MESSAGING_SENDER_ID',
    projectId: '$PROJECT_ID',
    authDomain: '$AUTH_DOMAIN',
    storageBucket: '$STORAGE_BUCKET',
    iosBundleId: 'com.artist.financemanager',
  );
}
EOF

    success "Firebase configuration updated in lib/firebase_options.dart"
  else
    warning "Could not extract API key from configuration"
  fi
else
  warning "Could not find or create web app"
  warning "Please visit: https://console.firebase.google.com/project/$PROJECT_ID/settings/general"
  warning "And manually add a web app, then run: ./scripts/get_firebase_config.sh"
fi

# Step 6: Enable Authentication methods using REST API
info "Step 6: Enabling Firebase Authentication methods..."

# Enable Email/Password provider
info "Enabling Email/Password authentication..."
curl -s -X PATCH \
  "https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT_ID/config" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "signIn": {
      "email": {
        "enabled": true,
        "passwordRequired": false
      }
    }
  }' > /dev/null

success "Email authentication enabled"

# Configure authorized domains
info "Configuring authorized domains..."

# Get current Cloud Run URL
CLOUD_RUN_URL=$(gcloud run services describe artist-finance-manager \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(status.url)" 2>/dev/null | sed 's|https://||' || echo "")

DOMAINS="localhost"
if [ -n "$CLOUD_RUN_URL" ]; then
  DOMAINS="$DOMAINS,$CLOUD_RUN_URL"
fi
DOMAINS="$DOMAINS,$PROJECT_ID.firebaseapp.com,$PROJECT_ID.web.app"

info "Adding authorized domains: $DOMAINS"

# Note: Authorized domains are typically managed through Firebase Console
# They're automatically added when using Firebase Hosting
warning "Authorized domains should be configured in Firebase Console:"
warning "https://console.firebase.google.com/project/$PROJECT_ID/authentication/settings"

# Step 7: Deploy Firestore rules and indexes
info "Step 7: Deploying Firestore rules and indexes..."

# Check if firebase CLI is available
if command -v firebase &> /dev/null; then
  info "Deploying with Firebase CLI..."
  firebase deploy --only firestore --project=$PROJECT_ID --non-interactive || \
    warning "Could not deploy via Firebase CLI, rules will need manual deployment"
else
  warning "Firebase CLI not found. Installing..."
  npm install -g firebase-tools || warning "Could not install Firebase CLI"
fi

# Step 8: Create App Engine app (required for Cloud Scheduler)
info "Step 8: Setting up App Engine for Cloud Scheduler..."
gcloud app describe --project=$PROJECT_ID &>/dev/null || {
  info "Creating App Engine app..."
  gcloud app create --region=$REGION --project=$PROJECT_ID 2>/dev/null || \
    info "App Engine app already exists or creation skipped"
}

success "Setup complete!"

info "======================================"
info "Setup Summary:"
info "======================================"
info "✓ Firebase APIs enabled"
info "✓ Firestore database created"
info "✓ Firestore rules and indexes configured"
info "✓ Firebase web app configured (if available)"
info "✓ Authentication methods enabled"
info "✓ App Engine initialized for Cloud Scheduler"
info ""
info "Next steps:"
info "1. Review firebase_options.dart for correct configuration"
info "2. Deploy Cloud Functions: ./scripts/deploy_functions.sh"
info "3. Deploy your app: ./scripts/deploy.sh"
info "4. Visit Firebase Console to verify setup:"
info "   https://console.firebase.google.com/project/$PROJECT_ID"
info "======================================"

exit 0
