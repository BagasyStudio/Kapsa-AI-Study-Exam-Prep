import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/navigation/routes.dart';
import '../../../../core/providers/generation_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../../../flashcards/presentation/providers/flashcard_provider.dart';
import '../../../courses/data/models/material_model.dart';
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
  bool _creatingDeck = false;

  /// Map of letter -> global key for scroll-to-letter.
  final Map<String, GlobalKey> _letterKeys = {};

  /// Map of term name (lowercased) -> global key for scroll-to-term.
  final Map<String, GlobalKey> _termKeys = {};

  /// The term name currently highlighted after a related-term tap.
  String? _highlightedTerm;

  /// The letter currently visible at the top of the scroll view.
  String? _currentScrollLetter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Determine which letter section is currently visible at the top.
  void _onScroll() {
    if (_letterKeys.isEmpty) return;

    String? topLetter;
    double topOffset = double.infinity;

    for (final entry in _letterKeys.entries) {
      final key = entry.value;
      if (key.currentContext == null) continue;

      final renderBox = key.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) continue;

      final offset = renderBox.localToGlobal(Offset.zero).dy;
      // Find the section closest to (but not far below) the top of the viewport
      if (offset < 200 && (200 - offset) < topOffset) {
        topOffset = 200 - offset;
        topLetter = entry.key;
      }
    }

    // Fallback: pick the first letter whose section is closest above the viewport top
    if (topLetter == null) {
      double closestBelow = double.infinity;
      for (final entry in _letterKeys.entries) {
        final key = entry.value;
        if (key.currentContext == null) continue;

        final renderBox = key.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.hasSize) continue;

        final offset = renderBox.localToGlobal(Offset.zero).dy;
        if (offset >= 0 && offset < closestBelow) {
          closestBelow = offset;
          topLetter = entry.key;
        }
      }
    }

    if (topLetter != null && topLetter != _currentScrollLetter) {
      setState(() => _currentScrollLetter = topLetter);
    }
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

  /// Scroll to and highlight a related term in the list.
  void _scrollToTerm(String termName, List<GlossaryTermModel> allTerms) {
    final normalized = termName.toLowerCase().trim();

    // Check if the term exists in the glossary
    final exists = allTerms.any((t) => t.term.toLowerCase().trim() == normalized);

    if (!exists) {
      // Show "Not found" tooltip
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"$termName" not found in glossary',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.immersiveCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusMd,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final key = _termKeys[normalized];
    if (key?.currentContext != null) {
      HapticFeedback.selectionClick();

      // Clear search so the term is visible
      if (_searchQuery.isNotEmpty) {
        setState(() => _searchQuery = '');
      }

      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.3,
      ).then((_) {
        // Trigger highlight animation
        setState(() => _highlightedTerm = normalized);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() => _highlightedTerm = null);
          }
        });
      });
    }
  }

  /// Generate a flashcard deck from all glossary terms.
  Future<void> _generateFlashcardsFromGlossary(
      List<GlossaryTermModel> terms) async {
    if (_creatingDeck || terms.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _creatingDeck = true);

    try {
      final repo = ref.read(flashcardRepositoryProvider);
      final course = ref.read(courseProvider(widget.courseId)).valueOrNull;
      final courseName = course?.title ?? 'Course';

      // Create the deck
      final deck = await repo.createDeck(
        courseId: widget.courseId,
        title: 'Glossary \u2014 $courseName',
      );

      // Build flashcard entries: question = term, answer = definition
      final now = DateTime.now().toUtc().toIso8601String();
      final cards = terms
          .map((t) => {
                'deck_id': deck.id,
                'topic': 'Glossary',
                'question_before': '',
                'keyword': t.term,
                'question_after': '',
                'answer': t.definition,
                'mastery': 'new',
                'stability': 0,
                'difficulty': 0,
                'elapsed_days': 0,
                'scheduled_days': 0,
                'reps': 0,
                'lapses': 0,
                'srs_state': 0,
                'due': now,
              })
          .toList();

      await repo.insertCards(cards);

      // Invalidate deck providers so they refresh
      ref.invalidate(flashcardDecksProvider(widget.courseId));
      ref.invalidate(parentDecksProvider(widget.courseId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Created deck with ${terms.length} flashcard${terms.length == 1 ? '' : 's'} from glossary',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusMd,
          ),
        ),
      );

      // Navigate to the new deck detail
      context.push(Routes.deckDetailPath(deck.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorHandler.friendlyMessage(e),
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusMd,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _creatingDeck = false);
    }
  }

  /// Export all glossary terms as formatted text grouped by letter.
  void _exportGlossary(List<GlossaryTermModel> terms) {
    if (terms.isEmpty) return;

    HapticFeedback.mediumImpact();

    // Group terms by first letter
    final grouped = <String, List<GlossaryTermModel>>{};
    for (final term in terms) {
      final letter =
          term.term.isNotEmpty ? term.term[0].toUpperCase() : '#';
      grouped.putIfAbsent(letter, () => []).add(term);
    }
    final sortedLetters = grouped.keys.toList()..sort();

    // Build formatted text
    final buffer = StringBuffer();
    for (final letter in sortedLetters) {
      buffer.writeln('## $letter');
      buffer.writeln();
      for (final term in grouped[letter]!) {
        buffer.writeln('${term.term}: ${term.definition}');
        buffer.writeln();
      }
    }

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  /// Show bottom sheet for adding a new custom term.
  void _showAddTermSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddTermSheet(
        courseId: widget.courseId,
        onTermAdded: () {
          ref.invalidate(glossaryTermsProvider(widget.courseId));
        },
      ),
    );
  }

  /// Show edit dialog for a term (triggered by long-press).
  void _showEditDialog(GlossaryTermModel term) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditTermSheet(
        term: term,
        onTermUpdated: () {
          ref.invalidate(glossaryTermsProvider(widget.courseId));
        },
      ),
    );
  }

  /// Show regenerate options bottom sheet.
  void _showRegenerateOptions() {
    HapticFeedback.mediumImpact();

    final isGenerating = ref.read(generationProvider).any(
      (t) =>
          t.type == GenerationType.glossary &&
          t.courseId == widget.courseId &&
          t.isRunning,
    );

    if (isGenerating) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Glossary generation already in progress',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusMd,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.immersiveSurface.withValues(alpha: 0.95),
          borderRadius: AppRadius.borderRadiusSheet,
          border: Border(
            top: BorderSide(color: AppColors.immersiveBorder, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderRadiusPill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Regenerate Glossary',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose a generation style',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _RegenerateOption(
                icon: Icons.bolt_rounded,
                title: 'Quick',
                subtitle: 'Brief definitions, up to 50 terms',
                color: AppColors.warning,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _triggerRegeneration();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _RegenerateOption(
                icon: Icons.auto_awesome_rounded,
                title: 'Detailed',
                subtitle: 'Comprehensive definitions with examples',
                color: AppColors.primary,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _triggerRegeneration();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _RegenerateOption(
                icon: Icons.filter_alt_rounded,
                title: 'Focus on key terms only',
                subtitle: 'Fewer but more important terms',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _triggerRegeneration();
                },
              ),
              SizedBox(
                height: MediaQuery.of(ctx).padding.bottom + AppSpacing.md,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Trigger glossary regeneration using the generation provider.
  void _triggerRegeneration() {
    HapticFeedback.mediumImpact();

    final course = ref.read(courseProvider(widget.courseId)).valueOrNull;
    final courseName = course?.title ?? 'Course';

    final notifier = ref.read(generationProvider.notifier);
    final started = notifier.generateGlossary(widget.courseId, courseName);

    if (started) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Regenerating glossary...',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusMd,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final termsAsync = ref.watch(glossaryTermsProvider(widget.courseId));
    final materialsAsync =
        ref.watch(courseMaterialsProvider(widget.courseId));
    final materials = materialsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.immersiveBg,
      appBar: AppBar(
        title: const Text('Glossary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Regenerate button — always visible (works with or without terms)
          Builder(
            builder: (context) {
              final isGenerating = ref.watch(generationProvider).any(
                (t) =>
                    t.type == GenerationType.glossary &&
                    t.courseId == widget.courseId &&
                    t.isRunning,
              );
              return IconButton(
                onPressed:
                    isGenerating ? null : () => _showRegenerateOptions(),
                tooltip: 'Regenerate Glossary',
                icon: isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 22),
              );
            },
          ),
          // Flashcards + Export — only when terms exist
          ...termsAsync.maybeWhen(
            data: (terms) => terms.isEmpty
                ? <Widget>[]
                : <Widget>[
                    IconButton(
                      onPressed: _creatingDeck
                          ? null
                          : () => _generateFlashcardsFromGlossary(terms),
                      tooltip: 'Create Flashcards',
                      icon: _creatingDeck
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            )
                          : const Icon(Icons.style_outlined, size: 22),
                    ),
                    IconButton(
                      onPressed: () => _exportGlossary(terms),
                      tooltip: 'Export Glossary',
                      icon: const Icon(Icons.share_outlined, size: 22),
                    ),
                  ],
            orElse: () => <Widget>[],
          ),
        ],
      ),
      floatingActionButton: termsAsync.maybeWhen(
        data: (_) => FloatingActionButton(
          onPressed: () => _showAddTermSheet(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        orElse: () => null,
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
                        const SizedBox(height: AppSpacing.xl),
                        TapScale(
                          onTap: () => _showAddTermSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppRadius.borderRadiusPill,
                            ),
                            child: Text(
                              'Add a term',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
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

                // Prepare term keys (using all terms, not just filtered)
                _termKeys.clear();
                for (final t in terms) {
                  _termKeys[t.term.toLowerCase().trim()] = GlobalKey();
                }

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
                                  key: _termKeys[term.term.toLowerCase().trim()],
                                  term: term,
                                  allTerms: terms,
                                  materials: materials,
                                  courseId: widget.courseId,
                                  isHighlighted: _highlightedTerm ==
                                      term.term.toLowerCase().trim(),
                                  onRelatedTermTap: (relatedName) =>
                                      _scrollToTerm(relatedName, terms),
                                  onLongPress: () => _showEditDialog(term),
                                )),
                          ],
                        );
                      },
                    ),

                    // Alphabetical sidebar — only letters that have terms
                    if (_searchQuery.isEmpty && sortedLetters.length > 1)
                      Positioned(
                        right: 2,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _AlphabetSidebar(
                            letters: sortedLetters,
                            currentLetter: _currentScrollLetter,
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

/// A single option row for the regenerate bottom sheet.
class _RegenerateOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RegenerateOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.borderRadiusXl,
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical alphabet sidebar showing only letters that have terms.
/// Highlights the current scroll-position letter with scale + color.
class _AlphabetSidebar extends StatelessWidget {
  /// Only letters that actually have glossary terms.
  final List<String> letters;

  /// The letter currently visible at the top of the scroll view.
  final String? currentLetter;

  final ValueChanged<String> onLetterTap;

  const _AlphabetSidebar({
    required this.letters,
    required this.currentLetter,
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
          final isCurrent = letter == currentLetter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onLetterTap(letter);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
              child: AnimatedScale(
                scale: isCurrent ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                    color: isCurrent ? AppColors.primary : Colors.white60,
                  ),
                  child: Text(letter),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Term Card
// ---------------------------------------------------------------------------

class _TermCard extends StatefulWidget {
  final GlossaryTermModel term;
  final List<GlossaryTermModel> allTerms;
  final List<MaterialModel> materials;
  final String courseId;
  final bool isHighlighted;
  final ValueChanged<String> onRelatedTermTap;
  final VoidCallback onLongPress;

  const _TermCard({
    super.key,
    required this.term,
    required this.allTerms,
    required this.materials,
    required this.courseId,
    required this.isHighlighted,
    required this.onRelatedTermTap,
    required this.onLongPress,
  });

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant _TermCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _glowController.forward(from: 0.0).then((_) {
        if (mounted) _glowController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  /// Resolve the source material name and build a tappable caption row.
  Widget _buildSourceRow(BuildContext context) {
    final sourceId = widget.term.sourceMaterialId;
    MaterialModel? sourceMaterial;
    if (sourceId != null && sourceId.isNotEmpty) {
      for (final m in widget.materials) {
        if (m.id == sourceId) {
          sourceMaterial = m;
          break;
        }
      }
    }

    final label =
        sourceMaterial?.displayTitle ?? 'Auto-generated';
    final canNavigate = sourceMaterial != null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: GestureDetector(
        onTap: canNavigate
            ? () {
                HapticFeedback.selectionClick();
                context.push(
                  Routes.materialViewerPath(
                    widget.courseId,
                    sourceMaterial!.id,
                  ),
                );
              }
            : null,
        child: Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: 12,
              color: Colors.white38,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Source: $label',
                style: AppTypography.caption.copyWith(
                  color: canNavigate
                      ? AppColors.primary.withValues(alpha: 0.7)
                      : Colors.white38,
                  decoration:
                      canNavigate ? TextDecoration.underline : null,
                  decorationColor:
                      AppColors.primary.withValues(alpha: 0.4),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (canNavigate) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.open_in_new_rounded,
                size: 10,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderRadiusXl,
              boxShadow: _glowAnimation.value > 0
                  ? [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.4 * _glowAnimation.value),
                        blurRadius: 16 * _glowAnimation.value,
                        spreadRadius: 2 * _glowAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
        child: GlassPanel(
          tier: GlassTier.medium,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            onLongPress: widget.onLongPress,
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
                              children:
                                  widget.term.relatedTerms.map((r) {
                                return TapScale(
                                  onTap: () => widget.onRelatedTermTap(r),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius: AppRadius.borderRadiusSm,
                                      border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.2),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.link,
                                          size: 10,
                                          color: AppColors.primary
                                              .withValues(alpha: 0.7),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          r,
                                          style:
                                              AppTypography.caption.copyWith(
                                            color: AppColors.primary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          // Source material link
                          _buildSourceRow(context),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Term Bottom Sheet
// ---------------------------------------------------------------------------

class _AddTermSheet extends ConsumerStatefulWidget {
  final String courseId;
  final VoidCallback onTermAdded;

  const _AddTermSheet({
    required this.courseId,
    required this.onTermAdded,
  });

  @override
  ConsumerState<_AddTermSheet> createState() => _AddTermSheetState();
}

class _AddTermSheetState extends ConsumerState<_AddTermSheet> {
  final _formKey = GlobalKey<FormState>();
  final _termController = TextEditingController();
  final _definitionController = TextEditingController();
  final _relatedController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _termController.dispose();
    _definitionController.dispose();
    _relatedController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final related = _relatedController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final repo = ref.read(glossaryRepositoryProvider);
      await repo.createTerm(
        courseId: widget.courseId,
        term: _termController.text.trim(),
        definition: _definitionController.text.trim(),
        relatedTerms: related,
      );

      widget.onTermAdded();
      if (mounted) {
        Navigator.of(context).pop();
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Term added',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusMd,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorHandler.friendlyMessage(e),
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusMd,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.immersiveSurface.withValues(alpha: 0.95),
        borderRadius: AppRadius.borderRadiusSheet,
        border: Border(
          top: BorderSide(color: AppColors.immersiveBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderRadiusPill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Add Term',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Term field
              _buildTextField(
                controller: _termController,
                hint: 'Term name',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Term is required';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Definition field
              _buildTextField(
                controller: _definitionController,
                hint: 'Definition',
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Definition is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Related terms field
              _buildTextField(
                controller: _relatedController,
                hint: 'Related terms (comma-separated, optional)',
              ),
              const SizedBox(height: AppSpacing.lg),

              // Save button
              SizedBox(
                width: double.infinity,
                child: TapScale(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _saving
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.primary,
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.bodySmall.copyWith(color: Colors.white38),
        filled: true,
        fillColor: AppColors.immersiveCard,
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
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.error),
        ),
        errorStyle: AppTypography.caption.copyWith(color: AppColors.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit Term Bottom Sheet
// ---------------------------------------------------------------------------

class _EditTermSheet extends ConsumerStatefulWidget {
  final GlossaryTermModel term;
  final VoidCallback onTermUpdated;

  const _EditTermSheet({
    required this.term,
    required this.onTermUpdated,
  });

  @override
  ConsumerState<_EditTermSheet> createState() => _EditTermSheetState();
}

class _EditTermSheetState extends ConsumerState<_EditTermSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _termController;
  late final TextEditingController _definitionController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _termController = TextEditingController(text: widget.term.term);
    _definitionController = TextEditingController(text: widget.term.definition);
  }

  @override
  void dispose() {
    _termController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(glossaryRepositoryProvider);
      await repo.updateTerm(
        id: widget.term.id,
        term: _termController.text.trim(),
        definition: _definitionController.text.trim(),
      );

      widget.onTermUpdated();
      if (mounted) {
        Navigator.of(context).pop();
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(
                  'Definition updated ',
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white),
                ),
                const Text('\u2713', style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusMd,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorHandler.friendlyMessage(e),
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.borderRadiusMd,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.immersiveSurface.withValues(alpha: 0.95),
        borderRadius: AppRadius.borderRadiusSheet,
        border: Border(
          top: BorderSide(color: AppColors.immersiveBorder, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderRadiusPill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                'Edit Term',
                style: AppTypography.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Term name field
              TextFormField(
                controller: _termController,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Term is required';
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Term name',
                  hintStyle:
                      AppTypography.bodySmall.copyWith(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.immersiveCard,
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
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  errorStyle:
                      AppTypography.caption.copyWith(color: AppColors.error),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Definition field
              TextFormField(
                controller: _definitionController,
                maxLines: 4,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Definition is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Definition',
                  hintStyle:
                      AppTypography.bodySmall.copyWith(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.immersiveCard,
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
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderRadiusMd,
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  errorStyle:
                      AppTypography.caption.copyWith(color: AppColors.error),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Save button
              SizedBox(
                width: double.infinity,
                child: TapScale(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _saving
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.primary,
                      borderRadius: AppRadius.borderRadiusMd,
                    ),
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save changes',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
