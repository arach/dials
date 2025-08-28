import ArgumentParser
import SwiftUI
import AppKit
import AppIntents

struct CommandCenter: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Start Dials as a background menu bar app"
    )
    
    // Store delegate as a static property to prevent deallocation
    private static var appDelegate: MenuBarAppDelegate?
    
    func run() throws {
        // Create the application
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory) // No dock icon
        
        // Create and store delegate with strong reference
        let delegate = MenuBarAppDelegate()
        CommandCenter.appDelegate = delegate
        app.delegate = delegate
        
        // Run the application
        app.run()
    }
}

class MenuBarAppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var commandCenterWindow: NSWindow?
    var globalEventMonitor: Any?
    var localEventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register App Shortcuts
        DialsShortcuts.updateAppShortcutParameters()
        
        setupMenuBar()
        setupGlobalHotkey()
        
        // Listen for show command center notifications
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(showCommandCenterFromNotification),
            name: Notification.Name("com.arach.dials.showCommandCenter"),
            object: nil
        )
        
        // Check if we should show command center on launch
        if ProcessInfo.processInfo.arguments.contains("--show-command-center") {
            showCommandCenter()
        }
    }
    
    @objc func showCommandCenterFromNotification(_ notification: Notification) {
        print("[DEBUG] Received show command center notification")
        DispatchQueue.main.async { [weak self] in
            print("[DEBUG] Calling showCommandCenter from notification")
            self?.showCommandCenter()
        }
    }
    
    func setupGlobalHotkey() {
        // Register global hotkey (Hyper+D)
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let hyperModifiers: NSEvent.ModifierFlags = [.shift, .option, .control, .command]
            if event.modifierFlags.contains(hyperModifiers) && event.charactersIgnoringModifiers?.lowercased() == "d" {
                DispatchQueue.main.async {
                    if self?.commandCenterWindow?.isVisible == true {
                        self?.commandCenterWindow?.close()
                    } else {
                        self?.showCommandCenter()
                    }
                }
            }
        }
        
        // Also add local monitor for when app is focused
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let hyperModifiers: NSEvent.ModifierFlags = [.shift, .option, .control, .command]
            if event.modifierFlags.contains(hyperModifiers) && event.charactersIgnoringModifiers?.lowercased() == "d" {
                if self?.commandCenterWindow?.isVisible == true {
                    self?.commandCenterWindow?.close()
                } else {
                    self?.showCommandCenter()
                }
                return nil
            }
            return event
        }
        
        print("[DEBUG] Global hotkey registered: Hyper+D (Shift+Option+Control+Command+D)")
    }
    
    func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use a simple text-based icon for now - we can make this more sophisticated later
            button.title = "◉"
            button.font = NSFont.systemFont(ofSize: 14)
            button.toolTip = "Dials - Audio & Display Control"
        }
        
        // Create menu
        let menu = NSMenu()
        
        // Command Center
        let commandCenterItem = NSMenuItem(title: "Command Center", action: #selector(showCommandCenter), keyEquivalent: "")
        commandCenterItem.target = self
        menu.addItem(commandCenterItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick Audio Balance Controls
        let balanceMenu = NSMenuItem(title: "Audio Balance", action: nil, keyEquivalent: "")
        let balanceSubMenu = NSMenu()
        
        let balanceLeftItem = NSMenuItem(title: "Balance Left", action: #selector(balanceLeft), keyEquivalent: "")
        balanceLeftItem.target = self
        balanceSubMenu.addItem(balanceLeftItem)
        
        let balanceCenterItem = NSMenuItem(title: "Balance Center", action: #selector(balanceCenter), keyEquivalent: "")
        balanceCenterItem.target = self
        balanceSubMenu.addItem(balanceCenterItem)
        
        let balanceRightItem = NSMenuItem(title: "Balance Right", action: #selector(balanceRight), keyEquivalent: "")
        balanceRightItem.target = self
        balanceSubMenu.addItem(balanceRightItem)
        
        balanceMenu.submenu = balanceSubMenu
        menu.addItem(balanceMenu)
        
        // Quick Fixes
        let quickFixesMenu = NSMenuItem(title: "Quick Fixes", action: nil, keyEquivalent: "")
        let quickFixesSubMenu = NSMenu()
        
        let resetAirPlayItem = NSMenuItem(title: "Reset AirPlay Mirror", action: #selector(resetAirPlayMirror), keyEquivalent: "")
        resetAirPlayItem.target = self
        quickFixesSubMenu.addItem(resetAirPlayItem)
        
        let forceStopAirPlayItem = NSMenuItem(title: "Force Stop AirPlay", action: #selector(forceStopAirPlay), keyEquivalent: "")
        forceStopAirPlayItem.target = self
        quickFixesSubMenu.addItem(forceStopAirPlayItem)
        
        quickFixesMenu.submenu = quickFixesSubMenu
        menu.addItem(quickFixesMenu)
        
        // Device Lists
        let devicesMenu = NSMenuItem(title: "Devices", action: nil, keyEquivalent: "")
        let devicesSubMenu = NSMenu()
        
        let listOutputsItem = NSMenuItem(title: "List Audio Outputs", action: #selector(listOutputs), keyEquivalent: "")
        listOutputsItem.target = self
        devicesSubMenu.addItem(listOutputsItem)
        
        let listDisplaysItem = NSMenuItem(title: "List Displays", action: #selector(listDisplays), keyEquivalent: "")
        listDisplaysItem.target = self
        devicesSubMenu.addItem(listDisplaysItem)
        
        devicesMenu.submenu = devicesSubMenu
        menu.addItem(devicesMenu)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Dials", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func showCommandCenter() {
        print("[DEBUG] showCommandCenter called")
        
        // Temporarily change activation policy to show window
        let currentPolicy = NSApp.activationPolicy()
        if currentPolicy == .accessory {
            NSApp.setActivationPolicy(.regular)
        }
        
        if commandCenterWindow == nil {
            print("[DEBUG] Creating new command center window")
            createCommandCenterWindow()
        } else {
            print("[DEBUG] Using existing command center window")
        }
        
        commandCenterWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Don't restore activation policy immediately - let the window stay visible
        // The policy will be restored when the window is closed
        
        print("[DEBUG] Window ordered front, app activated")
    }
    
    func createCommandCenterWindow() {
        print("[DEBUG] createCommandCenterWindow called")
        let contentView = CommandCenterView { [weak self] in
            self?.commandCenterWindow?.close()
        }
        
        commandCenterWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        commandCenterWindow?.center()
        commandCenterWindow?.titlebarAppearsTransparent = true
        commandCenterWindow?.titleVisibility = .hidden
        commandCenterWindow?.backgroundColor = NSColor.black.withAlphaComponent(0.9)
        commandCenterWindow?.isOpaque = false
        commandCenterWindow?.hasShadow = true
        commandCenterWindow?.contentView = NSHostingView(rootView: contentView)
        
        // Set up window delegate to handle closing
        commandCenterWindow?.delegate = self
    }
    
    // MARK: - Menu Actions
    
    @objc func balanceLeft() {
        executeDirectCommand {
            return try Dials.Audio.balanceLeft()
        }
    }
    
    @objc func balanceCenter() {
        executeDirectCommand {
            return try Dials.Audio.balanceCenter()
        }
    }
    
    @objc func balanceRight() {
        executeDirectCommand {
            return try Dials.Audio.balanceRight()
        }
    }
    
    @objc func resetAirPlayMirror() {
        Task {
            let result = await Dials.Fixes.resetAirPlayMirror()
            // Only show result window if there's an error (notification handles success)
            if result.contains("[✗]") {
                await MainActor.run {
                    showResultWindow(result)
                }
            }
        }
    }
    
    @objc func forceStopAirPlay() {
        Task {
            let result = await Dials.Fixes.forceStopAirPlay()
            // Only show result window if there's an error (notification handles success)
            if result.contains("[✗]") {
                await MainActor.run {
                    showResultWindow(result)
                }
            }
        }
    }
    
    @objc func listOutputs() {
        Task {
            do {
                let output = try Dials.Audio.listOutputs()
                await MainActor.run {
                    showDeviceListWindow(title: "Audio Output Devices", output: output, type: .audio)
                }
            } catch {
                await MainActor.run {
                    showErrorAlert("Failed to list audio outputs: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc func listDisplays() {
        Task {
            let output = Dials.Display.list()
            await MainActor.run {
                showDeviceListWindow(title: "Connected Displays", output: output, type: .display)
            }
        }
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up event monitors
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        // Clean up status item
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
        // Clean up command center window
        commandCenterWindow?.close()
        commandCenterWindow = nil
    }
}

// MARK: - Window Delegate
extension MenuBarAppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        commandCenterWindow = nil
        // Restore accessory activation policy when window closes
        NSApp.setActivationPolicy(.accessory)
    }
    
    // Helper function to execute commands directly
    func executeDirectCommand(_ action: @escaping () throws -> String) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let result = try action()
                DispatchQueue.main.async {
                    guard self != nil else { return }
                    showResultWindow(result)
                }
            } catch {
                DispatchQueue.main.async {
                    guard self != nil else { return }
                    showErrorAlert("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct CommandCenterView: View {
    let onClose: () -> Void
    
    let commands = [
        Command(
            icon: "speaker.wave.2.fill",
            title: "Balance",
            description: "Control audio balance",
            action: { 
                executeDirectAction {
                    return try Dials.Audio.balanceCenter()
                }
            }
        ),
        Command(
            icon: "speaker.wave.3.fill",
            title: "Output List",
            description: "List audio devices",
            action: { 
                Task {
                    do {
                        let output = try Dials.Audio.listOutputs()
                        await MainActor.run {
                            showDeviceListWindow(title: "Audio Output Devices", output: output, type: .audio)
                        }
                    } catch {
                        await MainActor.run {
                            showErrorAlert("Failed to list audio outputs: \(error.localizedDescription)")
                        }
                    }
                }
            }
        ),
        Command(
            icon: "info.circle.fill",
            title: "Output Info",
            description: "Device details",
            action: {
                executeDirectAction {
                    return try Dials.Audio.outputInfo()
                }
            }
        ),
        Command(
            icon: "display",
            title: "Display List",
            description: "List all displays",
            action: { 
                Task {
                    let output = Dials.Display.list()
                    await MainActor.run {
                        showDeviceListWindow(title: "Connected Displays", output: output, type: .display)
                    }
                }
            }
        ),
        Command(
            icon: "display.trianglebadge.exclamationmark",
            title: "Display Off",
            description: "Turn off display",
            action: { showDisplayOffAlert() }
        ),
        Command(
            icon: "cpu",
            title: "IOKit Info",
            description: "Raw display info",
            action: { 
                executeDirectAction {
                    return Dials.Display.ioKitInfo()
                }
            }
        )
    ]
    
    let pseudoCommands = [
        Command(
            icon: "airplayvideo.circle.fill",
            title: "Reset AirPlay Mirror",
            description: "Clear stuck mirroring",
            action: { 
                Task {
                    let result = await Dials.Fixes.resetAirPlayMirror()
                    // Only show result window if there's an error (notification handles success)
                    if result.contains("[✗]") {
                        await MainActor.run {
                            showResultWindow(result)
                        }
                    }
                }
            }
        ),
        Command(
            icon: "tv.and.mediabox",
            title: "Force Stop AirPlay",
            description: "Kill AirPlay processes",
            action: { 
                Task {
                    let result = await Dials.Fixes.forceStopAirPlay()
                    // Only show result window if there's an error (notification handles success)
                    if result.contains("[✗]") {
                        await MainActor.run {
                            showResultWindow(result)
                        }
                    }
                }
            }
        )
    ]
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("Dials Command Center")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onHover { hovering in
                        // Add hover effect if needed
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
                
                VStack(alignment: .leading, spacing: 30) {
                    // Regular Commands Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("System Commands")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 40)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(commands) { command in
                                CommandButton(command: command)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // Pseudo Commands Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Quick Fixes")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 40)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(pseudoCommands) { command in
                                CommandButton(command: command)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 20)
                
                // Footer
                HStack {
                    Spacer()
                    Text("Menu bar app • Always running")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.01))
    }
}

struct Command: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
}

struct CommandButton: View {
    let command: Command
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: command.action) {
            VStack(spacing: 12) {
                Image(systemName: command.icon)
                    .font(.system(size: 36))
                    .foregroundColor(isHovered ? .blue : .white)
                
                Text(command.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(command.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isHovered ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            if pressing {
                onPress()
            } else {
                onRelease()
            }
        }, perform: {})
    }
}

func executeDirectAction(_ action: @escaping () throws -> String) {
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let result = try action()
            DispatchQueue.main.async {
                showResultWindow(result)
            }
        } catch {
            DispatchQueue.main.async {
                showErrorAlert("Error: \(error.localizedDescription)")
            }
        }
    }
}

// Removed - now using Dials SDK directly

func showDisplayOffAlert() {
    let alert = NSAlert()
    alert.messageText = "Turn Off Display"
    alert.informativeText = "Enter the display ID (hex) to turn off:"
    alert.alertStyle = .warning
    
    let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    input.placeholderString = "e.g., 0x1"
    alert.accessoryView = input
    
    alert.addButton(withTitle: "Turn Off")
    alert.addButton(withTitle: "Cancel")
    
    if alert.runModal() == .alertFirstButtonReturn {
        let displayId = input.stringValue
        if !displayId.isEmpty {
            let result = Dials.Display.turnOff(id: displayId)
            showResultWindow(result)
        }
    }
}

func showResultWindow(_ output: String) {
    guard Thread.isMainThread else {
        DispatchQueue.main.async {
            showResultWindow(output)
        }
        return
    }
    
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
        styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered,
        defer: false
    )
    
    window.title = "Command Output"
    window.center()
    
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = false
    scrollView.borderType = .noBorder
    
    let textView = NSTextView()
    textView.isEditable = false
    textView.isSelectable = true
    textView.isRichText = false
    textView.importsGraphics = false
    textView.string = output
    textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    textView.textColor = .labelColor
    textView.backgroundColor = .textBackgroundColor
    textView.textContainerInset = NSSize(width: 10, height: 10)
    
    scrollView.documentView = textView
    window.contentView = scrollView
    
    // Keep a strong reference to prevent premature deallocation
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    
    // Ensure the window stays alive
    NSApp.activate(ignoringOtherApps: true)
}

func showErrorAlert(_ message: String) {
    let alert = NSAlert()
    alert.messageText = "Error"
    alert.informativeText = message
    alert.alertStyle = .critical
    alert.runModal()
}

// Removed - now using Dials SDK directly for pseudo commands