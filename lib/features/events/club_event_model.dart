import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_service.dart';

/// Club Event or Practice Session Model
class ClubEvent {
  final String id;
  final String title;
  final String eventType; // 'practice', 'friendly', 'tournament', 'fitness', 'meeting'
  final DateTime sessionDate;
  final String sessionTime;
  final String venue;
  final String description;
  final String createdByName;
  final String createdByRoll;
  final List<String> attendees;
  final bool isActive;
  final DateTime createdAt;

  const ClubEvent({
    required this.id,
    required this.title,
    required this.eventType,
    required this.sessionDate,
    required this.sessionTime,
    required this.venue,
    required this.description,
    required this.createdByName,
    required this.createdByRoll,
    required this.attendees,
    required this.isActive,
    required this.createdAt,
  });

  factory ClubEvent.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic d) {
      if (d is DateTime) return d;
      if (d != null) {
        final parsed = DateTime.tryParse(d.toString());
        if (parsed != null) return parsed;
      }
      return DateTime.now().add(const Duration(days: 1));
    }

    List<String> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return [];
    }

    return ClubEvent(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Squad Practice Session',
      eventType: map['event_type']?.toString() ?? 'practice',
      sessionDate: parseDate(map['session_date']),
      sessionTime: map['session_time']?.toString() ?? '07:00 AM',
      venue: map['venue']?.toString() ?? 'Badminton Courts 1 & 2',
      description: map['description']?.toString() ?? '',
      createdByName: map['created_by_name']?.toString() ?? 'Captain Sachin',
      createdByRoll: map['created_by_roll']?.toString() ?? 'SD-0001',
      attendees: parseList(map['attendees']),
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'event_type': eventType,
      'session_date':
          '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}',
      'session_time': sessionTime,
      'venue': venue,
      'description': description,
      'created_by_name': createdByName,
      'created_by_roll': createdByRoll,
      'attendees': attendees,
      'is_active': isActive,
    };
  }

  ClubEvent copyWith({
    List<String>? attendees,
  }) {
    return ClubEvent(
      id: id,
      title: title,
      eventType: eventType,
      sessionDate: sessionDate,
      sessionTime: sessionTime,
      venue: venue,
      description: description,
      createdByName: createdByName,
      createdByRoll: createdByRoll,
      attendees: attendees ?? this.attendees,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}

/// Common Space Squad Chat Message Model
class ClubMessage {
  final String id;
  final String senderName;
  final String senderRoll;
  final String senderRole;
  final String message;
  final bool isAnnouncement;
  final String? eventId;
  final DateTime createdAt;

  const ClubMessage({
    required this.id,
    required this.senderName,
    required this.senderRoll,
    required this.senderRole,
    required this.message,
    required this.isAnnouncement,
    this.eventId,
    required this.createdAt,
  });

  factory ClubMessage.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic d) {
      if (d is DateTime) return d;
      if (d != null) {
        final parsed = DateTime.tryParse(d.toString());
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return ClubMessage(
      id: map['id']?.toString() ?? '',
      senderName: map['sender_name']?.toString() ?? 'Squad Member',
      senderRoll: map['sender_roll']?.toString() ?? 'SD-0001',
      senderRole: map['sender_role']?.toString() ?? 'player',
      message: map['message']?.toString() ?? '',
      isAnnouncement: (map['is_announcement'] as bool?) ?? false,
      eventId: map['event_id']?.toString(),
      createdAt: parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_name': senderName,
      'sender_roll': senderRoll,
      'sender_role': senderRole,
      'message': message,
      'is_announcement': isAnnouncement,
      'event_id': eventId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Fallback seed events
final List<ClubEvent> fallbackEvents = [
  ClubEvent(
    id: 'evt-01',
    title: 'Morning Smash & Drops Circuit',
    eventType: 'practice',
    sessionDate: DateTime.now().add(const Duration(days: 1)),
    sessionTime: '07:00 AM - 08:30 AM',
    venue: 'Main Indoor Badminton Hall (Courts 1 & 2)',
    description:
        'Cross-court smash accuracy, fast net taps, and ladder ranking challenges. Bring 2 feather shuttles.',
    createdByName: 'Sachin Jyani',
    createdByRoll: 'SD-0001',
    attendees: ['SD-0001', 'SD-0002', 'SD-0003', 'SD-0008', 'SD-0010'],
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
  ),
  ClubEvent(
    id: 'evt-02',
    title: 'Inter-Squad Ladder Showdown',
    eventType: 'tournament',
    sessionDate: DateTime.now().add(const Duration(days: 3)),
    sessionTime: '05:30 PM - 07:30 PM',
    venue: 'Court 1 (Championship Arena)',
    description:
        'Official 21-point BWF sets. Ranks #1 through #13 active ladder repositioning matches.',
    createdByName: 'Ishan Narayan Shukla',
    createdByRoll: 'SD-0002',
    attendees: ['SD-0002', 'SD-0001', 'SD-0004', 'SD-0007', 'SD-0009', 'SD-0012'],
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
  ),
];

/// Fallback seed messages for the Common Space
final List<ClubMessage> fallbackMessages = [
  ClubMessage(
    id: 'msg-01',
    senderName: 'Sachin Jyani',
    senderRoll: 'SD-0001',
    senderRole: 'captain',
    message:
        '📢 Welcome to the new SmashDeck Common Space! All practice sessions & events will be posted here. Make sure to RSVP your attendance.',
    isAnnouncement: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
  ),
  ClubMessage(
    id: 'msg-02',
    senderName: 'Ishan Narayan Shukla',
    senderRoll: 'SD-0002',
    senderRole: 'admin',
    message:
        '⭐ 6 new squad accounts have been added: Kartikey, Shurit, Sai, Krishna, Shweta, and Manisha! Let us get ready for weekend tournament matches.',
    isAnnouncement: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  ClubMessage(
    id: 'msg-03',
    senderName: 'Marvin Joseph',
    senderRoll: 'SD-0003',
    senderRole: 'player',
    message: '🔥 Ready for tomorrow morning smash drills. Rackets restrung at 28 lbs.',
    isAnnouncement: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  ClubMessage(
    id: 'msg-04',
    senderName: 'Kartikey Shankar',
    senderRoll: 'SD-0008',
    senderRole: 'player',
    message: '🏸 Excited to join the squad! Will be there at 6:50 AM sharp.',
    isAnnouncement: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
  ),
];

/// Club Events State Notifier
class ClubEventsNotifier extends StateNotifier<AsyncValue<List<ClubEvent>>> {
  final SupabaseClient _client;

  ClubEventsNotifier(this._client) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final response = await _client
          .from('club_events')
          .select()
          .order('session_date', ascending: true)
          .timeout(const Duration(seconds: 4));

      final remoteList = (response as List<dynamic>)
          .map((item) => ClubEvent.fromMap(item as Map<String, dynamic>))
          .toList();

      if (remoteList.isEmpty) {
        state = AsyncValue.data(fallbackEvents);
      } else {
        state = AsyncValue.data(remoteList);
      }
    } catch (_) {
      // Local fallback
      state = AsyncValue.data(fallbackEvents);
    }
  }

  Future<void> createEvent(ClubEvent event) async {
    final current = state.value ?? fallbackEvents;
    state = AsyncValue.data([event, ...current]);

    try {
      await _client.from('club_events').insert(event.toMap());
    } catch (_) {}
  }

  Future<void> toggleRsvp(String eventId, String playerRoll) async {
    final current = state.value ?? fallbackEvents;
    final updated = current.map((e) {
      if (e.id != eventId) return e;
      final attendees = List<String>.from(e.attendees);
      if (attendees.contains(playerRoll)) {
        attendees.remove(playerRoll);
      } else {
        attendees.add(playerRoll);
      }
      return e.copyWith(attendees: attendees);
    }).toList();

    state = AsyncValue.data(updated);

    try {
      final ev = updated.firstWhere((e) => e.id == eventId);
      await _client
          .from('club_events')
          .update({'attendees': ev.attendees}).eq('id', eventId);
    } catch (_) {}
  }
}

final clubEventsProvider =
    StateNotifierProvider<ClubEventsNotifier, AsyncValue<List<ClubEvent>>>(
        (ref) {
  final client = ref.watch(supabaseClientProvider);
  return ClubEventsNotifier(client);
});

/// Club Chat Messages State Notifier
class ClubMessagesNotifier
    extends StateNotifier<AsyncValue<List<ClubMessage>>> {
  final SupabaseClient _client;

  ClubMessagesNotifier(this._client) : super(const AsyncValue.loading()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      final response = await _client
          .from('club_messages')
          .select()
          .order('created_at', ascending: false)
          .limit(50)
          .timeout(const Duration(seconds: 4));

      final remoteList = (response as List<dynamic>)
          .map((item) => ClubMessage.fromMap(item as Map<String, dynamic>))
          .toList();

      if (remoteList.isEmpty) {
        state = AsyncValue.data(fallbackMessages);
      } else {
        state = AsyncValue.data(remoteList);
      }
    } catch (_) {
      state = AsyncValue.data(fallbackMessages);
    }
  }

  Future<void> sendMessage({
    required String senderName,
    required String senderRoll,
    required String senderRole,
    required String message,
    bool isAnnouncement = false,
    String? eventId,
  }) async {
    final newMsg = ClubMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      senderRoll: senderRoll,
      senderRole: senderRole,
      message: message,
      isAnnouncement: isAnnouncement,
      eventId: eventId,
      createdAt: DateTime.now(),
    );

    final current = state.value ?? fallbackMessages;
    state = AsyncValue.data([newMsg, ...current]);

    try {
      await _client.from('club_messages').insert({
        'sender_name': senderName,
        'sender_roll': senderRoll,
        'sender_role': senderRole,
        'message': message,
        'is_announcement': isAnnouncement,
        'event_id': eventId,
      });
    } catch (_) {}
  }
}

final clubMessagesProvider =
    StateNotifierProvider<ClubMessagesNotifier, AsyncValue<List<ClubMessage>>>(
        (ref) {
  final client = ref.watch(supabaseClientProvider);
  return ClubMessagesNotifier(client);
});
