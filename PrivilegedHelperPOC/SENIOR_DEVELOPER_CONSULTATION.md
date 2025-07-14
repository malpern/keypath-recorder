# Senior Developer Consultation: SMAppService Registration Failure

**Date**: July 9, 2025  
**Environment**: macOS 15.x (Darwin 25.0.0)  
**Objective**: Implement functional privileged helper using SMAppService API  
**Status**: Complete implementation blocked by persistent registration error

---

## What We're Trying to Accomplish

We're building a proof-of-concept privileged helper for the KeypathRecorder project that can:

1. **Register a privileged daemon** using the modern SMAppService API (replacing legacy SMJobBless)
2. **Execute root-level operations** like creating files in protected directories
3. **Communicate via XPC** between the main app and privileged helper
4. **Work reliably** on modern macOS versions (13+) with proper code signing

This is critical for KeypathRecorder's core functionality - the ability to record system-wide keystrokes and mouse events requires elevated privileges that can only be obtained through a properly registered privileged helper.

---

## Complete Technical Implementation

### Architecture ✅
- **Bundle Structure**: Correct `Contents/Library/LaunchDaemons/` location
- **XPC Protocol**: Defined secure protocol with client validation
- **Code Signing**: Properly signed with Developer ID Application certificate
- **Notarization**: Fully notarized and stapled (Apple approved)
- **Entitlements**: Appropriate entitlements for both app and helper

### Current File Structure ✅
```
build/HelperPOCApp.app/
├── Contents/
│   ├── Info.plist                    # Contains SMPrivilegedExecutables
│   ├── MacOS/
│   │   └── HelperPOCApp              # Signed main app
│   └── Library/
│       └── LaunchDaemons/
│           ├── HelperPOCDaemon       # Signed helper (identifier: com.keypath.helperpoc)
│           └── com.keypath.helperpoc.plist  # Launch daemon plist
```

### Code Signing Verification ✅
```bash
$ codesign --verify --verbose build/HelperPOCApp.app
build/HelperPOCApp.app: valid on disk
build/HelperPOCApp.app: satisfies its Designated Requirement

$ codesign -dvvv build/HelperPOCApp.app/Contents/Library/LaunchDaemons/HelperPOCDaemon
Authority=Developer ID Application: Micah Alpern (X2RKZ5TG99)
TeamIdentifier=X2RKZ5TG99
```

### SMPrivilegedExecutables Configuration ✅
```xml
<key>SMPrivilegedExecutables</key>
<dict>
    <key>com.keypath.helperpoc</key>
    <string>identifier "com.keypath.helperpoc" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "X2RKZ5TG99"</string>
</dict>
```

### Helper Daemon Plist ✅
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.keypath.helperpoc</string>
    <key>BundleProgram</key>
    <string>Contents/Library/LaunchDaemons/HelperPOCDaemon</string>
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

## Everything We've Attempted

### 1. Plist Format Variations (All Failed)
- **`Program` key**: Used absolute paths per legacy documentation
- **`ProgramArguments` array**: Modern array-based format
- **`BundleProgram` key**: Apple's current recommended format for SMAppService

### 2. Code Signing Approaches (All Successful)
- **Basic Developer ID signing**: Both app and helper properly signed
- **Explicit identifier setting**: `--identifier "com.keypath.helperpoc"`
- **Entitlements files**: Created separate entitlements for app and helper
- **Full notarization**: Submitted to Apple, approved, and stapled

### 3. Bundle Structure Validation (Confirmed Correct)
- **Apple documentation compliance**: Using `Contents/Library/LaunchDaemons/`
- **Plist location**: Correctly placed in LaunchDaemons directory
- **Executable location**: Helper daemon in same directory as plist
- **Identifier consistency**: Matching identifiers across all files

### 4. Security Requirements Testing (All Valid)
- **Code signature validation**: Manual verification with `codesign --verify`
- **Requirement string testing**: Validated SMPrivilegedExecutables requirement
- **Team ID verification**: Confirmed X2RKZ5TG99 in all certificates

### 5. System Conflict Resolution (None Found)
- **Existing services check**: No conflicting keypath services in system
- **Previous registration cleanup**: No stale registrations found
- **Fresh app builds**: Complete rebuilds with clean slate

---

## Persistent Problem

### Error Details
```
[ERROR] [APP] Helper registration failed: The operation couldn't be completed. Unable to read plist: com.keypath.helperpoc
```

### When This Occurs
- **Immediate failure**: Error occurs instantly when calling `SMAppService.daemon(plistName: "com.keypath.helperpoc").register()`
- **No system dialog**: No authorization prompt appears
- **Consistent across attempts**: Same error regardless of plist format or signing approach
- **Status remains unchanged**: Helper status stays at `SMAppServiceStatus(rawValue: 3)` = "Not found"

