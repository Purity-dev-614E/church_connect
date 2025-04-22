import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';
import '../admin/Admin_dashboard.dart';

class RegionGroupAdministrationTab extends StatefulWidget {
  final String regionId;

  const RegionGroupAdministrationTab({
    Key? key,
    required this.regionId,
  }) : super(key: key);

  @override
  State<RegionGroupAdministrationTab> createState() => _RegionGroupAdministrationTabState();
}

class _RegionGroupAdministrationTabState extends State<RegionGroupAdministrationTab> {
  bool _isLoading = false;
  String? _errorMessage;
  List<GroupModel> _groups = [];
  
  @override
  void initState() {
    super.initState();
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
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                ? _buildErrorView()
                : _groups.isEmpty
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
            color: AppColors.textColor.withOpacity(0.5),
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
              color: AppColors.textColor.withOpacity(0.7),
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
                        future: _fetchAdminName(group.group_admin),
                        builder: (context, snapshot) {
                          final adminName = snapshot.data ?? (group.group_admin.isNotEmpty ? "Loading..." : "No admin assigned");
                          return Text(
                            'Admin: $adminName',
                            style: TextStyles.bodyText.copyWith(
                              fontSize: 14,
                              color: AppColors.textColor.withOpacity(0.7),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyles.bodyText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminDashboard(
                          groupId: group.id,
                          groupName: group.name,
                          initialTabIndex: 0,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _showEditGroupDialog(context, group);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _showDeleteGroupDialog(context, group);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
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
                color: AppColors.textColor.withOpacity(0.7),
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
  
  void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? selectedAdminId;
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
              title: const Text('Create New Group'),
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
                                value: selectedAdminId,
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
                      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                      final success = await groupProvider.createGroup(
                        nameController.text.trim(),
                        descriptionController.text.trim(),
                        selectedAdminId ?? '',
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
                  child: const Text('Create'),
                ),
              ],
            );
          },
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