import 'dart:async';

import 'package:everslot/core/providers.dart';
import 'package:everslot/design_system/design_system.dart';
import 'package:everslot/features/checklists/application/providers.dart';
import 'package:everslot/features/checklists/domain/collation.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot/features/habits/application/habit_providers.dart';
import 'package:everslot/features/habits/domain/habit.dart';
import 'package:everslot/features/habits/presentation/check_in_sheets.dart';
import 'package:everslot/features/organization/application/providers.dart';
import 'package:everslot/features/search/application/search_providers.dart';
import 'package:everslot/features/search/domain/search_models.dart';
import 'package:everslot/features/search/domain/search_syntax.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Global search (T8.1.14–15): debounced full-text search over every section, results grouped by
/// kind with *see all*, highlighted matches and breadcrumbs; filter chips, recent searches and
/// inline actions (complete an item, check in a habit). Tapping a result opens its deep link.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.initialQuery, super.key});

  final String? initialQuery;

  /// Results shown per group before *see all*.
  static const perGroup = 4;

  static const debounce = Duration(milliseconds: 150);

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery ?? '');
  Timer? _debounce;
  SearchFilters _filters = const SearchFilters();
  List<SearchResult>? _results;
  String _shownQuery = '';
  ParsedQuery _parsed = const ParsedQuery();
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    if (_controller.text.trim().isNotEmpty) unawaited(_run());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(SearchScreen.debounce, () => unawaited(_run()));
  }

  Future<void> _run() async {
    final query = _controller.text.trim();
    final parsed = SearchSyntax.parse(query);
    final generation = ++_generation;
    if (query.isEmpty) {
      setState(() {
        _results = null;
        _shownQuery = '';
        _parsed = parsed;
      });
      return;
    }
    final results = parsed.text.isEmpty
        ? const <SearchResult>[]
        : await ref.read(globalSearchQueriesProvider).search(parsed.text, kinds: _effective(parsed).kinds);
    if (!mounted || generation != _generation) return;
    setState(() {
      _results = results;
      _shownQuery = query;
      _parsed = parsed;
    });
  }

  /// Chip filters with the query's `key:value` tokens applied (T8.1.16).
  SearchFilters _effective(ParsedQuery parsed) {
    if (!parsed.hasFilters) return _filters;
    String? byName<T>(List<T> all, String Function(T) name, String Function(T) id, String wanted) {
      final key = Collation.key(wanted);
      return [
        for (final x in all)
          if (Collation.key(name(x)) == key) id(x),
      ].firstOrNull;
    }

    final tags = ref.read(tagsProvider).value ?? const [];
    final categories = ref.read(categoriesProvider).value ?? const [];
    return parsed.applyTo(
      _filters,
      today: ref
          .read(zoneResolverProvider)
          .toLocal(ref.read(clockProvider).nowUtc(), ref.read(deviceZoneProvider))
          .date,
      tagIdOf: (n) => byName(tags, (t) => t.name, (t) => t.id, n),
      categoryIdOf: (n) => byName(categories, (c) => c.name, (c) => c.id, n),
    );
  }

  void _removeToken(QueryToken t) {
    final text = _controller.text;
    final end = t.end < text.length && text[t.end] == ' ' ? t.end + 1 : t.end;
    _useQuery(text.replaceRange(t.start, end, '').trim());
  }

  void _setFilters(SearchFilters next) {
    setState(() => _filters = next);
    unawaited(_run());
  }

  void _useQuery(String q) {
    _controller
      ..text = q
      ..selection = TextSelection.collapsed(offset: q.length);
    unawaited(_run());
  }

  Future<void> _open(SearchResult r) async {
    unawaited(ref.read(searchRecentsProvider.notifier).add(_shownQuery));
    final link = r.link;
    if (link != null) await context.push(link);
  }

  Future<void> _complete(SearchResult r) async {
    final checklistId = r.parentId;
    if (checklistId == null) return;
    final l = context.l10n;
    final record = await ref.read(checklistServiceProvider).changeStatus(checklistId, [r.id], ItemStatus.completed);
    if (record != null && mounted) {
      showUndoSnackBar(context, ref, message: l.searchItemCompleted(r.title), record: record);
    }
    await _run();
  }

  Future<void> _checkIn(SearchResult r) async {
    final habit = await ref.read(habitsRepositoryProvider).byId(r.id);
    if (habit is! BuildHabit || !mounted) return;
    await CheckInActions(context, ref).checkNow(habit);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final query = _controller.text.trim();
    final filters = _effective(_parsed);
    final visible = _results?.where(filters.matches).toList();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const ValueKey('search-field'),
          controller: _controller,
          autofocus: widget.initialQuery == null,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: l.searchHint, border: InputBorder.none),
          onChanged: _onChanged,
          onSubmitted: (q) {
            _debounce?.cancel();
            unawaited(_run());
            unawaited(ref.read(searchRecentsProvider.notifier).add(q));
          },
        ),
        actions: [
          IconButton(
            key: const ValueKey('search-syntax-help'),
            tooltip: l.searchSyntaxHelp,
            icon: const Icon(Icons.help_outline),
            onPressed: () => unawaited(
              showAppSheet<void>(
                context,
                title: l.searchSyntaxHelp,
                builder: (_) => Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(Space.lg, 0, Space.lg, Space.lg),
                  child: Text(l.searchSyntaxHelpBody),
                ),
              ),
            ),
          ),
          if (query.isNotEmpty)
            IconButton(
              key: const ValueKey('search-clear'),
              tooltip: l.actionClear,
              icon: const Icon(Icons.close),
              onPressed: () => _useQuery(''),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchFilterBar(filters: _filters, onChanged: _setFilters),
          if (_parsed.tokens.isNotEmpty || _parsed.errors.isNotEmpty)
            QuerySyntaxBar(parsed: _parsed, onRemove: _removeToken),
          Expanded(
            child: switch (visible) {
              null when query.isEmpty => _RecentSearches(onPick: _useQuery),
              null => const Center(child: CircularProgressIndicator()),
              [] when _parsed.text.isEmpty => EmptyState(icon: Icons.manage_search, title: l.searchSyntaxNeedsWords),
              [] => EmptyState(icon: Icons.search_off, title: l.searchNoResults(_shownQuery)),
              final rows => _GroupedResults(
                results: rows,
                query: _parsed.text,
                expanded: filters.kinds.length == 1,
                onSeeAll: (kind) => _setFilters(_filters.copyWith(kinds: {kind})),
                onOpen: (r) => unawaited(_open(r)),
                onComplete: (r) => unawaited(_complete(r)),
                onCheckIn: (r) => unawaited(_checkIn(r)),
              ),
            },
          ),
        ],
      ),
    );
  }
}

