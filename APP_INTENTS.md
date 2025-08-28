# Dials App Intents

Dials now supports App Intents, allowing you to control audio balance through Siri, Shortcuts, and Spotlight!

## Available Intents

### Quick Balance Actions
- **Balance Left** - Set audio balance to full left
- **Balance Center** - Center the audio balance
- **Balance Right** - Set audio balance to full right
- **Get Balance** - Check current balance setting

### Custom Balance
- **Set Balance** - Set balance to a specific percentage (0-100)

## Usage Examples

### Siri
- "Hey Siri, balance audio with Dials"
- "Hey Siri, balance left with Dials"
- "Hey Siri, set audio balance to 75 percent with Dials"
- "Hey Siri, what's my audio balance with Dials"

### Shortcuts App
1. Open the Shortcuts app
2. Search for "Dials" 
3. You'll see all available balance actions
4. Create custom shortcuts combining multiple actions

### Spotlight
- Search for "Balance" in Spotlight
- Dials balance actions will appear in results

## Installation

1. Build and install the app:
   ```bash
   make install-app
   ```

2. Launch Dials once to register the intents:
   ```bash
   open /Applications/Dials.app
   ```

3. The intents should now be available system-wide

## Creating Custom Shortcuts

Example shortcut ideas:
- **Morning Routine**: Balance center when starting work
- **Movie Time**: Balance left for your preferred speaker setup
- **Focus Mode**: Automatically adjust balance when entering focus

## Technical Details

The App Intents integration:
- Uses the native AppIntents framework (macOS 13+)
- Calls the Dials SDK directly (no shell overhead)
- Provides visual feedback in Shortcuts
- Supports parameterized intents for custom values
- Returns success/failure status

## Troubleshooting

If intents don't appear:
1. Make sure Dials.app is in /Applications
2. Launch the app at least once
3. Check System Preferences > Privacy & Security
4. Try rebuilding with `make clean && make install-app`