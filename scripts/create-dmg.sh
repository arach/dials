#!/bin/bash

# Dials DMG Creator Script
# Creates a distributable DMG file for Dials

set -e

# Configuration
APP_NAME="Dials"
VERSION="0.2.1"
DMG_NAME="Dials-${VERSION}"
BUILD_DIR="dmg-build"
BACKGROUND_COLOR="#2C3E50"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if we're in the right directory
if [[ ! -f "Package.swift" ]] || [[ ! -f "Makefile" ]]; then
    print_error "This script must be run from the Dials project directory"
    exit 1
fi

# Build the app if it doesn't exist
if [[ ! -d "Dials.app" ]]; then
    print_step "Building Dials app..."
    make app
fi

# Clean up any existing build
if [[ -d "$BUILD_DIR" ]]; then
    print_step "Cleaning up previous build..."
    rm -rf "$BUILD_DIR"
fi

if [[ -f "${DMG_NAME}.dmg" ]]; then
    print_step "Removing existing DMG..."
    rm -f "${DMG_NAME}.dmg"
fi

# Create build directory
print_step "Setting up DMG contents..."
mkdir -p "$BUILD_DIR"

# Copy the app to build directory
cp -r "Dials.app" "$BUILD_DIR/"

# Create Applications symlink
ln -s /Applications "$BUILD_DIR/Applications"

# Create README for the DMG
cat > "$BUILD_DIR/README.txt" << 'EOF'
Welcome to Dials!

INSTALLATION:
1. Drag "Dials.app" to the "Applications" folder
2. Launch Dials from Applications or Spotlight
3. Look for the Dials icon in your menu bar

FEATURES:
• Control audio balance with precision
• Manage audio output devices
• Display controls and management
• Menu bar integration
• Raycast and Shortcuts support

USAGE:
The app runs in the background as a menu bar application.
You can also install the CLI tool using: make install

For more information, visit the project repository.
EOF

# Create installer script (optional CLI installation)
cat > "$BUILD_DIR/Install CLI.command" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

echo "Dials CLI Installer"
echo "=================="
echo ""

# Check if Dials.app exists
if [[ ! -d "Dials.app" ]]; then
    echo "❌ Dials.app not found in DMG"
    exit 1
fi

# Extract CLI from app bundle
CLI_BINARY="Dials.app/Contents/MacOS/Dials"
INSTALL_PATH="/usr/local/bin/dials"

if [[ ! -f "$CLI_BINARY" ]]; then
    echo "❌ CLI binary not found in app bundle"
    exit 1
fi

echo "Installing CLI to $INSTALL_PATH..."

# Check if we can write to the install path
if [[ -w "/usr/local/bin" ]]; then
    cp "$CLI_BINARY" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
else
    echo "Administrator privileges required..."
    sudo cp "$CLI_BINARY" "$INSTALL_PATH"
    sudo chmod +x "$INSTALL_PATH"
fi

echo "✅ CLI installed successfully!"
echo ""
echo "You can now use: dials --help"
EOF

chmod +x "$BUILD_DIR/Install CLI.command"

# Calculate DMG size (add some padding)
print_step "Calculating DMG size..."
SIZE_MB=$(du -sm "$BUILD_DIR" | cut -f1)
SIZE_MB=$((SIZE_MB + 50))  # Add 50MB padding

# Create the DMG
print_step "Creating DMG..."
hdiutil create -size ${SIZE_MB}m -fs HFS+ -volname "$APP_NAME" temp.dmg

# Mount the DMG
print_step "Mounting DMG..."
hdiutil attach temp.dmg -mountpoint /Volumes/"$APP_NAME"

# Copy contents to mounted DMG (excluding the Applications symlink)
print_step "Copying contents to DMG..."
cp -r "$BUILD_DIR"/Dials.app /Volumes/"$APP_NAME"/
cp "$BUILD_DIR"/README.txt /Volumes/"$APP_NAME"/
cp "$BUILD_DIR"/"Install CLI.command" /Volumes/"$APP_NAME"/

# Create the Applications symlink directly in the mounted DMG
ln -s /Applications /Volumes/"$APP_NAME"/Applications

# Set custom icon and background (if available)
if command -v sips &> /dev/null; then
    print_step "Setting up DMG appearance..."
    
    # Create a simple background
    # Note: You can replace this with a custom background image
    mkdir -p /Volumes/"$APP_NAME"/.background
    
    # Set folder view options using AppleScript
    osascript << EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 920, 420}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set position of item "Dials.app" of container window to {130, 120}
        set position of item "Applications" of container window to {390, 120}
        set position of item "README.txt" of container window to {130, 240}
        set position of item "Install CLI.command" of container window to {390, 240}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF
fi

# Unmount the DMG
print_step "Finalizing DMG..."
hdiutil detach /Volumes/"$APP_NAME"

# Convert to compressed, read-only DMG
hdiutil convert temp.dmg -format UDZO -o "${DMG_NAME}.dmg"

# Clean up
rm temp.dmg
rm -rf "$BUILD_DIR"

print_success "DMG created successfully: ${DMG_NAME}.dmg"

# Show file info
if [[ -f "${DMG_NAME}.dmg" ]]; then
    SIZE=$(du -h "${DMG_NAME}.dmg" | cut -f1)
    print_success "DMG size: $SIZE"
    
    echo ""
    echo -e "${BLUE}Distribution ready:${NC}"
    echo "  📦 ${DMG_NAME}.dmg"
    echo ""
    echo -e "${YELLOW}To test:${NC}"
    echo "  1. Double-click the DMG to mount it"
    echo "  2. Drag Dials.app to Applications"
    echo "  3. Optional: Run 'Install CLI.command' for CLI access"
    echo ""
fi