# Dials

**Version 0.2.0** - A cockpit-style controller for macOS system settings.

Dials provides intuitive control over macOS media I/O with both a powerful menu bar app and command-line interface. Control audio balance, manage displays, fix AirPlay issues, and more - all from your menu bar or terminal.

## Features

### 🎵 Audio Control
- **Precise Balance Control** - Pan audio left, right, or center with visual feedback
- **Device Management** - List and inspect all audio output devices
- **Real-time Updates** - Instant changes with notification feedback

### 📱 Multiple Interfaces
- **Menu Bar App** - Always-available status bar icon with quick controls
- **Command Center** - Beautiful SwiftUI interface with system commands
- **CLI Tool** - Full terminal interface for scripting and power users
- **App Intents** - Siri and Shortcuts integration

### 🚀 Quick Access
- **Global Hotkey** - Hyper+D (Shift+Option+Control+Command+D) for instant access
- **Launcher Integration** - Works with Raycast, Alfred, Hyper-D, and more
- **Menu Bar Quick Actions** - Balance controls right from the status bar

### 🛠 System Utilities
- **AirPlay Fixes** - Reset stuck mirroring and force-stop AirPlay processes
- **Display Management** - List displays and control external monitors
- **Smart Notifications** - Contextual feedback with auto-dismiss

---

## Installation

### Quick Install (Recommended)
```bash
# Clone the repository
git clone https://github.com/arach/dials.git
cd dials

# Build and install the app to /Applications
make install-app

# Optionally install CLI to /usr/local/bin
make install
```

### Manual Build
```bash
# Build app bundle
make app

# Or use Swift directly
swift build -c release
```

---

## Usage

### Menu Bar App
1. Launch Dials from Applications or run `open /Applications/Dials.app`
2. Look for the "◉" icon in your menu bar
3. Click for quick controls or use **Hyper+D** for the Command Center

### Command Line
```bash
# Audio balance controls
dials balance --left        # Pan to left speaker
dials balance --center      # Center balance
dials balance --right       # Pan to right speaker
dials balance               # Show current balance dial

# Device information
dials output list           # List all audio devices
dials output info           # Default device details

# Display management
dials display list          # List connected displays
dials display off 0x1       # Turn off specific display

# System fixes
dials fixes reset-airplay   # Reset AirPlay mirroring
dials fixes force-stop      # Force stop AirPlay processes

# Launcher integration
dials show                  # Show Command Center window
```

### Siri & Shortcuts
After installing the app, you can use:
- "Hey Siri, balance audio with Dials"
- "Hey Siri, balance left with Dials"
- "Hey Siri, set audio balance to 75 percent with Dials"

---

## Launcher Integration

### Raycast
1. Create a Script Command with: `dials show`
2. Set keyword to "dials"
3. Or use the provided script in `raycast/set-audio-balance.sh`

### Alfred
1. Create a Workflow with keyword trigger
2. Connect to Run Script action: `/usr/local/bin/dials show`

### Hyper-D
Add `dials show` to your Hyper-D configuration.

---

## Development

### Build System
The comprehensive Makefile provides all development commands:

```bash
# Development
make build          # Debug build (default)
make dev           # Auto-rebuilding file watcher
make watch         # Watch files for changes

# Distribution
make app           # Create app bundle
make dmg           # Create DMG installer
make install-app   # Install to /Applications
make install       # Install CLI to /usr/local/bin

# Quick commands (with auto-build)
make command-center    # Launch menu bar app
make balance-left      # Pan audio left
make list-outputs      # Show audio devices
make help             # Show all commands
```

### Requirements
- **macOS 13+** (for modern CoreAudio constants)
- **Swift 5.10+** (Xcode 15.3+)
- **Swift Package Manager** (included with Xcode)

### Architecture

Dials uses a clean, modular architecture:

```
Dials/
├── Sources/
│   ├── main.swift                  ← CLI entry point
│   ├── Commands/                   ← CLI commands
│   │   ├── Balance.swift           ← Audio balance control
│   │   ├── CommandCenter.swift     ← Menu bar app
│   │   ├── Show.swift              ← Launcher integration
│   │   └── ...
│   ├── Services/                   ← Core functionality
│   │   ├── Dials.swift             ← Main SDK
│   │   ├── AudioService.swift      ← Audio control
│   │   ├── DisplayService.swift    ← Display management
│   │   └── ...
│   ├── Intents/                    ← App Intents (Siri)
│   └── Views/                      ← SwiftUI components
├── scripts/                        ← Build and distribution
└── Documentation/
    ├── APP_INTENTS.md              ← Siri integration guide
    ├── LAUNCHER_SETUP.md           ← Launcher configuration
    └── CLAUDE.md                   ← Development guide
```

**Key Design Principles:**
- **SDK-Centric** - All functionality accessed through `Dials` SDK
- **Dual Interface** - Same features available in CLI and GUI
- **Modular Commands** - Each feature is an independent `ParsableCommand`
- **Service Layer** - Clean separation of system interactions

---

## Technical Details

### Audio Control
- Uses modern CoreAudio APIs with `kAudioObjectPropertyElementMain`
- Precise stereo pan control (0.0 = left, 0.5 = center, 1.0 = right)
- Device enumeration and detailed property inspection
- Real-time balance reading with visual dial display

### Menu Bar App
- Background process with no dock icon (`LSUIElement`)
- Global hotkey monitoring with proper cleanup
- Dynamic activation policy for window presentation
- Custom notification system with auto-dismiss

### App Intents Integration
- Native iOS/macOS shortcuts support
- Parameterized intents for custom balance values
- Voice control through Siri
- Spotlight integration

---

## Roadmap

### Current (v0.2.0)
- ✅ Menu bar app with Command Center UI
- ✅ App Intents for Siri/Shortcuts
- ✅ Global hotkey (Hyper+D)
- ✅ Launcher integration
- ✅ System fixes for AirPlay issues
- ✅ Visual balance dial display
- ✅ DMG distribution

### Next Release (v0.3.0)
- [ ] Audio device switching and routing
- [ ] Preset profiles and quick-switch
- [ ] Display brightness and color temperature
- [ ] Enhanced AirPlay management
- [ ] Notification customization

### Future
- [ ] Plugin system for third-party dials
- [ ] Touch Bar integration
- [ ] Stream Deck support
- [ ] Web interface for remote control

---

## Contributing

Contributions welcome! The modular architecture makes it easy to add new features:

1. **New Commands** - Add `ParsableCommand` in `Sources/Commands/`
2. **Services** - Extend functionality in `Sources/Services/`
3. **UI Components** - Add SwiftUI views in `Sources/Views/`
4. **Documentation** - Update relevant `.md` files

See [CLAUDE.md](CLAUDE.md) for detailed development guidance.

---

## License

MIT License - see LICENSE file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/arach/dials/issues)
- **Documentation**: See `APP_INTENTS.md` and `LAUNCHER_SETUP.md`
- **Development**: See `CLAUDE.md` for comprehensive development guide