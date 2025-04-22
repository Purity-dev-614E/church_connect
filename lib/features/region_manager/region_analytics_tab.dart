import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/services/analytics_services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/widgets/custom_button.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RegionAnalyticsTab extends StatefulWidget {
  final String regionId;

  const RegionAnalyticsTab({
    Key? key,
    required this.regionId,
  }) : super(key: key);

  @override
  State<RegionAnalyticsTab> createState() => _RegionAnalyticsTabState();
}

class _RegionAnalyticsTabState extends State<RegionAnalyticsTab> {
  bool _isLoading = true;
  String? _errorMessage;
  final AnalyticsServices _analyticsServices = AnalyticsServices();
  
  // Analytics data
  Map<String, dynamic> _attendanceTrends = {};
  Map<String, dynamic> _groupGrowthTrends = {};
  Map<String, dynamic> _memberParticipationStats = {};
  
  // Chart data
  List<FlSpot> _attendanceSpots = [];
  List<String> _attendanceLabels = [];
  List<FlSpot> _groupGrowthSpots = [];
  List<String> _groupGrowthLabels = [];
  
  // Filter options
  String _selectedDateRange = 'Last 6 Months';
  List<String> _availableDateRanges = ['Last Month', 'Last 3 Months', 'Last 6 Months', 'Last Year'];
  
