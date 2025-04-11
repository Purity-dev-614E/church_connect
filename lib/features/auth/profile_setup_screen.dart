import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_management_church_app/core/auth/auth_wrapper.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/input_field.dart';
import 'package:provider/provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  final String email;
  
  const ProfileSetupScreen({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _nextOfKinController = TextEditingController();
  final TextEditingController _nextOfKinContactController = TextEditingController();
  
  // Selected gender
  String _selectedGender = 'male';
  final List<String> _genderOptions = ['male', 'female'];
  
  // Default role is 'user' - only super_admin can change roles
  final String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    // We need to use a post-frame callback because ModalRoute.of(context) is not available in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  Future<void> _loadUserData() async {
    // Check if we're in edit mode
    final isEditMode = ModalRoute.of(context)?.settings.arguments == 'edit_mode';
    
    if (isEditMode) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Load current user data to pre-fill the form
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUser(widget.userId);
        final currentUser = userProvider.currentUser;
        
        if (currentUser != null) {
          // Pre-fill form fields with current user data
          setState(() {
            _fullNameController.text = currentUser.fullName;
            _contactController.text = currentUser.contact;
            _nextOfKinController.text = currentUser.nextOfKin;
            _nextOfKinContactController.text = currentUser.nextOfKinContact;
            
            // Set gender if it's one of the available options
            if (_genderOptions.contains(currentUser.gender)) {
              _selectedGender = currentUser.gender;
            }
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _contactController.dispose();
    _nextOfKinController.dispose();
    _nextOfKinContactController.dispose();
    super.dispose();
  }

  // Validate phone number format
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Simple validation for phone number format
    final phoneRegExp = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    
    return null;
  }

  // Validate full name
  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    
    return null;
  }

  // Submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Get the current user to preserve the role
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Try to get the current user to preserve their role
        await userProvider.loadUser(widget.userId);
        final currentUser = userProvider.currentUser;
        
        // Use existing role if available, otherwise default to 'user'
        final role = currentUser?.role ?? _userRole;
        
        // Create user model with updated information
        final userModel = UserModel(
          id: widget.userId,
          fullName: _fullNameController.text.trim(),
          email: widget.email,
          contact: _contactController.text.trim(),
          nextOfKin: _nextOfKinController.text.trim(),
          nextOfKinContact: _nextOfKinContactController.text.trim(),
          role: role, // Preserve existing role
          gender: _selectedGender,
        );
        
        // Update user profile
        final success = await authProvider.updateProfile(userModel);
        
        if (success) {
          // Update user in UserProvider
          await userProvider.loadUser(widget.userId);
          
          // Check if we're coming from ProfileScreen (edit mode)
          final isEditMode = ModalRoute.of(context)?.settings.arguments == 'edit_mode';
          
          if (isEditMode) {
            // Return to ProfileScreen with success result
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          } else {
            // First-time setup - navigate to AuthWrapper
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile. Please try again.'),
                backgroundColor: AppColors.errorColor,
              ),
            );
          }
        }
      } catch (e) {
        // Show error message
        if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  Text(
                    ModalRoute.of(context)?.settings.arguments == 'edit_mode'
                      ? 'Edit Your Profile'
                      : 'Complete Your Profile',
                    style: TextStyles.heading1.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    ModalRoute.of(context)?.settings.arguments == 'edit_mode'
                      ? 'Update your personal information below.'
                      : 'Please provide your personal information to complete your account setup.',
                    style: TextStyles.bodyText,
                  ),
                  const SizedBox(height: 32),
                  
                  // Profile picture section
                  _buildProfilePictureSection(),
                  const SizedBox(height: 32),
                  
                  // Personal information section
                  _buildPersonalInfoSection(),
                  const SizedBox(height: 32),
                  
                  // Emergency contact section
                  _buildEmergencyContactSection(),
                  const SizedBox(height: 32),
                  
                  // Additional information section
                  _buildAdditionalInfoSection(),
                  const SizedBox(height: 40),
                  
                  // Submit button
                  CustomButton(
                    label: ModalRoute.of(context)?.settings.arguments == 'edit_mode'
                      ? 'Save Changes'
                      : 'Complete Setup',
                    onPressed: _submitForm,
                    isLoading: _isLoading,
                    color: AppColors.primaryColor,
                    icon: ModalRoute.of(context)?.settings.arguments == 'edit_mode'
                      ? Icons.save
                      : Icons.check_circle,
                    isPulsing: true,
                    pulseEffect: PulseEffectType.glow,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Profile picture container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              
              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // TODO: Implement image picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Profile picture upload will be implemented'),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Add Profile Picture',
            style: TextStyles.bodyText.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Personal Information', Icons.person),
        const SizedBox(height: 16),
        
        // Full Name
        EnhancedInputField(
          controller: _fullNameController,
          label: 'Full Name',
          hintText: 'Enter your full name',
          prefixIcon: Icons.person_outline,
          validator: _validateFullName,
          autovalidate: true,
        ),
        const SizedBox(height: 16),
        
        // Email (non-editable, from login)
        EnhancedInputField(
          controller: TextEditingController(text: widget.email),
          label: 'Email Address',
          prefixIcon: Icons.email_outlined,
          enabled: false,
          filled: true,
          fillColor: Colors.grey[200],
        ),
        const SizedBox(height: 16),
        
        // Phone Number
        EnhancedInputField(
          controller: _contactController,
          label: 'Phone Number',
          hintText: 'Enter your phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: _validatePhoneNumber,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
          autovalidate: true,
        ),
        const SizedBox(height: 16),
        
        // Gender Selection
        _buildDropdownField(
          label: 'Gender',
          icon: Icons.wc,
          value: _selectedGender,
          items: _genderOptions,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedGender = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildEmergencyContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Emergency Contact', Icons.contact_phone),
        const SizedBox(height: 16),
        
        // Next of Kin
        EnhancedInputField(
          controller: _nextOfKinController,
          label: 'Next of Kin',
          hintText: 'Enter name of next of kin',
          prefixIcon: Icons.person_outline,
          validator: _validateFullName,
        ),
        const SizedBox(height: 16),
        
        // Next of Kin Contact
        EnhancedInputField(
          controller: _nextOfKinContactController,
          label: 'Next of Kin Phone Number',
          hintText: 'Enter next of kin phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: _validatePhoneNumber,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(15),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Additional Information', Icons.info_outline),
        const SizedBox(height: 16),
        
        // Display role information (not editable)
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.work_outline,
                color: AppColors.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role in Church',
                      style: TextStyles.bodyText.copyWith(
                        color: AppColors.textColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'User',
                      style: TextStyles.bodyText.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Note: Only Super Admins can change user roles',
                      style: TextStyles.bodyText.copyWith(
                        fontSize: 12,
                        color: AppColors.textColor.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
                style: TextStyles.bodyText,
                onChanged: onChanged,
                items: items.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

