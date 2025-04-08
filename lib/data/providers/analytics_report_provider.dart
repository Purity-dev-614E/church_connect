import 'package:flutter/material.dart';
import 'package:group_management_church_app/data/services/analytics_services.dart';

/// A specialized provider for generating and exporting analytics reports
class AnalyticsReportProvider extends ChangeNotifier {
  // Services
  final AnalyticsServices _analyticsServices = AnalyticsServices();
  
  // State
  bool _isLoading = false;
  String? _errorMessage;
  bool _reportGenerated = false;
  bool _exportCompleted = false;
  
  // Report data
  Map<String, dynamic> _reportData = {};
  String _exportUrl = '';
  String _currentReportType = '';
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get reportGenerated => _reportGenerated;
  bool get exportCompleted => _exportCompleted;
  Map<String, dynamic> get reportData => _reportData;
  String get exportUrl => _exportUrl;
  String get currentReportType => _currentReportType;
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _handleError(String operation, dynamic error) {
    _errorMessage = 'Error $operation: $error';
    debugPrint(_errorMessage);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  void resetReportState() {
    _reportGenerated = false;
    _exportCompleted = false;
    _reportData = {};
    _exportUrl = '';
    notifyListeners();
  }
  
  // SECTION: Report Generation
  
  /// Generate a custom analytics report
  Future<void> generateReport({
    required String reportType,
    required Map<String, dynamic> parameters,
  }) async {
    _setLoading(true);
    _reportGenerated = false;
    _currentReportType = reportType;
    
    try {
      _reportData = await _analyticsServices.generateCustomReport(
        reportType: reportType,
        parameters: parameters,
      );
      _reportGenerated = true;
      _errorMessage = null;
    } catch (error) {
      _handleError('generating report', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Generate a group attendance report
  Future<void> generateGroupAttendanceReport(String groupId) async {
    await generateReport(
      reportType: 'group_attendance',
      parameters: {'group_id': groupId},
    );
  }
  
  /// Generate a member participation report
  Future<void> generateMemberParticipationReport() async {
    await generateReport(
      reportType: 'member_participation',
      parameters: {},
    );
  }
  
  /// Generate a group growth report
  Future<void> generateGroupGrowthReport(String groupId) async {
    await generateReport(
      reportType: 'group_growth',
      parameters: {'group_id': groupId},
    );
  }
  
  /// Generate a demographic analysis report
  Future<void> generateDemographicReport(String groupId) async {
    await generateReport(
      reportType: 'demographics',
      parameters: {'group_id': groupId},
    );
  }
  
  /// Generate a monthly attendance summary report
  Future<void> generateMonthlyAttendanceReport(int year, int month) async {
    await generateReport(
      reportType: 'monthly_attendance',
      parameters: {'year': year, 'month': month},
    );
  }
  
  /// Generate a yearly attendance summary report
  Future<void> generateYearlyAttendanceReport(int year) async {
    await generateReport(
      reportType: 'yearly_attendance',
      parameters: {'year': year},
    );
  }
  
  // SECTION: Report Export
  
  /// Export the current report to a specific format
  Future<void> exportReport({
    required String format,
    Map<String, dynamic>? additionalParameters,
  }) async {
    if (!_reportGenerated) {
      _handleError('exporting report', 'No report has been generated yet');
      return;
    }
    
    _setLoading(true);
    _exportCompleted = false;
    
    try {
      final parameters = {
        'report_type': _currentReportType,
        ...?additionalParameters,
      };
      
      _exportUrl = await _analyticsServices.exportAnalyticsData(
        dataType: _currentReportType,
        format: format,
        parameters: parameters,
      );
      
      _exportCompleted = true;
      _errorMessage = null;
    } catch (error) {
      _handleError('exporting report', error);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Export the current report to CSV format
  Future<void> exportToCsv() async {
    await exportReport(format: 'csv');
  }
  
  /// Export the current report to PDF format
  Future<void> exportToPdf() async {
    await exportReport(format: 'pdf');
  }
  
  /// Export the current report to Excel format
  Future<void> exportToExcel() async {
    await exportReport(format: 'excel');
  }
  
  // SECTION: Report Utilities
  
  /// Check if the current report has data
  bool hasReportData() {
    return _reportGenerated && _reportData.isNotEmpty;
  }
  
  /// Get a specific section from the report data
  Map<String, dynamic>? getReportSection(String sectionName) {
    if (!hasReportData() || !_reportData.containsKey(sectionName)) {
      return null;
    }
    return _reportData[sectionName];
  }
  
  /// Get chart data from the report if available
  List<Map<String, dynamic>>? getChartData(String chartName) {
    if (!hasReportData() || 
        !_reportData.containsKey('charts') || 
        !_reportData['charts'].containsKey(chartName)) {
      return null;
    }
    return List<Map<String, dynamic>>.from(_reportData['charts'][chartName]);
  }
}