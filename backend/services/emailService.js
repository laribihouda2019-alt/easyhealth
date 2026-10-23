const nodemailer = require('nodemailer');

// Configure the SMTP transporter dynamically
const transporterConfig = process.env.EMAIL_HOST
  ? {
      host: process.env.EMAIL_HOST,
      port: parseInt(process.env.EMAIL_PORT || '587'),
      secure: process.env.EMAIL_SECURE === 'true', // true for 465, false for other ports
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    }
  : {
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    };

const transporter = nodemailer.createTransport(transporterConfig);

/**
 * Sends a premium password reset confirmation email
 * @param {string} toEmail - Recipient email address
 * @param {string} resetLink - Link containing the secure token
 */
async function sendResetPasswordEmail(toEmail, resetLink) {
  const fromEmail = process.env.EMAIL_FROM || 'noreply@easyhealth.com';

  const htmlContent = `
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Réinitialisation de votre mot de passe - EasyHealth</title>
      <style>
        body {
          margin: 0;
          padding: 0;
          background-color: #f1f5f9;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          color: #334155;
          -webkit-font-smoothing: antialiased;
        }
        .container {
          max-width: 600px;
          margin: 40px auto;
          background: #ffffff;
          border-radius: 16px;
          box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -4px rgba(0, 0, 0, 0.05);
          overflow: hidden;
          border: 1px solid #e2e8f0;
        }
        .header {
          background: linear-gradient(135deg, #0284c7 0%, #0369a1 100%);
          padding: 40px 20px;
          text-align: center;
        }
        .header h1 {
          color: #ffffff;
          font-size: 28px;
          margin: 0;
          font-weight: 700;
          letter-spacing: -0.5px;
        }
        .header p {
          color: #e0f2fe;
          margin: 10px 0 0 0;
          font-size: 16px;
        }
        .content {
          padding: 40px 30px;
          line-height: 1.6;
        }
        .content p {
          font-size: 16px;
          margin-bottom: 24px;
        }
        .btn-wrapper {
          text-align: center;
          margin: 36px 0;
        }
        .btn {
          display: inline-block;
          background-color: #0284c7;
          color: #ffffff !important;
          text-decoration: none;
          padding: 14px 30px;
          font-weight: 600;
          font-size: 16px;
          border-radius: 8px;
          box-shadow: 0 4px 6px -1px rgba(2, 132, 199, 0.3), 0 2px 4px -1px rgba(2, 132, 199, 0.1);
          transition: all 0.2s ease-in-out;
        }
        .btn:hover {
          background-color: #0369a1;
          box-shadow: 0 10px 15px -3px rgba(2, 132, 199, 0.4);
        }
        .warning-card {
          background-color: #fffbeb;
          border-left: 4px solid #f59e0b;
          padding: 16px;
          border-radius: 8px;
          margin-top: 24px;
        }
        .warning-card p {
          margin: 0;
          font-size: 14px;
          color: #78350f;
        }
        .footer {
          background-color: #f8fafc;
          padding: 24px;
          text-align: center;
          border-top: 1px solid #f1f5f9;
          font-size: 13px;
          color: #64748b;
        }
        .footer a {
          color: #0284c7;
          text-decoration: none;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>EasyHealth</h1>
          <p>Votre portail de santé intelligent</p>
        </div>
        <div class="content">
          <p>Bonjour,</p>
          <p>Nous avons reçu une demande de réinitialisation du mot de passe associé à votre compte EasyHealth. Pour procéder au changement, veuillez cliquer sur le bouton sécurisé ci-dessous :</p>
          
          <div class="btn-wrapper">
            <a href="${resetLink}" class="btn" target="_blank">Réinitialiser le mot de passe</a>
          </div>

          <p style="font-size: 14px; color: #64748b;">
            Si le bouton ci-dessus ne fonctionne pas, copiez et collez l'adresse URL suivante dans votre navigateur internet :<br>
            <a href="${resetLink}" style="color: #0284c7; word-break: break-all;">${resetLink}</a>
          </p>

          <div class="warning-card">
            <p><strong>Note de sécurité :</strong> Ce lien est valable pendant <strong>1 heure</strong> uniquement. Si vous n'êtes pas à l'origine de cette demande, vous pouvez ignorer cet e-mail en toute sécurité. Votre mot de passe restera inchangé.</p>
          </div>
        </div>
        <div class="footer">
          <p>Cet e-mail a été envoyé automatiquement par EasyHealth. Veuillez ne pas y répondre.</p>
          <p>&copy; 2026 EasyHealth. Tous droits réservés.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const mailOptions = {
    from: `"EasyHealth Assistance" <${fromEmail}>`,
    to: toEmail,
    subject: 'Réinitialisation de votre mot de passe - EasyHealth',
    html: htmlContent,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`Password reset email successfully sent to: ${toEmail}. Message ID: ${info.messageId}`);
    return info;
  } catch (error) {
    console.error('Error occurred while sending password reset email:', error);
    throw error;
  }
}

module.exports = {
  sendResetPasswordEmail,
};
