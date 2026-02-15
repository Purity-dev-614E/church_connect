import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_management_church_app/core/constants/app_endpoints.dart';

import 'package:group_management_church_app/core/theme/app_theme.dart';
import 'package:group_management_church_app/data/models/super_analytics_model.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/admin_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/analytics_providers/super_admin_analytics_provider.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/data/providers/group_provider.dart';
import 'package:group_management_church_app/data/services/analytics_services/admin_analytics_service.dart';
import 'package:group_management_church_app/data/services/auth_services.dart';
import 'package:group_management_church_app/data/services/attendance_overview.dart'
    as attendance_services;
import 'package:group_management_church_app/widgets/attendanceChart.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:intl/intl.dart';
import 'package:supabase/supabase.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/event_model.dart';
import '../../../data/providers/attendance_overview.dart'
    as attendance_overview;

class AdminAnalyticsScreen extends StatefulWidget {
  final groupId;
  const AdminAnalyticsScreen({super.key, this.groupId});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService(
      baseUrl: ApiEndpoints.baseUrl,
      token: AuthServices.accessTokenKey
  );
  final EventProvider _eventProvider = EventProvider();
  final GroupProvider _groupProvider = GroupProvider();
  final SuperAdminAnalyticsProvider _superProvider = SuperAdminAnalyticsProvider();
  final AdminAnalyticsProvider _adminProvider = AdminAnalyticsProvider();

  String _selectedPeriod = 'weekly';
  bool _isLoading = false;
  String? _errorMessage;
  bool _showLineChart = true;

