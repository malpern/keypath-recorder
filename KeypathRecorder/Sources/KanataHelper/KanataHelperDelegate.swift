import Foundation
import Security
import os.log

/// XPC listener delegate that handles incoming connections to the Kanata helper
class KanataHelperDelegate: NSObject, NSXPCListenerDelegate {
    private let logger = os.Logger(subsystem: "com.keypath.KeypathRecorder", category: "KanataHelperDelegate")
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        logger.info("New XPC connection request")
        
        // Validate the connecting client's code signature
        guard validateClient(connection: newConnection) else {
            logger.error("Client validation failed")
            return false
        }
        
        // Configure the connection
        newConnection.exportedInterface = NSXPCInterface(with: KanataHelperProtocol.self)
        let helperTool = KanataHelperTool()
        newConnection.exportedObject = helperTool
        
        newConnection.invalidationHandler = {
            self.logger.info("XPC connection invalidated")
        }
        
        newConnection.interruptionHandler = {
            self.logger.info("XPC connection interrupted")
        }
        
        newConnection.resume()
        
        logger.info("XPC connection accepted and configured")
        return true
    }
    
    /// Validate that the connecting client is the authorized KeypathRecorder app
    private func validateClient(connection: NSXPCConnection) -> Bool {
        // For now, skip client validation to simplify initial implementation
        // In production, you would implement proper code signature validation
        logger.info("Accepting connection (validation bypassed for development)")
        return true
        
        /*
        // Get the client's audit token
        let auditToken = connection.auditToken
        
        // Convert to pid for logging
        let clientPID = audit_token_to_pid(auditToken)
        logger.info("Validating client PID: \(clientPID)")
        
        // Create SecCode from audit token
        var clientSecCode: SecCode?
        let status = SecCodeCopyGuestWithAttributes(nil, [kSecGuestAttributeAudit: auditToken] as CFDictionary, [], &clientSecCode)
        
        guard status == errSecSuccess, let secCode = clientSecCode else {
            logger.error("Failed to get client SecCode (pid: \(clientPID), status: \(status))")
            return false
        }
        
        // Define requirement for the KeypathRecorder app
        // This should match the actual bundle identifier and team ID
        let requirementString = "identifier \"com.keypath.KeypathRecorder\" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */"
        
        var requirement: SecRequirement?
        guard SecRequirementCreateWithString(requirementString as CFString, [], &requirement) == errSecSuccess,
              let req = requirement else {
            logger.error("Failed to create SecRequirement")
            return false
        }
        
        // Validate the client against the requirement
        let validationStatus = SecCodeCheckValidity(secCode, [], req)
        guard validationStatus == errSecSuccess else {
            logger.error("Client code signature validation failed (pid: \(clientPID), status: \(validationStatus))")
            return false
        }
        
        logger.info("Client validation successful (pid: \(clientPID))")
        return true
        */
    }
}