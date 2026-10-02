import ActivityKit
import SwiftUI
import WidgetKit

/// Attributes of the `live_activities` plugin: the name must be exactly this (T8.2.10).
struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
  public typealias LiveDeliveryData = ContentState

  public struct ContentState: Codable, Hashable {}

  var id = UUID()
}

extension LiveActivitiesAppAttributes {
  func prefixedKey(_ key: String) -> String { "\(id)_\(key)" }
}

/// Values written by `LiveActivityTimerSurface` (Dart) into the App Group.
private struct TimerValues {
  let title: String
  let startedAt: Date
  let plannedEnd: Date?
  let link: URL
  let stopLink: URL
  let stopLabel: String
  let overLabel: String

  init(_ attributes: LiveActivitiesAppAttributes) {
    let d = SharedStore.defaults
    func string(_ key: String) -> String { d?.string(forKey: attributes.prefixedKey(key)) ?? "" }
    title = string("title")
    startedAt = Date(timeIntervalSince1970: d?.double(forKey: attributes.prefixedKey("startedAt")) ?? 0)
    let end = d?.double(forKey: attributes.prefixedKey("plannedEnd")) ?? 0
    plannedEnd = end > 0 ? Date(timeIntervalSince1970: end) : nil
    link = URL(string: string("link")) ?? URL(string: "everslot://today")!
    stopLink = URL(string: string("stopLink")) ?? link
    stopLabel = string("stopLabel")
    overLabel = string("overLabel")
  }
}

@available(iOS 16.1, *)
struct TimerActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
      let v = TimerValues(context.attributes)
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(v.title).font(.headline).lineLimit(1)
          Text(v.startedAt, style: .timer).font(.title2.monospacedDigit()).foregroundStyle(Color.accentColor)
          if let end = v.plannedEnd {
            if end < Date() {
              Text(v.overLabel).font(.caption).foregroundStyle(.orange)
            } else {
              ProgressView(timerInterval: v.startedAt...end, countsDown: false).tint(Color.accentColor)
            }
          }
        }
        Spacer()
        Link(destination: v.stopLink) {
          Label(v.stopLabel, systemImage: "stop.fill").font(.callout.bold())
        }
      }
      .padding()
      .widgetURL(v.link)
    } dynamicIsland: { context in
      let v = TimerValues(context.attributes)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "timer").foregroundStyle(Color.accentColor)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(v.title).font(.headline).lineLimit(1)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(v.startedAt, style: .timer).monospacedDigit().frame(maxWidth: 70)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Link(destination: v.stopLink) { Label(v.stopLabel, systemImage: "stop.fill") }
        }
      } compactLeading: {
        Image(systemName: "timer").foregroundStyle(Color.accentColor)
      } compactTrailing: {
        Text(v.startedAt, style: .timer).monospacedDigit().frame(maxWidth: 52)
      } minimal: {
        Image(systemName: "timer")
      }
      .widgetURL(v.link)
    }
  }
}
