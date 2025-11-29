/**
 * Email Template Service
 * Provides HTML email templates for various notifications
 * Import sendEmail from email_service_smtp.js or email_service_sendgrid.js
 */

import { sendEmail } from './email_service_smtp.js';

/**
 * Send welcome email to new user
 * @param {string} to - Recipient email
 * @param {string} name - User's name
 */
export async function sendWelcomeEmail(to, name) {
  const subject = 'Welcome to Artist Finance Manager!';

  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; font-size: 12px; color: #999; }
        ul { padding-left: 20px; }
        li { margin: 10px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Welcome to Artist Finance Manager!</h1>
        </div>
        <div class="content">
          <p>Hi ${name},</p>

          <p>Thank you for joining Artist Finance Manager! We're excited to help you manage your artist finances with ease.</p>

          <h3>What you can do:</h3>
          <ul>
            <li>Track your income and expenses</li>
            <li>Manage your artist profile</li>
            <li>View financial reports and analytics</li>
            <li>Access your data anytime, anywhere</li>
          </ul>

          <p>Your account is now active and ready to use. Start by exploring the dashboard!</p>

          <p>If you have any questions or need assistance, feel free to reach out to our support team.</p>

          <p>Best regards,<br>The Artist Finance Manager Team</p>
        </div>
        <div class="footer">
          <p>© ${new Date().getFullYear()} Artist Finance Manager. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const textBody = `
    Hi ${name},

    Thank you for joining Artist Finance Manager! We're excited to help you manage your artist finances with ease.

    What you can do:
    - Track your income and expenses
    - Manage your artist profile
    - View financial reports and analytics
    - Access your data anytime, anywhere

    Your account is now active and ready to use. Start by exploring the dashboard!

    If you have any questions or need assistance, feel free to reach out to our support team.

    Best regards,
    The Artist Finance Manager Team

    © ${new Date().getFullYear()} Artist Finance Manager. All rights reserved.
  `;

  return await sendEmail(to, subject, htmlBody, textBody);
}

/**
 * Send account deletion confirmation email
 * @param {string} to - Recipient email
 * @param {string} name - User's name
 */
export async function sendAccountDeletionEmail(to, name) {
  const subject = 'Account Deletion Confirmation - Artist Finance Manager';

  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #dc3545; color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; font-size: 12px; color: #999; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Account Deletion Confirmation</h1>
        </div>
        <div class="content">
          <p>Hi ${name},</p>

          <p>This email confirms that your Artist Finance Manager account has been scheduled for deletion.</p>

          <div class="warning">
            <strong>⚠️ Important:</strong> Your account and all associated data will be permanently deleted after 90 days.
            After this period, all your information will be completely removed from our systems and cannot be recovered.
          </div>

          <p><strong>What happens now:</strong></p>
          <ul>
            <li>Your account is now marked as deleted and inaccessible</li>
            <li>Your data will be retained for 90 days for compliance purposes</li>
            <li>After 90 days, all data will be permanently deleted</li>
          </ul>

          <p>If this deletion was made in error, please contact our support team immediately.</p>

          <p>Thank you for using Artist Finance Manager. We're sorry to see you go!</p>

          <p>Best regards,<br>The Artist Finance Manager Team</p>
        </div>
        <div class="footer">
          <p>© ${new Date().getFullYear()} Artist Finance Manager. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const textBody = `
    Hi ${name},

    This email confirms that your Artist Finance Manager account has been scheduled for deletion.

    ⚠️ IMPORTANT: Your account and all associated data will be permanently deleted after 90 days.
    After this period, all your information will be completely removed from our systems and cannot be recovered.

    What happens now:
    - Your account is now marked as deleted and inaccessible
    - Your data will be retained for 90 days for compliance purposes
    - After 90 days, all data will be permanently deleted

    If this deletion was made in error, please contact our support team immediately.

    Thank you for using Artist Finance Manager. We're sorry to see you go!

    Best regards,
    The Artist Finance Manager Team

    © ${new Date().getFullYear()} Artist Finance Manager. All rights reserved.
  `;

  return await sendEmail(to, subject, htmlBody, textBody);
}

/**
 * Send login notification email for security alerts
 * @param {string} to - Recipient email
 * @param {string} name - User's name
 * @param {string} deviceInfo - Device information
 * @param {string} ipAddress - IP address of login
 */
export async function sendLoginNotificationEmail(to, name, deviceInfo = 'Unknown device', ipAddress = 'Unknown IP') {
  const subject = 'New Login to Your Artist Finance Manager Account';

  const htmlBody = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #17a2b8; color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        .info-box { background: white; border: 1px solid #ddd; padding: 15px; margin: 20px 0; border-radius: 5px; }
        .security-notice { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 15px; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; font-size: 12px; color: #999; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>🔒 Security Alert</h1>
        </div>
        <div class="content">
          <p>Hi ${name},</p>

          <p>We detected a new login to your Artist Finance Manager account.</p>

          <div class="info-box">
            <p><strong>Login Details:</strong></p>
            <p>📱 Device: ${deviceInfo}</p>
            <p>🌐 IP Address: ${ipAddress}</p>
            <p>🕒 Time: ${new Date().toLocaleString()}</p>
          </div>

          <div class="security-notice">
            <strong>Was this you?</strong><br>
            If you recognize this activity, no action is needed. Your account is secure.
          </div>

          <p><strong>Didn't recognize this login?</strong></p>
          <p>If this wasn't you, please take immediate action:</p>
          <ul>
            <li>Change your password immediately</li>
            <li>Review your account activity</li>
            <li>Contact our support team if you notice any suspicious activity</li>
          </ul>

          <p>We take your security seriously and monitor all account activity to keep your data safe.</p>

          <p>Best regards,<br>The Artist Finance Manager Team</p>
        </div>
        <div class="footer">
          <p>© ${new Date().getFullYear()} Artist Finance Manager. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const textBody = `
    Hi ${name},

    We detected a new login to your Artist Finance Manager account.

    Login Details:
    - Device: ${deviceInfo}
    - IP Address: ${ipAddress}
    - Time: ${new Date().toLocaleString()}

    Was this you?
    If you recognize this activity, no action is needed. Your account is secure.

    Didn't recognize this login?
    If this wasn't you, please take immediate action:
    - Change your password immediately
    - Review your account activity
    - Contact our support team if you notice any suspicious activity

    We take your security seriously and monitor all account activity to keep your data safe.

    Best regards,
    The Artist Finance Manager Team

    © ${new Date().getFullYear()} Artist Finance Manager. All rights reserved.
  `;

  return await sendEmail(to, subject, htmlBody, textBody);
}
