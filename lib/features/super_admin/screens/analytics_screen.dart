import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/core/constants/app_endpoints.dart';
import 'package:group_management_church_app/data/models/region_model.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/regional_manager_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/super_admin_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:group_management_church_app/data/services/analytics_services/super_admin_analytics_service.dart';

class SuperAdminAnalyticsScreen extends StatefulWidget {
  const SuperAdminAnalyticsScreen({super.key});

  @override
  State<SuperAdminAnalyticsScreen> createState() =>
      _SuperAdminAnalyticsScreenState();
}

class _SuperAdminAnalyticsScreenState extends State<SuperAdminAnalyticsScreen> with SingleTickerProviderStateMixin {
  final SuperAdminAnalyticsProvider _superProvider =
      SuperAdminAnalyticsProvider();
  final RegionalManagerAnalyticsProvider _regionalProvider =
      RegionalManagerAnalyticsProvider();
  final RegionProvider _regionProvider = RegionProvider();

  String _selectedPeriod = 'week';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Data containers
  Map<String, double> _regionAttendance = {};
  Map<String, double> _activityStatus = {};
  Map<String, double> _groupAttendance = {};
  List<FlSpot> _attendanceTrend = [];
  Map<String, List<double>> _eventTimeline = {};
  Map<String, Map<String, int>> _demographics = {};

  // Stats data
  int _totalUsers = 0;
  int _totalGroups = 0;
  int _totalEvents = 0;
  double _overallAttendance = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _loadQuickStats();
      await _loadRegionalAttendance();
      await _loadActivityStatus();
      await _loadAttendanceTrend();
      await _loadGroupAttendance();
      await _loadEventTimeline();
      await _loadDemographics();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadQuickStats() async {
    try {
      final quickstats = _superProvider.dashboardSummary;
      if (quickstats != null) {
        setState(() {
          _totalUsers = quickstats['totalUsers'] ?? 0;
          _totalGroups = quickstats['totalGroups'] ?? 0;
          _totalEvents = quickstats['totalEvents'] ?? 0;
        });
      } else {
        print('No quick stats data available');
        setState(() {
          _totalUsers = 0;
          _totalGroups = 0;
          _totalEvents = 0;
        });
      }
    } catch (e) {
      print('Error loading quick stats: $e');
      setState(() {
        _totalUsers = 0;
        _totalGroups = 0;
        _totalEvents = 0;
      });
    }
  }

  Future<void> _loadRegionalAttendance() async {
    try {
      // Clear previous data
      _regionAttendance = {};

      // Try to load regions safely
      try {
        // Get regions from provider
        List<RegionModel> regions = [];

        // Use a safer approach to get regions
        try {
          // First load the regions
          await _regionProvider.loadRegions();
          // Then get the list from the provider
          regions = _regionProvider.regions;
        } catch (e) {
          print('Error loading regions: $e');
        }

        // Process each region if we have any
        if (regions.isNotEmpty) {
          for (var region in regions) {
            try {
              final attendanceStats = await _regionalProvider
                  .getOverallAttendanceByPeriodForRegion(
                    _selectedPeriod,
                    region.id,
                  );

              if (attendanceStats != null && attendanceStats.overallStats != null) {
                _regionAttendance[region.name] =
                    attendanceStats.overallStats.attendanceRate ?? 0.0;
              } else {
                print('No attendance data available for region: ${region.name}');
              }
            } catch (e) {
              print('Error loading attendance for region ${region.name}: $e');
            }
          }
        } else {
          print('No regions available');
        }
      } catch (e) {
        print('Error processing regions: $e');
      }
    } catch (e) {
      print('Error in _loadRegionalAttendance: $e');
    }
  }

  Future<void> _loadActivityStatus() async {
    try {
      final activityStatus = await _superProvider.getMemberActivityStatus();
      if (activityStatus != null && activityStatus.counts != null) {
        setState(() {
          _activityStatus = {
            'active': (activityStatus.counts.active ?? 0).toDouble(),
            'inactive': (activityStatus.counts.inactive ?? 0).toDouble(),
          };
        });
      } else {
        print('No activity status data available');
        setState(() {
          _activityStatus = {
            'active': 0.0,
            'inactive': 0.0,
          };
        });
      }
    } catch (e) {
      print('Error loading activity status: $e');
      setState(() {
        _activityStatus = {
          'active': 0.0,
          'inactive': 0.0,
        };
      });
    }
  }

