# macOS Privileged Helper Tool Implementation Plan
## Using SMAppService for KeypathRecorder

**Date**: July 8, 2025  
**Target**: macOS 13+ (Ventura, Sonoma, Sequoia)  
**Goal**: Enable KeypathRecorder to launch Kanata with sudo privileges automatically

---

## Executive Summary

This document outlines a plan to implement privileged helper tools using Apple's modern SMAppService API (introduced in macOS 13) to replace manual `sudo` commands in KeypathRecorder. The approach will create a privileged daemon that can launch Kanata with appropriate permissions while maintaining security best practices.

---

## Background & Current State

### Current Limitation
KeypathRecorder currently requires users to manually run:
```bash
sudo kanata --cfg "/path/to/config.kbd"
```

This breaks the "under 60 seconds" user experience goal and creates friction for non-technical users.

### Previous Attempts
- Multiple failed attempts with SMJobBless (legacy API)
- Complex code signing and authorization issues
- Inconsistent behavior across macOS versions

### Modern Solution: SMAppService
Apple's recommended approach since macOS 13, offering:
- Simplified implementation vs SMJobBless
- Better security model
- Native XPC integration
- User-friendly approval process

---

## Technical Architecture

### Components Overview

```
KeypathRecorder.app/
├── Contents/
│   ├── MacOS/
│   │   └── KeypathRecorder              # Main app executable
│   ├── Library/
│   │   └── LaunchDaemons/               # SMAppService required location
│   │       ├── KeypathHelper            # Privileged helper daemon
│   │       └── com.keypath.helper.plist # Launch daemon configuration
│   └── Info.plist                       # App bundle metadata
```

### Communication Flow

```
[User Action] → [Main App] → [XPC Request] → [Privileged Helper] → [Launch Kanata]
                     ↓
                [User Approval Required] (First time only)
                     ↓
            [System Settings Background Items]
```

### Process Architecture

1. **Main Application** (User Space)
   - SwiftUI interface for keyboard mapping
   - SMAppService registration/management
   - XPC client for communicating with helper

2. **Privileged Helper Tool** (Root Daemon)
   - Runs with root privileges via launchd
   - XPC service provider
   - Executes Kanata with proper permissions
   - Validates requests from authorized clients

3. **XPC Communication Layer**
   - Secure inter-process communication
   - Request/response protocol for Kanata operations
   - Client authentication and authorization

---

## Implementation Plan

### Phase 1: Proof of Concept (1-2 days)
**Goal**: Minimal working privileged helper demonstration

**Deliverables**:
- Simple "Hello World" privileged helper
- Basic XPC communication
- SMAppService registration/unregistration
- Documentation of any issues encountered

**Components**:
```
PrivilegedHelperExample/
├── HelloWorldApp/               # Main SwiftUI app
│   ├── ContentView.swift       # UI with register/test buttons
│   ├── HelperManager.swift     # SMAppService management
│   └── XPCClient.swift         # XPC communication
├── HelloWorldHelper/           # Privileged helper tool
│   ├── main.swift             # Helper daemon entry point
│   ├── XPCService.swift       # XPC service implementation
│   └── HelperOperations.swift # Privileged operations
└── Resources/
    └── com.example.helper.plist # Launch daemon config
```

**Test Operations**:
- Create file in `/tmp` with root ownership
- Execute simple shell command with privileges
- Verify XPC security and client validation

### Phase 2: KeypathRecorder Integration (2-3 days)
**Goal**: Integrate privileged helper into KeypathRecorder

**Components**:
- Extend existing RustBridge with helper communication
- Add helper management UI to KeypathRecorder
- Implement Kanata-specific operations in helper
- Update file generation to work with helper

**New User Flow**:
1. User creates keyboard mapping (existing)
2. App automatically registers helper (if needed)
3. System prompts for user approval (first time)
4. User clicks "Save & Launch" → Kanata starts immediately
5. Achievement: Full workflow in <60 seconds

