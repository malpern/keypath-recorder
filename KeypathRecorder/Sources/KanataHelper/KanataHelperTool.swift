import Foundation
import os.log

/// Implementation of the Kanata helper tool that performs privileged operations
class KanataHelperTool: NSObject, KanataHelperProtocol {
    private let logger = os.Logger(subsystem: "com.keypath.KeypathRecorder", category: "KanataHelperTool")
    private var kanataProcess: Process?
    
    override init() {
        super.init()
        logger.info("Kanata helper tool initialized")
    }
    
    /// Launch Kanata with the specified executable and configuration paths
    func launchKanata(executablePath: String, configPath: String, reply: @escaping (Bool, String?) -> Void) {
        logger.info("Launch request: executable=\(executablePath), config=\(configPath)")
        
        // Stop any existing instance managed by this helper
        if let existingProcess = kanataProcess, existingProcess.isRunning {
            logger.info("Stopping existing Kanata process")
            existingProcess.terminate()
            existingProcess.waitUntilExit()
            kanataProcess = nil
        }
        
        // Validate executable path
        guard !executablePath.isEmpty, FileManager.default.isExecutableFile(atPath: executablePath) else {
            let error = "Invalid Kanata executable path: \(executablePath)"
            logger.error("\(error)")
            reply(false, error)
            return
        }
        
        // Validate config path
        guard !configPath.isEmpty, FileManager.default.fileExists(atPath: configPath) else {
            let error = "Config file not found: \(configPath)"
            logger.error("\(error)")
            reply(false, error)
            return
        }
        
        // Additional security: ensure paths are not attempting path traversal
        guard !executablePath.contains(".."), !configPath.contains("..") else {
            let error = "Path traversal detected in arguments"
            logger.error("\(error)")
            reply(false, error)
            return
        }
        
        // Create and configure the process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["--cfg", configPath]
        
        // Set up process environment
        process.environment = [
            "PATH": "/usr/local/bin:/usr/bin:/bin",
            "HOME": "/var/empty"
        ]
        
        // Add termination handler to clean up reference
        process.terminationHandler = { [weak self] terminatedProcess in
            self?.logger.info("Kanata process terminated with status: \(terminatedProcess.terminationStatus)")
            self?.kanataProcess = nil
        }
        
        // Launch the process
        do {
            try process.run()
            kanataProcess = process
            
            let message = "Kanata launched successfully with PID: \(process.processIdentifier)"
            logger.info("\(message)")
            reply(true, message)
            
        } catch {
            let errorMessage = "Failed to launch Kanata: \(error.localizedDescription)"
            logger.error("\(errorMessage)")
            reply(false, errorMessage)
        }
    }
    
    /// Stop the currently running Kanata instance
    func stopKanata(reply: @escaping (Bool, String?) -> Void) {
        logger.info("Stop request received")
        
        guard let process = kanataProcess, process.isRunning else {
            let message = "Kanata is not running"
            logger.info("\(message)")
            reply(true, message)
            return
        }
        
        logger.info("Terminating Kanata process (PID: \(process.processIdentifier))")
        
        // Send SIGTERM for graceful shutdown
        process.terminate()
        
        // Wait a bit for graceful shutdown
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            if process.isRunning {
                // Force kill if still running
                self.logger.warning("Kanata did not terminate gracefully, sending SIGKILL")
                kill(process.processIdentifier, SIGKILL)
            }
            
            let message = "Kanata stopped successfully"
            self.logger.info("\(message)")
            reply(true, message)
        }
    }
    
    /// Get the status of the currently running Kanata instance
    func getKanataStatus(reply: @escaping (Bool, String?) -> Void) {
        logger.info("Status request received")
        
        if let process = kanataProcess, process.isRunning {
            let message = "Kanata is running (PID: \(process.processIdentifier))"
            logger.info("\(message)")
            reply(true, message)
        } else {
            let message = "Kanata is not running"
            logger.info("\(message)")
            reply(true, message)
        }
    }
    
    /// Get information about the helper daemon
    func getHelperInfo(reply: @escaping (Bool, String?) -> Void) {
        logger.info("Helper info request received")
        
        let info = """
        Kanata Privileged Helper
        Version: 1.0
        Bundle: com.keypath.KeypathRecorder
        UID: \(getuid())
        PID: \(getpid())
        """
        
        logger.info("Helper info: \(info)")
        reply(true, info)
    }
}