import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/profile_model.dart';
import '../../data/profile_repository.dart';

/// Provider for the profile repository.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

/// Fetches the current user's profile from Supabase.
///
/// Returns null if no user is authenticated.
/// NOT autoDispose — profile data is used across many screens and should
/// remain cached to avoid flicker on navigation.
final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});
