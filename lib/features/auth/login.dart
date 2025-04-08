import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_management_church_app/core/auth/auth_wrapper.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/core/navigation/page_router.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/features/auth/profile_setup_screen.dart';
import 'package:group_management_church_app/features/auth/reset_password.dart';
import 'package:group_management_church_app/features/auth/signup.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/input_field.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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

  Future<void> _login() async {
    // First validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the email and password
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      // Check for empty fields again (belt and suspenders)
      if (email.isEmpty || password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email and password are required'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
        return;
      }
      
      // Use AuthProvider for login
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('Attempting login with email: $email');
      
      final result = await authProvider.login(email, password);
      print('Login result: ${result.success}, message: ${result.message}');

      if (!mounted) return;

      if (result.success) {
        try {
          // Get user ID
          final authService = AuthServices();
          final userId = await authService.getUserId();
          print('User ID after login: $userId');
          
          if (userId == null || userId.isEmpty) {
            if (!mounted) return;
            
            // No user ID found
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful but user ID not found. Please try again.'),
                backgroundColor: AppColors.errorColor,
              ),
            );
            return;
          }
          
          // Load user data
          try {
            final userProvider = Provider.of<UserProvider>(context, listen: false);
            await userProvider.loadUser(userId);
            
            // Check if user has completed profile setup
            final user = userProvider.currentUser;
            print('User data loaded: ${user?.fullName}');
            
            if (!mounted) return;
            
            if (user != null && user.fullName.isNotEmpty) {
              // User has completed profile setup, navigate based on role
              print('Navigating to AuthWrapper for role-based routing. User role: ${user.role}');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
              );
            } else {
              // User needs to complete profile setup
              print('Navigating to ProfileSetupScreen');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSetupScreen(
                    userId: userId,
                    email: email,
                  ),
                ),
              );
            }
          } catch (e) {
            print('Error loading user data: $e');
            if (!mounted) return;
            
            // If we can't load user data, assume they need to complete profile setup
            print('Error loading user data, navigating to ProfileSetupScreen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileSetupScreen(
                  userId: userId,
                  email: email,
                ),
              ),
            );
          }
        } catch (e) {
          print('Error in login success flow: $e');
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error after login: ${e.toString()}'),
              backgroundColor: AppColors.errorColor,
            ),
          );
        }
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        print('Login exception: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.errorColor,
          ),
        );
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
      backgroundColor: AppColors.backgroundColor,
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
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Sign in to continue to your account',
                            style: TextStyles.bodyText.copyWith(
                              color: AppColors.textColor.withOpacity(0.7),
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
                                    color: AppColors.primaryColor,
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
                            color: AppColors.primaryColor,
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
                                style: TextStyles.bodyText,
                              ),
                              GestureDetector(
                                onTap: _navigateToSignup,
                                child: Text(
                                  'Sign Up',
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
              AppColors.secondaryColor,
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
                    'Church Connect',
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
                    'Pressing Towards the Mark',
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
            '© 2025 Church Connect. All rights reserved.',
            style: TextStyle(
              fontSize: 11, // Smaller font
              color: AppColors.textColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}