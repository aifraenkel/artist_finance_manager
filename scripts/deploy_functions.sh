#!/bin/bash

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

info "Deploying Cloud Functions for project: $PROJECT_ID"

# Check if functions directory exists
if [ ! -d "functions" ]; then
  error "functions directory not found"
  exit 1
fi

cd functions || exit 1

# Install dependencies
if [ ! -d "node_modules" ]; then
  info "Installing function dependencies..."
  npm install
  if [ $? -ne 0 ]; then
    error "Failed to install dependencies"
    exit 1
  fi
  success "Dependencies installed"
fi

# Deploy cleanup function (HTTP function called by Cloud Scheduler)
info "Deploying cleanupDeletedUsers function..."
gcloud functions deploy cleanupDeletedUsers \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=cleanupDeletedUsers \
  --trigger-http \
  --allow-unauthenticated \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
  success "cleanupDeletedUsers function deployed"
else
  error "Failed to deploy cleanupDeletedUsers function"
  exit 1
fi

# Deploy login notification function
info "Deploying sendLoginNotification function..."
gcloud functions deploy sendLoginNotification \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=sendLoginNotification \
  --trigger-http \
  --allow-unauthenticated \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
  success "sendLoginNotification function deployed"
else
  warning "Failed to deploy sendLoginNotification function"
fi

# Deploy createRegistration function
info "Deploying createRegistration function..."
gcloud functions deploy createRegistration \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=createRegistration \
  --trigger-http \
  --allow-unauthenticated \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
  success "createRegistration function deployed"
else
  error "Failed to deploy createRegistration function"
  exit 1
fi

# Deploy verifyRegistrationToken function
info "Deploying verifyRegistrationToken function..."
gcloud functions deploy verifyRegistrationToken \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=verifyRegistrationToken \
  --trigger-http \
  --allow-unauthenticated \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
  success "verifyRegistrationToken function deployed"
else
  error "Failed to deploy verifyRegistrationToken function"
  exit 1
fi

# Deploy createSignInRequest function
info "Deploying createSignInRequest function..."
gcloud functions deploy createSignInRequest \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=createSignInRequest \
  --trigger-http \
  --allow-unauthenticated \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
  success "createSignInRequest function deployed"
else
  error "Failed to deploy createSignInRequest function"
  exit 1
fi

# Deploy cleanupExpiredRegistrations function
info "Deploying cleanupExpiredRegistrations function..."
gcloud functions deploy cleanupExpiredRegistrations \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=. \
  --entry-point=cleanupExpiredRegistrations \
  --trigger-http \
  --allow-unauthenticated \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
  success "cleanupExpiredRegistrations function deployed"
else
  warning "Failed to deploy cleanupExpiredRegistrations function"
fi

# Get function URL for cleanup function
CLEANUP_URL=$(gcloud functions describe cleanupDeletedUsers \
  --gen2 \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(serviceConfig.uri)" 2>/dev/null)

if [ -n "$CLEANUP_URL" ]; then
  info "Cleanup function URL: $CLEANUP_URL"

  # Create Cloud Scheduler job
  info "Creating Cloud Scheduler job..."

  # Check if job already exists
  gcloud scheduler jobs describe cleanup-deleted-users \
    --location=$REGION \
    --project=$PROJECT_ID &>/dev/null

  if [ $? -eq 0 ]; then
    info "Updating existing scheduler job..."
    gcloud scheduler jobs update http cleanup-deleted-users \
      --location=$REGION \
      --schedule="0 2 * * *" \
      --uri="$CLEANUP_URL" \
      --http-method=GET \
      --project=$PROJECT_ID
  else
    info "Creating new scheduler job..."
    gcloud scheduler jobs create http cleanup-deleted-users \
      --location=$REGION \
      --schedule="0 2 * * *" \
      --uri="$CLEANUP_URL" \
      --http-method=GET \
      --project=$PROJECT_ID
  fi

  if [ $? -eq 0 ]; then
    success "Cloud Scheduler job configured (runs daily at 2 AM)"
  else
    warning "Failed to configure Cloud Scheduler job"
  fi
fi

# Get function URL for cleanup expired registrations function
CLEANUP_REG_URL=$(gcloud functions describe cleanupExpiredRegistrations \
  --gen2 \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(serviceConfig.uri)" 2>/dev/null)

if [ -n "$CLEANUP_REG_URL" ]; then
  info "Cleanup registrations function URL: $CLEANUP_REG_URL"

  # Create Cloud Scheduler job for expired registrations
  info "Creating Cloud Scheduler job for expired registrations..."

  # Check if job already exists
  gcloud scheduler jobs describe cleanup-expired-registrations \
    --location=$REGION \
    --project=$PROJECT_ID &>/dev/null

  if [ $? -eq 0 ]; then
    info "Updating existing scheduler job..."
    gcloud scheduler jobs update http cleanup-expired-registrations \
      --location=$REGION \
      --schedule="0 3 * * *" \
      --uri="$CLEANUP_REG_URL" \
      --http-method=GET \
      --project=$PROJECT_ID
  else
    info "Creating new scheduler job..."
    gcloud scheduler jobs create http cleanup-expired-registrations \
      --location=$REGION \
      --schedule="0 3 * * *" \
      --uri="$CLEANUP_REG_URL" \
      --http-method=GET \
      --project=$PROJECT_ID
  fi

  if [ $? -eq 0 ]; then
    success "Cloud Scheduler job configured (runs daily at 3 AM)"
  else
    warning "Failed to configure Cloud Scheduler job for expired registrations"
  fi
fi

cd ..

success "Cloud Functions deployment complete!"

# Get function URLs
CREATE_REG_URL=$(gcloud functions describe createRegistration \
  --gen2 \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(serviceConfig.uri)" 2>/dev/null)

VERIFY_TOKEN_URL=$(gcloud functions describe verifyRegistrationToken \
  --gen2 \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(serviceConfig.uri)" 2>/dev/null)

CREATE_SIGNIN_URL=$(gcloud functions describe createSignInRequest \
  --gen2 \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(serviceConfig.uri)" 2>/dev/null)

info "========================================"
info "Deployed Functions:"
info "1. cleanupDeletedUsers - Runs daily to clean up old deleted users"
info "2. sendLoginNotification - Sends security notifications"
info "3. createRegistration - Creates registration tokens and sends verification emails"
info "4. verifyRegistrationToken - Verifies registration tokens"
info "5. createSignInRequest - Creates sign-in tokens for existing users"
info "6. cleanupExpiredRegistrations - Cleans up expired registration tokens"
info ""
info "Function URLs:"
info "  createRegistration: $CREATE_REG_URL"
info "  verifyRegistrationToken: $VERIFY_TOKEN_URL"
info "  createSignInRequest: $CREATE_SIGNIN_URL"
info ""
info "IMPORTANT: Update lib/services/registration_api_service.dart"
info "Replace _functionsBaseUrl with: https://us-central1-$PROJECT_ID.cloudfunctions.net"
info ""
info "Next steps:"
info "- Update registration_api_service.dart with the correct base URL"
info "- Set up Firestore triggers for onUserCreated and onUserDeleted"
info "- Configure email service (SMTP, SendGrid, etc.)"
info "- Test the registration flow across different devices"
info "========================================"

exit 0