### Phase 3: Production Hardening (1-2 days)
**Goal**: Security, error handling, and user experience polish

**Security Enhancements**:
- Proper client certificate validation
- Command injection prevention
- Resource cleanup and daemon lifecycle management
- Audit logging of privileged operations

**Error Handling**:
- Helper registration failure recovery
- XPC communication timeouts
- Kanata process management (start/stop/status)
- User-friendly error messages

**UX Improvements**:
- System Settings deep-linking for approval
- Helper status indicators in UI
- Automatic helper uninstallation option
- Help documentation for user approval process

---

## Technical Specifications

### SMAppService Implementation

```swift
import ServiceManagement

class HelperManager {
    private let helperPlistName = "com.keypath.helper"
    
    func registerHelper() throws {
        let service = SMAppService.daemon(plistName: helperPlistName)
        try service.register()
    }
    
    func checkHelperStatus() -> SMAppService.Status {
        let service = SMAppService.daemon(plistName: helperPlistName)
        return service.status
    }
}
```

### Launch Daemon Plist Configuration

```xml
<!-- File: com.keypath.helper.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.keypath.helper</string>
    <!-- Use 'Program', not 'BundleProgram'. Path is relative to plist location -->
    <key>Program</key>
    <string>KeypathHelper</string>
    <key>MachServices</key>
    <dict>
        <!-- This must match the service name you connect to from the app -->
        <key>com.keypath.helper.xpc</key>
        <true/>
    </dict>
    <!-- RunAtLoad=false and KeepAlive=false for on-demand XPC service -->
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
```

### XPC Protocol Definition

```swift
@objc protocol HelperProtocol {
    // Pass the full path to kanata from the client (don't hardcode)
    func launchKanata(executablePath: String, configPath: String, reply: @escaping (Bool, String?) -> Void)
    func stopKanata(reply: @escaping (Bool, String?) -> Void)
    func getKanataStatus(reply: @escaping (Bool, String?) -> Void)
}
```

### Helper Tool Structure

```swift
import Foundation
import os.log

class HelperTool: NSObject, HelperProtocol {
    private var kanataProcess: Process?
    
    func launchKanata(executablePath: String, configPath: String, reply: @escaping (Bool, String?) -> Void) {
        // 1. Stop any existing instance managed by this helper
        if let existingProcess = self.kanataProcess, existingProcess.isRunning {
            existingProcess.terminate()
            existingProcess.waitUntilExit()
            self.kanataProcess = nil
        }
        
        // 2. Validate paths passed from the unprivileged client
        guard !executablePath.isEmpty, FileManager.default.isExecutableFile(atPath: executablePath) else {
            reply(false, "Invalid Kanata executable path.")
            return
        }
        guard !configPath.isEmpty, FileManager.default.fileExists(atPath: configPath) else {
            reply(false, "Config file not found.")
            return
        }
        
        // 3. Launch the process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["--cfg", configPath]
        
        // Add termination handler to clean up reference
        process.terminationHandler = { [weak self] _ in
            self?.kanataProcess = nil
        }
        
        do {
            try process.run()
            self.kanataProcess = process
            reply(true, nil)
        } catch {
            reply(false, error.localizedDescription)
        }
    }
    
    func stopKanata(reply: @escaping (Bool, String?) -> Void) {
        guard let process = self.kanataProcess, process.isRunning else {
            reply(true, "Kanata was not running.") // Not an error if already stopped
            return
        }
        process.terminate()
        reply(true, nil)
    }
}
```

---

## Security Considerations

### Client Authentication
- **MANDATORY XPC Client Validation**: Helper MUST cryptographically verify connecting XPC client
- **Code Signature Validation**: Helper validates client certificate matches expected signature
- **Bundle Identifier Check**: Ensure requests come from authorized KeypathRecorder app
- **XPC Peer Verification**: Standard XPC security model enforcement