String searchKindLabel(AppLocalizations l, SearchKind k) => switch (k) {
  SearchKind.task => l.searchKindTask,
  SearchKind.checklist => l.searchKindChecklist,
  SearchKind.item => l.searchKindItem,
  SearchKind.habit => l.searchKindHabit,
  SearchKind.log => l.searchKindLog,
  SearchKind.inbox => l.searchKindInbox,
};

IconData searchKindIcon(SearchKind k) => switch (k) {
  SearchKind.task => Icons.event_outlined,
  SearchKind.checklist => Icons.checklist,
  SearchKind.item => Icons.check_box_outline_blank,
  SearchKind.habit => Icons.repeat,
  SearchKind.log => Icons.notes,
  SearchKind.inbox => Icons.notifications_none,
};

class _GroupedResults extends StatelessWidget {
  const _GroupedResults({
    required this.results,
    required this.query,
    required this.expanded,
    required this.onSeeAll,
    required this.onOpen,
    required this.onComplete,
    required this.onCheckIn,
  });

  final List<SearchResult> results;
  final String query;
  final bool expanded;
  final ValueChanged<SearchKind> onSeeAll;
  final ValueChanged<SearchResult> onOpen;
  final ValueChanged<SearchResult> onComplete;
  final ValueChanged<SearchResult> onCheckIn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      key: const ValueKey('search-results'),
      padding: const EdgeInsetsDirectional.only(bottom: Space.xxxl),
      children: [
        for (final (kind, rows) in groupResults(results)) ...[
          SectionHeader(searchKindLabel(l, kind), key: ValueKey('search-group-${kind.name}')),
          for (final r in expanded ? rows : rows.take(SearchScreen.perGroup))
            SearchResultTile(
              result: r,
              query: query,
              onTap: () => onOpen(r),
              onComplete: kind == SearchKind.item && !r.closed ? () => onComplete(r) : null,
              onCheckIn: kind == SearchKind.habit && !r.closed && !r.quit ? () => onCheckIn(r) : null,
            ),
          if (!expanded && rows.length > SearchScreen.perGroup)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: ValueKey('search-see-all-${kind.name}'),
                onPressed: () => onSeeAll(kind),
                child: Text(l.searchSeeAll(rows.length)),
              ),
            ),
        ],
      ],
    );
  }
}

