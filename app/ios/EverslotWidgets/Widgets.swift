import SwiftUI
import WidgetKit

// MARK: - Timeline

struct SnapshotEntry: TimelineEntry {
  let date: Date
  let snapshot: Snapshot?
}

/// One provider for every widget: entries at each task boundary of the day and at midnight of
/// clean-time counters, so widgets advance without the app (T8.2.03 / T8.2.05).
struct SnapshotProvider: TimelineProvider {
  func placeholder(in context: Context) -> SnapshotEntry { SnapshotEntry(date: Date(), snapshot: nil) }

  func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
    completion(SnapshotEntry(date: Date(), snapshot: SharedStore.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
    let now = Date()
    let snapshot = SharedStore.load()
    var dates: Set<Date> = [now]
    for row in snapshot?.agenda ?? [] {
      for d in [row.startDate, row.endDate].compactMap({ $0 }) where d > now && d < now.addingTimeInterval(86_400) {
        dates.insert(d)
      }
    }
    for q in snapshot?.quits ?? [] {
      let elapsed = now.timeIntervalSince(q.sinceDate)
      let nextDay = q.sinceDate.addingTimeInterval((floor(elapsed / 86_400) + 1) * 86_400)
      if nextDay < now.addingTimeInterval(86_400) { dates.insert(nextDay) }
    }
    let entries = dates.sorted().prefix(60).map { SnapshotEntry(date: $0, snapshot: snapshot) }
    // Refresh at least every 30 minutes; the app reloads timelines whenever data changes.
    completion(Timeline(entries: Array(entries), policy: .after(now.addingTimeInterval(1800))))
  }
}

// MARK: - Shared views

enum L10n {
  private static var lang: String { Locale.current.language.languageCode?.identifier ?? "en" }

  static func t(_ en: String, _ fr: String, _ ar: String) -> String {
    switch lang {
    case "fr": return fr
    case "ar": return ar
    default: return en
    }
  }

  static var openApp: String { t("Open Everslot to load your day", "Ouvrez Everslot pour charger votre journée", "افتح Everslot لتحميل يومك") }
}

extension Color {
  init(argb: Int?) {
    guard let argb else {
      self = .accentColor
      return
    }
    let v = UInt32(truncatingIfNeeded: argb)
    self = Color(
      red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
  }
}

extension View {
  /// iOS 17 containers (StandBy, tinted modes) need an explicit background.
  @ViewBuilder func widgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(.fill.tertiary, for: .widget)
    } else {
      padding().background(Color(.systemBackground))
    }
  }
}

struct Frame<Content: View>: View {
  let snapshot: Snapshot?
  let title: String
  var subtitle: String? = nil
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.headline).lineLimit(1)
      if let subtitle, !subtitle.isEmpty {
        Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
      }
      if snapshot == nil || snapshot!.isStale() {
        Spacer()
        Text(snapshot?.s("stale") ?? L10n.openApp).font(.caption).foregroundStyle(.secondary)
        Spacer()
      } else {
        content()
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .environment(\.layoutDirection, snapshot?.rtl == true ? .rightToLeft : .leftToRight)
    .widgetBackground()
  }
}

// MARK: - Today (T8.2.03)

struct TodayView: View {
  @Environment(\.widgetFamily) var family
  let entry: SnapshotEntry

  var body: some View {
    let snapshot = entry.snapshot
    let rows = (snapshot?.agenda ?? []).filter { $0.allDay == true || !$0.isOver(entry.date) }
    let limit = family == .systemSmall ? 2 : (family == .systemMedium ? 3 : 8)
    Frame(snapshot: snapshot, title: snapshot?.dayLabel ?? "", subtitle: family == .systemSmall ? nil : snapshot?.progress) {
      if rows.isEmpty {
        Text(snapshot?.s((snapshot?.agenda ?? []).isEmpty ? "empty" : "allDone") ?? "").font(.caption).foregroundStyle(.secondary)
      } else {
        ForEach(Array(rows.prefix(limit)), id: \.key) { row in
          Link(destination: URL(string: row.link) ?? URL(string: "everslot://today")!) {
            HStack(spacing: 6) {
              RoundedRectangle(cornerRadius: 2).fill(Color(argb: row.color)).frame(width: 4, height: 26)
              VStack(alignment: .leading, spacing: 0) {
                Text(row.title).font(.caption).fontWeight(row.isNow(entry.date) ? .bold : .regular)
                  .strikethrough(row.done == true).lineLimit(1)
                Text(row.isNow(entry.date) ? "\(snapshot?.s("now") ?? "") · \(row.time)" : row.time)
                  .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
              }
            }
          }
        }
      }
    }
    .widgetURL(URL(string: "everslot://today"))
  }
}

struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "EverslotToday", provider: SnapshotProvider()) { TodayView(entry: $0) }
      .configurationDisplayName(L10n.t("Today", "Aujourd’hui", "اليوم"))
      .description(L10n.t("Your next tasks, with what is happening now", "Vos prochaines tâches et ce qui se passe maintenant", "مهامك التالية وما يجري الآن"))
      .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - Habits (T8.2.04)

struct HabitsView: View {
  @Environment(\.widgetFamily) var family
  let entry: SnapshotEntry

  var body: some View {
    let snapshot = entry.snapshot
    let habits = snapshot?.habits ?? []
    Frame(snapshot: snapshot, title: snapshot?.s("habits") ?? "", subtitle: family == .systemSmall ? nil : snapshot?.s("habitsProgress")) {
      if habits.isEmpty {
        Text(snapshot?.s("noHabits") ?? "").font(.caption).foregroundStyle(.secondary)
      } else {
        ForEach(Array(habits.prefix(family == .systemSmall ? 2 : (family == .systemMedium ? 3 : 8))), id: \.id) { habit in
          HStack {
            Link(destination: URL(string: habit.link) ?? URL(string: "everslot://habits")!) {
              VStack(alignment: .leading, spacing: 2) {
                Text(habit.name).font(.caption).lineLimit(1)
                ProgressView(value: habit.progress).tint(Color(argb: habit.color))
              }
            }
            CheckButton(habit: habit)
          }
        }
      }
    }
  }
}

struct CheckButton: View {
  let habit: HabitRow

  var label: some View {
    ZStack {
      Circle().fill(habit.done ? Color.accentColor : Color.secondary.opacity(0.2))
      Text(habit.counter ? (habit.label.isEmpty ? "+1" : habit.label) : (habit.done ? "✓" : ""))
        .font(.caption2).bold().foregroundStyle(habit.done ? .white : .primary).minimumScaleFactor(0.5)
    }
    .frame(width: 36, height: 36)
    .accessibilityLabel(habit.name)
  }

  var body: some View {
    if #available(iOS 17.0, *) {
      Button(intent: HabitTapIntent(habitId: habit.id, action: habit.action)) { label }.buttonStyle(.plain)
    } else {
      Link(destination: URL(string: habit.link) ?? URL(string: "everslot://habits")!) { label }
    }
  }
}

struct HabitsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "EverslotHabits", provider: SnapshotProvider()) { HabitsView(entry: $0) }
      .configurationDisplayName(L10n.t("Habits", "Habitudes", "العادات"))
      .description(L10n.t("Check in today’s habits with one tap", "Validez vos habitudes du jour d’un geste", "سجّل عادات اليوم بلمسة واحدة"))
      .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

// MARK: - Quit counter (T8.2.05)

struct QuitView: View {
  let entry: SnapshotEntry

  var body: some View {
    let snapshot = entry.snapshot
    let quit = snapshot?.quits?.first
    Frame(snapshot: snapshot, title: quit?.name ?? snapshot?.s("quit") ?? "") {
      if let quit {
        let elapsed = max(0, entry.date.timeIntervalSince(quit.sinceDate))
        let days = Int(elapsed / 86_400)
        let dayStart = quit.sinceDate.addingTimeInterval(Double(days) * 86_400)
        Text(L10n.t("\(days) d", "\(days) j", "\(days) ي")).font(.system(size: 30, weight: .bold)).foregroundStyle(Color.accentColor)
        // Counts up live without timeline refreshes.
        Text(dayStart, style: .timer).font(.title3).monospacedDigit().foregroundStyle(.secondary)
        if let saved = quit.saved { Text(saved).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
        if let next = quit.next { Text(next).font(.caption2).foregroundStyle(.secondary).lineLimit(1) }
      } else {
        Text(snapshot?.s("noQuit") ?? "").font(.caption).foregroundStyle(.secondary)
      }
    }
    .widgetURL(URL(string: quit?.link ?? "everslot://habits"))
  }
}

struct QuitWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "EverslotQuit", provider: SnapshotProvider()) { QuitView(entry: $0) }
      .configurationDisplayName(L10n.t("Clean time", "Temps d’abstinence", "مدة الامتناع"))
      .description(L10n.t("Live clean-time counter, money saved and next milestone", "Compteur en direct, argent économisé et prochain palier", "عداد مباشر والمال الموفّر والمرحلة التالية"))
      .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - Checklist (T8.2.08)

