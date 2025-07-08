#!/bin/bash
# Keypath Recorder Test Runner
# Run this to see all test output and verify current state

set -e  # Exit on first failure

echo "🧪 Keypath Recorder Test Suite"
echo "=============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to run a test section
run_section() {
    local name=$1
    local cmd=$2
    echo -e "${YELLOW}Running: $name${NC}"
    if eval "$cmd"; then
        echo -e "${GREEN}✅ $name passed${NC}\n"
        return 0
    else
        echo -e "${RED}❌ $name failed${NC}\n"
        return 1
    fi
}

# Track failures
FAILED=0

# Rust tests (only if Cargo.toml exists)
if [ -f "Cargo.toml" ]; then
    run_section "Cargo Format Check" "cargo fmt -- --check" || ((FAILED++))
    run_section "Cargo Clippy" "cargo clippy --all-targets --all-features -- -D warnings" || ((FAILED++))
    run_section "Cargo Build" "cargo build --verbose" || ((FAILED++))
    run_section "Cargo Tests" "cargo test --verbose" || ((FAILED++))
else
    echo -e "${YELLOW}⚠️  No Cargo.toml found, skipping Rust tests${NC}\n"
fi

# Schema validation (if schema exists)
if [ -f "ir_schema.json" ] && [ -f "simple.json" ]; then
    if command -v ajv &> /dev/null; then
        run_section "Schema Validation" "ajv validate -s ir_schema.json -d simple.json" || ((FAILED++))
    else
        echo -e "${YELLOW}⚠️  ajv-cli not installed, skipping schema validation${NC}"
        echo "   Install with: npm install -g ajv-cli"
        echo ""
    fi
fi

# Swift tests (only if Package.swift exists in KeypathRecorder)
if [ -f "KeypathRecorder/Package.swift" ]; then
    run_section "Swift Build" "cd KeypathRecorder && swift build" || ((FAILED++))
    run_section "Swift Tests" "cd KeypathRecorder && swift test" || ((FAILED++))
else
    echo -e "${YELLOW}⚠️  No Swift package found, skipping Swift tests${NC}\n"
fi

# CLI tests (only if CLI exists)
if [ -f "target/debug/keypath_cli" ]; then
    run_section "CLI Help" "./target/debug/keypath_cli --help" || ((FAILED++))
    run_section "CLI Validate" "./target/debug/keypath_cli validate simple.json" || ((FAILED++))
else
    echo -e "${YELLOW}⚠️  CLI not built yet, skipping CLI tests${NC}\n"
fi

# Summary
echo "=============================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED test section(s) failed${NC}"
    exit 1
fi