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
        // Use the Dials SDK to handle the balance operation
        let result: String
        
        if let v = value {
            let clampedValue = min(max(v, 0.0), 1.0)
            result = try Dials.Audio.setBalance(clampedValue)
        } else if left {
            result = try Dials.Audio.balanceLeft()
        } else if right {
            result = try Dials.Audio.balanceRight()
        } else if center {
            result = try Dials.Audio.balanceCenter()
        } else {
            // No arguments - show current balance like a dial
            result = try Dials.Audio.getCurrentBalance()
        }
        
        print(result)
    }
} 