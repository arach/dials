import Foundation
import CoreAudio

/// Shared audio service that provides high-level operations for both CLI and UI
enum AudioService {
    
    // MARK: - Device Information
    
    static func listOutputDevices() throws -> String {
        let devices = try AudioController.allOutputDevices()
        let defaultID = AudioController.defaultOutputDeviceID
        
        var output = "Audio Output Devices:\n\n"
        for device in devices {
            let isDefault = device.id == defaultID
            let prefix = isDefault ? "* " : "  "
            output += "\(prefix)\(device.name) (ID: \(device.id))\n"
        }
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
        return formatBalanceResult(value)
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