import Foundation
import CoreGraphics                  // Quartz Display Services

enum DisplayManager {

    // MARK: – Listing --------------------------------------------------------
    struct Screen {
        let id: CGDirectDisplayID
        let isBuiltin: Bool
        let name: String
    }

    static func all() -> [Screen] {
        var max: UInt32 = 16
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(max))
        CGGetOnlineDisplayList(max, &ids, &max)

        return ids.prefix(Int(max)).compactMap { id in
            guard id != 0 else { return nil }
            let isBuiltin = CGDisplayIsBuiltin(id) != 0
            let name = "Display \(id)"
            return Screen(id: id, isBuiltin: isBuiltin, name: name)
        }
    }

    // MARK: – Public-API "disconnect" ----------------------------------------
    /// Removes `id` from the desktop for this login session.
    static func deactivate(_ id: CGDirectDisplayID) throws {
        var config: CGDisplayConfigRef?
        try check(CGBeginDisplayConfiguration(&config))
        // kCGNullDirectDisplay = "no mirror target" → effectively offline
        try check(CGConfigureDisplayMirrorOfDisplay(config, id,
                                                    kCGNullDirectDisplay))
        try check(CGCompleteDisplayConfiguration(config, .forSession))
    }

    // MARK: – DDC "hard power-off" -------------------------------------------
    // Attempts to send VCP 0xD6 (DPMS power mode 5 = off).
    // Returns false if the monitor isn't DDC-controllable.
    @discardableResult
    static func ddcPowerOff(_ id: CGDirectDisplayID) -> Bool {
        // DDC/CI not implemented yet
        return false
    }

    // MARK: – Glue -----------------------------------------------------------
    private static func check(_ err: CGError) throws {
        guard err == .success else {
            throw NSError(domain: "DisplayManager", code: Int(err.rawValue),
                          userInfo: [NSLocalizedDescriptionKey:
                                     "CGError \(err.rawValue)"])
        }
    }
}

func displayName(for id: CGDirectDisplayID) -> String {
    return "Display \(id)"
}