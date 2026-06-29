import RheoSwiftUI
import SwiftUI

@MainActor
final class RheoExampleShellModel: ObservableObject {
  @Published private(set) var shellConfig: RheoConfig?

  func reloadFromStorage() {
    let saved = ExampleConfigStore.load()
    shellConfig = saved.buildRheoConfig()
  }

  func syncFromSavedConfig(_ config: ExampleConfig) {
    shellConfig = config.buildRheoConfig()
  }

  func clearShell() {
    shellConfig = nil
  }
}

/// Single app-root `RheoProvider` for the example app (no automatic prefetch).
struct RheoExampleShell<Content: View>: View {
  @StateObject private var model = RheoExampleShellModel()
  @ViewBuilder private let content: () -> Content

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }

  var body: some View {
    Group {
      if let config = model.shellConfig {
        RheoProvider(config: config) {
          content()
        }
      } else {
        content()
      }
    }
    .environmentObject(model)
    .task {
      model.reloadFromStorage()
    }
  }
}
