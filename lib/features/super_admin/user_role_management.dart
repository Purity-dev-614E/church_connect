import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:group_management_church_app/core/utils/role_utils.dart';

class _RoleOption {
  final String label;
  final String value;
  final String? alias;

  const _RoleOption({
    required this.label,
    required this.value,
    this.alias,
  });
}

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
  final List<_RoleOption> _availableRoles = const [
    _RoleOption(label: 'User', value: 'user'),
    _RoleOption(label: 'Admin', value: 'admin'),
    // _RoleOption(label: 'Regional Manager', value: 'regional manager'),
    _RoleOption(label: 'Regional Coordinator', value: 'regional manager', alias: 'Regional Coordinator'),
    _RoleOption(label: 'Regional Focal Person', value: 'regional manager', alias: 'Regional Focal Person'),
    _RoleOption(label: 'Super Admin', value: 'super admin'),
  ];
  
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
                 user.role.toLowerCase().contains(query.toLowerCase()) ||
                 (user.regionalTitle?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  String _formatRoleLabel(UserModel user) {
    final canonicalRole = RoleUtils.mapToDbRole(user.role);
    if (canonicalRole == 'regional manager') {
      final alias = user.regionalTitle?.trim();
      if (alias != null && alias.isNotEmpty) {
        return alias;
      }
      return 'Regional Manager';
    }
    return _titleCase(canonicalRole);
  }

  bool _optionMatchesUserRole(UserModel user, _RoleOption option) {
    final userRole = RoleUtils.mapToDbRole(user.role);
    final optionRole = RoleUtils.mapToDbRole(option.value);

    if (!RoleUtils.isRegionalLeadership(optionRole)) {
      return userRole == optionRole;
    }

    final alias = user.regionalTitle?.trim() ?? '';
    if (option.alias != null) {
      return userRole == 'regional manager' &&
          alias.toLowerCase() == option.alias!.toLowerCase();
    }

    return userRole == 'regional manager' && alias.isEmpty;
  }

  String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .map((segment) => segment[0].toUpperCase() + segment.substring(1))
        .join(' ');
  }

  Future<void> _updateUserRole(UserModel user, _RoleOption option, {String? regionId, String? groupId}) async {
    final mappedRole = RoleUtils.mapToDbRole(option.value);
    final isRegionalRole = RoleUtils.isRegionalLeadership(mappedRole);
    final displayLabel = option.label;

    log('Attempting to update role for user:');
    log('User ID: ${user.id}');
    log('User Name: ${user.fullName}');
    log('Current Role: ${user.role}');
    log('New Role (value): ${option.value}');
    log('Mapped Role (canonical): $mappedRole');
    log('Selected alias: ${option.alias}');
    log('Region ID (for Regional Manager): $regionId');
    log('Group ID (for Admin): $groupId or from user: ${user.regionId}');

    if (user.id.isEmpty) {
      _showError('Invalid user ID. Please try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Build updated user object
      final updatedUser = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        contact: user.contact,
        nextOfKin: user.nextOfKin,
        nextOfKinContact: user.nextOfKinContact,
        role: mappedRole,
        gender: user.gender,

        // Groups are tied to Admins
        regionId: mappedRole == 'admin'
            ? groupId ?? user.regionId
            : user.regionId,

        regionName: user.regionName,

        // Regions are tied to Regional leadership roles
        regionalID: isRegionalRole
            ? regionId ?? user.regionalID
            : user.regionalID,
        regionalTitle: isRegionalRole ? option.alias : null,
      );

      log('Created updated user model:');
      log('ID: ${updatedUser.id}');
      log('Role: ${updatedUser.role}');
      log('Group ID (regionId): ${updatedUser.regionId}');
      log('Region ID (regionalID): ${updatedUser.regionalID}');

      final success = await userProvider.updateUser(updatedUser);

      if (!success) {
        throw Exception('Failed to update user role');
      }

      // Assign regional leaders to region
      if (isRegionalRole && updatedUser.regionalID.isNotEmpty) {
        final regionSuccess = await userProvider.assignUserToRegion(user.id, updatedUser.regionalID);
        if (!regionSuccess) throw Exception('Failed to assign user to region');
      }

      // Assign admin to group
      if (mappedRole == 'admin' && updatedUser.regionId.isNotEmpty) {
        final adminSuccess = await GroupProvider().assignAdminToGroup(updatedUser.regionId, user.id);
        if (!adminSuccess) throw Exception('Failed to assign admin to group');
      }

      // Refresh user list
      await _loadUsers();

      // Success message
      if (mounted) {
        if (isRegionalRole && updatedUser.regionalID.isNotEmpty) {
          final region = _regions.firstWhere(
                (r) => r.id == updatedUser.regionalID,
            orElse: () => RegionModel(id: updatedUser.regionalID, name: 'Unknown Region'),
          );
          _showSuccess('${user.fullName}\'s role updated to $displayLabel for ${region.name}');
        } else if (mappedRole == 'admin' && updatedUser.regionId.isNotEmpty) {
          _showSuccess('${user.fullName}\'s role updated to ${displayLabel} for Group ${updatedUser.regionId}');
        } else {
          _showSuccess('${user.fullName}\'s role updated to $displayLabel');
        }
      }
    } catch (e) {
      log('Error in _updateUserRole: $e');
      if (mounted) {
        _showError('Failed to update role: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
              hintStyle: TextStyles.bodyText.copyWith(color: Theme.of(context).colorScheme.onBackground),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.background,
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
    final canonicalRole = RoleUtils.mapToDbRole(user.role);

    // Determine role color
    Color roleColor;
    switch (canonicalRole) {
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.contact,
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        "group: ${user.regionName}",
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (canonicalRole == 'regional manager' && user.regionalID.isNotEmpty)
                        Text(
                          'Region: ${user.overalRegionName}',
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
                  avatar: canonicalRole == 'regional manager'
                      ? const Icon(Icons.location_city, color: Colors.white, size: 16)
                      : null,
                  label: Text(
                    _formatRoleLabel(user),
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
                      children: _availableRoles.map((roleOption) {
                        final isCurrentRole = _optionMatchesUserRole(user, roleOption);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            key: ValueKey('${user.id}-${roleOption.label}'),
                            label: Text(roleOption.label),
                            backgroundColor: isCurrentRole
                                ? AppColors.primaryColor
                                : Colors.grey[200],
                            labelStyle: TextStyle(
                              color: isCurrentRole ? Colors.white : Colors.black,
                              fontWeight: isCurrentRole ? FontWeight.bold : FontWeight.normal,
                            ),
                            onPressed: isCurrentRole
                                ? null
                                : () => _showRoleChangeConfirmation(user, roleOption),
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
  
  void _showRoleChangeConfirmation(UserModel user, _RoleOption option) {
    final mappedRole = RoleUtils.mapToDbRole(option.value);

    if (RoleUtils.isRegionalLeadership(mappedRole)) {
      _showRegionSelectionDialog(user, option);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Role Change'),
        content: Text(
          'Are you sure you want to change ${user.fullName}\'s role from ${_formatRoleLabel(user)} to ${option.label}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateUserRole(user, option);
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

  void _showRegionSelectionDialog(UserModel user, _RoleOption option) {
    // Default selected region (either user's current region or first in list)
    String? selectedRegionId = user.regionalID.isNotEmpty ? user.regionalID : null;

    if (selectedRegionId == null && _regions.isNotEmpty) {
      selectedRegionId = _regions.first.id;
    }

    if (selectedRegionId != null &&
        !_regions.any((r) => r.id == selectedRegionId)) {
      selectedRegionId = _regions.isNotEmpty ? _regions.first.id : null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Assign ${option.label}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to change ${user.fullName}\'s role from ${_formatRoleLabel(user)} to ${option.label}.',
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
                _updateUserRole(user, option, regionId: selectedRegionId);
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