import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/services/group_creation_service.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';

class CreateGroupDialog extends StatefulWidget {
  final String userRole;
  final String? userRegionId;
  final GroupCreationService groupService;
  final VoidCallback? onGroupCreated;

  const CreateGroupDialog({
    Key? key,
    required this.userRole,
    this.userRegionId,
    required this.groupService,
    this.onGroupCreated,
  }) : super(key: key);

  @override
  _CreateGroupDialogState createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedRegionId;
  List<RegionModel> _regions = [];
  bool _isLoading = false;
  bool _isLoadingRegions = false;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    if (!_needsRegionSelection) return;

    setState(() => _isLoadingRegions = true);

    try {
      final regions = await widget.groupService.getAllRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
          _isLoadingRegions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRegions = false);
        _showError('Failed to load regions: $e');
      }
    }
  }

  bool get _needsRegionSelection =>
      ['super admin', 'root'].contains(widget.userRole.toLowerCase());

  bool get _isRegionalManager =>
      widget.userRole.toLowerCase() == 'regional manager';

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

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate region selection for super admin/root
    if (_needsRegionSelection &&
        (_selectedRegionId == null || _selectedRegionId!.isEmpty)) {
      _showError('Please select a region');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final group = await widget.groupService.createGroup(
        name: _nameController.text.trim(),
        regionId: _selectedRegionId,
      );

      _showSuccess('Group "${group['name']}" created successfully');

      // Call the callback if provided
      widget.onGroupCreated?.call();

      // Close the dialog
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.groups, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          const Text('Create Group'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a new group in the system',
                style: TextStyles.bodyText.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Group Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter group name',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Group name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Group name must be at least 2 characters';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              // Region Selection (for Super Admin & Root)
              if (_needsRegionSelection) ...[
                const SizedBox(height: 8),
                Text(
                  'Select Region',
                  style: TextStyles.bodyText.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _isLoadingRegions
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                    : DropdownButtonFormField<String>(
                      value: _selectedRegionId,
                      decoration: InputDecoration(
                        labelText: 'Region',
                        hintText: 'Choose a region',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),
                      ),
                      items:
                          _regions
                              .map(
                                (region) => DropdownMenuItem(
                                  value: region.id,
                                  child: Text(region.name),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() => _selectedRegionId = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a region';
                        }
                        return null;
                      },
                    ),
              ] else if (_isRegionalManager) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Region: Auto-assigned to your assigned region',
                          style: TextStyles.bodyText.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // User Role Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Creating as: ${widget.userRole}',
                        style: TextStyles.bodyText.copyWith(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text('Create Group'),
        ),
      ],
    );
  }
}
