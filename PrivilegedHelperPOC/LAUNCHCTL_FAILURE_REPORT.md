# Launchctl Bootstrap Failure Report

**Date**: July 9, 2025  
**Environment**: macOS 15.x (Darwin 25.0.0)  
**Status**: Both SMAppService and manual launchctl operations failing with I/O errors

---

## Summary

Following the senior developer's diagnosis and plist path fix, we applied the recommended changes but continue to experience failures. The issue has now been isolated to a fundamental problem with launchctl itself, not just SMAppService.

**Key Finding**: Manual `launchctl bootstrap` commands are failing with the same "Input/output error" that SMAppService reports, suggesting a deeper system-level issue.

---

## Applied Senior Developer Fixes ✅

### 1. Plist Path Correction
**Problem Identified**: `BundleProgram` with nested path was creating invalid executable location
**Fix Applied**: Changed from:
```xml
<key>BundleProgram</key>
<string>Contents/Library/LaunchDaemons/HelperPOCDaemon</string>
```
To:
```xml
<key>Program</key>
<string>HelperPOCDaemon</string>
```

### 2. Clean Rebuild
- Performed complete clean build with corrected plist
- All code signatures remain valid
- App structure unchanged and correct

---

## Launchctl Testing Results ❌

### Test 1: Direct Plist Loading
```bash
sudo launchctl load -w /path/to/com.keypath.helperpoc.plist
```
**Result**: `Load failed: 5: Input/output error`

### Test 2: Bootstrap with Richer Errors
```bash
sudo launchctl bootstrap system /tmp/com.keypath.helperpoc.plist
```
**Result**: `Bootstrap failed: 5: Input/output error`

### Test 3: Absolute Path Configuration
Created test plist with full absolute path to executable:
```xml
<key>Program</key>
<string>/Users/malpern/.../HelperPOCDaemon</string>
```
**Result**: `Bootstrap failed: 5: Input/output error`

### Test 4: Plist Validation
```bash
plutil -lint /tmp/com.keypath.helperpoc-clean.plist
```
**Result**: `OK` (plist syntax is valid)

---

## File Integrity Verification ✅

### Executable Status
```bash
$ file build/HelperPOCApp.app/Contents/Library/LaunchDaemons/HelperPOCDaemon
Mach-O 64-bit executable arm64

$ ls -la build/HelperPOCApp.app/Contents/Library/LaunchDaemons/HelperPOCDaemon
.rwxr-xr-x malpern staff 109 KB HelperPOCDaemon
```

### Code Signing Status
```bash
$ codesign --verify --verbose build/HelperPOCApp.app/Contents/Library/LaunchDaemons/HelperPOCDaemon
valid on disk
satisfies its Designated Requirement
```

### Plist Validation
- **Syntax**: Valid XML and plist structure
- **Required Keys**: Label, Program, MachServices all present
- **Path Resolution**: Executable exists at specified location

---

## Current Plist Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.keypath.helperpoc</string>
    <key>Program</key>
    <string>/full/absolute/path/to/HelperPOCDaemon</string>
    <key>MachServices</key>
    <dict>
        <key>com.keypath.helperpoc.xpc</key>
        <true/>
    </dict>
    <key>RunAtLoad</key>
    <false/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
```

---

## Error Analysis

### Error Code 5: Input/Output Error
This error code suggests:
1. **File system access issues** - but all files exist and have correct permissions
2. **System security blocking** - possibly SIP, TCC, or other macOS security features
3. **macOS 15 beta issues** - launchctl behavior changes in pre-release OS
4. **Code signing verification failure** - despite manual verification succeeding

### Consistency Across Methods
The fact that **both** SMAppService and manual launchctl operations fail with the same error suggests:
- This is not an SMAppService-specific bug
- The issue is at the launchd/system level
- The problem may be environmental (macOS 15 beta) rather than implementation

---

## Critical Questions for Senior Developer

### 1. macOS 15 Beta Considerations
**Q**: Are there known issues with launchctl/launchd daemon registration on macOS 15 beta?  
**Context**: Error occurs with both SMAppService and manual launchctl, suggesting system-level issue.

### 2. Error Code 5 Interpretation
**Q**: What specific conditions cause launchctl to return "Input/output error" (errno 5)?  
**Context**: This error persists despite valid plist, executable, and permissions.

### 3. System Security Requirements
**Q**: Are there additional security requirements for privileged daemon registration on modern macOS?  
**Context**: Could SIP, notarization, or other security features be blocking registration?

### 4. Code Signing for Daemons
**Q**: Are there specific code signing requirements for executables loaded by launchd?  
**Context**: Manual codesign verification passes, but launchd might have different requirements.

### 5. Alternative Debugging Approaches
**Q**: How can we get more detailed error information from launchctl/launchd?  
**Context**: Both `load` and `bootstrap` commands only return generic I/O error.

### 6. Development Environment
**Q**: Should privileged daemon development be done on stable macOS versions only?  
**Context**: Could beta OS instability be causing fundamental launchd issues?

---

## Attempted Debugging Commands

### System Logs
```bash
# Real-time ServiceManagement logs
log stream --level debug --predicate 'subsystem == "com.apple.servicemanagement"'

# Launchd-specific logs
sudo log stream --debug --info --predicate "process == 'launchd'"
```

### System State Checks
```bash
# Check for existing services
launchctl list | grep keypath

# System integrity
csrutil status
```

---

## Next Steps Pending Guidance

### Immediate Actions
1. **Await senior developer analysis** of launchctl I/O error
2. **Gather additional system information** if requested
3. **Test on macOS 14** if environment change recommended

### Potential Investigation Areas
1. **System permission debugging** - TCC database, SIP status
2. **Alternative executable formats** - different compilation/signing approaches
3. **Legacy daemon registration methods** - if modern approaches are broken
4. **Environment isolation** - clean macOS installation testing

---

## Technical Environment

- **macOS Version**: Darwin 25.0.0 (macOS 15.x beta)
- **Hardware**: Apple Silicon (arm64)
- **Development Tools**: Swift 5.9+, Xcode Command Line Tools
- **Code Signing**: Developer ID Application (valid and verified)
- **Notarization**: Complete and stapled

---

## Available Resources

### Complete Implementation
- **Source code**: All Swift sources for app and daemon
- **Build system**: Automated build and signing scripts
- **Test plists**: Multiple plist configurations for comparison

### Logs and Diagnostics
- **App logs**: `/tmp/helperpoc-app.log` - SMAppService registration attempts
- **System access**: Can provide detailed system logs, security status
- **File verification**: All file permissions, signatures, and integrity checks

---

**Conclusion**: The senior developer's plist path diagnosis was correct in principle, but applying the fix revealed a deeper issue. The consistent "Input/output error" from launchctl suggests either a macOS 15 beta bug or an undocumented system requirement we're missing. This appears to be a system-level launchd issue rather than an application implementation problem.