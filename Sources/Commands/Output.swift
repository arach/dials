import ArgumentParser

struct Output: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Inspect or change audio output devices.",
        subcommands: [List.self, Info.self]
    )

    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Print all output-capable audio devices."
        )

        func run() throws {
            for dev in try AudioController.allOutputDevices() {
                let star = dev.id == AudioController.defaultOutputDeviceID ? "*" : " "
                print("\(star) \(dev.name) [id \(dev.id)]")
            }
        }
    }

    struct Info: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Show detailed info for the default output device."
        )

        func run() throws {
            let devID = AudioController.defaultOutputDeviceID
            let info = try AudioController.deviceInfo(id: devID)
            print("Device: \(info.name)")
            print("ID: \(info.id)")
            print("Manufacturer: \(info.manufacturer)")
            print("Channels: \(info.channels)")
            print("Sample Rates: \(info.sampleRates.map { String($0) }.joined(separator: ", "))")
            print("Current Volume (L/R): \(info.leftVolume) / \(info.rightVolume)")
            print("Current Balance: \(info.balance)")
            print("Muted: \(info.muted)")
            print("Transport: \(info.transportType)")
        }
    }
} 