import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/widgets/change_user_group_dialog.dart';
import 'package:group_management_church_app/core/utils/role_utils.dart';

class RegionUserManagementTab extends StatefulWidget {
  final String regionId;

  const RegionUserManagementTab({super.key, required this.regionId});

  @override
  State<RegionUserManagementTab> createState() =>
      _RegionUserManagementTabState();
}

class _RegionUserManagementTabState extends State<RegionUserManagementTab> {
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];

  // State for search and filtering
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final users = await userProvider.getUsersByRegion(widget.regionId);

      if (mounted) {
        setState(() {
          _users = List<UserModel>.from(users);
          _filterUsers(); // Apply any existing filters
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredUsers =
          _users.where((user) {
            // Filter by search query
            final matchesQuery =
                query.isEmpty ||
                user.fullName.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query);

            // Filter by role
            final matchesRole =
                _selectedRole == 'All' ||
                (_selectedRole == 'Members' &&
                    user.role.toLowerCase() == 'user') ||
                (_selectedRole == 'Group Leaders' &&
                    user.role.toLowerCase() == 'admin');

            return matchesQuery && matchesRole;
          }).toList();
    });
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

  // Check if current user can change the target user's group
  bool _canChangeUserGroup(UserModel targetUser) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    final currentUserRole = currentUser?.role?.toLowerCase() ?? '';

    debugPrint('DEBUG: Current user role: $currentUserRole');
    debugPrint('DEBUG: Target user role: ${targetUser.role}');
    debugPrint(
      'DEBUG: Target user isRegionalLeadership: ${RoleUtils.isRegionalLeadership(targetUser.role)}',
    );
    debugPrint(
      'DEBUG: Target user isSuperAdmin: ${RoleUtils.isSuperAdmin(targetUser.role)}',
    );
    debugPrint(
      'DEBUG: Target user isRoot: ${RoleUtils.isRoot(targetUser.role)}',
    );

    // Regional Manager cannot change groups of Super Admins, Root, or other Regional Managers
    if (RoleUtils.isRoot(targetUser.role) ||
        RoleUtils.isSuperAdmin(targetUser.role) ||
        RoleUtils.isRegionalLeadership(targetUser.role)) {
      debugPrint('DEBUG: Cannot change group - target user is protected role');
      return false;
    }

    // Regional Manager can change groups of regular users and admins in their region
    final canChange = currentUserRole == 'regional manager';
    debugPrint('DEBUG: Can change group: $canChange');
    return canChange;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading users',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
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
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) {
              _filterUsers();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text('Filter by:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Members', child: Text('Members')),
                  DropdownMenuItem(
                    value: 'Group Leaders',
                    child: Text('Group Leaders'),
                  ),
                ],
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                    _filterUsers();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _filteredUsers.isEmpty
                  ? const Center(
                    child: Text('No users found matching the criteria'),
                  )
                  : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return Container(
                          key: ValueKey('user_${user.id}'),
                          child: _buildUserListItem(user),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildUserListItem(UserModel user) {
    // Get role display name
    String roleDisplay = 'Unknown';
    Color roleColor = Colors.grey;

    switch (user.role.toLowerCase()) {
      case 'super_admin':
        roleDisplay = 'Super Admin';
        roleColor = AppColors.primaryColor;
        break;
      case 'root':
        roleDisplay = 'Root';
        roleColor = AppColors.primaryColor;
        break;
      case 'regional manager':
        roleDisplay = 'Regional Manager';
        roleColor = AppColors.buttonColor;
        break;
      case 'admin':
        roleDisplay = 'Group Leader';
        roleColor = AppColors.secondaryColor;
        break;
      case 'user':
        roleDisplay = 'Member';
        roleColor = AppColors.accentColor;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.2),
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.fullName,
          style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyles.bodyText.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: roleColor.withOpacity(0.3)),
              ),
              child: Text(
                roleDisplay,
                style: TextStyles.bodyText.copyWith(
                  color: roleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (user.regionName != null && user.regionName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Group: ${user.regionName}',
                style: TextStyles.bodyText.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group change button
            if (_canChangeUserGroup(user))
              IconButton(
                key: ValueKey('change_group_${user.id}'),
                icon: const Icon(Icons.groups, color: AppColors.primaryColor),
                onPressed: () => _showChangeGroupDialog(user),
                tooltip: 'Change Group',
              ),
            // Edit role button
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.secondaryColor),
              onPressed: () {
                final role = user.role.toLowerCase();
                // Only Super Admin should assign or manage Regional Managers.
                // Prevent Region Managers from changing roles for Root, Super Admins or Regional leaders.
                if (role == 'root' ||
                    role == 'super_admin' ||
                    role == 'regional manager') {
                  _showInfo(
                    'You cannot change this user\'s role. Please contact a Super Admin.',
                  );
                  return;
                }
                _showEditUserDialog(user);
              },
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteUserDialog(user),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeGroupDialog(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => ChangeUserGroupDialog(
            user: user,
            currentRegionId:
                widget.regionId, // Restrict to regional manager's region
          ),
    ).then((result) {
      if (result == true) {
        // Refresh the current user data first to ensure permissions are up to date
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.currentUser != null) {
          userProvider.loadUser(userProvider.currentUser!.id);
        }
        // Then refresh the user list
        _loadUsers();
      }
    });
  }

  void _showEditUserDialog(UserModel user) {
    // Only allow editing between 'user' and 'admin' from the Region Manager screen.
    String selectedRole = user.role.toLowerCase();
    if (selectedRole != 'admin' && selectedRole != 'user') {
      selectedRole = 'user';
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.edit, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text('Change Role for ${user.fullName}'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Role:',
                  style: TextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getRoleColor(user.role).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getRoleDisplayName(user.role),
                    style: TextStyles.bodyText.copyWith(
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Select New Role:',
                  style: TextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  // Region managers should NOT be able to assign Regional Manager roles.
                  // Only Super Admin can promote someone to a regional leadership role.
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Member')),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Group Leader'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final updatedUser = UserModel(
                      id: user.id,
                      fullName: user.fullName,
                      email: user.email,
                      contact: user.contact,
                      nextOfKin: user.nextOfKin,
                      nextOfKinContact: user.nextOfKinContact,
                      role: selectedRole,
                      gender: user.gender,
                      regionId: user.regionId,
                      regionalID: user.regionalID,
                    );

                    final userProvider = Provider.of<UserProvider>(
                      context,
                      listen: false,
                    );
                    await userProvider.updateUser(updatedUser);

                    _showSuccess('User role updated successfully');
                    if (mounted) {
                      Navigator.pop(context);
                    }
                    _loadUsers(); // Refresh the user list
                  } catch (e) {
                    _showError('Failed to update user role: ${e.toString()}');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Update Role'),
              ),
            ],
          ),
    );
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove ${user.fullName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What would you like to remove the user from?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Choose one option:'),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Remove from groups only'),
                  subtitle: const Text(
                    'User will be removed from all groups in this region but will remain assigned to the region',
                  ),
                  leading: const Icon(
                    Icons.group_remove,
                    color: AppColors.primaryColor,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRemovalConfirmationDialog(
                      user,
                      removeFromGroups: true,
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _showRemovalConfirmationDialog(
    UserModel user, {
    required bool removeFromGroups,
  }) async {
    List<String> removalItems = [];
    if (removeFromGroups) removalItems.add('All groups in this region');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove ${user.fullName} from Groups'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to remove this user from:'),
                const SizedBox(height: 12),
                ...removalItems.map((item) => Text('• $item')),
                const SizedBox(height: 12),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
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
                onPressed: () async {
                  // Store navigator reference before async operation
                  final navigator = Navigator.of(context);

                  try {
                    if (mounted) {
                      Navigator.pop(context); // Close confirmation dialog
                    }

                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) => const AlertDialog(
                            content: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 16),
                                Text('Removing user...'),
                              ],
                            ),
                          ),
                    );

                    bool success = true;
                    String errorMessage = '';

                    // Remove from all groups in this region
                    if (removeFromGroups) {
                      try {
                        await _removeUserFromAllGroupsInRegion(user);
                      } catch (e) {
                        success = false;
                        errorMessage +=
                            'Failed to remove from groups: ${e.toString()}\n';
                      }
                    }

                    // Close loading dialog using stored navigator reference
                    try {
                      navigator.pop();
                    } catch (e) {
                      debugPrint('Error closing loading dialog: $e');
                    }

                    if (success) {
                      if (mounted) {
                        // Add a small delay to ensure dialog closure completes
                        await Future.delayed(const Duration(milliseconds: 100));
                        _showSuccess(
                          'User removed from all groups successfully',
                        );
                        _loadUsers(); // Refresh the user list
                      }
                    } else {
                      if (mounted) {
                        _showError(
                          errorMessage.isNotEmpty
                              ? errorMessage.trim()
                              : 'Failed to remove user',
                        );
                      }
                    }
                  } catch (e) {
                    // Close loading dialog if still open
                    try {
                      navigator.pop();
                    } catch (navError) {
                      debugPrint('Navigation error ignored: $navError');
                    }

                    if (mounted) {
                      _showError('Failed to remove user: ${e.toString()}');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  Future<void> _removeUserFromAllGroupsInRegion(UserModel user) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);

    // Only remove from the user's current group (1-user-to-1-group principle)
    if (user.regionId.isNotEmpty) {
      try {
        await groupProvider.removeMemberFromGroupWithReason(
          user.regionId,
          user.id,
          'Removed from region',
        );
      } catch (e) {
        // Try with legacy method if reason method fails
        try {
          await groupProvider.removeMemberFromGroup(user.regionId, user.id);
        } catch (legacyError) {
          print(
            'Error removing user from current group ${user.regionId}: $legacyError',
          );
          // Re-throw the error so the calling method knows it failed
          throw legacyError;
        }
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
      case 'root':
        return AppColors.primaryColor;
      case 'regional manager':
        return AppColors.buttonColor;
      case 'admin':
        return AppColors.secondaryColor;
      case 'user':
        return AppColors.accentColor;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return 'Super Admin';
      case 'root':
        return 'Root';
      case 'regional manager':
        return 'Regional Manager';
      case 'admin':
        return 'Group Leader';
      case 'user':
        return 'Member';
      default:
        return 'Unknown';
    }
  }
}
