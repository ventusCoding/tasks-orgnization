import 'dart:convert';

import 'package:everslot/features/notifications/domain/json_fields.dart';
import 'package:everslot/features/notifications/domain/notification_types.dart';
import 'package:meta/meta.dart';

/// One inbox row (`notifications`, id = uuidv5(dedupe_key)).
@immutable
class InboxItem {
  const InboxItem({
    required this.id,
    required this.dedupeKey,
    required this.category,
    required this.title,
    required this.fireAt,
    this.body,
    this.ruleId,
    this.sourceType,
    this.sourceId,
    this.occurrenceKey,
    this.section,
    this.payload = const {},
    this.deliveredAt,
    this.deliveredVia = const [],
    this.late = false,
    this.openedAt,
    this.readAt,
    this.dismissedAt,
    this.actedAt,
    this.action,
    this.snoozedUntil,
  });

  final String id;
  final String dedupeKey;
  final InboxCategory category;
  final String title;
  final String? body;
  final DateTime fireAt;
  final String? ruleId;
  final String? sourceType;
  final String? sourceId;
  final String? occurrenceKey;
  final NotificationSection? section;
  final Map<String, Object?> payload;
  final DateTime? deliveredAt;
  final List<String> deliveredVia;
  final bool late;
  final DateTime? openedAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final DateTime? actedAt;
  final String? action;
  final DateTime? snoozedUntil;

  bool get isRead => readAt != null;
  bool isSnoozedAt(DateTime now) => snoozedUntil != null && snoozedUntil!.isAfter(now);

  /// Unread = not read, not dismissed, not currently snoozed (T7.3.01).
  bool isUnreadAt(DateTime now) => readAt == null && dismissedAt == null && !isSnoozedAt(now);

  /// Acknowledged (stops nag chains on every device).
  bool get acknowledged => actedAt != null || openedAt != null || dismissedAt != null;

  String? get deepLink => asString(payload['link']);
  List<String> get actions => asStringList(payload['acts']) ?? const [];
  List<int> get snoozeOptions => asIntList(payload['snz']) ?? const [];

  /// Base key of a nag chain (the row's own key otherwise).
  String get baseKey => asString(payload['bk']) ?? dedupeKey;

  static Map<String, Object?> decodePayload(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      return asJsonMap(jsonDecode(json)) ?? const {};
    } on FormatException {
      return const {};
    }
  }

  static List<String> decodeVia(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      return asStringList(jsonDecode(json)) ?? const [];
    } on FormatException {
      return const [];
    }
  }

  @override
  bool operator ==(Object other) =>
      other is InboxItem &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.readAt == readAt &&
      other.dismissedAt == dismissedAt &&
      other.actedAt == actedAt &&
      other.openedAt == openedAt &&
      other.snoozedUntil == snoozedUntil &&
      other.late == late &&
      other.deliveredAt == deliveredAt;

  @override
  int get hashCode => Object.hash(id, title, body, readAt, dismissedAt, actedAt, openedAt, snoozedUntil);
}

/// Inbox list filter (T7.3.01).
@immutable
class InboxFilter {
  const InboxFilter({this.unreadOnly = false, this.section, this.category, this.from, this.to, this.query});

  static const all = InboxFilter();

  final bool unreadOnly;
  final NotificationSection? section;
  final InboxCategory? category;
  final DateTime? from;
  final DateTime? to;
  final String? query;

  InboxFilter copyWith({
    bool? unreadOnly,
    NotificationSection? section,
    bool clearSection = false,
    InboxCategory? category,
    bool clearCategory = false,
    String? query,
  }) => InboxFilter(
    unreadOnly: unreadOnly ?? this.unreadOnly,
    section: clearSection ? null : (section ?? this.section),
    category: clearCategory ? null : (category ?? this.category),
    from: from,
    to: to,
    query: query ?? this.query,
  );

  @override
  bool operator ==(Object other) =>
      other is InboxFilter &&
      other.unreadOnly == unreadOnly &&
      other.section == section &&
      other.category == category &&
      other.from == from &&
      other.to == to &&
      other.query == query;

  @override
  int get hashCode => Object.hash(unreadOnly, section, category, from, to, query);
}
