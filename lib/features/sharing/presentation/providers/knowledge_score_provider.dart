import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/knowledge_score_repository.dart';
import '../../data/models/knowledge_score_model.dart';

final knowledgeScoreRepositoryProvider = Provider<KnowledgeScoreRepository>((ref) {
  return KnowledgeScoreRepository(Supabase.instance.client);
});

final knowledgeScoreProvider =
    FutureProvider.autoDispose<KnowledgeScoreModel>((ref) async {
  return ref.watch(knowledgeScoreRepositoryProvider).calculateScore();
});
