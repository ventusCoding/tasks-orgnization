import 'dart:convert';

import 'package:meta/meta.dart';

/// One agenda row of the Today widget (T8.2.03). Instants are UTC so native timelines can place
/// entries at task boundaries without the app.
@immutable
class WidgetAgendaRow {
  const WidgetAgendaRow({
    required this.key,
    required this.title,
    required this.timeLabel,
    required this.link,
    this.start,
    this.end,
    this.allDay = false,
    this.color,
    this.done = false,
  });

  final String key;
  final String title;

  /// Pre-rendered time ("09:00–10:00", "All day").
  final String timeLabel;
  final String link;
  final DateTime? start;
  final DateTime? end;
  final bool allDay;

  /// ARGB category / task color.
  final int? color;
  final bool done;

  Map<String, Object?> toJson() => {
    'key': key,
    'title': title,
    'time': timeLabel,
    'link': link,
    if (start != null) 'start': start!.toUtc().toIso8601String(),
    if (end != null) 'end': end!.toUtc().toIso8601String(),
    'allDay': allDay,
    if (color != null) 'color': color,
    'done': done,
  };
}

/// One habit of the check-in widget (T8.2.04).
@immutable
class WidgetHabitRow {
  const WidgetHabitRow({
    required this.id,
    required this.name,
    required this.progress,
    required this.label,
    required this.done,
    required this.counter,
    required this.link,
    required this.action,
    this.color,
    this.icon,
  });

  final String id;
  final String name;

  /// 0..1 ring.
  final double progress;

  /// "3/8", "✓"…
  final String label;
  final bool done;

  /// Count habit: a tap adds one instead of checking.
  final bool counter;
  final String link;

  /// Background action URI (`everslot-widget://habit/check?id=…`).
  final String action;
  final int? color;
  final String? icon;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'progress': (progress.clamp(0, 1) * 1000).round() / 1000,
    'label': label,
    'done': done,
    'counter': counter,
    'link': link,
    'action': action,
    if (color != null) 'color': color,
    if (icon != null) 'icon': icon,
  };
}

/// One quit tracker of the counter widget (T8.2.05).
@immutable
class WidgetQuitRow {
  const WidgetQuitRow({
    required this.id,
    required this.name,
    required this.since,
    required this.link,
    this.savedLabel,
    this.nextMilestoneLabel,
    this.nextMilestoneAt,
  });

  final String id;
  final String name;

  /// Start of the clean time (UTC): natives render a live timer from it.
  final DateTime since;
  final String link;
  final String? savedLabel;
  final String? nextMilestoneLabel;
  final DateTime? nextMilestoneAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'since': since.toUtc().toIso8601String(),
    'link': link,
    if (savedLabel != null) 'saved': savedLabel,
    if (nextMilestoneLabel != null) 'next': nextMilestoneLabel,
    if (nextMilestoneAt != null) 'nextAt': nextMilestoneAt!.toUtc().toIso8601String(),
  };
}

@immutable
class WidgetChecklistItem {
  const WidgetChecklistItem({required this.id, required this.text, required this.depth, required this.action});

  final String id;
  final String text;
  final int depth;

  /// Background action completing the item.
  final String action;

  Map<String, Object?> toJson() => {'id': id, 'text': text, 'depth': depth, 'action': action};
}

/// The checklist widget's list (T8.2.08).
@immutable
class WidgetChecklist {
  const WidgetChecklist({
    required this.id,
    required this.title,
    required this.done,
    required this.total,
    required this.items,
    required this.link,
    this.color,
  });

  final String id;
  final String title;
  final int done;
  final int total;
  final List<WidgetChecklistItem> items;
  final String link;
  final int? color;

  WidgetChecklist withItems(List<WidgetChecklistItem> next) =>
      WidgetChecklist(id: id, title: title, done: done, total: total, items: next, link: link, color: color);

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'total': total,
    'items': [for (final i in items) i.toJson()],
    'link': link,
    if (color != null) 'color': color,
  };
}

