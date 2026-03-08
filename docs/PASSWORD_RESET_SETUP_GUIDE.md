# Password Reset Implementation Setup Guide

## Overview

This guide provides step-by-step instructions to properly configure the password reset functionality for Safari Connect using Supabase authentication.

## Current Implementation Status

✅ **Completed:**
- Frontend password reset screens
- URL parameter handling for reset tokens
- Environment-based redirect URLs
- Custom email template design
- Deep linking integration

🔄 **Requires Configuration:**
- Supabase dashboard settings
- Redirect URL configuration
- Email template customization

## Step 1: Supabase Dashboard Configuration

### 1.1 Access Supabase Dashboard
1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project: `hubrwunvnuslutyykvli`
3. Navigate to **Authentication** section

### 1.2 Configure Redirect URLs
1. Go to **Authentication** → **URL Configuration**
2. Add these URLs to **Redirect URLs** section:

**For Development:**
```
http://localhost:3000/reset-password-handler
```

**For Production:**
```
https://safariconnect.org/reset-password-handler
```

### 1.3 Configure Email Template
1. Go to **Authentication** → **Email Templates**
2. Select **Password Recovery** template
3. Click **Customize**
4. Copy the HTML template from `docs/SUPABASE_EMAIL_TEMPLATE.md`
5. Set the subject to: `Reset your Safari Connect password`
6. Save the template

### 1.4 Optional: Configure Custom SMTP
For better email deliverability:

1. Go to **Settings** → **SMTP**
2. Configure with your email service:
   ```
   Host: smtp.gmail.com (or your provider)   
   Port: 587
   Username: noreply@safariconnect.org
   Password: [Your App Password]
   From Email: noreply@safariconnect.org
   From Name: Safari Connect
   ```

## Step 2: Environment Configuration

### 2.1 Development Environment
When testing locally:
- The app automatically uses `http://localhost:3000/reset-password-handler`
- Make sure your development server runs on port 3000
- Test with real emails that can receive the reset links

### 2.2 Production Environment
For production deployment:
- The app automatically uses `https://safariconnect.org/reset-password-handler`
- Ensure your domain is properly configured
- SSL certificate must be installed

## Step 3: Testing the Complete Flow

### 3.1 Development Testing
1. Start your Flutter app in debug mode
2. Navigate to **Reset Password** screen
3. Enter a test email address
4. Check your email for the reset link
5. Click the link - it should open `http://localhost:3000/reset-password-handler`
6. The app should extract tokens and show the **New Password** screen
7. Set a new password and verify login works

### 3.2 Production Testing
1. Deploy the app to production
2. Test with the production URL
3. Verify email links redirect to `https://safariconnect.org/reset-password-handler`
4. Test the complete password reset flow

## Step 4: URL Handling Implementation

### 4.1 How It Works
The password reset flow uses these components:

1. **ResetPasswordScreen**: User enters email
2. **Supabase**: Sends email with reset link containing tokens
3. **PasswordResetHandler**: Extracts tokens from URL and validates
4. **NewPasswordScreen**: Allows user to set new password

### 4.2 URL Structure
Supabase sends URLs like:
```
https://safariconnect.org/reset-password-handler#access_token=eyJ...&refresh_token=eyJ...&expires_in=3600&token_type=bearer&type=recovery
```

The app extracts tokens from the URL fragment for security.

### 4.3 Route Configuration
The app handles these routes:
- `/reset-password`: Initial reset request screen
- `/reset-password-handler`: Processes reset links with tokens
- `/new-password`: Fallback route for password setting

## Step 5: Security Considerations

### 5.1 Token Security
- Tokens are passed in URL fragments (not query parameters)
- Fragments are not sent to server, enhancing security
- Tokens expire automatically (default 24 hours)

### 5.2 Email Security
- Reset links contain one-time use tokens
- Links expire after 24 hours
- Users must have access to their email account

### 5.3 Best Practices
- Always validate tokens before allowing password reset
- Log out all user sessions after password reset
- Use HTTPS in production (enforced by Supabase)

## Step 6: Troubleshooting

### 6.1 Common Issues

**Issue**: Reset link doesn't work
**Solution**: 
- Check redirect URL configuration in Supabase
- Ensure URL matches exactly (no trailing slashes)
- Verify the app route is properly configured

**Issue**: Tokens not extracted
**Solution**:
- Check if URL contains fragments (#) not query parameters (?)
- Verify the PasswordResetHandler is properly extracting tokens
- Check browser console for JavaScript errors

**Issue**: Email not received
**Solution**:
- Check spam/junk folders
- Verify SMTP configuration
- Check Supabase logs for email delivery status

### 6.2 Debug Mode
Add debug logging to track the flow:

```dart
// In PasswordResetHandler
print('Reset URL: $uri');
print('Access Token: $accessToken');
print('Refresh Token: $refreshToken');
```

### 6.3 Testing Checklist
- [ ] Development redirect URL configured
- [ ] Production redirect URL configured
- [ ] Email template customized
- [ ] SMTP configured (optional)
- [ ] Complete flow tested in development
- [ ] Complete flow tested in production
- [ ] Error handling verified
- [ ] Security measures confirmed

## Step 7: Maintenance

### 7.1 Regular Tasks
- Monitor email delivery rates
- Check for failed password reset attempts
- Update email template as needed
- Review security logs periodically

### 7.2 Scaling Considerations
- Consider rate limiting for password reset requests
- Monitor Supabase usage limits
- Plan for high-volume reset scenarios

## Support

For issues with this implementation:

1. Check Supabase documentation: [https://supabase.com/docs](https://supabase.com/docs)
2. Review the code in `lib/features/auth/`
3. Check the email template in `docs/SUPABASE_EMAIL_TEMPLATE.md`
4. Contact the development team for technical support

## Files Modified

- `lib/core/constants/supabase_config.dart` - Updated redirect URLs
- `lib/features/auth/password_reset_handler.dart` - New URL handler
- `lib/main.dart` - Added new routes
- `docs/SUPABASE_EMAIL_TEMPLATE.md` - Custom email template
- `docs/PASSWORD_RESET_SETUP_GUIDE.md` - This guide

## Next Steps

1. Complete Supabase dashboard configuration
2. Test the complete flow
3. Deploy to production
4. Monitor for issues
5. Gather user feedback
