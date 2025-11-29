#!/bin/bash

# Deploy Cloud Functions with AWS SES configuration
# Reads AWS credentials from functions/.env and deploys with environment variables

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

PROJECT_ID=${GCP_PROJECT_ID:-"artist-manager-479514"}
REGION=${GCP_REGION:-"us-central1"}

info "Deploying Cloud Functions with AWS SES"
info "Project: $PROJECT_ID"
info "Region: $REGION"
echo ""

# Check if .env file exists
if [ ! -f "functions/.env" ]; then
    error "functions/.env not found!"
    info "Run: ./scripts/setup_aws_ses.sh first"
    exit 1
fi

# Load environment variables from .env
info "Loading AWS SES configuration..."
export $(cat functions/.env | grep -v '^#' | xargs)

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$SES_SENDER_EMAIL" ]; then
    error "Missing AWS SES configuration in functions/.env"
    info "Required variables: AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, SES_SENDER_EMAIL"
    exit 1
fi

success "AWS SES configuration loaded"
info "Region: $AWS_REGION"
info "Sender: $SES_SENDER_EMAIL"
echo ""

# Check if functions directory exists
if [ ! -d "functions" ]; then
    error "functions directory not found"
    exit 1
fi

cd functions

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    info "Installing function dependencies..."
    npm install
    success "Dependencies installed"
fi

cd ..

# Deploy cleanup function with environment variables
info "Deploying cleanupDeletedUsers function..."
gcloud functions deploy cleanupDeletedUsers \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=functions \
  --entry-point=cleanupDeletedUsers \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars "AWS_REGION=$AWS_REGION,AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY,SES_SENDER_EMAIL=$SES_SENDER_EMAIL" \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
    success "cleanupDeletedUsers deployed"
else
    error "Failed to deploy cleanupDeletedUsers"
    exit 1
fi

# Deploy login notification function
info "Deploying sendLoginNotification function..."
gcloud functions deploy sendLoginNotification \
  --gen2 \
  --runtime=nodejs20 \
  --region=$REGION \
  --source=functions \
  --entry-point=sendLoginNotification \
  --trigger-http \
  --allow-unauthenticated \
  --set-env-vars "AWS_REGION=$AWS_REGION,AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY,SES_SENDER_EMAIL=$SES_SENDER_EMAIL" \
  --project=$PROJECT_ID

if [ $? -eq 0 ]; then
    success "sendLoginNotification deployed"
else
    warning "Failed to deploy sendLoginNotification"
fi

# Get function URLs
CLEANUP_URL=$(gcloud functions describe cleanupDeletedUsers \
  --gen2 \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(serviceConfig.uri)" 2>/dev/null)

if [ -n "$CLEANUP_URL" ]; then
    info "Cleanup function URL: $CLEANUP_URL"

    # Create or update Cloud Scheduler job
    info "Configuring Cloud Scheduler..."

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
        success "Cloud Scheduler configured (runs daily at 2 AM)"
    else
        warning "Failed to configure Cloud Scheduler"
    fi
fi

echo ""
success "Cloud Functions deployment complete!"
echo ""
info "======================================"
info "Deployed Functions:"
info "======================================"
info "✓ cleanupDeletedUsers - Runs daily to clean up old deleted users"
info "✓ sendLoginNotification - Sends security notifications"
info ""
info "Email Configuration:"
info "  Provider: AWS SES"
info "  Region: $AWS_REGION"
info "  Sender: $SES_SENDER_EMAIL"
info ""
info "Test email sending:"
info "  curl -X POST $CLEANUP_URL"
info "======================================"

exit 0
