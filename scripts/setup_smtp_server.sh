#!/bin/bash

# Deploy self-hosted SMTP server (Mailpit) on Cloud Run
# Mailpit is a lightweight SMTP server with a web UI for testing

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
section() { echo -e "${CYAN}[STEP]${NC} $1"; }

PROJECT_ID=${GCP_PROJECT_ID:-"artist-manager-479514"}
REGION=${GCP_REGION:-"us-central1"}
SERVICE_NAME="mailpit-smtp"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Deploy Self-Hosted SMTP Server (Mailpit) on Cloud Run   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
info "Project: $PROJECT_ID"
info "Region: $REGION"
info "Service: $SERVICE_NAME"
echo ""

section "Option 1: Mailpit (Recommended for Testing)"
info "Mailpit is a lightweight SMTP server with web UI"
info "Perfect for development and testing"
info "100% free, no limits"
echo ""

section "Option 2: Resend API (Recommended for Production)"
info "Modern email API with generous free tier"
info "3,000 emails/month free"
info "No SMTP server needed, just API calls"
echo ""

read -p "Choose option (1 for Mailpit, 2 for Resend): " CHOICE

if [ "$CHOICE" = "2" ]; then
    info "Setting up Resend API integration..."
    info ""
    info "To use Resend:"
    info "1. Sign up at: https://resend.com/signup"
    info "2. Get your API key from: https://resend.com/api-keys"
    info "3. Free tier: 3,000 emails/month, 100 emails/day"
    info ""
    read -sp "Enter your Resend API key: " RESEND_API_KEY
    echo ""
    read -p "Enter sender email (must be verified in Resend): " SENDER_EMAIL

    # Save to .env
    mkdir -p functions
    cat > functions/.env <<EOF
# Resend Configuration
RESEND_API_KEY=$RESEND_API_KEY
RESEND_SENDER_EMAIL=$SENDER_EMAIL
RESEND_SENDER_NAME=Art Finance Hub
EMAIL_PROVIDER=resend
EOF

    success "Resend configuration saved to functions/.env"

    # Create Resend email service
    cat > functions/email_service_resend.js <<'JSEOF'
/**
 * Resend Email Service
 * Modern email API - no SMTP server needed
 */

import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);
const SENDER_EMAIL = process.env.RESEND_SENDER_EMAIL || 'onboarding@resend.dev';
const SENDER_NAME = process.env.RESEND_SENDER_NAME || 'Art Finance Hub';

export async function sendEmail(to, subject, htmlBody, textBody) {
  try {
    const data = await resend.emails.send({
      from: `${SENDER_NAME} <${SENDER_EMAIL}>`,
      to: [to],
      subject: subject,
      html: htmlBody,
      text: textBody,
    });

    console.log('Email sent via Resend:', data.id);
    return { success: true, id: data.id };
  } catch (error) {
    console.error('Resend error:', error);
    throw error;
  }
}

// Import the email templates from email_service.js
export { sendWelcomeEmail, sendAccountDeletionEmail, sendLoginNotificationEmail } from './email_service.js';
JSEOF

    # Update package.json
    cd functions
    npm init -y 2>/dev/null || true
    npm install resend
    cd ..

    success "Resend setup complete!"
    info "Update functions/index.js to import from './email_service_resend.js'"
    exit 0
fi

# Continue with Mailpit setup
section "Step 1: Creating Mailpit Dockerfile"
echo ""

mkdir -p smtp-server

cat > smtp-server/Dockerfile <<'EOF'
FROM axllent/mailpit:latest

# Mailpit runs on:
# - Port 1025: SMTP server
# - Port 8025: Web UI

EXPOSE 1025 8025

# Set environment variables
ENV MP_SMTP_AUTH_ACCEPT_ANY=1
ENV MP_SMTP_AUTH_ALLOW_INSECURE=1

CMD ["mailpit"]
EOF

success "Dockerfile created"
echo ""

section "Step 2: Building and Deploying to Cloud Run"
echo ""

