import ArgumentParser
import AppKit

/// Command to show the Command Center window (for launcher integration)
struct Show: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show the Dials Command Center window"
    )
    
    func run() throws {
        // Check if Dials is already running
        let runningApps = NSWorkspace.shared.runningApplications
        let dialsApp = runningApps.first { app in
            app.bundleIdentifier == "com.arach.dials" ||
            (app.executableURL?.lastPathComponent == "dials" && app.activationPolicy == .accessory)
        }
        
        if let app = dialsApp {
            // Dials is running - send it a notification to show the window
            print("Dials is already running, showing Command Center...")
            print("[DEBUG] Found app: \(app.bundleIdentifier ?? "unknown"), executable: \(app.executableURL?.path ?? "unknown")")
            
            // Post a distributed notification that the running app can listen for
            print("[DEBUG] Posting notification: com.arach.dials.showCommandCenter")
            DistributedNotificationCenter.default().postNotificationName(
                Notification.Name("com.arach.dials.showCommandCenter"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            print("[DEBUG] Notification posted")
            
            // Also try to activate the app
            print("[DEBUG] Attempting to activate app")
            app.activate(options: [.activateIgnoringOtherApps])
        } else {
            // Dials is not running - start it and show the window
            print("Starting Dials and showing Command Center...")
            
            // Launch the app
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.arach.dials") {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                config.arguments = ["--show-command-center"]
                
                NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
                    if let error = error {
                        print("Error launching Dials: \(error)")
                    }
                }
            } else {
                // Fallback: try to find and launch the app
                let appPath = "/Applications/Dials.app"
                if FileManager.default.fileExists(atPath: appPath) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: appPath))
                    
                    // Wait a moment then send the notification
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        DistributedNotificationCenter.default().postNotificationName(
                            Notification.Name("com.arach.dials.showCommandCenter"),
                            object: nil,
                            userInfo: nil,
                            deliverImmediately: true
                        )
                    }
                } else {
                    throw ValidationError("Dials.app not found. Please run 'make install-app' first.")
                }
            }
        }
        
        // Keep the process alive longer to ensure the window stays open
        // This gives time for the app to receive and process the notification
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
    }
}