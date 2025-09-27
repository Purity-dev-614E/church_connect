import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/features/auth/login.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/input_field.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetLinkSent = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.error,
    );
  }

  void _showSuccess(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.success,
    );
  }

  void _showInfo(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.info,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the AuthProvider instance
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Call resetPassword method from provider
        final result = await authProvider.resetPassword(_emailController.text.trim());

        if (mounted) {
          if (result.success) {
            setState(() {
              _resetLinkSent = true;
            });
          } else {
            _showError(result.message);
          }
        }
      } catch (e) {
        if (mounted) {
          _showError('An unexpected error occurred. Please try again.');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top decorative wave and logo
              _buildTopSection(size),

              // Reset password form or success message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _resetLinkSent ? _buildSuccessMessage() : _buildResetForm(),
                  ),
                ),
              ),

              // Bottom decorative element
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Header text
          Text(
            'Reset Password',
            style: TextStyles.heading1.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Enter your email to receive a password reset link',
            style: TextStyles.bodyText.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Email field
          EnhancedInputField(
            controller: _emailController,
            label: 'Email',
            hintText: 'Enter your registered email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            autovalidate: true,
          ),
          const SizedBox(height: 32),

          // Send reset link button
          CustomButton(
            label: 'Send Reset Link',
            onPressed: _sendResetLink,
            isLoading: _isLoading,
            color: AppColors.primaryColor,
            isPulsing: true,
            pulseEffect: PulseEffectType.glow,
          ),
          const SizedBox(height: 24),

          // Back to login option
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: TextStyles.bodyText,
              ),
              GestureDetector(
                onTap: _navigateToLogin,
                child: Text(
                  'Login',
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 30),

        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline,
            color: AppColors.primaryColor,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),

        // Success title
        Text(
          'Reset Link Sent!',
          style: TextStyles.heading2.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Success message
        Text(
          'We\'ve sent a password reset link to:\n${_emailController.text}',
          style: TextStyles.bodyText,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Instructions
        Text(
          'Please check your email and follow the instructions to reset your password.',
          style: TextStyles.bodyText.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Didn't receive email note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Didn\'t receive the email?',
                style: TextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your spam folder or try again in a few minutes.',
                style: TextStyles.bodyText.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Back to login button
        CustomButton(
          label: 'Back to Login',
          onPressed: _navigateToLogin,
          color: AppColors.primaryColor,
          isPulsing: false,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTopSection(Size size) {
    return Container(
      height: size.height * 0.22,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_reset,
                      size: 40,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Screen title
                Text(
                  'Password Recovery',
                  style: TextStyle(
                    fontFamily: 'WinkySans',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decorative divider
          Row(
            children: [
              const Expanded(
                child: Divider(
                  color: Colors.grey,
                  thickness: 0.5,
                  indent: 40,
                  endIndent: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  color: AppColors.primaryColor,
                  size: 16,
                ),
              ),
              const Expanded(
                child: Divider(
                  color: Colors.grey,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Support text
          Text(
            'Need help? Contact safariconnect.com',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// Verification code screen that can be used after email is sent
class VerificationCodeScreen extends StatefulWidget {
  final String email;

  const VerificationCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyCode();
      }
    }
  }

  void _verifyCode() {
    final code = _controllers.map((controller) => controller.text).join();
    if (code.length == 6) {
      setState(() {
        _isLoading = true;
      });

      // Simulate verification
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Navigate to new password screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewPasswordScreen(),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Code'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Text(
              'Verification Code',
              style: TextStyles.heading2.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Enter the 6-digit code sent to:',
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              widget.email,
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Code input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onCodeChanged(value, index),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Verify button
            CustomButton(
              label: 'Verify Code',
              onPressed: _verifyCode,
              isLoading: _isLoading,
              color: AppColors.primaryColor,
            ),
            const SizedBox(height: 24),

            // Resend code option
            TextButton(
              onPressed: () {
                // Resend code logic
              },
              child: Text(
                'Resend Code',
                style: TextStyles.bodyText.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// New password screen after verification
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.error,
    );
  }

  void _showSuccess(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.success,
    );
  }

  void _showInfo(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.info,
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Show success and navigate to login
          _showSuccess('Password reset successfully!');

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Password'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Text(
                'Create New Password',
                style: TextStyles.heading2.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Your new password must be different from previously used passwords.',
                style: TextStyles.bodyText.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),

              // New password field
              EnhancedInputField(
                controller: _passwordController,
                label: 'New Password',
                hintText: 'Enter new password',
                prefixIcon: Icons.lock_outline,
                isPasswordField: true,
                validator: _validatePassword,
                autovalidate: true,
                helperText: 'Must be at least 6 characters with 1 uppercase letter and 1 number',
              ),
              const SizedBox(height: 24),

              // Confirm password field
              EnhancedInputField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hintText: 'Confirm your password',
                prefixIcon: Icons.lock_outline,
                isPasswordField: true,
                validator: _validateConfirmPassword,
                autovalidate: true,
              ),
              const SizedBox(height: 40),

              // Reset button
              CustomButton(
                label: 'Reset Password',
                onPressed: _resetPassword,
                isLoading: _isLoading,
                color: AppColors.primaryColor,
                isPulsing: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}