import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/calendar_event_model.dart';

/// Repository for calendar event operations.
class CalendarRepository {
  final SupabaseClient _client;

  CalendarRepository(this._client);

  /// Fetch events for a specific date.
  Future<List<CalendarEventModel>> getEvents(
      String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final data = await _client
        .from('calendar_events')
        .select()
        .eq('user_id', userId)
        .gte('start_time', startOfDay.toIso8601String())
        .lt('start_time', endOfDay.toIso8601String())
        .order('start_time', ascending: true);
    return (data as List)
        .map((e) => CalendarEventModel.fromJson(e))
        .toList();
  }

  /// Create a new event.
  Future<CalendarEventModel> createEvent({
    required String userId,
    String? courseId,
    required String title,
    required String type,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
  }) async {
    final data = await _client
        .from('calendar_events')
        .insert({
          'user_id': userId,
          'course_id': courseId,
          'title': title,
          'type': type,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime?.toIso8601String(),
          'description': description,
        })
        .select()
        .single();
    return CalendarEventModel.fromJson(data);
  }

  /// Update an event.
  Future<void> updateEvent(
    String eventId, {
    String? title,
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
    bool? isCompleted,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (type != null) updates['type'] = type;
    if (startTime != null) updates['start_time'] = startTime.toIso8601String();
    if (endTime != null) updates['end_time'] = endTime.toIso8601String();
    if (description != null) updates['description'] = description;
    if (isCompleted != null) updates['is_completed'] = isCompleted;

    await _client.from('calendar_events').update(updates).eq('id', eventId);
  }

  /// Toggle event completion.
  Future<void> toggleComplete(String eventId, bool isCompleted) async {
    await _client
        .from('calendar_events')
        .update({'is_completed': isCompleted})
        .eq('id', eventId);
  }
}
