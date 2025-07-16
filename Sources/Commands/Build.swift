import ArgumentParser
import Foundation

struct Build: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Build and manage the Dials CLI tool"
    )
    
    @Flag(name: .long, help: "Build in debug mode (default: release)")
    var debug = false
    
    @Flag(name: .long, help: "Install to system after building")
    var install = false
    
    @Option(name: .long, help: "Custom installation path (default: /usr/local/bin)")
    var installPath: String?
    
    @Flag(name: .long, help: "Show build information for current binary")
    var info = false
    
    func run() throws {
        if info {
            showBuildInfo()
            return
        }
        
        // Use the build.sh script
        let scriptPath = findBuildScript()
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            print("Error: build.sh not found at \(scriptPath)")
            print("Make sure you're running from the Dials project directory")
            throw ExitCode.failure
        }
        
        var args = [scriptPath]
        
        if debug {
            args.append("--debug")
        }
        
        if install {
            args.append("--install")
            if let path = installPath {
                args.append("--install-path")
                args.append(path)
            }
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = args
        
        // Connect to current terminal
        process.standardInput = FileHandle.standardInput
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ExitCode(process.terminationStatus)
        }
    }
    
    private func findBuildScript() -> String {
        // Try to find build.sh relative to the executable
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        
        // Check common locations
        let possiblePaths = [
            // If running from .build directory
            executableURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("build.sh").path,
            // If running from project root
            "./build.sh",
            // If installed, check for DIALS_PROJECT_PATH env var
            ProcessInfo.processInfo.environment["DIALS_PROJECT_PATH"].map { $0 + "/build.sh" } ?? ""
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Default to current directory
        return "./build.sh"
    }
    
    private func showBuildInfo() {
        print("Dials Build Information")
        print("=======================")
        
        // Binary location
        let binaryPath = CommandLine.arguments[0]
        print("Binary: \(binaryPath)")
        
        // Binary size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: binaryPath),
           let size = attributes[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            print("Size: \(formatter.string(fromByteCount: size))")
        }
        
        // Build date (from file modification time)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: binaryPath),
           let modDate = attributes[.modificationDate] as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            print("Built: \(formatter.string(from: modDate))")
        }
        
        // Version
        print("Version: \(DialsCLI.configuration.version)")
        
        // Swift version
        print("Swift: \(getSwiftVersion())")
        
        // Platform
        print("Platform: \(getPlatformInfo())")
    }
    
    private func getSwiftVersion() -> String {
        #if swift(>=5.10)
        return "5.10+"
        #elseif swift(>=5.9)
        return "5.9"
        #else
        return "5.x"
        #endif
    }
    
    private func getPlatformInfo() -> String {
        var info = ProcessInfo.processInfo.operatingSystemVersionString
        
        #if arch(arm64)
        info += " (Apple Silicon)"
        #elseif arch(x86_64)
        info += " (Intel)"
        #endif
        
        return info
    }
}