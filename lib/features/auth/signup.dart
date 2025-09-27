import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/features/auth/profile_setup_screen.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/input_field.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/features/auth/login.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  bool _isLoading = false;
  bool _agreeToTerms = false;
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
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all fields correctly');
      return;
    }

    if (!_agreeToTerms) {
      _showError('Please agree to the Terms and Conditions');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.signup(
        _emailController.text,
        _passwordController.text,
      );

      if (result.success) {
        if (mounted) {
          _showSuccess(result.message);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        if (mounted) {
          _showError(result.message);
        }
      }
    } catch (e) {
      if (mounted) {
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

  void _navigateToLogin() {
    Navigator.pop(context);
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

              // Signup form
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
                            'Create Account',
                            style: TextStyles.heading1.copyWith(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Join our community today',
                            style: TextStyles.bodyText.copyWith(
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
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
                            hintText: 'Create a password',
                            prefixIcon: Icons.lock_outline,
                            isPasswordField: true,
                            validator: _validatePassword,
                            autovalidate: true,
                            helperText: 'Must be at least 6 characters with 1 uppercase letter and 1 number',
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password field
                          EnhancedInputField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            hintText: 'Confirm your password',
                            prefixIcon: Icons.lock_outline,
                            isPasswordField: true,
                            validator: _validateConfirmPassword,
                            autovalidate: true,
                          ),
                          const SizedBox(height: 16),

                          // Terms and conditions checkbox
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _agreeToTerms = value ?? false;
                                    });
                                  },
                                  activeColor: AppColors.secondaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'I agree to the Terms and Conditions and Privacy Policy',
                                  style: TextStyles.bodyText.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Signup button
                          CustomButton(
                            label: 'Sign Up',
                            onPressed: () { 
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:(_) => DisclaimerPopup(
                                  onAccepted: () async{
                                    _signup();
                                  }
                                )
                             );
                            },
                            isLoading : _isLoading,
                            color: Color(0xffd32f2f),
                            isPulsing: true,
                            pulseEffect: PulseEffectType.glow,
                          ),
                          const SizedBox(height: 20),

                          // Login option
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyles.bodyText,
                              ),
                              GestureDetector(
                                onTap: _navigateToLogin,
                                child: Text(
                                  'Login',
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

              // Bottom decorative element
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
        height: size.height * 0.22, // Slightly smaller than login
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.secondaryColor, // Swapped colors from login
              AppColors.primaryColor,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryColor.withOpacity(0.3),
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
              left: -20, // Changed position from login
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
              right: -30, // Changed position from login
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
                onTap: _navigateToLogin,
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

            // App logo and name
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo (placeholder)
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
                        Icons.person_add, // Different icon from login
                        size: 40,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // App name
                  Text(
                    'Join Safari Connect',
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
                  color: AppColors.secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_add, // Different icon from login
                  color: AppColors.secondaryColor,
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

          // Copyright text
          Text(
            '© 2025 Safari Connect. All rights reserved.',
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

class DisclaimerPopup extends StatefulWidget {
  final VoidCallback onAccepted;

  const DisclaimerPopup({super.key, required this.onAccepted});

  @override
  State<DisclaimerPopup> createState() => _DisclaimerPopupState();
}

class _DisclaimerPopupState extends State<DisclaimerPopup> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = false;
  bool _accepted = false;
  bool _showFull = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent) {
        setState(() {
          _isAtBottom = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Data Protection & Privacy Disclaimer",
        style: TextStyles.heading2.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
          maxWidth: MediaQuery.of(context).size.width * 0.1, // Adjust the multiplier as needed
        ),
        child: _showFull ? _buildFullContent() : _buildShortContent(),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      backgroundColor: Theme.of(context).cardTheme.color,
      actions: _showFull
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Decline",
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.errorColor,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _accepted
                    ? () {
                        Navigator.pop(context);
                        widget.onAccepted();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Continue",
                  style: TextStyles.bodyText.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.errorColor,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showFull = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "View More",
                  style: TextStyles.bodyText.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
    );
  }
Widget _buildShortContent() {
  return  Text(
    "By creating an account, you consent to the collection and use of your personal data for Safari group Ministry purposes and strictly in line with the Kenya Data Protection Act, 2019.",
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onBackground,
      height: 1.5,
    ),
    textAlign: TextAlign.justify,
  );
}

  Widget _buildFullContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child:  Text(
              "By registering and using this application, you consent to the collection and processing of your personal information by Christ Is The Answer Ministries (CITAM) Valley Road Safari Groups administration, including enrollment, attendance tracking, communication and discipleship reporting. Your information will be stored securely and will not be shared with unauthorized third parties. Access will be restricted to designated Safari Group leaders, coordinators, and ministry administrators for official ministry purposes only. You have the right to request access, correction, or deletion of your personal data in line with the provisions of the Kenya Data Protection Act, 2019. For any questions or to exercise your rights, please contact the Citam valley road safari group leadership.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox(
              value: _accepted,
              onChanged: _isAtBottom
                  ? (val) {
                      setState(() {
                        _accepted = val ?? false;
                      });
                    }
                  : null,
            ),
            const Flexible(child: Text("I Accept")),
          ],
        ),
      ],
    );
  }
}