/// Everything the home / lock-screen widgets show (T8.2.02): one compact JSON document written to
/// the shared container, strings pre-rendered in the user's language.
@immutable
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.generatedAt,
    required this.locale,
    required this.rtl,
    required this.day,
    required this.dayLabel,
    required this.progressLabel,
    required this.strings,
    this.agenda = const [],
    this.habits = const [],
    this.quits = const [],
    this.checklist,
  });

  static const version = 1;

  /// Hard cap of the encoded document (App Group / shared preferences budget).
  static const maxBytes = 50 * 1024;

  /// Older snapshots make widgets ask to open the app.
  static const staleAfter = Duration(hours: 24);

  final DateTime generatedAt;
  final String locale;
  final bool rtl;

  /// Logical day (`YYYY-MM-DD`).
  final String day;
  final String dayLabel;
  final String progressLabel;

  /// Static labels: `today`, `habits`, `quit`, `empty`, `allDone`, `stale`, `now`, `open`…
  final Map<String, String> strings;
  final List<WidgetAgendaRow> agenda;
  final List<WidgetHabitRow> habits;
  final List<WidgetQuitRow> quits;
  final WidgetChecklist? checklist;

  bool isStale(DateTime now) => now.difference(generatedAt) > staleAfter;

  Map<String, Object?> toJson() => {
    'v': version,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'locale': locale,
    'rtl': rtl,
    'day': day,
    'dayLabel': dayLabel,
    'progress': progressLabel,
    'strings': strings,
    'agenda': [for (final r in agenda) r.toJson()],
    'habits': [for (final r in habits) r.toJson()],
    'quits': [for (final r in quits) r.toJson()],
    if (checklist != null) 'checklist': checklist!.toJson(),
  };

  String encode() => jsonEncode(toJson());

  WidgetSnapshot _copy({
    List<WidgetAgendaRow>? agenda,
    List<WidgetHabitRow>? habits,
    List<WidgetQuitRow>? quits,
    WidgetChecklist? checklist,
  }) => WidgetSnapshot(
    generatedAt: generatedAt,
    locale: locale,
    rtl: rtl,
    day: day,
    dayLabel: dayLabel,
    progressLabel: progressLabel,
    strings: strings,
    agenda: agenda ?? this.agenda,
    habits: habits ?? this.habits,
    quits: quits ?? this.quits,
    checklist: checklist ?? this.checklist,
  );

  /// Per-section caps first, then halves the longest list until the document fits [maxBytes]
  /// (long titles are clipped to 120 characters on the way in).
  WidgetSnapshot bounded({int agendaCap = 24, int habitsCap = 16, int quitsCap = 4, int itemsCap = 20}) {
    var s = _copy(
      agenda: agenda.take(agendaCap).toList(),
      habits: habits.take(habitsCap).toList(),
      quits: quits.take(quitsCap).toList(),
      checklist: checklist?.withItems(checklist!.items.take(itemsCap).toList()),
    );
    for (var guard = 0; guard < 40 && utf8.encode(s.encode()).length > maxBytes; guard++) {
      final lengths = {
        'agenda': s.agenda.length,
        'habits': s.habits.length,
        'items': s.checklist?.items.length ?? 0,
        'quits': s.quits.length,
      };
      final longest = lengths.entries.reduce((a, b) => b.value > a.value ? b : a);
      if (longest.value == 0) break;
      final keep = longest.value ~/ 2;
      s = switch (longest.key) {
        'agenda' => s._copy(agenda: s.agenda.take(keep).toList()),
        'habits' => s._copy(habits: s.habits.take(keep).toList()),
        'items' => s._copy(checklist: s.checklist!.withItems(s.checklist!.items.take(keep).toList())),
        _ => s._copy(quits: s.quits.take(keep).toList()),
      };
    }
    return s;
  }

  /// Clips a user string for widget display.
  static String clip(String text, [int max = 120]) => text.length <= max ? text : '${text.substring(0, max - 1)}…';
}

/// Background actions widgets can trigger (T8.2.04 / T8.2.08), as `everslot-widget://` URIs handled
/// by the Dart background callback.
abstract final class WidgetActions {
  static const scheme = 'everslot-widget';

  static String habitCheck(String habitId) =>
      Uri(scheme: scheme, host: 'habit', path: '/check', queryParameters: {'id': habitId}).toString();

  static String itemComplete(String checklistId, String itemId) => Uri(
    scheme: scheme,
    host: 'item',
    path: '/complete',
    queryParameters: {'checklist': checklistId, 'id': itemId},
  ).toString();

  static String refresh() => Uri(scheme: scheme, host: 'refresh').toString();

  /// Parsed action, or null for anything else.
  static WidgetAction? parse(Uri? uri) {
    if (uri == null || uri.scheme != scheme) return null;
    final q = uri.queryParameters;
    return switch ((uri.host, uri.path)) {
      ('habit', '/check') when q['id'] != null => WidgetAction.habitCheck(q['id']!),
      ('item', '/complete') when q['id'] != null && q['checklist'] != null => WidgetAction.itemComplete(
        q['checklist']!,
        q['id']!,
      ),
      ('refresh', _) => const WidgetAction.refresh(),
      _ => null,
    };
  }
}

enum WidgetActionKind { habitCheck, itemComplete, refresh }

@immutable
class WidgetAction {
  const WidgetAction.habitCheck(String this.id) : kind = WidgetActionKind.habitCheck, checklistId = null;
  const WidgetAction.itemComplete(String this.checklistId, String this.id) : kind = WidgetActionKind.itemComplete;
  const WidgetAction.refresh() : kind = WidgetActionKind.refresh, id = null, checklistId = null;

  final WidgetActionKind kind;
  final String? id;
  final String? checklistId;

  @override
  bool operator ==(Object other) =>
      other is WidgetAction && other.kind == kind && other.id == id && other.checklistId == checklistId;

  @override
  int get hashCode => Object.hash(kind, id, checklistId);
}