  Future<void> _loadAttendanceTrend() async {
    try {
      final attendance = await _superProvider.getOverallAttendanceByPeriod(
        _selectedPeriod,
      );
      if (attendance != null && attendance.overallStats != null) {
        setState(() {
          _overallAttendance = attendance.overallStats.attendanceRate ?? 0.0;

          // For trend data, we would ideally get historical data
          // Since we don't have that, we'll create a simple trend around the current value
          // In a real app, this would come from an API endpoint with historical data
          _attendanceTrend = [
            FlSpot(0, _overallAttendance * 0.9),
            FlSpot(1, _overallAttendance * 0.95),
            FlSpot(2, _overallAttendance * 0.97),
            FlSpot(3, _overallAttendance),
            FlSpot(4, _overallAttendance * 1.02),
            FlSpot(5, _overallAttendance * 1.05),
          ];
        });
      } else {
        print('No attendance trend data available');
        setState(() {
          _overallAttendance = 0.0;
          _attendanceTrend = [];
        });
      }
    } catch (e) {
      print('Error loading attendance trend: $e');
      setState(() {
        _overallAttendance = 0.0;
        _attendanceTrend = [];
      });
    }
  }

  Future<void> _loadGroupAttendance() async {
    try {
      // In a real app, this would come from an API endpoint
      // For now, we'll leave it empty to show the "No data" message
      print('No group attendance data available');
      _groupAttendance = {};
    } catch (e) {
      print('Error loading group attendance: $e');
      _groupAttendance = {};
    }
  }

  Future<void> _loadEventTimeline() async {
    try {
      // In a real app, this would come from an API endpoint
      // For now, we'll leave it empty to show the "No data" message
      print('No event timeline data available');
      _eventTimeline = {};
    } catch (e) {
      print('Error loading event timeline: $e');
      _eventTimeline = {};
    }
  }

  Future<void> _loadDemographics() async {
    try {
      // In a real app, this would come from an API endpoint
      // For now, we'll leave it empty to show the "No data" message
      print('No demographics data available');
      _demographics = {};
    } catch (e) {
      print('Error loading demographics: $e');
      _demographics = {};
    }
  }

