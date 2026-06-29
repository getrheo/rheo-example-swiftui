import RheoSwiftUI
import SwiftUI

struct ManifestPrefetchSection: View {
  let channelId: String
  let publishableKey: String
  let apiBaseURL: String
  let userId: String
  let locale: String

  @State private var entries: [ManifestResolveCache.Summary] = []
  @State private var loading = false
  @State private var prefetching = false
  @State private var clearing = false

  private let cache = ManifestResolveCache()

  private var trimmedChannel: String {
    channelId.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var prefetchConfig: RheoConfig? {
    guard !trimmedChannel.isEmpty,
          let url = URL(string: apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)),
          !publishableKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return nil
    }
    let trimmedUser = userId.trimmingCharacters(in: .whitespacesAndNewlines)
    return RheoConfig(
      publishableKey: publishableKey.trimmingCharacters(in: .whitespacesAndNewlines),
      apiBaseURL: url,
      userId: trimmedUser.isEmpty ? "example-user" : trimmedUser,
      sessionId: "sess_prefetch",
      locale: locale,
      appVersion: "0.1.0",
      platform: .ios
    )
  }

  private var canPrefetch: Bool {
    prefetchConfig != nil
  }

  private var targetKey: String? {
    guard let config = prefetchConfig else { return nil }
    return cache.cacheKey(
      apiBaseURL: config.apiBaseURL,
      publishableKey: config.publishableKey,
      channelId: trimmedChannel,
      locale: locale
    )
  }

  private var targetCached: Bool {
    guard let targetKey else { return false }
    return entries.contains { $0.key == targetKey }
  }

  var body: some View {
    Section("Manifest prefetch") {
      Text(
        "Prefetch is manual in this example. Use the buttons below to warm the cache, inspect "
          + "stored manifests, or clear them. FlowView still resolves on demand when the cache is cold."
      )
      .font(.caption)
      .foregroundStyle(.secondary)

      if trimmedChannel.isEmpty {
        Text("Enter a channel id to prefetch.")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        LabeledContent("Target channel") {
          HStack(spacing: 6) {
            Text(trimmedChannel)
              .font(.caption.monospaced())
            Text(targetCached ? "cached" : "not cached yet")
              .font(.caption)
              .foregroundStyle(targetCached ? .green : .orange)
          }
        }
      }

      Text("Stored manifests (\(entries.count))")
        .font(.subheadline.weight(.semibold))

      if loading {
        ProgressView()
      } else if entries.isEmpty {
        Text("No cached manifests yet. Tap Trigger prefetch while the API is reachable.")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        ForEach(entries, id: \.key) { entry in
          VStack(alignment: .leading, spacing: 4) {
            Text(entryTitle(entry))
              .font(.subheadline.weight(.semibold))
            Text("etag \(entry.etag)")
              .font(.caption.monospaced())
              .foregroundStyle(.secondary)
            Text("flow \(entry.flowId.prefix(8))… · v \(entry.versionId.prefix(8))…")
              .font(.caption.monospaced())
              .foregroundStyle(.secondary)
            Text(cacheLine(entry))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
          .listRowBackground(entry.key == targetKey ? Color.purple.opacity(0.12) : nil)
        }
      }

      HStack(spacing: 8) {
        Button(prefetching ? "Prefetching…" : "Trigger prefetch") {
          triggerPrefetch()
        }
        .disabled(!canPrefetch || prefetching)

        Button("Refresh") {
          refresh()
        }
        .disabled(loading)

        Button("Clear", role: .destructive) {
          clearing = true
          _ = cache.clearAll()
          refresh()
          clearing = false
        }
        .disabled(clearing)
      }
    }
    .onAppear {
      refresh()
    }
  }

  private func entryTitle(_ entry: ManifestResolveCache.Summary) -> String {
    if entry.locale.isEmpty {
      return entry.channelId
    }
    return "\(entry.channelId) · \(entry.locale)"
  }

  private func cacheLine(_ entry: ManifestResolveCache.Summary) -> String {
    let when = entry.cachedAt > 0
      ? Date(timeIntervalSince1970: entry.cachedAt).formatted(date: .abbreviated, time: .shortened)
      : "unknown"
    let store = entry.inMemory ? "memory" : "disk"
    return "cached \(when) · \(store)"
  }

  private func refresh() {
    loading = true
    entries = cache.listEntries()
    loading = false
  }

  private func triggerPrefetch() {
    guard let config = prefetchConfig else { return }
    prefetching = true
    let client = RheoAPIClient(config: config)
    let channel = trimmedChannel
    Task {
      defer {
        Task { @MainActor in
          prefetching = false
        }
      }
      _ = try? await client.resolve(channelId: channel)
      await MainActor.run {
        refresh()
      }
    }
  }
}
