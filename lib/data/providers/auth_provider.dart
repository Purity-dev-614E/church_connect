import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/auth_services.dart';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error
}

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

class AuthProvider extends ChangeNotifier {
  final AuthServices _authService = AuthServices();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _baseUrl = ApiEndpoints.baseUrl; // Replace with your actual API base URL

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;

  AuthProvider() {
    // Check if user is already logged in
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      await _loadUserData();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await _authService.getUserId();
      if (userId != null) {
        // In a real app, you would fetch user data from API
        // For now, we'll load from SharedPreferences if available
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('user_data');
        if (userData != null) {
          // Parse user data
          // _currentUser = UserModel.fromJson(json.decode(userData));
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<AuthResult> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      // Trim inputs to avoid whitespace issues
      final trimmedEmail = email.trim();
      final trimmedPassword = password;
      
      // Validate inputs
      if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Email and password are required';
        notifyListeners();
        return AuthResult(
          success: false,
          message: _errorMessage,
        );
      }
      
      // Call the login service
      final result = await _authService.login(trimmedEmail, trimmedPassword);
      print('Auth provider login result: $result');
      
      final bool success = result['success'] == true;
      final String message = result['message'] ?? 'Unknown error';
      
      if (success) {
        // Set the current user from the login response
        if (result['user'] != null) {
          _currentUser = UserModel.fromJson(result['user']);
          print('Current user set: ${_currentUser?.fullName}');
        }
        
        _status = AuthStatus.authenticated;
        notifyListeners();
        return AuthResult(
          success: true,
          message: 'Login successful',
          user: _currentUser,
        );
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = message;
        notifyListeners();
        return AuthResult(
          success: false,
          message: _errorMessage,
        );
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _getReadableErrorMessage(e.toString());
      notifyListeners();
      return AuthResult(
        success: false,
        message: _errorMessage,
      );
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _authService.resetPassword(email);

      if (success) {
        notifyListeners();
        return AuthResult(
          success: true,
          message: 'Password reset link sent successfully',
        );
      } else {
        _errorMessage = 'Failed to send reset link. Please check your email address.';
        notifyListeners();
        return AuthResult(
          success: false,
          message: _errorMessage,
        );
      }
    } catch (e) {
      _errorMessage = _getReadableErrorMessage(e.toString());
      notifyListeners();
      return AuthResult(
        success: false,
        message: _errorMessage,
      );
    }
  }

  Future<AuthResult> signup(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      if (email.trim().isEmpty || password.isEmpty) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Email and password are required';
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }

      print('AuthProvider: Attempting signup with email: ${email.trim()}');

      // Call the signup service
      final signupSuccess = await _authService.signup(email.trim(), password);

      if (signupSuccess) {
        // Signup succeeded → automatically log in
        print('Signup successful, logging in...');
        final loginResult = await login(email.trim(), password);
        return loginResult;
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Failed to create account. Email may already be in use.';
        notifyListeners();
        return AuthResult(success: false, message: _errorMessage);
      }
    } catch (e) {
      print('AuthProvider: Signup error: $e');
      _status = AuthStatus.error;
      _errorMessage = _getReadableErrorMessage(e.toString());
      notifyListeners();
      return AuthResult(success: false, message: _errorMessage);
    }
  }


  Future<bool> logout() async {
    try {
      await _authService.logout();
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getReadableErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(UserModel user) async {
    try {
      final success = await _authService.updateProfile(user);
      if (success) {
        _currentUser = user;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = _getReadableErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  // Helper method to convert technical error messages to user-friendly ones
  String _getReadableErrorMessage(String error) {
    if (error.contains('SocketException') || error.contains('Connection refused')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('401')) {
      return 'Authentication failed. Please login again.';
    } else if (error.contains('403')) {
      return 'You do not have permission to perform this action.';
    } else if (error.contains('404')) {
      return 'Resource not found. Please try again later.';
    } else if (error.contains('500')) {
      return 'Server error. Please try again later.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Reset error state
  void resetError() {
    _errorMessage = '';
    if (_status == AuthStatus.error) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
  
  /// Refresh the authentication token
  /// 
  /// Returns true if token was successfully refreshed
  Future<bool> refreshToken() async {
    try {
      final success = await _authService.refreshToken();
      
      if (!success) {
        // If token refresh fails, set status to unauthenticated
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Your session has expired. Please login again.';
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Authentication failed. Please login again.';
      notifyListeners();
      return false;
    }
  }
  
  /// Handle authentication errors
  /// 
  /// This method should be called when API requests return 401 errors
  Future<bool> handleAuthError() async {
    // Try to refresh the token
    final refreshed = await refreshToken();
    
    if (!refreshed) {
      // If refresh fails, logout the user
      await logout();
      return false;
    }
    
    return true;
  }

  Future<bool> uploadProfileImage(String userId, String base64Image) async {
    try {
      // Get token from secure storage
      final token = await _secureStorage.read(key: AuthServices.accessTokenKey);
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Format the base64 image with the data URL prefix if it doesn't have one
      final formattedBase64Image = base64Image.startsWith('data:image/') 
          ? base64Image 
          : 'data:image/jpeg;base64,$base64Image';

      // Make API request to upload profile image
      final url = Uri.parse('${ApiEndpoints.baseUrl}/users/$userId/uploadimage');
      
      // Log request details (excluding the full base64 string for brevity)
      print('Upload request details:');
      print('- URL: $url');
      print('- Method: PUT');
      print('- Headers: Authorization: Bearer ${token.substring(0, 10)}...');
      print('- Base64 image length: ${formattedBase64Image.length} characters');
      print('- Base64 image format: ${formattedBase64Image.substring(0, 30)}...');

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': formattedBase64Image,
        }),
      );

      print('\nUpload response details:');
      print('- Status code: ${response.statusCode}');
      print('- Headers: ${response.headers}');
      print('- Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (responseData['url'] != null) {
            // Construct the full image URL by combining the base URL with the relative path
            // Remove /api from the base URL when constructing the uploads URL
            final baseUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');
            final fullImageUrl = '$baseUrl${responseData['url']}';
            print('Full image URL: $fullImageUrl');

            // Update the current user's profile image URL with the full URL
            if (_currentUser != null) {
              _currentUser = _currentUser!.copyWith(
                profileImageUrl: fullImageUrl,
              );
              notifyListeners();
            }
            return true;
          } else {
            throw Exception('Server response missing URL');
          }
        } catch (e) {
          print('Error parsing upload response: $e');
          throw Exception('Invalid server response format');
        }
      } else if (response.statusCode == 401) {
        // Handle authentication error
        final refreshed = await handleAuthError();
        if (refreshed) {
          // Retry the upload with new token
          return uploadProfileImage(userId, base64Image);
        }
        throw Exception('Authentication failed');
      } else if (response.statusCode == 500) {
        // Add specific handling for 500 errors
        print('Server error details:');
        print('- Status: 500 Internal Server Error');
        print('- Response body: ${response.body}');
        throw Exception('Server error: ${response.body}');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to upload profile image');
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      _errorMessage = _getReadableErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }
}