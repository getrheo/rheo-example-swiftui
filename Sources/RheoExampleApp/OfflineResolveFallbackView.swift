import SwiftUI

private struct OfflineFallbackStep {
  var title: String
  var body: String
}

private let offlineFallbackSteps: [OfflineFallbackStep] = [
  OfflineFallbackStep(
    title: "Offline onboarding",
    body: "Rheo could not load your flow from the API. This screen is hardcoded in the example app — your escape hatch when resolve fails."
  ),
  OfflineFallbackStep(
    title: "Ship your own flow",
    body: "Pass a `fallback` view builder to `FlowView` with any SwiftUI you want. Rheo does not emit events on this surface."
  ),
  OfflineFallbackStep(
    title: "Try again later",
    body: "Dismiss and fix the API URL on the config screen when your backend is reachable again."
  ),
]

struct OfflineResolveFallbackView: View {
  var onExit: () -> Void
  @State private var step = 0

  private var content: OfflineFallbackStep {
    offlineFallbackSteps[step]
  }

  private var isLast: Bool {
    step >= offlineFallbackSteps.count - 1
  }

  var body: some View {
    VStack(spacing: 24) {
      VStack(alignment: .leading, spacing: 12) {
        Text("EXAMPLE · RESOLVE FALLBACK")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Text(content.title)
          .font(.title2.bold())
        Text(content.body)
          .font(.body)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
        Text("Step \(step + 1) of \(offlineFallbackSteps.count)")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(20)
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))

      Button {
        if isLast {
          onExit()
        } else {
          step += 1
        }
      } label: {
        Text(isLast ? "Back to config" : "Continue")
          .fontWeight(.semibold)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
