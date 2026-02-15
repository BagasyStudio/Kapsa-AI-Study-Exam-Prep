import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/calendar_repository.dart';
import '../../data/models/calendar_event_model.dart';

/// Provider for the calendar repository.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(ref.watch(supabaseClientProvider));
});

/// Fetches events for a specific date for the current user.
final calendarEventsProvider = FutureProvider.autoDispose
    .family<List<CalendarEventModel>, DateTime>((ref, date) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(calendarRepositoryProvider).getEvents(user.id, date);
});
