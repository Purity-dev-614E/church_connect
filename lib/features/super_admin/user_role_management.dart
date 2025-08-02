import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';

class UserRoleManagementScreen extends StatefulWidget {
  const UserRoleManagementScreen({super.key});

  @override
  State<UserRoleManagementScreen> createState() => _UserRoleManagementScreenState();
}

class _UserRoleManagementScreenState extends State<UserRoleManagementScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _users = [];
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _filteredUsers = [];
  
  // Available roles
  final List<String> _availableRoles = ['user', 'admin', 'regional manager', 'super admin'];
  
  // Regions list
  List<RegionModel> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadRegions();
  }
  
  Future<void> _loadRegions() async {
    try {
      final regionProvider = Provider.of<RegionProvider>(context, listen: false);
      await regionProvider.loadRegions();
      setState(() {
        _regions = regionProvider.regions;
      });
    } catch (e) {
      _showError('Failed to load regions: ${e.toString()}');
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final users = await userProvider.getAllUsers();
      
      setState(() {
        _users = List<UserModel>.from(users);
        _filteredUsers = List<UserModel>.from(users);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load users: ${e.toString()}';
      });
    }
  }
  
  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List<UserModel>.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          return user.fullName.toLowerCase().contains(query.toLowerCase()) ||
                 user.email.toLowerCase().contains(query.toLowerCase()) ||
                 user.role.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  Future<void> _updateUserRole(UserModel user, String newRole, {String? regionId}) async {
    // Debug logging
    log('Attempting to update role for user:');
    log('User ID: ${user.id}');
    log('User Name: ${user.fullName}');
    log('Current Role: ${user.role}');
    log('New Role: $newRole');
    log('Region ID: $regionId');

    // Validate user ID
    if (user.id.isEmpty) {
      print('Error: User ID is empty');
      _showError('Invalid user ID. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Create updated user model with all required fields
      final updatedUser = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        contact: user.contact,
        nextOfKin: user.nextOfKin,
        nextOfKinContact: user.nextOfKinContact,
        role: newRole,
        gender: user.gender,
        regionId: user.regionId,
        regionName: user.regionName,
        regionalID: newRole == 'regional manager' ? regionId ?? user.regionalID : user.regionalID,
      );

      print('Created updated user model:');
      print('ID: ${updatedUser.id}');
      print('Role: ${updatedUser.role}');
      
      // Update user role
      final success = await userProvider.updateUser(updatedUser);
      
      if (!success) {
        print('Failed to update user role');
        throw Exception('Failed to update user role');
      }
      
      // If the user is a regional manager, assign them to the region
      if (newRole == 'regional manager' && regionId != null) {
        print('Assigning user to region: $regionId');
        final regionSuccess = await userProvider.assignUserToRegion(user.id, regionId);
        if (!regionSuccess) {
          print('Failed to assign user to region');
          throw Exception('Failed to assign user to region');
        }
      }
      
      // Refresh user list
      await _loadUsers();
      
      // Show success message
      if (mounted) {
        if (newRole == 'regional manager' && regionId != null) {
          final region = _regions.firstWhere(
            (r) => r.id == regionId,
            orElse: () => RegionModel(id: regionId, name: 'Unknown Region')
          );
          _showSuccess('${user.fullName}\'s role updated to Regional Manager for ${region.name}');
        } else {
          _showSuccess('${user.fullName}\'s role updated to $newRole');
        }
      }
    } catch (e) {
      print('Error in _updateUserRole: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        _showError('Failed to update role: ${e.toString()}');
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
        title: 'User Role Management',
        showBackButton: true,
      ),
      body: _isLoading && _users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildUserList(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.errorColor,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyles.heading2.copyWith(
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyles.bodyText,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Retry',
            onPressed: _loadUsers,
            color: AppColors.primaryColor,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: _filterUsers,
          ),
        ),
        
        // User count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Users: ${_users.length}',
                style: TextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // User list
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    'No users found',
                    style: TextStyles.bodyText.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  key: const PageStorageKey<String>('userList'),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    return _buildUserCard(user);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildUserCard(UserModel user) {
    // Determine role color
    Color roleColor;
    switch (user.role.toLowerCase()) {
      case 'super_admin':
        roleColor = Colors.red;
        break;
      case 'admin':
        roleColor = Colors.orange;
        break;
      case 'regional manager':
        roleColor = Colors.purple;
        break;
      case 'user':
      default:
        roleColor = Colors.green;
        break;
    }
    
    return Card(
      key: ValueKey(user.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User avatar or initials
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  radius: 24,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyles.heading2.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (user.role == 'regional manager' && user.regionalID != null)
                        Text(
                          'Region: ${user.regionName}',
                          style: TextStyles.bodyText.copyWith(
                            color: Colors.purple[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Current role chip
                Chip(
                  avatar: user.role == 'regional manager'
                      ? const Icon(Icons.location_city, color: Colors.white, size: 16)
                      : null,
                  label: Text(
                    user.role == 'regional manager' ? 'Regional Manager' : user.role,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: roleColor,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            // Role selection
            Row(
              children: [
                const Text(
                  'Change Role:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _availableRoles.map((role) {
                        final isCurrentRole = role.toLowerCase() == user.role.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            key: ValueKey('${user.id}-$role'),
                            label: Text(role),
                            backgroundColor: isCurrentRole
                                ? AppColors.primaryColor
                                : Colors.grey[200],
                            labelStyle: TextStyle(
                              color: isCurrentRole ? Colors.white : Colors.black,
                              fontWeight: isCurrentRole ? FontWeight.bold : FontWeight.normal,
                            ),
                            onPressed: isCurrentRole
                                ? null
                                : () => _showRoleChangeConfirmation(user, role),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _showRoleChangeConfirmation(UserModel user, String newRole) {
    // If the new role is regional manager, show region selection dialog
    if (newRole == 'regional manager') {
      _showRegionSelectionDialog(user, newRole);
    } else {
      // For other roles, show standard confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Role Change'),
          content: Text(
            'Are you sure you want to change ${user.fullName}\'s role from ${user.role} to $newRole?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateUserRole(user, newRole);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }

  void _showRegionSelectionDialog(UserModel user, String newRole) {
    // Default selected region (either user's current region or first in list)
    String? selectedRegionId = user.regionalID;

    // ✅ Fallback to first region if user's region is null
    if (selectedRegionId == null && _regions.isNotEmpty) {
      selectedRegionId = _regions.first.id;
    }

    // ✅ Ensure selectedRegionId exists in the _regions list
    if (selectedRegionId != null &&
        !_regions.any((r) => r.id == selectedRegionId)) {
      selectedRegionId = _regions.isNotEmpty ? _regions.first.id : null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Regional Manager'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to change ${user.fullName}\'s role from ${user.role} to Regional Manager.',
                style: TextStyles.bodyText,
              ),
              const SizedBox(height: 16),
              const Text(
                'Select a region to manage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_regions.isEmpty)
                const Text(
                  'No regions available. Please create regions first.',
                  style: TextStyle(color: Colors.red),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedRegionId,
                      items: _regions.map((region) {
                        return DropdownMenuItem<String>(
                          value: region.id,
                          child: Text(region.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRegionId = value;
                        });
                      },
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _regions.isEmpty
                  ? null
                  : () {
                Navigator.pop(context);
                _updateUserRole(user, newRole, regionId: selectedRegionId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                disabledBackgroundColor: Colors.grey,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

}