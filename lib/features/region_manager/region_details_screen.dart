import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/regional_manager_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';

class RegionDetailsScreen extends StatefulWidget {
  final String regionId;

  const RegionDetailsScreen({
    super.key,
    required this.regionId,
  });

  @override
  State<RegionDetailsScreen> createState() => _RegionDetailsScreenState();
}

class _RegionDetailsScreenState extends State<RegionDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  RegionModel? _region;
  int _userCount = 0;
  int _groupCount = 0;
  int _eventCount = 0;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _loadRegionDetails();
  }

  Future<void> _loadRegionDetails() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get region details first
      final regionProvider = Provider.of<RegionProvider>(context, listen: false);
      final region = await regionProvider.getRegionById(widget.regionId);
      
      if (region == null) {
        throw Exception('Region not found');
      }

      if (!mounted) return;
      setState(() {
        _region = region;
      });

      // Load other data in parallel
      await Future.wait([
        _loadUsers(),
        _loadGroups(),
        _loadEvents(),
        _loadActivityStatus(),
      ]);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load region details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final users = await userProvider.getUsersByRegion(widget.regionId);
      if (mounted) {
        setState(() {
          _userCount = users.length;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  Future<void> _loadGroups() async {
    try {
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      final groups = await groupProvider.getGroupsByRegion(widget.regionId);
      if (mounted) {
        setState(() {
          _groupCount = groups.length;
        });
      }
    } catch (e) {
      print('Error loading groups: $e');
    }
  }

  Future<void> _loadEvents() async {
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final events = await eventProvider.getEventsByRegion(widget.regionId);
      if (mounted) {
        setState(() {
          _eventCount = events.length;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  Future<void> _loadActivityStatus() async {
    try {
      final regionmanagerProvider = Provider.of<RegionalManagerAnalyticsProvider>(context, listen: false);
      final activityStatus = await regionmanagerProvider.getActivityStatus(widget.regionId);
      
      if (activityStatus == null) {
        throw Exception('Activity status is null');
      }
      
      // Calculate if region is active based on member activity
      final activeMembers = activityStatus.statusSummary.active ?? 0;
      final inactiveMembers = activityStatus.statusSummary.inactive ?? 0;
      
      if (mounted) {
        setState(() {
          // If both active and inactive are zero, consider the region inactive
          if (activeMembers == 0 && inactiveMembers == 0) {
            _isActive = false;
          } else {
            _isActive = activeMembers > inactiveMembers;
          }
        });
      }
    } catch (e) {
      print('Error loading activity status: $e');
      // Default to false if we can't get the status
      if (mounted) {
        setState(() {
          _isActive = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Region Details',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _region == null
                  ? _buildEmptyView()
                  : _buildRegionDetails(),
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
              'Error Loading Region',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRegionDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Text('No region details found'),
    );
  }

  Widget _buildRegionDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region Header
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryColor, AppColors.secondaryColor],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _region!.name,
                              style: TextStyles.heading1.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_region!.description != null)
                              Text(
                                _region!.description!,
                                style: TextStyles.bodyText.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isActive ? Icons.check_circle : Icons.cancel,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isActive ? 'Active' : 'Inactive',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Users',
                _userCount.toString(),
                Icons.people,
                AppColors.primaryColor,
              ),
              _buildStatCard(
                'Groups',
                _groupCount.toString(),
                Icons.groups,
                AppColors.secondaryColor,
              ),
              _buildStatCard(
                'Events',
                _eventCount.toString(),
                Icons.event,
                AppColors.accentColor,
              ),
              _buildStatCard(
                'Status',
                _isActive ? 'Active' : 'Inactive',
                _isActive ? Icons.check_circle : Icons.cancel,
                _isActive ? Colors.green : Colors.red,
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyles.heading1.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyles.bodyText.copyWith(
                color: AppColors.textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 