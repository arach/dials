import AppIntents
import Foundation

/// Intent to quickly set balance to full left
struct BalanceLeftIntent: AppIntent {
    static let title: LocalizedStringResource = "Balance Left"
    static let description = IntentDescription("Set audio balance to full left")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetView {
        let result = try Dials.Audio.balanceLeft()
        
        return .result(
            value: result,
            view: BalanceResultView(
                icon: "speaker.wave.2.circle.fill",
                title: "Balance Left",
                message: result
            )
        )
    }
}

/// Intent to quickly set balance to center
struct BalanceCenterIntent: AppIntent {
    static let title: LocalizedStringResource = "Balance Center"
    static let description = IntentDescription("Set audio balance to center")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetView {
        let result = try Dials.Audio.balanceCenter()
        
        return .result(
            value: result,
            view: BalanceResultView(
                icon: "speaker.wave.2.circle.fill",
                title: "Balance Center",
                message: result
            )
        )
    }
}

/// Intent to quickly set balance to full right
struct BalanceRightIntent: AppIntent {
    static let title: LocalizedStringResource = "Balance Right"
    static let description = IntentDescription("Set audio balance to full right")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetView {
        let result = try Dials.Audio.balanceRight()
        
        return .result(
            value: result,
            view: BalanceResultView(
                icon: "speaker.wave.2.circle.fill",
                title: "Balance Right",
                message: result
            )
        )
    }
}

/// Intent to get current balance
struct GetBalanceIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Audio Balance"
    static let description = IntentDescription("Check the current audio balance setting")
    
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ShowsSnippetView {
        // Get current device info which includes balance
        let deviceInfo = try Dials.Audio.outputInfo()
        
        // Extract just the balance line
        let lines = deviceInfo.components(separatedBy: "\n")
        let balanceLine = lines.first { $0.contains("Balance:") } ?? "Balance: Unknown"
        
        return .result(
            value: balanceLine,
            view: BalanceResultView(
                icon: "speaker.wave.2.circle",
                title: "Current Balance",
                message: balanceLine
            )
        )
    }
}