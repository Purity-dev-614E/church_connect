import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/features/region_manager/region_dashboard.dart';
import 'package:group_management_church_app/features/region_manager/region_details_screen.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';

class RegionManagerScreen extends StatefulWidget {
  const RegionManagerScreen({super.key});

  @override
  State<RegionManagerScreen> createState() => _RegionManagerScreenState();
}

class _RegionManagerScreenState extends State<RegionManagerScreen> {
  bool _isLoading = true;
  List<RegionModel> _managedRegions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadManagedRegions();
  }

  Future<void> _loadManagedRegions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the regions managed by this user
      final regionProvider = Provider.of<RegionProvider>(context, listen: false);
      await regionProvider.loadRegions();
      
      // Get the list of regions
      final allRegions = regionProvider.regions;
      
      setState(() {
        _managedRegions = allRegions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load regions: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToRegionDashboard(RegionModel region) {
    // Just navigate to the details screen with the region ID
    // The details screen will handle loading the specific region data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegionDetailsScreen(regionId: region.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Region Management',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _managedRegions.isEmpty
                  ? _buildEmptyView()
                  : _buildRegionList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Regions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Retry',
              onPressed: _loadManagedRegions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_city,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No Regions Assigned',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'You are not currently assigned as a manager to any regions.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Refresh',
              onPressed: _loadManagedRegions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Managed Regions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _managedRegions.length,
              itemBuilder: (context, index) {
                final region = _managedRegions[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      region.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (region.description != null && region.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(region.description!),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _navigateToRegionDashboard(region),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}