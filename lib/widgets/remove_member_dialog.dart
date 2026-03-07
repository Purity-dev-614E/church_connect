import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/services/member_removal_service.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';

class RemoveMemberDialog extends StatefulWidget {
  final String groupId;
  final String memberName;
  final String memberId;
  final String userRole;
  final VoidCallback? onRemoved;

  const RemoveMemberDialog({
    super.key,
    required this.groupId,
    required this.memberName,
    required this.memberId,
    required this.userRole,
    this.onRemoved,
  });

  @override
  State<RemoveMemberDialog> createState() => _RemoveMemberDialogState();
}

class _RemoveMemberDialogState extends State<RemoveMemberDialog> {
  final _reasonController = TextEditingController();
  bool _isRemoving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _removeMember() async {
    if (_isRemoving) return;

    setState(() {
      _isRemoving = true;
    });

    try {
      final success = await MemberRemovalService().removeMemberFromGroup(
        widget.groupId,
        widget.memberId,
        reason: _reasonController.text.trim(),
      );

      if (success) {
        CustomNotification.show(
          context: context,
          message: '${widget.memberName} removed successfully',
          type: NotificationType.success,
        );
        widget.onRemoved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      CustomNotification.show(
        context: context,
        message: 'Failed to remove member: $e',
        type: NotificationType.error,
      );
    } finally {
      setState(() {
        _isRemoving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_off, color: AppColors.errorColor),
          const SizedBox(width: 12),
          const Text('Remove Member'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to remove ${widget.memberName} from the group?',
            style: TextStyles.bodyText,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: 'Reason for removal (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppColors.backgroundColor,
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 8),
          Text(
            'This action can be reversed by an admin.',
            style: TextStyles.bodyText.copyWith(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isRemoving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isRemoving ? null : _removeMember,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorColor,
            foregroundColor: Colors.white,
          ),
          child: _isRemoving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Remove'),
        ),
      ],
    );
  }
}
