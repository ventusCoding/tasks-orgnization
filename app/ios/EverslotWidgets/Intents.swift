import AppIntents
import WidgetKit

/// Habit check-in from a widget (T8.2.04): updates the widget at once and queues the write for the
/// app (applied with the tap's time on the next start / resume).
@available(iOS 17.0, *)
struct HabitTapIntent: AppIntent {
  static var title: LocalizedStringResource = "Check in habit"
  static var isDiscoverable = false

  @Parameter(title: "Habit") var habitId: String
  @Parameter(title: "Action") var action: String

  init() {}

  init(habitId: String, action: String) {
    self.habitId = habitId
    self.action = action
  }

  func perform() async throws -> some IntentResult {
    if var snapshot = SharedStore.load() {
      snapshot.tapHabit(habitId)
      SharedStore.save(snapshot)
    }
    SharedStore.enqueue(action: action)
    return .result()
  }
}

/// Checklist item completion from a widget (T8.2.08).
@available(iOS 17.0, *)
struct ItemTapIntent: AppIntent {
  static var title: LocalizedStringResource = "Complete item"
  static var isDiscoverable = false

  @Parameter(title: "Item") var itemId: String
  @Parameter(title: "Action") var action: String

  init() {}

  init(itemId: String, action: String) {
    self.itemId = itemId
    self.action = action
  }

  func perform() async throws -> some IntentResult {
    if var snapshot = SharedStore.load() {
      snapshot.completeItem(itemId)
      SharedStore.save(snapshot)
    }
    SharedStore.enqueue(action: action)
    return .result()
  }
}
