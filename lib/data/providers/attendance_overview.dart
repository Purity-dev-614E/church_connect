import 'package:flutter/foundation.dart';
import '../models/attendance_overview.dart';
import '../services/attendance_overview.dart';
import 'package:intl/intl.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _service;

  AttendanceProvider(this._service);

  AttendanceOverview? _overview;
  String _period = 'month';
  bool _loading = false;

  String get period => _period;
  AttendanceOverview? get overview => _overview;
  bool get loading => _loading;

  Future<void> loadData({
    String scope = 'overall',
    String? regionId,
    String? groupId,
  }) async {
    _loading = true;
    notifyListeners();

    _overview = await _service.getOverview(
      _period,
      scope: scope,
      regionId: regionId,
      groupId: groupId,
    );

    _loading = false;
    notifyListeners();
  }

  void changePeriod(
      String period, {
        String scope = 'overall',
        String? regionId,
        String? groupId,
      }) {
    _period = period;
    loadData(scope: scope, regionId: regionId, groupId: groupId);
  }

  List<double> get chartRates =>
      _overview?.buckets.map((b) => b.attendanceRate).toList() ?? [];

  List<String> get chartLabels {
    final buckets = _overview?.buckets ?? [];
    if (buckets.isEmpty) return [];

    final dateFormatter = DateFormat('MMM d');
    switch (_period) {
      case 'week':
        const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return buckets.asMap().entries.map((entry) {
          final dayIndex = entry.key % dayLabels.length;
          return dayLabels[dayIndex];
        }).toList();
      case 'month':
        return buckets.asMap().entries
            .map((entry) => 'Week ${entry.key + 1}')
            .toList();
      case 'quarter':
      case 'year':
        return buckets
            .map((bucket) => DateFormat('MMM').format(bucket.startDate))
            .toList();
      default:
        return buckets.map((bucket) {
          final baseLabel = bucket.label.trim().isEmpty
              ? dateFormatter.format(bucket.startDate)
              : bucket.label;
          final start = dateFormatter.format(bucket.startDate);
          final end = dateFormatter.format(bucket.endDate);
          return '$baseLabel ($start-$end)';
        }).toList();
    }
  }
}
