/// Shared enums of the notification system (arch §6.13, §7.3, §8.2). Pure Dart.
library;

/// App section a rule / target / inbox row belongs to (`notification_rules.section`).
enum NotificationSection {
  planner('planner'),
  checklists('checklists'),
  habits('habits'),
  quit('quit'),
  system('system');

  NotificationSection(this.wire);

  final String wire;

  static NotificationSection? tryParse(String? value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return null;
  }

  static NotificationSection parse(String? value) => tryParse(value) ?? NotificationSection.system;

  /// Sections that hold user items (everything except `system`).
  static const itemSections = [planner, checklists, habits, quit];
}

/// Kind of notifiable target (wire values mirror `notification_rules.target_type` where they exist).
enum NotificationTargetType {
  task('task'),
  checklist('checklist'),
  checklistItem('checklist_item'),
  habit('habit'),

  /// Synthetic targets built by the digest composer (daily agenda…).
  digest('digest'),

  /// Anything a future feature wants to notify about (uses generic defaults only).
  custom('custom');

  NotificationTargetType(this.wire);

  final String wire;

  static NotificationTargetType parse(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return NotificationTargetType.custom;
  }
}

/// Owner of a rule row (`notification_rules.target_type`).
enum RuleTargetType {
  task('task'),
  checklist('checklist'),
  checklistItem('checklist_item'),
  habit('habit'),
  category('category'),
  section('section'),
  global('global');

  RuleTargetType(this.wire);

  final String wire;

  static RuleTargetType parse(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return RuleTargetType.global;
  }

  /// Rule owner type for an item target type (null for synthetic targets).
  static RuleTargetType? forTarget(NotificationTargetType type) => switch (type) {
    NotificationTargetType.task => RuleTargetType.task,
    NotificationTargetType.checklist => RuleTargetType.checklist,
    NotificationTargetType.checklistItem => RuleTargetType.checklistItem,
    NotificationTargetType.habit => RuleTargetType.habit,
    NotificationTargetType.digest || NotificationTargetType.custom => null,
  };
}

/// `notify_mode` column of tasks, checklists, items and habits (arch §6.13).
enum NotifyMode {
  /// Defaults only.
  inherit('inherit'),

  /// Own rules only.
  custom('custom'),

  /// Defaults + own rules.
  inheritPlus('inherit_plus'),

  /// Nothing.
  off('off');

  NotifyMode(this.wire);

  final String wire;

  static NotifyMode parse(String? value) {
    for (final m in values) {
      if (m.wire == value) return m;
    }
    return NotifyMode.inherit;
  }

  bool get usesDefaults => this == inherit || this == inheritPlus;
  bool get usesOwn => this == custom || this == inheritPlus;
}

/// Timed vs all-day vs date-only items (separate section defaults, `conditions.itemKind`).
enum ItemKind {
  timed('timed'),
  allDay('all_day'),
  dateOnly('date_only'),
  any('any');

  ItemKind(this.wire);

  final String wire;

  static ItemKind? tryParse(String? value) {
    for (final k in values) {
      if (k.wire == value) return k;
    }
    return null;
  }
}

/// Inbox category (`notifications.category`).
enum InboxCategory {
  reminder('reminder'),
  nag('nag'),
  digest('digest'),
  milestone('milestone'),
  streak('streak'),
  system('system');

  InboxCategory(this.wire);

  final String wire;

  static InboxCategory parse(String? value) {
    for (final c in values) {
      if (c.wire == value) return c;
    }
    return InboxCategory.reminder;
  }
}

/// Delivery importance (`delivery.importance`) → Android channel importance / iOS interruption level.
enum NotificationImportance {
  min('min'),
  low('low'),
  normal('default'),
  high('high'),
  urgent('urgent');

  NotificationImportance(this.wire);

  final String wire;

  static NotificationImportance? tryParse(String? value) {
    for (final i in values) {
      if (i.wire == value) return i;
    }
    return null;
  }

  /// Ordering helper (higher = more important).
  int get rank => index;
}

/// iOS interruption levels we use (critical alerts are not planned — arch §9.7).
enum InterruptionLevel {
  passive('passive'),
  active('active'),
  timeSensitive('timeSensitive');

  InterruptionLevel(this.wire);

  final String wire;

  static InterruptionLevel? tryParse(String? value) {
    for (final l in values) {
      if (l.wire == value) return l;
    }
    return null;
  }
}

/// Quiet-hours behaviour (arch §8.5).
enum QuietHoursMode {
  /// Move to the end of the window.
  defer('defer'),

  /// Deliver without sound on the quiet channel.
  silent('silent'),

  /// Do not deliver (inbox keeps nothing either).
  drop('drop');

  QuietHoursMode(this.wire);

  final String wire;

  static QuietHoursMode parse(String? value) {
    for (final m in values) {
      if (m.wire == value) return m;
    }
    return QuietHoursMode.defer;
  }
}

/// Multi-device delivery policy (arch §8.5, [7.4] T7.4.13).
enum MultiDevicePolicy {
  all('all'),
  primary('primary'),
  lastActive('last_active');

  MultiDevicePolicy(this.wire);

  final String wire;

  static MultiDevicePolicy parse(String? value) {
    for (final p in values) {
      if (p.wire == value) return p;
    }
    return MultiDevicePolicy.all;
  }
}

/// Where a rule applying to a target comes from (shown greyed in editors).
enum RuleProvenance { own, ancestor, checklist, category, section, global, occurrence }
