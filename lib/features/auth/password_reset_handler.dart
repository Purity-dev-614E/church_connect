import 'package:flutter/material.dart';
import 'package:group_management_church_app/features/auth/reset_password.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordResetHandler extends StatefulWidget {
  const PasswordResetHandler({super.key});

  @override
  State<PasswordResetHandler> createState() => _PasswordResetHandlerState();
}

class _PasswordResetHandlerState extends State<PasswordResetHandler> {
  bool _isLoading = true;
  String? _error;
  String? _accessToken;
  String? _refreshToken;

  @override
  void initState() {
    super.initState();
    _handlePasswordReset();
  }

  Future<void> _handlePasswordReset() async {
    try {
      // Get the current URI to extract tokens
      final Uri? uri = ModalRoute.of(context)?.settings.arguments as Uri?;
      
      if (uri == null) {
        // Try to get from current route if no arguments passed
        final contextUri = Uri.base;
        await _extractTokensFromUri(contextUri);
      } else {
        await _extractTokensFromUri(uri);
      }
    } catch (e) {
      setState(() {
        _error = 'Invalid password reset link. Please request a new one.';
        _isLoading = false;
      });
    }
  }

  Future<void> _extractTokensFromUri(Uri uri) async {
    // Extract tokens from URL fragment or query parameters
    String? accessToken;
    String? refreshToken;

    // Check URL fragment ( Supabase uses fragments for security)
    if (uri.fragment.isNotEmpty) {
      final fragmentUri = Uri.parse('https://example.com?${uri.fragment}');
      accessToken = fragmentUri.queryParameters['access_token'];
      refreshToken = fragmentUri.queryParameters['refresh_token'];
    }

    // Fallback to query parameters
    accessToken ??= uri.queryParameters['access_token'];
    refreshToken ??= uri.queryParameters['refresh_token'];

    if (accessToken != null && refreshToken != null) {
      // Set the session with the tokens
      final response = await Supabase.instance.client.auth.setSession(accessToken);
      
      if (response.session != null) {
        setState(() {
          _accessToken = accessToken;
          _refreshToken = refreshToken;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Invalid or expired reset link. Please request a new one.';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = 'Missing tokens in reset link. Please request a new one.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Validating reset link...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Reset Password'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/reset-password');
                  },
                  child: Text('Request New Reset Link'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If tokens are valid, navigate to new password screen
    return NewPasswordScreen(
      accessToken: _accessToken,
      refreshToken: _refreshToken,
    );
  }
}
