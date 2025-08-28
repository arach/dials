import Foundation
import ArgumentParser
import CoreGraphics
import IOKit
import IOKit.i2c
import IOKit.graphics

struct Display: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Manage displays",
        subcommands: [List.self, Off.self, Iokit.self])

    // dials display list
    struct List: ParsableCommand {
        func run() {
            // Use the Dials SDK for consistent output
            let output = Dials.Display.list()
            print(output)
        }
    }

    // dials display off --id 0x1A2B3C4D [--ddc]
    struct Off: ParsableCommand {
        @Option(help: "CGDirectDisplayID in hex, as shown in `list`.") var id: String
        @Flag(name: .customLong("ddc"), help: "Also send DDC power-off") var useDDC = false

        func run() throws {
            // Use the Dials SDK
            let result = Dials.Display.turnOff(id: id, useDDC: useDDC)
            print(result)
        }
    }

    // dials display iokit
    struct Iokit: ParsableCommand {
        func run() {
            // Use the Dials SDK
            let output = Dials.Display.ioKitInfo()
            print(output)
        }
    }
}

func printDisplayInfo(_ id: CGDirectDisplayID) {
    print("Display ID: \(String(format: "0x%08X", id))")
    print("  Is Built-in: \(CGDisplayIsBuiltin(id) != 0)")
    print("  Is Main: \(CGDisplayIsMain(id) != 0)")
    print("  Is Active: \(CGDisplayIsActive(id) != 0)")
    print("  Is Asleep: \(CGDisplayIsAsleep(id) != 0)")
    print("  Is Online: \(CGDisplayIsOnline(id) != 0)")
    print("  Is Mirrored: \(CGDisplayIsInMirrorSet(id) != 0)")
    print("  Mirroring: \(CGDisplayIsAlwaysInMirrorSet(id) != 0)")
    print("  Rotation: \(CGDisplayRotation(id))°")
    let width = CGDisplayPixelsWide(id)
    let height = CGDisplayPixelsHigh(id)
    print("  Resolution: \(width) x \(height)")
    if let mode = CGDisplayCopyDisplayMode(id) {
        print("  Refresh Rate: \(mode.refreshRate) Hz")
        print("  I/O Flags: \(mode.ioDisplayModeID)")
    }
    print("  Vendor ID: \(CGDisplayVendorNumber(id))")
    print("  Model ID: \(CGDisplayModelNumber(id))")
    print("  Serial Number: \(CGDisplaySerialNumber(id))")
    print("")
}

func printAllIOKitDisplays() {
    print("Enumerating IOKit displays…")
    let matching = IOServiceMatching("IODisplayConnect")
    var iterator: io_iterator_t = 0

    let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
    if result != KERN_SUCCESS {
        print("Failed to get IOKit display services")
        return
    }

    var service = IOIteratorNext(iterator)
    while service != 0 {
        if let info = IODisplayCreateInfoDictionary(service, 0).takeRetainedValue() as? [String: Any] {
            print("---- IOKit Display ----")
            for (key, value) in info {
                print("\(key): \(value)")
            }
            print("----------------------\n")
        }
        IOObjectRelease(service)
        service = IOIteratorNext(iterator)
    }
    IOObjectRelease(iterator)
    print("Done")
}