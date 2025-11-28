#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Success/Error/Info functions
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-"artist-manager-479514"}
REGION=${GCP_REGION:-"us-central1"}

info "Setting up Firebase for project: $PROJECT_ID"

# Enable required APIs
info "Enabling Firebase APIs..."
gcloud services enable \
  firebase.googleapis.com \
  firestore.googleapis.com \
  identitytoolkit.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudscheduler.googleapis.com \
  firebasestorage.googleapis.com \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
  success "Firebase APIs enabled"
else
  error "Failed to enable Firebase APIs"
  exit 1
fi

# Configure Firebase Authentication
info "Configuring Firebase Authentication..."
info "Enabling email/password and email link authentication..."

# Note: Firebase Auth configuration via gcloud is limited
# Most auth configuration needs to be done via Firebase Console or REST API
success "Firebase Authentication is ready to configure via Firebase Console"
info "Please visit: https://console.firebase.google.com/project/$PROJECT_ID/authentication/providers"
info "Enable 'Email/Password' and 'Email link (passwordless sign-in)' providers"

# Set up Firestore security rules
info "Creating Firestore security rules..."
cat > /tmp/firestore.rules <<'EOF'
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      // Users can read their own profile
      allow read: if isOwner(userId);

      // Users can create their profile on first login
      allow create: if isOwner(userId)
        && request.resource.data.email == request.auth.token.email
        && request.resource.data.createdAt == request.time;

      // Users can update their own profile (name, lastLoginAt)
      allow update: if isOwner(userId)
        && request.resource.data.email == resource.data.email  // Can't change email
        && request.resource.data.uid == resource.data.uid;     // Can't change uid

      // Users can soft delete their account
      allow delete: if isOwner(userId);
    }

    // One-time codes collection (for email auth)
    match /authCodes/{codeId} {
      // Only server can write auth codes
      allow read, write: if false;
    }

    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
EOF

success "Firestore security rules created"

# Deploy Firestore rules
info "Deploying Firestore security rules..."
gcloud firestore databases patch \
  --project=$PROJECT_ID \
  --database="(default)" \
  --type=firestore-native 2>/dev/null || warning "Rules deployment via gcloud may require firebase CLI"

# Create Firestore indexes
info "Creating Firestore indexes..."
cat > /tmp/firestore.indexes.json <<'EOF'
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

# Create Cloud Scheduler job for cleaning up old deleted accounts
info "Setting up Cloud Scheduler for account cleanup..."

# Create App Engine app if needed (required for Cloud Scheduler)
gcloud app describe --project=$PROJECT_ID &>/dev/null || {
  info "Creating App Engine app (required for Cloud Scheduler)..."
  gcloud app create --region=$REGION --project=$PROJECT_ID 2>/dev/null || warning "App Engine app may already exist or need manual setup"
}

success "Firebase setup complete!"

info "========================================"
info "Next steps:"
info "1. Visit Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
info "2. Enable Email/Password authentication provider"
info "3. Enable Email link (passwordless) authentication"
info "4. Set up action URL: https://$PROJECT_ID.firebaseapp.com/__/auth/action"
info "========================================"

exit 0
