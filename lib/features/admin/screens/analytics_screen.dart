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
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:supabase/supabase.dart';

import '../../../data/models/event_model.dart';

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
  bool _isLoading = true;
  bool _showLineChart = true;

  Map<String, List<double>> _eventAttendance = {};
  Map<String, Map<String, int>> _eventComparison = {};
  Map<String, double> _activityStatus = {};
  final List<Map<String, dynamic>> _eventDetails = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try{
     _eventAttendance = await _EventAttendance() as Map<String, List<double>>;
     _eventComparison = await _groupAttendanceTrends() as Map<String, Map<String, int>>;
     _activityStatus = await _getGroupActivityStatus() as Map<String, double>;

    }catch (e)  {
      print('Error loading analytics: $e');
      CustomNotification(
          message: 'Error loading analytics: $e',
      );
    }

    setState(() => _isLoading = false);
  }
Future<Map<String, int>> _EventAttendance() async {
  final Map<String, int> attendance = {};
  final events = await _eventProvider.fetchEventsByGroup(widget.groupId);

  for (var event in events) {
    final attendedMembers = await _eventProvider.fetchAttendedMembers(event.id);
    attendance[event.title] = attendedMembers.length;
  }
  return attendance;
}

Future<Set<Object>> fetchQuickAnalytics() async {
  EventModel? latestEvent = await _eventProvider.fetchLatestEvent(widget.groupId);
  if (latestEvent != null) {
    print('Latest event title: ${latestEvent.title}');
  }

  final quickStats = await _superProvider.getEventParticipationStats(latestEvent!.id);
  print('Quick stats: $quickStats');
  return {
    quickStats.eventTitle,
    quickStats.eventDate,
    quickStats.totalParticipants,
    quickStats.presentCount,
    quickStats.attendanceRate
  };
}

Future<List<dynamic>> groupDemographics() async {
  final groupDemographics = await _superProvider.getGroupDemographics(widget.groupId);
  print('Gender distribution: ${groupDemographics.genderDistribution}');
  return groupDemographics.genderDistribution;
}

 Future<Map<String, Map<String, int>>> _getGroupActivityStatus() async {
    final groupActivityStatus = await _adminProvider.getGroupMemberActivityStatus(widget.groupId);
    if (groupActivityStatus != null) {
      print('Group activity status: $groupActivityStatus');
      return {
        "statusSummary" : groupActivityStatus['statusSummary'],
        "Active": groupActivityStatus['status_summary']['Active'],
        "Inactive": groupActivityStatus['status_summary']['Inactive'],
        "Total": groupActivityStatus['status_summary']['Total'],

      };
    } else {
      print('No group activity status available.');
      return {};
    }
 }

 Future<Map<String, dynamic>> _groupAttendanceTrends() async {
   final trends = await _adminProvider.getGroupAttendanceByPeriod(widget.groupId, _selectedPeriod);
   print('Group attendance trends: $trends');
   return {
     'eventStats': trends['eventStats'],
     'dailyStats': trends['dailyStats'],
   };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Analytics'),
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final data = snapshot.data!.toList();
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Event: ${data[0]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Date: ${data[1]}'),
                          const SizedBox(height: 8),
                          Text('Total Participants: ${data[2]}'),
                          const SizedBox(height: 8),
                          Text('Present Count: ${data[3]}'),
                          const SizedBox(height: 8),
                          Text('Attendance Rate: ${data[4]}%'),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const Center(child: Text('No quick stats available.'));
                }
              },
            ),
            // Detailed Analytics Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventAttendanceChart(),
                  const SizedBox(height: 16),
                  _buildDemographicsPieChart(),
                  const SizedBox(height: 16),
                  _buildActivityStatusCard(),
                  const SizedBox(height: 16),
                ],
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

  Widget _buildChartToggle() {
    return Row(
      children: [
        const Text('Chart Type: '),
        Switch(
          value: _showLineChart,
          onChanged: (value) {
            setState(() => _showLineChart = value);
          },
        ),
        Text(_showLineChart ? 'Line Chart' : 'Bar Chart'),
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
            const Text('Event Attendance', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            _buildPeriodSelector(), // Add the period selector here
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _groupAttendanceTrends(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final eventStats = snapshot.data!['eventStats'] as Map<String, dynamic>;
                  return SizedBox(
                    height: 300,
                    child: LineChart(
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
                                final index = value.toInt();
                                if (index >= 0 && index < eventStats.keys.length) {
                                  return Text(eventStats.keys.elementAt(index));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: eventStats.entries.map((entry) {
                              final index = eventStats.keys.toList().indexOf(entry.key);
                              return FlSpot(index.toDouble(), (entry.value as num).toDouble());
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
                  );
                } else {
                  return const Center(child: Text('No attendance data available.'));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildDemographicsPieChart() {
   return FutureBuilder<List<dynamic>>(
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
           (sum, item) => sum + int.parse(item['count']),
         );

         return Card(
           child: Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text('Gender Distribution', style: TextStyle(fontSize: 18)),
                 const SizedBox(height: 16),
                 SizedBox(
                   height: 200,
                   child: PieChart(
                     PieChartData(
                       sections: genderData.map((item) {
                         final percentage = (int.parse(item['count']) / total) * 100;
                         return PieChartSectionData(
                           value: percentage,
                           title: '${percentage.toStringAsFixed(1)}%',
                           color: item['gender'] == 'female' ? Colors.pink : Colors.blue,
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

 Widget _buildActivityStatusCard() {
   return FutureBuilder<Map<String, Map<String, int>>>(
     future: _getGroupActivityStatus(),
     builder: (context, snapshot) {
       if (snapshot.connectionState == ConnectionState.waiting) {
         return const Center(child: CircularProgressIndicator());
       } else if (snapshot.hasError) {
         return Center(child: Text('Error: ${snapshot.error}'));
       } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
         final statusSummary = snapshot.data!['statusSummary'] ?? {};
         final active = snapshot.data!['Active'] ?? 0;
         final inactive = snapshot.data!['Inactive'] ?? 0;
         final total = snapshot.data!['Total'] ?? 0;

         return Card(
           child: Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text('Group Activity Status', style: TextStyle(fontSize: 18)),
                 const SizedBox(height: 16),
                 Text('Active Members: $active', style: const TextStyle(fontSize: 16)),
                 const SizedBox(height: 8),
                 Text('Inactive Members: $inactive', style: const TextStyle(fontSize: 16)),
                 const SizedBox(height: 8),
                 Text('Total Members: $total', style: const TextStyle(fontSize: 16)),
               ],
             ),
           ),
         );
       } else {
         return const Center(child: Text('No activity status data available.'));
       }
     },
   );
 }
}