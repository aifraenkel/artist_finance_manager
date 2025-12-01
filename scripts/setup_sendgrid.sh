#!/bin/bash

# SendGrid Setup Script for GCP
# Sets up SendGrid email service via GCP Marketplace integration

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

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        SendGrid Email Service Setup (GCP Native)          ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
info "Project: $PROJECT_ID"
echo ""

section "Step 1: Get SendGrid API Key"
echo ""
info "SendGrid offers 12,000 free emails/month forever!"
echo ""
info "To get your SendGrid API key:"
echo "1. Visit: https://console.cloud.google.com/marketplace/product/sendgrid-app/sendgrid-email"
echo "2. Click 'Enable' or 'Manage' (if already enabled)"
echo "3. Or sign up directly: https://signup.sendgrid.com/"
echo ""
info "After signing up:"
echo "1. Go to Settings > API Keys: https://app.sendgrid.com/settings/api_keys"
echo "2. Click 'Create API Key'"
echo "3. Name: 'Artist Finance Manager'"
echo "4. Permission: 'Full Access' or 'Restricted Access' with Mail Send"
echo "5. Copy the API key (you'll only see it once!)"
echo ""

read -p "Press Enter when you have your SendGrid API key ready..."

# Get API key from user
echo ""
read -sp "Paste your SendGrid API Key: " SENDGRID_API_KEY
echo ""

if [ -z "$SENDGRID_API_KEY" ]; then
    error "API key is required"
    exit 1
fi

success "API key received"
echo ""

section "Step 2: Configure Sender Email"
echo ""
info "You need a verified sender email address"
read -p "Enter the email address to send from (e.g., noreply@yourdomain.com): " SENDER_EMAIL

if [ -z "$SENDER_EMAIL" ]; then
    error "Sender email is required"
    exit 1
fi

success "Using sender email: $SENDER_EMAIL"
echo ""

info "Important: You must verify this email in SendGrid"
info "1. Go to: https://app.sendgrid.com/settings/sender_auth/senders"
info "2. Click 'Create New Sender' or 'Verify Sender'"
info "3. Enter your email and complete verification"
echo ""

read -p "Press Enter after you've started the verification process..."

section "Step 3: Saving Configuration"
echo ""

# Save to .env file
mkdir -p functions
cat > functions/.env <<EOF
# SendGrid Configuration
SENDGRID_API_KEY=$SENDGRID_API_KEY
SENDGRID_SENDER_EMAIL=$SENDER_EMAIL
SENDGRID_SENDER_NAME=Artist Finance Manager
EOF

success "Configuration saved to functions/.env"
warning "⚠️  Keep this file secure! It's already in .gitignore"
echo ""

section "Step 4: Creating Email Service Module"
echo ""

# Create SendGrid email service module
cat > functions/email_service.js <<'JSEOF'
/**
 * SendGrid Email Service
 * Handles sending emails via SendGrid API
 */

import sgMail from '@sendgrid/mail';

// Initialize SendGrid
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
const SENDER_EMAIL = process.env.SENDGRID_SENDER_EMAIL || 'noreply@example.com';
const SENDER_NAME = process.env.SENDGRID_SENDER_NAME || 'Artist Finance Manager';

if (SENDGRID_API_KEY) {
  sgMail.setApiKey(SENDGRID_API_KEY);
} else {
  console.warn('SendGrid API key not configured');
}

/**
 * Send email via SendGrid
 * @param {string} to - Recipient email address
 * @param {string} subject - Email subject
 * @param {string} htmlBody - HTML email body
 * @param {string} textBody - Plain text email body
 */
export async function sendEmail(to, subject, htmlBody, textBody) {
  const msg = {
    to,
    from: {
      email: SENDER_EMAIL,
      name: SENDER_NAME,
    },
    subject,
    text: textBody,
    html: htmlBody,
  };

  try {
    const response = await sgMail.send(msg);
    console.log('Email sent successfully:', response[0].statusCode);
    return { success: true, statusCode: response[0].statusCode };
  } catch (error) {
    console.error('Error sending email:', error);
    if (error.response) {
      console.error('SendGrid error:', error.response.body);
    }
    throw error;
  }
}

/**
 * Send welcome email
 */
