import 'dart:convert';
import 'package:group_management_church_app/data/services/http_client.dart';

import '../models/attendance_overview.dart';

class AttendanceService {
  final String baseUrl;
  AttendanceService(this.baseUrl);

  final HttpClient _httpClient = HttpClient();

  Future<AttendanceOverview> getOverview(
      String period, {
        String scope = 'overall',
        String? regionId,
        String? groupId,
      }) async {
    final query = <String, String>{
      'period': period,
      'scope': scope,
    };
    if (scope == 'region' && regionId != null) {
      query['regionId'] = regionId;
    }
    if (scope == 'group' && groupId != null) {
      query['groupId'] = groupId;
    }

    final uri = Uri.parse('$baseUrl/attendance/overview').replace(
      queryParameters: query,
    );

    final response = await _httpClient.get(uri.toString());
    if (response.statusCode != 200) {
      throw Exception('Failed to load overview');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AttendanceOverview.fromJson(json);
  }
}
