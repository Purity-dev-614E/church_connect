import 'dart:convert';
import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/data/models/removed_member_model.dart';
import 'package:group_management_church_app/data/services/http_client.dart';
import 'package:http/http.dart' as http;

class MemberRemovalService {
  final HttpClient _httpClient = HttpClient();

  // Helper method to fetch user details for removed members
  Future<RemovedMemberModel> _fetchUserDetailsForMember(
    RemovedMemberModel member,
  ) async {
    try {
      print('Fetching user details for userId: ${member.userId}');
      print('API Endpoint: ${await ApiEndpoints.getUserById(member.userId)}');

      // Always fetch user details to ensure we have correct name and email
      final userResponse = await _httpClient.get(
        await ApiEndpoints.getUserById(member.userId),
      );

      print('Response status: ${userResponse.statusCode}');
      print('Response body: ${userResponse.body}');

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        print('User data fetched: ${userData.toString()}');

        // Check what fields are available in the response
        print('Available fields: ${userData.keys.toList()}');
        print('Full name field: ${userData['full_name']}');
        print('Name field: ${userData['name']}');
        print('Email field: ${userData['email']}');

        // Update the removed member with full user details
        final updatedMember = RemovedMemberModel.fromJson({
          ...member.toJson(),
          'user_name':
              userData['full_name'] ?? userData['name'] ?? member.userName,
          'user_email': userData['email'] ?? member.userEmail,
        });

        print('Original member name: ${member.userName}');
        print('Updated member name: ${updatedMember.userName}');
        print('Updated member email: ${updatedMember.userEmail}');
        return updatedMember;
      } else {
        print(
          'Failed to fetch user details for ${member.userId}: ${userResponse.statusCode} - ${userResponse.body}',
        );
      }
    } catch (e) {
      print('Error fetching user details for ${member.userId}: $e');
    }
    print('Returning original member with name: ${member.userName}');
    return member; // Return original member if user fetch fails
  }

  // 1. Remove member from group
  Future<bool> removeMemberFromGroup(
    String groupId,
    String userId, {
    String? reason,
  }) async {
    try {
      final response = await _httpClient.post(
        await ApiEndpoints.removeGroupMemberWithReason(groupId, userId),
        body: {'reason': reason},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to remove member: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error removing member: $e');
    }
  }

  // 2. Get removed members for a group
  Future<List<RemovedMemberModel>> getGroupRemovedMembers(
    String groupId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null) 'search': search,
      };

      final uri = Uri.parse(
        await ApiEndpoints.getRemovedMembers(groupId),
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _httpClient.getHeaders(),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        // Handle both direct array response and object-wrapped response
        List<dynamic> data;
        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          // If it's an object, try common pagination field names
          data =
              decodedData['data'] ??
              decodedData['members'] ??
              decodedData['results'] ??
              decodedData['removed_members'] ??
              [];
        } else {
          throw Exception(
            'Unexpected response format: ${decodedData.runtimeType}',
          );
        }

        final removedMembers =
            data.map((json) => RemovedMemberModel.fromJson(json)).toList();

        // Fetch full user details for each removed member in parallel
        return await Future.wait(
          removedMembers.map((member) => _fetchUserDetailsForMember(member)),
        );
      } else {
        throw Exception('Failed to fetch removed members: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching removed members: $e');
    }
  }

  // 3. Get removal statistics for a group
  Future<RemovalStats> getGroupRemovalStats(String groupId) async {
    try {
      final response = await _httpClient.get(
        await ApiEndpoints.getGroupRemovalStats(groupId),
      );

      if (response.statusCode == 200) {
        return RemovalStats.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch removal stats: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching removal stats: $e');
    }
  }

  // 4. Check if current user can remove members
  Future<bool> canRemoveMembers(String groupId) async {
    try {
      final response = await _httpClient.get(
        await ApiEndpoints.getGroupRemovalPermissions(groupId),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['can_remove'] as bool;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 5. Restore removed member
  Future<bool> restoreMember(String groupId, String userId) async {
    try {
      final response = await _httpClient.post(
        await ApiEndpoints.restoreGroupMember(groupId, userId),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to restore member: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error restoring member: $e');
    }
  }

  // 6. Get user removal history
  Future<List<RemovedMemberModel>> getUserRemovalHistory(String userId) async {
    try {
      final response = await _httpClient.get(
        await ApiEndpoints.getUserRemovalHistory(userId),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        // Handle both direct array response and object-wrapped response
        List<dynamic> data;
        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          // If it's an object, try common pagination field names
          data =
              decodedData['data'] ??
              decodedData['members'] ??
              decodedData['results'] ??
              decodedData['removed_members'] ??
              decodedData['history'] ??
              [];
        } else {
          throw Exception(
            'Unexpected response format: ${decodedData.runtimeType}',
          );
        }

        final removedMembers =
            data.map((json) => RemovedMemberModel.fromJson(json)).toList();

        // Fetch full user details for each removed member in parallel
        return await Future.wait(
          removedMembers.map((member) => _fetchUserDetailsForMember(member)),
        );
      } else {
        throw Exception('Failed to fetch removal history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching removal history: $e');
    }
  }

  // 7. Get all removed members (Admin only)
  Future<List<RemovedMemberModel>> getAllRemovedMembers({
    int page = 1,
    int limit = 50,
    String? search,
    String? groupId,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null) 'search': search,
        if (groupId != null) 'group_id': groupId,
        if (sortBy != null) 'sort_by': sortBy,
        if (sortOrder != null) 'sort_order': sortOrder,
      };

      final uri = Uri.parse(
        await ApiEndpoints.getAllRemovedMembers,
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _httpClient.getHeaders(),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        // Handle both direct array response and object-wrapped response
        List<dynamic> data;
        if (decodedData is List) {
          data = decodedData;
        } else if (decodedData is Map<String, dynamic>) {
          // If it's an object, try common pagination field names
          data =
              decodedData['data'] ??
              decodedData['members'] ??
              decodedData['results'] ??
              decodedData['removed_members'] ??
              [];
        } else {
          throw Exception(
            'Unexpected response format: ${decodedData.runtimeType}',
          );
        }

        final removedMembers =
            data.map((json) => RemovedMemberModel.fromJson(json)).toList();

        // Fetch full user details for each removed member in parallel
        return await Future.wait(
          removedMembers.map((member) => _fetchUserDetailsForMember(member)),
        );
      } else {
        throw Exception(
          'Failed to fetch all removed members: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching all removed members: $e');
    }
  }

  // 5. Get all removed members for a region using existing routes
  Future<List<RemovedMemberModel>> getRegionRemovedMembers(
    String regionId, {
    String? search,
  }) async {
    try {
      // 1. Get all groups in the region
      final response = await _httpClient.get(
        await ApiEndpoints.getRegionGroups(regionId),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch region groups: ${response.body}');
      }

      final groupsData = jsonDecode(response.body);
      List<dynamic> groups;

      if (groupsData is List) {
        groups = groupsData;
      } else if (groupsData is Map<String, dynamic>) {
        groups = groupsData['groups'] ?? groupsData['data'] ?? [];
      } else {
        return [];
      }

      // 2. Fetch removed members for all groups in parallel
      final futures =
          groups.where((group) => group['id'] != null).map((group) async {
            try {
              return await getGroupRemovedMembers(group['id'], search: search);
            } catch (e) {
              print(
                'Error fetching removed members for group ${group['id']}: $e',
              );
              return <RemovedMemberModel>[];
            }
          }).toList();

      final results = await Future.wait(futures);

      // 3. Combine all removed members
      List<RemovedMemberModel> allRemovedMembers = [];
      for (var groupMembers in results) {
        allRemovedMembers.addAll(groupMembers);
      }

      // 4. Remove duplicates by userId
      final uniqueMembers = <String, RemovedMemberModel>{};
      for (var member in allRemovedMembers) {
        uniqueMembers[member.userId] = member;
      }

      // 5. Fetch full user details for each unique removed member in parallel
      final membersWithDetails = await Future.wait(
        uniqueMembers.values.map(
          (member) => _fetchUserDetailsForMember(member),
        ),
      );

      return membersWithDetails;
    } catch (e) {
      throw Exception('Error fetching region removed members: $e');
    }
  }
}
