import 'dart:async';

import 'package:drift/native.dart';
import 'package:everslot/core/database/app_database.dart';
import 'package:everslot/core/env/env.dart';
import 'package:everslot/core/providers.dart';
import 'package:everslot/core/session/session.dart';
import 'package:everslot/core/time/clock.dart';
import 'package:everslot/features/planner/application/planner_contract.dart';
import 'package:everslot/features/planner/domain/planner_item.dart';
import 'package:everslot/features/planner/presentation/grid/data/item_copy.dart';
import 'package:everslot/features/planner/presentation/view_config/view_config_providers.dart';
import 'package:everslot/features/planner/presentation/views/planner_nav.dart';
import 'package:everslot/l10n/generated/app_localizations.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalCupertinoLocalizations, GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Fake planner data layer implementing the CONTRACT (items per range + actions).
class FakePlannerBackend implements PlannerActions {
  FakePlannerBackend([List<PlannerItem> items = const []]) : _items = [...items];

  final List<PlannerItem> _items;
  final List<PlannerItem> backlog = [];
  final _changes = StreamController<void>.broadcast();

  /// Ranges resolved (one entry per provider subscription).
  final List<DayRange> resolved = [];
  final List<String> calls = [];

  List<PlannerItem> get items => List.unmodifiable(_items);

  Stream<List<PlannerItem>> watch(DayRange range) async* {
    resolved.add(range);
    yield _inRange(range);
    await for (final _ in _changes.stream) {
      yield _inRange(range);
    }
  }

  List<PlannerItem> _inRange(DayRange range) => [for (final i in _items) if (overlapsRange(i, range)) i]
    ..sort((a, b) => a.startLocal.compareTo(b.startLocal));

  void replaceAll(List<PlannerItem> items) {
    _items
      ..clear()
      ..addAll(items);
    _changes.add(null);
  }

  void _replace(PlannerItem item, PlannerItem next) {
    final idx = _items.indexWhere((i) => i.key == item.key);
    if (idx >= 0) _items[idx] = next;
    _changes.add(null);
  }

  @override
  Future<String?> createAt(LocalDateTime start, int durationMinutes, {String? title, bool allDay = false}) async {
    calls.add('create ${start.toIso()} $durationMinutes ${title ?? ''}${allDay ? ' allDay' : ''}');
    final id = 'new-${calls.length}';
    _items.add(PlannerItem(
      taskId: id,
      seriesId: id,
      occurrenceKey: start.toIso(),
      title: title ?? 'New',
      startLocal: start,
      durationMinutes: durationMinutes,
      startUtc: start.toDateTimeUtc(),
      endUtc: start.toDateTimeUtc().add(Duration(minutes: durationMinutes)),
      status: OccurrenceStatus.scheduled,
      allDay: allDay,
    ));
    _changes.add(null);
    return id;
  }

  @override
  Future<void> reschedule(
    PlannerItem item, {
    required LocalDateTime newStart,
    int? newDurationMinutes,
    bool? allDay,
    EditScope scope = EditScope.thisOccurrence,
  }) async {
    calls.add('reschedule ${item.title} ${newStart.toIso()} ${newDurationMinutes ?? item.durationMinutes}'
        '${allDay == null ? '' : ' allDay=$allDay'} ${scope.name}');
    _replace(item, copyItem(item, startLocal: newStart, durationMinutes: newDurationMinutes, allDay: allDay));
  }

  @override
  Future<void> setStatus(PlannerItem item, OccurrenceStatus status, {String? skipReason}) async {
    calls.add('status ${item.title} ${status.name}');
    _replace(item, copyItem(item, status: status));
  }

  @override
  Future<void> scheduleBacklogItem(PlannerItem item, LocalDateTime start, int durationMinutes) async {
    calls.add('schedule ${item.title} ${start.toIso()} $durationMinutes');
  }

  Future<void> dispose() => _changes.close();
}

/// Device zone without the lifecycle observer (plain unit tests have no widgets binding).
class _TestZoneController extends DeviceZoneController {
  _TestZoneController(this.zone);

  final String zone;

  @override
  String build() => zone;
}

/// Records navigation instead of pushing routes.
class RecordingNav implements PlannerNav {
  final List<String> log = [];

  @override
  void openTask(BuildContext context, PlannerItem item) => log.add('task ${item.taskId} ${item.occurrenceKey}');

  @override
  void openTaskId(BuildContext context, String id) => log.add('task $id');

  @override
  void newTask(BuildContext context, {LocalDateTime? start, int? duration, bool allDay = false}) =>
      log.add('new ${start?.toIso()} $duration${allDay ? ' allDay' : ''}');

  @override
  void openView(BuildContext context, String viewKey, {LocalDate? date}) => log.add('view $viewKey ${date?.toIso()}');

  @override
  void openInsights(BuildContext context, {LocalDate? from, int days = 7}) => log.add('insights ${from?.toIso()} $days');
}

/// Container + DB + fake contract for planner view tests.
class PlannerHarness {
  PlannerHarness._(this.db, this.container, this.clock, this.backend, this.nav);

  static bool _tzReady = false;

  static PlannerHarness create({
    DateTime? now,
    String zone = 'UTC',
    List<PlannerItem> items = const [],
    List<Override> overrides = const [],
  }) {
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
    ViewConfigController.saveDelay = Duration.zero;
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final clock = FakeClock(now ?? DateTime.utc(2026, 9, 23, 9, 30));
    final backend = FakePlannerBackend(items);
    final nav = RecordingNav();
    SessionController.initial = const AppSession(userId: 'user-1', mode: SessionMode.localOnly);
    DeviceZoneController.initialZone = zone;
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(
          const Env(flavor: Flavor.dev, supabaseUrl: '', supabasePublishableKey: '', firebaseEnabled: false, featureFlags: {}),
        ),
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        deviceIdProvider.overrideWithValue('device-test'),
        deviceZoneProvider.overrideWith(() => _TestZoneController(zone)),
        plannerItemsProvider.overrideWith((ref, range) => backend.watch(range)),
        backlogItemsProvider.overrideWith((ref) => Stream.value(backend.backlog)),
        plannerActionsProvider.overrideWithValue(backend),
        plannerNavProvider.overrideWithValue(nav),
        ...overrides,
      ],
    );
    return PlannerHarness._(db, container, clock, backend, nav);
  }

  final AppDatabase db;
  final ProviderContainer container;
  final FakeClock clock;
  final FakePlannerBackend backend;
  final RecordingNav nav;

  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  Future<void> dispose() async {
    container.dispose();
    await backend.dispose();
    await db.close();
  }
}

/// Pumps [child] with localizations/theme; [size] sets the test surface (phone portrait by default).
Future<void> pumpPlanner(
  WidgetTester tester,
  PlannerHarness h,
  Widget child, {
  Locale locale = const Locale('en'),
  Size size = const Size(420, 860),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        locale: locale,
        themeMode: themeMode,
        darkTheme: ThemeData.dark(),
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
}
