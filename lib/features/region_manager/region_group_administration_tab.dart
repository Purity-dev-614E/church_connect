import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/features/region_manager/region_user_management_tab.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';
import '../../data/providers/analytics_providers/admin_analytics_provider.dart';
import '../admin/Admin_dashboard.dart';
import 'package:group_management_church_app/features/region_manager/group_details_screen.dart';

class RegionGroupAdministrationTab extends StatefulWidget {
  final String regionId;

  const RegionGroupAdministrationTab({
    super.key,
    required this.regionId,
  });

  @override
  State<RegionGroupAdministrationTab> createState() => _RegionGroupAdministrationTabState();
}

class _RegionGroupAdministrationTabState extends State<RegionGroupAdministrationTab> {
  bool _isLoading = false;
  String? _errorMessage;
  List<GroupModel> _groups = [];
  List<GroupModel> _filteredGroups = [];
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _filteredGroups = _groups;
    _loadGroups();
  }
  
  Future<void> _loadGroups() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final groups = await groupProvider.getGroupsByRegion(widget.regionId);
      
      if (mounted) {
        setState(() {
          _groups = groups;
          _filteredGroups = _groups;
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

  @override
 Widget build(BuildContext context) {
   return Padding(
     padding: const EdgeInsets.all(16.0),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(
           'Group Management',
           style: TextStyles.heading1.copyWith(
             fontWeight: FontWeight.bold,
           ),
         ),
         const SizedBox(height: 16),
         Text(
           'Manage all groups in this region. You can create, edit, and view details of each group.',
           style: TextStyles.bodyText,
         ),
         const SizedBox(height: 16),
         TextField(
           onChanged: (value) {
             setState(() {
               _searchQuery = value.trim().toLowerCase();
               _filteredGroups = _groups
                   .where((group) => group.name.toLowerCase().contains(_searchQuery))
                   .toList();
             });
           },
           decoration: InputDecoration(
             labelText: 'Search Groups',
             prefixIcon: const Icon(Icons.search),
             border: OutlineInputBorder(
               borderRadius: BorderRadius.circular(12),
             ),
           ),
         ),
         const SizedBox(height: 24),
         Expanded(
           child: _isLoading
             ? const Center(child: CircularProgressIndicator())
             : _errorMessage != null
               ? _buildErrorView()
               : _filteredGroups.isEmpty
                 ? _buildEmptyView()
                 : _buildGroupList(),
         ),
         const SizedBox(height: 16),
         SizedBox(
           width: double.infinity,
           child: ElevatedButton.icon(
             onPressed: () {
               _showCreateGroupDialog(context);
             },
             icon: const Icon(Icons.add),
             label: const Text('Create New Group'),
             style: ElevatedButton.styleFrom(
               backgroundColor: AppColors.primaryColor,
               padding: const EdgeInsets.symmetric(vertical: 16),
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(12),
               ),
             ),
           ),
         ),
       ],
     ),
   );
 }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading groups',
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
            onPressed: _loadGroups,
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
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Groups Found',
            style: TextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first group to get started',
            style: TextStyles.bodyText.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showCreateGroupDialog(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Group'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroupList() {
    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildGroupListItem(group);
        },
      ),
    );
  }
  
  Widget _buildGroupListItem(GroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                CircleAvatar(
                  backgroundColor: AppColors.secondaryColor,
                  radius: 24,
                  child: const Icon(Icons.groups, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: TextStyles.heading2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: _fetchAdminName(group.group_admin!),
                        builder: (context, snapshot) {
                          final adminName = snapshot.data ?? (group.group_admin!.isNotEmpty ? "Loading..." : "No admin assigned");
                          return Text(
                            'Admin: $adminName',
                            style: TextStyles.bodyText.copyWith(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                FutureBuilder<Map<String, int>>(
                  future: _fetchGroupActivityStatus(group.id),
                  builder: (context, snapshot) {
                    final status = snapshot.data ?? {'active': 0, 'inactive': 0};
                    final isActive = status['active']! >= status['inactive']!;
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.successColor : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchGroupStats(group.id),
              builder: (context, snapshot) {
                final memberCount = snapshot.data?['memberCount'] ?? '0';
                final eventCount = snapshot.data?['eventCount'] ?? '0';
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGroupStat(
                      'Members', 
                      memberCount.toString(), 
                      Icons.people,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminDashboard(
                              groupId: group.id,
                              groupName: group.name,
                              initialTabIndex: 1,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildGroupStat(
                      'Events', 
                      eventCount.toString(), 
                      Icons.event,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminDashboard(
                              groupId: group.id,
                              groupName: group.name,
                              initialTabIndex: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildGroupStat('Attendance', '0%', Icons.trending_up),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupDetailsScreen(
                          groupId: group.id,
                          groupName: group.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showEditGroupDialog(context, group);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showAssignAdminDialog(context, group);
                  },
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Assign Admin'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showDeleteGroupDialog(context, group);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGroupStat(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyles.heading2.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyles.bodyText.copyWith(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<String> _fetchAdminName(String adminId) async {
    if (adminId.isEmpty) {
      return "No admin assigned";
    }
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final admin = await userProvider.getUserById(adminId);
      return admin?.fullName ?? "Unknown";
    } catch (e) {
      print('Error fetching admin name: $e');
      return "Unknown";
    }
  }
  
  Future<Map<String, dynamic>> _fetchGroupStats(String groupId) async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      return await groupProvider.getGroupStats(groupId);
    } catch (e) {
      print('Error fetching group stats: $e');
      return {'memberCount': 0, 'eventCount': 0};
    }
  }
  
  Future<Map<String, int>> _fetchGroupActivityStatus(String groupId) async {
    try {
      final analyticsProvider = Provider.of<AdminAnalyticsProvider>(context, listen: false);
      final status = await analyticsProvider.getGroupMemberActivityStatus(groupId);
      
      // Handle the response format correctly
      final active = status['active'] is num ? (status['active'] as num).toInt() : 0;
      final inactive = status['inactive'] is num ? (status['inactive'] as num).toInt() : 0;
      
      return {
        'active': active,
        'inactive': inactive,
      };
    } catch (e) {
      print('Error fetching group activity status: $e');
      // Return default values on error
      return {'active': 0, 'inactive': 0};
    }
  }
  
  void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.group_add, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              const Text('Create New Group'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group Information',
                  style: TextStyles.heading2.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    prefixIcon: const Icon(Icons.group),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  _showError('Group name is required');
                  return;
                }

                try {
                  final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                  final success = await groupProvider.createGroup(
                    nameController.text.trim(),
                    descriptionController.text.trim(),
                    '', // Empty admin ID for now
                    widget.regionId,
                  );

                  if (success) {
                    _showSuccess('Group created successfully');
                    Navigator.pop(context);
                    _loadGroups(); // Refresh the group list
                  } else {
                    _showError('Failed to create group');
                  }
                } catch (e) {
                  _showError('Failed to create group: ${e.toString()}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Create Group'),
            ),
          ],
        );
      },
    );
  }
  
  void _showEditGroupDialog(BuildContext context, GroupModel group) {
    final TextEditingController nameController = TextEditingController(text: group.name);
    final TextEditingController descriptionController = TextEditingController(text: group.description);
    String? selectedAdminId = group.group_admin;
    List<UserModel> availableAdmins = [];
    bool isLoadingAdmins = true;
    
    // Load available admins
    Future<void> loadAdmins() async {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final users = await userProvider.getUsersByRegion(widget.regionId);
        // Filter users with admin role
        availableAdmins = users.where((user) => user.role == 'admin').toList();
        isLoadingAdmins = false;
      } catch (e) {
        print('Error loading admins: $e');
        isLoadingAdmins = false;
      }
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Start loading admins
        loadAdmins();
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Group'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Group Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    isLoadingAdmins
                        ? const Center(child: CircularProgressIndicator())
                        : availableAdmins.isEmpty
                            ? const Text('No group leaders available in this region')
                            : DropdownButtonFormField<String>(
                                value: selectedAdminId!.isEmpty ? null : selectedAdminId,
                                decoration: const InputDecoration(labelText: 'Group Leader'),
                                hint: const Text('Select Group Leader'),
                                items: availableAdmins.map((admin) {
                                  return DropdownMenuItem<String>(
                                    value: admin.id,
                                    child: Text(admin.fullName),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedAdminId = value;
                                  });
                                },
                              ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      _showError('Group name is required');
                      return;
                    }

                    try {
                      final updatedGroup = GroupModel(
                        id: group.id,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        group_admin: selectedAdminId ?? '',
                        region_id: widget.regionId,
                      );

                      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                      final success = await groupProvider.updateGroup(updatedGroup);

                      if (success) {
                        _showSuccess('Group updated successfully');
                        Navigator.pop(context);
                        _loadGroups(); // Refresh the group list
                      } else {
                        _showError('Failed to update group');
                      }
                    } catch (e) {
                      _showError('Failed to update group: ${e.toString()}');
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showAssignAdminDialog(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AssignAdminDialog(
        regionId: widget.regionId,
        group: group,
        onSuccess: () {
          _loadGroups(); // Refresh the group list
        },
      ),
    );
  }
  
  void _showDeleteGroupDialog(BuildContext context, GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete ${group.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                final success = await groupProvider.deleteGroup(group.id);
                
                if (success) {
                  _showSuccess('Group deleted successfully');
                  Navigator.pop(context);
                  _loadGroups(); // Refresh the group list
                } else {
                  _showError('Failed to delete group');
                }
              } catch (e) {
                _showError('Failed to delete group: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AssignAdminDialog extends StatefulWidget {
  final String regionId;
  final GroupModel group;
  final VoidCallback onSuccess;

  const _AssignAdminDialog({
    required this.regionId,
    required this.group,
    required this.onSuccess,
  });

  @override
  State<_AssignAdminDialog> createState() => _AssignAdminDialogState();
}

class _AssignAdminDialogState extends State<_AssignAdminDialog> {
  String? selectedAdminId;
  List<UserModel> availableAdmins = [];
  bool isLoadingAdmins = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    print('Starting to load admins for region: ${widget.regionId}');
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      print('Fetching users from region...');
      final users = await userProvider.getUsersByRegion(widget.regionId);
      print('Found ${users.length} total users in region');
      
      // Filter users with admin role and log their details
      final admins = users.where((user) {
        final hasAdminRole = user.role.toLowerCase() == 'admin' || 
                            user.role.toLowerCase() == 'group_leader' ||
                            user.role.toLowerCase() == 'regional_manager';
        if (hasAdminRole) {
          print('Found potential admin: ${user.fullName} (${user.email}) with role: ${user.role}');
        }
        return hasAdminRole;
      }).toList();
      
      print('Found ${admins.length} users with admin roles');
      print('Available admins:');
      for (var admin in admins) {
        print('- ${admin.fullName} (${admin.email}) - Role: ${admin.role}');
      }

      if (mounted) {
        setState(() {
          availableAdmins = admins;
          isLoadingAdmins = false;
        });
      }
    } catch (e) {
      print('Error loading admins: $e');
      if (mounted) {
        setState(() {
          isLoadingAdmins = false;
        });
      }
      _showError('Failed to load group leaders: ${e.toString()}');
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.person_add, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Text('Assign Admin to ${widget.group.name}'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoadingAdmins)
              const Center(child: CircularProgressIndicator())
            else if (availableAdmins.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'No Group Leaders Available',
                          style: TextStyles.bodyText.copyWith(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You need to assign an admin role to users before they can be selected as group leaders.',
                      style: TextStyles.bodyText.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to user management tab
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegionUserManagementTab(regionId: widget.regionId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people),
                      label: const Text('Manage Users'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedAdminId,
                  decoration: const InputDecoration(
                    labelText: 'Select Group Leader',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: availableAdmins.map((admin) {
                    return DropdownMenuItem<String>(
                      value: admin.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                            child: Text(
                              admin.fullName.isNotEmpty ? admin.fullName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                admin.fullName,
                                style: TextStyles.bodyText.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                admin.email,
                                style: TextStyles.bodyText.copyWith(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                'Role: ${admin.role}',
                                style: TextStyles.bodyText.copyWith(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    print('Selected admin ID: $value');
                    setState(() {
                      selectedAdminId = value;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (selectedAdminId == null) {
              _showError('Please select a group leader');
              return;
            }

            print('Attempting to assign admin $selectedAdminId to group ${widget.group.id}');
            try {
              final updatedGroup = GroupModel(
                id: widget.group.id,
                name: widget.group.name,
                description: widget.group.description,
                group_admin: selectedAdminId!,
                region_id: widget.group.region_id,
              );

              final groupProvider = Provider.of<GroupProvider>(context, listen: false);
              print('Updating group with new admin...');
              final success = await groupProvider.updateGroup(updatedGroup);

              if (success) {
                print('Successfully assigned admin to group');
                _showSuccess('Group leader assigned successfully');
                Navigator.pop(context);
                widget.onSuccess();
              } else {
                print('Failed to assign admin to group');
                _showError('Failed to assign group leader');
              }
            } catch (e) {
              print('Error assigning admin: $e');
              _showError('Failed to assign group leader: ${e.toString()}');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Assign Leader'),
        ),
      ],
    );
  }
}