import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// A template variable and the target types that provide it (editor validation, T7.1.08).
@immutable
class TemplateVariable {
  const TemplateVariable(this.name, {this.targets, this.userText = false});

  final String name;

  /// Null = every target type.
  final Set<NotificationTargetType>? targets;

  /// User-authored text (bidi-isolated inside RTL sentences).
  final bool userText;

  bool availableFor(NotificationTargetType type) => targets == null || targets!.contains(type);
}

abstract final class TemplateVariables {
  static const _task = {NotificationTargetType.task};
  static const _items = {NotificationTargetType.checklist, NotificationTargetType.checklistItem};
  static const _habits = {NotificationTargetType.habit};

  static const all = <TemplateVariable>[
    TemplateVariable('title', userText: true),
    TemplateVariable('parent_path', targets: _items, userText: true),
    TemplateVariable('start_time'),
    TemplateVariable('end_time'),
    TemplateVariable('date'),
    TemplateVariable('weekday'),
    TemplateVariable('minutes_until'),
    TemplateVariable('due_relative'),
    TemplateVariable('duration', targets: _task),
    TemplateVariable('category', userText: true),
    TemplateVariable('notes_excerpt', userText: true),
    TemplateVariable('status'),
    TemplateVariable('status_note', targets: _items, userText: true),
    TemplateVariable('status_age', targets: _items),
    TemplateVariable('reason', userText: true),
    TemplateVariable('checklist_title', targets: _items, userText: true),
    TemplateVariable('item_text', targets: _items, userText: true),
    TemplateVariable('open_items', targets: _items),
    TemplateVariable('done', targets: _items),
    TemplateVariable('total', targets: _items),
    TemplateVariable('progress'),
    TemplateVariable('target', targets: _habits),
    TemplateVariable('unit', targets: _habits),
    TemplateVariable('logged_today', targets: _habits),
    TemplateVariable('remaining_in_period', targets: _habits),
    TemplateVariable('streak', targets: _habits),
    TemplateVariable('best_streak', targets: _habits),
    TemplateVariable('clean_time', targets: _habits),
    TemplateVariable('days_free', targets: _habits),
    TemplateVariable('money_saved', targets: _habits),
    TemplateVariable('units_avoided', targets: _habits),
    TemplateVariable('next_milestone', targets: _habits),
  ];

  static final Map<String, TemplateVariable> byName = {for (final v in all) v.name: v};

  static bool isKnown(String name) => byName.containsKey(name);

  static List<TemplateVariable> forTarget(NotificationTargetType type) =>
      [for (final v in all) if (v.availableFor(type)) v];

  static Set<String> get userTextNames => {for (final v in all) if (v.userText) v.name};
}

/// Renders `{variable}` templates (T7.1.08). Unknown variables render literally (and are flagged
/// by the validator); user text is bidi-isolated in RTL locales; results are length-budgeted.
abstract final class TemplateEngine {
  static final _pattern = RegExp(r'\{([a-z_]+)\}');

  /// Title / body budgets before truncation (T7.1.08).
  static const titleMax = 64;
  static const bodyMax = 178;

  static const _fsi = '\u2068';
  static const _pdi = '\u2069';

  /// Variable names used in [template].
  static Set<String> variablesIn(String template) =>
      {for (final m in _pattern.allMatches(template)) m.group(1)!};

  /// Unknown variable names in [template].
  static Set<String> unknownIn(String template) =>
      {for (final v in variablesIn(template)) if (!TemplateVariables.isKnown(v)) v};

  static String render(String template, Map<String, String> values, {bool rtl = false, int? maxLength}) {
    final userText = TemplateVariables.userTextNames;
    final out = template.replaceAllMapped(_pattern, (m) {
      final name = m.group(1)!;
      final value = values[name];
      if (value == null) return m.group(0)!;
      return rtl && userText.contains(name) && value.isNotEmpty ? '$_fsi$value$_pdi' : value;
    });
    final collapsed = out.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
    return maxLength == null ? collapsed : truncate(collapsed, maxLength);
  }

  /// Truncates on a character boundary with an ellipsis, keeping bidi isolates balanced.
  static String truncate(String text, int max) {
    final runes = text.runes.toList();
    if (runes.length <= max) return text;
    var cut = String.fromCharCodes(runes.take(max - 1)).trimRight();
    final opened = _fsi.allMatches(cut).length - _pdi.allMatches(cut).length;
    if (opened > 0) cut += _pdi * opened;
    return '$cut…';
  }
}

/// Default-content kinds (localized built-in templates per trigger, T7.1.08).
enum DefaultContentKind {
  beforeStart,
  atStart,
  afterStart,
  beforeEnd,
  atEnd,
  afterEnd,
  beforeDue,
  atDue,
  followUp,
  slot,
  onDay,
  daysBefore,
  absolute,
  schedule,
  notDoneBy,
  statusAge,
  overdue,
  streakRisk,
  quotaBehind,
  milestone,
  inactivity,
  digest,
  statusChange,
  childrenComplete,
  childOverdue,
  stale,
  snoozed,
  test,
}

/// Localized strings and formatting used by the planner (implemented in the application layer
/// with `AppLocalizations` + `AppFormat`; [PlainNotificationTexts] is an English fallback).
abstract interface class NotificationTexts {
  String get localeTag;
  bool get isRtl;

  String time(LocalDateTime local);
  String date(LocalDate date);
  String weekday(LocalDate date);
  String duration(int minutes);
  String number(num value);

  /// "in 10 min" / "10 min ago" / "now" relative to the fire time.
  String relative(int minutes);

