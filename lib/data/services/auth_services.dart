import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_endpoints.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user_model.dart';

class AuthServices {
  // Use a single instance of FlutterSecureStorage
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  // Token keys
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String userIdKey = 'user_id';

  // Login method with proper error handling and token storage
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password are required.'
        };
      }

      // Try both JSON and form-encoded formats
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password
        })
      );

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('Error parsing response: $e');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'message': 'Invalid server response'
        };
      }

      print('Login response: $responseData');

      if (response.statusCode == 200) {
        try {
          // Store tokens securely
          await secureStorage.write(
            key: accessTokenKey, 
            value: responseData['session']['access_token']
          );
          await secureStorage.write(
            key: refreshTokenKey, 
            value: responseData['session']['refresh_token']
          );

          // Store user_id in SharedPreferences for easier access
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            userIdKey, 
            responseData['user']['id'].toString()
          );

          print('Login successful: ${responseData['message']}');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Login successful'
          };
        } catch (e) {
          print('Error storing auth data: $e');
          return {
            'success': false,
            'message': 'Error processing login response: $e'
          };
        }
      } else {
        final errorMessage = responseData['message'] ?? 
                            responseData['error'] ?? 
                            'Unknown error occurred';
        print('Login failed: $errorMessage');
        return {
          'success': false,
          'message': errorMessage
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Network or server error: $e'
      };
    }
  }

  // Get the current user ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdKey);
  }

  // Get access token
  Future<String?> getAccessToken() async {
    return await secureStorage.read(key: accessTokenKey);
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: refreshTokenKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await getAccessToken();
      final userId = await getUserId();
      
      // Check both token and userId
      return token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    // Clear stored tokens from secure storage
    await secureStorage.delete(key: accessTokenKey);
    await secureStorage.delete(key: refreshTokenKey);

    // Clear user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdKey);

    print('Logout successful');
  }

  // Signup method with proper error handling
  Future<bool> signup(String email, String password) async {
    try {
      print("Attempting signup with email: $email");
      
      // Use JSON format for the request body, similar to login
      final response = await http.post(
        Uri.parse(ApiEndpoints.signup),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "email": email,
          "password": password
        })
      );

      print("Signup response status code: ${response.statusCode}");
      print("Signup response body: ${response.body}");

      // Parse response body
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print("Error parsing signup response: $e");
        print("Raw response body: ${response.body}");
        return false;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Signup Successful: ${responseData['message'] ?? 'User created successfully'}");
        return true;
      } else {
        // Extract error message with fallback
        final errorMessage = responseData['message'] ?? 
                            responseData['error'] ?? 
                            'Failed to create account. Email may already be in use.';
        print("Signup Failed: $errorMessage");
        return false;
      }
    } catch (e) {
      print("Signup Error: $e");
      return false;
    }
  }

  // Reset password method
  Future<bool> resetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.forgotPassword),
        body: {
          "email": email
        }
      );

      if (response.statusCode == 200) {
        print("Reset Password Link Sent Successfully");
        return true;
      } else {
        final data = json.decode(response.body);
        print("Reset Password Failed: ${data['message']}");
        return false;
      }
    } catch (e) {
      print("Reset Password Error: $e");
      return false;
    }
  }

  // Update user profile
 Future<bool> updateProfile(UserModel user) async {
        try {
          // Get the user ID
          final userId = await getUserId();
          if (userId == null) {
            print("Cannot update profile: User ID not found");
            return false;
          }

          // Get the access token for authorization
          final token = await getAccessToken();
          if (token == null) {
            print("Cannot update profile: Not authenticated");
            return false;
          }

          final response = await http.put(
            Uri.parse(ApiEndpoints.updateUser(userId)),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              "full_name": user.fullName,
              "phone_number": user.contact,
              "gender": user.gender,
              "next_of_kin_name": user.nextOfKin,
              "next_of_kin_contact": user.nextOfKinContact,
              "role": user.role
            })
          );

      if (response.statusCode == 200) {
        print("Profile Updated Successfully");
        return true;
      } else {
        final data = json.decode(response.body);
        print("Failed to Update Profile: ${data['message']}");
        return false;
      }
    } catch (e) {
      print("Profile Update Error: $e");
      return false;
    }
  }

  // Method to refresh the access token using the refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        print("Cannot refresh token: No refresh token found");
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiEndpoints.refreshToken),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({
          "refresh_token": refreshToken
        })
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          // Store the new access token
          if (data.containsKey('access_token')) {
            await secureStorage.write(key: accessTokenKey, value: data['access_token']);
          } else if (data.containsKey('session') && data['session'].containsKey('access_token')) {
            await secureStorage.write(key: accessTokenKey, value: data['session']['access_token']);
          } else {
            print("Invalid refresh token response format");
            return false;
          }
          
          // Store the new refresh token if provided
          if (data.containsKey('refresh_token')) {
            await secureStorage.write(key: refreshTokenKey, value: data['refresh_token']);
          } else if (data.containsKey('session') && data['session'].containsKey('refresh_token')) {
            await secureStorage.write(key: refreshTokenKey, value: data['session']['refresh_token']);
          }
          
          print("Token refreshed successfully");
          return true;
        } catch (e) {
          print("Error processing refresh token response: $e");
          return false;
        }
      } else {
        print("Failed to refresh token: ${response.statusCode}");
        print("Response body: ${response.body}");
        
        // If refresh token is invalid or expired, clear tokens to force re-login
        if (response.statusCode == 401 || response.statusCode == 403) {
          await logout();
        }
        
        return false;
      }
    } catch (e) {
      print("Token Refresh Error: $e");
      return false;
    }
  }
}