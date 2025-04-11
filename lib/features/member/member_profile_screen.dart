import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';

class MemberProfileScreen extends StatefulWidget {
  final String userId;
  final String? groupId; // Optional: to show which group this member belongs to

  const MemberProfileScreen({
    Key? key,
    required this.userId,
    this.groupId,
  }) : super(key: key);

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _user;
  List<GroupModel> _userGroups = [];
  
  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _user = await userProvider.getUserById(widget.userId);
      
      if (_user == null) {
        throw Exception('Failed to load member data');
      }
      
      // Load user groups if groupId is not provided
      if (widget.groupId == null) {
        final groupProvider = Provider.of<GroupProvider>(context, listen: false);
        _userGroups = await groupProvider.getUserGroups(widget.userId);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading member profile: $e';
      });
      print('Error loading member profile data: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Member Profile',
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

                      // User Role
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRoleColor(_user!.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getRoleColor(_user!.role).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          _getRoleDisplay(_user!.role),
                          style: TextStyles.bodyText.copyWith(
                            color: _getRoleColor(_user!.role),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Contact Button
                      CustomButton(
                        label: 'Contact Member',
                        onPressed: () => _contactMember(_user!),
                        icon: Icons.message,
                        color: AppColors.primaryColor,
                        isFullWidth: false,
                        horizontalPadding: 32,
                      ),
                      
                      const SizedBox(height: 40),

                      // User Information Card
                      _buildUserInfoCard(_user!),

                      const SizedBox(height: 24),

                      // Emergency Contact Card
                      _buildEmergencyContactCard(_user!),
                      
                      if (_userGroups.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        // Groups Card
                        _buildGroupsCard(_userGroups),
                      ],
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }
  
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return AppColors.primaryColor;
      case 'admin':
        return AppColors.secondaryColor;
      case 'user':
        return AppColors.accentColor;
      default:
        return AppColors.textColor;
    }
  }
  
  String _getRoleDisplay(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Group Leader';
      case 'user':
        return 'Member';
      default:
        return role;
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

  void _contactMember(UserModel user) {
    CustomNotification.show(
      context: context,
      message: 'Contact ${user.fullName} at ${user.contact}',
      type: NotificationType.info,
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
              onPressed: _loadMemberData,
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
              'Member Not Found',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find this member\'s profile.',
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Go Back',
              onPressed: () => Navigator.pop(context),
              icon: Icons.arrow_back,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String fullName) {
    return Container(
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
      child: Center(
        child: Text(
          _getInitials(fullName),
          style: TextStyles.heading1.copyWith(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.bold,
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
            Row(
              children: [
                Icon(
                  Icons.emergency,
                  color: AppColors.errorColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Emergency Contact',
                  style: TextStyles.heading2.copyWith(
                    color: AppColors.errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
  
  Widget _buildGroupsCard(List<GroupModel> groups) {
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
                  Icons.group,
                  color: AppColors.secondaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Member Groups',
                  style: TextStyles.heading2.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondaryColor.withOpacity(0.2),
                    child: Text(
                      group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: TextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textColor.withOpacity(0.5),
                  ),
                  onTap: () {
                    // Navigate to group details
                    _showInfo('Navigate to ${group.name} details');
                  },
                );
              },
            ),
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
                value.isEmpty ? 'Not provided' : value,
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