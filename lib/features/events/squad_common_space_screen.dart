import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_avatars.dart';
import '../auth/current_user_notifier.dart';
import 'club_event_model.dart';

/// Screen: Squad Common Space & Captain Event Hub
/// Allows Captain / Master Admin to schedule practice sessions and broadcasts
/// to a shared common space where all squad members can chat and RSVP.
class SquadCommonSpaceScreen extends ConsumerStatefulWidget {
  const SquadCommonSpaceScreen({super.key});

  @override
  ConsumerState<SquadCommonSpaceScreen> createState() =>
      _SquadCommonSpaceScreenState();
}

class _SquadCommonSpaceScreenState
    extends ConsumerState<SquadCommonSpaceScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(clubMessagesProvider.notifier).sendMessage(
          senderName: user.fullName,
          senderRoll: user.rollNumber,
          senderRole: user.isMasterAdmin
              ? 'admin'
              : (user.isCaptain ? 'captain' : 'player'),
          message: text,
          isAnnouncement: false,
        );

    _msgController.clear();
  }

  void _sendQuickReaction(String reaction) {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    ref.read(clubMessagesProvider.notifier).sendMessage(
          senderName: user.fullName,
          senderRoll: user.rollNumber,
          senderRole: user.isMasterAdmin
              ? 'admin'
              : (user.isCaptain ? 'captain' : 'player'),
          message: reaction,
          isAnnouncement: false,
        );
  }

  void _showCreateEventDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateEventSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canManageEvents = user?.isCaptain ?? false;
    final eventsAsync = ref.watch(clubEventsProvider);
    final messagesAsync = ref.watch(clubMessagesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.limeNeon,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Squad Common Space',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          if (canManageEvents)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: AppTheme.limeNeon),
                tooltip: 'Create Practice Session / Event',
                onPressed: () => _showCreateEventDialog(context),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Practice Sessions & Events Header Section ───────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.cardDarker,
              border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.sports_tennis_rounded,
                            size: 16, color: AppTheme.limeNeon),
                        SizedBox(width: 6),
                        Text(
                          'PRACTICE SESSIONS & SQUAD EVENTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.limeNeon,
                          ),
                        ),
                      ],
                    ),
                    if (canManageEvents)
                      GestureDetector(
                        onTap: () => _showCreateEventDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.limeNeon.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.limeNeon.withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            '+ Schedule',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.limeNeon,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                eventsAsync.when(
                  loading: () => const SizedBox(
                    height: 90,
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.limeNeon),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (events) {
                    if (events.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No upcoming sessions scheduled yet. Captain can create one!',
                          style:
                              TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: events.length,
                        itemBuilder: (context, idx) {
                          final ev = events[idx];
                          final isAttending = user != null &&
                              ev.attendees.contains(user.rollNumber);

                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isAttending
                                    ? AppTheme.limeNeon.withValues(alpha: 0.4)
                                    : AppTheme.borderDark,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: ev.eventType == 'practice'
                                            ? AppTheme.limeNeon
                                                .withValues(alpha: 0.2)
                                            : AppTheme.gold
                                                .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        ev.eventType.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: ev.eventType == 'practice'
                                              ? AppTheme.limeNeon
                                              : AppTheme.gold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat('EEE, MMM d')
                                          .format(ev.sessionDate),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                Text(
                                  ev.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textWhite,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        size: 12, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      ev.sessionTime,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textMuted),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        if (user != null) {
                                          ref
                                              .read(
                                                  clubEventsProvider.notifier)
                                              .toggleRsvp(
                                                  ev.id, user.rollNumber);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isAttending
                                              ? AppTheme.limeNeon
                                              : Colors.white
                                                  .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isAttending
                                                  ? Icons.check
                                                  : Icons.add,
                                              size: 12,
                                              color: isAttending
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isAttending
                                                  ? 'Attending (${ev.attendees.length})'
                                                  : 'RSVP (${ev.attendees.length})',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: isAttending
                                                    ? Colors.black
                                                    : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Common Space Chat Stream ────────────────────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.limeNeon)),
              error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.white70))),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Common space is quiet. Say hi to the squad!',
                        style: TextStyle(color: AppTheme.textMuted)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, idx) {
                    final msg = messages[idx];
                    final isMe = user?.rollNumber == msg.senderRoll;
                    final isMaster = msg.senderRole == 'admin' ||
                        msg.senderRoll.toUpperCase() == 'SD-0002';
                    final isCaptain = msg.senderRole == 'captain';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppAvatars.buildAvatar(
                            rollNumber: msg.senderRoll,
                            size: 36,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      msg.senderName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textWhite,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (isMaster)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppTheme.gold
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'MASTER',
                                          style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.gold),
                                        ),
                                      )
                                    else if (isCaptain)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppTheme.limeNeon
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'CAPTAIN',
                                          style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.limeNeon),
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      DateFormat('hh:mm a')
                                          .format(msg.createdAt),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textMutedDark),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: msg.isAnnouncement
                                        ? const Color(0xFF1B2A1C)
                                        : (isMe
                                            ? const Color(0xFF1E2822)
                                            : AppTheme.cardDark),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: msg.isAnnouncement
                                          ? AppTheme.limeNeon
                                              .withValues(alpha: 0.5)
                                          : AppTheme.borderDark,
                                    ),
                                  ),
                                  child: Text(
                                    msg.message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: msg.isAnnouncement
                                          ? AppTheme.limeNeon
                                          : Colors.white,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ── Quick Reactions Bar ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: AppTheme.cardDarker,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _quickReactionPill('🏸 Smash!'),
                  const SizedBox(width: 6),
                  _quickReactionPill('🔥 Ready!'),
                  const SizedBox(width: 6),
                  _quickReactionPill('⏱️ On my way'),
                  const SizedBox(width: 6),
                  _quickReactionPill('💪 In court'),
                  const SizedBox(width: 6),
                  _quickReactionPill('🏆 Match on!'),
                ],
              ),
            ),
          ),

          // ── Bottom Message Input Bar ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppTheme.cardDarker,
              border: Border(top: BorderSide(color: AppTheme.borderDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Message squad or discuss tactics...',
                      hintStyle: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.cardDark,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: AppTheme.borderDark),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: AppTheme.borderDark),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: AppTheme.limeNeon, size: 24),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickReactionPill(String text) {
    return GestureDetector(
      onTap: () => _sendQuickReaction(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}

/// Create Event / Practice Session Sheet for Captain / Master
class _CreateEventSheet extends ConsumerStatefulWidget {
  const _CreateEventSheet();

  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet> {
  final _titleController =
      TextEditingController(text: 'Morning Practice & Smash Drills');
  final _venueController =
      TextEditingController(text: 'Badminton Courts 1 & 2');
  final _notesController = TextEditingController(
      text: 'Focus on clear drops, cross smash, and doubles rotation.');
  String _eventType = 'practice';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool _broadcast = true;

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _createSession() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final timeStr = _selectedTime.format(context);

    final event = ClubEvent(
      id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      eventType: _eventType,
      sessionDate: _selectedDate,
      sessionTime: timeStr,
      venue: _venueController.text.trim(),
      description: _notesController.text.trim(),
      createdByName: user.fullName,
      createdByRoll: user.rollNumber,
      attendees: [user.rollNumber],
      isActive: true,
      createdAt: DateTime.now(),
    );

    ref.read(clubEventsProvider.notifier).createEvent(event);

    if (_broadcast) {
      ref.read(clubMessagesProvider.notifier).sendMessage(
            senderName: user.fullName,
            senderRoll: user.rollNumber,
            senderRole: user.isMasterAdmin
                ? 'admin'
                : (user.isCaptain ? 'captain' : 'player'),
            message:
                '📢 NEW SESSION: "$title" on ${DateFormat('EEE, MMM d').format(_selectedDate)} at $timeStr at ${_venueController.text.trim()}. RSVP your attendance!',
            isAnnouncement: true,
            eventId: event.id,
          );
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session "$title" scheduled & announced!'),
        backgroundColor: const Color(0xFF0F3E28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_rounded,
                    color: AppTheme.limeNeon, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Schedule Event / Practice',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textWhite),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Event Type Selector
            Row(
              children: [
                _typeChip('Practice', 'practice'),
                const SizedBox(width: 8),
                _typeChip('Friendly Match', 'friendly'),
                const SizedBox(width: 8),
                _typeChip('Tournament', 'tournament'),
              ],
            ),
            const SizedBox(height: 14),

            // Title
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Session Title',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.cardDarker,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Date & Time pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (d != null) setState(() => _selectedDate = d);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDarker,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: AppTheme.limeNeon),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEE, MMM d').format(_selectedDate),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (t != null) setState(() => _selectedTime = t);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDarker,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: AppTheme.limeNeon),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Venue
            TextField(
              controller: _venueController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Venue / Courts',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.cardDarker,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Focus & Instructions',
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.cardDarker,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Broadcast Checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Broadcast notification to Common Space chat',
                  style: TextStyle(fontSize: 13, color: Colors.white)),
              value: _broadcast,
              activeColor: AppTheme.limeNeon,
              checkColor: Colors.black,
              onChanged: (val) => setState(() => _broadcast = val ?? true),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.limeNeon,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _createSession,
                child: const Text('Post Session to Club',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final selected = _eventType == value;
    return GestureDetector(
      onTap: () => setState(() => _eventType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.limeNeon.withValues(alpha: 0.2)
              : AppTheme.cardDarker,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppTheme.limeNeon : AppTheme.borderDark),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppTheme.limeNeon : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
