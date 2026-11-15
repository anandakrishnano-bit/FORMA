"use strict";
/**
 * FORMA Custom Branded HTML Email Templates
 *
 * Design System:
 * - Brand: FORMA
 * - Background: Warm cream #F5F1E9
 * - Primary Text: Charcoal #171719
 * - Primary Accent / Highlight: Golden Yellow #FFC443
 * - Secondary Accent: Icy Blue #C5D0DE
 * - Alert Accent: Coral Pink #F27689
 * - Muted Text: Concrete Grey #7A7A78
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.getEmailVerificationHtml = getEmailVerificationHtml;
exports.getPasswordResetHtml = getPasswordResetHtml;
exports.getEmailChangeHtml = getEmailChangeHtml;
const formaHeader = `
  <tr>
    <td align="center" style="padding: 40px 0 24px 0;">
      <table border="0" cellpadding="0" cellspacing="0">
        <tr>
          <td align="center" style="background-color: #171719; width: 48px; height: 48px; border-radius: 14px;">
            <span style="font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 26px; font-weight: 900; color: #FFC443; line-height: 48px;">F</span>
          </td>
          <td style="padding-left: 14px;">
            <span style="font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 22px; font-weight: 900; letter-spacing: 4px; color: #171719; text-transform: uppercase;">FORMA</span>
          </td>
        </tr>
      </table>
    </td>
  </tr>
`;
const formaFooter = `
  <tr>
    <td align="center" style="padding: 32px 20px 40px 20px; border-top: 1px solid #E5E1D8;">
      <p style="margin: 0 0 8px 0; font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 600; color: #7A7A78; letter-spacing: 0.5px;">
        FORMA • Train. Track. Improve. Together.
      </p>
      <p style="margin: 0; font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; font-size: 11px; color: #A09E9B; line-height: 1.5;">
        This automated account security message was sent to your registered address.<br/>
        Personal workout diaries, financial ledgers and health vitals remain strictly private.
      </p>
    </td>
  </tr>
`;
function wrapTemplate(title, bodyContent) {
    return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    body { margin: 0; padding: 0; background-color: #F5F1E9; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table { border-collapse: collapse; }
    a { text-decoration: none; }
    @media only screen and (max-width: 600px) {
      .container { width: 92% !important; }
      .card { padding: 26px 20px !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: #F5F1E9;">
  <table width="100%" border="0" cellpadding="0" cellspacing="0" style="background-color: #F5F1E9;">
    <tr>
      <td align="center">
        <table class="container" width="560" border="0" cellpadding="0" cellspacing="0" style="width: 560px; max-width: 560px; margin: 0 auto;">
          ${formaHeader}
          <tr>
            <td style="padding: 0 10px 20px 10px;">
              <table width="100%" border="0" cellpadding="0" cellspacing="0" class="card" style="background-color: #FFFFFF; border-radius: 24px; padding: 36px 32px; box-shadow: 0 4px 20px rgba(23, 23, 25, 0.04); border: 1px solid #EBE7DE;">
                ${bodyContent}
              </table>
            </td>
          </tr>
          ${formaFooter}
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `.trim();
}
/**
 * 1. Email Verification Template
 */
function getEmailVerificationHtml(data) {
    const name = data.displayName || "Athlete";
    const hours = data.expirationHours || 24;
    const content = `
    <tr>
      <td>
        <span style="display: inline-block; padding: 5px 12px; background-color: rgba(255, 196, 67, 0.2); border-radius: 8px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 11px; font-weight: 800; letter-spacing: 1.2px; color: #171719; text-transform: uppercase;">
          ACCOUNT VERIFICATION
        </span>
        <h1 style="margin: 18px 0 10px 0; font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 24px; font-weight: 900; letter-spacing: -0.5px; color: #171719;">
          Verify your email address
        </h1>
        <p style="margin: 0 0 20px 0; font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 15px; line-height: 1.6; color: #4A4A48;">
          Hi ${name},<br/>
          Welcome to FORMA. To secure your profile, preserve your workout history, and connect with genuine training partners, please confirm your email address below.
        </p>

        <!-- CTA Button -->
        <table border="0" cellpadding="0" cellspacing="0" style="margin: 28px 0;">
          <tr>
            <td align="center" style="border-radius: 14px; background-color: #FFC443;">
              <a href="${data.actionUrl}" target="_blank" style="display: inline-block; padding: 14px 32px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 15px; font-weight: 800; color: #171719; text-decoration: none; border-radius: 14px; letter-spacing: 0.3px;">
                Verify Email Address
              </a>
            </td>
          </tr>
        </table>

        <p style="margin: 0 0 16px 0; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13px; line-height: 1.5; color: #7A7A78;">
          This secure link is valid for <strong>${hours} hours</strong>. If the button above does not work, copy and paste this link into your browser:
        </p>
        <p style="margin: 0 0 24px 0; word-break: break-all; font-family: 'JetBrains Mono', Consolas, monospace; font-size: 12px; line-height: 1.5; color: #171719; background-color: #F5F1E9; padding: 12px; border-radius: 10px;">
          ${data.actionUrl}
        </p>

        <p style="margin: 0; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 12px; line-height: 1.5; color: #A09E9B; border-top: 1px solid #F0ECE4; padding-top: 16px;">
          If you did not register for an account on FORMA, you can safely disregard this email.
        </p>
      </td>
    </tr>
  `;
    return wrapTemplate("Verify your email address | FORMA", content);
}
/**
 * 2. Password Reset Template
 */
