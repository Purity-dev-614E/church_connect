import 'dart:developer';

import 'package:flutter/material.dart';
import '../../core/utils/role_utils.dart';
import '../services/regional_alias_service.dart';
import '../../data/services/user_services.dart';
import '../../data/services/auth_services.dart';
import '../../data/models/user_model.dart';

class UserProvider with ChangeNotifier {
  final UserServices _userService = UserServices();
  final AuthServices _authService = AuthServices();
  final RegionalAliasService _aliasService = RegionalAliasService();
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<void> loadUser(String userId) async {
    try {
      final fetchedUser = await _userService.fetchCurrentUser(userId);
      final alias = await _aliasService.getAlias(userId);
      _currentUser = fetchedUser.copyWith(regionalTitle: alias);
      notifyListeners();
      log('User Found: ${_currentUser!.fullName} (ID: ${_currentUser!.id})');
    } catch (e) {
      print('Error loading user: $e');
      // Don't update _currentUser if there's an error
    }
  }
  
  Future<bool> updateUser(UserModel updatedUser) async {
    try {
      // Validate user ID
      if (updatedUser.id.isEmpty) {
        print('Error: Empty user ID provided to updateUser');
        return false;
      }

      // Log the update attempt
      print('Updating user: ${updatedUser.fullName} (ID: ${updatedUser.id})');
      print('New role: ${updatedUser.role}');
      
      // Update the user profile
      final success = await _authService.updateProfile(updatedUser);
      
      if (success) {
        if (RoleUtils.isRegionalLeadership(updatedUser.role)) {
          await _aliasService.setAlias(updatedUser.id, updatedUser.regionalTitle);
        } else {
          await _aliasService.clearAlias(updatedUser.id);
        }

        final alias = await _aliasService.getAlias(updatedUser.id);
        _currentUser = updatedUser.copyWith(regionalTitle: alias);
        notifyListeners();
        return true;
      } else {
        print('Failed to update user profile');
        return false;
      }
    } catch (error) {
      print('Error updating user: $error');
      return false;
    }
  }
  
  Future<List<UserModel>> getAllUsers() async {
    try {
      final users = await _userService.fetchAllUsers();
      return await _attachAliases(users);
    } catch (error) {
      print('Error fetching users: $error');
      return [];
    }
  }
  
  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final results = await _userService.searchUsers(query);
      return await _attachAliases(results);
    } catch (error) {
      print('Error searching users: $error');
      return [];
    }
  }
  
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Validate userId
      if (userId.isEmpty) {
        print('Error: Empty userId provided to getUserById');
        return null;
      }
      
      print('UserProvider: Getting user by ID: $userId');
      final user = await _userService.fetchCurrentUser(userId);
      final alias = await _aliasService.getAlias(userId);
      final mergedUser = user.copyWith(regionalTitle: alias);
      
      // Log the result for debugging
      print('UserProvider: Successfully retrieved user: ${user.fullName} (ID: ${user.id})');
          
      return mergedUser;
    } catch (error) {
      print('Error fetching user by ID: $error');
      return null;
    }
  }
  
  // Region-specific methods
  
  Future<List<UserModel>> getUsersByRegion(String regionId) async {
    try {
      final users = await _userService.getUsersByRegion(regionId);
      final merged = await _attachAliases(users);
      return merged;
    } catch (error) {
      print('Error fetching users by region: $error');
      return [];
    }
  }
  
  Future<bool> createUser(String fullName, String email, String contact, String gender, String regionId) async {
    try {
      return await _userService.createUser(fullName, email, contact, gender, regionId);
    } catch (error) {
      print('Error creating user: $error');
      return false;
    }
  }
  
  Future<bool> assignUserToRegion(String userId, String regionId) async {
    try {
      // Validate inputs
      if (userId.isEmpty || regionId.isEmpty) {
        print('Error: Empty userId or regionId provided to assignUserToRegion');
        return false;
      }

      print('Assigning user $userId to region $regionId');
      final success = await _userService.assignUserToRegion(userId, regionId);
      
      if (success) {
        // Reload the current user if it's the same user
        if (_currentUser?.id == userId) {
          await loadUser(userId);
        }
        notifyListeners();
      }
      
      return success;
    } catch (error) {
      print('Error assigning user to region: $error');
      return false;
    }
  }
  
  Future<bool> removeUserFromRegion(String userId, String regionId) async {
    try {
      return await _userService.removeUserFromRegion(userId, regionId);
    } catch (error) {
      print('Error removing user from region: $error');
      return false;
    }
  }

  Future<List<UserModel>> _attachAliases(List<UserModel> users) async {
    if (users.isEmpty) return users;
    final aliasMap = await _aliasService.getAllAliases();
    if (aliasMap.isEmpty) return users;

    return users
        .map((user) => aliasMap.containsKey(user.id)
            ? user.copyWith(regionalTitle: aliasMap[user.id])
            : user)
        .toList();
  }
}