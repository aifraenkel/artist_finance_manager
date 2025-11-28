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

cd ..

success "Cloud Functions deployment complete!"

info "========================================"
info "Deployed Functions:"
info "1. cleanupDeletedUsers - Runs daily to clean up old deleted users"
info "2. sendLoginNotification - Sends security notifications"
info ""
info "Next steps:"
info "- Set up Firestore triggers for onUserCreated and onUserDeleted"
info "- Configure email service (SendGrid, Mailgun, etc.)"
info "- Update functions/index.js with email service integration"
info "========================================"

exit 0
