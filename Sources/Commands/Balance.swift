import ArgumentParser

struct Balance: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Set the left/right balance of the default output device."
    )

    @Option(name: .shortAndLong, help: "Balance value -1 (full L) … 1 (full R).")
    var value: Float?

    @Flag(help: "Full left")
    var left: Bool = false
    @Flag(help: "Centre")
    var center: Bool = false
    @Flag(help: "Full right")
    var right: Bool = false

    func run() throws {
        let val: Float = {
            if left   { return 0.0 }
            if center { return 0.5 }
            if right  { return 1.0 }
            if let v = value { return min(max(v, 0.0), 1.0) }
            return 0
        }()

        try AudioController.setBalance(val)
    }
} 