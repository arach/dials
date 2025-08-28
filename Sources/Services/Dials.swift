import Foundation
import AppKit

/// The main Dials SDK that provides access to all system control functionality
/// This is the central API that both CLI and UI use
public enum Dials {
    
    /// Audio control module
    public enum Audio {
        /// Set the audio balance (0.0 = full left, 0.5 = center, 1.0 = full right)
        public static func setBalance(_ value: Float) throws -> String {
            return try AudioService.setBalance(value)
        }
        
        /// Convenience methods for common balance settings
        public static func balanceLeft() throws -> String {
            return try AudioService.setBalanceLeft()
        }
        
        public static func balanceCenter() throws -> String {
            return try AudioService.setBalanceCenter()
        }
        
        public static func balanceRight() throws -> String {
            return try AudioService.setBalanceRight()
        }
        
        /// Get the current balance position (like reading a dial)
        public static func getCurrentBalance() throws -> String {
            return try AudioService.getCurrentBalance()
        }
        
        /// Get list of all audio output devices
        public static func listOutputs() throws -> String {
            return try AudioService.listOutputDevices()
        }
        
        /// Get detailed info about the default output device
        public static func outputInfo() throws -> String {
            return try AudioService.getDefaultDeviceInfo()
        }
    }
    
    /// Display control module
    public enum Display {
        /// List all connected displays
        public static func list() -> String {
            return DisplayService.listDisplays()
        }
        
        /// Get IOKit level display information
        public static func ioKitInfo() -> String {
            return DisplayService.getIOKitInfo()
        }
        
        /// Turn off a display by ID
        public static func turnOff(id: String, useDDC: Bool = false) -> String {
            if useDDC {
                return DisplayService.turnOffDisplayWithDDC(id: id)
            } else {
                return DisplayService.turnOffDisplay(id: id)
            }
        }
    }
    
    /// System fixes module
    public enum Fixes {
        /// Reset AirPlay mirroring (gentle restart)
        public static func resetAirPlayMirror() async -> String {
            let commands = [
                ("pkill", ["-f", "ControlCenter"], true),
                ("pkill", ["-f", "AirPlay"], true)
            ]
            return await executeSystemCommands(commands, 
                description: "Resetting AirPlay mirroring by restarting audio and AirPlay services...")
        }
        
        /// Force stop all AirPlay processes
        public static func forceStopAirPlay() async -> String {
            let commands = [
                ("pkill", ["-9", "-f", "ControlCenter"], true),
                ("pkill", ["-9", "-f", "AirPlay"], true),
                ("killall", ["-9", "sharingd"], false),
                ("launchctl", ["kickstart", "-k", "system/com.apple.audio.coreaudiod"], false)
            ]
            return await executeSystemCommands(commands,
                description: "Force stopping all AirPlay processes and restarting core audio...")
        }
        
        private static func executeSystemCommands(_ commands: [(String, [String], Bool)], description: String) async -> String {
            var output = description + "\n\n"
            var allSuccessful = true
            
            for (cmd, args, needsSudo) in commands {
                let result = await SystemCommand.execute(command: cmd, arguments: args, requiresSudo: needsSudo)
                output += "[\(result.success ? "✓" : "✗")] \(needsSudo ? "sudo " : "")\(cmd) \(args.joined(separator: " "))\n"
                if !result.output.isEmpty {
                    output += result.output + "\n"
                }
                if !result.success {
                    allSuccessful = false
                }
            }
            
            output += "\nCommand sequence completed."
            
            // Show notification based on the command type (only in GUI mode)
            let success = allSuccessful
            if NSApp != nil && NSApp.activationPolicy() != .prohibited {
                await MainActor.run {
                    if description.contains("AirPlay mirroring") {
                        if success {
                            showNotification(
                                type: .success,
                                title: "AirPlay Reset Complete",
                                message: "AirPlay services have been restarted",
                                secondaryMessage: "Now go to Control Center and stop mirroring manually",
                                autoDismissAfter: 5.0
                            )
                        } else {
                            showNotification(
                                type: .error,
                                title: "AirPlay Reset Failed",
                                message: "Some commands failed to execute",
                                secondaryMessage: "Check the output window for details",
                                autoDismissAfter: 5.0
                            )
                        }
                    } else if description.contains("Force stopping") {
                        if success {
                            showNotification(
                                type: .success,
                                title: "AirPlay Force Stop Complete",
                                message: "All AirPlay processes terminated",
                                secondaryMessage: "You may need to restart mirroring if desired",
                                autoDismissAfter: 5.0
                            )
                        } else {
                            showNotification(
                                type: .error,
                                title: "Force Stop Failed",
                                message: "Some processes could not be terminated",
                                secondaryMessage: "Check the output window for details",
                                autoDismissAfter: 5.0
                            )
                        }
                    }
                }
            }
            
            return output
        }
    }
    
    /// Version and info
    public static let version = "0.2.0"
    public static let description = "A cockpit-style controller for macOS media I/O"
}