# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Dials** is a macOS system control utility that provides "cockpit-style" control for media I/O operations. It functions as both a command-line tool and a menu bar app, with the first implemented feature being **audio balance control**. The project is built using Swift Package Manager and targets macOS 13+.

## Build System

### Make Commands (Primary Interface)
The comprehensive Makefile provides the main interface for development:

```bash
# Development
make build         # Quick debug build (default)
make debug         # Build debug version
make release       # Build release version
make dev           # Development mode with auto-reload
make watch         # Watch files for changes

# App Bundle & Distribution
make app           # Create app bundle
make dmg           # Create DMG installer
make install-app   # Install app to /Applications
make install       # Install CLI to /usr/local/bin

# Quick Commands
make command-center    # Launch as menu bar app
make balance-left      # Set audio balance to left
make balance-center    # Center audio balance
make balance-right     # Set balance to right
make list-outputs      # List audio devices
make list-displays     # List display devices

# Maintenance
make clean         # Clean build artifacts
make test          # Run tests
make help          # Show all available commands
```

### Alternative Build Methods
```bash
# Direct Swift Package Manager
swift build                    # Debug build
swift build -c release        # Release build
swift run dials --help        # Run CLI directly

# Build scripts
./build.sh                     # Release build
./build.sh --debug            # Debug build  
./build.sh --install          # Build and install
./dev.sh                      # Development with file watching
```

## Architecture

### Core Design Patterns
1. **SDK-Centric Architecture**: All functionality is centralized in the `Dials` SDK (`Sources/Services/Dials.swift`)
2. **Command Pattern**: CLI commands are individual `ParsableCommand` structs in `Sources/Commands/`
3. **Dual Interface**: Same functionality exposed via CLI and SwiftUI menu bar app
4. **Service Layer**: Core system interactions handled by dedicated services

### Key Components

#### 1. Entry Point (`Sources/main.swift`)
- Root `DialsCLI` command using Swift ArgumentParser
- Registers all subcommands and sets `CommandCenter` as default
- Version: 0.2.0

#### 2. Dials SDK (`Sources/Services/Dials.swift`)
Central API providing three modules:
- `Dials.Audio` - Audio balance and device management
- `Dials.Display` - Display enumeration and control  
- `Dials.Fixes` - System repair utilities (AirPlay issues, etc.)

#### 3. Menu Bar App (`Sources/Commands/CommandCenter.swift`)
- Full-featured SwiftUI interface with global hotkey (Hyper+D)
- Status bar icon "◉" with dropdown menu
- Floating Command Center window with grid of system controls
- App Intents integration for Siri/Shortcuts support

#### 4. Service Layer
- `AudioService.swift` - CoreAudio wrapper for balance/device control
- `DisplayService.swift` - IOKit display management  
- `SystemCommand.swift` - Secure system command execution
- `NotificationWindow.swift` - Custom notification system

#### 5. CLI Commands
All commands inherit from `ParsableCommand`:
- `Balance.swift` - Audio balance control (--left, --center, --right)
- `Output.swift` - Audio device listing and info
- `Display.swift` - Display management
- `Show.swift` - Launcher integration command
- `Build.swift` - Development utilities

### Frameworks & Dependencies
- **Swift ArgumentParser** - CLI parsing and command structure
- **CoreAudio/AudioToolbox** - Low-level audio device control
- **CoreGraphics/ApplicationServices** - Display management
- **SwiftUI/AppKit** - Menu bar app and UI
- **AppIntents** - Siri and Shortcuts integration

## Development Workflow

### Testing Audio Balance
```bash
# Test basic functionality
make balance-left
make balance-center  
make balance-right

# List available devices
make list-outputs

# Test menu bar app
make command-center
```

### Development Mode
```bash
# Auto-rebuilding file watcher
make dev
# or
./dev.sh

# Manual development workflow
make debug
.build/debug/dials balance --help
```

### App Bundle Development
```bash
# Create and test app bundle
make app
open Dials.app

# Install for system-wide testing
make install-app
```

## Integration Features

### App Intents (Siri/Shortcuts)
- Registered intents: Balance Left/Center/Right, Set Balance, Get Balance
- System-wide availability after installing app bundle
- See `Sources/Intents/` for implementation

### Launcher Integration
- **Hyper-D Global Hotkey**: Shift+Option+Control+Command+D
- **Launcher Command**: `dials show` - shows Command Center window
- **Menu Bar**: Always-available status item with quick actions
- Raycast script included in `raycast/set-audio-balance.sh`

### Distribution
- **DMG Creation**: `make dmg` creates installer with `scripts/create-dmg.sh`
- **CLI Installation**: `make install` installs to `/usr/local/bin`
- **App Installation**: `make install-app` installs to `/Applications`

## Key Technical Details

### Audio Control
- Uses modern `kAudioObjectPropertyElementMain` constants (macOS 13+ required)
- Pan values: 0.0 (full left) to 1.0 (full right), 0.5 (center)
- Direct CoreAudio property manipulation for precise control

### Menu Bar Architecture
- `LSUIElement` = true (no dock icon, menu bar only)
- `MenuBarAppDelegate` manages lifecycle and global hotkeys
- Dynamic activation policy switching for window presentation
- Background process with distributed notifications for IPC

### System Command Execution
- Secure execution of system commands with sudo handling
- Process monitoring and cleanup
- Custom notification system for user feedback
- Support for AirPlay troubleshooting and display control

## Common Development Tasks

### Adding New Commands
1. Create new `ParsableCommand` in `Sources/Commands/`
2. Add corresponding method to `Dials` SDK in `Sources/Services/Dials.swift`
3. Register command in `main.swift` subcommands array
4. Update Makefile with quick command if needed

### Extending Audio Features
- Core logic in `Sources/Services/AudioService.swift`
- Expose via `Dials.Audio` namespace
- Add CLI command and menu bar UI elements

### Display/Video Features
- Implementation in `Sources/Services/DisplayService.swift`  
- IOKit-based display enumeration and control
- DDC (Display Data Channel) support for external monitors