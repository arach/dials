// The Swift Programming Language
// https://docs.swift.org/swift-book

import ArgumentParser

struct DialsCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A cockpit-style controller for macOS media I/O.",
        version: "0.2.0",
        subcommands: [
            Balance.self,
            Output.self,
            Display.self,
            CommandCenter.self,
            Build.self,
            Show.self
        ],
        defaultSubcommand: CommandCenter.self
    )
}

DialsCLI.main()
