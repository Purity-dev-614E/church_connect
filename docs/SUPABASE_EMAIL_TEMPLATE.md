# Supabase Email Template Configuration

## Password Reset Email Template

### HTML Template
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Reset - Safari Connect</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #D32F2F, #F44336);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 28px;
            font-weight: 600;
        }
        .content {
            padding: 40px 30px;
        }
        .logo {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo svg {
            width: 60px;
            height: 60px;
        }
        .message {
            background-color: #FFEBEE;
            border-left: 4px solid #F44336;
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
        }
        .reset-button {
            display: inline-block;
            background: linear-gradient(135deg, #D32F2F, #F44336);
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 25px;
            font-weight: 600;
            margin: 20px 0;
            transition: all 0.3s ease;
        }
        .reset-button:hover {
            background: linear-gradient(135deg, #B71C1C, #D32F2F);
            transform: translateY(-2px);
        }
        .security-info {
            background-color: #FFF3E0;
            border-left: 4px solid #FF9800;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
            font-size: 14px;
        }
        .footer {
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 14px;
        }
        .support-info {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #eee;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 Password Reset</h1>
            <p>Safari Connect Church Management</p>
        </div>
        
        <div class="content">
            <div class="logo">
                <!-- Safari Connect Logo - Same as splash screen -->
                <div style="width: 80px; height: 80px; background: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 15px rgba(211, 47, 47, 0.3); margin: 0 auto;">
                    <div style="font-size: 40px; color: #D32F2F;">⛪</div>
                </div>
            </div>
            
            <h2>Hello {{ .User.Email }},</h2>
            
            <p>We received a request to reset your password for your Safari Connect account. If you made this request, please click the button below to set a new password:</p>
            
            <div style="text-align: center;">
                <a href="{{ .ConfirmationURL }}" class="reset-button">
                    Reset My Password
                </a>
            </div>
            
            <div class="message">
                <strong>Important:</strong> This password reset link will expire in 24 hours for your security.
            </div>
            
            <div class="security-info">
                <strong>🛡️ Security Notice:</strong>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    <li>If you didn't request this password reset, please ignore this email</li>
                    <li>Your password will remain unchanged if you don't click the reset link</li>
                    <li>Never share this reset link with anyone</li>
                    <li>Safari Connect staff will never ask for your password</li>
                </ul>
            </div>
            
            <p>If the button above doesn't work, you can copy and paste this link into your browser:</p>
            <p style="word-break: break-all; background-color: #f5f5f5; padding: 10px; border-radius: 5px; font-family: monospace; font-size: 12px;">
                {{ .ConfirmationURL }}
            </p>
            
            <div class="support-info">
                <p><strong>Need Help?</strong></p>
                <p>If you're having trouble resetting your password or didn't request this reset, please contact our support team:</p>
                <p>
                    📧 Email: support@safariconnect.org<br>
                    🌐 Website: safariconnect.org<br>
                    📱 Phone: [Your Support Phone Number]
                </p>
            </div>
        </div>
        
        <div class="footer">
            <p><em>This is an automated message from Safari Connect Church Management System.</em></p>
            <p style="font-size: 12px; color: #999;">
                © 2024 Safari Connect. All rights reserved.<br>
                This email was sent to {{ .User.Email }} because it's associated with a Safari Connect account.
            </p>
        </div>
    </div>
</body>
</html>
```

### Text Template (Fallback)
```
Password Reset - Safari Connect

Hello {{ .User.Email }},

We received a request to reset your password for your Safari Connect account.

To reset your password, please visit this link:
{{ .ConfirmationURL }}

Important:
- This link will expire in 24 hours for your security
- If you didn't request this reset, please ignore this email
- Never share this reset link with anyone

Need Help?
If you're having trouble, contact our support team:
Email: support@safariconnect.org
Website: safariconnect.org

This is an automated message from Safari Connect Church Management System.
© 2024 Safari Connect. All rights reserved.
```

## Configuration Instructions

### 1. In Supabase Dashboard:

1. Go to **Authentication** → **Email Templates**
2. Select **Password Recovery** template
3. Choose **Customize**
4. Paste the HTML template above
5. Set the subject line to: `Reset your Safari Connect password`
6. Save the template

### 2. Configure Redirect URLs:

In **Authentication** → **URL Configuration**, add these URLs:

**Production:**
- `https://safariconnect.org/reset-password-handler`

**Development:**
- `http://localhost:3000/reset-password-handler`

### 3. SMTP Configuration (Optional):

For better deliverability, configure custom SMTP in **Settings** → **SMTP**:

- **Host**: Your SMTP server
- **Port**: 587 (TLS) or 465 (SSL)
- **Username**: Your SMTP username
- **Password**: Your SMTP password
- **From Email**: noreply@safariconnect.org
- **From Name**: Safari Connect

### 4. Test the Template:

1. Go to **Authentication** → **Users**
2. Select a test user
3. Click "Send Password Recovery"
4. Check the email appearance and functionality

## Template Variables Available:

- `{{ .User.Email }}` - User's email address
- `{{ .User.ConfirmationURL }}` - Password reset link
- `{{ .SiteURL }}` - Your site URL
- `{{ .RedirectTo }}` - Redirect URL configured in your app

## Brand Colors Used:

- Primary Red: `#D32F2F`
- Light Red: `#F44336`
- Dark Red: `#B71C1C`
- Warning Orange: `#FF9800`
- Success Light: `#FFEBEE`
- Warning Light: `#FFF3E0`

These colors match the Safari Connect red honey app theme and provide a professional, trustworthy appearance for password reset emails.
