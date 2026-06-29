// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "RheoExampleSwiftUI",
  platforms: [
    .iOS(.v16),
  ],
  dependencies: [
    .package(path: "rheo-swiftui/packages/sdks/swiftui"),
  ],
  targets: [
    .executableTarget(
      name: "RheoExampleApp",
      dependencies: [
        .product(name: "RheoSwiftUI", package: "swiftui"),
        .product(name: "RheoSwiftUIAppsFlyer", package: "swiftui"),
      ],
      path: "Sources/RheoExampleApp",
      resources: [
        .process("../../Support"),
      ],
    ),
  ]
)
