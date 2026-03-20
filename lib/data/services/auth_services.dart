import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_endpoints.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;

import 'http_client.dart';

class AuthServices {
  // Use a single instance of FlutterSecureStorage
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  // In-memory fallback (keeps session alive if browser storage is blocked)
  String? _memoryAccessToken;
  String? _memoryRefreshToken;
  String? _memoryUserId;

  // Token keys
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String userIdKey = 'user_id';

  final HttpClient _httpClient = HttpClient();

  // Login method with proper error handling and token storage
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password are required.',
        };
      }

      print('Attempting login with email: $email');

      final response = await http.post(
        Uri.parse(await ApiEndpoints.login),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({'email': email, 'password': password}),
      );

      print('Login response status code: ${response.statusCode}');
      // print('Login response body: ${response.body}');

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        print('Error parsing response: $e');
        print('Response body: ${response.body}');
        return {'success': false, 'message': 'Invalid server response'};
      }

      print('Parsed login response: $responseData');

      if (response.statusCode == 200) {
        // Check if the response has the expected structure
        if (responseData['session'] != null && responseData['user'] != null) {
          final session = responseData['session'];
          final user = responseData['user'];

          // Store tokens and user data
          // Be tolerant to different API shapes (snake_case vs camelCase, nested vs top-level)
          String? accessToken;
          String? refreshToken;
          if (session is Map) {
            accessToken =
                session['access_token']?.toString() ??
                session['accessToken']?.toString();
            refreshToken =
                session['refresh_token']?.toString() ??
                session['refreshToken']?.toString();
          }
          accessToken ??=
              responseData['access_token']?.toString() ??
              responseData['accessToken']?.toString();
          refreshToken ??=
              responseData['refresh_token']?.toString() ??
              responseData['refreshToken']?.toString();
          final String? userId = (user is Map) ? user['id']?.toString() : null;

          print('Login successful. Storing tokens and user data...');
          // print('User ID: $userId');
          // print('User Data: $user');

          // Validate critical fields before writing (prevents null-safety crashes in storage plugins)
          if (accessToken == null || accessToken.isEmpty) {
            return {
              'success': false,
              'message': 'Login failed: server response missing access token.',
            };
          }
          if (userId == null || userId.isEmpty) {
            return {
              'success': false,
              'message': 'Login failed: server response missing user id.',
            };
          }

          // Always cache in memory (so API calls can still work in-session)
          _memoryAccessToken = accessToken;
          _memoryRefreshToken = refreshToken;
          _memoryUserId = userId;

          // Store tokens in secure storage (best effort; web implementations can fail)
          try {
            await secureStorage.write(key: accessTokenKey, value: accessToken);
            if (refreshToken != null && refreshToken.isNotEmpty) {
              await secureStorage.write(
                key: refreshTokenKey,
                value: refreshToken,
              );
            }
            await secureStorage.write(key: userIdKey, value: userId);
          } catch (e) {
            print('Secure storage write failed (continuing): $e');
          }

          // Store user data in SharedPreferences
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_data', json.encode(user));
            await prefs.setString('user_id', userId);
            // Also store tokens here for reliable web persistence / fallback reads
            await prefs.setString('auth_token', accessToken);
            if (refreshToken != null && refreshToken.isNotEmpty) {
              await prefs.setString('refresh_token', refreshToken);
            }
          } catch (e) {
            // Some browsers / contexts block storage (e.g. strict privacy modes).
            // Don't fail login just because persistence is unavailable.
            print('SharedPreferences write failed (continuing): $e');
          }

          return {'success': true, 'message': 'Login successful', 'user': user};
        } else {
          final errorMessage = responseData['message'] ?? 'Login failed';
          print('Login failed: $errorMessage');
          return {'success': false, 'message': errorMessage};
        }
      } else {
        final errorMessage = responseData['message'] ?? 'Login failed';
        print('Login failed with status ${response.statusCode}: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
    } catch (e, st) {
      print('Login error: $e');
      print('Login stacktrace: $st');
      return {
        'success': false,
        'message': 'An error occurred during login: $e',
      };
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
        Uri.parse(await ApiEndpoints.refreshToken),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({"refresh_token": refreshToken}),
      );

      print("Refresh token response status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Parse response body (don't mix parsing and storage writes in same try)
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          print("Error parsing refresh token response: $e");
          print("Raw refresh token response body: ${response.body}");
          return false;
        }

        // Get the new tokens (tolerant to API shape)
        String? newAccessToken;
        String? newRefreshToken;

        if (data.containsKey('access_token')) {
          newAccessToken = data['access_token']?.toString();
        } else if (data.containsKey('accessToken')) {
          newAccessToken = data['accessToken']?.toString();
        } else if (data.containsKey('session') &&
            data['session'] is Map &&
            (data['session'] as Map).containsKey('access_token')) {
          newAccessToken = (data['session'] as Map)['access_token']?.toString();
        } else if (data.containsKey('session') &&
            data['session'] is Map &&
            (data['session'] as Map).containsKey('accessToken')) {
          newAccessToken = (data['session'] as Map)['accessToken']?.toString();
        }

        if (data.containsKey('refresh_token')) {
          newRefreshToken = data['refresh_token']?.toString();
        } else if (data.containsKey('refreshToken')) {
          newRefreshToken = data['refreshToken']?.toString();
        } else if (data.containsKey('session') &&
            data['session'] is Map &&
            (data['session'] as Map).containsKey('refresh_token')) {
          newRefreshToken =
              (data['session'] as Map)['refresh_token']?.toString();
        } else if (data.containsKey('session') &&
            data['session'] is Map &&
            (data['session'] as Map).containsKey('refreshToken')) {
          newRefreshToken =
              (data['session'] as Map)['refreshToken']?.toString();
        }

        if (newAccessToken == null || newAccessToken.isEmpty) {
          print("Invalid refresh token response format");
          return false;
        }

        // Update in-memory values first (keeps session alive even if persistence fails)
        _memoryAccessToken = newAccessToken;
        _memoryRefreshToken =
            (newRefreshToken != null && newRefreshToken.isNotEmpty)
                ? newRefreshToken
                : _memoryRefreshToken;

        // Store the new tokens (best effort; web storage can be blocked)
        try {
          await secureStorage.write(key: accessTokenKey, value: newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await secureStorage.write(
              key: refreshTokenKey,
              value: newRefreshToken,
            );
          }
        } catch (e) {
          print("Secure storage write failed during refresh (continuing): $e");
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await prefs.setString('refresh_token', newRefreshToken);
          }
        } catch (e) {
          print(
            "SharedPreferences write failed during refresh (continuing): $e",
          );
        }

        return true;
      } else {
        print("Refresh token failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e, st) {
      print("Refresh token error: $e");
      print("Refresh token stacktrace: $st");
      return false;
    }
  }

  // Get access token
  Future<String?> getAccessToken() async {
    try {
      // Prefer in-memory token first
      if (_memoryAccessToken != null && _memoryAccessToken!.isNotEmpty) {
        return _memoryAccessToken;
      }

      // Try to get from FlutterSecureStorage first
      String? token = await secureStorage.read(key: accessTokenKey);

      // If not found, try SharedPreferences
      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('auth_token');
      }

      return token;
    } catch (e) {
      print("Error getting access token: $e");
      return null;
    }
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      // Prefer in-memory token first
      if (_memoryRefreshToken != null && _memoryRefreshToken!.isNotEmpty) {
        return _memoryRefreshToken;
      }

      // Try to get from FlutterSecureStorage first
      String? token = await secureStorage.read(key: refreshTokenKey);

      // If not found, try SharedPreferences
      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('refresh_token');
      }

      return token;
    } catch (e) {
      print("Error getting refresh token: $e");
      return null;
    }
  }

  // Get user ID
  Future<String?> getUserId() async {
    try {
      // Prefer in-memory value first
      if (_memoryUserId != null && _memoryUserId!.isNotEmpty) {
        return _memoryUserId;
      }

      // Try to get from FlutterSecureStorage first
      String? userId = await secureStorage.read(key: userIdKey);

      // If not found, try SharedPreferences
      if (userId == null) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString(userIdKey);
      }

      return userId;
    } catch (e) {
      print("Error getting user ID: $e");
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await getAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print("Error checking login status: $e");
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      // Clear in-memory values
      _memoryAccessToken = null;
      _memoryRefreshToken = null;
      _memoryUserId = null;

      // Clear tokens from FlutterSecureStorage
      await secureStorage.delete(key: accessTokenKey);
      await secureStorage.delete(key: refreshTokenKey);
      await secureStorage.delete(key: userIdKey);

      // Clear tokens from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
      await prefs.remove(userIdKey);

      print('Logout successful');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Signup method with proper error handling
  Future<bool> signup(String email, String password) async {
    try {
      print("Attempting signup with email: $email");

      final response = await http.post(
        Uri.parse(await ApiEndpoints.signup),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({"email": email, "password": password}),
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
        print(
          "Signup Successful: ${responseData['message'] ?? 'User created successfully'}",
        );
        return true;
      } else {
        // Extract error message with fallback
        final errorMessage =
            responseData['message'] ??
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
        Uri.parse(await ApiEndpoints.forgotPassword),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode({"email": email}),
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
      final response = await _httpClient.put(
        await ApiEndpoints.updateUser(user.id),
        body: json.encode({
          "full_name": user.fullName,
          "phone_number": user.contact,
          "gender": user.gender,
          "next_of_kin_name": user.nextOfKin,
          "next_of_kin_contact": user.nextOfKinContact,
          "role": user.role,
          "location": user.regionName,
          "group_id": user.regionId,
          "age": user.age,
          "citam_assembly": user.citam_Assembly,
          "if_not_member": user.if_Not,
          "region_id": user.regionalID,
        }),
      );

      if (response.statusCode == 200) {
        print("Profile Updated Successfully");
        return true;
      } else {
        final data = json.decode(response.body);
        print(
          "Failed to Update Profile: ${data['message']}. \n Response status code: ${response.statusCode}, \n Response body: ${response.body}",
        );
        return false;
      }
    } catch (e) {
      print("Profile Update Error: $e");
      return false;
    }
  }
}
