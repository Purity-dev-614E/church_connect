import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/core/utils/role_utils.dart';
import 'package:flutter/material.dart';

class GroupCreationService {
  final String baseUrl;
  final String? authToken;
  final AuthServices _authServices = AuthServices();
  final UserServices _userServices = UserServices();

  GroupCreationService({required this.baseUrl, this.authToken});

  /// Create a group with role-based behavior
  ///
  /// For Super Admin & Root: Must specify regionId
  /// For Regional Manager: Region is auto-assigned (regionId is ignored)
  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? regionId,
    String? groupAdminId,
    BuildContext? context, // For accessing providers if needed
  }) async {
    try {
      // Get current user's role
      final userRole = await _userServices.getUserRole();
      if (userRole == null) {
        throw Exception('User role not found');
      }

      // Validate role permissions
      final normalizedRole = RoleUtils.normalize(userRole);
      if (!_canCreateGroup(normalizedRole)) {
        throw Exception('User does not have permission to create groups');
      }

      // Prepare request body based on role
      final body = <String, dynamic>{
        'name': name,
        if (groupAdminId != null && groupAdminId.isNotEmpty)
          'group_admin_id': groupAdminId,
      };

      // Handle region_id based on user role
      if (RoleUtils.isSuperAdmin(normalizedRole) ||
          RoleUtils.isRoot(normalizedRole)) {
        // Super admin & root must specify region_id
        if (regionId == null || regionId.isEmpty) {
          throw Exception(
            'Region ID is required for Super Admin and Root users',
          );
        }
        body['region_id'] = regionId;
      } else if (RoleUtils.isRegionalLeadership(normalizedRole)) {
        // Regional manager gets auto-assigned region
        final userRegionId = await _getUserRegionId();
        if (userRegionId == null) {
          throw Exception('Regional manager must be assigned to a region');
        }
        body['region_id'] = userRegionId;

        // Log that region_id is being auto-assigned
        print(
          'Regional manager creating group - auto-assigned to region: $userRegionId',
        );
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/groups'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${authToken ?? await _authServices.getAccessToken()}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        print('Group created successfully: ${result['name']}');
        return result;
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Bad request: ${errorBody['message'] ?? 'Missing required fields'}',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        throw Exception('Insufficient permissions to create groups');
      } else if (response.statusCode == 500) {
        throw Exception('Server error occurred');
      } else {
        throw Exception(
          'Failed to create group: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error creating group: $e');
    }
  }

  /// Check if user role can create groups
  bool _canCreateGroup(String normalizedRole) {
    final allowedRoles = ['regional manager', 'super_admin', 'root'];
    return allowedRoles.contains(normalizedRole);
  }

  /// Get the current user's region ID (for regional managers)
  Future<String?> _getUserRegionId() async {
    try {
      final userId = await _authServices.getUserId();
      if (userId == null) return null;

      // Get user details to find their assigned region
      final user = await _userServices.fetchCurrentUser(userId);
      return user?.regionId;
    } catch (e) {
      print('Error getting user region ID: $e');
      return null;
    }
  }

  /// Get all regions (for super admin/root region selection)
  Future<List<RegionModel>> getAllRegions() async {
    try {
      // This would typically call a region service or provider
      // For now, we'll return an empty list - this should be implemented
      // based on your existing region management code
      final response = await http.get(
        Uri.parse('$baseUrl/api/regions'),
        headers: {
          'Authorization':
              'Bearer ${authToken ?? await _authServices.getAccessToken()}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((region) => RegionModel.fromJson(region)).toList();
      } else {
        throw Exception('Failed to fetch regions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching regions: $e');
      return [];
    }
  }

  /// Get current user's role and region information
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      final userRole = await _userServices.getUserRole();
      final userId = await _authServices.getUserId();
      final userRegionId = await _getUserRegionId();

      return {
        'role': userRole,
        'userId': userId,
        'regionId': userRegionId,
        'canCreateGroup': userRole != null ? _canCreateGroup(userRole) : false,
        'needsRegionSelection':
            userRole != null
                ? RoleUtils.isSuperAdmin(RoleUtils.normalize(userRole)) ||
                    RoleUtils.isRoot(RoleUtils.normalize(userRole))
                : false,
      };
    } catch (e) {
      throw Exception('Error getting user info: $e');
    }
  }
}