info "Building Docker image..."
gcloud builds submit smtp-server \
  --tag gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --project=$PROJECT_ID

success "Image built"
echo ""

info "Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --port 8025 \
  --set-env-vars "MP_SMTP_AUTH_ACCEPT_ANY=1,MP_SMTP_AUTH_ALLOW_INSECURE=1" \
  --project=$PROJECT_ID

success "Mailpit deployed!"
echo ""

section "Step 3: Getting Service Details"
echo ""

SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(status.url)")

SMTP_HOST=$(echo $SERVICE_URL | sed 's|https://||' | sed 's|http://||')

success "Service URL: $SERVICE_URL"
info "SMTP Host: $SMTP_HOST"
info "SMTP Port: 1025 (internal)"
info "Web UI: $SERVICE_URL (for viewing sent emails)"
echo ""

section "Step 4: Configuring Email Service"
echo ""

# Save configuration
mkdir -p functions
cat > functions/.env <<EOF
# Mailpit SMTP Configuration
SMTP_HOST=$SMTP_HOST
SMTP_PORT=1025
SMTP_USER=
SMTP_PASS=
SMTP_SECURE=false
SENDER_EMAIL=noreply@artist-finance-manager.local
SENDER_NAME=Art Finance Hub
EMAIL_PROVIDER=smtp
MAILPIT_WEB_UI=$SERVICE_URL
EOF

success "Configuration saved to functions/.env"
echo ""

# Create SMTP email service using nodemailer
cat > functions/email_service_smtp.js <<'JSEOF'
/**
 * SMTP Email Service using Nodemailer
 * Works with Mailpit or any SMTP server
 */

import nodemailer from 'nodemailer';

const SMTP_HOST = process.env.SMTP_HOST;
const SMTP_PORT = parseInt(process.env.SMTP_PORT) || 1025;
const SMTP_USER = process.env.SMTP_USER || '';
const SMTP_PASS = process.env.SMTP_PASS || '';
const SMTP_SECURE = process.env.SMTP_SECURE === 'true';
const SENDER_EMAIL = process.env.SENDER_EMAIL || 'noreply@example.com';
const SENDER_NAME = process.env.SENDER_NAME || 'Art Finance Hub';

// Create transporter
const transporter = nodemailer.createTransporter({
  host: SMTP_HOST,
  port: SMTP_PORT,
  secure: SMTP_SECURE,
  auth: SMTP_USER ? {
    user: SMTP_USER,
    pass: SMTP_PASS,
  } : undefined,
  tls: {
    rejectUnauthorized: false
  }
});

export async function sendEmail(to, subject, htmlBody, textBody) {
  try {
    const info = await transporter.sendMail({
      from: `"${SENDER_NAME}" <${SENDER_EMAIL}>`,
      to: to,
      subject: subject,
      text: textBody,
      html: htmlBody,
    });

    console.log('Email sent via SMTP:', info.messageId);
    console.log('Preview URL:', nodemailer.getTestMessageUrl(info));
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('SMTP error:', error);
    throw error;
  }
}

// Import the email templates
export { sendWelcomeEmail, sendAccountDeletionEmail, sendLoginNotificationEmail } from './email_service.js';
JSEOF

# Update package.json
cd functions
npm init -y 2>/dev/null || true
npm install nodemailer
cd ..

success "SMTP email service created"
echo ""

success "Setup complete!"
echo ""
info "══════════════════════════════════════════════════════════"
info "Mailpit SMTP Server Deployed!"
info "══════════════════════════════════════════════════════════"
info "Web UI: $SERVICE_URL"
info "SMTP Host: $SMTP_HOST"
info "SMTP Port: 1025"
info ""
info "To view sent emails:"
info "Open: $SERVICE_URL"
info ""
info "Next steps:"
info "1. Update functions/index.js to use email_service_smtp.js"
info "2. Deploy functions: ./scripts/deploy_functions_smtp.sh"
info "3. Test by registering a user"
info "4. View emails in Mailpit web UI"
info "══════════════════════════════════════════════════════════"

exit 0