#### Required XPC Security Implementation

```swift
// MANDATORY: Implement in Helper's NSXPCListenerDelegate
class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // 1. Verify the connecting client's code signature
        guard let clientAuditToken = newConnection.auditToken.val else {
            os_log("Failed to get client audit token", type: .error)
            return false
        }
        
        let clientPID = audit_token_to_pid(clientAuditToken)
        var clientSecCode: SecCode?
        let status = SecCodeCopyGuestWithAttributes(nil, [kSecGuestAttributeAudit: clientAuditToken] as CFDictionary, [], &clientSecCode)
        
        guard status == errSecSuccess, let secCode = clientSecCode else {
            os_log("Failed to get client SecCode (pid: %d)", type: .error, clientPID)
            return false
        }
        
        // 2. Define the requirement for the client
        // Replace "YOUR_TEAM_ID" and "com.keypath.KeypathRecorder"
        let requirementString = "identifier \"com.keypath.KeypathRecorder\" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = \"YOUR_TEAM_ID\""
        
        var requirement: SecRequirement?
        guard SecRequirementCreateWithString(requirementString as CFString, [], &requirement) == errSecSuccess, let req = requirement else {
            os_log("Failed to create SecRequirement", type: .error)
            return false
        }
        
        // 3. Perform the validation
        let validationStatus = SecCodeCheckValidity(secCode, [], req)
        guard validationStatus == errSecSuccess else {
            os_log("Client code signature validation failed for pid %d with status %d", type: .error, clientPID, validationStatus)
            return false
        }
        
        // If validation passes, configure and resume the connection
        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        let helper = HelperTool()
        newConnection.exportedObject = helper
        newConnection.resume()
        
        return true
    }
}
```

### Privilege Minimization
- **Specific Operations Only**: Helper only supports Kanata-related operations
- **Path Validation**: Strict validation of file paths and arguments
- **No Shell Injection**: Direct process execution, no shell interpretation
- **Resource Limits**: Prevent helper from consuming excessive system resources

### User Control
- **Explicit Approval**: User must approve helper in System Settings
- **Visibility**: Helper appears in Login Items as "KeypathRecorder Helper"
- **Revocable**: User can disable helper at any time
- **Audit Trail**: Operations logged to system log

---

## Risk Assessment

### High Priority Risks
1. **User Approval Friction**: Users may not understand or approve helper
   - *Mitigation*: Clear UI guidance, help documentation
   
2. **Kanata Conflicts**: Multiple keyboard tools may conflict
   - *Mitigation*: Detect and warn about Karabiner-Elements
   
3. **macOS Version Compatibility**: SMAppService behavior varies across versions
   - *Mitigation*: Test on multiple macOS versions, fallback handling

### Medium Priority Risks
4. **Code Signing Issues**: Developer certificate requirements
   - *Mitigation*: Comprehensive signing documentation and testing
   
5. **XPC Communication Failures**: Network issues or service unavailability
   - *Mitigation*: Robust error handling, retry mechanisms, timeouts

### Low Priority Risks
6. **Helper Process Crashes**: Daemon becomes unavailable
   - *Mitigation*: Automatic restart via launchd, status monitoring

---

## Testing Strategy

### Unit Testing
- XPC protocol compliance and error handling
- Helper registration/unregistration cycles
- Security validation (unauthorized access attempts)
- Kanata process lifecycle management

### Integration Testing
- End-to-end workflow from UI to Kanata execution
- Multiple concurrent mapping operations
- Helper service restart scenarios
- Cross-version macOS compatibility

### User Acceptance Testing
- First-time user approval process
- Error recovery scenarios
- Performance under normal usage
- Documentation clarity and completeness

---

## Success Criteria

### Functional Requirements
- ✅ Helper successfully registers on first app launch
- ✅ User approval process completes without confusion
- ✅ Kanata launches with root privileges via helper
- ✅ XPC communication is reliable and secure
- ✅ Helper can be cleanly uninstalled

