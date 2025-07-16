import Foundation
import CoreGraphics

/// Shared display service that provides high-level operations for both CLI and UI
enum DisplayService {
    
    // MARK: - Display Information
    
    static func listDisplays() -> String {
        let screens = DisplayManager.all()
        let displayList = CGGetOnlineDisplayList(10, nil, nil)
        
        var output = "Connected Displays:\n\n"
        
        for screen in screens {
            output += "Display ID: \(String(format: "0x%X", screen.id))\n"
            output += "  Name: \(screen.name)\n"
            
            // Get display bounds
            let bounds = CGDisplayBounds(screen.id)
            output += "  Resolution: \(Int(bounds.width)) x \(Int(bounds.height))\n"
            
            // Check if main display
            let isMain = CGDisplayIsMain(screen.id) != 0
            output += "  Main: \(isMain ? "Yes" : "No")\n"
            
            // Check if active
            let isActive = CGDisplayIsActive(screen.id) != 0
            output += "  Active: \(isActive ? "Yes" : "No")\n"
            
            // Built-in status
            output += "  Builtin: \(screen.isBuiltin ? "Yes" : "No")\n\n"
        }
        
        return output
    }
    
    static func getIOKitInfo() -> String {
        // For now, return basic display info since IOKit details aren't implemented
        return "IOKit display information not yet implemented.\n\n" + listDisplays()
    }
    
    // MARK: - Display Operations
    
    static func turnOffDisplay(id: String) -> String {
        guard let displayID = parseDisplayID(id) else {
            return "Error: Invalid display ID format. Use hex format like 0x1 or decimal."
        }
        
        do {
            try DisplayManager.deactivate(displayID)
            return "Display \(id) has been turned off"
        } catch {
            return "Error: Failed to turn off display - \(error.localizedDescription)"
        }
    }
    
    static func turnOffDisplayWithDDC(id: String) -> String {
        guard let displayID = parseDisplayID(id) else {
            return "Error: Invalid display ID format. Use hex format like 0x1 or decimal."
        }
        
        // DDC control not yet implemented
        return "DDC control not yet implemented. Using system deactivation instead.\n" + turnOffDisplay(id: id)
    }
    
    // MARK: - Private Helpers
    
    private static func parseDisplayID(_ idString: String) -> CGDirectDisplayID? {
        let cleanedString = idString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try hex format (0x...)
        if cleanedString.hasPrefix("0x") || cleanedString.hasPrefix("0X") {
            let hexString = String(cleanedString.dropFirst(2))
            if let id = UInt32(hexString, radix: 16) {
                return CGDirectDisplayID(id)
            }
        }
        
        // Try decimal format
        if let id = UInt32(cleanedString) {
            return CGDirectDisplayID(id)
        }
        
        return nil
    }
}