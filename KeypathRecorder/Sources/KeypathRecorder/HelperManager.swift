import Foundation
import ServiceManagement
import os.log

/// Manages privileged helper registration and Kanata operations via SMAppService
@MainActor
class HelperManager: ObservableObject {
    private let helperPlistName = "com.keypath.kanata.helper.plist"
    private let helperMachServiceName = "com.keypath.kanata.xpc"
    private let logger = os.Logger(subsystem: "com.keypath.KeypathRecorder", category: "HelperManager")
    
    @Published var isHelperRegistered = false
    @Published var status: SMAppService.Status = .notRegistered
    @Published var lastError: String?
    
    private var xpcConnection: NSXPCConnection?
    
    init() {
        checkStatus()
    }
    
    /// Check current helper registration status
    func checkStatus() {
        let service = SMAppService.daemon(plistName: helperPlistName)
        status = service.status
        isHelperRegistered = (status == .enabled)
        
        let statusMsg = "Helper status: \(String(describing: status))"
        logger.info("\(statusMsg)")
    }
    
    /// Register the privileged helper daemon
    func registerHelper() async throws {
        let service = SMAppService.daemon(plistName: helperPlistName)
        
        logger.info("Attempting to register helper...")
        
        do {
            try service.register()
            logger.info("Helper registration initiated")
            
            // Wait briefly for registration to complete
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            checkStatus()
            
            if status == .requiresApproval {
                logger.info("Helper requires user approval in System Settings")
                throw HelperError.requiresApproval
            }
            
            self.lastError = nil
            
        } catch {
            let errorCode = (error as NSError).code
            let errorDomain = (error as NSError).domain
            let errorMsg = "Helper registration failed: \(error.localizedDescription) (Code: \(errorCode), Domain: \(errorDomain))"
            
            logger.error("\(errorMsg)")
            self.lastError = errorMsg
            
            // Enhanced error context for debugging
            logger.error("Bundle path: \(Bundle.main.bundlePath)")
            logger.error("Helper plist name: \(self.helperPlistName)")
            
            throw error
        }
    }
    
    /// Unregister the privileged helper daemon
    func unregisterHelper() async throws {
        let service = SMAppService.daemon(plistName: helperPlistName)
        
        logger.info("Attempting to unregister helper...")
        
        // Close any existing connection
        xpcConnection?.invalidate()
        xpcConnection = nil
        
        do {
            try await service.unregister()
            logger.info("Helper unregistered successfully")
            checkStatus()
            self.lastError = nil
        } catch {
            let errorMsg = "Helper unregistration failed: \(error.localizedDescription)"
            logger.error("\(errorMsg)")
            self.lastError = errorMsg
            throw error
        }
    }
    
    /// Launch Kanata with the specified configuration file
    func launchKanata(configPath: String) async throws -> String {
        guard isHelperRegistered else {
            throw HelperError.notRegistered
        }
        
        guard let kanataPath = RustBridge.findKanataPath() else {
            throw HelperError.kanataNotFound
        }
        
        logger.info("Starting Kanata via helper: \(configPath)")
        let connection = getXPCConnection()
        
        return try await withCheckedThrowingContinuation { continuation in
            let remoteProxy = connection.remoteObjectProxyWithErrorHandler { error in
                self.logger.error("XPC connection error: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            } as! KanataHelperProtocol
            
            remoteProxy.launchKanata(executablePath: kanataPath, configPath: configPath) { success, message in
                if success {
                    let result = message ?? "Kanata launched successfully"
                    self.logger.info("Kanata launched: \(result)")
                    continuation.resume(returning: result)
                } else {
                    let error = message ?? "Unknown error"
                    self.logger.error("Kanata launch failed: \(error)")
                    continuation.resume(throwing: HelperError.kanataLaunchFailed(error))
                }
            }
        }
    }
    
    /// Stop the currently running Kanata instance
    func stopKanata() async throws -> String {
        guard isHelperRegistered else {
            throw HelperError.notRegistered
        }
        
        logger.info("Stopping Kanata via helper")
        let connection = getXPCConnection()
        
        return try await withCheckedThrowingContinuation { continuation in
            let remoteProxy = connection.remoteObjectProxyWithErrorHandler { error in
                self.logger.error("XPC connection error: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            } as! KanataHelperProtocol
            
            remoteProxy.stopKanata { success, message in
                if success {
                    let result = message ?? "Kanata stopped successfully"
                    self.logger.info("Kanata stopped: \(result)")
                    continuation.resume(returning: result)
                } else {
                    let error = message ?? "Unknown error"
                    self.logger.error("Kanata stop failed: \(error)")
                    continuation.resume(throwing: HelperError.kanataStopFailed(error))
                }
            }
        }
    }
    
    /// Get the status of the currently running Kanata instance
    func getKanataStatus() async throws -> String {
        guard isHelperRegistered else {
            throw HelperError.notRegistered
        }
        
        let connection = getXPCConnection()
        
        return try await withCheckedThrowingContinuation { continuation in
            let remoteProxy = connection.remoteObjectProxyWithErrorHandler { error in
                self.logger.error("XPC connection error: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            } as! KanataHelperProtocol
            
            remoteProxy.getKanataStatus { success, message in
                if success {
                    let result = message ?? "Status unknown"
                    continuation.resume(returning: result)
                } else {
                    let error = message ?? "Unknown error"
                    self.logger.error("Kanata status check failed: \(error)")
                    continuation.resume(throwing: HelperError.kanataStatusFailed(error))
                }
            }
        }
    }
    
    /// Open System Settings to allow user to enable the helper
    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
    
    /// Get or create XPC connection to the helper
    private func getXPCConnection() -> NSXPCConnection {
        if let connection = xpcConnection {
            return connection
        }
        
        let connection = NSXPCConnection(machServiceName: helperMachServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: KanataHelperProtocol.self)
        
        connection.invalidationHandler = {
            self.logger.info("XPC connection invalidated")
            self.xpcConnection = nil
        }
        
        connection.interruptionHandler = {
            self.logger.info("XPC connection interrupted")
        }
        
        connection.resume()
        xpcConnection = connection
        
        return connection
    }
}

/// Errors that can occur during helper operations
enum HelperError: LocalizedError {
    case notRegistered
    case requiresApproval
    case kanataNotFound
    case kanataLaunchFailed(String)
    case kanataStopFailed(String)
    case kanataStatusFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notRegistered:
            return "Helper is not registered. Please register the helper first."
        case .requiresApproval:
            return "Helper requires user approval in System Settings > General > Login Items"
        case .kanataNotFound:
            return "Kanata executable not found. Please install Kanata: brew install kanata"
        case .kanataLaunchFailed(let message):
            return "Failed to launch Kanata: \(message)"
        case .kanataStopFailed(let message):
            return "Failed to stop Kanata: \(message)"
        case .kanataStatusFailed(let message):
            return "Failed to get Kanata status: \(message)"
        }
    }
}