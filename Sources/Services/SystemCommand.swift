import Foundation
import AppKit

/// Helper for executing system commands with proper error handling
enum SystemCommand {
    
    struct Result {
        let success: Bool
        let output: String
        let exitCode: Int32
    }
    
    /// Execute a system command with optional sudo
    static func execute(command: String, arguments: [String], requiresSudo: Bool) async -> Result {
        if requiresSudo {
            return await executeSudo(command: command, arguments: arguments)
        } else {
            return await executeNormal(command: command, arguments: arguments)
        }
    }
    
    private static func executeNormal(command: String, arguments: [String]) async -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/\(command)")
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return Result(
                success: process.terminationStatus == 0,
                output: output.trimmingCharacters(in: .whitespacesAndNewlines),
                exitCode: process.terminationStatus
            )
        } catch {
            return Result(
                success: false,
                output: "Failed to execute \(command): \(error.localizedDescription)",
                exitCode: -1
            )
        }
    }
    
    private static func executeSudo(command: String, arguments: [String]) async -> Result {
        // Use AppleScript to execute with admin privileges
        let quotedArgs = arguments.map { "'\($0)'" }.joined(separator: " ")
        let script = """
        do shell script "\(command) \(quotedArgs)" with administrator privileges
        """
        
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        let result = appleScript?.executeAndReturnError(&error)
        
        if let error = error {
            return Result(
                success: false,
                output: error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error",
                exitCode: 1
            )
        } else {
            return Result(
                success: true,
                output: result?.stringValue ?? "",
                exitCode: 0
            )
        }
    }
}