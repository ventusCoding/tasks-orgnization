import 'package:collection/collection.dart';
import 'package:everslot/features/checklists/domain/item_status.dart';
import 'package:everslot_recurrence/everslot_recurrence.dart';
import 'package:meta/meta.dart';

/// How a parent's progress is computed (arch §8.6).
enum ProgressMode {
  leaves,
  children;

  static ProgressMode parse(Object? v) => v == 'children' ? ProgressMode.children : ProgressMode.leaves;
}

/// Completing a parent with open descendants (arch §8.6).
enum CascadeChoice {
  ask,
  always,
  never;

  static CascadeChoice parse(Object? v) => switch (v) {
    'always' => CascadeChoice.always,
    'never' => CascadeChoice.never,
    _ => CascadeChoice.ask,
  };
}

/// Mode a checklist opens in.
enum OpenMode {
  edit,
  preview;

  static OpenMode parse(Object? v, {OpenMode fallback = OpenMode.preview}) => switch (v) {
    'edit' => OpenMode.edit,
    'preview' => OpenMode.preview,
    _ => fallback,
  };
}

/// Reset behaviour of recurring checklists (T4.5.06).
enum ResetMode {
  allToTodo('all_to_todo'),
  completedToTodo('completed_to_todo');

  ResetMode(this.dbValue);

  final String dbValue;

  static ResetMode? parse(String? v) => switch (v) {
    'all_to_todo' => ResetMode.allToTodo,
    'completed_to_todo' => ResetMode.completedToTodo,
    _ => null,
  };
}

/// `checklists.settings` JSON v1 (arch §8.6, T4.1.03). Unknown keys survive a round trip.
@immutable
class ChecklistSettings {
  const ChecklistSettings({
    this.progressMode = ProgressMode.leaves,
    this.autoCompleteParent = true,
    this.completeChildrenWithParent = CascadeChoice.ask,
    this.requireReasonFor = const {},
    this.showCompleted = true,
    this.sortCompletedToBottom = false,
    this.defaultNewItemStatus = ItemStatus.todo,
    this.hideCheckboxes = false,
    this.defaultOpenMode = OpenMode.preview,
    this.staleAfterDays = 14,
    this.showAttachmentsInPreview = true,
    this.showNotesInPreview = true,
    this.extra = const {},
  });

  static const version = 1;
  static const defaults = ChecklistSettings();

  final ProgressMode progressMode;
  final bool autoCompleteParent;
  final CascadeChoice completeChildrenWithParent;
  final Set<ItemStatus> requireReasonFor;
  final bool showCompleted;
  final bool sortCompletedToBottom;
  final ItemStatus defaultNewItemStatus;
  final bool hideCheckboxes;
  final OpenMode defaultOpenMode;
  final int staleAfterDays;
  final bool showAttachmentsInPreview;
  final bool showNotesInPreview;

  /// Keys this version doesn't know (kept verbatim).
  final Map<String, Object?> extra;

  static const _known = {
    'v',
    'progressMode',
    'autoCompleteParent',
    'completeChildrenWithParent',
    'requireReasonFor',
    'showCompleted',
    'sortCompletedToBottom',
    'defaultNewItemStatus',
    'hideCheckboxes',
    'defaultOpenMode',
    'staleAfterDays',
    'showAttachmentsInPreview',
    'showNotesInPreview',
  };

  factory ChecklistSettings.fromJson(Map<String, Object?> json) {
    bool b(String k, bool d) => json[k] is bool ? json[k]! as bool : d;
    final reasons = json['requireReasonFor'];
    return ChecklistSettings(
      progressMode: ProgressMode.parse(json['progressMode']),
      autoCompleteParent: b('autoCompleteParent', true),
      completeChildrenWithParent: CascadeChoice.parse(json['completeChildrenWithParent']),
      requireReasonFor: reasons is List
          ? {
              for (final r in reasons)
                if (r is String && ItemStatus.values.any((s) => s.name == r)) ItemStatus.parse(r),
            }
          : const {},
      showCompleted: b('showCompleted', true),
      sortCompletedToBottom: b('sortCompletedToBottom', false),
      defaultNewItemStatus: json['defaultNewItemStatus'] is String
          ? ItemStatus.parse(json['defaultNewItemStatus']! as String)
          : ItemStatus.todo,
      hideCheckboxes: b('hideCheckboxes', false),
      defaultOpenMode: OpenMode.parse(json['defaultOpenMode']),
      staleAfterDays: json['staleAfterDays'] is num ? (json['staleAfterDays']! as num).toInt().clamp(1, 3650) : 14,
      showAttachmentsInPreview: b('showAttachmentsInPreview', true),
      showNotesInPreview: b('showNotesInPreview', true),
      extra: {
        for (final e in json.entries)
          if (!_known.contains(e.key)) e.key: e.value,
      },
    );
  }

