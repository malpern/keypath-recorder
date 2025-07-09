import Foundation

class Logger {
    static let shared = Logger()
    private let logFile: URL
    private let queue = DispatchQueue(label: "logger", qos: .utility)
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logFile = documentsPath.appendingPathComponent("keypath_debug.log")
        
        // Clear previous log on startup
        try? "=== KeyPath Recorder Debug Log Started ===\n".write(to: logFile, atomically: true, encoding: .utf8)
    }
    
    func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logEntry = "\(timestamp) [\(fileName):\(line)] \(function): \(message)\n"
        
        queue.async {
            if let data = logEntry.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.logFile.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: self.logFile) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: self.logFile)
                }
            }
        }
        
        // Also print to console for immediate visibility
        print("LOG: \(message)")
    }
    
    func getLogPath() -> String {
        return logFile.path
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}