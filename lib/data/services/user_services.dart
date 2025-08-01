import 'dart:convert';

import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/services/http_client.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'auth_services.dart';

class UserServices {
  final AuthServices _authServices = AuthServices();
  final HttpClient _httpClient = HttpClient();
  
  //get current user data
  Future<UserModel> fetchCurrentUser(String id, [BuildContext? context]) async {
    try {
      // Validate the ID parameter
      if (id.isEmpty) {
        print('Error: Empty user ID provided to fetchCurrentUser');
        throw Exception('User ID cannot be empty');
      }
      
      print('Fetching user data for ID: $id');
      
      final response = await _httpClient.get(ApiEndpoints.getUserById(id));

      print('User data response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('User data response: $responseData');
        
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
      } else {
        print('Failed to load user. Status: ${response.statusCode}, Body: ${response.body}');
        
        // If the user doesn't exist in the database yet, create a minimal user model
        // This handles the case where a user has authenticated but hasn't set up their profile
        if (response.statusCode == 404) {
          print('User not found, creating minimal user model with ID: $id');
          return UserModel(
            id: id,
            fullName: 'User $id',  // Add a default name to make it more user-friendly
            email: '',
            contact: '',
            nextOfKin: '',
            nextOfKinContact: '',
            role: 'user',
            gender: '',
            regionId: '',
          );
        }
        
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchCurrentUser: $e');
      // Return a minimal user model instead of throwing
      return UserModel(
        id: id.isNotEmpty ? id : 'unknown',
        fullName: 'User ${id.isNotEmpty ? id : "Unknown"}',  // Add a default name
        email: '',
        contact: '',
        nextOfKin: '',
        nextOfKinContact: '',
        role: 'user',
        gender: '',
        regionId: '',
      );
    }
  }
  
  //fetch user role
  Future<String?> getUserRole() async {
    final userId = await _authServices.getUserId();
    if (userId == null) {
      throw Exception('User ID is null');
    }
    
    final response = await _httpClient.get(ApiEndpoints.getUserById(userId));

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));
      return user.role;
    } else {
      throw Exception('Failed to load user role');
    }
  }
  
  // assign user to group
  Future<bool> assignUserToGroup(String userId, String groupId) async {
    final response = await _httpClient.post(
      ApiEndpoints.addGroupMember(userId, groupId)
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to assign user to group');
    }
  }

  //getall users
  Future<List<UserModel>> fetchAllUsers() async {
    final response = await _httpClient.get(ApiEndpoints.users);

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
      final response = await _httpClient.get('${ApiEndpoints.searchUsers}?query=$query');
      
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((user) => UserModel.fromJson(user)).toList();
      } else {
        // If the search endpoint fails, fall back to filtering all users locally
        final allUsers = await fetchAllUsers();
        final lowercaseQuery = query.toLowerCase();
        
        return allUsers.where((user) => 
          user.fullName.toLowerCase().contains(lowercaseQuery) || 
          user.email.toLowerCase().contains(lowercaseQuery)
        ).toList();
      }
    } catch (e) {
      print('Error searching users: $e');
      // Fall back to filtering all users locally
      final allUsers = await fetchAllUsers();
      final lowercaseQuery = query.toLowerCase();
      
      return allUsers.where((user) => 
        user.fullName.toLowerCase().contains(lowercaseQuery) || 
        user.email.toLowerCase().contains(lowercaseQuery)
      ).toList();
    }
  }
  
  // Region-specific methods
  
  // Get users by region
  Future<List<UserModel>> getUsersByRegion(String regionId) async {
    try {
      final response = await _httpClient.get(ApiEndpoints.getRegionUsers(regionId));
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        print('Region users response: $jsonResponse');
        
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
            print('Unexpected response structure: $jsonResponse');
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
              print('Invalid user data format: $userData');
            }
          } catch (e) {
            print('Error parsing user data: $userData, Error: $e');
            // Skip this user and continue with others
            continue;
          }
        }
        
        return users;
      } else {
        print('API request failed with status: ${response.statusCode}, Body: ${response.body}');
        // If the API fails, fall back to filtering all users locally by region
        final allUsers = await fetchAllUsers();
        return allUsers.where((user) => user.regionId == regionId).toList();
      }
    } catch (e) {
      print('Error fetching users by region: $e');
      // Fall back to filtering all users locally
      try {
        final allUsers = await fetchAllUsers();
        return allUsers.where((user) => user.regionId == regionId).toList();
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        return []; // Return empty list if everything fails
      }
    }
  }
  
  // Create a new user with region
  Future<bool> createUser(String fullName, String email, String contact, String gender, String regionId) async {
    try {
      final response = await _httpClient.post(
        ApiEndpoints.users,
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
      print('Error creating user: $e');
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
        regionId: regionId,
      );
      
      // Update the user
      final response = await _httpClient.put(
        ApiEndpoints.updateUser(userId),
        body: jsonEncode(updatedUser.toJson()),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error assigning user to region: $e');
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
      );
      
      // Update the user
      final response = await _httpClient.put(
        ApiEndpoints.updateUser(userId),
        body: jsonEncode(updatedUser.toJson()),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing user from region: $e');
      return false;
    }
  }
}