  Map<String, Object?> toJson() => {
    ...extra,
    'v': version,
    'progressMode': progressMode.name,
    'autoCompleteParent': autoCompleteParent,
    'completeChildrenWithParent': completeChildrenWithParent.name,
    'requireReasonFor': [for (final s in requireReasonFor) s.name]..sort(),
    'showCompleted': showCompleted,
    'sortCompletedToBottom': sortCompletedToBottom,
    'defaultNewItemStatus': defaultNewItemStatus.name,
    'hideCheckboxes': hideCheckboxes,
    'defaultOpenMode': defaultOpenMode.name,
    'staleAfterDays': staleAfterDays,
    'showAttachmentsInPreview': showAttachmentsInPreview,
    'showNotesInPreview': showNotesInPreview,
  };

  bool requiresReason(ItemStatus s) => requireReasonFor.contains(s);

  ChecklistSettings copyWith({
    ProgressMode? progressMode,
    bool? autoCompleteParent,
    CascadeChoice? completeChildrenWithParent,
    Set<ItemStatus>? requireReasonFor,
    bool? showCompleted,
    bool? sortCompletedToBottom,
    ItemStatus? defaultNewItemStatus,
    bool? hideCheckboxes,
    OpenMode? defaultOpenMode,
    int? staleAfterDays,
    bool? showAttachmentsInPreview,
    bool? showNotesInPreview,
  }) => ChecklistSettings(
    progressMode: progressMode ?? this.progressMode,
    autoCompleteParent: autoCompleteParent ?? this.autoCompleteParent,
    completeChildrenWithParent: completeChildrenWithParent ?? this.completeChildrenWithParent,
    requireReasonFor: requireReasonFor ?? this.requireReasonFor,
    showCompleted: showCompleted ?? this.showCompleted,
    sortCompletedToBottom: sortCompletedToBottom ?? this.sortCompletedToBottom,
    defaultNewItemStatus: defaultNewItemStatus ?? this.defaultNewItemStatus,
    hideCheckboxes: hideCheckboxes ?? this.hideCheckboxes,
    defaultOpenMode: defaultOpenMode ?? this.defaultOpenMode,
    staleAfterDays: staleAfterDays ?? this.staleAfterDays,
    showAttachmentsInPreview: showAttachmentsInPreview ?? this.showAttachmentsInPreview,
    showNotesInPreview: showNotesInPreview ?? this.showNotesInPreview,
    extra: extra,
  );

