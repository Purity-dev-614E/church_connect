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
        ApiEndpoints.deleteUser(userId),
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
      final response = await _httpClient.delete(
        ApiEndpoints.deleteUserCompletely(userId),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to completely delete user: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to completely delete user: $e');
    }
  }
}
