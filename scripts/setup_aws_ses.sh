#!/bin/bash

# AWS SES Setup Script for Cloud Functions
# This script helps configure AWS SES for sending authentication emails

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

info "======================================"
info "AWS SES Email Service Setup"
info "======================================"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    warning "AWS CLI not found"
    info "Install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    info "Or use homebrew: brew install awscli"
    exit 1
fi

info "AWS CLI found"
echo ""

# Check AWS credentials
info "Checking AWS credentials..."
if aws sts get-caller-identity &>/dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region || echo "us-east-1")
    success "AWS credentials configured"
    info "Account: $AWS_ACCOUNT"
    info "Region: $AWS_REGION"
else
    error "AWS credentials not configured"
    info "Run: aws configure"
    info "You'll need:"
    info "  - AWS Access Key ID"
    info "  - AWS Secret Access Key"
    info "  - Default region (e.g., us-east-1)"
    exit 1
fi
echo ""

# Prompt for sender email
info "AWS SES requires a verified sender email address"
read -p "Enter the email address to send from (e.g., noreply@yourdomain.com): " SENDER_EMAIL

if [ -z "$SENDER_EMAIL" ]; then
    error "Sender email is required"
    exit 1
fi

info "Using sender email: $SENDER_EMAIL"
echo ""

# Verify email in SES
info "Verifying email address in AWS SES..."
aws ses verify-email-identity --email-address "$SENDER_EMAIL" --region "$AWS_REGION" 2>/dev/null || \
    warning "Email verification request already sent or failed"

info "Verification email sent to: $SENDER_EMAIL"
warning "⚠️  CHECK YOUR EMAIL and click the verification link!"
echo ""

read -p "Press Enter after you've verified the email in AWS SES..."

# Check verification status
info "Checking verification status..."
VERIFICATION_STATUS=$(aws ses get-identity-verification-attributes \
    --identities "$SENDER_EMAIL" \
    --region "$AWS_REGION" \
    --query "VerificationAttributes.\"$SENDER_EMAIL\".VerificationStatus" \
    --output text)

if [ "$VERIFICATION_STATUS" = "Success" ]; then
    success "Email verified in AWS SES!"
else
    warning "Email verification status: $VERIFICATION_STATUS"
    warning "You may need to complete verification before sending emails"
fi
echo ""

# Create IAM user for Cloud Functions
info "Creating IAM user for Cloud Functions..."
IAM_USER="firebase-functions-ses"

# Check if user exists
if aws iam get-user --user-name "$IAM_USER" &>/dev/null; then
    warning "IAM user '$IAM_USER' already exists"
else
    aws iam create-user --user-name "$IAM_USER" --tags Key=Purpose,Value=FirebaseFunctions
    success "IAM user created"
fi

# Attach SES sending policy
info "Attaching SES sending policy..."
cat > /tmp/ses-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": "*"
        }
    ]
}
EOF

POLICY_ARN="arn:aws:iam::$AWS_ACCOUNT:policy/FirebaseFunctionsSESPolicy"

# Create policy if it doesn't exist
if aws iam get-policy --policy-arn "$POLICY_ARN" &>/dev/null; then
    info "Policy already exists"
else
    aws iam create-policy \
        --policy-name FirebaseFunctionsSESPolicy \
        --policy-document file:///tmp/ses-policy.json
    success "Policy created"
fi

# Attach policy to user
aws iam attach-user-policy \
    --user-name "$IAM_USER" \
    --policy-arn "$POLICY_ARN" 2>/dev/null || \
    info "Policy already attached"

success "Policy attached"
echo ""

# Create access keys
info "Creating access keys..."
ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name "$IAM_USER" 2>&1)

if echo "$ACCESS_KEY_OUTPUT" | grep -q "AccessKeyId"; then
    AWS_ACCESS_KEY_ID=$(echo "$ACCESS_KEY_OUTPUT" | grep -o '"AccessKeyId": "[^"]*"' | cut -d'"' -f4)
    AWS_SECRET_ACCESS_KEY=$(echo "$ACCESS_KEY_OUTPUT" | grep -o '"SecretAccessKey": "[^"]*"' | cut -d'"' -f4)

    success "Access keys created"
    echo ""

    # Save credentials to .env file for local development
    info "Saving credentials to functions/.env..."
    mkdir -p functions
    cat > functions/.env <<EOF
# AWS SES Configuration
AWS_REGION=$AWS_REGION
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
SES_SENDER_EMAIL=$SENDER_EMAIL
EOF

    success "Credentials saved to functions/.env"
    warning "⚠️  Keep this file secure! It's already in .gitignore"
    echo ""

    # Set as environment variables for Cloud Functions
    info "Setting Cloud Functions environment variables..."

    # Note: These will be set during function deployment
    info "Environment variables will be set during function deployment"
    echo ""

else
    warning "Could not create new access keys (may already exist)"
    info "Existing access keys:"
    aws iam list-access-keys --user-name "$IAM_USER"
    echo ""
    warning "If you need new keys, delete old ones first:"
    info "aws iam delete-access-key --user-name $IAM_USER --access-key-id <KEY_ID>"
fi

# Update Cloud Functions code
info "Updating Cloud Functions to use AWS SES..."
cat > functions/email_service.js <<'EOF'
/**
 * AWS SES Email Service
 * Handles sending emails via AWS Simple Email Service
 */

import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';

