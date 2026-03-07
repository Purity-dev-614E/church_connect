// This is a demo file to show how the removed members functionality now works
// This file is for demonstration purposes only and should not be part of the final build

import 'package:group_management_church_app/data/services/member_removal_service.dart';

void main() async {
  // Example of how to fetch removed members with user details
  final removalService = MemberRemovalService();

  try {
    // Example 1: Get removed members for a specific group
    print('Fetching removed members for group...');
    final groupRemovedMembers = await removalService.getGroupRemovedMembers(
      'group-id-here',
    );

    for (final member in groupRemovedMembers) {
      print('Member: ${member.userName} (${member.userEmail})');
      print('Reason: ${member.reason ?? 'No reason provided'}');
      print('Removed at: ${member.removedAt}');
      print('---');
    }

    // Example 2: Get all removed members (admin only)
    print('\nFetching all removed members...');
    final allRemovedMembers = await removalService.getAllRemovedMembers();

    for (final member in allRemovedMembers) {
      print('Member: ${member.userName} (${member.userEmail})');
      print('From group: ${member.groupName}');
      print('---');
    }

    // Example 3: Get user removal history
    print('\nFetching user removal history...');
    final userHistory = await removalService.getUserRemovalHistory(
      'user-id-here',
    );

    for (final member in userHistory) {
      print('Member: ${member.userName} (${member.userEmail})');
      print('From group: ${member.groupName}');
      print('---');
    }
  } catch (e) {
    print('Error: $e');
  }
}