struct ChecklistView: View {
  @Environment(\.widgetFamily) var family
  let entry: SnapshotEntry

  var body: some View {
    let snapshot = entry.snapshot
    let list = snapshot?.checklist
    Frame(snapshot: snapshot, title: list?.title ?? snapshot?.s("list") ?? "", subtitle: list.map { "\($0.done)/\($0.total)" }) {
      if let list {
        if list.items.isEmpty {
          Text(snapshot?.s("listDone") ?? "").font(.caption).foregroundStyle(.secondary)
        } else {
          ForEach(Array(list.items.prefix(family == .systemLarge ? 10 : 4)), id: \.id) { item in
            HStack(spacing: 6) {
              ItemButton(item: item)
              Text(item.text).font(.caption).lineLimit(1)
            }
            .padding(.leading, CGFloat(item.depth) * 12)
          }
        }
      } else {
        Text(snapshot?.s("noList") ?? "").font(.caption).foregroundStyle(.secondary)
      }
    }
    .widgetURL(URL(string: list?.link ?? "everslot://lists"))
  }
}

struct ItemButton: View {
  let item: ChecklistItemRow

  var body: some View {
    let box = Image(systemName: "square").foregroundStyle(Color.accentColor).accessibilityLabel(item.text)
    if #available(iOS 17.0, *) {
      Button(intent: ItemTapIntent(itemId: item.id, action: item.action)) { box }.buttonStyle(.plain)
    } else {
      box
    }
  }
}

struct ChecklistWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "EverslotChecklist", provider: SnapshotProvider()) { ChecklistView(entry: $0) }
      .configurationDisplayName(L10n.t("Checklist", "Liste", "قائمة"))
      .description(L10n.t("Open items of your pinned list", "Éléments ouverts de votre liste épinglée", "العناصر المفتوحة في قائمتك المثبتة"))
      .supportedFamilies([.systemMedium, .systemLarge])
  }
}

// MARK: - Lock screen / StandBy accessories (T8.2.09)

struct AccessoryView: View {
  @Environment(\.widgetFamily) var family
  let entry: SnapshotEntry

  var body: some View {
    let snapshot = entry.snapshot
    switch family {
    case .accessoryCircular:
      let habits = snapshot?.habits ?? []
      let done = habits.filter(\.done).count
      Gauge(value: Double(done), in: 0...Double(max(habits.count, 1))) {
        Image(systemName: "checkmark")
      } currentValueLabel: {
        Text("\(done)/\(habits.count)")
      }
      .gaugeStyle(.accessoryCircularCapacity)
      .widgetURL(URL(string: "everslot://habits"))
      .widgetBackground()
    case .accessoryInline:
      if let quit = snapshot?.quits?.first {
        Text("\(quit.name) · \(Text(quit.sinceDate, style: .relative))")
      } else {
        Text(snapshot?.progress ?? "Everslot")
      }
    default:
      let next = (snapshot?.agenda ?? []).first { $0.allDay != true && !$0.isOver(entry.date) }
      VStack(alignment: .leading) {
        Text(next?.title ?? (snapshot?.s("empty") ?? "")).font(.headline).lineLimit(1)
        if let next { Text(next.time).font(.caption).lineLimit(1) }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .widgetURL(URL(string: next?.link ?? "everslot://today"))
      .widgetBackground()
    }
  }
}

struct AccessoryWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "EverslotAccessory", provider: SnapshotProvider()) { AccessoryView(entry: $0) }
      .configurationDisplayName("Everslot")
      .description(L10n.t("Habit ring, next task or clean time", "Anneau d’habitudes, prochaine tâche ou temps d’abstinence", "حلقة العادات أو المهمة التالية أو مدة الامتناع"))
      .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

@main
struct EverslotWidgetsBundle: WidgetBundle {
  var body: some Widget {
    TodayWidget()
    HabitsWidget()
    QuitWidget()
    ChecklistWidget()
    AccessoryWidget()
  }
}
