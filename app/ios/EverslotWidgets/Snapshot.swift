import Foundation
import WidgetKit

/// The snapshot the app writes to the App Group (Dart `WidgetSnapshot`, T8.2.02).
struct Snapshot: Codable {
  var v: Int?
  var generatedAt: String?
  var locale: String?
  var rtl: Bool?
  var day: String?
  var dayLabel: String?
  var progress: String?
  var strings: [String: String]?
  var agenda: [AgendaRow]?
  var habits: [HabitRow]?
  var quits: [QuitRow]?
  var checklist: ChecklistBlock?

  func s(_ key: String, _ fallback: String = "") -> String { strings?[key] ?? fallback }

  var generated: Date? { generatedAt.flatMap(Snapshot.parse) }

  func isStale(at now: Date = Date()) -> Bool {
    guard let generated else { return true }
    return now.timeIntervalSince(generated) > 24 * 3600
  }

  static func parse(_ iso: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
  }
}

struct AgendaRow: Codable, Hashable {
  var key: String
  var title: String
  var time: String
  var link: String
  var start: String?
  var end: String?
  var allDay: Bool?
  var color: Int?
  var done: Bool?

  var startDate: Date? { start.flatMap(Snapshot.parse) }
  var endDate: Date? { end.flatMap(Snapshot.parse) }

  func isNow(_ date: Date) -> Bool {
    guard let s = startDate, let e = endDate else { return false }
    return date >= s && date < e
  }

  func isOver(_ date: Date) -> Bool {
    guard let e = endDate else { return false }
    return date >= e
  }
}

struct HabitRow: Codable, Hashable {
  var id: String
  var name: String
  var progress: Double
  var label: String
  var done: Bool
  var counter: Bool
  var link: String
  var action: String
  var color: Int?
}

struct QuitRow: Codable, Hashable {
  var id: String
  var name: String
  var since: String
  var link: String
  var saved: String?
  var next: String?

  var sinceDate: Date { Snapshot.parse(since) ?? Date() }
}

struct ChecklistItemRow: Codable, Hashable {
  var id: String
  var text: String
  var depth: Int
  var action: String
}

struct ChecklistBlock: Codable, Hashable {
  var id: String
  var title: String
  var done: Int
  var total: Int
  var items: [ChecklistItemRow]
  var link: String
}

/// Shared container access: the snapshot and the queue of widget taps the app applies on its next
/// start / resume (iOS keeps Flutter out of the widget extension).
enum SharedStore {
  static let snapshotKey = "everslot_snapshot"
  static let actionsKey = "everslot_widget_actions"

  static var appGroup: String {
    Bundle.main.object(forInfoDictionaryKey: "EverslotAppGroup") as? String ?? "group.app.everslot"
  }

  static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

  static func load() -> Snapshot? {
    guard let raw = defaults?.string(forKey: snapshotKey), let data = raw.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(Snapshot.self, from: data)
  }

  /// Saves an optimistic copy; keys the app does not know are kept by re-encoding the whole document.
  static func save(_ snapshot: Snapshot) {
    guard let data = try? JSONEncoder().encode(snapshot), let raw = String(data: data, encoding: .utf8) else { return }
    defaults?.set(raw, forKey: snapshotKey)
  }

  static func enqueue(action: String, at date: Date = Date()) {
    var queue: [[String: String]] = []
    if let raw = defaults?.string(forKey: actionsKey), let data = raw.data(using: .utf8),
      let existing = try? JSONSerialization.jsonObject(with: data) as? [[String: String]]
    {
      queue = existing
    }
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    queue.append(["uri": action, "at": f.string(from: date)])
    if let data = try? JSONSerialization.data(withJSONObject: queue), let raw = String(data: data, encoding: .utf8) {
      defaults?.set(raw, forKey: actionsKey)
    }
  }
}

extension Snapshot {
  /// Optimistic habit tap: done for yes/no habits, one more for counters.
  mutating func tapHabit(_ id: String) {
    guard var list = habits, let i = list.firstIndex(where: { $0.id == id }) else { return }
    var h = list[i]
    if h.counter {
      let parts = h.label.split(separator: "/").map { Double($0) }
      if parts.count == 2, let achieved = parts[0], let target = parts[1], target > 0 {
        let next = achieved + 1
        h.label = "\(next.rounded() == next ? String(Int(next)) : String(next))/\(String(h.label.split(separator: "/")[1]))"
        h.progress = min(1, next / target)
        h.done = next >= target
      }
    } else {
      h.done = true
      h.progress = 1
      h.label = "✓"
    }
    list[i] = h
    habits = list
  }

  /// Optimistic item tap: the item leaves the open list.
  mutating func completeItem(_ id: String) {
    guard var c = checklist else { return }
    c.items.removeAll { $0.id == id }
    c.done += 1
    checklist = c
  }
}
