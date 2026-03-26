import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';

class ChangeUserGroupDialog extends StatefulWidget {
  final UserModel user;
  final String? currentRegionId; // For regional managers to filter groups

  const ChangeUserGroupDialog({
    super.key,
    required this.user,
    this.currentRegionId,
  });

  @override
  State<ChangeUserGroupDialog> createState() => _ChangeUserGroupDialogState();
}

class _ChangeUserGroupDialogState extends State<ChangeUserGroupDialog> {
  bool _isLoading = false;
  List<GroupModel> _availableGroups = [];
  GroupModel? _selectedGroup;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableGroups();
  }

  Future<void> _loadAvailableGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      List<GroupModel> groups;

      if (widget.currentRegionId != null) {
        // Regional Manager: Load groups only from their region
        groups = await groupProvider.getGroupsByRegion(widget.currentRegionId!);
      } else {
        // Super Admin: Load all groups
        await groupProvider.fetchGroups();
        groups = groupProvider.groups;
      }

      if (mounted) {
        setState(() {
          _availableGroups = groups;
          // Pre-select the user's current group if they have one
          if (widget.user.regionId != null &&
              widget.user.regionId!.isNotEmpty) {
            try {
              _selectedGroup = groups.firstWhere(
                (group) => group.id == widget.user.regionId,
                orElse:
                    () =>
                        groups.isNotEmpty
                            ? groups.first
                            : GroupModel(
                              id: '',
                              name: 'No groups available',
                              region_id: '',
                            ),
              );
            } catch (e) {
              // If current group not found, select first available
              _selectedGroup = groups.isNotEmpty ? groups.first : null;
            }
          } else {
            _selectedGroup = groups.isNotEmpty ? groups.first : null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load groups: ${e.toString()}';
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

  Future<void> _changeUserGroup() async {
    if (_selectedGroup == null || _selectedGroup!.id.isEmpty) {
      _showError('Please select a valid group');
      return;
    }

    // Show reason dialog first
    final reason = await _showReasonDialog();
    if (reason == null) return; // User cancelled

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);

      // Use the new dedicated method for changing user groups
      final success = await userProvider.changeUserGroup(
        widget.user.id,
        _selectedGroup!.id,
        _selectedGroup!.name,
      );

      if (!success) {
        throw Exception('Failed to change user group');
      }

      // Sequential operations: Remove from current group, then add to new group
      // 1. Remove from current group if they have one
      if (widget.user.regionId != null && widget.user.regionId!.isNotEmpty) {
        try {
          await groupProvider.removeMemberFromGroupWithReason(
            widget.user.regionId!,
            widget.user.id,
            'Moved to ${_selectedGroup!.name}',
          );
        } catch (e) {
          // If the reason method fails, fallback to legacy method
          try {
            await groupProvider.removeMemberFromGroup(
              widget.user.regionId!,
              widget.user.id,
            );
          } catch (fallbackError) {
            // If removal fails, we can still proceed with adding to new group
            print('Error removing from current group: $fallbackError');
          }
        }
      }

      // 2. Add to the new group
      await groupProvider.addMemberToGroup(_selectedGroup!.id, widget.user.id);

      // 3. If user is an admin, assign them as admin to the new group
      if (widget.user.role.toLowerCase() == 'admin') {
        await groupProvider.assignAdminToGroup(
          _selectedGroup!.id,
          widget.user.id,
        );
      }

      _showSuccess(
        '${widget.user.fullName} moved to ${_selectedGroup!.name} successfully',
      );

      if (mounted) {
        Navigator.pop(context, true); // Return success to refresh parent
      }
    } catch (e) {
      _showError('Failed to change user group: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _showReasonDialog() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reason for Group Change'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please provide a reason for changing ${widget.user.fullName}\'s group:',
                    style: TextStyles.bodyText,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for group change *',
                      hintText:
                          'e.g. Reassigned, requested transfer, promotion...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a reason for the group change';
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
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context, reasonController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.groups, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Change Group for ${widget.user.fullName}',
              style: TextStyles.heading2,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current group info
            if (widget.user.regionName != null &&
                widget.user.regionName!.isNotEmpty) ...[
              Text(
                'Current Group:',
                style: TextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.secondaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.user.regionName!,
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // New group selection
            Text(
              'Select New Group:',
              style: TextStyles.bodyText.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.errorColor,
                  ),
                ),
              )
            else if (_availableGroups.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  widget.currentRegionId != null
                      ? 'No groups available in your region. Please create groups first.'
                      : 'No groups available. Please create groups first.',
                  style: TextStyles.bodyText.copyWith(color: Colors.orange),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<GroupModel>(
                    isExpanded: true,
                    value: _selectedGroup,
                    items:
                        _availableGroups.map((group) {
                          return DropdownMenuItem<GroupModel>(
                            value: group,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: TextStyles.bodyText.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (group.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    group.description,
                                    style: TextStyles.bodyText.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGroup = value;
                      });
                    },
                  ),
                ),
              ),

            if (widget.currentRegionId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'As a Regional Manager, you can only assign groups within your region.',
                        style: TextStyles.bodyText.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              (_isLoading || _selectedGroup == null) ? null : _changeUserGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Change Group'),
        ),
      ],
    );
  }
}
