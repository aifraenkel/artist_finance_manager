/**
 * SendGrid Email Service
 */
import sgMail from '@sendgrid/mail';

const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
const SENDER_EMAIL = process.env.SENDER_EMAIL || 'noreply@artist-finance-manager.local';
const SENDER_NAME = process.env.SENDER_NAME || 'Artist Finance Manager';

if (!SENDGRID_API_KEY) {
  console.warn('SENDGRID_API_KEY is not set. Emails will fail.');
}
sgMail.setApiKey(SENDGRID_API_KEY || '');

/**
 * Send an email via SendGrid
 * @param {string} to
 * @param {string} subject
 * @param {string} htmlBody
 * @param {string} textBody
 * @returns {Promise<{success: boolean, messageId?: string}>}
 */
export async function sendEmail(to, subject, htmlBody, textBody) {
  const msg = {
    to,
    from: { email: SENDER_EMAIL, name: SENDER_NAME },
    subject,
    text: textBody,
    html: htmlBody,
  };
  try {
    const [resp] = await sgMail.send(msg);
    const messageId = resp?.headers?.['x-message-id'] || resp?.headers?.['x-sendgrid-message-id'];
    console.log('Email sent via SendGrid:', messageId || resp?.statusCode);
    return { success: true, messageId };
  } catch (error) {
    console.error('SendGrid error:', error?.response?.body || error.message || error);
    throw error;
  }
}
