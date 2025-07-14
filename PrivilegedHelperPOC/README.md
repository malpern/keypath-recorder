# SMAppService Privileged Helper POC

## Overview

This proof of concept demonstrates the modern SMAppService API for creating privileged helper tools on macOS 13+. It implements the corrected architecture based on senior developer feedback.

## Key Features Implemented

### ✅ Correct Bundle Structure
- Helper daemon located in `Contents/Library/LaunchDaemons/`
- Plist uses `Program` key (not `BundleProgram`)
- On-demand launch configuration (`RunAtLoad=false`, `KeepAlive=false`)

### ✅ SMAppService Integration
- Registration/unregistration through `SMAppService.daemon()`
- Status monitoring (enabled, requiresApproval, notRegistered)
- User approval workflow via System Settings

### ✅ XPC Communication
- Secure XPC listener with client validation
- Proper error handling and connection management
- Async/await pattern for Swift concurrency

### ✅ Privileged Operations
- Helper runs with root privileges
- Test operations: file creation with root ownership
- Process information reporting (UID, EUID, PID)

## Architecture

```
HelperPOCApp.app/
├── Contents/
│   ├── MacOS/
│   │   └── HelperPOCApp              # Main SwiftUI app
│   ├── Library/
│   │   └── LaunchDaemons/            # SMAppService required location
│   │       ├── HelperPOCDaemon       # Privileged helper daemon
│   │       └── com.keypath.helperpoc.plist
│   └── Info.plist
```

## Testing Results

### Build Status: ✅ SUCCESS
- Swift package builds without errors
- App bundle created with correct structure
- Helper daemon compiles and links properly

### Expected Workflow
1. Launch app → Shows "Helper not registered"
2. Click "Register Helper" → SMAppService registration
3. System prompts for approval → User approves in System Settings
4. Helper status → "Enabled"
5. Click "Test Helper" → Privileged operations execute
6. Verify root file creation in `/tmp/`

## Implementation Notes

### Security Simplifications (POC Only)
- Client validation uses simplified PID check
- Production requires full code signature validation
- No certificate/team ID validation in POC mode

### Key Differences from Legacy SMJobBless
- No separate authorization dialog
- User approval via System Settings only
- Simplified plist configuration
- Native XPC integration

## Next Steps for KeypathRecorder Integration

### Phase 2: Integration Tasks
1. **Update existing KeypathRecorder project structure**
   - Add `Contents/Library/LaunchDaemons/` to build phases
   - Create proper Info.plist with helper references

2. **Implement production XPC security**
   - Add full code signature validation
   - Replace simplified PID check with audit token validation
   - Set correct team ID and bundle identifier

3. **Add Kanata-specific operations**
   - Extend `HelperProtocol` with Kanata launch/stop methods
   - Implement process lifecycle management
   - Add path validation and error handling

4. **UI Integration**
   - Add helper management to existing ContentView
   - Status indicators for helper state
   - User guidance for approval process

### Estimated Timeline
- **Phase 2 Integration**: 2-3 days
- **Production Hardening**: 1-2 days
- **Testing & Polish**: 1 day

## Files Created

### Source Code
- `Sources/HelperPOCApp/` - Main SwiftUI application
- `Sources/HelperPOCDaemon/` - Privileged helper daemon
- `Package.swift` - Swift package configuration

### Build System
- `build_and_test.sh` - Build script with app bundle creation
- `com.keypath.helperpoc.plist` - Launch daemon configuration

### Documentation
- `README.md` - This documentation

## Key Success Factors

1. **Bundle Structure**: Correct LaunchDaemons location is critical
2. **Plist Configuration**: `Program` key and on-demand settings
3. **XPC Security**: Client validation prevents unauthorized access
4. **User Experience**: Clear guidance for System Settings approval

This POC validates the technical approach and provides a foundation for KeypathRecorder integration.