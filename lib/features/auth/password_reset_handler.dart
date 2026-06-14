import 'package:flutter/material.dart';
import 'package:group_management_church_app/features/auth/reset_password.dart';

class PasswordResetHandler extends StatefulWidget {
  const PasswordResetHandler({super.key});

  @override
  State<PasswordResetHandler> createState() => _PasswordResetHandlerState();
}

class _PasswordResetHandlerState extends State<PasswordResetHandler> {
  bool _isLoading = true;
  String? _error;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _handlePasswordReset();
  }

  Future<void> _handlePasswordReset() async {
    try {
      final Uri? uri = ModalRoute.of(context)?.settings.arguments as Uri?;
      final contextUri = uri ?? Uri.base;
      _extractTokenFromUri(contextUri);
    } catch (e) {
      setState(() {
        _error = 'Invalid password reset link. Please request a new one.';
        _isLoading = false;
      });
    }
  }

  void _extractTokenFromUri(Uri uri) {
    String? accessToken;

    // Supabase embeds tokens in the URL fragment (#access_token=...&type=recovery)
    if (uri.fragment.isNotEmpty) {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      accessToken = fragmentParams['access_token'];
    }

    // Fallback: some redirect configurations use query parameters
    accessToken ??= uri.queryParameters['access_token'];

    if (accessToken != null && accessToken.isNotEmpty) {
      setState(() {
        _accessToken = accessToken;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'Missing token in reset link. Please request a new one.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
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
          title: const Text('Reset Password'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/reset-password');
                  },
                  child: const Text('Request New Reset Link'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return NewPasswordScreen(accessToken: _accessToken);
  }
}
