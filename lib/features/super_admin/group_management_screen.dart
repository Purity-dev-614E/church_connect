import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:provider/provider.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({Key? key}) : super(key: key);

  @override
  State<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Management'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: FutureBuilder<List<GroupModel>>(
        future: Provider.of<GroupProvider>(context, listen: false).fetchGroups().then((_) => 
          Provider.of<GroupProvider>(context, listen: false).groups),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
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
                    snapshot.error.toString(),
                    style: TextStyles.bodyText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {}); // Refresh the FutureBuilder
                    },
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
          
          final groups = snapshot.data ?? <GroupModel>[];
              
          // State for search and filtering
          final searchController = TextEditingController();
          final filteredGroups = ValueNotifier<List<GroupModel>>(groups);
          final selectedStatus = ValueNotifier<String>('All');
          
          void filterGroups() {
            final query = searchController.text.toLowerCase();
            final status = selectedStatus.value;
            
            filteredGroups.value = groups.where((group) {
              // Filter by search query
              final matchesQuery = query.isEmpty || 
                  group.name.toLowerCase().contains(query) ||
                  group.id.toLowerCase().contains(query);
                  
              // For now, we don't have a status field in GroupModel
              // This would need to be implemented if groups have a status
              final matchesStatus = status == 'All';
                  
              return matchesQuery && matchesStatus;
            }).toList();
          }
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search groups...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          filterGroups();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Show dialog to create a new group
                        _showCreateGroupDialog(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Group'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'All Groups (${groups.length})',
                      style: TextStyles.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<String>(
                      valueListenable: selectedStatus,
                      builder: (context, value, child) {
                        return DropdownButton<String>(
                          value: value,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(value: 'Active', child: Text('Active')),
                            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                          ],
                          onChanged: (newValue) {
                            if (newValue != null) {
                              selectedStatus.value = newValue;
                              filterGroups();
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<List<GroupModel>>(
                  valueListenable: filteredGroups,
                  builder: (context, filteredList, child) {
                    if (filteredList.isEmpty) {
                      return const Center(
                        child: Text('No groups found matching the criteria'),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<List<dynamic>>(
                          future: Provider.of<GroupProvider>(context, listen: false)
                              .getGroupMembers(filteredList[index].id),
                          builder: (context, memberSnapshot) {
                            final memberCount = memberSnapshot.data?.length ?? 0;
                            return _buildGroupListItemDetailed(filteredList[index], memberCount);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupListItemDetailed(GroupModel group, int memberCount) {
    // We'll assume all groups are active for now
    final isActive = true;

    return Card(
      elevation: 2,
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
                      FutureBuilder<UserModel?>(
                        future: group.group_admin.isNotEmpty 
                            ? Provider.of<UserProvider>(context, listen: false).loadUser(group.group_admin).then((_) => 
                                Provider.of<UserProvider>(context, listen: false).currentUser)
                            : Future.value(null),
                        builder: (context, snapshot) {
                          final adminName = snapshot.data?.fullName ?? 'No admin assigned';
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
                    color: isActive ? AppColors.successColor : AppColors.errorColor,
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGroupStat('Members', memberCount.toString(), Icons.people),
                // For now, use placeholders for events and attendance
                _buildGroupStat('Events', '0', Icons.event),
                _buildGroupStat('Attendance', '0%', Icons.trending_up),
              ],
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
                    _showEditGroupDialog(context, group);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryColor.withOpacity(0.7),
          size: 20,
        ),
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
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
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
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Group "${nameController.text}" created successfully'),
                        backgroundColor: AppColors.successColor,
                      ),
                    );
                    setState(() {}); // Refresh the group list
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create group: $e'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(BuildContext context, GroupModel group) {
    final nameController = TextEditingController(text: group.name);
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
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
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Group "${nameController.text}" updated successfully'),
                        backgroundColor: AppColors.successColor,
                      ),
                    );
                    setState(() {}); // Refresh the group list
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update group: $e'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}