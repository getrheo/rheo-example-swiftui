import SwiftUI

struct ConfigScreen: View {
  @EnvironmentObject private var shell: RheoExampleShellModel
  @State private var config = ExampleConfigStore.load()
  @State private var showFlow = false

  var body: some View {
    Form {
      Section {
        Text("Test the Rheo SDK")
            .font(.title2.bold())
            .foregroundStyle(.primary)
            .listRowBackground(Color.clear)
      }

      Section("Connection") {
          LabeledContent("Publishable key") {
            TextField("ob_pk_test_...", text: $config.publishableKey)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .multilineTextAlignment(.trailing)
          }
          LabeledContent("Channel id") {
            TextField("ch_test_...", text: $config.channelId)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .multilineTextAlignment(.trailing)
          }
          LabeledContent("API base URL") {
            TextField("https://api.getrheo.io", text: $config.apiBaseUrl)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .keyboardType(.URL)
              .multilineTextAlignment(.trailing)
          }
          Text("Default is production. Local API: http://127.0.0.1:4000 with the API on port 4000.")
            .font(.caption)
            .foregroundStyle(.secondary)
      }

      Section("Identity") {
          LabeledContent("User id") {
            TextField("example-user", text: $config.userId)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .multilineTextAlignment(.trailing)
          }
          Text("Forwarded as identity.appUserId on every event.")
            .font(.caption)
            .foregroundStyle(.secondary)
      }

      Section("Flow chrome") {
        Toggle("Hide navigation bar in flow", isOn: $config.hideFlowNavigationBar)
        Text(
          "Hides the navigation title and back button while the flow is running. "
            + "Use for full-screen onboarding."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      Section("Resolve fallback") {
        Toggle("Offline resolve fallback", isOn: $config.useResolveFallback)
        Text(
          "When resolve fails, show hardcoded example UI instead of the SDK default error. "
            + "Turn off to see “Error to load the content” and Try again."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
      }

      ManifestPrefetchSection(
        channelId: config.channelId,
        publishableKey: config.publishableKey,
        apiBaseURL: config.apiBaseUrl,
        userId: config.userId,
        locale: "en"
      )

      Section {
        Button("Start flow") {
            ExampleConfigStore.save(config)
            shell.syncFromSavedConfig(config)
            showFlow = true
          }
          .disabled(!config.canStart)
          .fontWeight(.semibold)

        Button("Reset config", role: .destructive) {
          ExampleConfigStore.reset()
          shell.clearShell()
          config = .empty
        }
      }
    }
      .navigationTitle("Rheo Example")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(isPresented: $showFlow) {
        FlowScreen(hideNavigationBar: config.hideFlowNavigationBar)
      }
  }
}

struct FlowBackButton: View {
  @Environment(\.dismiss) private var dismiss
  var title: String

  var body: some View {
    Button {
      dismiss()
    } label: {
      HStack(spacing: 4) {
        Image(systemName: "chevron.left")
          .fontWeight(.semibold)
        Text(title)
      }
    }
  }
}
