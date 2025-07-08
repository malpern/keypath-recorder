# Keypath Recorder macOS App

A SwiftUI application for recording keyboard mappings.

## Building

```bash
swift build
```

## Running

```bash
swift run
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9 or later
- Accessibility permissions (will be requested on first run)

## Architecture

- `KeypathRecorderApp.swift` - Main app entry point
- `ContentView.swift` - Main UI view
- `Info.plist` - App permissions and metadata

## Features (In Progress)

- [ ] CGEvent tap for keyboard capture
- [ ] Scan code detection
- [ ] Output sequence recording
- [ ] Integration with keypath_core