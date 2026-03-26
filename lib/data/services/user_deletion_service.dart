import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_endpoints.dart';
import '../services/http_client.dart';

class UserDeletionService {
  final HttpClient _httpClient = HttpClient();

  /// Delete user from backend only (cascade: users_groups, attendance)
  /// Required Roles: super admin, root, regional manager (limited to their region)
  Future<bool> deleteUser(String userId) async {
    try {
      final response = await _httpClient.delete(
        await ApiEndpoints.deleteUser(userId),
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Delete user completely (backend + Supabase auth + all related records)
  /// Required Roles: super admin, root only
  Future<Map<String, dynamic>> deleteUserCompletely(String userId) async {
    try {
      final url = await ApiEndpoints.deleteUserCompletely(userId);
      print('DEBUG: Making DELETE request to: $url');

      final response = await _httpClient.delete(url);

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to completely delete user: ${response.body}');
      }
    } catch (e) {
      print('DEBUG: deleteUserCompletely error: $e');
      throw Exception('Failed to completely delete user: $e');
    }
  }
}
