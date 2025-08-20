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
runAppleScript(forFile: fileURL.path, andPage: pageNumber)

// 4. Keep the program alive to allow the async AppleScript to execute.
// The AppleScript is dispatched to a background thread, so the main thread
// needs to wait for it to complete. A RunLoop is a good way to do this.
RunLoop.main.run(until: Date(timeIntervalSinceNow: 5.0))

log("[LOG] Program finished.")


// --- Helper Function ---

/// Compiles and executes an AppleScript to control Preview.
func runAppleScript(forFile filePath: String, andPage page: String) {
    log("[LOG] Preparing to run AppleScript.")
    let sanitizedPage = page.filter { "0123456789".contains($0) }
    guard !sanitizedPage.isEmpty else {
        print("Error: Invalid page number provided: '\(page)'")
        exit(1)
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

    log("[LOG] Creating NSAppleScript object.")
    if let script = NSAppleScript(source: source) {
        // Run the script on a background thread to avoid blocking the main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            var errorInfo: NSDictionary?
            _ = script.executeAndReturnError(&errorInfo)
            
            if let error = errorInfo {
                DispatchQueue.main.async {
                    print("AppleScript Error: \(error)")
                    exit(1)
                }
            } else {
                DispatchQueue.main.async {
                    log("[SUCCESS] AppleScript executed successfully.")
                    exit(0)
                }
            }
        }
    } else {
        print("Error: Could not create NSAppleScript object.")
        exit(1)
    }
}
