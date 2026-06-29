import Foundation

/// Optional AppsFlyer setup for the SwiftUI example (mirrors `apps/example-expo/lib/appsFlyerBootstrap.ts`).
enum AppsFlyerExampleBootstrap {
  private static let devKeyPlistKey = "RHEO_EXAMPLE_APPSFLYER_DEV_KEY"
  private static let iosAppIdPlistKey = "RHEO_EXAMPLE_APPSFLYER_IOS_APP_ID"

  /// True when Info.plist includes a non-empty dev key (opt-in for local MMP testing).
  static var isConfigured: Bool {
    guard let devKey = Bundle.main.object(forInfoDictionaryKey: devKeyPlistKey) as? String else {
      return false
    }
    return !devKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  static func prepare(customerUserId: String) {
    guard isConfigured else { return }
    prepareImpl(customerUserId: customerUserId)
  }

  fileprivate static func prepareImpl(customerUserId: String) {
    #if canImport(AppsFlyerLib)
    prepareWithAppsFlyerLib(customerUserId: customerUserId)
    #else
    print(
      "[rheo-example-swiftui] AppsFlyer keys present in Info.plist but AppsFlyerLib is not linked — add the SDK to exercise attribution."
    )
    #endif
  }
}

#if canImport(AppsFlyerLib)
import AppsFlyerLib

extension AppsFlyerExampleBootstrap {
  private static var didInitialize = false

  fileprivate static func prepareWithAppsFlyerLib(customerUserId: String) {
    let devKey = (Bundle.main.object(forInfoDictionaryKey: devKeyPlistKey) as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let appId = (Bundle.main.object(forInfoDictionaryKey: iosAppIdPlistKey) as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    guard !devKey.isEmpty else { return }

    let lib = AppsFlyerLib.shared()
    lib.appsFlyerDevKey = devKey
    if !appId.isEmpty {
      lib.appleAppID = appId
    }
    if !didInitialize {
      lib.start()
      didInitialize = true
    }
    let uid = customerUserId.trimmingCharacters(in: .whitespacesAndNewlines)
    if !uid.isEmpty {
      lib.customerUserID = uid
    }
  }
}
#endif