  /// Built-in content for [kind]. [vars] are already formatted; [count] carries the minutes,
  /// days or streak the sentence needs for ICU plurals.
  ({String title, String? body}) defaultContent(DefaultContentKind kind, Map<String, String> vars, {int? count});

  String get redactedTitle;
  String get redactedBody;

  /// "3 reminders" (same-minute merge).
  String mergedTitle(int count);
  String get saturationTitle;
  String get saturationBody;
  String actionLabel(String actionId);
  String digestTitle(String kind);
}

/// English fallback (pure; used by domain tests and when localizations are unavailable).
class PlainNotificationTexts implements NotificationTexts {
  const PlainNotificationTexts({this.use24h = true});

  final bool use24h;

  @override
  String get localeTag => 'en';

  @override
  bool get isRtl => false;

  @override
  String time(LocalDateTime local) {
    if (use24h) return local.time.toIso();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$h:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  String date(LocalDate date) => date.toIso();

  @override
  String weekday(LocalDate date) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday.iso - 1];

  @override
  String duration(int minutes) => minutes >= 60
      ? (minutes % 60 == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h ${minutes % 60} min')
      : '$minutes min';

  @override
  String number(num value) => value is int || value == value.roundToDouble() ? '${value.round()}' : value.toStringAsFixed(1);

  @override
  String relative(int minutes) => minutes == 0 ? 'now' : (minutes > 0 ? 'in $minutes min' : '${-minutes} min ago');

  @override
  ({String title, String? body}) defaultContent(DefaultContentKind kind, Map<String, String> vars, {int? count}) {
    final t = vars['title'] ?? '';
    final range = [vars['start_time'], vars['end_time']].whereType<String>().where((s) => s.isNotEmpty).join('–');
    return switch (kind) {
      DefaultContentKind.beforeStart => (title: t, body: 'Starts in ${count ?? 0} min${range.isEmpty ? '' : ' · $range'}'),
      DefaultContentKind.atStart => (title: t, body: 'Starting now${range.isEmpty ? '' : ' · $range'}'),
      DefaultContentKind.afterStart => (title: t, body: 'Started ${count ?? 0} min ago'),
      DefaultContentKind.beforeEnd => (title: t, body: 'Ends in ${count ?? 0} min'),
      DefaultContentKind.atEnd => (title: t, body: 'Ending now'),
      DefaultContentKind.afterEnd => (title: t, body: 'Ended ${count ?? 0} min ago'),
      DefaultContentKind.beforeDue => (title: t, body: 'Due in ${count ?? 0} min'),
      DefaultContentKind.atDue => (title: t, body: 'Due now'),
      DefaultContentKind.followUp => (title: 'Follow up: $t', body: vars['status_note']),
      DefaultContentKind.slot => (title: t, body: 'Time for $t'),
      DefaultContentKind.onDay => (title: t, body: 'Today${vars['date'] == null ? '' : ' · ${vars['date']}'}'),
      DefaultContentKind.daysBefore => (title: t, body: 'In ${count ?? 1} days · ${vars['date'] ?? ''}'),
      DefaultContentKind.absolute || DefaultContentKind.schedule => (title: t, body: null),
      DefaultContentKind.notDoneBy => (title: t, body: "You haven't logged $t today"),
      DefaultContentKind.statusAge => (title: t, body: 'Still ${vars['status'] ?? ''} (${vars['status_age'] ?? ''})'),
      DefaultContentKind.overdue => (title: t, body: '$t is overdue'),
      DefaultContentKind.streakRisk => (title: t, body: 'Keep your ${count ?? 0}-day streak alive'),
      DefaultContentKind.quotaBehind => (title: t, body: 'Behind pace: ${vars['done'] ?? ''}/${vars['target'] ?? ''}'),
      DefaultContentKind.milestone => (title: t, body: vars['next_milestone'] ?? 'Milestone reached'),
      DefaultContentKind.inactivity => (title: t, body: 'No activity for ${count ?? 0} days'),
      DefaultContentKind.digest => (title: digestTitle(vars['kind'] ?? ''), body: vars['summary']),
      DefaultContentKind.statusChange => (title: t, body: 'Now ${vars['status'] ?? ''}'),
      DefaultContentKind.childrenComplete => (title: t, body: 'All sub-items are done — complete it?'),
      DefaultContentKind.childOverdue => (title: t, body: 'A sub-item is overdue'),
      DefaultContentKind.stale => (title: t, body: 'No activity for ${count ?? 0} days'),
      DefaultContentKind.snoozed => (title: t, body: 'Snoozed reminder'),
      DefaultContentKind.test => (title: t, body: 'Test notification'),
    };
  }

  @override
  String get redactedTitle => 'Reminder from Everslot';

  @override
  String get redactedBody => 'Open Everslot to see it';

  @override
  String mergedTitle(int count) => '$count reminders';

  @override
  String get saturationTitle => 'Open Everslot';

  @override
  String get saturationBody => 'Open Everslot to keep your reminders up to date';

  @override
  String actionLabel(String actionId) => switch (actionId) {
    'done' => 'Done',
    'snooze' => 'Snooze',
    'skip' => 'Skip',
    'open' => 'Open',
    _ => actionId,
  };

  @override
  String digestTitle(String kind) => switch (kind) {
    'daily_agenda' => "Today's agenda",
    'plan_tomorrow' => 'Plan tomorrow',
    'evening_review' => 'Evening review',
    'overdue_summary' => 'Overdue',
    'weekly_review' => 'Weekly review',
    'monthly_report' => 'Monthly report',
    _ => 'Digest',
  };
}
