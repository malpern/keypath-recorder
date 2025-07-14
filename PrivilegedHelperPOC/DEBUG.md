# SMAppService Privileged Helper Debug Report

**Date**: July 8, 2025  
**Objective**: Create a fully functional privileged helper using SMAppService that can execute root operations  
**Status**: Registration failing with "Unable to read plist" error

---

## Summary

We have successfully created a properly signed Swift application with a privileged helper daemon, but SMAppService registration is failing with a consistent "Unable to read plist: com.keypath.helperpoc" error. Despite following Apple's documentation and senior developer guidance, the helper cannot be registered.

---

## What We've Accomplished ✅

### 1. Correct Architecture Implementation
- **Bundle Structure**: Implemented correct `Contents/Library/LaunchDaemons/` location
- **Plist Configuration**: Uses `Program` key (not `BundleProgram`) as specified
- **XPC Protocol**: Defined proper protocol with secure client validation
- **Logging System**: Comprehensive file logging to `/tmp/helperpoc-*.log`

### 2. Proper Code Signing
- **Developer ID**: Successfully signed with "Developer ID Application: Micah Alpern (X2RKZ5TG99)"
- **Both Executables**: Main app and helper daemon properly signed
- **Entitlements**: Created appropriate entitlements files
- **Verification**: All signatures verify correctly with `codesign --verify`

### 3. Testing Infrastructure
- **Automated Testing**: Full test suite with `automated_test.sh`
- **Real-time Monitoring**: Log monitoring with `log_monitor.sh`
- **Build System**: Automated build and signing with `build_and_sign.sh`

---

## Current Problem ❌

### Error Details
```
[ERROR] [APP] Helper registration failed: The operation couldn't be completed. Unable to read plist: com.keypath.helperpoc
```

### When It Occurs
- Happens immediately when calling `SMAppService.daemon(plistName: "com.keypath.helperpoc").register()`
- No system approval dialog appears
- Helper status remains `SMAppServiceStatus(rawValue: 3)` = "Not found"

### What We've Verified
- ✅ Plist file exists at correct location: `Contents/Library/LaunchDaemons/com.keypath.helperpoc.plist`
- ✅ Plist syntax is valid: `plutil -lint` passes
- ✅ Helper daemon identifier matches plist label: "com.keypath.helperpoc"
- ✅ SMPrivilegedExecutables entry matches helper identifier
- ✅ All code signatures verify successfully

---

## Attempted Solutions

### 1. Bundle Structure Corrections
**Tried**: Initially had helper in `Contents/MacOS/`, moved to `Contents/Library/LaunchDaemons/`
**Result**: Fixed architecture but didn't resolve plist error

### 2. Plist Configuration Updates
**Tried**: Changed from `BundleProgram` to `Program` key in plist
**Result**: Syntactically correct but error persists

### 3. Code Signing Fixes
**Tried**: 
- Added proper entitlements files
- Set explicit identifier during signing: `--identifier "com.keypath.helperpoc"`
- Verified both app and helper have matching team ID

**Result**: Signatures are valid but registration still fails

### 4. Identifier Consistency
**Tried**: Ensured all identifiers match:
- Plist Label: "com.keypath.helperpoc"
- Helper Code Signature: "com.keypath.helperpoc"  
- SMPrivilegedExecutables key: "com.keypath.helperpoc"
- HelperManager plistName: "com.keypath.helperpoc"

**Result**: Everything matches but error continues

---

## Current File Structure

```
build/HelperPOCApp.app/
├── Contents/
│   ├── Info.plist                    # Contains SMPrivilegedExecutables
│   ├── MacOS/
│   │   └── HelperPOCApp              # Signed main app
│   └── Library/
│       └── LaunchDaemons/
│           ├── HelperPOCDaemon       # Signed helper (identifier: com.keypath.helperpoc)
│           └── com.keypath.helperpoc.plist  # Valid plist
```

---

## Root Cause Hypotheses

### Hypothesis 1: macOS Version Compatibility
**Theory**: SMAppService behavior varies between macOS versions
**Evidence**: Using macOS 15.x (Darwin 25.0.0), which might have stricter requirements
**Status**: Unknown - need to verify SMAppService requirements for this macOS version

