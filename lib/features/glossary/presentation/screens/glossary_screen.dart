import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/models/glossary_term_model.dart';
import '../providers/glossary_provider.dart';

class GlossaryScreen extends ConsumerStatefulWidget {
  final String courseId;

  const GlossaryScreen({super.key, required this.courseId});

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  /// Map of letter → global key for scroll-to-letter.
  final Map<String, GlobalKey> _letterKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLetter(String letter) {
    final key = _letterKeys[letter];
    if (key?.currentContext != null) {
      HapticFeedback.selectionClick();
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsAsync = ref.watch(glossaryTermsProvider(widget.courseId));

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      appBar: AppBar(
        title: const Text('Glossary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            child: GlassPanel(
              tier: GlassTier.medium,
              borderRadius: AppRadius.borderRadiusPill,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search terms...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: Colors.white38,
                  ),
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.search,
                    color: Colors.white38,
                    size: 20,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                  ),
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Terms list with alphabetical sidebar
          Expanded(
            child: termsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: ShimmerList(count: 8, itemHeight: 70),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    AppErrorHandler.friendlyMessage(e),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (terms) {
                if (terms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 64,
                          color: Colors.white38,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No glossary terms yet',
                          style: AppTypography.h4.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Generate a glossary from your course materials',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _searchQuery.isEmpty
                    ? terms
                    : terms.where((t) =>
                        t.term.toLowerCase().contains(_searchQuery) ||
                        t.definition.toLowerCase().contains(_searchQuery)).toList();

                // Group terms by first letter
                final grouped = <String, List<GlossaryTermModel>>{};
                for (final term in filtered) {
                  final letter = term.term.isNotEmpty
                      ? term.term[0].toUpperCase()
                      : '#';
                  grouped.putIfAbsent(letter, () => []).add(term);
                }
                final sortedLetters = grouped.keys.toList()..sort();

                // Prepare letter keys
                _letterKeys.clear();
                for (final letter in sortedLetters) {
                  _letterKeys[letter] = GlobalKey();
                }

                // All available letters for the sidebar
                final allLetters = <String>{};
                for (final t in terms) {
                  if (t.term.isNotEmpty) {
                    allLetters.add(t.term[0].toUpperCase());
                  }
                }
                final sidebarLetters = allLetters.toList()..sort();

                return Stack(
                  children: [
                    // Main list grouped by letter
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, 36, AppSpacing.huge,
                      ),
                      itemCount: sortedLetters.length,
                      itemBuilder: (context, sectionIndex) {
                        final letter = sortedLetters[sectionIndex];
                        final sectionTerms = grouped[letter]!;
                        return Column(
                          key: _letterKeys[letter],
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Letter header
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.md,
                                bottom: AppSpacing.xs,
                                left: 4,
                              ),
                              child: Text(
                                letter,
                                style: AppTypography.h3.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            // Terms for this letter
                            ...sectionTerms.map((term) => _TermCard(
                                  term: term,
                                )),
                          ],
                        );
                      },
                    ),

                    // Alphabetical sidebar
                    if (_searchQuery.isEmpty && sidebarLetters.length > 1)
                      Positioned(
                        right: 2,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _AlphabetSidebar(
                            letters: sidebarLetters,
                            activeLetters: sortedLetters.toSet(),
                            onLetterTap: _scrollToLetter,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical alphabet sidebar for quick navigation.
class _AlphabetSidebar extends StatelessWidget {
  final List<String> letters;
  final Set<String> activeLetters;
  final ValueChanged<String> onLetterTap;

  const _AlphabetSidebar({
    required this.letters,
    required this.activeLetters,
    required this.onLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: letters.map((letter) {
          final isActive = activeLetters.contains(letter);
          return GestureDetector(
            onTap: isActive ? () => onLetterTap(letter) : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? AppColors.primary
                      : Colors.white38.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TermCard extends StatefulWidget {
  final GlossaryTermModel term;

  const _TermCard({required this.term});

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: GlassPanel(
        tier: GlassTier.medium,
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: AppRadius.borderRadiusXl,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.term.term,
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white38,
                      size: 20,
                    ),
                  ],
                ),

                // Definition (always visible, collapsed by default)
                AnimatedCrossFade(
                  firstChild: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.xs,
                      left: AppSpacing.lg,
                    ),
                    child: Text(
                      widget.term.definition,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      left: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.term.definition,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        if (widget.term.relatedTerms.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xxs,
                            runSpacing: AppSpacing.xxs,
                            children: widget.term.relatedTerms.map((r) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: AppRadius.borderRadiusSm,
                                ),
                                child: Text(
                                  r,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
