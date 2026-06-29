#!/usr/bin/env node
/**
 * Build (and optionally launch) the Rheo SwiftUI example app on the iOS Simulator.
 *
 * SwiftPM `executableTarget` builds a bare binary; this script wraps it in
 * RheoExampleApp.app so `simctl install` can run it on a simulator.
 *
 * Interactive device picker (TTY): run without SWIFTUI_SIMULATOR_* set, or pass --pick.
 * Non-interactive: SWIFTUI_SIMULATOR_NAME + SWIFTUI_SIMULATOR_OS, or --device + --os.
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline/promises';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const exampleDir = repoRoot;
const derivedData = path.join(exampleDir, '.derivedData');
const bundleId = 'app.rheo.example.swiftui';
const scheme = 'RheoExampleSwiftUI';
const defaultSimulatorName = 'iPhone 17 Pro';
const defaultSimulatorOs = '26.5';

const args = parseArgs(process.argv.slice(2));
if (!args.mode) {
  console.error(
    'Usage: node scripts/run-swiftui-example.mjs <build|run> [--pick] [--device NAME] [--os VERSION]',
  );
  process.exit(1);
}

const selection = await resolveSimulatorSelection(args);
const destination = `platform=iOS Simulator,name=${selection.name},OS=${selection.osVersion}`;

requireCommand(
  'xcodebuild',
  ['-version'],
  'Xcode is required. Install Xcode and run:\n  xcode-select -s /Applications/Xcode.app/Contents/Developer',
);

console.log(
  `[example-swiftui] ${args.mode} (scheme=${scheme}, destination=${destination})`,
);

execFileSync(
  'xcodebuild',
  [
    'build',
    '-scheme',
    scheme,
    '-destination',
    destination,
    '-derivedDataPath',
    derivedData,
    '-skipPackagePluginValidation',
  ],
  { cwd: exampleDir, stdio: 'inherit' },
);

const appPath = findBuiltApp();
if (!appPath) {
  console.error(
    '[example-swiftui] Built RheoExampleApp binary not found under .derivedData/Build/Products.',
  );
  process.exit(1);
}

if (args.mode === 'build') {
  console.log(`[example-swiftui] Built ${appPath}`);
  process.exit(0);
}

const simId = ensureBooted(selection);
execFileSync('xcrun', ['simctl', 'install', simId, appPath], { stdio: 'inherit' });
execFileSync('xcrun', ['simctl', 'launch', simId, bundleId], { stdio: 'inherit' });
console.log(
  `[example-swiftui] Launched ${bundleId} on ${selection.name} (iOS ${selection.osVersion})`,
);

function parseArgs(argv) {
  const parsed = { mode: null, pick: false, device: null, os: null };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === 'build' || arg === 'run') parsed.mode = arg;
    else if (arg === '--pick') parsed.pick = true;
    else if (arg === '--device') parsed.device = argv[++i] ?? null;
    else if (arg === '--os') parsed.os = argv[++i] ?? null;
    else if (arg.startsWith('--device=')) parsed.device = arg.slice('--device='.length);
    else if (arg.startsWith('--os=')) parsed.os = arg.slice('--os='.length);
  }
  return parsed;
}

async function resolveSimulatorSelection(cli) {
  const envName = process.env.SWIFTUI_SIMULATOR_NAME;
  const envOs = process.env.SWIFTUI_SIMULATOR_OS;
  const simulators = listIosSimulators();

  if (cli.device) {
    const osVersion = cli.os ?? envOs ?? defaultSimulatorOs;
    const match = findSimulator(simulators, cli.device, osVersion);
    if (!match) {
      throw new Error(`Simulator not found: ${cli.device} (iOS ${osVersion})`);
    }
    return match;
  }

  if (envName && envOs && !cli.pick) {
    const match = findSimulator(simulators, envName, envOs);
    if (!match) {
      throw new Error(`Simulator not found: ${envName} (iOS ${envOs})`);
    }
    return match;
  }

  const wantsInteractivePick = cli.pick || (!envName && !envOs);
  if (wantsInteractivePick && process.stdin.isTTY) {
    return pickSimulator(simulators);
  }
  if (cli.pick && !process.stdin.isTTY) {
    console.warn(
      '[example-swiftui] --pick requires an interactive terminal; using defaults or env vars.',
    );
  }

  const name = envName ?? defaultSimulatorName;
  const osVersion = envOs ?? defaultSimulatorOs;
  const match = findSimulator(simulators, name, osVersion);
  if (!match) {
    throw new Error(`Simulator not found: ${name} (iOS ${osVersion})`);
  }
  return match;
}

function findSimulator(simulators, name, osVersion) {
  const matches = simulators.filter((s) => s.name === name && s.osVersion === osVersion);
  if (matches.length === 0) return null;
  return matches.find((s) => s.state === 'Booted') ?? matches[0];
}

async function pickSimulator(simulators) {
  if (simulators.length === 0) {
    throw new Error('No available iOS simulators. Install an iOS runtime in Xcode.');
  }

  console.log('\nSelect a simulator to build and run RheoExampleApp:\n');
  for (const [index, sim] of simulators.entries()) {
    const booted = sim.state === 'Booted' ? ' · booted' : '';
    console.log(`  ${index + 1}) ${sim.name} — iOS ${sim.osVersion}${booted}`);
  }
  console.log('');

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    while (true) {
      const answer = (await rl.question(`Enter number (1–${simulators.length}), or q to quit: `))
        .trim()
        .toLowerCase();
      if (answer === 'q' || answer === 'quit') {
        console.log('[example-swiftui] Cancelled.');
        process.exit(0);
      }
      const index = Number.parseInt(answer, 10);
      if (Number.isFinite(index) && index >= 1 && index <= simulators.length) {
        const chosen = simulators[index - 1];
        console.log(`[example-swiftui] Using ${chosen.name} (iOS ${chosen.osVersion})\n`);
        return chosen;
      }
      console.log(`Invalid choice. Enter a number from 1 to ${simulators.length}.`);
    }
  } finally {
    rl.close();
  }
}

function listIosSimulators() {
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
}

function parseIosRuntimeVersion(runtime) {
  const match = runtime.match(/SimRuntime\.iOS-(\d+)-(\d+)/);
  if (!match) return null;
  return `${match[1]}.${match[2]}`;
}

function compareVersion(a, b) {
  const aParts = a.split('.').map((part) => Number.parseInt(part, 10));
  const bParts = b.split('.').map((part) => Number.parseInt(part, 10));
  const length = Math.max(aParts.length, bParts.length);
  for (let i = 0; i < length; i += 1) {
    const diff = (aParts[i] ?? 0) - (bParts[i] ?? 0);
    if (diff !== 0) return diff;
  }
  return 0;
}

function ensureBooted(selection) {
  if (selection.state === 'Booted') return selection.udid;
  execFileSync('xcrun', ['simctl', 'boot', selection.udid], { stdio: 'inherit' });
  openSimulatorApp();
  return selection.udid;
}

function requireCommand(command, cmdArgs, hint) {
  try {
    execFileSync(command, cmdArgs, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  } catch {
    console.error(hint);
    process.exit(1);
  }
}

function findBuiltApp() {
  const products = path.join(derivedData, 'Build/Products');
  if (!fs.existsSync(products)) return null;

  for (const config of fs.readdirSync(products)) {
    const configDir = path.join(products, config);
    if (!fs.statSync(configDir).isDirectory()) continue;

    const existingApp = path.join(configDir, 'RheoExampleApp.app');
    if (fs.existsSync(existingApp)) return existingApp;

    const wrapped = wrapExecutableAsAppBundle(configDir);
    if (wrapped) return wrapped;
  }

  return null;
}

function wrapExecutableAsAppBundle(configDir) {
  const binaryPath = path.join(configDir, 'RheoExampleApp');
  if (!fs.existsSync(binaryPath)) return null;

  const appPath = path.join(configDir, 'RheoExampleApp.app');
  if (fs.existsSync(appPath)) {
    fs.rmSync(appPath, { recursive: true, force: true });
  }
  fs.mkdirSync(appPath, { recursive: true });

  const plistSrc = path.join(exampleDir, 'Support/Info.plist');
  fs.copyFileSync(plistSrc, path.join(appPath, 'Info.plist'));
  fs.copyFileSync(binaryPath, path.join(appPath, 'RheoExampleApp'));

  for (const entry of fs.readdirSync(configDir)) {
    if (!entry.endsWith('.bundle')) continue;
    fs.cpSync(path.join(configDir, entry), path.join(appPath, entry), { recursive: true });
  }

  execFileSync(
    'codesign',
    ['--force', '--sign', '-', '--timestamp=none', '--generate-entitlement-der', appPath],
    { stdio: 'inherit' },
  );

  console.log(`[example-swiftui] Wrapped simulator app bundle at ${appPath}`);
  return appPath;
}

function openSimulatorApp() {
  try {
    execFileSync('open', ['-a', 'Simulator'], { stdio: 'ignore' });
  } catch {
    /* optional */
  }
}
