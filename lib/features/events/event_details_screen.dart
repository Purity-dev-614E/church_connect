import 'package:flutter/material.dart';
import 'package:group_management_church_app/core/constants/colors.dart';
import 'package:group_management_church_app/core/constants/text_styles.dart';
import 'package:group_management_church_app/data/models/event_model.dart';
import 'package:group_management_church_app/data/providers/auth_provider.dart';
import 'package:group_management_church_app/data/providers/event_provider.dart';
import 'package:group_management_church_app/widgets/custom_app_bar.dart';
import 'package:group_management_church_app/widgets/custom_notification.dart';
import 'package:provider/provider.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final String groupId;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.groupId,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLoading = false;
  bool _hasMarkedAttendance = false;
  bool _isAttending = true; // Default to attending
  
  // Form controllers
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _aobController = TextEditingController();
  final TextEditingController _apologyController = TextEditingController();
  
  // Form keys
  final _attendedFormKey = GlobalKey<FormState>();
  final _notAttendedFormKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _topicController.dispose();
    _aobController.dispose();
    _apologyController.dispose();
    super.dispose();
  }
  
  // Format date nicely
  String _formatEventDate(DateTime dateTime) {
    final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final String weekday = weekdays[dateTime.weekday - 1];
    final String month = months[dateTime.month - 1];
    final String day = dateTime.day.toString();

    String hour = dateTime.hour.toString();
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String amPm = dateTime.hour >= 12 ? 'PM' : 'AM';

    if (dateTime.hour > 12) {
      hour = (dateTime.hour - 12).toString();
    } else if (dateTime.hour == 0) {
      hour = '12';
    }

    return '$weekday, $month $day at $hour:$minute $amPm';
  }
  
  void _showError(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.error,
    );
  }

  void _showSuccess(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.success,
    );
  }

  void _showInfo(String message) {
    CustomNotification.show(
      context: context,
      message: message,
      type: NotificationType.info,
    );
  }
  
  // Submit attendance
  Future<void> _submitAttendance() async {
    // Validate form based on attendance choice
    bool isValid = _isAttending 
        ? _attendedFormKey.currentState!.validate()
        : _notAttendedFormKey.currentState!.validate();
        
    if (!isValid) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        _showError('User not authenticated');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final result = await eventProvider.markAttendance(
        eventId: widget.event.id,
        userId: userId,
        present: _isAttending,
        topic: _isAttending ? _topicController.text : null,
        aob: _isAttending ? _aobController.text : null,
        apology: !_isAttending ? _apologyController.text : null,
      );
      
      if (result) {
        setState(() {
          _hasMarkedAttendance = true;
          _isLoading = false;
        });
        
        if (mounted) {
          _showSuccess(_isAttending 
            ? 'Attendance marked successfully!' 
            : 'Absence recorded successfully!');
        }
      } else {
        if (mounted) {
          _showError('Failed to mark attendance. Please try again.');
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error marking attendance: $e');
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Event Details',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Header
              _buildEventHeader(),
              
              const SizedBox(height: 24),
              
              // Event Details
              _buildEventDetails(),
              
              const SizedBox(height: 32),
              
              // Attendance Section
              _hasMarkedAttendance
                ? _buildAttendanceConfirmation()
                : _buildAttendanceForm(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEventHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.secondaryColor,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              style: TextStyles.heading1.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatEventDate(widget.event.dateTime),
                    style: TextStyles.bodyText.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.location,
                    style: TextStyles.bodyText.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Description',
              style: TextStyles.heading2.copyWith(
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.description,
              style: TextStyles.bodyText,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttendanceForm() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark Your Attendance',
              style: TextStyles.heading2.copyWith(
              ),
            ),
            const SizedBox(height: 16),
            
            // Attendance Options
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceOption(
                    title: 'Attending',
                    icon: Icons.check_circle,
                    color: AppColors.successColor,
                    isSelected: _isAttending,
                    onTap: () {
                      setState(() {
                        _isAttending = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAttendanceOption(
                    title: 'Not Attending',
                    icon: Icons.cancel,
                    color: AppColors.errorColor,
                    isSelected: !_isAttending,
                    onTap: () {
                      setState(() {
                        _isAttending = false;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Form based on selection
            _isAttending
                ? _buildAttendingForm()
                : _buildNotAttendingForm(),
                
            const SizedBox(height: 16),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAttending 
                      ? AppColors.successColor 
                      : AppColors.errorColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isAttending 
                            ? 'Confirm Attendance' 
                            : 'Submit Apology',
                        style: TextStyles.buttonText.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttendanceOption({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyles.bodyText.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttendingForm() {
    return Form(
      key: _attendedFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please provide feedback:',
            style: TextStyles.bodyText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Topic Field
          TextFormField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'Topic Discussed',
              hintText: 'Enter the main topic discussed',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the topic discussed';
              }
              return null;
            },
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          // AOB Field
          TextFormField(
            controller: _aobController,
            decoration: const InputDecoration(
              labelText: 'Any Other Business (AOB)',
              hintText: 'Enter any other business discussed',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotAttendingForm() {
    return Form(
      key: _notAttendedFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please provide an apology:',
            style: TextStyles.bodyText.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Apology Field
          TextFormField(
            controller: _apologyController,
            decoration: const InputDecoration(
              labelText: 'Reason for Absence',
              hintText: 'Enter your reason for not attending',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please provide a reason for your absence';
              }
              return null;
            },
            maxLines: 3,
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttendanceConfirmation() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              _isAttending ? Icons.check_circle : Icons.cancel,
              color: _isAttending ? AppColors.successColor : AppColors.errorColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _isAttending 
                  ? 'You have marked your attendance for this event!' 
                  : 'You have submitted your apology for this event.',
              style: TextStyles.heading2.copyWith(

                color: _isAttending ? AppColors.successColor : AppColors.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _hasMarkedAttendance = false;
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _isAttending ? AppColors.successColor : AppColors.errorColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Change Response',
                style: TextStyles.bodyText.copyWith(
                  color: _isAttending ? AppColors.successColor : AppColors.errorColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}