  Map<String, List<double>> _eventAttendance = {};
  Map<String, dynamic> _eventComparison = {};
  Map<String, double> _activityStatus = {};
  final List<Map<String, dynamic>> _eventDetails = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    // Don't start loading if already loading
    if (_isLoading && mounted) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await Future.wait([
        _loadEventAttendance(),
        _loadGroupActivityStatus(),
        groupDemographics()

      ]);
    } catch (e) {
      print('Error loading analytics: $e');
      print('Error stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load analytics: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadEventAttendance() async {
    try {
      final allEvents = await _eventProvider.fetchEventsByGroup(widget.groupId);
      if (!mounted) return;

      if (allEvents.isEmpty) {
        setState(() {
          _eventComparison = {};
        });
        return;
      }

      final filteredEvents = allEvents
          .where((event) => _eventMatchesSelectedPeriod(event.dateTime))
          .toList();

      if (filteredEvents.isEmpty) {
        setState(() {
          _eventComparison = {};
        });
        return;
      }

      final summaries = await Future.wait(filteredEvents.map((event) async {
        final attendance = await _eventProvider.fetchEventAttendance(event.id);
        final total = attendance.length;
        final present = attendance.where((record) => record.isPresent).length;
        final absent = total - present;
        final rate = total == 0 ? 0.0 : (present / total) * 100;

        final label = event.title.isNotEmpty
            ? event.title
            : 'Event ${DateFormat('MMM d').format(event.dateTime)}';

        return {
          'label': label,
          'rate': double.parse(rate.toStringAsFixed(1)),
          'present': present,
          'absent': absent,
          'total': total,
        };
      }));

      if (!mounted) return;

      final Map<String, double> eventRates = {
        for (final summary in summaries)
          summary['label'] as String: summary['rate'] as double,
      };

      final Map<String, Map<String, int>> attendanceCounts = {
        for (final summary in summaries)
          summary['label'] as String: {
            'present': summary['present'] as int,
            'absent': summary['absent'] as int,
            'total': summary['total'] as int,
          },
      };

      setState(() {
        _eventComparison = {
          'eventStats': eventRates,
          'counts': attendanceCounts,
        };
      });
    } catch (e) {
      print('Error loading event attendance: $e');
      if (!mounted) return;
      setState(() {
        _eventComparison = {};
        _errorMessage ??= 'Failed to load event attendance: ${e.toString()}';
      });
    }
  }

  bool _eventMatchesSelectedPeriod(DateTime eventDate) {
    final now = DateTime.now();
    if (eventDate.isAfter(now)) return false;

    final differenceInDays = now.difference(eventDate).inDays;
    switch (_selectedPeriod) {
      case 'weekly':
        return differenceInDays <= 7;
      case 'monthly':
        return differenceInDays <= 30;
      case 'yearly':
        return differenceInDays <= 365;
      default:
        return true;
    }
  }

  Future<void> _loadGroupActivityStatus() async {
    try {
      final groupActivityStatus = await _adminProvider.getGroupMemberActivityStatus(widget.groupId);
      
      if (groupActivityStatus != null) {
        if (mounted) {
          setState(() {
            _activityStatus = {
              'active': (groupActivityStatus['status_summary']?['Active'] ?? 0).toDouble(),
              'inactive': (groupActivityStatus['status_summary']?['Inactive'] ?? 0).toDouble(),
            };
          });
        }
      } else {
        print('No group activity status data available, using default values');
        if (mounted) {
          setState(() {
            _activityStatus = {
              'active': 0.0,
              'inactive': 0.0,
            };
          });
        }
      }
    } catch (e) {
      print('Error loading group activity status: $e');
      if (mounted) {
        setState(() {
          _activityStatus = {
            'active': 0.0,
            'inactive': 0.0,
          };
        });
      }
    }
  }

  Future<Set<Object>> fetchQuickAnalytics() async {
    try {
      final latestEvent = await _eventProvider.fetchLatestEvent(widget.groupId);
      
      if (latestEvent == null) {
        throw Exception('No latest event found');
      }

      final quickStats = await _superProvider.getEventParticipationStats(latestEvent.id);
      
      if (quickStats == null) {
        throw Exception('No quick stats available');
      }

      return {
        quickStats.eventTitle,
        quickStats.eventDate,
        quickStats.totalParticipants,
        quickStats.presentCount,
        quickStats.attendanceRate
      };
    } catch (e) {
      print('Error fetching quick analytics: $e');
      throw Exception('Failed to fetch quick analytics: ${e.toString()}');
    }
  }

  Future<List<GenderDistribution>> groupDemographics() async {
    try {
      final groupDemographics = await _superProvider.getGroupDemographics(widget.groupId);

      if (groupDemographics == null || groupDemographics.genderDistribution == null) {
        throw Exception('No demographics data available');
      }

      return groupDemographics.genderDistribution.cast<GenderDistribution>();
    } catch (e) {
      print('Error loading group demographics: $e');
      throw Exception('Failed to load group demographics: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Analytics'),
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
            ]
          ),
        ),
        body: TabBarView(
          children: [
            // Quick Analytics Tab
            FutureBuilder<Set<Object>>(
              future: fetchQuickAnalytics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${snapshot.error}',
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
                  );
                } else if (snapshot.hasData) {
                  final data = snapshot.data!.toList();
                  return _buildQuickStatsCard(snapshot.data!);
                } else {
                  return const Center(child: Text('No quick stats available.'));
                }
              },
            ),
            // Detailed Analytics Tab
            ChangeNotifierProvider<attendance_overview.AttendanceProvider>(
              create: (_) {
                final service = attendance_services.AttendanceService(
                  ApiEndpoints.baseUrl,
                );
                final provider =
                    attendance_overview.AttendanceProvider(service);
                provider.loadData(scope: 'group', groupId: widget.groupId);
                return provider;
              },
              child: Builder(
                builder: (context) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGroupAttendanceOverview(context),
                      const SizedBox(height: 16),
                      _buildEventAttendanceChart(),
                      const SizedBox(height: 16),
                      _buildDemographicsPieChart(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

 Widget _buildEventAttendanceChart() {
   return Card(
     child: Padding(
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text('Event Attendance', style: TextStyles.bodyText),
           const SizedBox(height: 16),
           _buildPeriodSelector(),
           const SizedBox(height: 16),
           FutureBuilder<Map<String, dynamic>>(
             future: Future.value(_eventComparison),
             builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
               } else if (snapshot.hasError) {
                 return Center(child: Text('Error: ${snapshot.error}'));
               }

               final data = snapshot.data ?? {};
               final eventStats =
                   (data['eventStats'] as Map<String, double>?) ?? {};
               final counts =
                   (data['counts'] as Map<String, Map<String, int>>?) ?? {};

               if (eventStats.isEmpty) {
                 return const Center(child: Text('No attendance data available.'));
               }

               final eventLabels = eventStats.keys.toList();

               return SizedBox(
                 height: 320,
                 child: BarChart(
                   BarChartData(
                     alignment: BarChartAlignment.spaceAround,
                     maxY: 100,
                     barTouchData: BarTouchData(
                       enabled: true,
                       touchTooltipData: BarTouchTooltipData(
                         tooltipBgColor: Colors.black87,
                         getTooltipItem: (group, groupIndex, rod, rodIndex) {
                           final label = eventLabels[group.x.toInt()];
                           final count = counts[label];
                           final present = count?['present'] ?? 0;
                           final total = count?['total'] ?? 0;
                           return BarTooltipItem(
                             '$label\n${rod.toY.toStringAsFixed(1)}% attendance\n$present of $total present',
                             const TextStyle(
                               color: Colors.white,
                               fontWeight: FontWeight.w600,
                             ),
                           );
                         },
                       ),
                     ),
                     gridData: const FlGridData(
                       show: true,
                       drawVerticalLine: false,
                     ),
                     borderData: FlBorderData(
                       show: true,
                       border: Border.all(color: Colors.grey.withOpacity(0.3)),
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
                             if (index >= 0 && index < eventLabels.length) {
                               return Padding(
                                 padding: const EdgeInsets.only(top: 8.0),
                                 child: Transform.rotate(
                                   angle: -0.6,
                                   child: Text(
                                     eventLabels[index],
                                     style: Theme.of(context)
                                         .textTheme
                                         .bodySmall
                                         ?.copyWith(fontSize: 10),
                                   ),
                                 ),
                               );
                             }
                             return const SizedBox.shrink();
                           },
                         ),
                       ),
                     ),
                     barGroups: eventStats.entries.map((entry) {
                       final index = eventLabels.indexOf(entry.key);
                       return BarChartGroupData(
                         x: index,
                         barRods: [
                           BarChartRodData(
                             toY: entry.value,
                             color: AppColors.primaryColor,
                             width: 18,
                             borderRadius: BorderRadius.circular(6),
                           ),
                         ],
                       );
                     }).toList(),
                   ),
                 ),
               );
             },
           ),
         ],
       ),
     ),
   );
 }

 Widget _buildDemographicsPieChart() {
   return FutureBuilder<List<GenderDistribution>>(
     future: groupDemographics(),
     builder: (context, snapshot) {
       if (snapshot.connectionState == ConnectionState.waiting) {
         return const Center(child: CircularProgressIndicator());
       } else if (snapshot.hasError) {
         return Center(child: Text('Error: ${snapshot.error}'));
       } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
         final genderData = snapshot.data!;
         final total = genderData.fold<int>(
           0,
           (sum, item) => sum + item.count,
         );

         return Card(
           child: Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                Text('Gender Distribution', style: TextStyles.bodyText),
                 const SizedBox(height: 16),
                 SizedBox(
                   height: 200,
                   child: PieChart(
                     PieChartData(
                       sections: genderData.map((item) {
                         final percentage = (item.count / total) * 100;
                         return PieChartSectionData(
                           value: percentage,
                           title: '${percentage.toStringAsFixed(1)}%',
                           color: item.gender == 'female' ? Colors.pink : Colors.blue,
                         );
                       }).toList(),
                       sectionsSpace: 2,
                       centerSpaceRadius: 40,
                     ),
                   ),
                 ),
               ],
             ),
           ),
         );
       } else {
         return const Center(child: Text('No gender distribution data available.'));
       }
     },
   );
 }

  Widget _buildGroupAttendanceOverview(BuildContext context) {
    final attendanceProvider =
        context.watch<attendance_overview.AttendanceProvider>();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Overview',
              style: TextStyles.heading2.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AttendanceChart(
              periods: const ['week', 'month', 'quarter', 'year'],
              selectedPeriod: attendanceProvider.period,
              labels: attendanceProvider.chartLabels,
              values: attendanceProvider.chartRates,
              isLoading: attendanceProvider.loading,
              onPeriodChange: (value) {
                if (value == null) return;
                attendanceProvider.changePeriod(
                  value,
                  scope: 'group',
                  groupId: widget.groupId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

 // Widget _buildActivityStatusCard() {
 //   return FutureBuilder<Map<String, double>>(
 //     future: Future.value(_activityStatus),
 //     builder: (context, snapshot) {
 //       if (snapshot.connectionState == ConnectionState.waiting) {
 //         return const Center(child: CircularProgressIndicator());
 //       } else if (snapshot.hasError) {
 //         return Center(child: Text('Error: ${snapshot.error}'));
 //       } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
 //         final active = snapshot.data!['active'] ?? 0;
 //         final inactive = snapshot.data!['inactive'] ?? 0;
 //
 //         return Card(
 //           child: Padding(
 //             padding: const EdgeInsets.all(16),
 //             child: Column(
 //               crossAxisAlignment: CrossAxisAlignment.start,
 //               children: [
 //                 const Text('Group Activity Status', style: TextStyle(fontSize: 18)),
 //                 const SizedBox(height: 16),
 //                 Text('Active Members: $active', style: const TextStyle(fontSize: 16)),
 //                 const SizedBox(height: 8),
 //                 Text('Inactive Members: $inactive', style: const TextStyle(fontSize: 16)),
 //               ],
 //             ),
 //           ),
 //         );
 //       } else {
 //         return const Center(child: Text('No activity status data available.'));
 //       }
 //     },
 //   );
 // }

 Widget _buildQuickStatsCard(Set<Object> quickStats) {
   final stats = quickStats.toList();
   // Ensure we have at least 4 elements, pad with 0 if needed
   while (stats.length <= 4) {
     stats.add(0);
   }
   
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
                 'Quick Stats of the last event',
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
                   'Event Name',
                   stats[0].toString(),
                   Icons.group_work,
                   AppColors.primaryColor,
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: _buildStatCard(
                   'Event Date',
                   DateFormat('yyyy-MM-dd').format(DateTime.parse(stats[1].toString())),
                   Icons.event,
                   AppColors.secondaryColor,
                 ),
               ),
             ],
           ),
           const SizedBox(height: 16),
           Row(
             children: [
               Expanded(
                 child: _buildStatCard(
                   'Total Participants',
                   stats[2].toString(),
                   Icons.people,
                   AppColors.accentColor,
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: _buildStatCard(
                   'Members Present',
                   stats[3].toString(),
                   Icons.people,
                   AppColors.accentColor,
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: _buildStatCard(
                   'Attendance Rate',
                   '${stats[4].toString()}%',
                   Icons.trending_up,
                   AppColors.successColor,
                 ),
               ),
             ],
           ),
         ],
       ),
     ),
   );
 }

Widget _buildStatCard(String title, String value, IconData icon, Color color,) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 25, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyles.heading2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyles.bodyText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
}