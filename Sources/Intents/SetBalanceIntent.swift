import AppIntents
import Foundation

/// Main intent for setting audio balance to a specific value
struct SetBalanceIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Audio Balance"
    static let description = IntentDescription("Adjust the left/right audio balance")
    
    @Parameter(title: "Balance", description: "Balance value (0-100, where 0 is full left, 50 is center, 100 is full right)")
    var balance: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set audio balance to \(\.$balance)%")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Validate input
        guard balance >= 0 && balance <= 100 else {
            throw IntentError.invalidInput("Balance must be between 0 and 100")
        }
        
        // Convert percentage to 0.0-1.0 range
        let balanceValue = Float(balance / 100.0)
        
        // Use the Dials SDK
        let result = try Dials.Audio.setBalance(balanceValue)
        
        // Return the result for Shortcuts/Siri
        return .result(value: result)
    }
}

/// Custom error types for intents
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidInput(String)
    case deviceError(String)
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidInput(let message):
            return LocalizedStringResource(stringLiteral: message)
        case .deviceError(let message):
            return LocalizedStringResource(stringLiteral: "Audio device error: \(message)")
        }
    }
}