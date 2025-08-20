import AppKit
import Foundation

/// Prints a message only when the code is compiled in DEBUG mode.
func log(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}

// --- Main Logic ---
log("[LOG] Starting execution.")

// 1. Argument Parsing
guard CommandLine.arguments.count > 1 else {
    // Non-debug errors should always be printed.
    print("Error: No file path provided.")
    print("Usage: open_pdf <file> [page]")
    exit(1)
}

let filePath = CommandLine.arguments[1]
let pageNumber = (CommandLine.arguments.count > 2) ? CommandLine.arguments[2] : "1"
log("[LOG] Arguments parsed: File='\(filePath)', Page='\(pageNumber)'")

// 2. Resolve file path to an absolute URL
let currentDirectoryPath = FileManager.default.currentDirectoryPath
let fullPath = (filePath as NSString).expandingTildeInPath
let absolutePath: String
if (fullPath as NSString).isAbsolutePath {
    absolutePath = fullPath
} else {
    absolutePath = (currentDirectoryPath as NSString).appendingPathComponent(fullPath)
}

let fileURL = URL(fileURLWithPath: absolutePath).standardized
log("[LOG] Resolved absolute file URL: \(fileURL.path)")

// Check if the file actually exists before trying to open it.
guard FileManager.default.fileExists(atPath: fileURL.path) else {
    print("Error: File does not exist at resolved path: \(fileURL.path)")
    exit(1)
}

// 3. Execute AppleScript to open the file and go to the page.
let success = runAppleScript(forFile: fileURL.path, andPage: pageNumber)

// 4. Check result and exit.
if success {
    log("[LOG] Program finished successfully.")
    exit(0)
} else {
    // Error message was already printed by the helper function.
    exit(1)
}


// --- Helper Function ---

/// Executes an AppleScript using the `osascript` command-line tool.
/// Returns true on success, false on failure.
func runAppleScript(forFile filePath: String, andPage page: String) -> Bool {
    log("[LOG] Preparing to run AppleScript via osascript.")
    let sanitizedPage = page.filter { "0123-456789".contains($0) }
    guard !sanitizedPage.isEmpty else {
        print("Error: Invalid page number provided: '\(page)'")
        return false
    }
    log("[LOG] Sanitized page number: '\(sanitizedPage)'")

    let source = """
    tell application "Preview"
        activate
        open POSIX file "\(filePath)"
        tell front document
            tell application "System Events"
                keystroke "g" using {option down, command down} -- Go to Page…
                delay 0.5
                keystroke "\(sanitizedPage)"
                delay 0.2
                keystroke return
            end tell
        end tell
    end tell
    """

    log("[LOG] Creating Process to run osascript.")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    // Pass the script source via standard input
    process.arguments = ["-"]

    let pipe = Pipe()
    process.standardInput = pipe

    do {
        try process.run()
        // Write the script to the process's standard input
        if let data = source.data(using: .utf8) {
            try pipe.fileHandleForWriting.write(contentsOf: data)
            try pipe.fileHandleForWriting.close()
        }
        
        process.waitUntilExit()
        
        let exitCode = process.terminationStatus
        log("[LOG] osascript exited with code: \(exitCode)")
        
        if exitCode == 0 {
            log("[SUCCESS] osascript executed successfully.")
            return true
        } else {
            print("Error: osascript failed with exit code \(exitCode).")
            return false
        }
    } catch {
        print("Error: Failed to run osascript process: \(error)")
        return false
    }
}
