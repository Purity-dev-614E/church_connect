import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/removed_member_model.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/services/member_removal_service.dart';
import 'package:group_management_church_app/data/services/group_services.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';

class RegionRemovedMembersList extends StatefulWidget {
  final String regionId;
  final String userRole;
  final bool showRestoreButton;
  final bool showStats;

  const RegionRemovedMembersList({
    super.key,
    required this.regionId,
    required this.userRole,
    this.showRestoreButton = true,
    this.showStats = true,
  });

  @override
  State<RegionRemovedMembersList> createState() =>
      _RegionRemovedMembersListState();
}

class _RegionRemovedMembersListState extends State<RegionRemovedMembersList> {
  final MemberRemovalService _removalService = MemberRemovalService();
  final GroupServices _groupServices = GroupServices();
  List<RemovedMemberModel> _removedMembers = [];
  List<Map<String, dynamic>> _groupStats = [];
  bool _isLoading = false;
  bool _isLoadingGroups = false;
  String? _error;
  String? _searchQuery;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchRemovedMembers();
    // if (widget.showStats) {
    //   _fetchGroupStats();
    // } // Commented out since stats section is disabled
  }

  Future<void> _fetchRemovedMembers({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _removedMembers.clear();
      }
    });

    try {
      // Use the efficient region-wide endpoint instead of individual group calls
      final allRemovedMembers = await _removalService.getRegionRemovedMembers(
        widget.regionId,
        search: _searchQuery, // Pass search parameter
      );

      // Debug logging
      print(
        'Loaded ${allRemovedMembers.length} removed members from region-wide API',
      );
      if (allRemovedMembers.isNotEmpty) {
        final firstMember = allRemovedMembers.first;
        print('First member data:');
        print('  ID: ${firstMember.id}');
        print('  User ID: ${firstMember.userId}');
        print('  User Name: "${firstMember.userName}"');
        print('  User Email: "${firstMember.userEmail}"');
        print('  Group ID: "${firstMember.groupId}"');
        print('  Group Name: "${firstMember.groupName}"');
        print('  Removed By: "${firstMember.removedByName}"');
        print('  Removed At: ${firstMember.removedAt}');
        print('  Reason: "${firstMember.reason}"');
        print('  Is Restored: ${firstMember.isRestored}');
      } else {
        print('No removed members found');
      }

      // Sort by removal date (most recent first)
      allRemovedMembers.sort((a, b) => b.removedAt.compareTo(a.removedAt));

      setState(() {
        _removedMembers = allRemovedMembers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGroupStats() async {
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final groups = await groupProvider.getGroupsByRegion(widget.regionId);

      // Use Future.wait to make parallel API calls instead of sequential
      final futures =
          groups.map((group) async {
            try {
              final groupStats = await _removalService.getGroupRemovalStats(
                group.id,
              );
              return {
                'groupName': group.name,
                'groupId': group.id,
                'stats': groupStats,
              };
            } catch (e) {
              print('Error fetching stats for group ${group.name}: $e');
              return null;
            }
          }).toList();

      final results = await Future.wait(futures);

      // Filter out null results and convert to list
      final stats =
          results
              .where((result) => result != null)
              .cast<Map<String, dynamic>>()
              .toList();

      setState(() {
        _groupStats = stats;
        _isLoadingGroups = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGroups = false;
      });
    }
  }

  Future<void> _addMemberToGroup(String userId, String userName) async {
    final selectedGroup = await _showGroupSelectionDialog(userName);
    if (selectedGroup == null) return;

    try {
      final success = await _groupServices.addMemberToGroup(
        selectedGroup.id,
        userId,
      );

      if (success) {
        CustomNotification.show(
          context: context,
          message: '$userName added to ${selectedGroup.name} successfully',
          type: NotificationType.success,
        );
        _fetchRemovedMembers(refresh: true);
        _fetchGroupStats();
      }
    } catch (e) {
      CustomNotification.show(
        context: context,
        message: 'Failed to add member to group: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<GroupModel?> _showGroupSelectionDialog(String userName) async {
    List<GroupModel> allGroups = [];
    List<GroupModel> filteredGroups = [];
    bool isLoading = true;
    String searchQuery = '';

    return await showDialog<GroupModel>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              // Load groups on first build
              if (isLoading && allGroups.isEmpty) {
                _loadGroups().then((groups) {
                  setState(() {
                    allGroups = groups;
                    filteredGroups = groups;
                    isLoading = false;
                  });
                });
              }

              return AlertDialog(
                title: Text('Add $userName to Group'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search groups...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          prefixIconColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                            filteredGroups =
                                allGroups
                                    .where(
                                      (group) => group.name
                                          .toLowerCase()
                                          .contains(searchQuery),
                                    )
                                    .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Groups list
                      Expanded(
                        child:
                            isLoading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : filteredGroups.isEmpty
                                ? Center(
                                  child: Text(
                                    searchQuery.isEmpty
                                        ? 'No groups available'
                                        : 'No groups found',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: filteredGroups.length,
                                  itemBuilder: (context, index) {
                                    final group = filteredGroups[index];
                                    return ListTile(
                                      title: Text(group.name),
                                      subtitle:
                                          group.description.isNotEmpty
                                              ? Text(group.description)
                                              : null,
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.primaryColor,
                                        child: Text(
                                          group.name.isNotEmpty
                                              ? group.name[0].toUpperCase()
                                              : 'G',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      onTap:
                                          () => Navigator.pop(context, group),
                                    );
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
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<List<GroupModel>> _loadGroups() async {
    try {
      // For regional managers, only show groups from their region
      if (widget.userRole == 'regional_manager') {
        return await _groupServices.getGroupsByRegion(widget.regionId);
      }
      // For other roles (super admin), show all groups
      return await _groupServices.fetchAllGroups();
    } catch (e) {
      print('Error loading groups: $e');
      return [];
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query.isEmpty ? null : query;
    _fetchRemovedMembers(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Removed Members'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchRemovedMembers(refresh: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildSearchSection(), _buildMembersList()],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search removed members...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 6),
          ),
          prefixIconColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 6),
        ),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildMembersList() {
    if (_isLoading && _removedMembers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
              const SizedBox(height: 16),
              Text('Error loading removed members', style: TextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyles.bodyText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _fetchRemovedMembers(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_removedMembers.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No removed members found',
                style: TextStyles.heading2.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Members removed from groups in this region will appear here',
                style: TextStyles.bodyText.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        minHeight: 300,
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: RefreshIndicator(
        onRefresh: () => _fetchRemovedMembers(refresh: true),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _removedMembers.length,
          itemBuilder: (context, index) {
            final member = _removedMembers[index];
            return _buildMemberItem(member);
          },
        ),
      ),
    );
  }

  Widget _buildMemberItem(RemovedMemberModel member) {
    print(
      'Building member item: ${member.userId}, name: ${member.userName}, email: ${member.userEmail}',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor:
              member.isRestored ? AppColors.successColor : AppColors.errorColor,
          child: Icon(
            member.isRestored ? Icons.restore : Icons.person_off,
            color: Colors.white,
          ),
        ),
        title: Text(
          member.userName.isNotEmpty
              ? member.userName
              : 'User ID: ${member.userId}',
          style: TextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
            decoration: member.isRestored ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member.userEmail.isNotEmpty
                  ? member.userEmail
                  : 'Email not available',
              style: TextStyles.bodyText.copyWith(color: Colors.grey[600]),
            ),
            if (member.groupName != null && member.groupName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Group: ${member.groupName}',
                style: TextStyles.bodyText.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (member.reason != null && member.reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Reason: ${member.reason}',
                style: TextStyles.bodyText.copyWith(
                  color: AppColors.errorColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Removed: ${_formatDate(member.removedAt)}',
              style: TextStyles.bodyText.copyWith(color: Colors.grey[500]),
            ),
            if (member.removedByName.isNotEmpty) ...[
              Text(
                'By: ${member.removedByName}',
                style: TextStyles.bodyText.copyWith(color: Colors.grey[500]),
              ),
            ],
          ],
        ),
        trailing:
            widget.showRestoreButton &&
                    !member.isRestored &&
                    member.groupId != null
                ? ElevatedButton.icon(
                  onPressed:
                      () => _addMemberToGroup(member.userId, member.userName),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add to Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                )
                : member.isRestored
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successColor.withValues(alpha: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Restored',
                    style: TextStyles.bodyText.copyWith(
                      color: AppColors.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now().toLocal();
    final localDate = date.toLocal();
    final difference = now.difference(localDate);

    if (difference.inDays == 0) {
      return 'Today at ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${localDate.day}/${localDate.month}/${localDate.year}';
    }
  }
}
