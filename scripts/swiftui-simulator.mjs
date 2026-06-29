import { execFileSync } from 'node:child_process';

export const DEFAULT_SWIFTUI_SIMULATOR_NAME = 'iPhone 17 Pro';

export const listIosSimulators = () => {
  const json = execFileSync('xcrun', ['simctl', 'list', 'devices', 'available', '-j'], {
    encoding: 'utf8',
  });
  const devices = JSON.parse(json).devices ?? {};
  const simulators = [];

  for (const [runtime, runtimeDevices] of Object.entries(devices)) {
    const osVersion = parseIosRuntimeVersion(runtime);
    if (!osVersion) continue;
    for (const device of runtimeDevices) {
      if (!device.isAvailable) continue;
      simulators.push({
        udid: device.udid,
        name: device.name,
        osVersion,
        runtime,
        state: device.state,
      });
    }
  }

  simulators.sort((a, b) => {
    const osCmp = compareVersion(b.osVersion, a.osVersion);
    if (osCmp !== 0) return osCmp;
    if (a.state === 'Booted' && b.state !== 'Booted') return -1;
    if (b.state === 'Booted' && a.state !== 'Booted') return 1;
    return a.name.localeCompare(b.name);
  });

  return simulators;
};

const parseIosRuntimeVersion = (runtime) => {
  const match = runtime.match(/SimRuntime\.iOS-(\d+)-(\d+)/);
  if (!match) return null;
  return `${match[1]}.${match[2]}`;
};

const compareVersion = (a, b) => {
  const aParts = a.split('.').map((part) => Number.parseInt(part, 10));
  const bParts = b.split('.').map((part) => Number.parseInt(part, 10));
  const length = Math.max(aParts.length, bParts.length);
  for (let i = 0; i < length; i += 1) {
    const diff = (aParts[i] ?? 0) - (bParts[i] ?? 0);
    if (diff !== 0) return diff;
  }
  return 0;
};

export const findSimulator = (simulators, name, osVersion) => {
  const matches = simulators.filter((s) => s.name === name && s.osVersion === osVersion);
  if (matches.length === 0) return null;
  return matches.find((s) => s.state === 'Booted') ?? matches[0];
};

const formatDestination = (sim) =>
  `platform=iOS Simulator,name=${sim.name},OS=${sim.osVersion}`;

/** Resolve an xcodebuild -destination for iOS Simulator tests/builds. */
export const resolveIosSimulatorDestination = () => {
  const override = process.env.SWIFTUI_SIMULATOR_DESTINATION?.trim();
  if (override) return override;

  const preferredName =
    process.env.SWIFTUI_SIMULATOR_NAME?.trim() || DEFAULT_SWIFTUI_SIMULATOR_NAME;
  const preferredOs = process.env.SWIFTUI_SIMULATOR_OS?.trim();

  const simulators = listIosSimulators();
  if (simulators.length === 0) {
    throw new Error(
      'No available iOS simulators. Install an iOS runtime in Xcode (Settings → Platforms).',
    );
  }

  if (preferredOs) {
    const exact = findSimulator(simulators, preferredName, preferredOs);
    if (exact) return formatDestination(exact);
    console.warn(
      `[swiftui-sdk] Simulator ${preferredName} (iOS ${preferredOs}) not found; using newest available for that device.`,
    );
  }

  const byName = simulators.filter((s) => s.name === preferredName);
  if (byName.length > 0) return formatDestination(byName[0]);

  const iphone = simulators.find((s) => s.name.includes('iPhone'));
  if (iphone) {
    console.warn(
      `[swiftui-sdk] Simulator ${preferredName} not found; using ${iphone.name} (iOS ${iphone.osVersion}).`,
    );
    return formatDestination(iphone);
  }

  console.warn(
    `[swiftui-sdk] No iPhone simulator found; using ${simulators[0].name} (iOS ${simulators[0].osVersion}).`,
  );
  return formatDestination(simulators[0]);
};
