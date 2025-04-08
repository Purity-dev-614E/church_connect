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
    _currentUser = await _userService.fetchCurrentUser(userId);
    notifyListeners();
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
  Future<List> getAllUsers() async {
    try {
      List<UserModel> users = await _userService.fetchAllUsers();
      return users;
    } catch (error) {
      print('Error fetching users: $error');
      return [];
    }
  }
}