import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_management_church_app/core/auth/auth_wrapper.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/core/navigation/page_router.dart';
import 'package:group_management_church_app/features/auth/reset_password.dart';
import 'package:group_management_church_app/features/auth/signup.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';

import '../../widgets/input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
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
      begin: const Offset(0, 0.5),
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
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  void _showError(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.error,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all fields correctly');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        _emailController.text,
        _passwordController.text,
      );

      if (result.success) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
          );
        }
      } else {
        if (mounted) {
          _showError(result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        print(e);
        _showError('An error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignupScreen()),
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

              // Login form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Welcome text
                          Text(
                            'Welcome Back',
                            style: TextStyles.heading1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Sign in to continue to your account',
                            style: TextStyles.bodyText.copyWith(
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email field
                          EnhancedInputField(
                            controller: _emailController,
                            label: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            autovalidate: true,
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          EnhancedInputField(
                            controller: _passwordController,
                            label: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icons.lock_outline,
                            isPasswordField: true,
                            validator: _validatePassword,
                            autovalidate: true,
                          ),
                          const SizedBox(height: 12),

                          // Remember me and forgot password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Remember me checkbox
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: TextStyles.bodyText.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),

                              // Forgot password
                              TextButton(
                                onPressed: () {
                                  PageRouter.navigateTo(context, ResetPasswordScreen());
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyles.bodyText.copyWith(
                                    color: Theme.of(context).colorScheme.onBackground,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Login button
                          CustomButton(
                            label: 'Login',
                            onPressed: _login,
                            isLoading: _isLoading,
                            color: Color(0xffd32f2f),
                            isPulsing: true,
                            pulseEffect: PulseEffectType.glow,
                          ),
                          const SizedBox(height: 20),

                          // Sign up option
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyles.bodyText.copyWith(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateToSignup,
                                child: Text(
                                  'Sign Up',
                                  style: TextStyles.bodyText.copyWith(
                                    color: Theme.of(context).colorScheme.onBackground,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom decorative element and copyright
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(Size size) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: size.height * 0.25, // Reduced height
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor,
              Colors.black38,
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
            // Decorative circles
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80, // Smaller circle
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
                width: 60, // Smaller circle
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // App logo and name
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo (placeholder)
                  Container(
                    width: 70, // Smaller logo
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
                        Icons.church,
                        size: 40, // Smaller icon
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced spacing

                  // App name
                  Text(
                    'Safari Connect',
                    style: TextStyle(
                      fontFamily: 'WinkySans',
                      fontSize: 26, // Smaller font
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced spacing

                  // App tagline
                  Text(
                    'Powered by the Spirit',
                    style: TextStyle(
                      fontSize: 13, // Smaller font
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0), // Reduced padding
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space
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
                padding: const EdgeInsets.all(6), // Smaller padding
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.church_outlined,
                  color: AppColors.primaryColor,
                  size: 16, // Smaller icon
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
          const SizedBox(height: 8), // Reduced spacing

          // Copyright text
          Text(
            '© 2025 Safari Connect. All rights reserved.',
            style: TextStyle(
              fontSize: 11, // Smaller font
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}