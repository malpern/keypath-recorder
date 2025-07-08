# Keypath Recorder Test Plan

## Overview
This document outlines the testing strategy for Keypath Recorder, with mandatory test gates at each major milestone. All tests must pass before proceeding to the next phase.

## Testing Philosophy
- **Test-Driven Development**: Write tests before implementation where possible
- **CI/CD**: All tests run automatically on every push
- **No Broken Builds**: Main branch must always be green
- **Comprehensive Coverage**: Unit, integration, and end-to-end tests

## Test Checkpoints & Milestones

### Milestone 1: Core IR Implementation (Tasks 1-8)
**Must Pass Before Proceeding:**
- ✅ CI pipeline runs on all platforms
- ✅ Rust project compiles without warnings
- ✅ JSON Schema validates against sample files
- ✅ IR parsing handles valid/invalid inputs correctly
- ✅ Deterministic JSON serialization works

**Test Commands:**
```bash
cargo test
cargo fmt -- --check
cargo clippy -- -D warnings
ajv validate -s ir_schema.json -d simple.json
```

### Milestone 2: CLI Implementation (Tasks 9-11)
**Must Pass Before Proceeding:**
- ✅ CLI help text displays correctly
- ✅ Validate command works with good/bad JSON
- ✅ Pretty command reformats files deterministically
- ✅ Error messages are helpful and actionable

**Test Commands:**
```bash
cargo run --bin keypath_cli -- --help
cargo run --bin keypath_cli -- validate simple.json
cargo run --bin keypath_cli -- pretty simple.json
```

### Milestone 3: Kanata Export (Tasks 12-15)
**Must Pass Before Proceeding:**
- ✅ Basic layer export works
- ✅ Tap/hold mappings export correctly
- ✅ Macros and conditions are handled
- ✅ Integration tests pass for full pipeline

**Test Commands:**
```bash
cargo test export_
cargo run --bin keypath_cli -- export simple.json
diff expected_output.kbd actual_output.kbd
```

### Milestone 4: Swift UI Foundation (Tasks 16-19)
**Must Pass Before Proceeding:**
- ✅ Swift project builds without errors
- ✅ CGEvent capture works (requires manual verification)
- ✅ UI displays captured keys correctly
- ✅ Output sequence capture works

**Test Commands:**
```bash
swift build
swift test
# Manual: Verify key capture shows "A (0x00)"
```

### Milestone 5: Integration (Tasks 20-25)
**Must Pass Before Proceeding:**
- ✅ Rust-Swift bridge passes data correctly
- ✅ File flag communication works
- ✅ IR merge logic handles edge cases
- ✅ Kanata reload triggered successfully

**Test Commands:**
```bash
# Test bridge
swift test BridgeTests

# Test file flag
echo "1" > ~/.keypath/suspend
cargo run --bin keypath_cli -- check-suspend

# Test full flow
./run_integration_test.sh
```

### Milestone 6: Polish & Release (Tasks 26-30)
**Must Pass Before Proceeding:**
- ✅ All error paths handled gracefully
- ✅ End-to-end workflow < 60 seconds
- ✅ DMG is notarized successfully
- ✅ README includes working examples

**Test Commands:**
```bash
# Full end-to-end test
./test_e2e.sh

# Notarization check
xcrun notarytool info <submission-id>

# Performance test
time ./test_remap_performance.sh
```

## Automated Test Visibility

To ensure you can see test output and iterate autonomously:

1. **Local Test Runner**: Create `test.sh` that runs all relevant tests
2. **Verbose Output**: Use `--verbose` flag for detailed results
3. **JSON Output**: Some tests output JSON for parsing
4. **Status Badges**: GitHub Actions provides status for each job

## When Human Help is Needed

**You'll need my help for:**
1. **GitHub Repository Creation**: Initial push and permissions
2. **Apple Developer Signing**: Code signing certificates and notarization credentials
3. **macOS Permissions**: First-time accessibility and input monitoring permissions
4. **Manual UI Testing**: Verifying CGEvent capture and UI interactions
5. **Kanata Installation**: Setting up the actual Kanata helper
6. **Release Process**: Publishing to GitHub releases and distribution

**You can work autonomously on:**
- All Rust development and testing
- GitHub Actions setup and configuration
- Swift/SwiftUI code (except signing)
- Documentation and examples
- Test implementation
- Bug fixes based on CI output

## Test Output Format

All test commands should output in a parseable format:
```bash
# Example test output parser
cargo test --message-format=json | jq '.type'
swift test --parallel --xunit-output tests.xml
```

This allows you to read results and make decisions without human intervention.