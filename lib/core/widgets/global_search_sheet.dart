import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../navigation/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Global search bottom sheet that searches courses, decks, and materials.
class GlobalSearchSheet extends ConsumerStatefulWidget {
  const GlobalSearchSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) => _SheetBody(scrollController: controller),
      ),
    );
  }

  @override
  ConsumerState<GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends ConsumerState<GlobalSearchSheet> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SheetBody extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _SheetBody({required this.scrollController});

  @override
  ConsumerState<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends ConsumerState<_SheetBody> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<_SearchResult> _results = [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _lastQuery = '';
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final client = Supabase.instance.client;
    final results = <_SearchResult>[];
    final lowerQuery = '%${query.toLowerCase()}%';

    try {
      // Search courses
      final courses = await client
          .from('courses')
          .select('id, title')
          .eq('user_id', userId)
          .ilike('title', lowerQuery)
          .limit(5);
      for (final c in (courses as List)) {
        results.add(_SearchResult(
          id: c['id'] as String,
          title: c['title'] as String,
          subtitle: 'Course',
          type: _ResultType.course,
          icon: Icons.school_rounded,
        ));
      }

      // Search decks
      final decks = await client
          .from('flashcard_decks')
          .select('id, title, courses!inner(title)')
          .eq('user_id', userId)
          .ilike('title', lowerQuery)
          .limit(5);
      for (final d in (decks as List)) {
        final courseTitle =
            (d['courses'] as Map<String, dynamic>?)?['title'] ?? '';
        results.add(_SearchResult(
          id: d['id'] as String,
          title: d['title'] as String,
          subtitle: courseTitle is String ? courseTitle : 'Deck',
          type: _ResultType.deck,
          icon: Icons.style_rounded,
        ));
      }

      // Search materials
      final materials = await client
          .from('materials')
          .select('id, title, course_id, courses!inner(title)')
          .eq('user_id', userId)
          .ilike('title', lowerQuery)
          .limit(5);
      for (final m in (materials as List)) {
        final courseTitle =
            (m['courses'] as Map<String, dynamic>?)?['title'] ?? '';
        results.add(_SearchResult(
          id: m['id'] as String,
          title: m['title'] as String,
          subtitle: courseTitle is String ? courseTitle : 'Material',
          type: _ResultType.material,
          courseId: m['course_id'] as String?,
          icon: Icons.description_rounded,
        ));
      }
    } catch (e) {
      debugPrint('GlobalSearch: search query failed: $e');
    }

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
        _lastQuery = query;
      });
    }
  }

  void _onResultTap(_SearchResult result) {
    Navigator.of(context).pop(); // close sheet
    switch (result.type) {
      case _ResultType.course:
        context.push(Routes.courseDetailPath(result.id));
      case _ResultType.deck:
        context.push(Routes.deckDetailPath(result.id));
      case _ResultType.material:
        if (result.courseId != null) {
          context.push(Routes.materialViewerPath(result.courseId!, result.id));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.immersiveSurface,
        borderRadius: AppRadius.borderRadiusSheet,
        border: Border.all(color: AppColors.immersiveBorder),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryDark,
              ),
              decoration: InputDecoration(
                hintText: 'Search courses, decks, materials...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: Colors.white38,
                ),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Colors.white38, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white38, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.immersiveCard,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                  borderSide: BorderSide(color: AppColors.immersiveBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                  borderSide: BorderSide(color: AppColors.immersiveBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                  borderSide:
                      BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
              ),
              onChanged: _onQueryChanged,
            ),
          ),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _lastQuery.isEmpty
                              ? 'Start typing to search'
                              : 'No results found',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: widget.scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.immersiveBorder,
                          height: 1,
                        ),
                        itemBuilder: (_, index) {
                          final result = _results[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: AppRadius.borderRadiusSm,
                              ),
                              child: Icon(
                                result.icon,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              result.title,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              result.subtitle,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white38,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white24,
                              size: 20,
                            ),
                            onTap: () => _onResultTap(result),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

enum _ResultType { course, deck, material }

class _SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final _ResultType type;
  final IconData icon;
  final String? courseId;

  const _SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    this.courseId,
  });
}
