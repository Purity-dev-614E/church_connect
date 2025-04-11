import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/user_model.dart';
import 'package:group_management_church_app/data/providers/attendance_provider.dart';
import 'package:group_management_church_app/data/providers/user_provider.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MemberAttendanceScreen extends StatefulWidget {
  final String userId;
  final String? groupId; // Optional: to filter attendance by group

  const MemberAttendanceScreen({
    Key? key,
    required this.userId,
    this.groupId,
  }) : super(key: key);

  @override
  State<MemberAttendanceScreen> createState() => _MemberAttendanceScreenState();
}

class _MemberAttendanceScreenState extends State<MemberAttendanceScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _user;
  List<Map<String, dynamic>> _attendanceRecords = [];
  String _selectedFilter = 'All';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _user = await userProvider.getUserById(widget.userId);
      
      if (_user == null) {
        throw Exception('Failed to load member data');
      }
      
      // Load attendance records
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      _attendanceRecords = await attendanceProvider.getUserAttendanceRecords(widget.userId);
      
      // Filter by group if groupId is provided
      if (widget.groupId != null) {
        _attendanceRecords = _attendanceRecords.where((record) {
          final event = record['event'];
          return event != null && event['group_id'] == widget.groupId;
        }).toList();
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading attendance data: $e';
      });
      print('Error loading attendance data: $e');
    }
  }
  
  List<Map<String, dynamic>> get _filteredRecords {
    if (_selectedFilter == 'All') {
      return _attendanceRecords;
    } else if (_selectedFilter == 'Present') {
      return _attendanceRecords.where((record) {
        final attendance = record['attendance'];
        return attendance != null && attendance['present'] == true;
      }).toList();
    } else if (_selectedFilter == 'Absent') {
      return _attendanceRecords.where((record) {
        final attendance = record['attendance'];
        return attendance != null && attendance['present'] == false;
      }).toList();
    }
    return _attendanceRecords;
  }
  
  double get _attendanceRate {
    if (_attendanceRecords.isEmpty) return 0.0;
    
    int presentCount = _attendanceRecords.where((record) {
      final attendance = record['attendance'];
      return attendance != null && attendance['present'] == true;
    }).length;
    
    return presentCount / _attendanceRecords.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Attendance History',
        showBackButton: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? _buildErrorView()
          : _user == null
            ? _buildNoUserView()
            : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return Column(
      children: [
        // Member info header
        _buildMemberHeader(),
        
        // Filter options
        _buildFilterOptions(),
        
        // Attendance stats
        _buildAttendanceStats(),
        
        // Attendance records list
        Expanded(
          child: _filteredRecords.isEmpty
            ? _buildEmptyState()
            : _buildAttendanceList(),
        ),
      ],
    );
  }
  
  Widget _buildMemberHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _getInitials(_user!.fullName),
              style: TextStyles.heading2.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.fullName,
                  style: TextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _user!.email,
                  style: TextStyles.bodyText.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: TextStyles.bodyText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedFilter,
              isExpanded: true,
              underline: Container(
                height: 1,
                color: AppColors.primaryColor.withOpacity(0.5),
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFilter = newValue;
                  });
                }
              },
              items: <String>['All', 'Present', 'Absent']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttendanceStats() {
    final attendancePercentage = (_attendanceRate * 100).toStringAsFixed(1);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Rate',
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$attendancePercentage%',
                  style: TextStyles.heading2.copyWith(
                    color: _getAttendanceColor(_attendanceRate),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Events',
                  style: TextStyles.bodyText.copyWith(
                    color: AppColors.textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_attendanceRecords.length}',
                  style: TextStyles.heading2.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttendanceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        final attendance = record['attendance'];
        final event = record['event'];
        
        if (event == null) {
          return const SizedBox.shrink();
        }
        
        final isPresent = attendance['present'] == true;
        final eventTitle = event['title'] ?? 'Unknown Event';
        final eventDate = event['date'] != null 
            ? DateFormat('MMM dd, yyyy').format(DateTime.parse(event['date']))
            : 'Unknown Date';
        final eventLocation = event['location'] ?? 'Unknown Location';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isPresent ? AppColors.primaryColor.withOpacity(0.3) : AppColors.errorColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eventTitle,
                        style: TextStyles.heading2.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPresent 
                            ? AppColors.primaryColor.withOpacity(0.1) 
                            : AppColors.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPresent ? 'Present' : 'Absent',
                        style: TextStyles.bodyText.copyWith(
                          color: isPresent ? AppColors.primaryColor : AppColors.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      eventDate,
                      style: TextStyles.bodyText.copyWith(
                        color: AppColors.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.textColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      eventLocation,
                      style: TextStyles.bodyText.copyWith(
                        color: AppColors.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                if (!isPresent && attendance['apology'] != null && attendance['apology'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  Text(
                    'Apology:',
                    style: TextStyles.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    attendance['apology'],
                    style: TextStyles.bodyText.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: AppColors.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyles.heading2.copyWith(
              color: AppColors.textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter != 'All'
                ? 'Try changing the filter to see more records'
                : 'This member has not attended any events yet',
            style: TextStyles.bodyText.copyWith(
              color: AppColors.textColor.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Attendance',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoUserView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off,
              color: AppColors.secondaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Member Not Found',
              style: TextStyles.heading2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find this member\'s profile.',
              style: TextStyles.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    
    List<String> nameParts = fullName.split(' ');
    String initials = '';

    if (nameParts.isNotEmpty) {
      if (nameParts.length >= 2) {
        // Get first letter of first and last name
        initials = nameParts[0][0] + nameParts[nameParts.length - 1][0];
      } else {
        // If only one name, get first two letters or just first letter if name is only one character
        initials = nameParts[0].length > 1 ? nameParts[0].substring(0, 2) : nameParts[0][0];
      }
    }

    return initials.toUpperCase();
  }
  
  Color _getAttendanceColor(double rate) {
    if (rate >= 0.8) {
      return AppColors.buttonColor; // Green for excellent attendance
    } else if (rate >= 0.6) {
      return AppColors.primaryColor; // Blue for good attendance
    } else if (rate >= 0.4) {
      return AppColors.accentColor; // Yellow for average attendance
    } else {
      return AppColors.errorColor; // Red for poor attendance
    }
  }
}