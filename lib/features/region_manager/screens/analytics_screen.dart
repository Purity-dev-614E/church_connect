import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/group_model.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/regional_manager_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/super_admin_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/region_provider.dart';
import 'package:provider/provider.dart';

class RegionManagerAnalyticsScreen extends StatefulWidget {
  final String regionId;

  const RegionManagerAnalyticsScreen({super.key, required this.regionId});

  @override
  State<RegionManagerAnalyticsScreen> createState() =>
      _RegionManagerAnalyticsScreenState();
}

class _RegionManagerAnalyticsScreenState
    extends State<RegionManagerAnalyticsScreen> {
  late RegionalManagerAnalyticsProvider _analyticsProvider;
  late RegionProvider _regionProvider;
  String _selectedPeriod = 'week';
  bool _isLoading = true;
  String? _errorMessage;
  Set<Object> _quickStatsData = {};
  List<double> _regionalAttendanceData = [];
  Map<String, double> _groupAttendanceData = {};
  Map<String, double> _activityStatusData = {};
  Map<String, double> _regionAttendance = {};
  int? _touchedGroupIndex;


  @override
  void initState() {
    super.initState();
    _analyticsProvider = Provider.of<RegionalManagerAnalyticsProvider>(
      context,
      listen: false,
    );
    _regionProvider = Provider.of<RegionProvider>(context, listen: false);
    Future.microtask(() => _loadAnalytics());
  }

  void _applyQuarterlyFilter() {
    setState(() {
      // Example logic: Average recent attendance data
      if (_regionalAttendanceData.isNotEmpty) {
        // Average of every 3 entries
        final List<double> quarterlyData = [];
        for (int i = 0; i < _regionalAttendanceData.length; i += 3) {
          final chunk = _regionalAttendanceData.skip(i).take(3);
          final avg = chunk.isNotEmpty
              ? chunk.reduce((a, b) => a + b) / chunk.length
              : 0.0;
          quarterlyData.add(avg);
        }
        _regionalAttendanceData = quarterlyData;
      }

      // Optionally aggregate group attendance
      if (_groupAttendanceData.isNotEmpty) {
        final aggregated = _groupAttendanceData.map((k, v) =>
            MapEntry(k, (v * 0.9) + 5)); // some smoothing example
        _groupAttendanceData = aggregated;
      }

      // You can also adjust quick stats slightly
      _quickStatsData = _quickStatsData.map((e) {
        if (e is num) return (e * 0.25).round(); // quarter-year scale
        return e;
      }).toSet();
    });
  }


  Future<void> _loadAnalytics() async {
    if (!mounted) return;

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
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load analytics: ${e.toString()}';
      });
      print('Error loading analytics: $e');
      print('Error stack trace: ${StackTrace.current}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleLocalFilterChange() {
    if (_selectedPeriod == 'quarter') {
      _applyQuarterlyFilter();
    } else {
      _loadAnalytics(); // fallback to normal backend calls
    }
  }


  Future<void> _loadQuickStats() async {
    try {
      print('Loading quick stats for region: ${widget.regionId}');
      final quickStats = await _analyticsProvider.getDashboardSummaryForRegion(
        widget.regionId,
      );

      if (quickStats != null) {
        print('Received quick stats: $quickStats');
        if (!mounted) return;
        setState(() {
          _quickStatsData = {
            quickStats.groupCount,
            quickStats.eventCount,
            quickStats.userCount,
            quickStats.attendanceCount ?? 0,
          };
        });
      } else {
        print('No quick stats data available, using default values');
        if (mounted) {
          setState(() {
            _quickStatsData = {0, 0, 0, 0};
          });
        }
      }
    } catch (e) {
      print('Error loading quick stats: $e');
      print('Error stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _quickStatsData = {0, 0, 0, 0};
        });
      }
    }
  }

  Future<void> _loadRegionalAttendance() async {
    try {
      _regionAttendance = {};

      // Load regions
      await _regionProvider.loadRegions();
      final regions = _regionProvider.regions;

      if (regions.isEmpty) {
        throw Exception('No regions available');
      }

      // Load attendance for each region
      for (var region in regions) {
        try {
          final attendanceStats = await _analyticsProvider
              .getOverallAttendanceByPeriodForRegion(
                _selectedPeriod,
                region.id,
              );

          if (attendanceStats?.overallStats?.attendanceRate != null) {
            _regionAttendance[region.name] =
                attendanceStats!.overallStats!.attendanceRate;
          }
        } catch (e) {
          print('Error loading attendance for region ${region.name}: $e');
          // Provide fallback data for regions with missing attendance
          _regionAttendance[region.name] = 0.0;
        }
      }

      // If all regions failed, provide some sample data
      if (_regionAttendance.isEmpty) {
        for (var region in regions) {
          _regionAttendance[region.name] = 0.0;
        }
      }
    } catch (e) {
      print('Error in _loadRegionalAttendance: $e');
      // Don't throw exception, just set empty data
      _regionAttendance = {};
    }
  }

  Future<void> _loadGroupAttendance() async {
    try {
      final allRegionGroups = await _regionProvider.getGroupsByRegion(
        widget.regionId,
      );
      final Map<String, double> groupAttendanceData = {};

      if (allRegionGroups.isEmpty) {
        if (mounted) {
          setState(() => _groupAttendanceData = {});
        }
        return;
      }

      // Launch all requests in parallel
      final futures =
          allRegionGroups.map((group) async {
            try {
              final groupAttendance = await _analyticsProvider
                  .getGroupAttendanceStatsForRegion(group.id);
              return MapEntry(
                group.name,
                groupAttendance?.overallStats?.presentMembers.toDouble() ?? 0.0,
              );
            } catch (e) {
              print('Error loading attendance for group ${group.name}: $e');
              return MapEntry(group.name, 0.0); // fallback
            }
          }).toList();

      // Wait for all requests to finish
      final results = await Future.wait(futures);

      if (!mounted) return;

      setState(() {
        _groupAttendanceData = Map.fromEntries(results);
      });
    } catch (e) {
      print('Error loading group attendance: $e');
      if (mounted) setState(() => _groupAttendanceData = {});
    }
  }

  Future<void> _loadActivityStatus() async {
    try {
      final regionalActivityStatus = await _analyticsProvider.getActivityStatus(
        widget.regionId,
      );

      if (regionalActivityStatus != null) {
        if (!mounted) return;
        setState(() {
          _activityStatusData = {
            'active':
                (regionalActivityStatus.statusSummary?.active?.toDouble() ??
                    0.0),
            'inactive':
                (regionalActivityStatus.statusSummary?.inactive?.toDouble() ??
                    0.0),
          };
        });
      } else {
        print('No activity status data available, using default values');
        if (mounted) {
          setState(() {
            _activityStatusData = {'active': 0.0, 'inactive': 0.0};
          });
        }
      }
    } catch (e) {
      print('Error loading activity status: $e');
      if (mounted) {
        setState(() {
          _activityStatusData = {'active': 0.0, 'inactive': 0.0};
        });
      }
    }
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
                      const SizedBox(height: 24),
                      _buildActivitySummary(),
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

  Widget _buildQuickStatsCard(Set<Object> quickStats) {
    final stats = quickStats.toList();
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
                Text(
                  'Quick Stats',
                  style: TextStyles.heading1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAnalytics,
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Groups',
                    stats[0].toString(),
                    Icons.group_work,
                    AppColors.primaryColor,
                    'Active groups in region',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Events',
                    stats[1].toString(),
                    Icons.event,
                    AppColors.secondaryColor,
                    'Scheduled events',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Members',
                    stats[2].toString(),
                    Icons.people,
                    AppColors.accentColor,
                    'Active members',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Attendance Rate',
                    '${_regionalAttendanceData.isNotEmpty ? _regionalAttendanceData[0].toStringAsFixed(1) : 0}%',
                    Icons.trending_up,
                    AppColors.successColor,
                    'Overall attendance',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyles.bodyText.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyles.heading1.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyles.bodyText.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentColor),
              ),
              child: Column(
                children: [
                  _buildActivityItem(
                    Icons.people,
                    'Member Growth',
                    '${_quickStatsData.isNotEmpty ? (int.parse(_quickStatsData.elementAt(2).toString()) * 0.1).toStringAsFixed(0) : 0} new members this week',
                    AppColors.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityItem(
                    Icons.event,
                    'Event Activity',
                    '${_quickStatsData.isNotEmpty ? (int.parse(_quickStatsData.elementAt(1).toString()) * 0.2).toStringAsFixed(0) : 0} events scheduled this week',
                    AppColors.grey,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityItem(
                    Icons.trending_up,
                    'Attendance Trend',
                    '${_regionalAttendanceData.isNotEmpty ? (_regionalAttendanceData[0] * 1.05).toStringAsFixed(1) : 0}% expected next week',
                    AppColors.successColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyles.bodyText.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
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
                DropdownMenuItem(value: 'quarter', child: Text('Quarterly')), // ✅ new
                DropdownMenuItem(value: 'year', child: Text('Yearly')),
              ],
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
                _handleLocalFilterChange(); // ✅ new helper
              },
            )

          ],
        ),
      ),
    );
  }

  Widget _buildRegionalAttendanceChart(List<double> attendanceData) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regional Attendance Trend',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
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
                      spots:
                          attendanceData.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value);
                          }).toList(),
                      isCurved: true,
                      color: AppColors.primaryColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
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
      ),
    );
  }

  Widget _buildGroupAttendanceChart(Map<String, double> groupAttendance) {
    const double baseBarWidth = 22;
    const double spacing = 22;
    final entries = groupAttendance.entries.toList();
    final int groupCount = entries.length;
    final double chartWidth = groupCount * (baseBarWidth + spacing) + 60;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double rotationAngle = screenWidth < 400 ? -0.8 : -0.4;
    final int labelSkip = groupCount > 10 ? 2 : 1;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Attendance',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 4,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth < screenWidth ? screenWidth : chartWidth,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.start,
                        maxY: 100,
                        gridData: const FlGridData(show: false), // no grid lines
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            left: BorderSide(width: 0.5, color: Colors.grey),
                            bottom: BorderSide(width: 0.5, color: Colors.grey),
                          ),
                        ),
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
                                    index < groupCount &&
                                    index % labelSkip == 0) {
                                  String label = entries[index].key;
                                  if (label.length > 10) {
                                    label = label.substring(0, 10) + '...';
                                  }
                                  return Transform.rotate(
                                    angle: rotationAngle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        label,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final idx = group.x.toInt();
                              if (idx < 0 || idx >= groupCount) return null;
                              final groupName = entries[idx].key;
                              final value = rod.toY.toStringAsFixed(1);
                              return BarTooltipItem(
                                '$groupName\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$value% attendance',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
// update touched index on touch events
                          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                            if (response == null || response.spot == null) {
                              if (_touchedGroupIndex != null) {
                                setState(() {
                                  _touchedGroupIndex = null;
                                });
                              }
                              return;
                            }
                            final touchedIndex = response.spot!.touchedBarGroupIndex;
                            if (_touchedGroupIndex != touchedIndex) {
                              setState(() {
                                _touchedGroupIndex = touchedIndex;
                              });
                            }
                          },
                        ),
                        barGroups: entries.asMap().entries.map((e) {
                          final int index = e.key;
                          final MapEntry<String, double> entry = e.value;
                          final bool isTouched = _touchedGroupIndex != null && _touchedGroupIndex == index;
                          final double barWidth = isTouched ? baseBarWidth + 8 : baseBarWidth;
                          final Color color = isTouched ? AppColors.primaryColor : AppColors.secondaryColor;
                          return BarChartGroupData(
                            x: index,
                            barsSpace: spacing / 2,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                width: barWidth,
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: 100,
                                  color: AppColors.secondaryColor.withOpacity(0.06),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 400),
                    ),
                  ),
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Status',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: activityStatus['active'] ?? 0,
                      title:
                          '${(activityStatus['active'] ?? 0).toStringAsFixed(1)}%',
                      color: AppColors.successColor,
                      radius: 80,
                      titleStyle: TextStyles.heading2,
                    ),
                    PieChartSectionData(
                      value: activityStatus['inactive'] ?? 0,
                      title:
                          '${(activityStatus['inactive'] ?? 0).toStringAsFixed(1)}%',
                      color: AppColors.errorColor,
                      radius: 80,
                      titleStyle: TextStyles.heading2,
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
}
