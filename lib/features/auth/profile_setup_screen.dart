import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_management_church_app/core/auth/auth_wrapper.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/input_field.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  final String email;
  
  const ProfileSetupScreen({
    super.key,
    required this.userId,
    required this.email,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingRegions = false;
  
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _nextOfKinController = TextEditingController();
  final TextEditingController _nextOfKinContactController = TextEditingController();
  final TextEditingController _CitamAssembly = TextEditingController();
  final TextEditingController _ifNot = TextEditingController();
  
  // Selected gender
  String _selectedGender = 'female';
  final List<String> _genderOptions = ['male', 'female'];
  
  // Selected region
  String? _selectedRegionId;
  List<GroupModel> _regions = [];
  
  // Default role is 'user' - only super_admin can change roles
  final String _userRole = 'Christian User';

  // Profile picture state
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  // Age group radio buttons
  final List<String> _ageGroups = ['Under 20yrs', '21 to 30yrs', '31 to 40yrs', '41 to 50 yrs', 'Above 50yrs'];
  String _selectedAgeGroup = 'Under 18';
  //// Age group selection section
  // _buildAgeGroupSection(),


  @override
  void initState() {
    super.initState();
    // We need to use a post-frame callback because ModalRoute.of(context) is not available in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      _loadRegions();
    });
  }
  
  // Load available regions
  Future<void> _loadRegions() async {
    setState(() {
      _isLoadingRegions = true;
    });
    
    try {
      final regionProvider = Provider.of<GroupProvider>(context, listen: false);
      await regionProvider.fetchGroups();
      
      setState(() {
        _regions = regionProvider.groups;
        _isLoadingRegions = false;
      });
    } catch (e) {
      _showError('Error loading regions: $e');
      setState(() {
        _isLoadingRegions = false;
      });
    }
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
            
            // Set region if available
            _selectedRegionId = currentUser.regionId;
                    });
        }
      } catch (e) {
        _showError('Error loading user data: $e');
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

  // Ensure the phone number starts with '254' and matches the format
  final phoneRegExp = RegExp(r'^254[0-9]{9}$');
  if (!phoneRegExp.hasMatch(value)) {
    return 'Enter a valid phone number starting with 254';
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

  //Submit Form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRegionId == null || _selectedRegionId!.isEmpty) {
        _showError('Please select your region');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        await userProvider.loadUser(widget.userId);
        final currentUser = userProvider.currentUser;

        final role = currentUser?.role ?? _userRole;

        String selectedRegionName = 'your place of residence';
        if (_selectedRegionId != null) {
          final selectedRegion = _regions.firstWhere(
            (region) => region.id == _selectedRegionId,
            orElse: () => GroupModel(id: '', name: '', region_id: 'not specified'),
          );
          if (selectedRegion.name.isNotEmpty) {
            selectedRegionName = selectedRegion.name;
          }
        }

        final userModel = UserModel(
          id: widget.userId,
          fullName: _fullNameController.text.trim(),
          email: widget.email,
          contact: _contactController.text.trim(),
          nextOfKin: _nextOfKinController.text.trim(),
          nextOfKinContact: _nextOfKinContactController.text.trim(),
          age: _selectedAgeGroup,
          role: role,
          gender: _selectedGender,
          regionId: _selectedRegionId ?? '',
          regionName: selectedRegionName != 'your region' ? selectedRegionName : null,
          citam_Assembly: _CitamAssembly.text.trim(),
          if_Not: _ifNot.text.trim()

        );

        final success = await authProvider.updateProfile(userModel);

        if (success) {
          await userProvider.loadUser(widget.userId);
          _showSuccess('Profile updated successfully!');

          final isEditMode = ModalRoute.of(context)?.settings.arguments == 'edit_mode';
          if (isEditMode) {
            if (mounted) Navigator.of(context).pop(true);
          } else {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
              );
            }
          }
        } else {
          _showError('Failed to update profile. Please try again.');
        }
      } catch (e) {
        _showError('Error: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final image = await ImagePickerWeb.getImageAsBytes();
      if (image != null) {
        setState(() {
          _profileImageBytes = image;
          _profileImageUrl = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImageBytes == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      String tobase64Url(Uint8List bytes) {
        return base64Encode(bytes)
            .replaceAll('+', '-')
            .replaceAll('/', '_')
            .replaceAll(RegExp('=+\$'), '');
      }
      // Convert image bytes to base64
    final base64Image = tobase64Url(_profileImageBytes!);
    print('Base64 Image: $base64Image');
      
      // Get auth provider for token
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Upload image to server
      final success = await authProvider.uploadProfileImage(
        widget.userId,
        base64Image,
      );

      if (success) {
        _showSuccess('Profile picture updated successfully');
        // Get the new image URL
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUser(widget.userId);
        final updatedUser = userProvider.currentUser;
        if (updatedUser != null && updatedUser.profileImageUrl != null) {
          setState(() {
            _profileImageUrl = updatedUser.profileImageUrl;
            _profileImageBytes = null;
          });
        }
      } else {
        _showError('Failed to upload profile picture');
      }
    } catch (e) {
      _showError('Error uploading profile picture: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
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
                child: _profileImageBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _profileImageBytes!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      )
                    : _profileImageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _profileImageUrl!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primaryColor,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.primaryColor,
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
                    onPressed: _isUploadingImage ? null : _pickProfileImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_profileImageBytes != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadProfileImage,
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _isUploadingImage
                        ? null
                        : () {
                            setState(() {
                              _profileImageBytes = null;
                            });
                          },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorColor,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Add Profile Picture',
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
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

        // Age section
        _buildAgeGroupSection(),
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
        
        // Region selection dropdown
        _buildRegionDropdown(),
        const SizedBox(height: 16),

        //Citam Assembly
        EnhancedInputField(
          controller: _CitamAssembly,
          label: 'CITAM Assembly',
          hintText: 'Indicate CITAM Assembly you Attend',
          prefixIcon: Icons.group_work_outlined,
        ),

        // if not
        EnhancedInputField(
          controller: _ifNot,
          label: 'Not a CITAM Member?',
          hintText: 'If Not CITAM Member, Please Indicate Your Church',
          prefixIcon: Icons.question_mark_outlined,
        ),
        
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
  
  Widget _buildRegionDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.7)),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primaryColor.withOpacity(0.05),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Your Region',
                              style: TextStyles.bodyText.copyWith(
                                color: AppColors.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star,
                              color: AppColors.secondaryColor,
                              size: 16,
                            ),
                          ],
                        ),
                        // View all regions button
                        TextButton(
                          onPressed: () => _showAllRegions(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View All',
                                style: TextStyles.bodyText.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.primaryColor,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select the region you belong to for group assignments',
                      style: TextStyles.bodyText.copyWith(
                        fontSize: 12,
                        color: AppColors.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingRegions)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    else if (_regions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.errorColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No regions available. Please contact an administrator.',
                                style: TextStyles.bodyText.copyWith(
                                  color: AppColors.errorColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRegionId,
                            isExpanded: true,
                            hint: Text(
                              'Select your region',
                              style: TextStyles.bodyText.copyWith(
                                color: AppColors.textColor.withOpacity(0.5),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
                            style: TextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                // Find the selected region
                                final selectedRegion = _regions.firstWhere(
                                  (region) => region.id == newValue,
                                  orElse: () => GroupModel(id: '', name: '', region_id: 'not specified'),
                                );

                                if (selectedRegion.id.isNotEmpty) {
                                  // Debugging: Print selected region details
                                  print('Selected Region ID: ${selectedRegion.id}');
                                  print('Selected Region Name: ${selectedRegion.name}');

                                  // Update the selected region ID
                                  setState(() {
                                    _selectedRegionId = selectedRegion.id;
                                  });

                                  // Optionally show region info
                                  _showRegionInfo(selectedRegion);
                                }
                              }
                            },
                            items: _regions.map<DropdownMenuItem<String>>((GroupModel region) {
                              return DropdownMenuItem<String>(
                                value: region.id,
                                child: Text(region.name),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!_isLoadingRegions && _regions.isNotEmpty && _selectedRegionId == null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.secondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please select your region to continue',
                      style: TextStyles.bodyText.copyWith(
                        fontSize: 12,
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // Show region information dialog
  void _showRegionInfo(GroupModel region) {
    // Only show dialog if there's a description
    if (region.description == null || region.description!.isEmpty) {
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                region.name,
                style: TextStyles.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Region Information',
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              region.description ?? 'No description available',
              style: TextStyles.bodyText,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Show all available regions in a dialog
void _showAllRegions() {
  if (_regions.isEmpty) {
    _showInfo('No regions available');
    return;
  }

  String searchQuery = '';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.map,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Available Regions',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search field
            TextField(
              decoration: InputDecoration(
                hintText: 'Search regions...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            // Filtered regions list
            Expanded(
              child: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _regions.length,
                  itemBuilder: (context, index) {
                    final region = _regions[index];
                    final isSelected = _selectedRegionId == region.id;

                    // Filter regions based on search query
                    if (!region.name.toLowerCase().contains(searchQuery)) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      elevation: isSelected ? 2 : 0,
                      color: isSelected
                          ? AppColors.primaryColor.withOpacity(0.1)
                          : Colors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedRegionId = region.id;
                          });
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : AppColors.secondaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      region.name,
                                      style: TextStyles.bodyText.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : AppColors.textColor,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                ],
                              ),
                              if (region.description != null &&
                                  region.description!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  region.description!,
                                  style: TextStyles.bodyText.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textColor.withOpacity(0.7),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
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
  Widget _buildAgeGroupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Indicate your Age', Icons.cake_sharp),
        const SizedBox(height: 16),
        Column(
          children: _ageGroups.map((ageGroup) {
            return RadioListTile<String>(
              title: Text(ageGroup),
              value: ageGroup,
              groupValue: _selectedAgeGroup,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAgeGroup = value;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

