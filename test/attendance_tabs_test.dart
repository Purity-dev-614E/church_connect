import 'package:flutter_test/flutter_test.dart';
import 'package:group_management_church_app/data/models/attendance_model.dart';
import 'package:group_management_church_app/data/models/user_model.dart';

void main() {
  group('Attendance Tab Interface Tests', () {
    test('Should split absentees by apology status', () {
      // Mock attendance data
      final attendanceWithApology = AttendanceModel(
        eventId: '1',
        userId: 'user1',
        isPresent: false,
        apology: 'Sick',
        aob: null,
        topic: null,
      );

      final attendanceWithoutApology = AttendanceModel(
        eventId: '1',
        userId: 'user2',
        isPresent: false,
        apology: null,
        aob: null,
        topic: null,
      );

      final attendanceWithEmptyApology = AttendanceModel(
        eventId: '1',
        userId: 'user3',
        isPresent: false,
        apology: '',
        aob: null,
        topic: null,
      );

      // Test splitting logic
      final records = [
        {
          'user': UserModel(
            id: 'user1',
            fullName: 'User 1',
            email: 'user1@test.com',
            contact: '1234567890',
            nextOfKin: 'Kin1',
            nextOfKinContact: '0987654321',
            role: 'member',
            gender: 'Male',
            regionId: 'region1',
            regionalID: 'regional1',
          ),
          'attendance': attendanceWithApology,
        },
        {
          'user': UserModel(
            id: 'user2',
            fullName: 'User 2',
            email: 'user2@test.com',
            contact: '1234567891',
            nextOfKin: 'Kin2',
            nextOfKinContact: '0987654322',
            role: 'member',
            gender: 'Female',
            regionId: 'region2',
            regionalID: 'regional2',
          ),
          'attendance': attendanceWithoutApology,
        },
        {
          'user': UserModel(
            id: 'user3',
            fullName: 'User 3',
            email: 'user3@test.com',
            contact: '1234567892',
            nextOfKin: 'Kin3',
            nextOfKinContact: '0987654323',
            role: 'member',
            gender: 'Male',
            regionId: 'region3',
            regionalID: 'regional3',
          ),
          'attendance': attendanceWithEmptyApology,
        },
      ];

      // Simulate the splitting logic from the app
      final withApology =
          records.where((record) {
            final attendance = record['attendance'] as AttendanceModel;
            return attendance.apology != null && attendance.apology!.isNotEmpty;
          }).toList();

      final withoutApology =
          records.where((record) {
            final attendance = record['attendance'] as AttendanceModel;
            return attendance.apology == null || attendance.apology!.isEmpty;
          }).toList();

      expect(withApology.length, equals(1));
      expect(withoutApology.length, equals(2));

      // Check the first record
      expect(
        (withApology.first['user'] as UserModel).fullName,
        equals('User 1'),
      );
      expect(
        (withoutApology.first['user'] as UserModel).fullName,
        equals('User 2'),
      );
    });

    test('Should display apology only when showApology is true', () {
      final attendance = AttendanceModel(
        eventId: '1',
        userId: 'user1',
        isPresent: false,
        apology: 'Family emergency',
        aob: null,
        topic: null,
      );

      // Test UI logic - when showApology is true, apology should be visible
      final showApology = true;
      final displayApology =
          showApology &&
          attendance.apology != null &&
          attendance.apology!.isNotEmpty;

      expect(displayApology, isTrue);
      expect(attendance.apology, equals('Family emergency'));
    });

    test('Should not display apology when showApology is false', () {
      final attendance = AttendanceModel(
        eventId: '1',
        userId: 'user1',
        isPresent: false,
        apology: null,
        aob: null,
        topic: null,
      );

      // Test UI logic - when showApology is false, apology should not be visible
      final showApology = false;
      final displayApology =
          showApology &&
          attendance.apology != null &&
          attendance.apology!.isNotEmpty;

      expect(displayApology, isFalse);
    });

    test('Should handle empty apology correctly', () {
      final attendance = AttendanceModel(
        eventId: '1',
        userId: 'user1',
        isPresent: false,
        apology: '',
        aob: null,
        topic: null,
      );

      // Test UI logic - empty string should not display
      final showApology = true;
      final displayApology =
          showApology &&
          attendance.apology != null &&
          attendance.apology!.isNotEmpty;

      expect(displayApology, isFalse);
    });
  });
}