/// One result row: kind icon, highlighted title, breadcrumb and body snippet, inline action.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.result,
    required this.query,
    required this.onTap,
    super.key,
    this.onComplete,
    this.onCheckIn,
  });

  final SearchResult result;
  final String query;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onCheckIn;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = result;
    final mark = TextStyle(
      fontWeight: FontWeight.w700,
      color: context.colors.onPrimaryContainer,
      backgroundColor: context.colors.primaryContainer,
    );
    final crumbs = r.breadcrumb.where((c) => c.isNotEmpty).join(' › ');
    return ListTile(
      key: ValueKey('search-result-${r.id}'),
      leading: Icon(searchKindIcon(r.kind)),
      title: Text.rich(
        _highlighted(r.title, highlightRanges(r.title, query), mark),
        key: ValueKey('search-title-${r.id}'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: r.closed ? TextStyle(color: context.colors.onSurfaceVariant) : null,
      ),
      subtitle: crumbs.isEmpty && r.snippet == null
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (crumbs.isNotEmpty) Text(crumbs, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (r.snippet case final s?)
                  Text.rich(
                    TextSpan(
                      children: [for (final (t, hit) in snippetSpans(s)) TextSpan(text: t, style: hit ? mark : null)],
                    ),
                    key: ValueKey('search-snippet-${r.id}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
      trailing: switch ((onComplete, onCheckIn)) {
        (final complete?, _) => IconButton(
          key: ValueKey('search-complete-${r.id}'),
          tooltip: l.searchComplete,
          icon: const Icon(Icons.check_circle_outline),
          onPressed: complete,
        ),
        (_, final checkIn?) => IconButton(
          key: ValueKey('search-checkin-${r.id}'),
          tooltip: l.searchCheckIn,
          icon: const Icon(Icons.task_alt),
          onPressed: checkIn,
        ),
        _ => null,
      },
      onTap: onTap,
    );
  }

  static TextSpan _highlighted(String text, List<(int, int)> ranges, TextStyle mark) {
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in ranges) {
      if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
      spans.add(TextSpan(text: text.substring(start, end), style: mark));
      at = end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return TextSpan(children: spans);
  }
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final recents = ref.watch(searchRecentsProvider).value ?? const <String>[];
    if (recents.isEmpty) return EmptyState(icon: Icons.search, title: l.searchHint, message: l.searchIntro);
    return ListView(
      key: const ValueKey('search-recents'),
      children: [
        SectionHeader(
          l.searchRecent,
          trailing: TextButton(
            key: const ValueKey('search-recents-clear'),
            onPressed: () => unawaited(ref.read(searchRecentsProvider.notifier).clear()),
            child: Text(l.actionClear),
          ),
        ),
        for (final (i, q) in recents.indexed)
          ListTile(
            key: ValueKey('search-recent-$i'),
            leading: const Icon(Icons.history),
            title: Text(q),
            trailing: IconButton(
              tooltip: l.searchRemoveRecent,
              icon: const Icon(Icons.close),
              onPressed: () => unawaited(ref.read(searchRecentsProvider.notifier).remove(q)),
            ),
            onTap: () => onPick(q),
          ),
      ],
    );
  }
}

/// Filter chips (T8.1.15): kinds (multi-select), status, category, tag and dates.
class SearchFilterBar extends ConsumerWidget {
  const SearchFilterBar({required this.filters, required this.onChanged, super.key});

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final tags = ref.watch(tagsProvider).value ?? const [];
    final category = categories.where((c) => c.id == filters.categoryId).firstOrNull;
    final tag = tags.where((t) => t.id == filters.tagId).firstOrNull;
    final fmt = AppFormat(context.localeName, use24h: ref.watch(userPreferencesProvider).use24h, l10n: l);
    final today = ref
        .watch(zoneResolverProvider)
        .toLocal(ref.watch(clockProvider).nowUtc(), ref.watch(deviceZoneProvider))
        .date;

    Future<T?> pick<T>(String title, List<(T?, String)> options) => showAppSheet<T>(
      context,
      title: title,
      builder: (sheet) => ListView(
        shrinkWrap: true,
        children: [
          for (final (value, label) in options) ListTile(title: Text(label), onTap: () => Navigator.pop(sheet, value)),
        ],
      ),
    );

    String? dates() {
      final (from, to) = (filters.from, filters.to);
      if (from == null && to == null) return null;
      return [if (from != null) fmt.dateMedium(from), if (to != null) fmt.dateMedium(to)].join(' – ');
    }

    final status = filters.status;
    return SizedBox(
      height: 56,
      child: ListView(
        key: const ValueKey('search-filters'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: Space.md, vertical: Space.sm),
        children: [
          for (final k in SearchKind.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.sm),
              child: FilterChip(
                key: ValueKey('search-kind-${k.name}'),
                label: Text(searchKindLabel(l, k)),
                selected: filters.kinds.contains(k),
                onSelected: (on) =>
                    onChanged(filters.copyWith(kinds: on ? {...filters.kinds, k} : ({...filters.kinds}..remove(k)))),
              ),
            ),
          _MenuChip(
            key: const ValueKey('search-status'),
            label: switch (status) {
              SearchStatus.open => l.searchStatusOpen,
              SearchStatus.closed => l.searchStatusClosed,
              null => l.searchStatus,
            },
            selected: status != null,
            onPressed: () async {
              final picked = await pick<SearchStatus>(l.searchStatus, [
                (null, l.searchAny),
                (SearchStatus.open, l.searchStatusOpen),
                (SearchStatus.closed, l.searchStatusClosed),
              ]);
              if (context.mounted) onChanged(filters.copyWith(status: picked, clearStatus: picked == null));
            },
          ),
          if (categories.isNotEmpty)
            _MenuChip(
              key: const ValueKey('search-category'),
              label: category?.name ?? l.searchCategory,
              selected: category != null,
              onPressed: () async {
                final picked = await pick<String>(l.searchCategory, [
                  (null, l.searchAny),
                  for (final c in categories) (c.id, c.name),
                ]);
                onChanged(filters.copyWith(categoryId: picked, clearCategory: picked == null));
              },
            ),
          if (tags.isNotEmpty)
            _MenuChip(
              key: const ValueKey('search-tag'),
              label: tag?.name ?? l.searchTag,
              selected: tag != null,
              onPressed: () async {
                final picked = await pick<String>(l.searchTag, [
                  (null, l.searchAny),
                  for (final t in tags) (t.id, t.name),
                ]);
                onChanged(filters.copyWith(tagId: picked, clearTag: picked == null));
              },
            ),
          _MenuChip(
            key: const ValueKey('search-dates'),
            label: dates() ?? l.searchDates,
            selected: dates() != null,
            onPressed: () async {
              final picked = await pick<(LocalDate?, LocalDate?)>(l.searchDates, [
                ((null, null), l.searchAny),
                ((today, today), l.searchDatesToday),
                ((today.plusDays(-6), today), l.searchDatesWeek),
                ((today.plusDays(-29), today), l.searchDatesMonth),
                // Sentinel: a start without an end asks for a custom range below.
                ((today, null), '${l.searchDatesFrom}…'),
              ]);
              if (picked == null || !context.mounted) return;
              var (from, to) = picked;
              if (from != null && to == null) {
                // Custom range: pick both ends.
                from = await pickDate(context, initial: filters.from ?? today);
                if (from == null || !context.mounted) return;
                to = await pickDate(context, initial: filters.to ?? from, first: from);
                if (to == null) return;
              }
              onChanged(
                from == null && to == null ? filters.copyWith(clearDates: true) : filters.copyWith(from: from, to: to),
              );
            },
          ),
          if (!filters.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: Space.sm),
              child: ActionChip(
                key: const ValueKey('search-clear-filters'),
                avatar: const Icon(Icons.filter_alt_off_outlined),
                label: Text(l.searchClearFilters),
                onPressed: () => onChanged(const SearchFilters()),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip({required this.label, required this.selected, required this.onPressed, super.key});

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: Space.sm),
    child: FilterChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [Text(label), const Icon(Icons.arrow_drop_down, size: 18)]),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onPressed(),
    ),
  );
}

