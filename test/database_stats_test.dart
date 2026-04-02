import 'package:flutter_test/flutter_test.dart';
import 'package:group_management_church_app/data/models/database_stats_model.dart';

void main() {
  group('DatabaseStats Model Tests', () {
    test('DatabaseStats should create from JSON correctly', () {
      // Test data matching the backend API response format
      final Map<String, dynamic> json = {
        "totalUsers": 150,
        "totalGroups": 25,
        "totalEvents": 120,
        "overallAttendancePercentage": 78.5,
        "activeGroups": 18,
        "inactiveGroups": 7
      };

      final databaseStats = DatabaseStats.fromJson(json);

      expect(databaseStats.totalUsers, 150);
      expect(databaseStats.totalGroups, 25);
      expect(databaseStats.totalEvents, 120);
      expect(databaseStats.overallAttendancePercentage, 78.5);
      expect(databaseStats.activeGroups, 18);
      expect(databaseStats.inactiveGroups, 7);
    });

    test('DatabaseStats should handle null values gracefully', () {
      final Map<String, dynamic> json = {
        "totalUsers": null,
        "totalGroups": null,
        "totalEvents": null,
        "overallAttendancePercentage": null,
        "activeGroups": null,
        "inactiveGroups": null
      };

      final databaseStats = DatabaseStats.fromJson(json);

      expect(databaseStats.totalUsers, 0);
      expect(databaseStats.totalGroups, 0);
      expect(databaseStats.totalEvents, 0);
      expect(databaseStats.overallAttendancePercentage, 0.0);
      expect(databaseStats.activeGroups, 0);
      expect(databaseStats.inactiveGroups, 0);
    });

    test('DatabaseStats should serialize to JSON correctly', () {
      final databaseStats = DatabaseStats(
        totalUsers: 150,
        totalGroups: 25,
        totalEvents: 120,
        overallAttendancePercentage: 78.5,
        activeGroups: 18,
        inactiveGroups: 7,
      );

      final json = databaseStats.toJson();

      expect(json['totalUsers'], 150);
      expect(json['totalGroups'], 25);
      expect(json['totalEvents'], 120);
      expect(json['overallAttendancePercentage'], 78.5);
      expect(json['activeGroups'], 18);
      expect(json['inactiveGroups'], 7);
    });
  });
}
