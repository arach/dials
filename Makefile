# Dials Makefile - Based on Grab build system patterns
# A comprehensive build system for the Dials CLI and app

# Project Configuration
APP_NAME = Dials
BINARY_NAME = dials
VERSION = 0.2.1
BUNDLE_ID = com.arach.dials

# Build Configuration
SWIFT_BUILD_FLAGS = 
SWIFT_RELEASE_FLAGS = -c release
SWIFT_DEBUG_FLAGS = -c debug

# Paths
BUILD_DIR = .build
DEBUG_DIR = $(BUILD_DIR)/debug
RELEASE_DIR = $(BUILD_DIR)/release
APP_DIR = $(APP_NAME).app
CONTENTS_DIR = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources
INSTALL_PATH = /usr/local/bin
APP_INSTALL_PATH = /Applications

# Binaries
DEBUG_BINARY = $(DEBUG_DIR)/$(BINARY_NAME)
RELEASE_BINARY = $(RELEASE_DIR)/$(BINARY_NAME)
APP_BINARY = $(MACOS_DIR)/$(APP_NAME)

# Colors
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
BLUE = \033[0;34m
NC = \033[0m

# Architecture Detection
ARCH := $(shell uname -m)
ifeq ($(ARCH),arm64)
	ARCH_FLAG = --arch arm64
else
	ARCH_FLAG = --arch x86_64
endif

.PHONY: all build debug release clean install uninstall test help info
.PHONY: app bundle dev watch run-dev run-app dmg dist
.PHONY: command-center balance-left balance-center balance-right
.PHONY: list-outputs list-displays

# Default target
all: build

# === BUILD TARGETS ===

# Quick development build
build: debug
	@echo "$(GREEN)✅ Development build ready$(NC)"
	@echo "Binary: $(DEBUG_BINARY)"

# Debug build
debug:
	@echo "$(BLUE)🔨 Building debug version...$(NC)"
	@swift build $(SWIFT_DEBUG_FLAGS)
	@echo "$(GREEN)✅ Debug build complete$(NC)"

# Release build
release:
	@echo "$(BLUE)🔨 Building release version...$(NC)"
	@swift build $(SWIFT_RELEASE_FLAGS)
	@echo "$(GREEN)✅ Release build complete$(NC)"

# Universal binary build
universal:
	@echo "$(BLUE)🔨 Building universal binary...$(NC)"
	@swift build $(SWIFT_RELEASE_FLAGS) $(ARCH_FLAG)
	@echo "$(GREEN)✅ Universal build complete$(NC)"

# === APP BUNDLE TARGETS ===

# Create app bundle
app: bundle

bundle: release
	@echo "$(BLUE)📦 Creating app bundle...$(NC)"
	@rm -rf $(APP_DIR)
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@cp $(RELEASE_BINARY) $(APP_BINARY)
	@chmod +x $(APP_BINARY)
	@$(MAKE) --no-print-directory create-info-plist
	@echo "$(GREEN)✅ App bundle created: $(APP_DIR)$(NC)"

# Create Info.plist
create-info-plist:
	@echo "$(BLUE)📝 Creating Info.plist...$(NC)"
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(CONTENTS_DIR)/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(CONTENTS_DIR)/Info.plist
	@echo '<plist version="1.0">' >> $(CONTENTS_DIR)/Info.plist
	@echo '<dict>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>CFBundleDisplayName</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>$(APP_NAME)</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>CFBundleExecutable</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>$(APP_NAME)</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>CFBundleIdentifier</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>$(BUNDLE_ID)</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>CFBundleInfoDictionaryVersion</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>6.0</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>CFBundleName</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>$(APP_NAME)</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>CFBundlePackageType</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>APPL</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>CFBundleShortVersionString</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>$(VERSION)</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>CFBundleVersion</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>$(VERSION)</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>LSMinimumSystemVersion</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>13.0</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>LSUIElement</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<true/>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>NSHighResolutionCapable</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<true/>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>NSMicrophoneUsageDescription</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>Dials needs access to audio devices to control balance and output settings.</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>NSSystemAdministrationUsageDescription</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>Dials needs administrator privileges to control system audio settings.</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>NSAppleEventsUsageDescription</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<string>Dials needs accessibility access to register global keyboard shortcuts.</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<key>INIntentsSupported</key>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	<array>' >> $(CONTENTS_DIR)/Info.plist
	@echo '		<string>SetBalanceIntent</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '		<string>BalanceLeftIntent</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '		<string>BalanceCenterIntent</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '		<string>BalanceRightIntent</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '		<string>GetBalanceIntent</string>' >> $(CONTENTS_DIR)/Info.plist
	@echo '	</array>' >> $(CONTENTS_DIR)/Info.plist
	@echo '</dict>' >> $(CONTENTS_DIR)/Info.plist
	@echo '</plist>' >> $(CONTENTS_DIR)/Info.plist

# === DISTRIBUTION TARGETS ===

# Create DMG installer
dmg: app
	@echo "$(BLUE)📦 Creating DMG installer...$(NC)"
	@./scripts/create-dmg.sh
	@echo "$(GREEN)✅ DMG installer created$(NC)"

# Create distribution package (alias for dmg)
dist: dmg

# === DEVELOPMENT TARGETS ===

# Development mode with auto-reload
dev: debug
	@echo "$(BLUE)🛠️  Starting development mode...$(NC)"
	@./dev.sh

# Watch mode for file changes
watch: debug
	@echo "$(BLUE)👀 Starting watch mode...$(NC)"
	@./watch.sh

# Run development binary
run-dev: debug
	@echo "$(BLUE)🚀 Running development binary...$(NC)"
	@$(DEBUG_BINARY) --help

# Run app bundle
run-app: app
	@echo "$(BLUE)🚀 Running app bundle...$(NC)"
	@open $(APP_DIR)

# === INSTALLATION TARGETS ===

# Install CLI to system
install: release
	@echo "$(YELLOW)📦 Installing $(BINARY_NAME) to $(INSTALL_PATH)...$(NC)"
	@if [ -w "$(INSTALL_PATH)" ]; then \
		cp $(RELEASE_BINARY) $(INSTALL_PATH)/$(BINARY_NAME); \
		chmod +x $(INSTALL_PATH)/$(BINARY_NAME); \
	else \
		sudo cp $(RELEASE_BINARY) $(INSTALL_PATH)/$(BINARY_NAME); \
		sudo chmod +x $(INSTALL_PATH)/$(BINARY_NAME); \
	fi
	@echo "$(GREEN)✅ CLI installation complete! Try: $(BINARY_NAME) --help$(NC)"

# Install app to Applications
install-app: app
	@echo "$(YELLOW)📦 Installing $(APP_NAME).app to $(APP_INSTALL_PATH)...$(NC)"
	@if [ -w "$(APP_INSTALL_PATH)" ]; then \
		cp -r $(APP_DIR) $(APP_INSTALL_PATH)/; \
	else \
		sudo cp -r $(APP_DIR) $(APP_INSTALL_PATH)/; \
	fi
	@echo "$(GREEN)✅ App installation complete!$(NC)"

# Install both CLI and app
install-all: install install-app

# Uninstall CLI
uninstall:
	@echo "$(YELLOW)🗑️  Uninstalling $(BINARY_NAME) from $(INSTALL_PATH)...$(NC)"
	@if [ -f "$(INSTALL_PATH)/$(BINARY_NAME)" ]; then \
		if [ -w "$(INSTALL_PATH)/$(BINARY_NAME)" ]; then \
			rm $(INSTALL_PATH)/$(BINARY_NAME); \
		else \
			sudo rm $(INSTALL_PATH)/$(BINARY_NAME); \
		fi; \
		echo "$(GREEN)✅ CLI uninstall complete$(NC)"; \
	else \
		echo "$(RED)❌ $(BINARY_NAME) not found in $(INSTALL_PATH)$(NC)"; \
	fi

# Uninstall app
uninstall-app:
	@echo "$(YELLOW)🗑️  Uninstalling $(APP_NAME).app from $(APP_INSTALL_PATH)...$(NC)"
	@if [ -d "$(APP_INSTALL_PATH)/$(APP_DIR)" ]; then \
		if [ -w "$(APP_INSTALL_PATH)/$(APP_DIR)" ]; then \
			rm -rf $(APP_INSTALL_PATH)/$(APP_DIR); \
		else \
			sudo rm -rf $(APP_INSTALL_PATH)/$(APP_DIR); \
		fi; \
		echo "$(GREEN)✅ App uninstall complete$(NC)"; \
	else \
		echo "$(RED)❌ $(APP_NAME).app not found in $(APP_INSTALL_PATH)$(NC)"; \
	fi

# === UTILITY TARGETS ===

# Clean build artifacts
clean:
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(NC)"
	@swift package clean
	@rm -rf $(APP_DIR)
	@rm -f .pid
	@echo "$(GREEN)✅ Clean complete$(NC)"

# Run tests
test:
	@echo "$(YELLOW)🧪 Running tests...$(NC)"
	@swift test
	@echo "$(GREEN)✅ Tests complete$(NC)"

# Show build info
info:
	@echo "$(GREEN)Dials Build Information$(NC)"
	@echo "======================="
	@echo "Project: $(APP_NAME)"
	@echo "Binary: $(BINARY_NAME)"
	@echo "Version: $(VERSION)"
	@echo "Bundle ID: $(BUNDLE_ID)"
	@echo "Architecture: $(ARCH)"
	@echo "CLI Install path: $(INSTALL_PATH)"
	@echo "App Install path: $(APP_INSTALL_PATH)"
	@echo ""
	@if [ -f "$(DEBUG_BINARY)" ]; then \
		echo "Debug binary: $(DEBUG_BINARY) ($$(du -h $(DEBUG_BINARY) | cut -f1))"; \
	fi
	@if [ -f "$(RELEASE_BINARY)" ]; then \
		echo "Release binary: $(RELEASE_BINARY) ($$(du -h $(RELEASE_BINARY) | cut -f1))"; \
	fi
	@if [ -d "$(APP_DIR)" ]; then \
		echo "App bundle: $(APP_DIR) ($$(du -sh $(APP_DIR) | cut -f1))"; \
	fi
	@echo ""
	@echo "Swift version: $$(swift --version | head -n1)"
	@echo "Platform: $$(uname -m) $$(sw_vers -productName) $$(sw_vers -productVersion)"

# === QUICK COMMAND TARGETS ===

# Launch command center (menu bar app)
command-center: debug
	@echo "$(GREEN)🚀 Launching Dials Menu Bar App...$(NC)"
	@$(DEBUG_BINARY) command-center &

# Launch menu bar app (alias)
menubar: command-center

# Show command center window (for launchers)
show: debug
	@echo "$(GREEN)🚀 Showing Dials Command Center...$(NC)"
	@$(DEBUG_BINARY) show

# Audio balance controls
balance-left: debug
	@$(DEBUG_BINARY) balance --left > /dev/null 2>&1

balance-center: debug
	@$(DEBUG_BINARY) balance --center > /dev/null 2>&1

balance-right: debug
	@$(DEBUG_BINARY) balance --right > /dev/null 2>&1

# Device listings
list-outputs: debug
	@$(DEBUG_BINARY) output list > /dev/null 2>&1

list-displays: debug
	@$(DEBUG_BINARY) display list > /dev/null 2>&1

# === HELP TARGET ===

help:
	@echo "$(GREEN)Dials Build System$(NC)"
	@echo "=================="
	@echo ""
	@echo "$(YELLOW)Build Commands:$(NC)"
	@echo "  make build         - Quick development build (default)"
	@echo "  make debug         - Build debug version"
	@echo "  make release       - Build release version"
	@echo "  make universal     - Build universal binary"
	@echo "  make app           - Create app bundle"
	@echo "  make dmg           - Create DMG installer"
	@echo "  make dist          - Create distribution package (alias for dmg)"
	@echo "  make clean         - Clean build artifacts"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  make dev           - Development mode with auto-reload"
	@echo "  make watch         - Watch files for changes"
	@echo "  make run-dev       - Run development binary"
	@echo "  make run-app       - Run app bundle"
	@echo ""
	@echo "$(YELLOW)Installation:$(NC)"
	@echo "  make install       - Install CLI to $(INSTALL_PATH)"
	@echo "  make install-app   - Install app to $(APP_INSTALL_PATH)"
	@echo "  make install-all   - Install both CLI and app"
	@echo "  make uninstall     - Remove CLI from system"
	@echo "  make uninstall-app - Remove app from system"
	@echo ""
	@echo "$(YELLOW)Quick Commands:$(NC)"
	@echo "  make command-center   - Launch Dials as menu bar app"
	@echo "  make menubar          - Launch menu bar app (alias)"
	@echo "  make balance-left     - Set audio balance to left"
	@echo "  make balance-center   - Set audio balance to center"
	@echo "  make balance-right    - Set audio balance to right"
	@echo "  make list-outputs     - List audio output devices"
	@echo "  make list-displays    - List display devices"
	@echo ""
	@echo "$(YELLOW)Other:$(NC)"
	@echo "  make test          - Run tests"
	@echo "  make info          - Show build information"
	@echo "  make help          - Show this help message"