/// Parsed `key:value` tokens as removable chips, and syntax errors (T8.1.16).
class QuerySyntaxBar extends StatelessWidget {
  const QuerySyntaxBar({required this.parsed, required this.onRemove, super.key});

  final ParsedQuery parsed;
  final ValueChanged<QueryToken> onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String error(QueryError e) => switch (e.code) {
      QueryErrorCode.unknownKey => l.searchSyntaxUnknownKey(e.key ?? ''),
      QueryErrorCode.badValue => l.searchSyntaxBadValue(e.value ?? '', e.key ?? ''),
      QueryErrorCode.unclosedQuote => l.searchSyntaxUnclosedQuote,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Space.md, 0, Space.md, Space.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parsed.tokens.isNotEmpty)
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.xs,
              children: [
                for (final (i, t) in parsed.tokens.indexed)
                  InputChip(
                    key: ValueKey('search-token-$i'),
                    avatar: const Icon(Icons.filter_alt_outlined, size: 18),
                    label: Text(t.raw),
                    deleteButtonTooltipMessage: l.actionDelete,
                    onDeleted: () => onRemove(t),
                  ),
              ],
            ),
          for (final (i, e) in parsed.errors.indexed)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: Space.xs),
              child: Text(
                error(e),
                key: ValueKey('search-syntax-error-$i'),
                style: context.text.bodySmall?.copyWith(color: context.colors.error),
              ),
            ),
        ],
      ),
    );
  }
}
