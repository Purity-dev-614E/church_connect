import 'dart:convert';

import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
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

      // Check if user has permission to create a group
      if (userRole != 'super admin' && userRole != 'admin') {
        throw Exception('User does not have permission to create a group');
      }

      final response = await _httpClient.post(
        ApiEndpoints.groups,
        body: {
          'name': name,
          'group_admin_id': userId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create group: HTTP status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }
  
  // Create group with region
  Future<bool> createGroupWithRegion(String name, String description, String adminId, String regionId) async {
    try {
      final response = await _httpClient.post(
        ApiEndpoints.groups,
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
      final response = await _httpClient.get(ApiEndpoints.groups);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((group) => GroupModel.fromJson(group)).toList();
      } else {
        throw Exception("Failed to fetch groups: HTTP status ${response.statusCode}");
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
      final response = await _httpClient.get(ApiEndpoints.getGroupById(id));

      if (response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to fetch group: HTTP status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch group: $e");
    }
  }

  // Fetch group members
  Future<List<dynamic>> fetchGroupMembers(String groupId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getGroupMembers(groupId));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data; // Return raw data as members might not be GroupModel objects
      } else {
        throw Exception("Failed to fetch group members: HTTP status ${response.statusCode}");
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
      final response = await _httpClient.get(ApiEndpoints.getmemberGroups(userId));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((group) => GroupModel.fromJson(group)).toList();
      } else {
        throw Exception("Failed to fetch user's groups: HTTP status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch user's groups: $e");
    }
  }

  // Update group
  Future<GroupModel> updateGroup(String id, String name) async {
    try {
      final response = await _httpClient.put(
        ApiEndpoints.updateGroup(id),
        body: {
          'name': name,
        },
      );

      if (response.statusCode == 200) {
        return GroupModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to update group: HTTP status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to update group: $e");
    }
  }
  
  // Update group with region
  Future<bool> updateGroupWithRegion(String id, String name, String description, String adminId, String regionId) async {
    try {
      final response = await _httpClient.put(
        ApiEndpoints.updateGroup(id),
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
      final response = await _httpClient.delete(ApiEndpoints.deleteGroup(id));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to delete group: HTTP status ${response.statusCode}");
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
      } else if (userRole != 'super admin' && userRole != 'region_manager') {
        throw Exception('User is not authorized to assign admin');
      }

      final response = await _httpClient.post(
        ApiEndpoints.assignAdmin,
        body: {
          'group_id': groupId,
          'group_admin_id': userId,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to assign admin to group: HTTP status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to assign admin to group: $e");
    }
  }

  // Add member to group
  Future<bool> addMemberToGroup(String groupId, String userId) async {
    try {
      final endpoint = ApiEndpoints.addGroupMember(groupId, userId);
      print("GroupServices: Adding member to group");
      print("GroupServices: Endpoint: $endpoint");
      print("GroupServices: GroupId: $groupId, UserId: $userId");
      
      final response = await _httpClient.post(endpoint,
          body: jsonEncode({
            'userId': userId,
          })
      );
      
      print("GroupServices: Response status: ${response.statusCode}");
      print("GroupServices: Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("GroupServices: Successfully added member to group");
        return true;
      } else {
        print("GroupServices: Failed to add member - HTTP ${response.statusCode}");
        throw Exception("Failed to add member to group: HTTP status ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("GroupServices: Exception adding member to group: $e");
      throw Exception("Failed to add member to group: $e");
    }
  }

  // Remove member from group
  Future<bool> removeMemberFromGroup(String groupId, String userId) async {
    try {
      final response = await _httpClient.delete(ApiEndpoints.removeGroupMember(groupId, userId));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception("Failed to remove member from group: HTTP status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to remove member from group: $e");
    }
  }

  // Get groups by admin
  Future<List<GroupModel>> getGroupsByAdmin(String adminId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getGroupsByAdmin(adminId));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((group) => GroupModel.fromJson(group)).toList();
      } else {
        throw Exception("Failed to fetch admin's groups: HTTP status ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch admin's groups: $e");
    }
    return [];
  }

  // Get group demographics
  Future<Map<String, dynamic>> getGroupDemographics(String groupId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getGroupDemographics(groupId));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to fetch group demographics: HTTP status ${response.statusCode}");
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
          final isMember = members.any((member) => 
            member is Map<String, dynamic> && 
            member.containsKey('user_id') && 
            member['user_id'] == userId
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
      final response = await _httpClient.get(ApiEndpoints.getGroupsByRegion(regionId));
      
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
        ApiEndpoints.updateGroup(groupId),
        body: jsonEncode({
          'name': group.name,
          'description': group.description,
          'group_admin_id': group.group_admin!.isNotEmpty ? group.group_admin : null,
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
        ApiEndpoints.updateGroup(groupId),
        body: jsonEncode({
          'name': group.name,
          'description': group.description,
          'group_admin_id': group.group_admin!.isNotEmpty ? group.group_admin : null,
          'region_id': null, // Remove region ID
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Failed to remove group from region: $e");
    }
}

  Future<Map<String, dynamic>> fetchGroupAttendancePercentage(String groupId) async {
    try {
      final response = await _httpClient.get(
        ApiEndpoints.getGroupAttendancePercentage(groupId)
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