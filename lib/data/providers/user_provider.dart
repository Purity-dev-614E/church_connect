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
  Future<void> updateUser( UserModel updatedUser) async{
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
      return await _userService.fetchCurrentUser(userId);
    } catch (error) {
      print('Error fetching user by ID: $error');
      return null;
    }
  }
}