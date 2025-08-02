import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/features/auth/profile_setup_screen.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';
import '../data/providers/user_provider.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile image state
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  bool _isUploadingImage = false;
  bool _isLoading = true;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  
  // User and group data
  UserModel? _user;
  List<GroupModel> _userGroups = [];
  GroupModel? _primaryGroup;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current user from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Get user ID
      final authService = AuthServices();
      final userId = await authService.getUserId();
      print('User ID: $userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }
      
      // Load user data
      await userProvider.loadUser(userId);
      _user = userProvider.currentUser;
      
      if (_user == null) {
        throw Exception('Failed to load user data');
      }
      
      // Set profile image URL if available
      if (_user!.profileImageUrl != null) {
        setState(() {
          _profileImageUrl = _user!.profileImageUrl;
        });
      }
      
      // Load user groups
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      _userGroups = await groupProvider.getUserGroups(userId);
      
      // Set primary group (first group or empty if no groups)
      _primaryGroup = _userGroups.isNotEmpty ? _userGroups.first : null;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: $e';
      });
      print('Error loading profile data: $e');
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
      // Convert image bytes to base64
      final base64Image = base64Encode(_profileImageBytes!);
      
      // Get auth provider for token
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get user ID
      final authService = AuthServices();
      final userId = await authService.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }
      
      // Upload image to server
      final success = await authProvider.uploadProfileImage(
        userId,
        base64Image,
      );

      if (success) {
        _showSuccess('Profile picture updated successfully');
        // Get the new image URL
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUser(userId);
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

  // Get user initials from full name
  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    
    List<String> nameParts = fullName.split(' ');
    String initials = '';

    if (nameParts.isNotEmpty) {
      if (nameParts.length >= 2) {
        // Get first letter of first and last name
        initials = nameParts[0][0] + nameParts[nameParts.length - 1][0];
      } else {
        // If only one name, get first two letters or just first letter if name is only one character
        initials = nameParts[0].length > 1 ? nameParts[0].substring(0, 2) : nameParts[0][0];
      }
    }

    return initials.toUpperCase();
  }

  void _navigateToEditProfile() async {
    if (_user == null) return;
    
    try {
      final authService = AuthServices();
      final userId = await authService.getUserId();
      
      if (userId == null) {
        _showError('Cannot edit profile: User ID not found');
        return;
      }
      
      // Navigate to profile setup screen with current user data
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(
            userId: userId,
            email: _user!.email,
          ),
          settings: const RouteSettings(arguments: 'edit_mode'),
        ),
      );
      
      // Reload user data when returning from edit screen
      if (result == true) {
        _loadUserData();
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    }
  }
  
  // Logout function
  Future<void> _logout(BuildContext context) async {
    try {
      final authServices = AuthServices();
      await authServices.logout();
      
      // Navigate to login screen and clear all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      _showError('Error logging out: $e');
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all required fields correctly');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Get current user to preserve existing data
      final currentUser = userProvider.currentUser;
      if (currentUser == null) {
        _showError('User data not found');
        return;
      }

      // Create updated user model
      final updatedUser = UserModel(
        id: currentUser.id,
        fullName: currentUser.fullName,
        email: currentUser.email,
        contact: currentUser.contact,
        nextOfKin: currentUser.nextOfKin,
        nextOfKinContact: currentUser.nextOfKinContact,
        role: currentUser.role,
        gender: currentUser.gender,
        regionId: currentUser.regionId,
        regionalID: currentUser.regionalID
      );

      // Update user profile
      final success = await authProvider.updateProfile(updatedUser);

      if (success) {
        if (mounted) {
          _showSuccess('Profile updated successfully!');
          // Reload user data to reflect changes
          await userProvider.loadUser(currentUser.id);
        }
      } else {
        if (mounted) {
          _showError('Failed to update profile. Please try again.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Profile',
        showBackButton: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? _buildErrorView()
          : _user == null
            ? _buildNoUserView()
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Profile Picture or Initials
                        _buildProfileAvatar(_user!.fullName),

                        const SizedBox(height: 24),

                        // User Name
                        Text(
                          _user!.fullName,
                          style: TextStyles.heading1.copyWith(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // User Role and Group
                        Text(
                          _primaryGroup != null 
                            ? '${_user!.role} • ${_primaryGroup!.name}'
                            : _user!.role,
                          style: TextStyles.bodyText.copyWith(
                            color: AppColors.secondaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Edit Profile Button
                        CustomButton(
                          label: 'Edit Profile',
                          onPressed: _navigateToEditProfile,
                          icon: Icons.edit,
                          color: AppColors.primaryColor,
                          isPulsing: true,
                          pulseEffect: PulseEffectType.glow,
                          isFullWidth: false,
                          horizontalPadding: 32,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Logout Button
                        CustomButton(
                          label: 'Logout',
                          onPressed: () => _logout(context),
                          icon: Icons.logout,
                          color: AppColors.errorColor,
                          isFullWidth: false,
                          horizontalPadding: 32,
                        ),

                        const SizedBox(height: 40),

                        // User Information Card
                        _buildUserInfoCard(_user!),

                        const SizedBox(height: 24),

                        // Emergency Contact Card
                        _buildEmergencyContactCard(_user!),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Profile',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Try Again',
              onPressed: _loadUserData,
              icon: Icons.refresh,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoUserView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off,
              color: AppColors.secondaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'User Not Found',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find your user profile. Please try logging in again.',
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Refresh',
              onPressed: _loadUserData,
              icon: Icons.refresh,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String fullName) {
    return Stack(
      children: [
        Hero(
          tag: 'profile-avatar',
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.secondaryColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
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
                            return Center(
                              child: Text(
                                _getInitials(fullName),
                                style: TextStyles.heading1.copyWith(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          _getInitials(fullName),
                          style: TextStyles.heading1.copyWith(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
          ),
        ),
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
        if (_profileImageBytes != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadProfileImage,
                    icon: const Icon(Icons.upload, color: Colors.white, size: 16),
                    label: const Text(
                      'Upload',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.white, size: 16),
                    onPressed: _isUploadingImage
                        ? null
                        : () {
                            setState(() {
                              _profileImageBytes = null;
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
        if (_isUploadingImage)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfoCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Personal Information',
                  style: TextStyles.heading2.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', user.email),
            const Divider(),
            _buildInfoRow(Icons.phone, 'Phone', user.contact),
            const Divider(),
            _buildInfoRow(Icons.person, 'Gender', user.gender),
            const Divider(),
            _buildInfoRow(
              Icons.location_on, 
              'Region', 
              user.regionName ?? (user.regionId != null ? 'Region ID: ${user.regionId}' : 'Not assigned'),
              user.regionId != null ? AppColors.primaryColor : AppColors.errorColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(UserModel user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contact',
              style: TextStyles.heading2.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Name', user.nextOfKin),
            const Divider(),
            _buildInfoRow(Icons.phone, 'Phone', user.nextOfKinContact),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, [Color? iconColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? AppColors.secondaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.textColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: label == 'Region' && value == 'Not assigned' 
                        ? AppColors.errorColor.withOpacity(0.7)
                        : AppColors.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}