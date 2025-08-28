# Dials Launcher Integration

Dials now supports quick launch from Hyper-D, Raycast, Alfred, and other launchers!

## How It Works

The `dials show` command will:
1. Check if Dials is already running in the menu bar
2. If running, show the Command Center window
3. If not running, start Dials and show the Command Center

## Setup for Different Launchers

### Hyper-D
Add this to your Hyper-D configuration:
```
dials show
```

### Raycast
1. Create a Script Command
2. Set the script to:
   ```bash
   #!/bin/bash
   dials show
   ```
3. Set title to "Dials Command Center"
4. Set keyword to "dials"

### Alfred
1. Create a Workflow
2. Add a Script Filter or Keyword trigger
3. Connect to a Run Script action with:
   ```bash
   /usr/local/bin/dials show
   ```

### Spotlight
Unfortunately, Spotlight doesn't support custom commands, but you can:
1. Use the Shortcuts app to create a shortcut that runs `dials show`
2. The shortcut will then appear in Spotlight search

## Keyboard Shortcuts

In addition to launcher support:
- **Cmd+Shift+D**: Toggle Command Center window (when Dials is running)
- **Menu bar icon**: Click to access all commands

## Installation

Make sure Dials is installed:
```bash
make install-app  # Install the menu bar app
make install      # Install the CLI (optional, for terminal use)
```

## Troubleshooting

If the command doesn't work:
1. Make sure Dials.app is in /Applications
2. Try running `dials show` in Terminal to test
3. Check if Dials is already running in the menu bar
4. For some launchers, you may need the full path: `/usr/local/bin/dials show`

## Alternative Setup

If you prefer not to install the CLI globally, you can use the script directly:
```bash
~/dev/dials/scripts/dials-show.sh
```