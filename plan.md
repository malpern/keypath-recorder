# Keypath Minimal Product — Implementation Plan

## Background
Keypath Recorder is a lean macOS utility that lets a user remap a key (or short key‑sequence) **without touching config files**.  
Workflow:  
1. User clicks **Start**, presses a physical key (captured as raw scan‑code).  
2. User types the desired output sequence.  
3. App rewrites `keypath.json`, exports to Kanata `.kbd`, helper reloads: behaviour changes instantly.

## Objective
Ship a notarised DMG that allows "A → F" remap in under 60 s, with no manual editing, by **15 Aug 2025**.

---

## One‑Story‑Point Tasks

### Parallelization Notes
- **Sequential Track**: Tasks 1-15 (Rust core development)
- **Parallel Track**: Tasks 16-19 (UI development, can start after task 2)
- **Convergence**: Tasks 20+ require both tracks complete

### Sequential Track (Core Development)
1. **Repo & CI** – Create GitHub repo; enable Actions with `echo Hello`.
2. **Cargo workspace** – Add `keypath_core` (lib) and `keypath_cli` (bin).
3. **IR structs** – Implement `IR`, `Key`, `Action` in Rust.
4. **Generate JSON‑Schema** – Use `schemars`; commit `ir_schema.json`.
5. **`parse_ir()` validator** – Deserialise + schema‑check.
6. **Core unit tests** – Test parsing valid/invalid JSON fixtures.
7. **`to_pretty_json()`** – Deterministic serializer.
8. **Sample fixtures** – `samples/simple.json`, `samples/dual.json`.
9. **CLI scaffold** – Clap `--help` compiles.
10. **`validate` command** – Prints ✅ or errors.
11. **`pretty` command** – Rewrites file in place.
12. **Exporter stub** – `export_kanata()` returns `(deflayer base)`.
13. **Tap/hold mapping** – Real Kanata layer output + unit test.
14. **Macros & conditions** – Extend exporter + tests.
15. **Integration tests** – Full IR → Kanata export pipeline tests.

### Parallel Track (UI Development - can start after task 2)
16. **SwiftUI project** – Xcode "KeypathRecorder" blank window.
17. **Raw CGEvent tap** – Capture first scan‑code; display label.
18. **Input label UI** – Show "Captured: A (0x00)".
19. **NSEvent output capture** – Collect output sequence, end on Return.

### Convergence (Requires both tracks)
20. **Suspend remap flag** – Use file flag at `~/.keypath/suspend` for helper communication.
21. **Rust bridge** – Link `keypath_core` via Swift-C interop with C API from Rust.
22. **Bridge tests** – Verify Swift → Rust → Swift data roundtrip.
23. **Merge rule in IR** – Overwrite or append, prettify, save.
24. **Run CLI export** – Write `.kbd` into watched folder.
25. **Helper reload** – Restart Kanata, confirm remap works.
26. **Comprehensive error handling** – Handle permissions, file locks, CGEvent failures, invalid states.
27. **Error alerts** – Surface all failures to UI with recovery hints.
28. **End-to-end tests** – Full capture → save → reload workflow test suite.
29. **Notarised DMG** – Codesign, Hardened runtime, notarise.
30. **README + GIF demo** – Document usage for testers.

---

## Done Criteria
* Press‑map‑save loop changes keyboard state in < 1 s.
* All tasks checked off in GitHub Project board.
* CI green on macOS, Linux, Windows.
* DMG downloadable and notarised.
