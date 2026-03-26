import 'dart:convert';

import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/core/utils/role_utils.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/services/http_client.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'auth_services.dart';

class UserServices {
  final AuthServices _authServices = AuthServices();
  final HttpClient _httpClient = HttpClient();
  final Logger _logger = Logger();

  //get current user data
  Future<UserModel> fetchCurrentUser(String id, [BuildContext? context]) async {
    try {
      // Validate the ID parameter
      if (id.isEmpty) {
        _logger.e('Error: Empty user ID provided to fetchCurrentUser');
        throw Exception('User ID cannot be empty');
      }

      _logger.d('Fetching user data for ID: $id');

      final response = await _httpClient.get(
        await ApiEndpoints.getUserById(id),
      );

      _logger.d('User data response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _logger.d('User data response: $responseData');

        // Create user model with null safety
        return UserModel.fromJson(responseData);
      } else if (response.statusCode == 401 && context != null) {
        // Handle token expiration
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final refreshed = await authProvider.handleAuthError();

        if (refreshed) {
          // Retry the request after token refresh
          return await fetchCurrentUser(id, context);
        } else {
          throw Exception('Authentication failed. Please login again.');
        }
      } else if (response.statusCode == 403) {
        // Handle forbidden access - could be token issue or permissions
        _logger.w('Access denied (403) when fetching user data for ID: $id');
        _logger.w('Response body: ${response.body}');

        // Try to get more context about the token issue
        try {
          final httpClient = HttpClient();
          final headers = await httpClient.getHeaders();
          _logger.d('Current auth headers being used: $headers');
        } catch (e) {
          _logger.e('Could not get auth headers for debugging: $e');
        }

        throw Exception(
          'Access denied: You may not have permission to access this user data',
        );
      } else if (response.statusCode == 404) {
        // User not yet created in the profiles database.
        // Return a minimal, clearly "incomplete" user so that the app
        // can route them to profile setup, but DO NOT pretend they have
        // groups or a finalized role.
        _logger.w(
          'User not found (404), returning minimal placeholder for ID: $id',
        );
        return UserModel(
          id: id,
          fullName: '', // Empty so profile-setup checks still trigger
          email: '',
          contact: '',
          nextOfKin: '',
          nextOfKinContact: '',
          role: 'user',
          gender: '',
          regionId: '',
          regionalID: '',
        );
      } else {
        _logger.e(
          'Failed to load user. Status: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Exception in fetchCurrentUser: $e');
      // Bubble the error up so callers can show a proper error state
      // instead of silently treating the user as a plain "user" with no group.
      rethrow;
    }
  }

  // Get current user ID
  Future<String?> getUserId() async {
    return await _authServices.getUserId();
  }

  //fetch user role
  Future<String?> getUserRole() async {
    final userId = await _authServices.getUserId();
    if (userId == null) {
      throw Exception('User ID is null');
    }

    final response = await _httpClient.get(
      await ApiEndpoints.getUserById(userId),
    );

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));
      return user.role;
    } else {
      throw Exception('Failed to load user role');
    }
  }

  //fetch user region ID
  Future<String?> getUserRegionId() async {
    final userId = await _authServices.getUserId();
    if (userId == null) {
      throw Exception('User ID is null');
    }

    final response = await _httpClient.get(
      await ApiEndpoints.getUserById(userId),
    );

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));

      // For regional leadership roles, return regionalID instead of regionId
      if (RoleUtils.isRegionalLeadership(user.role)) {
        _logger.d(
          'Getting regionalID for regional manager: ${user.regionalID}',
        );
        return user.regionalID;
      }

      _logger.d('Getting regionId for regular user: ${user.regionId}');
      return user.regionId;
    } else {
      throw Exception('Failed to load user region ID');
    }
  }

  // assign user to group
  Future<bool> assignUserToGroup(String userId, String groupId) async {
    final response = await _httpClient.post(
      await ApiEndpoints.addGroupMember(userId, groupId),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to assign user to group');
    }
  }

  //getall users
  Future<List<UserModel>> fetchAllUsers() async {
    final response = await _httpClient.get(await ApiEndpoints.users);

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((user) => UserModel.fromJson(user)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _httpClient.get(
        '${await ApiEndpoints.searchUsers}?query=$query',
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((user) => UserModel.fromJson(user)).toList();
      } else {
        // If the search endpoint fails, fall back to filtering all users locally
        final allUsers = await fetchAllUsers();
        final lowercaseQuery = query.toLowerCase();

        return allUsers
            .where(
              (user) =>
                  user.fullName.toLowerCase().contains(lowercaseQuery) ||
                  user.email.toLowerCase().contains(lowercaseQuery),
            )
            .toList();
      }
    } catch (e) {
      _logger.e('Error searching users: $e');
      // Fall back to filtering all users locally
      final allUsers = await fetchAllUsers();
      final lowercaseQuery = query.toLowerCase();

      return allUsers
          .where(
            (user) =>
                user.fullName.toLowerCase().contains(lowercaseQuery) ||
                user.email.toLowerCase().contains(lowercaseQuery),
          )
          .toList();
    }
  }

  // Region-specific methods

  // Get users by region
  Future<List<UserModel>> getUsersByRegion(String regionId) async {
    try {
      final response = await _httpClient.get(
        await ApiEndpoints.getRegionUsers(regionId),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _logger.d('Region users response: $jsonResponse');

        // Handle different response structures
        List<dynamic> usersData = [];

        if (jsonResponse is List) {
          // If the response is directly a list of users
          usersData = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          // If the response is wrapped in an object
          if (jsonResponse.containsKey('data')) {
            usersData = jsonResponse['data'] ?? [];
          } else if (jsonResponse.containsKey('users')) {
            usersData = jsonResponse['users'] ?? [];
          } else {
            // If the response structure is different, try to extract users
            _logger.w('Unexpected response structure: $jsonResponse');
            usersData = [];
          }
        }

        // Convert each user data to UserModel with error handling
        List<UserModel> users = [];
        for (var userData in usersData) {
          try {
            if (userData is Map<String, dynamic>) {
              users.add(UserModel.fromJson(userData));
            } else {
              _logger.e('Invalid user data format: $userData');
            }
          } catch (e) {
            _logger.e('Error parsing user data: $userData, Error: $e');
            // Skip this user and continue with others
            continue;
          }
        }

        return users;
      } else {
        _logger.e(
          'API request failed with status: ${response.statusCode}, Body: ${response.body}',
        );
        // If the API fails, fall back to filtering all users locally by region
        final allUsers = await fetchAllUsers();
        return allUsers.where((user) => user.regionId == regionId).toList();
      }
    } catch (e) {
      _logger.e('Error fetching users by region: $e');
      // Fall back to filtering all users locally
      try {
        final allUsers = await fetchAllUsers();
        return allUsers.where((user) => user.regionId == regionId).toList();
      } catch (fallbackError) {
        _logger.e('Fallback also failed: $fallbackError');
        return []; // Return empty list if everything fails
      }
    }
  }

  // Create a new user with region
  Future<bool> createUser(
    String fullName,
    String email,
    String contact,
    String gender,
    String regionId,
  ) async {
    try {
      final response = await _httpClient.post(
        await ApiEndpoints.users,
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'phone_number': contact,
          'gender': gender,
          'region_id': regionId,
          'role': 'user',
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      _logger.e('Error creating user: $e');
      return false;
    }
  }

  // Assign user to region
  Future<bool> assignUserToRegion(String userId, String regionId) async {
    try {
      // First get the current user
      final user = await fetchCurrentUser(userId);

      // Update the user with the new region ID
      final updatedUser = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        contact: user.contact,
        nextOfKin: user.nextOfKin,
        nextOfKinContact: user.nextOfKinContact,
        role: user.role,
        gender: user.gender,
        regionId: user.regionId,
        regionalID: regionId, // Keep existing regional ID
      );

      // Update the user
      final response = await _httpClient.put(
        await ApiEndpoints.updateUser(userId),
        body: jsonEncode(updatedUser.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Error assigning user to region: $e');
      return false;
    }
  }

  // Remove user from region
  Future<bool> removeUserFromRegion(String userId, String regionId) async {
    try {
      // First get the current user
      final user = await fetchCurrentUser(userId);

      // Update the user with null region ID
      final updatedUser = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        contact: user.contact,
        nextOfKin: user.nextOfKin,
        nextOfKinContact: user.nextOfKinContact,
        role: user.role,
        gender: user.gender,
        regionId: '', // Remove region ID
        regionalID: user.regionalID, // Keep existing regional ID
      );

      // Update the user
      final response = await _httpClient.put(
        await ApiEndpoints.updateUser(userId),
        body: jsonEncode(updatedUser.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.e('Error removing user from region: $e');
      return false;
    }
  }
}
