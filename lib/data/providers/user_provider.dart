import 'package:flutter/material.dart';
import '../../data/services/user_services.dart';
import '../../data/services/auth_services.dart';
import '../../data/models/user_model.dart';

class UserProvider with ChangeNotifier {
  final UserServices _userService = UserServices();
  final AuthServices _authService = AuthServices();
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<void> loadUser(String userId) async {
    try {
      _currentUser = await _userService.fetchCurrentUser(userId);
      notifyListeners();
    } catch (e) {
      print('Error loading user: $e');
      // Don't update _currentUser if there's an error
    }
  }
  
  Future<void> updateUser(UserModel updatedUser) async{
    try {
      await _authService.updateProfile(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (error) {
      print('Error updating user: $error');
    }
  }
  
  Future<List<UserModel>> getAllUsers() async {
    try {
      List<UserModel> users = await _userService.fetchAllUsers();
      return users;
    } catch (error) {
      print('Error fetching users: $error');
      return [];
    }
  }
  
  // Search users by name or email
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      return await _userService.searchUsers(query);
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
      
      // Log the result for debugging
      if (user != null) {
        print('UserProvider: Successfully retrieved user: ${user.fullName} (ID: ${user.id})');
      } else {
        print('UserProvider: User not found for ID: $userId');
      }
      
      return user;
    } catch (error) {
      print('Error fetching user by ID: $error');
      return null;
    }
  }
  
  // Region-specific methods
  
  Future<List<UserModel>> getUsersByRegion(String regionId) async {
    try {
      return await _userService.getUsersByRegion(regionId);
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
      return await _userService.assignUserToRegion(userId, regionId);
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
}