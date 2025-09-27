import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';

import '../admin/Admin_dashboard.dart';
import '../region_manager/group_details_screen.dart';


class GroupAdministrationTab extends StatefulWidget {
  const GroupAdministrationTab({super.key});

  @override
  State<GroupAdministrationTab> createState() => _GroupAdministrationTabState();
}

class _GroupAdministrationTabState extends State<GroupAdministrationTab> {
  bool _isLoading = false;
  String? _errorMessage;
  List<GroupModel> _groups = [];
  List<GroupModel> _filteredGroups = [];
  String _searchQuery = '';
  String _selectedFilter = 'All Groups';
  final List<String> _filterOptions = ['All Groups', 'Active', 'Inactive'];
  final ScrollController _scrollController = ScrollController();
  bool _isHeaderVisible = true;
  
  @override
  void initState() {
    super.initState();
    _filteredGroups = _groups;
    _loadGroups();

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isHeaderVisible) {
          setState(() {
            _isHeaderVisible = true;
          });
        }
      }
    });
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
          _filteredGroups = _groups;
          _errorMessage = null;
          _isLoading = false;
        });
        _filterGroups();
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

  void _filterGroups() {
    setState(() {
      _filteredGroups = _groups.where((group) {
        final matchesSearch = group.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesFilter = _selectedFilter == 'All Groups' ||
                             (_selectedFilter == 'Active' && true) || // Assuming all groups are active for now
                             (_selectedFilter == 'Inactive' && false);
        return matchesSearch && matchesFilter;
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

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Title + subtitle (scroll away)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Group Management',
                    style: TextStyles.heading1.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),),
                  const SizedBox(height: 16),
                  Text('Manage all church groups from this dashboard.',
                    style: TextStyles.heading2.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),

                ],
              ),
            ),
          ),

          // Search + filter (pinned)
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchFilterHeader(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                        _filterGroups();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Search Groups',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                        });
                        _filterGroups();
                      },
                      items: _filterOptions
                          .map((filter) => DropdownMenuItem(
                        value: filter,
                        child: Text(filter),
                      ))
                          .toList(),
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Groups list
          _isLoading
              ? const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
              : _errorMessage != null
              ? SliverFillRemaining(child: _buildErrorView())
              : _filteredGroups.isEmpty
              ? SliverFillRemaining(child: _buildEmptyView())
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                  _buildGroupListItem(_filteredGroups[index]),
              childCount: _filteredGroups.length,
            ),
          ),
        ],
      ),

      // Floating Add Button (just plus)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await _showCreateGroupDialog(context);
          if (created) {
            await _loadGroups();
          }
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
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

          SizedBox(
            width: double.infinity,
            child: FloatingActionButton(
              onPressed: () async {
                final created = await _showCreateGroupDialog(context);
                if (created) {
                  await _loadGroups();
                }
              },
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add),
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
       itemCount: _filteredGroups.length,
       itemBuilder: (context, index) {
         if (_filteredGroups.isEmpty) {
           return const Center(child: Text('No groups available'));
         }
         final group = _filteredGroups[index];
         return _buildGroupListItem(group);
       },
     )
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
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
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
    );
  }
  
  Widget _buildGroupStat(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<bool> _showCreateGroupDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
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
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter group description',
                ),
                maxLines: 2,
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
                  // Show loading indicator
                  setState(() {
                    _isLoading = true;
                  });
                  
                  final groupProvider = Provider.of<GroupProvider>(context, listen: false);
                  final name = nameController.text.trim();
                  final description = descriptionController.text.trim();
                  final adminId = ''; // Default empty admin ID
                  final regionId = ''; // Default empty region ID
                  
                  print('Creating group with name: $name, description: $description');
                  
                  final success = await groupProvider.createGroup(name, description, adminId, regionId);
                  
                  setState(() {
                    _isLoading = false;
                  });
                  
                  if (success) {
                    Navigator.pop(dialogContext);
                    _showSuccess('Group "$name" created successfully');
                    await _loadGroups(); // Reload groups after successful creation
                    completer.complete(true); // Group created successfully
                  } else {
                    _showError('Failed to create group. Please try again.');
                    completer.complete(false); // Failed to create group
                  }
                } catch (e) {
                  setState(() {
                    _isLoading = false;
                  });
                  _showError('Failed to create group: $e');
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
                    region_id: group.region_id,
                  );
                  
                  await groupProvider.updateGroup(updatedGroup);
                  
                  Navigator.pop(dialogContext);
                  _showSuccess('Group "${nameController.text}" updated successfully');
                  completer.complete(true); // Group updated successfully
                } catch (e) {
                  _showError('Failed to update group: $e');
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
      final userServices = UserServices();
      final adminUser = await userServices.fetchCurrentUser(adminId);
      final fullName = adminUser.fullName.isNotEmpty ? adminUser.fullName : "Admin #$adminId";
      final phoneNumber = adminUser.contact.isNotEmpty ? adminUser.contact : "N/A";
      return "$fullName : (+$phoneNumber)";
    } catch (e) {
      print('Error fetching admin name: $e');
      return "Admin #$adminId (N/A)";
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
                _showSuccess('Group "${group.name}" deleted successfully');
                completer.complete(true); // Group deleted successfully
              } catch (e) {
                _showError('Failed to delete group: $e');
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
class _SearchFilterHeader extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchFilterHeader({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  double get _height {
    // adjust if you change paddings
    return 16 + 56 + 16 + 48 + 16;
    // top padding + TextField + spacing + Dropdown + bottom padding
  }

  @override
  bool shouldRebuild(covariant _SearchFilterHeader oldDelegate) {
    return oldDelegate.child != child;
  }
}
