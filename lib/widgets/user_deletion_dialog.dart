import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/user_deletion_service.dart';
import '../core/utils/role_utils.dart';

class UserDeletionDialog extends StatefulWidget {
  final UserModel user;
  final String currentUserRole;
  final VoidCallback? onDeletionComplete;

  const UserDeletionDialog({
    super.key,
    required this.user,
    required this.currentUserRole,
    this.onDeletionComplete,
  }) : super();

  @override
  State<UserDeletionDialog> createState() => _UserDeletionDialogState();
}

class _UserDeletionDialogState extends State<UserDeletionDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final userCanonicalRole = RoleUtils.mapToDbRole(widget.user.role);
    final isSuperAdminOrRoot =
        widget.currentUserRole == 'super_admin' ||
        widget.currentUserRole == 'root';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red),
          const SizedBox(width: 8),
          const Text('Delete User'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${widget.user.fullName}?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email: ${widget.user.email}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Phone: +${widget.user.contact}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Role: ${_getRoleDisplay(userCanonicalRole)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will permanently delete the user from the system.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Removes user from database AND authentication',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        if (isSuperAdminOrRoot)
          ElevatedButton(
            onPressed: _isDeleting ? null : () => _deleteUser(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child:
                _isDeleting
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    )
                    : const Text('Delete User'),
          ),
      ],
    );
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'root':
        return 'Root';
      case 'admin':
        return 'Group Leader';
      case 'regional manager':
        return 'Regional Manager';
      case 'user':
        return 'Member';
      default:
        return role
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  Future<void> _deleteUser(BuildContext context, bool completeDelete) async {
    if (!mounted) return;

    setState(() {
      _isDeleting = true;
    });

    final deletionService = UserDeletionService();

    try {
      if (completeDelete) {
        final result = await deletionService.deleteUserCompletely(
          widget.user.id,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'User completely deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await deletionService.deleteUser(widget.user.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted from backend'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      widget.onDeletionComplete?.call();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
