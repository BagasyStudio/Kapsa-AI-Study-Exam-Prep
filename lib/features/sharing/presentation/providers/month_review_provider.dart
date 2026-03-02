import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/month_review_repository.dart';
import '../../data/models/month_review_model.dart';

final monthReviewRepositoryProvider = Provider<MonthReviewRepository>((ref) {
  return MonthReviewRepository(Supabase.instance.client);
});

final monthReviewProvider =
    FutureProvider.autoDispose<MonthReviewModel>((ref) async {
  return ref.watch(monthReviewRepositoryProvider).getReview();
});
