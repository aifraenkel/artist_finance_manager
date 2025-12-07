/**
 * Email Templates
 *
 * HTML and text templates for various email types
 */

/**
 * Generate registration verification email
 *
 * @param {string} name - User's display name
 * @param {string} verificationUrl - URL to verify registration (with token)
 * @returns {{html: string, text: string}}
 */
export function generateRegistrationEmail(name, verificationUrl) {
  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="x-apple-disable-message-reformatting">
  <title>Complete Your Registration - Art Finance Hub</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Outfit', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #FCFBF9;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background-color: #FCFBF9; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" role="presentation" style="background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 8px rgba(29,47,46,0.08); min-width: 600px;">
          <!-- Header -->
          <tr>
            <td style="background: linear-gradient(135deg, #2E9A85 0%, #3FC0A8 100%); padding: 40px 20px; text-align: center;">
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: bold; font-family: 'Outfit', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
                Welcome to Art Finance Hub
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding: 40px 30px;">
              <p style="font-size: 16px; color: #333333; margin: 0 0 20px 0;">
                Hi ${name},
              </p>

              <p style="font-size: 16px; color: #333333; margin: 0 0 20px 0;">
                Thanks for creating an account with Art Finance Hub! We're excited to help you manage your finances.
              </p>

              <p style="font-size: 16px; color: #333333; margin: 0 0 30px 0;">
                Click the button below to complete your registration and access your account:
              </p>

              <table width="100%" cellpadding="0" cellspacing="0" role="presentation">
                <tr>
                  <td align="center" style="padding: 0 0 30px 0;">
                    <!--[if mso]>
                    <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="${verificationUrl}" style="height:48px;v-text-anchor:middle;width:280px;" arcsize="50%" strokecolor="#F5A54A" fillcolor="#F5A54A">
                    <w:anchorlock/>
                    <center style="color:#1D2F2E;font-family:'Outfit','Segoe UI',sans-serif;font-size:16px;font-weight:bold;">Complete Registration</center>
                    </v:roundrect>
                    <![endif]-->
                    <!--[if !mso]><!-->
                    <a href="${verificationUrl}" target="_blank" rel="noopener noreferrer" style="display: inline-block; padding: 16px 40px; background-color: #F5A54A; color: #1D2F2E; text-decoration: none; border-radius: 24px; font-size: 16px; font-weight: bold; font-family: 'Outfit', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; mso-hide: all;">
                      Complete Registration
                    </a>
                    <!--<![endif]-->
                  </td>
                </tr>
              </table>

              <p style="font-size: 14px; color: #666666; margin: 0 0 20px 0;">
                Or copy and paste this link into your browser:
              </p>

              <p style="font-size: 14px; margin: 0 0 30px 0; word-break: break-all;">
                <a href="${verificationUrl}" target="_blank" rel="noopener noreferrer" style="color: #2E9A85; text-decoration: underline; font-family: 'Courier New', Courier, monospace;">${verificationUrl}</a>
              </p>

              <div style="background-color: #E8F7F4; border-left: 4px solid #2E9A85; padding: 16px; margin: 0 0 20px 0; border-radius: 4px;">
                <p style="font-size: 14px; color: #1D2F2E; margin: 0; font-family: 'Outfit', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
                  <strong>Important:</strong> This link will expire in 24 hours for security reasons. You can complete your registration on any device (phone, tablet, or computer).
                </p>
              </div>

              <p style="font-size: 14px; color: #666666; margin: 0;">
                If you didn't create this account, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #e9ecef;">
              <p style="font-size: 14px; color: #666666; margin: 0 0 10px 0;">
                Art Finance Hub
              </p>
              <p style="font-size: 12px; color: #999999; margin: 0;">
                This is an automated message, please do not reply to this email.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

  const text = `
Welcome to Art Finance Hub!

Hi ${name},

Thanks for creating an account with Art Finance Hub! We're excited to help you manage your finances.

Complete your registration by visiting this link:
${verificationUrl}

Important: This link will expire in 24 hours for security reasons. You can complete your registration on any device (phone, tablet, or computer).

If you didn't create this account, you can safely ignore this email.

---
Art Finance Hub
This is an automated message, please do not reply to this email.
`;

  return { html, text };
}

