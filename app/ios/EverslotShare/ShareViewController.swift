import UIKit
import UniformTypeIdentifiers

/// Share extension (T8.2.07): copies what was shared into the App Group and hands off to the app
/// with the `receive_sharing_intent` contract (`ShareKey` JSON + `ShareMedia-<bundle id>:share`).
/// The app shows the destination sheet (task, list, attach) — no UI here, so nothing to localize.
final class ShareViewController: UIViewController {
  private struct Media: Codable {
    var path: String
    var mimeType: String?
    var thumbnail: String?
    var duration: Double?
    var message: String?
    var type: String
  }

  private var hostBundleId: String {
    let id = Bundle.main.bundleIdentifier ?? "app.everslot.share"
    return id.hasSuffix(".share") ? String(id.dropLast(".share".count)) : id
  }

  private var appGroup: String {
    Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String ?? "group.\(hostBundleId)"
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { await collect() }
  }

  private func collect() async {
    var media: [Media] = []
    let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
    for provider in providers {
      if let item = await load(provider) { media.append(item) }
    }
    let defaults = UserDefaults(suiteName: appGroup)
    defaults?.set(try? JSONEncoder().encode(media), forKey: "ShareKey")
    defaults?.removeObject(forKey: "ShareMessageKey")
    defaults?.synchronize()
    openHostApp()
    extensionContext?.completeRequest(returningItems: nil)
  }

  private func load(_ provider: NSItemProvider) async -> Media? {
    let kinds: [(UTType, String)] = [(.image, "image"), (.movie, "video"), (.url, "url"), (.plainText, "text"), (.data, "file")]
    for (type, kind) in kinds where provider.hasItemConformingToTypeIdentifier(type.identifier) {
      if kind == "text" || kind == "url" {
        guard let value = try? await provider.loadItem(forTypeIdentifier: type.identifier) else { continue }
        let text = (value as? URL)?.isFileURL == false ? (value as? URL)?.absoluteString : value as? String
        if let text { return Media(path: text, type: kind) }
        if let url = value as? URL, url.isFileURL { return copy(url, kind: "file") }
        continue
      }
      if let url = await fileURL(provider, type: type) { return copy(url, kind: kind) }
    }
    return nil
  }

  private func fileURL(_ provider: NSItemProvider, type: UTType) async -> URL? {
    await withCheckedContinuation { continuation in
      _ = provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, _ in
        // The URL is only valid inside this callback: copy it out first.
        guard let url else { return continuation.resume(returning: nil) }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "-" + url.lastPathComponent)
        try? FileManager.default.copyItem(at: url, to: tmp)
        continuation.resume(returning: tmp)
      }
    }
  }

  /// Copies into the shared container so the app can read it after the extension exits.
  private func copy(_ url: URL, kind: String) -> Media? {
    guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else { return nil }
    let dir = container.appendingPathComponent("shared", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let target = dir.appendingPathComponent(url.lastPathComponent)
    do {
      try FileManager.default.copyItem(at: url, to: target)
    } catch {
      return nil
    }
    let mime = UTType(filenameExtension: target.pathExtension)?.preferredMIMEType
    return Media(path: target.absoluteString, mimeType: mime, type: kind)
  }

  /// Extensions cannot call `UIApplication.shared`: walk the responder chain to the app.
  private func openHostApp() {
    guard let url = URL(string: "ShareMedia-\(hostBundleId):share") else { return }
    var responder: UIResponder? = self
    while let r = responder {
      if let app = r as? UIApplication {
        app.open(url, options: [:], completionHandler: nil)
        return
      }
      responder = r.next
    }
    let selector = sel_registerName("openURL:")
    responder = self
    while let r = responder {
      if r.responds(to: selector) {
        _ = r.perform(selector, with: url)
        return
      }
      responder = r.next
    }
  }
}