### Hypothesis 2: Sandbox/Entitlements Issue
**Theory**: App might need different entitlements or sandbox configuration
**Evidence**: Currently using `com.apple.security.app-sandbox: false`
**Status**: Unknown - might need to try sandboxed approach

### Hypothesis 3: Notarization Requirement
**Theory**: Modern macOS might require notarization even for Developer ID signed apps
**Evidence**: App is signed but not notarized
**Status**: Likely - Apple has been tightening requirements progressively

### Hypothesis 4: System Integrity Protection (SIP) Interference
**Theory**: SIP might be blocking privileged helper registration
**Evidence**: No direct evidence, but could explain plist reading failure
**Status**: Unknown - need to check SIP status

### Hypothesis 5: Missing System Permissions
**Theory**: App might need explicit permissions that aren't being requested
**Evidence**: No permission dialogs have appeared
**Status**: Possible - might need specific privacy permissions

### Hypothesis 6: Plist Location/Format Issue
**Theory**: Despite looking correct, something about the plist location or format is wrong
**Evidence**: System can't "read" the plist even though it exists and validates
**Status**: Possible - might need different approach to bundle embedding

---

## Questions for Senior Developer

### Technical Questions

1. **SMAppService Version Compatibility**: Are there known issues with SMAppService on macOS 15.x (Darwin 25.0.0)? Should we expect different behavior compared to macOS 13-14?

2. **Notarization Requirements**: Is notarization now required for SMAppService registration, even for local development? If so, what's the recommended development workflow?

3. **Bundle Structure Validation**: The "Unable to read plist" error suggests macOS can't find/access the plist. Are there any known issues with the `Contents/Library/LaunchDaemons/` location, or alternative approaches?

4. **Entitlements Deep Dive**: Are there specific entitlements required for SMAppService that we might be missing? Should the app be sandboxed or unsandboxed?

5. **SIP and Security**: Could System Integrity Protection or other security features be blocking this? Are there recommended ways to verify this?

### Debugging Questions

6. **System Logs**: What's the best way to access detailed SMAppService registration logs on modern macOS? The `log show` command seems to have issues.

7. **Alternative Validation**: Is there a way to manually test if the helper daemon can be loaded by launchd independently of SMAppService?

8. **Error Interpretation**: The "Unable to read plist" error is quite generic. Are there known specific causes for this error in SMAppService context?

### Process Questions

9. **Development Workflow**: What's the recommended development approach for privileged helpers? Should we be testing on a separate machine, VM, or with specific system configurations?

10. **Fallback Strategies**: If SMAppService continues to fail, are there alternative approaches for the KeypathRecorder use case that would be more reliable?

---

## Next Steps Pending Senior Review

### Immediate Actions
1. **Wait for senior developer input** before attempting more complex solutions
2. **Gather additional system information** if requested
3. **Test alternative approaches** based on recommendations

### Potential Solutions to Explore (Based on Feedback)
1. **Notarization workflow** if required
2. **Alternative bundle structures** if current approach is flawed  
3. **Different entitlements configuration** if sandbox approach needed
4. **System permission debugging** if privacy/security issues suspected
5. **Legacy SMJobBless fallback** if SMAppService proves unreliable

---

## Technical Environment

- **macOS Version**: Darwin 25.0.0 (macOS 15.x)
- **Xcode/Swift**: Swift 5.9+
- **Code Signing**: Developer ID Application: Micah Alpern (X2RKZ5TG99)
- **Target**: macOS 13+ (Ventura, Sonoma, Sequoia)
- **Architecture**: arm64 (Apple Silicon)

---

## Logs Available for Review

- **App Log**: `/tmp/helperpoc-app.log` - Shows registration attempts and failures
- **Daemon Log**: `/tmp/helperpoc-daemon.log` - Currently empty (daemon never starts)
- **System Logs**: Attempted to access but command issues prevented detailed review

---

This debug report provides a comprehensive overview of our current state. The core issue appears to be that macOS cannot read our plist file during SMAppService registration, despite the file being present, valid, and properly referenced. Senior developer guidance would be invaluable in determining the root cause and appropriate next steps.