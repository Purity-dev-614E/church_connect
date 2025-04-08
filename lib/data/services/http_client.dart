import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:group_management_church_app/data/services/auth_services.dart';

/// A centralized HTTP client that handles token refresh automatically
class HttpClient {
  final AuthServices _authServices = AuthServices();
  static final HttpClient _instance = HttpClient._internal();
  
  factory HttpClient() {
    return _instance;
  }
  
  HttpClient._internal();
  
  /// Get authentication token with refresh capability
  Future<String> _getToken() async {
    String? token = await _authServices.getAccessToken();
    
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is null');
    }
    
    return token;
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
      
      // If unauthorized, try to refresh token and retry
      if (response.statusCode == 401) {
        print('Token expired, attempting to refresh...');
        final refreshed = await _authServices.refreshToken();
        
        if (refreshed) {
          print('Token refreshed successfully, retrying request...');
          return await requestFunction();
        } else {
          print('Token refresh failed');
          throw Exception('Authentication failed. Please login again.');
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
    return _handleResponse(() async {
      final headers = await getHeaders();
      return await http.get(Uri.parse(url), headers: headers);
    });
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