### What We've Verified ✅
- Plist file exists at correct location
- Plist syntax is valid (`plutil -lint` passes)
- All code signatures verify successfully
- Helper identifier matches plist label
- SMPrivilegedExecutables entry matches helper identifier
- Requirement string validates against actual helper signature
- App is fully notarized and stapled

---

## Research Findings

### SMAppService Documentation Review
- **Apple's migration guidance**: "Replace the Program key with the BundleProgram key and make the path relative to the bundle"
- **Bundle-based architecture**: Launch daemons stay within app bundle (not copied to system directories)
- **Code signing requirements**: Proper Developer ID signing should be sufficient for local testing

### Known Issues in Other macOS Versions
- **Ventura 13.0.1/13.1**: Code signature errors (-67054) with plist loading
- **Sonoma 14.4**: Registration failures with certain configurations
- **Version-specific bugs**: Pattern of SMAppService issues varying by macOS release

### Error Pattern Analysis
The "Unable to read plist" error typically indicates:
1. **Code signature mismatch**: Helper signature doesn't match SMPrivilegedExecutables requirement
2. **Plist format issues**: Incorrect plist structure or key usage
3. **Bundle location problems**: Plist not found at expected location

We've systematically eliminated all three possibilities through our testing.

---

## Critical Questions for Senior Developer

### 1. macOS 15 Compatibility
**Q**: Are there known issues with SMAppService registration on macOS 15.x (Darwin 25.0.0)?  
**Context**: We're developing on a beta/pre-release system. Could there be undocumented changes or bugs?

### 2. Plist Format Requirements
**Q**: Is the `BundleProgram` key definitively correct for privileged daemons in SMAppService?  
**Context**: Apple's documentation mentions this for agents, but privileged daemons might have different requirements.

### 3. Code Signature Validation
**Q**: How can we debug the actual code signature validation that SMAppService performs?  
**Context**: Our manual validation passes, but SMAppService might be checking something different.

### 4. System Requirements
**Q**: Are there additional system permissions or configurations required for SMAppService on modern macOS?  
**Context**: No TCC prompts appear, but there might be hidden requirements.

### 5. Alternative Debugging Approaches
**Q**: What's the most effective way to debug SMAppService registration failures with verbose system logging?  
**Context**: Standard `log show` commands haven't provided useful details.

### 6. Notarization Impact
**Q**: Could there be notarization-related requirements we're missing for privileged helpers?  
**Context**: App is notarized, but maybe there are specific requirements for the helper executable.

### 7. Development Workflow
**Q**: Should we be testing this on a different macOS version first to isolate potential beta OS issues?  
**Context**: Is there a recommended development approach for privileged helpers?

### 8. Bundle Identifier Conflicts
**Q**: Could there be system-level conflicts with our bundle identifier that aren't visible through standard commands?  
**Context**: The error suggests the system can't "read" our plist specifically.

---

## Next Steps Pending Guidance

### Immediate Actions
1. **Await senior developer input** before attempting more complex solutions
2. **Gather additional system information** if requested
3. **Test on macOS 14** if recommended to isolate beta OS issues

### Potential Solutions to Explore
1. **Alternative plist formats** based on senior developer recommendations
2. **Different code signing approaches** if current method has issues
3. **Legacy SMJobBless fallback** if SMAppService proves unreliable on macOS 15
4. **System permission debugging** if there are hidden requirements

---

## Technical Environment Details

- **macOS Version**: Darwin 25.0.0 (macOS 15.x beta)
- **Development Tools**: Xcode Command Line Tools, Swift 5.9+
- **Code Signing**: Developer ID Application: Micah Alpern (X2RKZ5TG99)
- **Target Compatibility**: macOS 13+ (Ventura, Sonoma, Sequoia)
- **Architecture**: arm64 (Apple Silicon)
- **Notarization Status**: Approved and stapled

---

## Available Resources

### Logs for Analysis
- **App Activity Log**: `/tmp/helperpoc-app.log` - Shows all registration attempts and failures
- **Daemon Log**: `/tmp/helperpoc-daemon.log` - Currently empty (daemon never starts)
- **System Logs**: Can provide detailed ServiceManagement logs if needed

### Code Repository
- **Complete implementation**: All source code, build scripts, and configuration files ready for review
- **Automated testing**: Scripts for building, signing, and testing the complete workflow
- **Documentation**: Comprehensive debug reports and implementation notes

---

**Summary**: We have a complete, properly implemented privileged helper that meets all documented requirements but fails at the SMAppService registration step with a generic "Unable to read plist" error. This appears to be either a macOS 15 beta issue or an undocumented requirement we're missing. Senior developer guidance would be invaluable in determining the root cause and appropriate resolution.