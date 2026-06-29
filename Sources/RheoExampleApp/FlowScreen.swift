import RheoSwiftUI
import RheoSwiftUIAppsFlyer
import SwiftUI

struct FlowScreen: View {
  @Environment(\.dismiss) private var dismiss

  var hideNavigationBar: Bool = false

  @State private var bundle: FlowBundle?
  @State private var missingConfig = false

  var body: some View {
    Group {
      if let bundle {
        flowContent(bundle: bundle)
      } else if missingConfig {
        Color.clear
      } else {
        VStack(spacing: 12) {
          ProgressView()
          Text("Loading config…")
            .foregroundStyle(.secondary)
        }
      }
    }
    .task {
      await loadBundle()
    }
    .onChange(of: missingConfig) { missing in
      if missing {
        dismiss()
      }
    }
    .navigationTitle(hideNavigationBar ? "" : "Flow")
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar(hideNavigationBar ? .hidden : .visible, for: .navigationBar)
    .toolbar {
      if !hideNavigationBar {
        ToolbarItem(placement: .topBarLeading) {
          FlowBackButton(title: "Config")
        }
      }
    }
  }

  @ViewBuilder
  private func flowContent(bundle: FlowBundle) -> some View {
    let appsFlyerMode: AppsFlyerAttributionMode =
      AppsFlyerExampleBootstrap.isConfigured ? .automatic : .off

    let completed: @Sendable (FlowTerminalSnapshot) -> Void = { snapshot in
      print("[rheo-example] Flow completed:", snapshot.terminal)
      dismiss()
    }
    let abandoned: @Sendable (FlowTerminalSnapshot) -> Void = { snapshot in
      print("[rheo-example] Flow abandoned:", snapshot.terminal)
      dismiss()
    }

    if bundle.useResolveFallback {
      FlowView(
        channelId: bundle.channelId,
        appsFlyerAttribution: appsFlyerMode,
        fallback: {
          OfflineResolveFallbackView {
            dismiss()
          }
        },
        onFlowCompleted: completed,
        onFlowAbandoned: abandoned,
        onOAuthLogin: handleOAuthLogin,
        onEmailPasswordAuth: handleEmailPasswordAuth
      )
    } else {
      FlowView(
        channelId: bundle.channelId,
        appsFlyerAttribution: appsFlyerMode,
        onFlowCompleted: completed,
        onFlowAbandoned: abandoned,
        onOAuthLogin: handleOAuthLogin,
        onEmailPasswordAuth: handleEmailPasswordAuth
      )
    }
  }

  @MainActor
  private func loadBundle() async {
    let saved = ExampleConfigStore.load()
    guard saved.canStart else {
      missingConfig = true
      return
    }
    let userId = saved.userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? "example-user"
      : saved.userId.trimmingCharacters(in: .whitespacesAndNewlines)
    AppsFlyerExampleBootstrap.prepare(customerUserId: userId)

    bundle = FlowBundle(
      channelId: saved.channelId.trimmingCharacters(in: .whitespacesAndNewlines),
      useResolveFallback: saved.useResolveFallback
    )
  }

  private func handleOAuthLogin(_ payload: OAuthLoginHandlerPayload) {
    let providerName = payload.provider.provider ?? payload.provider.type
    print("[rheo-example] OAuth tap", providerName, payload.screenId)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
      payload.resolve(
        OAuthLoginResolveInput(
          success: true,
          customerExternalId: "example_\(providerName)"
        )
      )
    }
  }

  private func handleEmailPasswordAuth(_ payload: EmailPasswordAuthHandlerPayload) {
    print("[rheo-example] Email/password", payload.mode.rawValue, payload.screenId)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      payload.resolve(EmailPasswordAuthResolveInput(success: true))
    }
  }
}

private struct FlowBundle {
  var channelId: String
  var useResolveFallback: Bool
}