export async function sendWelcomeEmail(to, name) {
  const subject = 'Welcome to Artist Finance Manager!';

  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #2563EB 0%, #1E40AF 100%); color: white; padding: 40px 20px; text-align: center; }
        .header h1 { margin: 0; font-size: 28px; font-weight: 600; }
        .content { padding: 40px 30px; background-color: #ffffff; }
        .content h2 { color: #1E40AF; margin-top: 0; }
        .features { background-color: #F3F4F6; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .features ul { margin: 10px 0; padding-left: 20px; }
        .features li { margin: 8px 0; }
        .button { display: inline-block; padding: 14px 28px; background-color: #2563EB; color: white; text-decoration: none; border-radius: 8px; margin: 20px 0; font-weight: 500; }
        .footer { text-align: center; padding: 30px 20px; color: #6B7280; font-size: 14px; background-color: #F9FAFB; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🎨 Welcome to Artist Finance Manager</h1>
        </div>
        <div class="content">
          <h2>Hello ${name}!</h2>
          <p>Thank you for joining Artist Finance Manager. We're excited to help you take control of your project finances.</p>

          <div class="features">
            <strong>What you can do:</strong>
            <ul>
              <li>📊 Track income and expenses for your creative projects</li>
              <li>💰 View real-time financial summaries and balance</li>
              <li>📝 Manage transactions with ease</li>
              <li>🔒 Keep your financial data secure in the cloud</li>
            </ul>
          </div>

          <p>Ready to get started? Click below to access your dashboard:</p>

          <center>
            <a href="https://artist-finance-manager-456648586026.us-central1.run.app" class="button">Go to Dashboard →</a>
          </center>

          <p style="margin-top: 30px; color: #6B7280; font-size: 14px;">
            Need help? Check out our documentation or reach out to support.
          </p>
        </div>
        <div class="footer">
          <p><strong>Artist Finance Manager</strong></p>
          <p>This email was sent to ${to}</p>
          <p style="margin-top: 15px; font-size: 12px;">
            You received this email because you created an account with Artist Finance Manager
          </p>
        </div>
      </div>
    </body>
    </html>
  `;

  const textBody = `
Hello ${name}!

Thank you for joining Artist Finance Manager. We're excited to help you take control of your project finances.

What you can do:
• Track income and expenses for your creative projects
• View real-time financial summaries and balance
• Manage transactions with ease
• Keep your financial data secure in the cloud

Get started: https://artist-finance-manager-456648586026.us-central1.run.app

Need help? Check out our documentation or reach out to support.

Best regards,
The Artist Finance Manager Team
  `.trim();

  return sendEmail(to, subject, htmlBody, textBody);
}

/**
 * Send account deletion email
 */
export async function sendAccountDeletionEmail(to, name) {
  const subject = 'Your Artist Finance Manager account has been deleted';

  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; }
        .header { background-color: #DC2626; color: white; padding: 40px 20px; text-align: center; }
        .header h1 { margin: 0; font-size: 28px; font-weight: 600; }
        .content { padding: 40px 30px; background-color: #ffffff; }
        .warning { background-color: #FEF3C7; border-left: 4px solid #F59E0B; padding: 16px; margin: 20px 0; border-radius: 4px; }
        .warning strong { color: #92400E; }
        .footer { text-align: center; padding: 30px 20px; color: #6B7280; font-size: 14px; background-color: #F9FAFB; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Account Deleted</h1>
        </div>
        <div class="content">
          <h2>Hello ${name}</h2>
          <p>Your Artist Finance Manager account has been deleted as requested.</p>

          <div class="warning">
            <strong>⏰ Recovery Period:</strong><br>
            Your data will be kept for 90 days in case you change your mind. You can recover your account by signing in again within this period.
          </div>

          <p>After 90 days, your account and all associated data will be permanently deleted.</p>

          <p style="margin-top: 30px;">
            <strong>If you didn't request this deletion:</strong><br>
            Please contact support immediately to secure your account.
          </p>
        </div>
        <div class="footer">
          <p><strong>Artist Finance Manager</strong></p>
          <p>This email was sent to ${to}</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const textBody = `
Hello ${name}

Your Artist Finance Manager account has been deleted as requested.

RECOVERY PERIOD: Your data will be kept for 90 days in case you change your mind. You can recover your account by signing in again within this period.

After 90 days, your account and all associated data will be permanently deleted.

If you didn't request this deletion, please contact support immediately to secure your account.

Best regards,
The Artist Finance Manager Team
  `.trim();

  return sendEmail(to, subject, htmlBody, textBody);
}

/**
 * Send login notification email
 */
export async function sendLoginNotificationEmail(to, name, deviceInfo, ipAddress) {
  const subject = 'New login to your Artist Finance Manager account';
  const timestamp = new Date().toLocaleString('en-US', {
    dateStyle: 'full',
    timeStyle: 'long'
  });

  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; }
        .header { background-color: #F59E0B; color: white; padding: 40px 20px; text-align: center; }
        .header h1 { margin: 0; font-size: 28px; font-weight: 600; }
        .content { padding: 40px 30px; background-color: #ffffff; }
        .info-box { background-color: #EFF6FF; border: 1px solid: #BFDBFE; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .info-box strong { color: #1E40AF; display: block; margin-bottom: 10px; }
        .info-box p { margin: 5px 0; color: #1E3A8A; }
        .footer { text-align: center; padding: 30px 20px; color: #6B7280; font-size: 14px; background-color: #F9FAFB; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🔔 New Login Detected</h1>
        </div>
        <div class="content">
          <h2>Hello ${name}</h2>
          <p>We detected a new login to your Artist Finance Manager account.</p>

          <div class="info-box">
            <strong>Login Details:</strong>
            <p><strong>Device:</strong> ${deviceInfo || 'Unknown'}</p>
            <p><strong>IP Address:</strong> ${ipAddress || 'Unknown'}</p>
            <p><strong>Time:</strong> ${timestamp}</p>
          </div>

          <p>If this was you, you can safely ignore this email.</p>

          <p style="margin-top: 30px; padding: 15px; background-color: #FEF2F2; border-left: 4px solid #DC2626; border-radius: 4px;">
            <strong style="color: #991B1B;">If this wasn't you:</strong><br>
            <span style="color: #7F1D1D;">Please secure your account immediately by changing your credentials and reviewing recent activity.</span>
          </p>
        </div>
        <div class="footer">
          <p><strong>Artist Finance Manager</strong></p>
          <p>This is a security notification sent to ${to}</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const textBody = `
Hello ${name}

We detected a new login to your Artist Finance Manager account.

Login Details:
- Device: ${deviceInfo || 'Unknown'}
- IP Address: ${ipAddress || 'Unknown'}
- Time: ${timestamp}

If this was you, you can safely ignore this email.

IF THIS WASN'T YOU: Please secure your account immediately by changing your credentials and reviewing recent activity.

Best regards,
The Artist Finance Manager Team

This is a security notification sent to ${to}
  `.trim();

  return sendEmail(to, subject, htmlBody, textBody);
}

// Export for testing
export default {
  sendEmail,
  sendWelcomeEmail,
  sendAccountDeletionEmail,
  sendLoginNotificationEmail,
};
JSEOF

success "Email service module created: functions/email_service.js"
echo ""

section "Step 5: Updating package.json"
echo ""

# Update package.json to include SendGrid
if [ -f "functions/package.json" ]; then
    # Check if @sendgrid/mail is already in package.json
    if ! grep -q "@sendgrid/mail" functions/package.json; then
        # Add SendGrid dependency
        info "Adding @sendgrid/mail to dependencies..."

        # Create a backup
        cp functions/package.json functions/package.json.bak

        # Use Node.js to update package.json properly
        node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('functions/package.json', 'utf8'));
        pkg.dependencies = pkg.dependencies || {};
        pkg.dependencies['@sendgrid/mail'] = '^8.1.0';
        fs.writeFileSync('functions/package.json', JSON.stringify(pkg, null, 2));
        "

        success "package.json updated"
    else
        info "@sendgrid/mail already in package.json"
    fi
else
    warning "functions/package.json not found, creating it..."
    cat > functions/package.json <<'EOF'
{
  "name": "artist-finance-manager-functions",
  "description": "Cloud Functions for Artist Finance Manager",
  "version": "1.0.0",
  "type": "module",
  "main": "index.js",
  "scripts": {
    "deploy": "gcloud functions deploy"
  },
  "engines": {
    "node": "20"
  },
  "dependencies": {
    "@google-cloud/firestore": "^7.1.0",
    "@google-cloud/functions-framework": "^3.3.0",
    "@sendgrid/mail": "^8.1.0"
  }
}
EOF
    success "package.json created"
fi

echo ""
section "Step 6: Installing Dependencies"
echo ""

cd functions
npm install
cd ..

success "Dependencies installed"
echo ""

success "SendGrid setup complete!"
echo ""
info "══════════════════════════════════════════════════════════"
info "Configuration Summary:"
info "══════════════════════════════════════════════════════════"
info "✅ SendGrid API key saved"
info "✅ Sender email configured: $SENDER_EMAIL"
info "✅ Email service module created"
info "✅ Dependencies installed"
echo ""
info "Next Steps:"
info "1. Complete sender verification in SendGrid:"
info "   https://app.sendgrid.com/settings/sender_auth/senders"
echo ""
info "2. Deploy Cloud Functions:"
info "   ./scripts/deploy_functions_sendgrid.sh"
echo ""
info "3. Test email sending"
info "══════════════════════════════════════════════════════════"

exit 0