// Initialize SES client
const ses = new SESClient({
  region: process.env.AWS_REGION || 'us-east-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

const SENDER_EMAIL = process.env.SES_SENDER_EMAIL || 'noreply@example.com';

/**
 * Send email via AWS SES
 * @param {string} to - Recipient email address
 * @param {string} subject - Email subject
 * @param {string} htmlBody - HTML email body
 * @param {string} textBody - Plain text email body
 */
export async function sendEmail(to, subject, htmlBody, textBody) {
  const params = {
    Source: SENDER_EMAIL,
    Destination: {
      ToAddresses: [to],
    },
    Message: {
      Subject: {
        Data: subject,
        Charset: 'UTF-8',
      },
      Body: {
        Html: {
          Data: htmlBody,
          Charset: 'UTF-8',
        },
        Text: {
          Data: textBody,
          Charset: 'UTF-8',
        },
      },
    },
  };

  try {
    const command = new SendEmailCommand(params);
    const response = await ses.send(command);
    console.log('Email sent successfully:', response.MessageId);
    return { success: true, messageId: response.MessageId };
  } catch (error) {
    console.error('Error sending email:', error);
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
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #2563EB; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9fafb; }
        .button { display: inline-block; padding: 12px 24px; background-color: #2563EB; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #6b7280; font-size: 14px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Welcome to Artist Finance Manager</h1>
        </div>
        <div class="content">
          <h2>Hello ${name}!</h2>
          <p>Thank you for joining Artist Finance Manager. We're excited to help you manage your project finances.</p>
          <p>With Artist Finance Manager, you can:</p>
          <ul>
            <li>Track income and expenses for your projects</li>
            <li>View real-time financial summaries</li>
            <li>Manage transactions easily</li>
            <li>Keep your financial data secure</li>
          </ul>
          <p>Get started by adding your first transaction!</p>
          <a href="https://artist-finance-manager-456648586026.us-central1.run.app" class="button">Go to Dashboard</a>
        </div>
        <div class="footer">
          <p>Artist Finance Manager</p>
          <p>This email was sent to ${to}</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const textBody = `
Hello ${name}!

Thank you for joining Artist Finance Manager. We're excited to help you manage your project finances.

Get started by visiting your dashboard and adding your first transaction.

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
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #DC2626; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9fafb; }
        .warning { background-color: #FEF3C7; border-left: 4px solid #F59E0B; padding: 12px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #6b7280; font-size: 14px; }
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
            <strong>Recovery Period:</strong> Your data will be kept for 90 days. You can recover your account by signing in again within this period.
          </div>
          <p>After 90 days, your account and all associated data will be permanently deleted.</p>
          <p>If you didn't request this deletion, please contact support immediately.</p>
        </div>
        <div class="footer">
          <p>Artist Finance Manager</p>
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

If you didn't request this deletion, please contact support immediately.

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

  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #F59E0B; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9fafb; }
        .info-box { background-color: #EFF6FF; border: 1px solid #BFDBFE; padding: 12px; margin: 20px 0; border-radius: 6px; }
        .footer { text-align: center; padding: 20px; color: #6b7280; font-size: 14px; }
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
            <strong>Login Details:</strong><br>
            Device: ${deviceInfo || 'Unknown'}<br>
            IP Address: ${ipAddress || 'Unknown'}<br>
            Time: ${new Date().toISOString()}
          </div>
          <p>If this was you, you can safely ignore this email.</p>
          <p><strong>If this wasn't you:</strong> Please secure your account immediately by changing your email address and reviewing recent activity.</p>
        </div>
        <div class="footer">
          <p>Artist Finance Manager</p>
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
- Time: ${new Date().toISOString()}

If this was you, you can safely ignore this email.

If this wasn't you, please secure your account immediately.

Best regards,
The Artist Finance Manager Team
  `.trim();

  return sendEmail(to, subject, htmlBody, textBody);
}
EOF

success "Email service module created"
echo ""

# Update package.json to include AWS SES SDK
info "Updating package.json..."
if [ -f "functions/package.json" ]; then
    # Add AWS SDK dependency if not already present
    if ! grep -q "@aws-sdk/client-ses" functions/package.json; then
        # Use jq if available, otherwise manual edit
        if command -v jq &> /dev/null; then
            tmp=$(mktemp)
            jq '.dependencies["@aws-sdk/client-ses"] = "^3.0.0"' functions/package.json > "$tmp"
            mv "$tmp" functions/package.json
        else
            warning "jq not found, please manually add '@aws-sdk/client-ses': '^3.0.0' to dependencies"
        fi
    fi
    success "package.json updated"
else
    warning "functions/package.json not found"
fi
echo ""

# Update index.js to use email service
info "Updating Cloud Functions to use email service..."
info "You'll need to manually integrate email_service.js into functions/index.js"
info "Import and use the functions: sendWelcomeEmail, sendAccountDeletionEmail, sendLoginNotificationEmail"
echo ""

success "AWS SES setup complete!"
echo ""
info "======================================"
info "Next Steps:"
info "======================================"
info "1. Update functions/index.js to import and use email_service.js"
info "2. Install dependencies:"
info "   cd functions && npm install"
info "3. Deploy functions with environment variables:"
info "   gcloud functions deploy <function-name> \\"
info "     --set-env-vars AWS_REGION=$AWS_REGION,\\"
info "     AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID,\\"
info "     AWS_SECRET_ACCESS_KEY=<your-secret>,\\"
info "     SES_SENDER_EMAIL=$SENDER_EMAIL"
info ""
info "Or use the deployment script:"
info "   ./scripts/deploy_functions_with_ses.sh"
info "======================================"

exit 0
