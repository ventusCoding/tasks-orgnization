import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// The blocks of the Today screen (T8.1.02).
enum TodayBlockId {
  nowNext('now_next'),
  agenda('agenda'),
  overdue('overdue'),
  habits('habits'),
  quit('quit'),
  checklists('checklists'),
  inbox('inbox');

  TodayBlockId(this.json);

  /// Stable JSON spelling (`user_settings.today`).
  final String json;

  static TodayBlockId? parse(Object? value) => values.firstWhereOrNull((b) => b.json == value);
}

/// Agenda swipe gestures (T8.1.04): start→end (right in LTR) and end→start.
enum SwipeAction {
  done('done'),
  skip('skip'),
  none('none');

  SwipeAction(this.json);

  final String json;

  static SwipeAction parse(Object? value, SwipeAction fallback) =>
      values.firstWhereOrNull((a) => a.json == value) ?? fallback;
}

/// Today customization (T8.1.12), stored as the versioned JSON value of the synced `today`
/// settings namespace (`user_settings`, arch §8.5) so the layout follows the user across devices.
///
/// ```jsonc
/// {"v": 1, "blocks": ["now_next", "agenda", …], "hidden": ["inbox"], "showWhenEmpty": ["agenda"],
///  "showHeader": true, "agenda": {"showCompleted": true, "swipeStart": "done", "swipeEnd": "skip"},
///  "overdue": {"lookbackDays": 7, "includeRecurring": true}, "dismissedHints": ["swipe"]}
/// ```
/// Unknown keys are preserved; blocks added in later versions are appended to a stored order.
@immutable
class TodayLayout {
  const TodayLayout({
    this.order = defaultOrder,
    this.hidden = const {},
    this.showWhenEmpty = const {TodayBlockId.agenda},
    this.showHeader = true,
    this.agendaShowCompleted = true,
    this.swipeStart = SwipeAction.done,
    this.swipeEnd = SwipeAction.skip,
    this.overdueLookbackDays,
    this.overdueIncludeRecurring = true,
    this.dismissedHints = const {},
    this.extra = const {},
  });

  factory TodayLayout.fromJson(Map<String, Object?> json) {
    final agenda = _map(json['agenda']);
    final overdue = _map(json['overdue']);
    final lookback = overdue['lookbackDays'];
    return TodayLayout(
      order: [
        for (final v in _list(json['blocks']))
          if (TodayBlockId.parse(v) case final id?) id,
      ],
      hidden: {
        for (final v in _list(json['hidden']))
          if (TodayBlockId.parse(v) case final id?) id,
      },
      showWhenEmpty: json.containsKey('showWhenEmpty')
          ? {
              for (final v in _list(json['showWhenEmpty']))
                if (TodayBlockId.parse(v) case final id?) id,
            }
          : const {TodayBlockId.agenda},
      showHeader: json['showHeader'] is bool ? json['showHeader']! as bool : true,
      agendaShowCompleted: agenda['showCompleted'] is bool ? agenda['showCompleted']! as bool : true,
      swipeStart: SwipeAction.parse(agenda['swipeStart'], SwipeAction.done),
      swipeEnd: SwipeAction.parse(agenda['swipeEnd'], SwipeAction.skip),
      overdueLookbackDays: lookback is num ? lookback.toInt().clamp(1, maxLookbackDays) : null,
      overdueIncludeRecurring: overdue['includeRecurring'] is bool ? overdue['includeRecurring']! as bool : true,
      dismissedHints: {
        for (final v in _list(json['dismissedHints']))
          if (v is String) v,
      },
      extra: {
        for (final e in json.entries)
          if (!_known.contains(e.key)) e.key: e.value,
      },
    );
  }

  static const version = 1;
  static const maxLookbackDays = 60;

  static const defaultOrder = [
    TodayBlockId.nowNext,
    TodayBlockId.agenda,
    TodayBlockId.overdue,
    TodayBlockId.habits,
    TodayBlockId.quit,
    TodayBlockId.checklists,
    TodayBlockId.inbox,
  ];

  static const defaults = TodayLayout();

  static const _known = {'v', 'blocks', 'hidden', 'showWhenEmpty', 'showHeader', 'agenda', 'overdue', 'dismissedHints'};

  /// Stored order (may be partial; see [blocks]).
  final List<TodayBlockId> order;
  final Set<TodayBlockId> hidden;

  /// Blocks that stay visible with their empty state instead of disappearing.
  final Set<TodayBlockId> showWhenEmpty;
  final bool showHeader;
  final bool agendaShowCompleted;
  final SwipeAction swipeStart;
  final SwipeAction swipeEnd;

  /// Overdue look-back; null = `planner.overdueLookbackDays` (default 7).
  final int? overdueLookbackDays;
  final bool overdueIncludeRecurring;
  final Set<String> dismissedHints;

  /// Keys of newer versions, kept verbatim.
  final Map<String, Object?> extra;

