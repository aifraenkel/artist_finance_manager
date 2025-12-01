#!/bin/bash

# Deploy all Cloud Functions with environment variables
set -e

# Source environment variables from .env
export $(cat .env | grep -v '^#' | xargs)

echo "Deploying Cloud Functions with environment variables..."

# Deploy createRegistration
echo "Deploying createRegistration..."
gcloud functions deploy createRegistration \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=createRegistration \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars SENDGRID_API_KEY="$SENDGRID_API_KEY",SENDER_EMAIL="$SENDER_EMAIL",SENDER_NAME="$SENDER_NAME" \
  --quiet

# Deploy verifyRegistrationToken
echo "Deploying verifyRegistrationToken..."
gcloud functions deploy verifyRegistrationToken \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=verifyRegistrationToken \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars SENDGRID_API_KEY="$SENDGRID_API_KEY",SENDER_EMAIL="$SENDER_EMAIL",SENDER_NAME="$SENDER_NAME" \
  --quiet

# Deploy createSignInRequest
echo "Deploying createSignInRequest..."
gcloud functions deploy createSignInRequest \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=createSignInRequest \
  --trigger-http \
  --allow-unauthenticated \
  --update-env-vars SENDGRID_API_KEY="$SENDGRID_API_KEY",SENDER_EMAIL="$SENDER_EMAIL",SENDER_NAME="$SENDER_NAME" \
  --quiet

# Deploy cleanupExpiredRegistrations (scheduled)
echo "Deploying cleanupExpiredRegistrations..."
gcloud functions deploy cleanupExpiredRegistrations \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=cleanupExpiredRegistrations \
  --trigger-topic=cleanup-expired-registrations \
  --quiet

# Deploy cleanupDeletedUsers (scheduled)
echo "Deploying cleanupDeletedUsers..."
gcloud functions deploy cleanupDeletedUsers \
  --gen2 \
  --runtime=nodejs20 \
  --region=us-central1 \
  --source=. \
  --entry-point=cleanupDeletedUsers \
  --trigger-topic=cleanup-deleted-users \
  --quiet

echo "✅ All functions deployed successfully!"
