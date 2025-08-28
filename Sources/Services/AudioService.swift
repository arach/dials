import Foundation
import CoreAudio
import AppKit

/// Shared audio service that provides high-level operations for both CLI and UI
enum AudioService {
    
    // MARK: - Device Information
    
    static func listOutputDevices() throws -> String {
        print("[AudioService] Listing output devices...")
        let devices = try AudioController.allOutputDevices()
        let defaultID = AudioController.defaultOutputDeviceID
        
        print("[AudioService] Found \(devices.count) devices, default ID: \(defaultID)")
        
        var output = "Audio Output Devices:\n\n"
        for device in devices {
            let isDefault = device.id == defaultID
            let prefix = isDefault ? "* " : "  "
            output += "\(prefix)\(device.name) (ID: \(device.id))\n"
        }
        
        print("[AudioService] Output: \(output)")
        return output
    }
    
    static func getDefaultDeviceInfo() throws -> String {
        let deviceID = AudioController.defaultOutputDeviceID
        let deviceInfo = try AudioController.deviceInfo(id: deviceID)
        
        var info = "Default Output Device:\n\n"
        info += "Name: \(deviceInfo.name)\n"
        info += "ID: \(deviceInfo.id)\n"
        info += "Manufacturer: \(deviceInfo.manufacturer)\n"
        info += "Channels: \(deviceInfo.channels)\n"
        
        // Volume info
        info += "\nVolume:\n"
        info += "  Left: \(String(format: "%.0f%%", deviceInfo.leftVolume * 100))\n"
        info += "  Right: \(String(format: "%.0f%%", deviceInfo.rightVolume * 100))\n"
        info += "  Muted: \(deviceInfo.muted ? "Yes" : "No")\n"
        
        // Balance info
        info += "\n" + formatBalance(deviceInfo.balance)
        
        // Sample rates
        if !deviceInfo.sampleRates.isEmpty {
            info += "\nSample Rates: \(deviceInfo.sampleRates.map { "\(Int($0))Hz" }.joined(separator: ", "))\n"
        }
        
        // Transport type
        info += "Transport: \(deviceInfo.transportType)"
        
        return info
    }
    
    // MARK: - Balance Operations
    
    static func setBalance(_ value: Float) throws -> String {
        try AudioController.setBalance(value)
        let result = formatBalanceResult(value)
        
        // Only show notification if we're running as a GUI app (not CLI)
        if NSApp != nil && NSApp.activationPolicy() != .prohibited {
            DispatchQueue.main.async {
                showNotification(
                    type: .success,
                    title: "Balance Updated",
                    message: result,
                    autoDismissAfter: 2.0
                )
            }
        }
        
        return result
    }
    
    static func setBalanceLeft() throws -> String {
        return try setBalance(0.0)
    }
    
    static func setBalanceCenter() throws -> String {
        return try setBalance(0.5)
    }
    
    static func setBalanceRight() throws -> String {
        return try setBalance(1.0)
    }
    
    static func getCurrentBalance() throws -> String {
        let balance = try AudioController.getBalance()
        
        // Create a visual dial representation
        let dialPositions = ["⬤○○", "○⬤○", "○○⬤"] // Left, Center, Right
        let labelPositions = ["LEFT", "CENTER", "RIGHT"]
        
        var output = "\n"
        
        // Determine position
        let position: Int
        let label: String
        
        if balance < 0.25 {
            position = 0
            label = labelPositions[0]
        } else if balance > 0.75 {
            position = 2
            label = labelPositions[2]
        } else {
            position = 1
            label = labelPositions[1]
        }
        
        // Create visual dial
        output += "  Audio Balance Dial\n"
        output += "  ╭─────────────╮\n"
        output += "  │  " + dialPositions[position] + "  │\n"
        output += "  │   " + label + "   │\n"
        output += "  ╰─────────────╯\n"
        output += "\n"
        
        // Add detailed info
        output += formatBalance(balance) + "\n"
        
        if balance != 0.0 && balance != 0.5 && balance != 1.0 {
            // Show exact value if not at a preset position
            output += "Exact value: \(String(format: "%.0f%%", balance * 100))\n"
        }
        
        return output
    }
    
    // MARK: - Private Helpers
    
    private static func formatBalance(_ balance: Float) -> String {
        let balancePercent = Int((balance - 0.5) * 200)
        if balancePercent == 0 {
            return "Balance: Center"
        } else if balancePercent < 0 {
            return "Balance: \(abs(balancePercent))% Left"
        } else {
            return "Balance: \(balancePercent)% Right"
        }
    }
    
    private static func formatBalanceResult(_ value: Float) -> String {
        if value == 0.0 {
            return "Audio balance set to left"
        } else if value == 0.5 {
            return "Audio balance set to center"
        } else if value == 1.0 {
            return "Audio balance set to right"
        } else {
            return "Audio balance set to \(Int(value * 100))%"
        }
    }
}