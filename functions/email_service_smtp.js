/**
 * SMTP Email Service using Nodemailer
 * Works with Mailpit SMTP server deployed on Cloud Run
 */

import pkg from 'nodemailer';
const { createTransport, getTestMessageUrl } = pkg;

const SMTP_HOST = process.env.SMTP_HOST || 'mailpit-smtp-456648586026.us-central1.run.app';
const SMTP_PORT = parseInt(process.env.SMTP_PORT) || 1025;
const SMTP_USER = process.env.SMTP_USER || '';
const SMTP_PASS = process.env.SMTP_PASS || '';
const SMTP_SECURE = process.env.SMTP_SECURE === 'true';
const SENDER_EMAIL = process.env.SENDER_EMAIL || 'noreply@artist-finance-manager.local';
const SENDER_NAME = process.env.SENDER_NAME || 'Artist Finance Manager';

// Create nodemailer transporter
const transporter = createTransport({
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

/**
 * Send an email via SMTP
 * @param {string} to - Recipient email address
 * @param {string} subject - Email subject
 * @param {string} htmlBody - HTML body content
 * @param {string} textBody - Plain text body content
 * @returns {Promise<{success: boolean, messageId: string}>}
 */
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
    console.log('Preview URL:', getTestMessageUrl(info));
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('SMTP error:', error);
    throw error;
  }
}