/**
 * Generate sign-in email (for existing users)
 *
 * @param {string} name - User's display name
 * @param {string} signInUrl - URL to sign in (with token)
 * @returns {{html: string, text: string}}
 */
export function generateSignInEmail(name, signInUrl) {
  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="x-apple-disable-message-reformatting">
  <title>Sign In to Art Finance Hub</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Outfit', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #FCFBF9;">
  <table width="100%" cellpadding="0" cellspacing="0" role="presentation" style="background-color: #FCFBF9; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" role="presentation" style="background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 2px 8px rgba(29,47,46,0.08); min-width: 600px;">
          <!-- Header -->
          <tr>
            <td style="background: linear-gradient(135deg, #2E9A85 0%, #3FC0A8 100%); padding: 40px 20px; text-align: center;">
              <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: bold; font-family: 'Outfit', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
                Sign In to Art Finance Hub
              </h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding: 40px 30px;">
              <p style="font-size: 16px; color: #333333; margin: 0 0 20px 0;">
                Hi ${name},
              </p>

              <p style="font-size: 16px; color: #333333; margin: 0 0 30px 0;">
                Click the button below to sign in to your Art Finance Hub account:
              </p>

              <table width="100%" cellpadding="0" cellspacing="0" role="presentation">
                <tr>
                  <td align="center" style="padding: 0 0 30px 0;">
                    <!--[if mso]>
                    <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="${signInUrl}" style="height:48px;v-text-anchor:middle;width:200px;" arcsize="50%" strokecolor="#F5A54A" fillcolor="#F5A54A">
                    <w:anchorlock/>
                    <center style="color:#1D2F2E;font-family:'Outfit','Segoe UI',sans-serif;font-size:16px;font-weight:bold;">Sign In</center>
                    </v:roundrect>
                    <![endif]-->
                    <!--[if !mso]><!-->
                    <a href="${signInUrl}" target="_blank" rel="noopener noreferrer" style="display: inline-block; padding: 16px 40px; background-color: #F5A54A; color: #1D2F2E; text-decoration: none; border-radius: 24px; font-size: 16px; font-weight: bold; font-family: 'Outfit', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; mso-hide: all;">
                      Sign In
                    </a>
                    <!--<![endif]-->
                  </td>
                </tr>
              </table>

              <p style="font-size: 14px; color: #666666; margin: 0 0 20px 0;">
                Or copy and paste this link into your browser:
              </p>

              <p style="font-size: 14px; margin: 0 0 30px 0; word-break: break-all;">
                <a href="${signInUrl}" target="_blank" rel="noopener noreferrer" style="color: #2E9A85; text-decoration: underline; font-family: 'Courier New', Courier, monospace;">${signInUrl}</a>
              </p>

              <div style="background-color: #E8F7F4; border-left: 4px solid #2E9A85; padding: 16px; margin: 0 0 20px 0; border-radius: 4px;">
                <p style="font-size: 14px; color: #1D2F2E; margin: 0; font-family: 'Outfit', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
                  <strong>Important:</strong> This link will expire in 24 hours for security reasons. You can sign in from any device (phone, tablet, or computer).
                </p>
              </div>

              <p style="font-size: 14px; color: #666666; margin: 0;">
                If you didn't request this sign-in link, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #f8f9fa; padding: 30px; text-align: center; border-top: 1px solid #e9ecef;">
              <p style="font-size: 14px; color: #666666; margin: 0 0 10px 0;">
                Art Finance Hub
              </p>
              <p style="font-size: 12px; color: #999999; margin: 0;">
                This is an automated message, please do not reply to this email.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

  const text = `
Sign In to Your Account

Hi ${name},

Click the link below to sign in to your Art Finance Hub account:
${signInUrl}

Important: This link will expire in 24 hours for security reasons. You can sign in from any device (phone, tablet, or computer).

If you didn't request this sign-in link, you can safely ignore this email.

---
Art Finance Hub
This is an automated message, please do not reply to this email.
`;

  return { html, text };
}
