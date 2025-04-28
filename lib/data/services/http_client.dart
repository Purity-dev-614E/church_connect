import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_endpoints.dart';

/// A centralized HTTP client that handles token refresh automatically
class HttpClient {
  static HttpClient? _instance;
  bool _isRefreshing = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Token keys
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  
  factory HttpClient() {
    _instance ??= HttpClient._internal();
    return _instance!;
  }
  
  HttpClient._internal();
  
  /// Get authentication token
  Future<String> _getToken() async {
    // Try to get from FlutterSecureStorage first
    String? token = await _secureStorage.read(key: accessTokenKey);
    
    // If not found, try SharedPreferences
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
    }
    
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is null');
    }
    
    return token;
  }
  
  /// Get refresh token
  Future<String?> _getRefreshToken() async {
    // Try to get from FlutterSecureStorage first
    String? token = await _secureStorage.read(key: refreshTokenKey);
    
    // If not found, try SharedPreferences
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('refresh_token');
    }
    
    return token;
  }
  
  /// Refresh the access token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
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
          
          // Get the new tokens
          String? newAccessToken;
          String? newRefreshToken;
          
          if (data.containsKey('access_token')) {
            newAccessToken = data['access_token'];
          } else if (data.containsKey('session') && data['session'].containsKey('access_token')) {
            newAccessToken = data['session']['access_token'];
          }
          
          if (data.containsKey('refresh_token')) {
            newRefreshToken = data['refresh_token'];
          } else if (data.containsKey('session') && data['session'].containsKey('refresh_token')) {
            newRefreshToken = data['session']['refresh_token'];
          }
          
          if (newAccessToken == null) {
            print("Invalid refresh token response format");
            return false;
          }
          
          // Store the new tokens
          await _secureStorage.write(key: accessTokenKey, value: newAccessToken);
          if (newRefreshToken != null) {
            await _secureStorage.write(key: refreshTokenKey, value: newRefreshToken);
          }
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', newAccessToken);
          if (newRefreshToken != null) {
            await prefs.setString('refresh_token', newRefreshToken);
          }
          
          return true;
        } catch (e) {
          print("Error parsing refresh token response: $e");
          return false;
        }
      } else {
        print("Refresh token failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Refresh token error: $e");
      return false;
    }
  }
  
  /// Get default HTTP headers with authentication
  Future<Map<String, String>> getHeaders() async {
    final token = await _getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer $token"
    };
  }
  
  /// Handle HTTP response and refresh token if needed
  Future<http.Response> _handleResponse(Future<http.Response> Function() requestFunction) async {
    try {
      final response = await requestFunction();
      
      // If unauthorized and not already refreshing, try to refresh token
      if (response.statusCode == 401 && !_isRefreshing) {
        _isRefreshing = true;
        try {
          print('Token expired, attempting to refresh...');
          final refreshed = await _refreshToken();
          
          if (refreshed) {
            print('Token refreshed successfully, retrying request...');
            final retryResponse = await requestFunction();
            _isRefreshing = false;
            return retryResponse;
          } else {
            print('Token refresh failed');
            _isRefreshing = false;
            throw Exception('Authentication failed. Please login again.');
          }
        } catch (e) {
          _isRefreshing = false;
          rethrow;
        }
      }
      
      return response;
    } catch (e) {
      print('HTTP request error: $e');
      throw e;
    }
  }
  
  /// GET request with automatic token refresh
  Future<http.Response> get(String url) async {
    print('HTTP GET request to: $url');
    try {
      final response = await _handleResponse(() async {
        final headers = await getHeaders();
        return await http.get(Uri.parse(url), headers: headers);
      });
      if (response.statusCode >= 400) {
       
      }
      
      return response;
    } catch (e) {
      print('HTTP GET request failed: $e');
      rethrow;
    }
  }
  
  /// POST request with automatic token refresh
  Future<http.Response> post(String url, {Object? body}) async {
    return _handleResponse(() async {
      final headers = await getHeaders();
      return await http.post(
        Uri.parse(url), 
        headers: headers,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }
  
  /// PUT request with automatic token refresh
  Future<http.Response> put(String url, {Object? body}) async {
    return _handleResponse(() async {
      final headers = await getHeaders();
      return await http.put(
        Uri.parse(url), 
        headers: headers,
        body: body is String ? body : jsonEncode(body),
      );
    });
  }
  
  /// DELETE request with automatic token refresh
  Future<http.Response> delete(String url) async {
    return _handleResponse(() async {
      final headers = await getHeaders();
      return await http.delete(Uri.parse(url), headers: headers);
    });
  }
}