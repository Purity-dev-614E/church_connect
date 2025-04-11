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
          print('User not found, creating minimal user model');
          return UserModel(
            id: id,
            fullName: '',
            email: '',
            contact: '',
            nextOfKin: '',
            nextOfKinContact: '',
            role: 'user',
            gender: '',
          );
        }
        
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchCurrentUser: $e');
      // Return a minimal user model instead of throwing
      return UserModel(
        id: id,
        fullName: '',
        email: '',
        contact: '',
        nextOfKin: '',
        nextOfKinContact: '',
        role: 'user',
        gender: '',
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
}