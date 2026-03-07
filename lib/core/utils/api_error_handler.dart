class ApiErrorHandler {
  static String getErrorMessage(int statusCode, dynamic responseBody) {
    switch (statusCode) {
      case 400:
        final error = responseBody['error']?.toString() ?? '';
        if (error.contains('leadership')) {
          if (error.contains('must be created using the /api/events/leadership endpoint')) {
            return 'Please select "Leadership Event" type to create this event';
          }
          if (error.contains('This endpoint only accepts leadership events')) {
            return 'Leadership events cannot be created as group events';
          }
          if (error.contains('Only super admin, root, and regional managers can create leadership events')) {
            return 'You do not have permission to create leadership events';
          }
          if (error.contains('target_audience')) {
            return 'Invalid target audience specified for leadership event';
          }
        }
        return 'Invalid request data';
      case 401:
        return 'Please log in to perform this action';
      case 403:
        if (responseBody['error']?.toString().contains('leadership') == true) {
          return 'You do not have permission to access leadership events';
        }
        return 'Access denied - insufficient permissions';
      case 404:
        if (responseBody['error']?.toString().contains('leadership') == true) {
          return 'Leadership event not found';
        }
        return 'Event not found';
      case 500:
        return 'Server error - please try again later';
      default:
        return 'An error occurred (HTTP $statusCode)';
    }
  }

  static String getAttendanceErrorMessage(int statusCode, dynamic responseBody) {
    switch (statusCode) {
      case 400:
        final error = responseBody['error']?.toString() ?? '';
        if (error.contains('leadership')) {
          if (error.contains('must use leadership attendance endpoint')) {
            return 'This is a leadership event - please use the leadership attendance marking';
          }
          if (error.contains('not a leadership event')) {
            return 'This is a regular event - please use the regular attendance marking';
          }
        }
        return 'Invalid attendance data';
      case 403:
        if (responseBody['error']?.toString().contains('leadership') == true) {
          return 'You do not have permission to mark attendance for leadership events';
        }
        return 'Access denied - insufficient permissions';
      case 404:
        return 'Event not found or attendance period has ended';
      case 422:
        final error = responseBody['error']?.toString() ?? '';
        if (error.contains('already marked')) {
          return 'Attendance has already been marked for this user';
        }
        return 'Invalid attendance data';
      default:
        return 'Failed to mark attendance (HTTP $statusCode)';
    }
  }

  static String getParticipantErrorMessage(int statusCode, dynamic responseBody) {
    switch (statusCode) {
      case 400:
        final error = responseBody['error']?.toString() ?? '';
        if (error.contains('target_audience')) {
          return 'Invalid target audience specified';
        }
        if (error.contains('not a leadership event')) {
          return 'Participants can only be fetched for leadership events';
        }
        return 'Invalid request';
      case 403:
        return 'You do not have permission to view event participants';
      case 404:
        return 'Event not found or no participants available';
      default:
        return 'Failed to load participants (HTTP $statusCode)';
    }
  }
}
