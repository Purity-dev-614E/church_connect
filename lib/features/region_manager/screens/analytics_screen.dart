import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/core/theme/app_theme.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/regional_manager_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/super_admin_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:provider/provider.dart';

class RegionManagerAnalyticsScreen extends StatefulWidget {
  final String regionId;
  
  const RegionManagerAnalyticsScreen({
    super.key,
    required this.regionId,
  });

  @override
  State<RegionManagerAnalyticsScreen> createState() => _RegionManagerAnalyticsScreenState();
}

class _RegionManagerAnalyticsScreenState extends State<RegionManagerAnalyticsScreen> {
  late RegionalManagerAnalyticsProvider _analyticsProvider;
  late RegionProvider _regionProvider;
  String _selectedPeriod = 'weekly';
  bool _isLoading = true;
  String? _errorMessage;
  Set<Object> _quickStatsData = {};
  List<double> _regionalAttendanceData = [];
  Map<String, double> _groupAttendanceData = {};
  Map<String, double> _activityStatusData = {};

  @override
  void initState() {
    super.initState();
    _analyticsProvider = Provider.of<RegionalManagerAnalyticsProvider>(context, listen: false);
    _regionProvider = Provider.of<RegionProvider>(context, listen: false);
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadQuickStats(),
        _loadRegionalAttendance(),
        _loadGroupAttendance(),
        _loadActivityStatus(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics: ${e.toString()}';
      });
      print('Error loading analytics: $e');
      print('Error stack trace: ${StackTrace.current}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadQuickStats() async {
    try {
      final quickStats = await _analyticsProvider.getDashboardSummaryForRegion(widget.regionId);
      
      if (quickStats != null) {
        setState(() {
          _quickStatsData = {
            quickStats.groupCount,
            quickStats.eventCount,
            quickStats.userCount
          };
        });
      } else {
        throw Exception('No quick stats data available');
      }
    } catch (e) {
      print('Error loading quick stats: $e');
      throw Exception('Failed to load quick stats: ${e.toString()}');
    }
  }

  Future<void> _loadRegionalAttendance() async {
    try {
      final regionalAttendanceStat = await _analyticsProvider.getOverallAttendanceByPeriodForRegion(
        _selectedPeriod,
        widget.regionId,
      );

      if (regionalAttendanceStat?.overallStats?.presentCount != null) {
        setState(() {
          _regionalAttendanceData = [
            regionalAttendanceStat.overallStats.presentCount.toDouble(),
          ];
        });
      } else {
        throw Exception('No regional attendance data available');
      }
    } catch (e) {
      print('Error loading regional attendance: $e');
      throw Exception('Failed to load regional attendance: ${e.toString()}');
    }
  }

  Future<void> _loadGroupAttendance() async {
    try {
      final allRegionGroups = await _regionProvider.getGroupsByRegion(widget.regionId);
      final Map<String, double> groupAttendanceData = {};

      for (var group in allRegionGroups) {
        if (group != null) {
          try {
            final groupAttendance = await _analyticsProvider.getGroupAttendanceStatsForRegion(group.id);
            if (groupAttendance?.overallStats?.presentMembers != null) {
              groupAttendanceData[group.name] = groupAttendance.overallStats.presentMembers.toDouble();
            }
          } catch (e) {
            print('Error loading attendance for group ${group.name}: $e');
            // Continue with other groups even if one fails
          }
        }
      }

      if (groupAttendanceData.isEmpty) {
        throw Exception('No group attendance data available');
      }

      setState(() {
        _groupAttendanceData = groupAttendanceData;
      });
    } catch (e) {
      print('Error loading group attendance: $e');
      throw Exception('Failed to load group attendance: ${e.toString()}');
    }
  }

  Future<void> _loadActivityStatus() async {
    try {
      final regionalActivityStatus = await _analyticsProvider.getActivityStatus(widget.regionId);
      
      if (regionalActivityStatus != null) {
        setState(() {
          _activityStatusData = {
            'active': (regionalActivityStatus['active'] ?? 0).toDouble(),
            'inactive': (regionalActivityStatus['inactive'] ?? 0).toDouble(),
          };
        });
      } else {
        throw Exception('No activity status data available');
      }
    } catch (e) {
      print('Error loading activity status: $e');
      throw Exception('Failed to load activity status: ${e.toString()}');
    }
  }

  Widget _buildQuickStatsCard(Set<Object> quickStats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick Stats', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: quickStats.map((stat) {
                return Column(
                  children: [
                    Text(stat.toString(), style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Stat'),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionalAttendanceChart(List<double> attendanceData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Regional Attendance Trend', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: attendanceData
                          .asMap()
                          .entries
                          .map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
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

  Widget _buildGroupAttendanceChart(Map<String, double> groupAttendance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Attendance', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
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
                          if (index >= 0 && index < groupAttendance.length) {
                            return Text(groupAttendance.keys.elementAt(index));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: groupAttendance.entries.map((entry) {
                    return BarChartGroupData(
                      x: groupAttendance.keys.toList().indexOf(entry.key),
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

  Widget _buildActivityStatusChart(Map<String, double> activityStatus) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Status', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: activityStatus['active'] ?? 0,
                      title: '${(activityStatus['active'] ?? 0).toStringAsFixed(
                          1)}%',
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: activityStatus['inactive'] ?? 0,
                      title: '${(activityStatus['inactive'] ?? 0)
                          .toStringAsFixed(1)}%',
                      color: Colors.red,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RegionalManagerAnalyticsProvider>(
      builder: (context, provider, _) {
        if (_isLoading || provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAnalytics,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Regional Analytics'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAnalytics,
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Quick Analytics'),
                  Tab(text: 'Detailed Analytics'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Quick Analytics Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStatsCard(_quickStatsData),
                    ],
                  ),
                ),
                // Detailed Analytics Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(),
                      const SizedBox(height: 16),
                      _buildRegionalAttendanceChart(_regionalAttendanceData),
                      const SizedBox(height: 16),
                      _buildGroupAttendanceChart(_groupAttendanceData),
                      const SizedBox(height: 16),
                      _buildActivityStatusChart(_activityStatusData),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        const Text('Period: '),
        DropdownButton<String>(
          value: _selectedPeriod,
          items: const [
            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
            DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
          ],
          onChanged: (value) {
            setState(() => _selectedPeriod = value!);
            _loadAnalytics();
          },
        ),
      ],
    );
  }
}