  /// Every block exactly once: the stored order (duplicates dropped), then missing blocks in
  /// their default position order.
  List<TodayBlockId> get blocks {
    final seen = <TodayBlockId>{};
    return [
      for (final b in order)
        if (seen.add(b)) b,
      for (final b in defaultOrder)
        if (!seen.contains(b)) b,
    ];
  }

  List<TodayBlockId> get visibleBlocks => [
    for (final b in blocks)
      if (!hidden.contains(b)) b,
  ];

  bool isHidden(TodayBlockId id) => hidden.contains(id);

  bool keepsWhenEmpty(TodayBlockId id) => showWhenEmpty.contains(id);

  bool hintDismissed(String hint) => dismissedHints.contains(hint);

  Map<String, Object?> toJson() => {
    ...extra,
    'v': version,
    'blocks': [for (final b in blocks) b.json],
    'hidden': [
      for (final b in blocks)
        if (hidden.contains(b)) b.json,
    ],
    'showWhenEmpty': [
      for (final b in blocks)
        if (showWhenEmpty.contains(b)) b.json,
    ],
    'showHeader': showHeader,
    'agenda': {'showCompleted': agendaShowCompleted, 'swipeStart': swipeStart.json, 'swipeEnd': swipeEnd.json},
    'overdue': {'lookbackDays': ?overdueLookbackDays, 'includeRecurring': overdueIncludeRecurring},
    'dismissedHints': dismissedHints.toList()..sort(),
  };

  /// Moves the block at [from] to [to] in [blocks] order (ReorderableList semantics: [to] is the
  /// index before removal).
  TodayLayout moved(int from, int to) {
    final list = [...blocks];
    if (from < 0 || from >= list.length) return this;
    final item = list.removeAt(from);
    final target = (to > from ? to - 1 : to).clamp(0, list.length);
    list.insert(target, item);
    return copyWith(order: list);
  }

  TodayLayout withHidden(TodayBlockId id, {required bool hidden}) =>
      copyWith(hidden: hidden ? {...this.hidden, id} : ({...this.hidden}..remove(id)));

  TodayLayout withShowWhenEmpty(TodayBlockId id, {required bool show}) =>
      copyWith(showWhenEmpty: show ? {...showWhenEmpty, id} : ({...showWhenEmpty}..remove(id)));

  TodayLayout withHintDismissed(String hint) => copyWith(dismissedHints: {...dismissedHints, hint});

  static const Object _unset = Object();

  TodayLayout copyWith({
    List<TodayBlockId>? order,
    Set<TodayBlockId>? hidden,
    Set<TodayBlockId>? showWhenEmpty,
    bool? showHeader,
    bool? agendaShowCompleted,
    SwipeAction? swipeStart,
    SwipeAction? swipeEnd,
    Object? overdueLookbackDays = _unset,
    bool? overdueIncludeRecurring,
    Set<String>? dismissedHints,
  }) => TodayLayout(
    order: order ?? this.order,
    hidden: hidden ?? this.hidden,
    showWhenEmpty: showWhenEmpty ?? this.showWhenEmpty,
    showHeader: showHeader ?? this.showHeader,
    agendaShowCompleted: agendaShowCompleted ?? this.agendaShowCompleted,
    swipeStart: swipeStart ?? this.swipeStart,
    swipeEnd: swipeEnd ?? this.swipeEnd,
    overdueLookbackDays: identical(overdueLookbackDays, _unset)
        ? this.overdueLookbackDays
        : overdueLookbackDays as int?,
    overdueIncludeRecurring: overdueIncludeRecurring ?? this.overdueIncludeRecurring,
    dismissedHints: dismissedHints ?? this.dismissedHints,
    extra: extra,
  );

  static Map<String, Object?> _map(Object? v) => v is Map ? Map<String, Object?>.from(v) : const {};

  static List<Object?> _list(Object? v) => v is List ? v : const [];

  static const _setEq = SetEquality<Object?>();

  @override
  bool operator ==(Object other) =>
      other is TodayLayout &&
      const ListEquality<TodayBlockId>().equals(other.blocks, blocks) &&
      _setEq.equals(other.hidden, hidden) &&
      _setEq.equals(other.showWhenEmpty, showWhenEmpty) &&
      other.showHeader == showHeader &&
      other.agendaShowCompleted == agendaShowCompleted &&
      other.swipeStart == swipeStart &&
      other.swipeEnd == swipeEnd &&
      other.overdueLookbackDays == overdueLookbackDays &&
      other.overdueIncludeRecurring == overdueIncludeRecurring &&
      _setEq.equals(other.dismissedHints, dismissedHints) &&
      const DeepCollectionEquality().equals(other.extra, extra);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(blocks),
    Object.hashAllUnordered(hidden),
    Object.hashAllUnordered(showWhenEmpty),
    showHeader,
    agendaShowCompleted,
    swipeStart,
    swipeEnd,
    overdueLookbackDays,
    overdueIncludeRecurring,
    Object.hashAllUnordered(dismissedHints),
  );
}
