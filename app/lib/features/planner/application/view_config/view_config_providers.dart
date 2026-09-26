import 'dart:async';

import 'package:collection/collection.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/features/planner/data/view_config/saved_views_repository.dart';
import 'package:everslot/features/planner/data/view_config/view_state_repository.dart';
import 'package:everslot/features/planner/domain/view_config/planner_view_config.dart';
import 'package:everslot/features/planner/domain/view_config/saved_view.dart';
import 'package:everslot/features/planner/domain/view_config/view_state.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:everslot/features/planner/domain/view_config/planner_view_config.dart';
export 'package:everslot/features/planner/domain/view_config/saved_view.dart';
export 'package:everslot/features/planner/domain/view_config/view_state.dart';

final savedViewsRepositoryProvider = Provider<SavedViewsRepository>(
  (ref) => SavedViewsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(syncWriterProvider),
    () => ref.read(currentUserIdProvider),
  ),
);

/// Planner saved views, ordered.
final plannerSavedViewsProvider = StreamProvider<List<SavedView>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(savedViewsRepositoryProvider).watchAll();
});

final viewStateRepositoryProvider = Provider<ViewStateRepository>(
  (ref) => ViewStateRepository(ref.watch(appDatabaseProvider), ref.watch(clockProvider)),
);

/// Deterministic id of the built-in saved view of a registry entry (converges across devices).
String entryViewId(String userId, String entryId) => SavedViewsRepository.entryViewId(userId, entryId);

/// Local view state of one view (T3.3.02): loaded once, then kept in memory; writes are debounced
/// to the local-only `ui_view_state` table (never synced).
final plannerViewStateProvider = NotifierProvider.family<ViewStateController, ViewState?, String>(ViewStateController.new);

class ViewStateController extends Notifier<ViewState?> {
  ViewStateController(this.viewKey);

  /// Debounce of persistence (tests set it to zero).
  static Duration saveDelay = const Duration(milliseconds: 600);

  final String viewKey;
  Timer? _timer;
  ViewState? _pending;
  var _loaded = false;

  /// Completes once the stored state was read (or failed to load).
  final Completer<ViewState?> _ready = Completer<ViewState?>();
  Future<ViewState?> get ready => _ready.future;

  @override
  ViewState? build() {
    ref.onDispose(() {
      _timer?.cancel();
      final pending = _pending;
      if (pending != null) unawaited(_persist(pending));
    });
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    ViewState? stored;
    try {
      stored = await ref.read(viewStateRepositoryProvider).read(viewKey);
    } on Object {
      stored = null; // No database (previews): state stays in memory.
    }
    _loaded = true;
    if (!ref.mounted) {
      if (!_ready.isCompleted) _ready.complete(stored);
      return;
    }
    if (_pending == null && stored != null) state = stored;
    if (!_ready.isCompleted) _ready.complete(state ?? stored);
  }

  bool get isLoaded => _loaded;

  void update(ViewState Function(ViewState current) change) {
    final next = change(state ?? const ViewState());
    if (next == state) return;
    state = next;
    _pending = next;
    _timer?.cancel();
    if (saveDelay == Duration.zero) {
      unawaited(flush());
    } else {
      _timer = Timer(saveDelay, () => unawaited(flush()));
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    final pending = _pending;
    if (pending == null) return;
    await _persist(pending);
    if (identical(_pending, pending)) _pending = null;
  }

  Future<void> _persist(ViewState s) async {
    try {
      await ref.read(viewStateRepositoryProvider).write(viewKey, s);
    } on Object {
      // Best effort: view state is a convenience.
    }
  }
}

/// A view key is a registry entry id (`week_table`, `work_week`, `month`…) or `saved:<id>`.
abstract final class ViewKeys {
  static const savedPrefix = 'saved:';

  static String saved(String id) => '$savedPrefix$id';

  static String? savedIdOf(String key) => key.startsWith(savedPrefix) ? key.substring(savedPrefix.length) : null;

