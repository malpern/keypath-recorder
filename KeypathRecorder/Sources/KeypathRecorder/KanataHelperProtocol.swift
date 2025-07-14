import Foundation

/// XPC protocol for secure communication with the privileged Kanata helper
@objc protocol KanataHelperProtocol {
    
    /// Launch Kanata with the specified executable and configuration paths
    /// - Parameters:
    ///   - executablePath: Full path to the Kanata executable
    ///   - configPath: Full path to the .kbd configuration file
    ///   - reply: Completion handler with success status and optional message
    func launchKanata(executablePath: String, configPath: String, reply: @escaping (Bool, String?) -> Void)
    
    /// Stop the currently running Kanata instance
    /// - Parameter reply: Completion handler with success status and optional message
    func stopKanata(reply: @escaping (Bool, String?) -> Void)
    
    /// Get the status of the currently running Kanata instance
    /// - Parameter reply: Completion handler with success status and status message
    func getKanataStatus(reply: @escaping (Bool, String?) -> Void)
    
    /// Get information about the helper daemon
    /// - Parameter reply: Completion handler with success status and info message
    func getHelperInfo(reply: @escaping (Bool, String?) -> Void)
}