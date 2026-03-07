import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/removed_member_model.dart';
import 'package:group_management_church_app/data/services/member_removal_service.dart';
import 'package:group_management_church_app/data/services/group_services.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';

class RemovedMembersList extends StatefulWidget {
  final String groupId;
  final String userRole;
  final bool showRestoreButton;
  final bool showStats;

  const RemovedMembersList({
    super.key,
    required this.groupId,
    required this.userRole,
    this.showRestoreButton = true,
    this.showStats = true,
  });

  @override
  State<RemovedMembersList> createState() => _RemovedMembersListState();
}

class _RemovedMembersListState extends State<RemovedMembersList> {
  final MemberRemovalService _removalService = MemberRemovalService();
  final GroupServices _groupServices = GroupServices();
  List<RemovedMemberModel> _removedMembers = [];
  RemovalStats? _removalStats;
  bool _isLoading = false;
  bool _isLoadingStats = false;
  String? _error;
  String? _searchQuery;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchRemovedMembers();
    if (widget.showStats) {
      _fetchRemovalStats();
    }
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
      List<RemovedMemberModel> members;

      // For super admin with empty groupId, use getAllRemovedMembers
      if (widget.userRole == 'super_admin' && widget.groupId.isEmpty) {
        members = await _removalService.getAllRemovedMembers(
          page: _currentPage,
          limit: 20,
          search: _searchQuery,
        );
      } else {
        // For other roles or when groupId is provided, use group-specific endpoint
        members = await _removalService.getGroupRemovedMembers(
          widget.groupId,
          page: _currentPage,
          limit: 20,
          search: _searchQuery,
        );
      }

      setState(() {
        if (refresh) {
          _removedMembers = members;
        } else {
          _removedMembers.addAll(members);
        }
        _isLoading = false;
        _hasMore = members.length == 20;
        if (!refresh) _currentPage++;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRemovalStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      // For super admin with empty groupId, skip fetching stats as it requires a group
      if (widget.userRole == 'super_admin' && widget.groupId.isEmpty) {
        setState(() {
          _isLoadingStats = false;
        });
        return;
      }

      final stats = await _removalService.getGroupRemovalStats(widget.groupId);
      setState(() {
        _removalStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
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
        _fetchRemovalStats();
      }
    } catch (e) {
      CustomNotification.show(
        context: context,
        message: 'Failed to add member to group: $e',
        type: NotificationType.error,
      );
    }
  }

  Future<List<GroupModel>> _loadGroups() async {
    try {
      // For admin users, only show their own group
      if (widget.userRole == 'admin' && widget.groupId.isNotEmpty) {
        final group = await _groupServices.fetchGroupById(widget.groupId);
        return [group];
      }
      // For regional managers, only show groups from their region (if regionId is available)
      if (widget.userRole == 'regional_manager' && widget.groupId.isNotEmpty) {
        return await _groupServices.getGroupsByRegion(widget.groupId);
      }
      // For super admin, show all groups
      return await _groupServices.fetchAllGroups();
    } catch (e) {
      print('Error loading groups: $e');
      return [];
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
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          prefixIconColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
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
          if (widget.userRole == 'admin' || widget.userRole == 'super_admin')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _fetchRemovedMembers(refresh: true),
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.showStats &&
              widget.userRole != 'admin' &&
              widget.userRole != 'super_admin')
            _buildStatsSection(),
          _buildSearchSection(),
          Expanded(child: _buildMembersList()),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_removalStats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Removal Statistics',
            style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Removed',
                  _removalStats!.totalRemoved.toString(),
                  Icons.person_off,
                  AppColors.errorColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active Removals',
                  _removalStats!.activeRemovals.toString(),
                  Icons.remove_circle,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Restored',
                  _removalStats!.restoredMembers.toString(),
                  Icons.restore,
                  AppColors.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'This Month',
                  _removalStats!.removalsByMonth.values
                      .fold(0, (sum, count) => sum + count)
                      .toString(),
                  Icons.calendar_today,
                  AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyles.heading2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyles.bodyText.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIconColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
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
      return Center(
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
      );
    }

    if (_removedMembers.isEmpty) {
      return Center(
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
              'Members removed from this group will appear here',
              style: TextStyles.bodyText.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchRemovedMembers(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _removedMembers.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _removedMembers.length) {
            return _buildLoadMoreItem();
          }

          final member = _removedMembers[index];
          return _buildMemberItem(member);
        },
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
            color: Colors.black.withOpacity(0.05),
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
                    (widget.userRole == 'admin' ||
                        widget.userRole == 'super_admin')
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
                    color: AppColors.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Added',
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

  Widget _buildLoadMoreItem() {
    if (!_hasMore) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _fetchRemovedMembers,
                  child: const Text('Load More'),
                ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