function getPasswordResetHtml(data) {
    const name = data.displayName || "Athlete";
    const hours = data.expirationHours || 1;
    const content = `
    <tr>
      <td>
        <span style="display: inline-block; padding: 5px 12px; background-color: rgba(242, 118, 137, 0.18); border-radius: 8px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 11px; font-weight: 800; letter-spacing: 1.2px; color: #C23B50; text-transform: uppercase;">
          PASSWORD RECOVERY
        </span>
        <h1 style="margin: 18px 0 10px 0; font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 24px; font-weight: 900; letter-spacing: -0.5px; color: #171719;">
          Reset your FORMA password
        </h1>
        <p style="margin: 0 0 20px 0; font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 15px; line-height: 1.6; color: #4A4A48;">
          Hi ${name},<br/>
          We received a request to reset the password for your FORMA account. Click the button below to choose a new password.
        </p>

        <!-- CTA Button -->
        <table border="0" cellpadding="0" cellspacing="0" style="margin: 28px 0;">
          <tr>
            <td align="center" style="border-radius: 14px; background-color: #171719;">
              <a href="${data.actionUrl}" target="_blank" style="display: inline-block; padding: 14px 32px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 15px; font-weight: 800; color: #FFFFFF; text-decoration: none; border-radius: 14px; letter-spacing: 0.3px;">
                Reset Password
              </a>
            </td>
          </tr>
        </table>

        <!-- Security Notice Callout -->
        <table width="100%" border="0" cellpadding="0" cellspacing="0" style="background-color: #F8F6F1; border-left: 3px solid #FFC443; border-radius: 8px; padding: 12px 14px; margin-bottom: 20px;">
          <tr>
            <td>
              <p style="margin: 0; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 12px; line-height: 1.5; color: #4A4A48;">
                <strong>Security Notice:</strong> Your password will not change until you access the link above and create a new one. This link will expire in <strong>${hours} hour(s)</strong>.
              </p>
            </td>
          </tr>
        </table>

        <p style="margin: 0 0 16px 0; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13px; line-height: 1.5; color: #7A7A78;">
          If the button above does not open, copy and paste this link:
        </p>
        <p style="margin: 0 0 24px 0; word-break: break-all; font-family: 'JetBrains Mono', Consolas, monospace; font-size: 12px; line-height: 1.5; color: #171719; background-color: #F5F1E9; padding: 12px; border-radius: 10px;">
          ${data.actionUrl}
        </p>

        <p style="margin: 0; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 12px; line-height: 1.5; color: #A09E9B; border-top: 1px solid #F0ECE4; padding-top: 16px;">
          If you did not request a password reset, please ignore this message. Your account remains secure.
        </p>
      </td>
    </tr>
  `;
    return wrapTemplate("Reset your FORMA password", content);
}
/**
 * 3. Email Change Confirmation Template
 */
function getEmailChangeHtml(data) {
    const name = data.displayName || "Athlete";
    const newEmail = data.newEmail || "your new email address";
    const content = `
    <tr>
      <td>
        <span style="display: inline-block; padding: 5px 12px; background-color: rgba(197, 208, 222, 0.4); border-radius: 8px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 11px; font-weight: 800; letter-spacing: 1.2px; color: #171719; text-transform: uppercase;">
          SECURITY UPDATE
        </span>
        <h1 style="margin: 18px 0 10px 0; font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 24px; font-weight: 900; letter-spacing: -0.5px; color: #171719;">
          Confirm your new email address
        </h1>
        <p style="margin: 0 0 20px 0; font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 15px; line-height: 1.6; color: #4A4A48;">
          Hi ${name},<br/>
          We received a request to update the primary email address for your FORMA account to <strong>${newEmail}</strong>.
        </p>

        <!-- CTA Button -->
        <table border="0" cellpadding="0" cellspacing="0" style="margin: 28px 0;">
          <tr>
            <td align="center" style="border-radius: 14px; background-color: #FFC443;">
              <a href="${data.actionUrl}" target="_blank" style="display: inline-block; padding: 14px 32px; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 15px; font-weight: 800; color: #171719; text-decoration: none; border-radius: 14px; letter-spacing: 0.3px;">
                Confirm Email Change
              </a>
            </td>
          </tr>
        </table>

        <p style="margin: 0 0 16px 0; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 13px; line-height: 1.5; color: #7A7A78;">
          Fallback plain-text link:
        </p>
        <p style="margin: 0 0 24px 0; word-break: break-all; font-family: 'JetBrains Mono', Consolas, monospace; font-size: 12px; line-height: 1.5; color: #171719; background-color: #F5F1E9; padding: 12px; border-radius: 10px;">
          ${data.actionUrl}
        </p>

        <p style="margin: 0; font-family: 'Plus Jakarta Sans', sans-serif; font-size: 12px; line-height: 1.5; color: #A09E9B; border-top: 1px solid #F0ECE4; padding-top: 16px;">
          If you did not initiate this change, contact FORMA security immediately.
        </p>
      </td>
    </tr>
  `;
    return wrapTemplate("Confirm your new email address | FORMA", content);
}
//# sourceMappingURL=emailTemplates.js.map