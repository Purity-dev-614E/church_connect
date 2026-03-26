import 'dart:convert';
import 'dart:developer';

import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/core/utils/role_utils.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/models/removed_member_model.dart';
import 'package:group_management_church_app/data/services/user_services.dart';
import 'package:group_management_church_app/data/services/http_client.dart';

import 'auth_services.dart';

class GroupServices {
  final AuthServices _authServices = AuthServices();
  final HttpClient _httpClient = HttpClient();

  // Create group
  Future<GroupModel> createGroup(String name) async {
    final userId = await _authServices.getUserId();
    if (userId == null) {
      throw Exception('User ID is null');
    }

    try {
      final userServices = UserServices();
      final userRole = await userServices.getUserRole();

      if (userRole == null) {
        throw Exception('User role is null');
      }

      // Check if user has permission to create a group (root bypasses RBAC)
      final normalizedRole = RoleUtils.normalize(userRole);
      if (!RoleUtils.isRoot(normalizedRole) &&
          !RoleUtils.isSuperAdmin(normalizedRole) &&
          !RoleUtils.isRegionalLeadership(normalizedRole) &&
          normalizedRole != 'admin') {
        throw Exception('User does not have permission to create a group');
      }

      final response = await _httpClient.post(
        await await ApiEndpoints.groups,
        body: {'name': name, 'group_admin_id': userId},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          'Failed to create group: HTTP status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Create group with region
  Future<bool> createGroupWithRegion(
    String name,
    String description,
    String adminId,
    String regionId,
  ) async {
    try {
      final response = await _httpClient.post(
        await await ApiEndpoints.groups,
        body: jsonEncode({
          'name': name,
          'description': description,
          'group_admin_id': adminId.isNotEmpty ? adminId : null,
          'region_id': regionId,
        }),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Fetch all groups
  Future<List<GroupModel>> fetchAllGroups() async {
    try {
      final response = await _httpClient.get(await await ApiEndpoints.groups);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((group) => GroupModel.fromJson(group)).toList();
      } else {
        throw Exception(
          "Failed to fetch groups: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to fetch groups: $e");
    }
    // This line should never be reached due to the throws above,
    // but it satisfies the non-nullable return type requirement
    return [];
  }

  // Fetch group by id
  Future<GroupModel> fetchGroupById(String id) async {
    try {
      final response = await _httpClient.get(
        await await ApiEndpoints.getGroupById(id),
      );

      if (response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          "Failed to fetch group: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to fetch group: $e");
    }
  }

  // Fetch group members
  Future<List<dynamic>> fetchGroupMembers(String groupId) async {
    try {
      final response = await _httpClient.get(
        await await ApiEndpoints.getGroupMembers(groupId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data; // Return raw data as members might not be GroupModel objects
      } else {
        throw Exception(
          "Failed to fetch group members: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to fetch group members: $e");
    }
    return [];
  }

  // Get user's groups
  Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      // Make a GET request to the new endpoint for fetching user groups by user ID
      final response = await _httpClient.get(
        await await ApiEndpoints.getmemberGroups(userId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((group) => GroupModel.fromJson(group)).toList();
      } else {
        throw Exception(
          "Failed to fetch user's groups: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to fetch user's groups: $e");
    }
  }

  // Update group
  Future<GroupModel> updateGroup(String id, String name) async {
    try {
      final response = await _httpClient.put(
        await await ApiEndpoints.updateGroup(id),
        body: {'name': name},
      );

      if (response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
          "Failed to update group: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to update group: $e");
    }
  }

  // Update group with region
  Future<bool> updateGroupWithRegion(
    String id,
    String name,
    String description,
    String adminId,
    String regionId,
  ) async {
    try {
      final response = await _httpClient.put(
        await await ApiEndpoints.updateGroup(id),
        body: jsonEncode({
          'name': name,
          'description': description,
          'group_admin_id': adminId.isNotEmpty ? adminId : null,
          'region_id': regionId.isNotEmpty ? regionId : null,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to update group: $e");
    }
  }

  // Delete group
  Future<bool> deleteGroup(String id) async {
    try {
      final response = await _httpClient.delete(
        await await ApiEndpoints.deleteGroup(id),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          "Failed to delete group: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to delete group: $e");
    }
  }

  // Assign admin to group
  Future<bool> assignAdminToGroup(String groupId, String userId) async {
    try {
      // Check if current user has permission
      final userServices = UserServices();
      final userRole = await userServices.getUserRole();

      if (userRole == null) {
        throw Exception('User role is null');
      } else {
        final normalizedRole = RoleUtils.normalize(userRole);
        if (!RoleUtils.isRoot(normalizedRole) &&
            !RoleUtils.isSuperAdmin(normalizedRole) &&
            !RoleUtils.isRegionalLeadership(normalizedRole)) {
          throw Exception('User is not authorized to assign admin');
        }
      }

      final response = await _httpClient.put(
        await await ApiEndpoints.updateGroup(groupId),
        body: {'group_admin_id': userId},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          "Failed to assign admin to group: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to assign admin to group: $e");
    }
  }

  // Add member to group
  Future<bool> addMemberToGroup(String groupId, String userId) async {
    try {
      final endpoint = await await ApiEndpoints.addGroupMember(groupId, userId);

      final response = await _httpClient.post(
        endpoint,
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception(
          "Failed to add member to group: HTTP status ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Failed to add member to group: $e");
    }
  }

  // Check if user has access to manage a specific group (region-based validation)
  Future<bool> canManageGroup(String groupId) async {
    try {
      final userServices = UserServices();
      final userRole = await userServices.getUserRole();

      if (userRole == null) {
        return false;
      }

      final normalizedRole = RoleUtils.normalize(userRole);

      // Root and super admin can manage any group
      if (RoleUtils.isRoot(normalizedRole) ||
          RoleUtils.isSuperAdmin(normalizedRole)) {
        return true;
      }

      // For regional managers, check if group is in their region
      if (RoleUtils.isRegionalLeadership(normalizedRole)) {
        final group = await fetchGroupById(groupId);
        final currentUserId = await userServices.getUserId();

        if (currentUserId == null) {
          return false;
        }

        final currentUser = await userServices.fetchCurrentUser(currentUserId);

        if (currentUser.regionalID.isEmpty || group.region_id == null) {
          return false;
        }

        return currentUser.regionalID == group.region_id;
      }

      // For regular admins, check if they are the group admin
      if (normalizedRole == 'admin') {
        final group = await fetchGroupById(groupId);
        final currentUserId = await userServices.getUserId();

        if (currentUserId == null || group.group_admin == null) {
          return false;
        }

        return currentUserId == group.group_admin;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Remove member from group (legacy, no reason)
  Future<bool> removeMemberFromGroup(String groupId, String userId) async {
    try {
      final response = await _httpClient.delete(
        await await ApiEndpoints.removeGroupMember(groupId, userId),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          "Failed to remove member from group: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to remove member from group: $e");
    }
  }

  /// Remove member from group with a required reason (stored for Removed Members list).
  /// If the backend does not support the reason endpoint (404/501), falls back to legacy DELETE.
  Future<bool> removeMemberFromGroupWithReason(
    String groupId,
    String userId,
    String reason,
  ) async {
    try {
      final response = await _httpClient.post(
        await await ApiEndpoints.removeGroupMemberWithReason(groupId, userId),
        body: jsonEncode({'reason': reason.trim()}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      if (response.statusCode == 404 || response.statusCode == 501) {
        return removeMemberFromGroup(groupId, userId);
      }

      // Handle specific error messages
      if (response.statusCode == 403) {
        final responseBody = response.body.toLowerCase();
        if (responseBody.contains('region')) {
          throw Exception('Access denied: Group not in your region');
        } else if (responseBody.contains('permission')) {
          throw Exception('Access denied: Insufficient permissions');
        } else {
          throw Exception(
            'Access denied: You cannot remove members from this group',
          );
        }
      }

      throw Exception(
        "Failed to remove member: HTTP status ${response.statusCode}, Body: ${response.body}",
      );
    } catch (e) {
      // Try legacy removal as fallback
      try {
        return await removeMemberFromGroup(groupId, userId);
      } catch (legacyError) {
        // If legacy also fails with 403, preserve the original region error message
        if (e.toString().contains('Access denied: Group not in your region')) {
          throw Exception('Access denied: Group not in your region');
        }
        throw Exception("Failed to remove member from group: $e");
      }
    }
  }

  /// Fetch list of removed members for a group (with removal reasons).
  Future<List<RemovedMemberModel>> getRemovedMembers(String groupId) async {
    try {
      final response = await _httpClient.get(
        await await ApiEndpoints.getRemovedMembers(groupId),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        // Handle both direct array response and object-wrapped response
        List<dynamic> data;
        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          // If it's an object, try common field names
          data =
              decodedData['data'] ??
              decodedData['members'] ??
              decodedData['removed_members'] ??
              decodedData['results'] ??
              [];
        } else {
          print('Unexpected response format: ${decodedData.runtimeType}');
          return [];
        }

        print('DEBUG: Removed members API returned ${data.length} items');
        return data
            .map((e) => RemovedMemberModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        print('API returned status ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      log("Failed to fetch removed members: $e");
      return [];
    }
  }

  // Get groups by admin
  Future<List<GroupModel>> getGroupsByAdmin(String adminId) async {
    try {
      final response = await _httpClient.get(
        await await ApiEndpoints.getGroupsByAdmin(adminId),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((group) => GroupModel.fromJson(group)).toList();
      } else {
        throw Exception(
          "Failed to fetch admin's groups: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to fetch admin's groups: $e");
    }
    return [];
  }

  // Get group demographics
  Future<Map<String, dynamic>> getGroupDemographics(String groupId) async {
    try {
      final response = await _httpClient.get(
        await await ApiEndpoints.getGroupDemographics(groupId),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Failed to fetch group demographics: HTTP status ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Failed to fetch group demographics: $e");
    }
  }

  // Get user's groups (alternative implementation)
  Future<List<GroupModel>> getUserGroups1(String userId) async {
    try {
      // Since there's no direct endpoint for getting user's groups,
      // we'll fetch all groups and filter for those where the user is a member
      final allGroups = await fetchAllGroups();
      List<GroupModel> userGroups = [];

      for (var group in allGroups) {
        try {
          final members = await fetchGroupMembers(group.id);
          final isMember = members.any(
            (member) =>
                member is Map<String, dynamic> &&
                member.containsKey('user_id') &&
                member['user_id'] == userId,
          );

          if (isMember) {
            userGroups.add(group);
          }
        } catch (e) {
          // Skip this group if there's an error fetching members
          continue;
        }
      }

      return userGroups;
    } catch (e) {
      throw Exception("Failed to fetch user's groups: $e");
    }
  }

  // Region-specific methods

  // Get groups by region
  Future<List<GroupModel>> getGroupsByRegion(String regionId) async {
    try {
      final response = await _httpClient.get(
        await await ApiEndpoints.getGroupsByRegion(regionId),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> groupsData = jsonResponse['data'] ?? [];
        return groupsData.map((group) => GroupModel.fromJson(group)).toList();
      } else {
        // If the API fails, fall back to filtering all groups locally by region
        final allGroups = await fetchAllGroups();
        return allGroups.where((group) => group.region_id == regionId).toList();
      }
    } catch (e) {
      // Fall back to filtering all groups locally
      try {
        final allGroups = await fetchAllGroups();
        return allGroups.where((group) => group.region_id == regionId).toList();
      } catch (innerError) {
        throw Exception("Failed to fetch groups by region: $e, $innerError");
      }
    }
  }

  // Assign group to region
  Future<bool> assignGroupToRegion(String groupId, String regionId) async {
    try {
      // First get the current group
      final group = await fetchGroupById(groupId);

      // Update the group with the new region ID
      final response = await _httpClient.put(
        await ApiEndpoints.updateGroup(groupId),
        body: jsonEncode({
          'name': group.name,
          'description': group.description,
          'group_admin_id':
              group.group_admin!.isNotEmpty ? group.group_admin : null,
          'region_id': regionId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to assign group to region: $e");
    }
  }

  // Remove group from region
  Future<bool> removeGroupFromRegion(String groupId) async {
    try {
      // First get the current group
      final group = await fetchGroupById(groupId);

      // Update the group with null region ID
      final response = await _httpClient.put(
        await ApiEndpoints.updateGroup(groupId),
        body: jsonEncode({
          'name': group.name,
          'description': group.description,
          'group_admin_id':
              group.group_admin!.isNotEmpty ? group.group_admin : null,
          'region_id': null, // Remove region ID
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to remove group from region: $e");
    }
  }

  Future<Map<String, dynamic>> fetchGroupAttendancePercentage(
    String groupId,
  ) async {
    try {
      final response = await _httpClient.get(
        await await ApiEndpoints.getGroupAttendancePercentage(groupId),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] ?? {};
      } else {
        throw Exception('Failed to fetch attendance');
      }
    } catch (e) {
      throw Exception("Failed to fetch group percentage: $e");
    }
  }
}
