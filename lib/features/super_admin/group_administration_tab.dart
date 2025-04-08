import 'dart:async';

import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:provider/provider.dart';

class GroupAdministrationTab extends StatefulWidget {
  const GroupAdministrationTab({Key? key}) : super(key: key);

  @override
  State<GroupAdministrationTab> createState() => _GroupAdministrationTabState();
}

class _GroupAdministrationTabState extends State<GroupAdministrationTab> {
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
      await groupProvider.fetchGroups();
      
      if (mounted) {
        setState(() {
          _groups = groupProvider.groups;
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
            'Manage all church groups from this dashboard. You can create, edit, and view details of each group.',
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
                _showCreateGroupDialog(context).then((created) {
                  if (created) {
                    _loadGroups();
                  }
                });
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
              _showCreateGroupDialog(context).then((created) {
                if (created) {
                  _loadGroups();
                }
              });
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
    // Wrap with IgnorePointer to disable any automatic navigation that might be happening
    return IgnorePointer(
      ignoring: false, // Set to true to completely disable all interactions
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // Explicitly set onTap to null to prevent any navigation
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
                      // Fetch admin name safely
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
            // Fetch group stats safely
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchGroupStats(group.id),
              builder: (context, snapshot) {
                final memberCount = snapshot.data?['memberCount'] ?? '0';
                final eventCount = snapshot.data?['eventCount'] ?? '0';
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGroupStat('Members', memberCount.toString(), Icons.people),
                    _buildGroupStat('Events', eventCount.toString(), Icons.event),
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
                    // View group details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('View details for ${group.name}')),
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
                    // Edit group
                    _showEditGroupDialog(context, group).then((updated) {
                      if (updated) {
                        _loadGroups();
                      }
                    });
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
                    // Delete group
                    _showDeleteGroupDialog(context, group).then((deleted) {
                      if (deleted) {
                        _loadGroups();
                      }
                    });
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
      ),
    );
  }
  
  Widget _buildGroupStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyles.bodyText.copyWith(
            fontSize: 12,
            color: AppColors.textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Future<bool> _showCreateGroupDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final completer = Completer<bool>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              completer.complete(false); // No changes made
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                  final newGroup = GroupModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    group_admin: '',
                  );
                  
                  await groupProvider.createGroup(newGroup);
                  
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "${nameController.text}" created successfully'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                  completer.complete(true); // Group created successfully
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create group: $e'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                  completer.complete(false); // Failed to create group
                }
              } else {
                completer.complete(false); // Validation failed
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    
    return completer.future;
  }
  
  Future<bool> _showEditGroupDialog(BuildContext context, GroupModel group) async {
    final nameController = TextEditingController(text: group.name);
    final formKey = GlobalKey<FormState>();
    final completer = Completer<bool>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              completer.complete(false); // No changes made
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                  final updatedGroup = GroupModel(
                    id: group.id,
                    name: nameController.text.trim(),
                    group_admin: group.group_admin,
                  );
                  
                  await groupProvider.updateGroup(group.id, updatedGroup);
                  
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "${nameController.text}" updated successfully'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                  completer.complete(true); // Group updated successfully
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update group: $e'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                  completer.complete(false); // Failed to update group
                }
              } else {
                completer.complete(false); // Validation failed
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    return completer.future;
  }
  
  // Safely fetch admin name without causing navigation
  Future<String> _fetchAdminName(String adminId) async {
    if (adminId.isEmpty) {
      return "No admin assigned";
    }
    
    try {
      // Create a local instance of UserProvider to avoid state changes
      final userServices = UserServices();
      final adminUser = await userServices.fetchCurrentUser(adminId);
      return adminUser.fullName.isNotEmpty ? adminUser.fullName : "Admin #$adminId";
    } catch (e) {
      print('Error fetching admin name: $e');
      return "Admin #$adminId";
    }
  }
  
  // Safely fetch group statistics without causing navigation
  Future<Map<String, dynamic>> _fetchGroupStats(String groupId) async {
    Map<String, dynamic> stats = {
      'memberCount': 0,
      'eventCount': 0,
    };
    
    try {
      // Fetch member count
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final members = await groupProvider.getGroupMembers(groupId);
      stats['memberCount'] = members.length;
      
      // Fetch event count using EventProvider
      try {
        final eventProvider = Provider.of<EventProvider>(context, listen: false);
        final events = await eventProvider.getGroupEvents(groupId);
        stats['eventCount'] = events.length;
      } catch (e) {
        print('Error fetching events: $e');
        stats['eventCount'] = 0;
      }
    } catch (e) {
      print('Error fetching group stats: $e');
    }
    
    return stats;
  }

  Future<bool> _showDeleteGroupDialog(BuildContext context, GroupModel group) async {
    final completer = Completer<bool>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              completer.complete(false); // No changes made
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                await groupProvider.deleteGroup(group.id);
                
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Group "${group.name}" deleted successfully'),
                    backgroundColor: AppColors.successColor,
                  ),
                );
                completer.complete(true); // Group deleted successfully
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete group: $e'),
                    backgroundColor: AppColors.errorColor,
                  ),
                );
                completer.complete(false); // Failed to delete group
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    return completer.future;
  }
}