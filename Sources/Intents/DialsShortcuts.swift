import AppIntents

/// Provides app shortcuts that appear in the Shortcuts app and Spotlight
struct DialsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Balance Center - Most common action
        AppShortcut(
            intent: BalanceCenterIntent(),
            phrases: [
                "Balance audio with \(.applicationName)",
                "Center audio with \(.applicationName)",
                "Reset balance with \(.applicationName)"
            ],
            shortTitle: "Balance Center",
            systemImageName: "speaker.wave.2.circle.fill"
        )
        
        // Balance Left
        AppShortcut(
            intent: BalanceLeftIntent(),
            phrases: [
                "Balance left with \(.applicationName)",
                "Audio left with \(.applicationName)",
                "Set balance left with \(.applicationName)"
            ],
            shortTitle: "Balance Left",
            systemImageName: "speaker.wave.2.circle.fill"
        )
        
        // Balance Right
        AppShortcut(
            intent: BalanceRightIntent(),
            phrases: [
                "Balance right with \(.applicationName)",
                "Audio right with \(.applicationName)",
                "Set balance right with \(.applicationName)"
            ],
            shortTitle: "Balance Right",
            systemImageName: "speaker.wave.2.circle.fill"
        )
        
        // Get Current Balance
        AppShortcut(
            intent: GetBalanceIntent(),
            phrases: [
                "What's my audio balance with \(.applicationName)",
                "Check balance with \(.applicationName)",
                "Get audio balance with \(.applicationName)"
            ],
            shortTitle: "Get Balance",
            systemImageName: "speaker.wave.2.circle"
        )
        
        // Set specific balance
        AppShortcut(
            intent: SetBalanceIntent(),
            phrases: [
                "Set audio balance to \(\.$balance) percent with \(.applicationName)",
                "Balance \(\.$balance) with \(.applicationName)",
                "Audio balance \(\.$balance) percent with \(.applicationName)"
            ],
            shortTitle: "Set Balance",
            systemImageName: "slider.horizontal.3"
        )
    }
    
    static var shortcutTileColor: ShortcutTileColor = .blue
}