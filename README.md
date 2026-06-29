# rheo-example-swiftui

Runnable **SwiftUI** sample for **RheoSwiftUI** — config screen, then `RheoProvider` + `FlowView`.

Not published to npm.

## Quick start

```bash
git clone --recurse-submodules https://github.com/getrheo/rheo-example-swiftui.git
cd rheo-example-swiftui
pnpm install
pnpm build    # iOS Simulator via Xcode
pnpm run      # build, install, and launch on a simulator
```

Or open `Package.swift` in Xcode, select the **RheoExampleSwiftUI** scheme, and run on an iPhone simulator.

The SDK is pinned via git submodule [`rheo-swiftui`](https://github.com/getrheo/rheo-swiftui) at `swiftui-v2.0.2`.

The config screen defaults to **`https://api.getrheo.io`**. Use `http://127.0.0.1:4000` when testing against a local API.

## SDK repository

[rheo-swiftui](https://github.com/getrheo/rheo-swiftui)

## Development

Requires **Xcode** with an iOS Simulator runtime.

```bash
pnpm install
pnpm verify   # guardrail scan (macOS job also runs pnpm build in CI)
```

[Documentation](https://docs.getrheo.io/docs/developer-guide/sdk-swiftui) · [CONTRIBUTING](./CONTRIBUTING.md) · [MIT](./LICENSE)
