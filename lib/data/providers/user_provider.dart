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
          await _aliasService.setAlias(
            updatedUser.id,
            updatedUser.regionalTitle,
          );
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

      return mergedUser;
    } catch (error) {
      print('Error getting user by ID: $error');
      return null;
    }
  }

  Future<List<UserModel>> getUsersByRegion(String regionId) async {
    try {
      final users = await _userService.getUsersByRegion(regionId);
      return await _attachAliases(users);
    } catch (error) {
      print('Error fetching users by region: $error');
      return [];
    }
  }

  Future<bool> assignUserToRegion(String userId, String regionId) async {
    try {
      final success = await _userService.assignUserToRegion(userId, regionId);

      if (success) {
        // Refresh current user if it's the same user
        if (_currentUser != null && _currentUser!.id == userId) {
          await loadUser(userId);
        }
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

  /// Change user's group with proper validation and group membership management
  Future<bool> changeUserGroup(
    String userId,
    String newGroupId,
    String newGroupName,
  ) async {
    try {
      // Validate inputs
      if (userId.isEmpty || newGroupId.isEmpty) {
        print('Error: Invalid user ID or group ID provided');
        return false;
      }

      print(
        'UserProvider: Changing group for user $userId to group $newGroupId ($newGroupName)',
      );

      // Get current user data
      final currentUser = await _userService.fetchCurrentUser(userId);
      if (currentUser == null) {
        print('Error: User not found');
        return false;
      }

      // Update user with new group information
      final updatedUser = currentUser.copyWith(
        regionId: newGroupId,
        regionName: newGroupName,
      );

      // Update user profile
      final success = await updateUser(updatedUser);

      if (success) {
        print('UserProvider: Successfully changed group for user $userId');
        // Refresh the current user data to ensure consistency
        if (_currentUser != null && _currentUser!.id == userId) {
          await loadUser(userId);
        }
        return true;
      } else {
        print('UserProvider: Failed to update user profile');
        return false;
      }
    } catch (error) {
      print('Error changing user group: $error');
      return false;
    }
  }

  Future<List<UserModel>> _attachAliases(List<UserModel> users) async {
    if (users.isEmpty) return users;
    final aliasMap = await _aliasService.getAllAliases();
    if (aliasMap.isEmpty) return users;

    return users
        .map(
          (user) =>
              aliasMap.containsKey(user.id)
                  ? user.copyWith(regionalTitle: aliasMap[user.id])
                  : user,
        )
        .toList();
  }
}
