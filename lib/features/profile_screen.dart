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
import 'package:provider/provider.dart';
import '../data/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile image URL - null means we'll show initials
  String? _profileImageUrl;
  bool _isLoading = true;
  String? _errorMessage;
  
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot edit profile: User ID not found')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
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
    return Hero(
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
        child: _profileImageUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(_profileImageUrl!),
                backgroundColor: Colors.transparent,
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
            Text(
              'Personal Information',
              style: TextStyles.heading2.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', user.email),
            const Divider(),
            _buildInfoRow(Icons.phone, 'Phone', user.contact),
            const Divider(),
            _buildInfoRow(Icons.person, 'Gender', user.gender),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.secondaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Column(
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}