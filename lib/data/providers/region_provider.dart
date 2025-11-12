import 'package:flutter/material.dart';
import '../models/region_model.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/region_services.dart';
import '../services/user_services.dart';
import '../services/group_services.dart';
import '../services/analytics_services/regional_manager_analytics_service.dart';
import '../services/regional_alias_service.dart';

class RegionProvider extends ChangeNotifier {
  final RegionServices _regionServices = RegionServices();
  final UserServices _userServices = UserServices();
  final GroupServices _groupServices = GroupServices();
  final RegionAnalyticsService _analyticsServices = RegionAnalyticsService(
    baseUrl: 'https://safari-backend-fgl3.onrender.com/api',
  );
  final RegionalAliasService _aliasService = RegionalAliasService();
  
  List<RegionModel> _regions = [];
  List<RegionModel> get regions => _regions;
  
  List<UserModel> _regionUsers = [];
  List<UserModel> get regionUsers => _regionUsers;
  
  List<GroupModel> _regionGroups = [];
  List<GroupModel> get regionGroups => _regionGroups;
  
  Map<String, dynamic> _regionAnalytics = {};
  Map<String, dynamic> get regionAnalytics => _regionAnalytics;
  
  RegionModel? _selectedRegion;
  RegionModel? get selectedRegion => _selectedRegion;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Load all regions
  Future<void> loadRegions() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final regions = await _regionServices.getRegions();
      _regions = regions;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load regions: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get region by ID
  Future<RegionModel?> getRegionById(String regionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final region = await _regionServices.getRegionById(regionId);
      _isLoading = false;
      notifyListeners();
      return region;
    } catch (e) {
      _errorMessage = 'Failed to get region: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Set selected region
  void setSelectedRegion(RegionModel region) {
    _selectedRegion = region;
    notifyListeners();
  }
  
  // Set selected region by ID
  Future<void> setSelectedRegionById(String regionId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final region = await _regionServices.getRegionById(regionId);
      if (region != null) {
        _selectedRegion = region;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to set selected region: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Clear selected region
  void clearSelectedRegion() {
    _selectedRegion = null;
    notifyListeners();
  }
  
  // Create a new region (for super admin)
  Future<bool> createRegion(String name, String? description) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final success = await _regionServices.createRegion(name, description);
      
      if (success) {
        // Reload regions to get the new one
        await loadRegions();
      } else {
        _errorMessage = 'Failed to create region';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error creating region: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update a region (for super admin)
  Future<bool> updateRegion(String regionId, String name, String? description) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final success = await _regionServices.updateRegion(regionId, name, description);
      
      if (success) {
        // Reload regions to get the updated one
        await loadRegions();
        
        // Update selected region if it's the one that was updated
        if (_selectedRegion != null && _selectedRegion!.id == regionId) {
          final updatedRegion = await _regionServices.getRegionById(regionId);
          if (updatedRegion != null) {
            _selectedRegion = updatedRegion;
          }
        }
      } else {
        _errorMessage = 'Failed to update region';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error updating region: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete a region (for super admin)
  Future<bool> deleteRegion(String regionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final success = await _regionServices.deleteRegion(regionId);
      
      if (success) {
        // Reload regions
        await loadRegions();
        
        // Clear selected region if it's the one that was deleted
        if (_selectedRegion != null && _selectedRegion!.id == regionId) {
          _selectedRegion = null;
        }
      } else {
        _errorMessage = 'Failed to delete region';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error deleting region: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Get users by region
  Future<List<UserModel>> getUsersByRegion(String regionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final users = await _userServices.getUsersByRegion(regionId);
      final aliasMap = await _aliasService.getAllAliases();
      final mergedUsers = aliasMap.isEmpty
          ? users
          : users
              .map((user) => aliasMap.containsKey(user.id)
                  ? user.copyWith(regionalTitle: aliasMap[user.id])
                  : user)
              .toList();
      _regionUsers = mergedUsers;
      _isLoading = false;
      notifyListeners();
      return mergedUsers;
    } catch (e) {
      _errorMessage = 'Failed to load region users: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
  
  // Get groups by region
  Future<List<GroupModel>> getGroupsByRegion(String regionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final groups = await _groupServices.getGroupsByRegion(regionId);
      _regionGroups = groups;
      _isLoading = false;
      notifyListeners();
      return groups;
    } catch (e) {
      _errorMessage = 'Failed to load region groups: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }
  
  // Get region analytics
  Future<Map<String, dynamic>> getRegionAnalytics(String regionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Get dashboard summary
      final summary = await _analyticsServices.getDashboardSummaryForRegion(regionId);
      
      // Get attendance trends
      final attendanceTrends = await _analyticsServices.getRegionAttendanceStats(regionId);
      
      // Get growth trends
      final growthTrends = await _analyticsServices.getRegionGrowthAnalytics(regionId);
      
      // Get engagement metrics
      final engagement = await _analyticsServices.getMemberActivityStatusForRegion(regionId);
      
      // Combine all analytics data
      _regionAnalytics = {
        'summary': summary,
        'attendance_trends': attendanceTrends,
        'growth_trends': growthTrends,
        'engagement': engagement,
      };
      
      _isLoading = false;
      notifyListeners();
      return _regionAnalytics;
    } catch (e) {
      _errorMessage = 'Failed to load region analytics: $e';
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }
  
  // Export region report
  Future<Map<String, dynamic>> exportRegionReport(String regionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      // Get all analytics data
      final summary = await _analyticsServices.getDashboardSummaryForRegion(regionId);
      final attendanceStats = await _analyticsServices.getRegionAttendanceStats(regionId);
      final growthAnalytics = await _analyticsServices.getRegionGrowthAnalytics(regionId);
      final demographics = await _analyticsServices.getRegionDemographics(regionId);
      
      // Combine into a report
      final report = {
        'summary': summary,
        'attendance_stats': attendanceStats,
        'growth_analytics': growthAnalytics,
        'demographics': demographics,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _isLoading = false;
      notifyListeners();
      return report;
    } catch (e) {
      _errorMessage = 'Failed to export region report: $e';
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Failed to export region report: $e',
        'download_url': null
      };
    }
  }
  
  // Assign user to region
  Future<bool> assignUserToRegion(String userId, String regionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final success = await _userServices.assignUserToRegion(userId, regionId);
      
      if (success) {
        // Reload region users to get the updated list
        await getUsersByRegion(regionId);
      } else {
        _errorMessage = 'Failed to assign user to region';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error assigning user to region: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Remove user from region
  Future<bool> removeUserFromRegion(String userId, String regionId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final success = await _userServices.removeUserFromRegion(userId, regionId);
      
      if (success) {
        // Reload region users to get the updated list
        await getUsersByRegion(regionId);
      } else {
        _errorMessage = 'Failed to remove user from region';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error removing user from region: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}