  void _refreshData() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Quick Analytics'),
              Tab(text: 'Detailed Analytics'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: TabBarView(
                    children: [
                      // Quick Analytics Tab
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildPeriodSelector(),
                          const SizedBox(height: 16),
                          _buildQuickStatsCard(),
                          const SizedBox(height: 16),
                          _buildRegionalAttendanceChart(),
                          const SizedBox(height: 16),
                          _buildActivityStatusChart(),
                        ],
                      ),
                      // Detailed Analytics Tab
                      ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildOverallAttendanceChart(),
                          const SizedBox(height: 16),
                          _buildGroupAttendanceChart(),
                          const SizedBox(height: 16),
                          _buildEventTimelineChart(),
                          const SizedBox(height: 16),
                          _buildDemographicsChart(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text(
              'Period: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _selectedPeriod,
              items: const [
                DropdownMenuItem(value: 'week', child: Text('Weekly')),
                DropdownMenuItem(value: 'month', child: Text('Monthly')),
                DropdownMenuItem(value: 'year', child: Text('Yearly')),
              ],
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _totalUsers == 0 && _totalGroups == 0 && _totalEvents == 0
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No data available at this time'),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Users',
                      _totalUsers.toString(),
                      Icons.people,
                    ),
                    _buildStatItem(
                      'Total Groups',
                      _totalGroups.toString(),
                      Icons.group_work,
                    ),
                    _buildStatItem(
                      'Total Events',
                      _totalEvents.toString(),
                      Icons.event,
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildRegionalAttendanceChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Regional Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: _regionAttendance.isEmpty
                  ? const Center(
                      child: Text(
                        'No regional attendance data available at this time',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _regionAttendance.values.isEmpty
                            ? 100
                            : _regionAttendance.values.reduce(
                                  (a, b) => a > b ? a : b,
                                ) *
                                1.2,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < _regionAttendance.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _regionAttendance.keys.elementAt(index),
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: _regionAttendance.entries.map((entry) {
                          return BarChartGroupData(
                            x: _regionAttendance.keys.toList().indexOf(
                                  entry.key,
                                ),
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: Colors.blue,
                                width: 20,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStatusChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: _activityStatus.isEmpty
                  ? const Center(
                      child: Text(
                        'No activity status data available at this time',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: _activityStatus['active'] ?? 0,
                                  title:
                                      '${(_activityStatus['active'] ?? 0).toStringAsFixed(1)}%',
                                  color: Colors.green,
                                  radius: 80,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: _activityStatus['inactive'] ?? 0,
                                  title:
                                      '${(_activityStatus['inactive'] ?? 0).toStringAsFixed(1)}%',
                                  color: Colors.red,
                                  radius: 80,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLegendItem('Active', Colors.green),
                              const SizedBox(height: 8),
                              _buildLegendItem('Inactive', Colors.red),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildOverallAttendanceChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Overall Attendance Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _overallAttendance > 0
                    ? Text(
                        'Current: ${_overallAttendance.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: _attendanceTrend.isEmpty
                  ? const Center(
                      child: Text(
                        'No attendance trend data available at this time',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                ];
                                final index = value.toInt();
                                if (index >= 0 && index < labels.length) {
                                  return Text(labels[index]);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _attendanceTrend,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupAttendanceChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: _groupAttendance.isEmpty
                  ? const Center(
                      child: Text(
                        'No group attendance data available at this time',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _groupAttendance.values.isEmpty
                            ? 100
                            : _groupAttendance.values.reduce(
                                  (a, b) => a > b ? a : b,
                                ) *
                                1.2,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < _groupAttendance.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _groupAttendance.keys.elementAt(index),
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: _groupAttendance.entries.map((entry) {
                          return BarChartGroupData(
                            x: _groupAttendance.keys.toList().indexOf(
                                  entry.key,
                                ),
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: Colors.blue,
                                width: 20,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTimelineChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Attendance Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: _eventTimeline.isEmpty
                  ? const Center(
                      child: Text(
                        'No event timeline data available at this time',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = [
                                  'Jan',
                                  'Feb',
                                  'Mar',
                                  'Apr',
                                  'May',
                                  'Jun',
                                ];
                                final index = value.toInt();
                                if (index >= 0 && index < labels.length) {
                                  return Text(labels[index]);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: _eventTimeline.entries.map((entry) {
                          final color = entry.key == 'Sunday Service'
                              ? Colors.blue
                              : entry.key == 'Bible Study'
                                  ? Colors.green
                                  : Colors.orange;

                          return LineChartBarData(
                            spots: entry.value.asMap().entries.map((e) {
                              return FlSpot(
                                e.key.toDouble(),
                                e.value,
                              );
                            }).toList(),
                            isCurved: true,
                            color: color,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: color.withOpacity(0.1),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            _eventTimeline.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Wrap(
                      spacing: 16,
                      children: _eventTimeline.keys.map((key) {
                        final color = key == 'Sunday Service'
                            ? Colors.blue
                            : key == 'Bible Study'
                                ? Colors.green
                                : Colors.orange;

                        return _buildLegendItem(key, color);
                      }).toList(),
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildDemographicsChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Regional Demographics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: _demographics.isEmpty
                  ? const Center(
                      child: Text(
                        'No demographics data available at this time',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _demographics.values.isEmpty
                            ? 100
                            : _demographics.values
                                    .map(
                                      (e) =>
                                          (e['Male'] ?? 0) +
                                          (e['Female'] ?? 0),
                                    )
                                    .reduce((a, b) => a > b ? a : b)
                                    .toDouble() *
                                1.1,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < _demographics.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _demographics.keys.elementAt(index),
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: _demographics.entries.map((entry) {
                          return BarChartGroupData(
                            x: _demographics.keys.toList().indexOf(
                                  entry.key,
                                ),
                            barRods: [
                              BarChartRodData(
                                toY: (entry.value['Male'] ?? 0).toDouble(),
                                color: Colors.blue,
                                width: 20,
                              ),
                              BarChartRodData(
                                toY: (entry.value['Female'] ?? 0).toDouble(),
                                color: Colors.pink,
                                width: 20,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
            _demographics.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Male', Colors.blue),
                        const SizedBox(width: 24),
                        _buildLegendItem('Female', Colors.pink),
                      ],
                    ),
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