  @override
  bool operator ==(Object other) =>
      other is ChecklistSettings && const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

/// A checklist / note card (T4.1.03).
@immutable
class Checklist {
  const Checklist({
    required this.id,
    required this.sortKey,
    this.title = '',
    this.body,
    this.color,
    this.categoryId,
    this.isPinned = false,
    this.archivedAt,
    this.coverAttachmentId,
    this.dueLocal,
    this.timeZone,
    this.resetRule,
    this.resetMode,
    this.lastResetKey,
    this.settings = ChecklistSettings.defaults,
    this.isTemplate = false,
    this.templateId,
    this.notifyMode = 'inherit',
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String? body;

  /// ARGB, null = default card color.
  final int? color;
  final String? categoryId;
  final bool isPinned;
  final String sortKey;
  final DateTime? archivedAt;
  final String? coverAttachmentId;
  final LocalDateTime? dueLocal;
  final String? timeZone;

  /// Recurrence JSON (arch §8.1).
  final Map<String, Object?>? resetRule;
  final ResetMode? resetMode;
  final String? lastResetKey;
  final ChecklistSettings settings;
  final bool isTemplate;
  final String? templateId;
  final String notifyMode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  bool get isArchived => archivedAt != null;
  bool get isDeleted => deletedAt != null;
  bool get isRecurring => resetRule != null;
  bool get hasBody => body != null && body!.trim().isNotEmpty;

  Checklist copyWith({
    String? title,
    String? body,
    int? color,
    bool clearColor = false,
    String? categoryId,
    bool clearCategory = false,
    bool? isPinned,
    String? sortKey,
    DateTime? archivedAt,
    bool clearArchived = false,
    ChecklistSettings? settings,
    bool? isTemplate,
  }) => Checklist(
    id: id,
    title: title ?? this.title,
    body: body ?? this.body,
    color: clearColor ? null : (color ?? this.color),
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    isPinned: isPinned ?? this.isPinned,
    sortKey: sortKey ?? this.sortKey,
    archivedAt: clearArchived ? null : (archivedAt ?? this.archivedAt),
    coverAttachmentId: coverAttachmentId,
    dueLocal: dueLocal,
    timeZone: timeZone,
    resetRule: resetRule,
    resetMode: resetMode,
    lastResetKey: lastResetKey,
    settings: settings ?? this.settings,
    isTemplate: isTemplate ?? this.isTemplate,
    templateId: templateId,
    notifyMode: notifyMode,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Checklist &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.color == color &&
      other.categoryId == categoryId &&
      other.isPinned == isPinned &&
      other.sortKey == sortKey &&
      other.archivedAt == archivedAt &&
      other.coverAttachmentId == coverAttachmentId &&
      other.dueLocal == dueLocal &&
      const DeepCollectionEquality().equals(other.resetRule, resetRule) &&
      other.resetMode == resetMode &&
      other.lastResetKey == lastResetKey &&
      other.settings == settings &&
      other.isTemplate == isTemplate &&
      other.templateId == templateId &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    body,
    color,
    categoryId,
    isPinned,
    sortKey,
    archivedAt,
    coverAttachmentId,
    resetMode,
    lastResetKey,
    settings,
    isTemplate,
    updatedAt,
    deletedAt,
  );
}

/// One item row of a checklist (T4.1.03).
@immutable
class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.sortKey,
    this.parentId,
    this.text = '',
    this.note,
    this.status = ItemStatus.todo,
    this.statusNote,
    this.statusChangedAt,
    this.completedAt,
    this.followUpAt,
    this.dueLocal,
    this.timeZone,
    this.waitingOn,
    this.priority = 0,
    this.notifyMode = 'inherit',
    this.estimateMinutes,
    this.mirrorOfId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String checklistId;
  final String? parentId;
  final String sortKey;
  final String text;
  final String? note;
  final ItemStatus status;
  final String? statusNote;
  final DateTime? statusChangedAt;
  final DateTime? completedAt;
  final DateTime? followUpAt;

  /// Wall-clock due (floating unless [timeZone]); 00:00 means "date only".
  final LocalDateTime? dueLocal;
  final String? timeZone;
  final String? waitingOn;

  /// 0 none … 4 urgent.
  final int priority;

  /// Reminder mode of the item (`notify_mode`: inherit | custom | inherit_plus | off).
  final String notifyMode;

  /// Routine step duration in minutes (`estimate_minutes`, T3.7.07); null = share of the task.
  final int? estimateMinutes;

  /// Original item this row mirrors (`mirror_of_id`, T4.5.16): the row shows and edits the
  /// original; its own [text] is the snapshot used once the original is gone.
  final String? mirrorOfId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isMirror => mirrorOfId != null;

  /// This mirror row as displayed (T4.5.16): its own identity and place, the [original]'s
  /// content and status.
  ChecklistItem showing(ChecklistItem original) => ChecklistItem(
    id: id,
    checklistId: checklistId,
    parentId: parentId,
    sortKey: sortKey,
    text: original.text,
    note: original.note,
    status: original.status,
    statusNote: original.statusNote,
    statusChangedAt: original.statusChangedAt,
    completedAt: original.completedAt,
    followUpAt: original.followUpAt,
    dueLocal: original.dueLocal,
    timeZone: original.timeZone,
    waitingOn: original.waitingOn,
    priority: original.priority,
    notifyMode: notifyMode,
    estimateMinutes: original.estimateMinutes,
    mirrorOfId: mirrorOfId,
    createdAt: createdAt,
    updatedAt: original.updatedAt,
  );

  bool get hasNote => note != null && note!.trim().isNotEmpty;

  /// Instant since which the item has been in its current status.
  DateTime? get statusSince => statusChangedAt ?? createdAt;

  ChecklistItem copyWith({
    String? checklistId,
    String? parentId,
    bool clearParent = false,
    String? sortKey,
    String? text,
    String? note,
    ItemStatus? status,
    String? statusNote,
    bool clearStatusNote = false,
    DateTime? statusChangedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? followUpAt,
    bool clearFollowUp = false,
    LocalDateTime? dueLocal,
    bool clearDue = false,
    int? priority,
    int? estimateMinutes,
    bool clearEstimate = false,
    String? mirrorOfId,
    bool clearMirror = false,
    DateTime? updatedAt,
  }) => ChecklistItem(
    id: id,
    checklistId: checklistId ?? this.checklistId,
    parentId: clearParent ? null : (parentId ?? this.parentId),
    sortKey: sortKey ?? this.sortKey,
    text: text ?? this.text,
    note: note ?? this.note,
    status: status ?? this.status,
    statusNote: clearStatusNote ? null : (statusNote ?? this.statusNote),
    statusChangedAt: statusChangedAt ?? this.statusChangedAt,
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    followUpAt: clearFollowUp ? null : (followUpAt ?? this.followUpAt),
    dueLocal: clearDue ? null : (dueLocal ?? this.dueLocal),
    timeZone: timeZone,
    waitingOn: waitingOn,
    priority: priority ?? this.priority,
    notifyMode: notifyMode,
    estimateMinutes: clearEstimate ? null : (estimateMinutes ?? this.estimateMinutes),
    mirrorOfId: clearMirror ? null : (mirrorOfId ?? this.mirrorOfId),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is ChecklistItem &&
      other.id == id &&
      other.checklistId == checklistId &&
      other.parentId == parentId &&
      other.sortKey == sortKey &&
      other.text == text &&
      other.note == note &&
      other.status == status &&
      other.statusNote == statusNote &&
      other.statusChangedAt == statusChangedAt &&
      other.completedAt == completedAt &&
      other.followUpAt == followUpAt &&
      other.dueLocal == dueLocal &&
      other.timeZone == timeZone &&
      other.waitingOn == waitingOn &&
      other.priority == priority &&
      other.notifyMode == notifyMode &&
      other.estimateMinutes == estimateMinutes &&
      other.mirrorOfId == mirrorOfId &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    checklistId,
    parentId,
    sortKey,
    text,
    note,
    status,
    statusNote,
    statusChangedAt,
    completedAt,
    followUpAt,
    dueLocal,
    priority,
    estimateMinutes,
    mirrorOfId,
    updatedAt,
  );

  @override
  String toString() => 'Item($id "${text.length > 20 ? text.substring(0, 20) : text}" $status p=$parentId k=$sortKey)';
}

/// Snapshot of one item at reset time (T4.5.06).
@immutable
class RunSnapshotEntry {
  const RunSnapshotEntry({required this.itemId, required this.status, this.completedAt, this.statusNote});

