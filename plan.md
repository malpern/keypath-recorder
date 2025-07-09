# Keypath Minimal Product — Implementation Plan

## Background
Keypath Recorder is a lean macOS utility that lets a user remap a key (or short key‑sequence) **without touching config files**.  
Workflow:  
1. User clicks **Start**, presses a physical key (captured as raw scan‑code).  
2. User types the desired output sequence.  
3. App generates `.kbd` file with instructions for manual Kanata launch.

## Objective
Ship a notarised DMG that allows "A → F" remap creation in under 60 s, with no manual config editing, by **15 Aug 2025**.

---

## Status: Fully Functional MVP Complete! 🎉

### COMPLETED Tasks (1-26)

#### Sequential Track (Core Development) ✅
1. ✅ **Repo & CI** – GitHub repo with Actions enabled
2. ✅ **Cargo workspace** – `keypath_core` (lib) and `keypath_cli` (bin)
3. ✅ **IR structs** – `IR`, `Key`, `Action` with serde + schemars
4. ✅ **Generate JSON‑Schema** – Schema generation with `schemars`
5. ✅ **`parse_ir()` validator** – JSON deserialisation + validation
6. ✅ **Core unit tests** – 27 Rust tests covering all functionality
7. ✅ **`to_pretty_json()`** – Deterministic pretty-print serializer
8. ✅ **Sample fixtures** – `samples/simple.json`, `samples/complex.json`
9. ✅ **CLI scaffold** – Clap CLI with help and subcommands
10. ✅ **`validate` command** – JSON validation with error reporting
11. ✅ **`pretty` command** – In-place JSON prettification
12. ✅ **Exporter stub** – `export_kanata()` with proper Kanata syntax
13. ✅ **Tap/hold mapping** – Full Kanata layer output with tests
14. ✅ **Macros & conditions** – Complete exporter with all features
15. ✅ **Integration tests** – End-to-end IR → Kanata pipeline testing

#### Parallel Track (UI Development) ✅
16. ✅ **SwiftUI project** – Functional macOS app with Package.swift
17. ✅ **Raw CGEvent tap** – Keyboard capture with scan-code detection
18. ✅ **Input label UI** – "Captured: A (0x00)" format display
19. ✅ **SwiftUI TextField output** – Simple, reliable text input

#### Convergence & File Management ✅
20. ✅ **Rust-C bridge interface** – FFI bridge for Swift-Rust interop
21. ✅ **Swift calls Rust** – Complete data conversion pipeline
22. ✅ **Export integration** – UI calls Kanata export functions
23. ✅ **File I/O** – Save IR JSON and .kbd files with timestamps
24. ✅ **File management UI** – Directory picker, save location display
25. ✅ **Manual launch workflow** – Save files + show sudo instructions

#### Critical Bug Fixes & Polish ✅
26. ✅ **Terminal parent process issue** – Fixed by launching from .app bundle instead of terminal

**Test Coverage**: 48 comprehensive tests (27 Rust + 21 Swift)

### BREAKTHROUGH: App Bundle Solution
**Major Discovery**: The keyboard capture issues were caused by running the app from terminal (parent process interference).

**Solution**: Launch from Finder using `.app` bundle:
- ✅ **CGEvent tap works perfectly** when launched from Finder
- ✅ **SwiftUI TextField receives input** without interference 
- ✅ **End-to-end workflow functional**: 1→2 key mapping verified working
- ✅ **Proper Kanata syntax**: Fixed `--cfg` flag usage

### REMAINING Tasks (27-32)

#### Known Limitations
- ⚠️ **Kanata conflicts with Karabiner-Elements** (only one can run at a time)
- ⚠️ **Single Kanata instance** (multiple mappings need combined .kbd files)
- ⚠️ **Manual sudo required** (macOS security prevents direct launch)

#### Future Enhancements
27. **Multi-device support** – Device-specific mappings in single config
28. **Mapping combination** – Merge multiple .kbd files into one
29. **Privileged helper tool** – SMJobBless-based solution for auto-launch  
30. **Enhanced error handling** – Better conflict detection and user guidance
31. **Notarised DMG** – Code signing and distribution
32. **Documentation** – User guide with Karabiner conflict warnings

#### Alternative Approaches Under Consideration
- **AppleScript automation** – Use osascript to prompt for sudo
- **Terminal.app integration** – Auto-open Terminal with command
- **Kanata daemon mode** – Run Kanata as persistent service
- **User education** – Clear setup instructions for one-time Kanata setup

---

## Done Criteria
* Press‑map‑save loop changes keyboard state in < 1 s.
* All tasks checked off in GitHub Project board.
* CI green on macOS, Linux, Windows.
* DMG downloadable and notarised.
