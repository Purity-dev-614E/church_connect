import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';
import 'package:group_management_church_app/features/region_manager/region_details_screen.dart';
import 'package:group_management_church_app/features/region_manager/region_dashboard.dart';

import '../../data/models/user_model.dart';

class RegionManagementTab extends StatefulWidget {
  const RegionManagementTab({super.key});

  @override
  State<RegionManagementTab> createState() => _RegionManagementTabState();
}

class _RegionManagementTabState extends State<RegionManagementTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<RegionModel> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final regionProvider = Provider.of<RegionProvider>(context, listen: false);
      await regionProvider.loadRegions();

      setState(() {
        _regions = regionProvider.regions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load regions: ${e.toString()}';
        _isLoading = false;
      });
      CustomNotification.show(
        context: context,
        message: _errorMessage!,
        type: NotificationType.error,
      );
    }
  }
  Future<String?> getRegionHeadName(String regionId) async {
    try {
      // Fetch all users in the region
      final users = await RegionProvider().getUsersByRegion(regionId);

      // Find the user with the role of "region manager"
      final regionHead = users.firstWhere(
        (user) => user.role == 'region manager',
         orElse: () => users.first,
      );

      // Return the name of the region head, or null if not found
      return '${regionHead.fullName}\nPhone Number: +${regionHead.contact}';
    } catch (e) {
      // Handle any errors
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Region Management',
                          style: TextStyles.heading1,
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _regions.isEmpty
                              ? Center(
                                  child: Text(
                                    'No regions found',
                                    style: TextStyles.heading2,
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _regions.length,
                                  itemBuilder: (context, index) {
                                    final region = _regions[index];
                                return SizedBox(
                                  height: 100, // Adjust the height as needed
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      title: Text(
                                        region.name,
                                        style: TextStyles.bodyText.copyWith(fontWeight: FontWeight.bold,color: Colors.red),
                                      ),
                                      subtitle:
                                      FutureBuilder<String?>(
                                        future: getRegionHeadName(region.id),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return Text(
                                              'Region Focal Person: Loading...',
                                              style: TextStyles.buttonText,
                                            );
                                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                            return Text(
                                              'Region Focal Person: Not Assigned',
                                              style: TextStyles.buttonText,
                                            );
                                          } else {
                                            return Text(
                                              'Region Focal Person: ${snapshot.data}',
                                              style: TextStyles.bodyText,
                                            );
                                          }
                                        },
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        color: AppColors.primaryColor,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => RegionDashboard(
                                              regionId: region.id,
                                              actingAsSuperAdmin: true,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        final regionProvider = Provider.of<RegionProvider>(context, listen: false);

        TextEditingController nameController = TextEditingController();
        TextEditingController descriptionController = TextEditingController();

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Create New Region'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Region Name'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final success = await regionProvider.createRegion(
                      nameController.text,
                      descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                    );

                    Navigator.of(context).pop();

                    if (success) {
                      CustomNotification.show(
                        context: context,
                        message: 'Region created successfully',
                        type: NotificationType.success,
                      );
                    } else {
                      CustomNotification.show(
                        context: context,
                        message: regionProvider.errorMessage ?? 'Failed to create region',
                        type: NotificationType.error,
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
      tooltip: 'Create new region',
      child: const Icon(Icons.add),
    ),
    );
  }
}
