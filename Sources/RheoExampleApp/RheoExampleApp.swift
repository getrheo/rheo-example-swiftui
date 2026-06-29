import SwiftUI

@main
struct RheoExampleApp: App {
  var body: some Scene {
    WindowGroup {
      RheoExampleShell {
        NavigationStack {
          ConfigScreen()
        }
      }
    }
  }
}