  final String itemId;
  final ItemStatus status;
  final DateTime? completedAt;
  final String? statusNote;

  Map<String, Object?> toJson() => {
    'itemId': itemId,
    'status': status.name,
    if (completedAt != null) 'completedAt': completedAt!.toUtc().toIso8601String(),
    if (statusNote != null) 'note': statusNote,
  };

  factory RunSnapshotEntry.fromJson(Map<String, Object?> j) => RunSnapshotEntry(
    itemId: j['itemId']! as String,
    status: ItemStatus.parse(j['status'] as String?),
    completedAt: j['completedAt'] is String ? DateTime.tryParse(j['completedAt']! as String) : null,
    statusNote: j['note'] as String?,
  );
}

/// One finished period of a resettable checklist (`checklist_runs`).
@immutable
class ChecklistRun {
  const ChecklistRun({
    required this.id,
    required this.checklistId,
    required this.occurrenceKey,
    required this.startedAt,
    this.endedAt,
    this.totalItems,
    this.completedItems,
    this.snapshot = const [],
  });

  final String id;
  final String checklistId;
  final String occurrenceKey;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? totalItems;
  final int? completedItems;
  final List<RunSnapshotEntry> snapshot;

  double get completionRatio => (totalItems ?? 0) == 0 ? 0 : (completedItems ?? 0) / totalItems!;
}

/// Validated checklist title (T4.1.03): trailing whitespace trimmed, ≤ 500 characters.
extension type const ChecklistTitle._(String value) {
  static const maxLength = 500;

  factory ChecklistTitle(String input) {
    final t = input.trimRight();
    return ChecklistTitle._(t.length > maxLength ? t.substring(0, maxLength) : t);
  }
}

/// Validated item text: trailing whitespace trimmed, inner newlines kept, ≤ 10 000 characters.
extension type const ItemText._(String value) {
  static const maxLength = 10000;
  static const noteMaxLength = 50000;
  static const bodyMaxLength = 100000;

  factory ItemText(String input) {
    final t = input.trimRight();
    return ItemText._(t.length > maxLength ? t.substring(0, maxLength) : t);
  }

  static String? note(String? input) {
    if (input == null) return null;
    final t = input.trimRight();
    if (t.trim().isEmpty) return null;
    return t.length > noteMaxLength ? t.substring(0, noteMaxLength) : t;
  }

  static String? body(String? input) {
    if (input == null) return null;
    final t = input.trimRight();
    if (t.trim().isEmpty) return null;
    return t.length > bodyMaxLength ? t.substring(0, bodyMaxLength) : t;
  }
}
