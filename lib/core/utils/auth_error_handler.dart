import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// A utility class for handling authentication errors globally
class AuthErrorHandler {
  /// Show a dialog when authentication fails
  static void handleAuthError(BuildContext context, {String? message}) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Show dialog only if user is currently authenticated
    if (authProvider.isAuthenticated) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Session Expired'),
          content: Text(message ?? 'Your session has expired. Please login again.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                
                // Navigate to login screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login', 
                  (route) => false
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  /// Try to refresh the token and return success status
  static Future<bool> tryRefreshToken(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final refreshed = await authProvider.refreshToken();
    
    if (!refreshed) {
      // Show error dialog if refresh failed
      handleAuthError(context);
    }
    
    return refreshed;
  }
}