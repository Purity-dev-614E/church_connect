import 'package:flutter_test/flutter_test.dart';
import 'package:group_management_church_app/data/models/event_model.dart';

void main() {
  group('Leadership Event Tests', () {
    test('Leadership events should be identified correctly', () {
      final leadershipEvent = EventModel(
        id: '1',
        title: 'Leadership Meeting',
        description: 'Test leadership meeting',
        dateTime: DateTime.now(),
        location: 'Conference Room',
        tag: 'leadership',
      );

      final regularEvent = EventModel(
        id: '2',
        title: 'Regular Event',
        description: 'Test regular event',
        dateTime: DateTime.now(),
        location: 'Main Hall',
        tag: 'org',
      );

      expect(leadershipEvent.isLeadershipEvent, isTrue);
      expect(regularEvent.isLeadershipEvent, isFalse);
    });

    test('Leadership events should be filtered out from attendance calculation', () {
      final events = [
        EventModel(
          id: '1',
          title: 'Leadership Meeting',
          description: 'Test leadership meeting',
          dateTime: DateTime.now(),
          location: 'Conference Room',
          tag: 'leadership',
        ),
        EventModel(
          id: '2',
          title: 'Regular Event',
          description: 'Test regular event',
          dateTime: DateTime.now(),
          location: 'Main Hall',
          tag: 'org',
        ),
        EventModel(
          id: '3',
          title: 'Another Leadership Meeting',
          description: 'Another leadership meeting',
          dateTime: DateTime.now(),
          location: 'Board Room',
          tag: 'leadership',
        ),
      ];

      final regularEvents = events.where((event) => !event.isLeadershipEvent).toList();

      expect(regularEvents.length, equals(1));
      expect(regularEvents.first.title, equals('Regular Event'));
    });

    test('Should detect leadership-only events', () {
      final leadershipOnlyEvents = [
        EventModel(
          id: '1',
          title: 'Leadership Meeting',
          description: 'Test leadership meeting',
          dateTime: DateTime.now(),
          location: 'Conference Room',
          tag: 'leadership',
        ),
      ];

      final allEventsAreLeadership = leadershipOnlyEvents.every((event) => event.isLeadershipEvent);
      final hasEvents = leadershipOnlyEvents.isNotEmpty;

      expect(allEventsAreLeadership, isTrue);
      expect(hasEvents, isTrue);
    });
  });
}
