# Keypath Minimal Product — Implementation Plan

## Background
Keypath Recorder is a lean macOS utility that lets a user remap a key (or short key‑sequence) **without touching config files**.  
Workflow:  
1. User clicks **Start**, presses a physical key (captured as raw scan‑code).  
2. User types the desired output sequence.  
3. App rewrites `keypath.json`, exports to Kanata `.kbd`, helper reloads: behaviour changes instantly.

## Objective
Ship a notarised DMG that allows “A → F” remap in under 60 s, with no manual editing, by **15 Aug 2025**.

---

## One‑Story‑Point Tasks (sequential)

1. **Repo & CI** – Create GitHub repo; enable Actions with `echo Hello`.
2. **Cargo workspace** – Add `keypath_core` (lib) and `keypath_cli` (bin).
3. **IR structs** – Implement `IR`, `Key`, `Action` in Rust.
4. **Generate JSON‑Schema** – Use `schemars`; commit `ir_schema.json`.
5. **`parse_ir()` validator** – Deserialise + schema‑check.
6. **`to_pretty_json()`** – Deterministic serializer.
7. **Sample fixtures** – `samples/simple.json`, `samples/dual.json`.
8. **CLI scaffold** – Clap `--help` compiles.
9. **`validate` command** – Prints ✅ or errors.
10. **`pretty` command** – Rewrites file in place.
11. **Exporter stub** – `export_kanata()` returns `(deflayer base)`.
12. **Tap/hold mapping** – Real Kanata layer output + unit test.
13. **Macros & conditions** – Extend exporter + tests.
14. **SwiftUI project** – Xcode “KeypathRecorder” blank window.
15. **Raw CGEvent tap** – Capture first scan‑code; display label.
16. **Input label UI** – Show “Captured: A (0x00)”.
17. **NSEvent output capture** – Collect output sequence, end on Return.
18. **Suspend remap flag** – Helper bypasses remap during capture.
19. **Rust bridge** – Link `keypath_core` via SwiftPM.
20. **Merge rule in IR** – Overwrite or append, prettify, save.
21. **Run CLI export** – Write `.kbd` into watched folder.
22. **Helper reload** – Restart Kanata, confirm remap works.
23. **Error alerts** – Validation/export failures bubble up.
24. **Notarised DMG** – Codesign, Hardened runtime, notarise.
25. **README + GIF demo** – Document usage for testers.

---

## Done Criteria
* Press‑map‑save loop changes keyboard state in \< 1 s.
* All tasks checked off in GitHub Project board.
* CI green on macOS, Linux, Windows.
* DMG downloadable and notarised.

