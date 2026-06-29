import Foundation
import RheoSwiftUI

struct ExampleConfig: Codable, Equatable {
  var publishableKey: String
  var channelId: String
  var apiBaseUrl: String
  var userId: String
  /// When true, `FlowView(fallback:)` shows hardcoded offline UI on resolve failure.
  var useResolveFallback: Bool
  /// When true, hide the host navigation bar (title and back) on the flow screen.
  var hideFlowNavigationBar: Bool

  static let storageKey = "rheo.exampleConfig.v1"

  static let defaultApiBaseUrl = "https://api.getrheo.io"

  static let empty = ExampleConfig(
    publishableKey: "",
    channelId: "",
    apiBaseUrl: defaultApiBaseUrl,
    userId: "example-user",
    useResolveFallback: true,
    hideFlowNavigationBar: false
  )

  enum CodingKeys: String, CodingKey {
    case publishableKey
    case channelId
    case apiBaseUrl
    case userId
    case useResolveFallback
    case hideFlowNavigationBar
  }

  init(
    publishableKey: String,
    channelId: String,
    apiBaseUrl: String,
    userId: String,
    useResolveFallback: Bool = true,
    hideFlowNavigationBar: Bool = false
  ) {
    self.publishableKey = publishableKey
    self.channelId = channelId
    self.apiBaseUrl = apiBaseUrl
    self.userId = userId
    self.useResolveFallback = useResolveFallback
    self.hideFlowNavigationBar = hideFlowNavigationBar
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    publishableKey = try container.decode(String.self, forKey: .publishableKey)
    channelId = try container.decode(String.self, forKey: .channelId)
    apiBaseUrl = try container.decode(String.self, forKey: .apiBaseUrl)
    userId = try container.decode(String.self, forKey: .userId)
    useResolveFallback = try container.decodeIfPresent(Bool.self, forKey: .useResolveFallback) ?? true
    hideFlowNavigationBar =
      try container.decodeIfPresent(Bool.self, forKey: .hideFlowNavigationBar) ?? false
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(publishableKey, forKey: .publishableKey)
    try container.encode(channelId, forKey: .channelId)
    try container.encode(apiBaseUrl, forKey: .apiBaseUrl)
    try container.encode(userId, forKey: .userId)
    try container.encode(useResolveFallback, forKey: .useResolveFallback)
    try container.encode(hideFlowNavigationBar, forKey: .hideFlowNavigationBar)
  }

  var canStart: Bool {
    !publishableKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !channelId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !apiBaseUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func apiBaseURL() -> URL? {
    let trimmed = apiBaseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return URL(string: trimmed)
  }

  func buildRheoConfig() -> RheoConfig? {
    guard canStart, let apiURL = apiBaseURL() else { return nil }
    let trimmedUser = userId.trimmingCharacters(in: .whitespacesAndNewlines)
    let userIdValue = trimmedUser.isEmpty ? "example-user" : trimmedUser
    return RheoConfig(
      publishableKey: publishableKey.trimmingCharacters(in: .whitespacesAndNewlines),
      apiBaseURL: apiURL,
      userId: userIdValue,
      sessionId: "sess_\(Int(Date().timeIntervalSince1970))",
      locale: "en",
      appVersion: "0.1.0",
      platform: .ios
    )
  }
}

enum ExampleConfigStore {
  static func load() -> ExampleConfig {
    guard let data = UserDefaults.standard.data(forKey: ExampleConfig.storageKey) else {
      return .empty
    }
    do {
      var parsed = try JSONDecoder().decode(ExampleConfig.self, from: data)
      if parsed.apiBaseUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        parsed.apiBaseUrl = ExampleConfig.defaultApiBaseUrl
      }
      return parsed
    } catch {
      return .empty
    }
  }

  static func save(_ config: ExampleConfig) {
    guard let data = try? JSONEncoder().encode(config) else { return }
    UserDefaults.standard.set(data, forKey: ExampleConfig.storageKey)
  }

  static func reset() {
    UserDefaults.standard.removeObject(forKey: ExampleConfig.storageKey)
  }
}