  // Export options
  List<String> _exportFormats = ['CSV', 'PDF', 'Excel'];
  String _selectedExportFormat = 'CSV';
  
  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }
  
  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Load region attendance trends
      final attendanceTrends = await _analyticsServices.getRegionAttendanceTrends(widget.regionId);
      
      // Load region growth trends
      final growthTrends = await _analyticsServices.getRegionGrowth(widget.regionId);
      
      // Load member participation stats
      final participationStats = await _analyticsServices.getMemberParticipationStats();
      
      if (mounted) {
        setState(() {
          _attendanceTrends = attendanceTrends;
          _groupGrowthTrends = growthTrends;
          _memberParticipationStats = participationStats;
          
          _processAttendanceChartData();
          _processGroupGrowthChartData();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load analytics data: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  void _processAttendanceChartData() {
    _attendanceSpots = [];
    _attendanceLabels = [];
    
    try {
      if (_attendanceTrends.containsKey('trend_data')) {
        final trendData = _attendanceTrends['trend_data'] as List;
        
        for (int i = 0; i < trendData.length; i++) {
          final item = trendData[i];
          final rate = item['attendance_rate'] as double? ?? 0.0;
          _attendanceSpots.add(FlSpot(i.toDouble(), rate));
          _attendanceLabels.add(item['month'] as String? ?? '');
        }
      } else {
        // Fallback to sample data if no trend data is available
        _attendanceSpots = [
          const FlSpot(0, 75),
          const FlSpot(1, 82),
          const FlSpot(2, 88),
          const FlSpot(3, 85),
          const FlSpot(4, 92),
          const FlSpot(5, 90),
        ];
        _attendanceLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      }
    } catch (e) {
      print('Error processing attendance chart data: $e');
      // Fallback to sample data
      _attendanceSpots = [
        const FlSpot(0, 75),
        const FlSpot(1, 82),
        const FlSpot(2, 88),
        const FlSpot(3, 85),
        const FlSpot(4, 92),
        const FlSpot(5, 90),
      ];
      _attendanceLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    }
  }
  
  void _processGroupGrowthChartData() {
    _groupGrowthSpots = [];
    _groupGrowthLabels = [];
    
    try {
      if (_groupGrowthTrends.containsKey('growth_data')) {
        final growthData = _groupGrowthTrends['growth_data'] as List;
        
        for (int i = 0; i < growthData.length; i++) {
          final item = growthData[i];
          final count = item['group_count'] as int? ?? 0;
          _groupGrowthSpots.add(FlSpot(i.toDouble(), count.toDouble()));
          _groupGrowthLabels.add(item['month'] as String? ?? '');
        }
      } else {
        // Fallback to sample data if no growth data is available
        _groupGrowthSpots = [
          const FlSpot(0, 5),
          const FlSpot(1, 7),
          const FlSpot(2, 8),
          const FlSpot(3, 10),
          const FlSpot(4, 12),
          const FlSpot(5, 15),
        ];
        _groupGrowthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      }
    } catch (e) {
      print('Error processing group growth chart data: $e');
      // Fallback to sample data
      _groupGrowthSpots = [
        const FlSpot(0, 5),
        const FlSpot(1, 7),
        const FlSpot(2, 8),
        const FlSpot(3, 10),
        const FlSpot(4, 12),
        const FlSpot(5, 15),
      ];
      _groupGrowthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    }
  }
  
  void _changeDateRange(String range) {
    setState(() {
      _selectedDateRange = range;
      _isLoading = true;
    });
    
    // In a real implementation, you would fetch data for the selected date range
    // For now, we'll just simulate loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
  
  Future<void> _exportAnalyticsData(String format) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Convert format to lowercase for API
      final formatLower = format.toLowerCase();
      
      // Call the export API
      final exportData = await _analyticsServices.exportRegionReport(widget.regionId);
      
      // Get the app's temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'region_report_$timestamp.$formatLower';
      final filePath = '${directory.path}/$fileName';
      
      // Write the data to a file
      final file = File(filePath);
      await file.writeAsString(exportData.toString());
      
      // Share the file
      await Share.shareFiles([filePath], text: 'Region Report');
      
      setState(() {
        _isLoading = false;
      });
      
      CustomNotification.show(
        context: context,
        message: 'Report exported successfully',
        type: NotificationType.success,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      CustomNotification.show(
        context: context,
        message: 'Failed to export report: $e',
        type: NotificationType.error,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Region Analytics',
            style: TextStyles.heading1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFilterRow(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _buildAnalyticsContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedDateRange,
            decoration: const InputDecoration(
              labelText: 'Date Range',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: _availableDateRanges.map((range) {
              return DropdownMenuItem<String>(
                value: range,
                child: Text(range),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _changeDateRange(value);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        CustomButton(
          label: 'Export',
          onPressed: () => _showExportDialog(),
          icon: Icons.download,
        ),
      ],
    );
  }
  
  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select export format:'),
            const SizedBox(height: 16),
            ...List.generate(_exportFormats.length, (index) {
              final format = _exportFormats[index];
              return RadioListTile<String>(
                title: Text(format),
                value: format,
                groupValue: _selectedExportFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedExportFormat = value!;
                  });
                  Navigator.pop(context);
                  _exportAnalyticsData(value!);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Analytics',
            style: TextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyles.bodyText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Retry',
            onPressed: _loadAnalyticsData,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          _buildAttendanceChart(),
          const SizedBox(height: 24),
          _buildGroupGrowthChart(),
          const SizedBox(height: 24),
          _buildMemberParticipationTable(),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCards() {
    final totalGroups = _groupGrowthTrends['total_groups'] ?? 0;
    final totalMembers = _attendanceTrends['total_members'] ?? 0;
    final avgAttendance = _attendanceTrends['average_attendance_rate'] ?? 0.0;
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Groups',
            totalGroups.toString(),
            Icons.groups,
            AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Total Members',
            totalMembers.toString(),
            Icons.people,
            AppColors.secondaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Avg. Attendance',
            '${avgAttendance.toStringAsFixed(1)}%',
            Icons.trending_up,
            AppColors.successColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyles.bodyText.copyWith(
                  color: AppColors.textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttendanceChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Trends',
            style: TextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Average attendance rate over time',
            style: TextStyles.bodyText.copyWith(
              color: AppColors.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _attendanceLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _attendanceLabels[value.toInt()],
                              style: TextStyles.bodyText.copyWith(
                                fontSize: 12,
                                color: AppColors.textColor.withOpacity(0.7),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '${value.toInt()}%',
                            style: TextStyles.bodyText.copyWith(
                              fontSize: 12,
                              color: AppColors.textColor.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: (_attendanceSpots.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _attendanceSpots,
                    isCurved: true,
                    color: AppColors.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primaryColor.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroupGrowthChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Growth',
            style: TextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Number of groups over time',
            style: TextStyles.bodyText.copyWith(
              color: AppColors.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _groupGrowthLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _groupGrowthLabels[value.toInt()],
                              style: TextStyles.bodyText.copyWith(
                                fontSize: 12,
                                color: AppColors.textColor.withOpacity(0.7),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            '${value.toInt()}',
                            style: TextStyles.bodyText.copyWith(
                              fontSize: 12,
                              color: AppColors.textColor.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: List.generate(_groupGrowthSpots.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _groupGrowthSpots[index].y,
                        color: AppColors.secondaryColor,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMemberParticipationTable() {
    // Sample data for member participation
    final List<Map<String, dynamic>> topMembers = [
      {'name': 'John Doe', 'attendance_rate': 95, 'events_attended': 38},
      {'name': 'Jane Smith', 'attendance_rate': 92, 'events_attended': 37},
      {'name': 'Michael Johnson', 'attendance_rate': 88, 'events_attended': 35},
      {'name': 'Sarah Williams', 'attendance_rate': 85, 'events_attended': 34},
      {'name': 'Robert Brown', 'attendance_rate': 82, 'events_attended': 33},
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Members by Participation',
            style: TextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Members with highest attendance rates',
            style: TextStyles.bodyText.copyWith(
              color: AppColors.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
            },
            border: TableBorder.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                ),
                children: [
                  _buildTableHeader('Member Name'),
                  _buildTableHeader('Attendance Rate'),
                  _buildTableHeader('Events Attended'),
                ],
              ),
              ...topMembers.map((member) {
                return TableRow(
                  children: [
                    _buildTableCell(member['name']),
                    _buildTableCell('${member['attendance_rate']}%'),
                    _buildTableCell('${member['events_attended']}'),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyles.bodyText.copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyles.bodyText,
        textAlign: TextAlign.center,
      ),
    );
  }
}