  /// Default config of a registry entry (work week = N-day preset limited to work days, T3.6.05).
  static PlannerViewConfig defaultsForEntry(String entryId) {
    if (entryId == 'work_week') {
      return PlannerViewConfig.defaultsFor(PlannerViewType.nDay).copyWith(
        daysVisible: 5,
        daysVisibleLandscape: 5,
        showWeekends: false,
        firstDay: 'week_start',
        paging: PagingMode.week,
        options: const {'rolling': false, 'workWeek': true, 'followWorkHours': true},
      );
    }
    return PlannerViewConfig.defaultsFor(PlannerViewType.tryParse(entryId) ?? PlannerViewType.weekTable);
  }
}

/// Live config of one view (T3.3.01): starts from the entry defaults or the saved view, follows
/// synced changes, and persists edits (debounced) to `saved_views`.
final plannerViewConfigProvider = NotifierProvider.family<ViewConfigController, PlannerViewConfig, String>(
  ViewConfigController.new,
);

class ViewConfigController extends Notifier<PlannerViewConfig> {
  ViewConfigController(this.viewKey);

  /// Debounce of persistence (tests set it to zero).
  static Duration saveDelay = const Duration(milliseconds: 400);

  final String viewKey;
  Timer? _timer;
  PlannerViewConfig? _pending;

  String? get _savedId => ViewKeys.savedIdOf(viewKey);

  SavedView? _match(List<SavedView> views) {
    final saved = _savedId;
    if (saved != null) return views.firstWhereOrNull((v) => v.id == saved);
    final userId = ref.read(currentUserIdProvider);
    final id = SavedViewsRepository.entryViewId(userId, viewKey);
    return views.firstWhereOrNull((v) => v.id == id);
  }

  @override
  PlannerViewConfig build() {
    ref.onDispose(() {
      _timer?.cancel();
      final pending = _pending;
      if (pending != null) unawaited(_persist(pending));
    });
    ref.listen<AsyncValue<List<SavedView>>>(plannerSavedViewsProvider, (_, next) {
      final views = next.value;
      if (views == null || _pending != null) return;
      final match = _match(views);
      if (match != null && match.config != state) state = match.config;
    });
    final current = ref.read(plannerSavedViewsProvider).value;
    final match = current == null ? null : _match(current);
    return match?.config ?? ViewKeys.defaultsForEntry(viewKey);
  }

  void update(PlannerViewConfig config) {
    if (config == state) return;
    state = config;
    _pending = config;
    _timer?.cancel();
    if (saveDelay == Duration.zero) {
      unawaited(flush());
    } else {
      _timer = Timer(saveDelay, () => unawaited(flush()));
    }
  }

  void change(PlannerViewConfig Function(PlannerViewConfig c) f) => update(f(state));

  Future<void> flush() async {
    _timer?.cancel();
    final pending = _pending;
    if (pending == null) return;
    await _persist(pending);
    if (identical(_pending, pending)) _pending = null;
  }

  Future<void> _persist(PlannerViewConfig config) async {
    try {
      final repo = ref.read(savedViewsRepositoryProvider);
      final saved = _savedId;
      if (saved != null) {
        await repo.saveConfig(saved, config);
      } else {
        await repo.saveEntry(viewKey, viewKey, config);
      }
    } on Object catch (e) {
      // No database (widget previews) or a deleted saved view: keep the in-memory config.
      _log(e);
    }
  }

  void _log(Object e) {
    // Intentionally quiet: persistence is best-effort for views.
  }

  /// Resets to the entry defaults.
  void reset() => update(ViewKeys.defaultsForEntry(_savedId == null ? viewKey : state.type.id));
}

/// Anchor date shared between views (T3.6.03): switching views keeps the date.
final plannerAnchorProvider = NotifierProvider<PlannerAnchorController, LocalDate?>(PlannerAnchorController.new);

class PlannerAnchorController extends Notifier<LocalDate?> {
  @override
  LocalDate? build() => null;

  // ignore: use_setters_to_change_properties
  void set(LocalDate date) => state = date;
}

/// Minute of day shown at the top of time-based views, shared between them (T3.6.03).
final plannerScrollMinuteProvider = NotifierProvider<PlannerScrollMinuteController, double?>(
  PlannerScrollMinuteController.new,
);

class PlannerScrollMinuteController extends Notifier<double?> {
  @override
  double? build() => null;

  // ignore: use_setters_to_change_properties
  void set(double minute) => state = minute;
}