### Performance Requirements
- ✅ Helper registration completes in <5 seconds
- ✅ Kanata launch via helper takes <3 seconds
- ✅ XPC round-trip latency <100ms
- ✅ Memory footprint <10MB for idle helper

### Security Requirements
- ✅ Only authorized KeypathRecorder instances can communicate with helper
- ✅ Helper validates all input parameters
- ✅ No privilege escalation beyond intended Kanata operations
- ✅ All privileged operations are auditable

### User Experience Requirements
- ✅ Complete keyboard mapping workflow in <60 seconds (including first-time setup)
- ✅ Clear status indicators for helper state
- ✅ Helpful error messages with actionable guidance
- ✅ No unexpected system prompts after initial approval

---

## Alternative Approaches Considered

### 1. AppleScript Automation
**Approach**: Use `osascript` to prompt for sudo password
**Rejected**: Still requires user interaction, poor UX, security concerns

### 2. Terminal.app Integration
**Approach**: Auto-open Terminal with pre-filled sudo command
**Rejected**: Breaks automation goal, requires user action

### 3. SMJobBless (Legacy)
**Approach**: Use older privileged helper API
**Rejected**: Overly complex, deprecated, poor reliability

### 4. System Extension
**Approach**: Use DriverKit or SystemExtension framework
**Rejected**: Overkill for this use case, requires entitlements

---

## Timeline & Milestones

### Week 1: Research & Proof of Concept
- **Day 1-2**: Complete SMAppService proof of concept
- **Day 3**: Senior developer review and feedback incorporation
- **Day 4-5**: Address any fundamental issues discovered

### Week 2: Integration & Testing
- **Day 1-2**: Integrate helper into KeypathRecorder
- **Day 3**: Comprehensive testing across macOS versions
- **Day 4**: Security review and hardening
- **Day 5**: Documentation and user guide updates

### Week 3: Polish & Release Preparation
- **Day 1-2**: UX refinements and error handling
- **Day 3**: Beta testing with real users
- **Day 4**: Bug fixes and final optimizations
- **Day 5**: Release preparation and documentation

---

## Senior Developer Review Feedback (Completed)

### Questions & Answers

1. **SMAppService vs SMJobBless**: ✅ **SMAppService is production-ready** - no SMJobBless fallback needed

2. **XPC Security Model**: ✅ **Code signature validation is critical** - must implement cryptographic client verification

3. **Helper Lifecycle**: ✅ **On-demand is optimal** - RunAtLoad=false, KeepAlive=false recommended

4. **Error Recovery**: ✅ **launchd auto-restarts** - implement retry logic in main app's XPC client

5. **Code Signing**: ✅ **Standard Developer ID** - both app and helper must be signed with same certificate

6. **Testing Strategy**: ✅ **Focus on edge cases** - user denial, uninstall, upgrade, race conditions

7. **Deployment**: ✅ **Standard practice** - embedded helpers are common, notarization required

8. **macOS Version Support**: ✅ **macOS 13+ sufficient** - focusing on SMAppService only

### Key Corrections Applied
- ✅ Fixed bundle structure: `Contents/Library/LaunchDaemons/`
- ✅ Corrected plist: `Program` instead of `BundleProgram`
- ✅ Added mandatory XPC client validation
- ✅ Improved process lifecycle management
- ✅ Removed hardcoded executable paths

---

## Conclusion

The SMAppService approach represents a significant simplification over previous privileged helper implementations while maintaining security and user control. The proposed phased implementation minimizes risk while delivering the core functionality needed for KeypathRecorder's automation goals.

Success of this implementation will eliminate the current manual `sudo` requirement and achieve the target "<60 seconds" user experience for keyboard mapping workflows.

**Status**: Senior developer review completed with excellent feedback. Ready to proceed with Phase 1 proof of concept implementation using corrected technical specifications.