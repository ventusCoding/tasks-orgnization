import AppIntents
import UIKit

/// Siri / Shortcuts entry points (T8.2.15). Each intent opens Everslot on an `everslot://do/…` link;
/// the app does the work (same code path as Android App Actions and external links).
@available(iOS 16.0, *)
private func openEverslot(_ path: String, _ query: [String: String] = [:]) async {
  var components = URLComponents()
  components.scheme = "everslot"
  components.host = "do"
  components.path = path
  if !query.isEmpty {
    components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }.sorted { $0.name < $1.name }
  }
  guard let url = components.url else { return }
  await MainActor.run { UIApplication.shared.open(url) }
}

@available(iOS 16.0, *)
struct LogHabitIntent: AppIntent {
  static var title: LocalizedStringResource = "Log a habit"
  static var description = IntentDescription("Checks in a habit, or adds an amount to a counted habit.")
  static var openAppWhenRun = true

  @Parameter(title: "Habit") var habit: String
  @Parameter(title: "Amount") var amount: Double?

  func perform() async throws -> some IntentResult {
    var query = ["name": habit]
    if let amount { query["value"] = String(amount) }
    await openEverslot("/habit-log", query)
    return .result()
  }
}

@available(iOS 16.0, *)
struct NextTaskIntent: AppIntent {
  static var title: LocalizedStringResource = "What's next"
  static var description = IntentDescription("Opens the task running now or coming next.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    await openEverslot("/next")
    return .result()
  }
}

@available(iOS 16.0, *)
struct StartFocusIntent: AppIntent {
  static var title: LocalizedStringResource = "Start focus"
  static var description = IntentDescription("Starts the timer of the current or next task.")
  static var openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    await openEverslot("/focus")
    return .result()
  }
}

@available(iOS 16.0, *)
struct EverslotShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: LogHabitIntent(),
      phrases: ["Log a habit in \(.applicationName)", "Check in a habit with \(.applicationName)"],
      shortTitle: "Log habit",
      systemImageName: "checkmark.circle"
    )
    AppShortcut(
      intent: NextTaskIntent(),
      phrases: ["What's next in \(.applicationName)", "Show my next task in \(.applicationName)"],
      shortTitle: "What's next",
      systemImageName: "clock"
    )
    AppShortcut(
      intent: StartFocusIntent(),
      phrases: ["Start focus in \(.applicationName)", "Start my next task in \(.applicationName)"],
      shortTitle: "Start focus",
      systemImageName: "timer"
    )
  }
}
