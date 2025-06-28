# Dials

Local-first, cockpit-style controller for macOS system settings.  
First dial implemented: **audio balance**. Quickly pan the default output device hard-left/right or anywhere in between, list available output devices, and pave the way for future controls like AirPlay routing, display modes, and preset profiles.

---

## Requirements

* macOS 13 or later (for `kAudioObjectPropertyElementMain` constants)
* Swift 5.10 toolchain (comes with Xcode 15.3 or newer) – Swift Package Manager is used for builds.

---

## Build & Run

Clone (or drop the sources in a folder) and let SwiftPM do the rest:

```bash
# build in debug (default)
swift build

# run the CLI
a./swift run dials --help

# examples
swift run dials balance --left      # hard-pan left
swift run dials balance --center    # centre
swift run dials balance -v 0.5      # 50 % right

swift run dials output list         # list output-capable devices
```

For the fastest binary, add the release flag:

```bash
swift build -c release
.build/release/dials --version
```

---

## Project layout & architecture

```
Dials/
├── Package.swift        ← SwiftPM manifest (dependencies & linker flags)
├── README.md            ← you are here
└── Sources/
    ├── main.swift       ← Root command that wires sub-commands together
    ├── AudioController.swift  ← Thin CoreAudio wrapper
    └── Commands/
        ├── Balance.swift ← `dials balance` implementation
        └── Output.swift  ← `dials output list` implementation
```

### 1. Swift ArgumentParser

We rely on [swift-argument-parser](https://github.com/apple/swift-argument-parser) for ergonomic CLI parsing.
Each feature lives in its own `ParsableCommand` under `Sources/Commands/` so adding a new dial is as simple as:

```swift
struct AirPlay: ParsableCommand { /* … */ }
```

and registering it in `main.swift`:

```swift
subcommands: [Balance.self, Output.self, AirPlay.self]
```

### 2. AudioController

`AudioController` wraps the messy CoreAudio C APIs and exposes:

* `setBalance(Float)` – converts a pan value (−1…1) into per-channel scalar volumes and writes them with `AudioObjectSetPropertyData`.
* `allOutputDevices()` – enumerates devices via `kAudioHardwarePropertyDevices` and filters those with output channels using `UnsafeMutableAudioBufferListPointer`.
* `defaultOutputDeviceID` – helper to fetch the current default sink.

Only the modern `kAudioObjectPropertyElementMain` constant is used, so we avoid deprecation warnings on macOS 12+.

### 3. Extensibility

Because every dial is an independent `ParsableCommand`, future features can plug in without touching existing code. Possible next steps:

* AirPlay / output routing (`dials route`)
* Display & projector presets (`dials display night-mode`)
* Profile files stored under `~/Library/Application Support/Dials/Presets`

---

## Roadmap

* [ ] `--device <id>` option to target non-default outputs
* [ ] Saving / loading presets
* [ ] SwiftUI menu-bar companion app

Contributions & bug-reports welcome – open an issue or PR.

# Raycast Integration

A ready-to-use Raycast script command is provided in the `raycast/` directory:

```
raycast/set-audio-balance.sh
```

This script lets you set the system audio balance (left, center, right) from Raycast using your `dials` CLI.

## Usage
1. Build and install the `dials` binary as described above (make sure it's in `/usr/local/bin` or your `$PATH`).
2. Copy or symlink `raycast/set-audio-balance.sh` to your Raycast Script Commands directory (usually `~/Raycast/Scripts/`)
3. [Make sure your ~/Raycast/Scripts/ is added in Extensions](https://github.com/raycast/script-commands?tab=readme-ov-file#install-script-commands-from-this-repository).
4. In Raycast `Reload Script Directories`
3. In Raycast, search for "Set Audio Balance" and enter `left`, `center`, or `right` as the argument.

The script will call your CLI and show the result in Raycast. 