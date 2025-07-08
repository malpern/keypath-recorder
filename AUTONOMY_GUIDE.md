# Autonomy Guide for Claude

This document outlines what I (Claude) can do autonomously vs. when I need human help.

## 🤖 What I Can Do Autonomously

### Development Tasks
- ✅ **All Rust development** - Write, test, refactor core library and CLI
- ✅ **Swift/SwiftUI code** - Create UI, implement logic (except signing)
- ✅ **Write and run tests** - Unit, integration, and most end-to-end tests
- ✅ **Fix bugs** - Iterate based on test output and CI results
- ✅ **Create documentation** - README, code comments, API docs
- ✅ **Setup CI/CD** - GitHub Actions, test automation
- ✅ **Refactor code** - Improve structure based on patterns
- ✅ **Git operations** - Commit, branch (but not initial push)

### Iteration Capabilities
- 📊 **Read test output** - Parse JSON/XML test results
- 🔍 **Debug failures** - Analyze stack traces and error messages
- 🔄 **Try multiple approaches** - Iterate on solutions
- 📝 **Update plans** - Adjust approach based on results

### Specific Commands I Can Run
```bash
# Rust development
cargo new, cargo build, cargo test, cargo fmt, cargo clippy
cargo run --bin keypath_cli -- [commands]

# Swift development  
swift build, swift test, swift package
xcodebuild (limited - no signing)

# Testing
./test.sh  # Our custom test runner
ajv validate -s schema.json -d data.json

# Git operations
git add, git commit, git status, git diff
git branch, git checkout
```

## 🙋 When I Need Human Help

### Initial Setup
- ❌ **GitHub repo creation** - Need you to create github.com/malpern/keypath-recorder
- ❌ **First push** - Need your credentials for `git push origin master`
- ❌ **GitHub secrets** - Setting up signing keys, tokens

### Apple Development
- ❌ **Developer account** - Certificates, provisioning profiles
- ❌ **Code signing** - Requires your developer identity
- ❌ **Notarization** - Needs Apple ID credentials
- ❌ **Entitlements** - Accessibility, input monitoring permissions

### System Integration
- ❌ **First-time permissions** - macOS will prompt user
- ❌ **Kanata installation** - Need actual binary installed
- ❌ **System-wide testing** - Verifying actual keyboard remapping

### Manual Verification
- ❌ **UI interaction testing** - "Does the button look right?"
- ❌ **CGEvent capture** - "Is it capturing the right scancode?"
- ❌ **Performance feel** - "Does it feel responsive?"

### Release & Distribution
- ❌ **GitHub releases** - Creating release tags
- ❌ **DMG distribution** - Final packaging decisions
- ❌ **User testing** - Getting feedback from real users

## 📋 Handoff Points

Here's when I'll need to stop and ask for help:

1. **After Task 1** - Push to GitHub
2. **After Task 17** - Test CGEvent capture manually  
3. **After Task 19** - Verify UI captures output correctly
4. **After Task 25** - Test with real Kanata installation
5. **After Task 29** - Handle notarization process
6. **After Task 30** - Release and distribution

## 🎯 My Testing Strategy

To work autonomously, I'll:

1. **Run tests frequently** - After every significant change
2. **Parse output** - Use `--json` flags where available
3. **Create fixtures** - Mock external dependencies
4. **Log verbosely** - Add debug output to understand failures
5. **Fail fast** - Stop and analyze on first failure

Example of how I'll iterate:
```bash
# Run test
./test.sh > test_output.log 2>&1

# If it fails, I'll read the log
cat test_output.log

# Make fixes based on errors
# Re-run until green
```

## 🚦 Decision Framework

When I encounter issues, I'll:

1. **Try 3 approaches** before asking for help
2. **Document what I tried** in comments/commits
3. **Ask specific questions** when stuck
4. **Provide context** about what's blocking me

This approach maximizes my autonomy while ensuring I don't waste time on things that require human intervention.