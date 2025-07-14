#!/bin/bash

# Build script to create proper app bundle structure for SMAppService privileged helper

set -e

echo "Building KeypathRecorder with privileged helper..."

# Code signing identity
DEVELOPER_ID="Developer ID Application: Micah Alpern (X2RKZ5TG99)"

# Build both executables
swift build --product KeypathRecorder
swift build --product KanataHelper

# Create app bundle structure
APP_BUNDLE="build/KeypathRecorder.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
LAUNCHDAEMONS_DIR="$CONTENTS_DIR/Library/LaunchDaemons"

echo "Creating app bundle structure..."
mkdir -p "$MACOS_DIR"
mkdir -p "$LAUNCHDAEMONS_DIR"

# Copy main executable
cp .build/debug/KeypathRecorder "$MACOS_DIR/KeypathRecorder"

# Copy helper executable
cp .build/debug/KanataHelper "$MACOS_DIR/KanataHelper"

# Copy launch daemon plist
cp Resources/com.keypath.kanata.helper.plist "$LAUNCHDAEMONS_DIR/"

# Create basic Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.keypath.KeypathRecorder</string>
    <key>CFBundleName</key>
    <string>KeypathRecorder</string>
    <key>CFBundleDisplayName</key>
    <string>KeypathRecorder</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>KeypathRecorder</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
EOF

# Make executables executable
chmod +x "$MACOS_DIR/KeypathRecorder"
chmod +x "$MACOS_DIR/KanataHelper"

echo "Code signing executables and dependencies..."

# Sign the Rust library first (required for linking)
RUST_LIB_PATH="../target/debug/libkeypath_core.dylib"
RUST_LIB_DEPS_PATH="../target/debug/deps/libkeypath_core.dylib"

if [ -f "$RUST_LIB_PATH" ]; then
    echo "Signing main Rust library..."
    codesign --force --sign "$DEVELOPER_ID" \
        --options runtime \
        "$RUST_LIB_PATH"
fi

if [ -f "$RUST_LIB_DEPS_PATH" ]; then
    echo "Signing deps Rust library..."
    codesign --force --sign "$DEVELOPER_ID" \
        --options runtime \
        "$RUST_LIB_DEPS_PATH"
fi

# Sign the helper executable first (with helper entitlements)
codesign --force --sign "$DEVELOPER_ID" \
    --entitlements "Resources/KanataHelper.entitlements" \
    --options runtime \
    "$MACOS_DIR/KanataHelper"

# Sign the main executable (with main app entitlements)
codesign --force --sign "$DEVELOPER_ID" \
    --entitlements "Resources/KeypathRecorder.entitlements" \
    --options runtime \
    "$MACOS_DIR/KeypathRecorder"

# Sign the entire app bundle
codesign --force --sign "$DEVELOPER_ID" \
    --entitlements "Resources/KeypathRecorder.entitlements" \
    --options runtime \
    "$APP_BUNDLE"

echo "Verifying code signatures..."
codesign --verify --deep --strict "$APP_BUNDLE"
codesign --display --verbose=2 "$APP_BUNDLE"

echo "App bundle created and signed at: $APP_BUNDLE"
echo ""
echo "To test the privileged helper:"
echo "1. Open $APP_BUNDLE (double-click in Finder)"
echo "2. Go to Helper Settings and register the helper" 
echo "3. Approve in System Settings > General > Login Items"
echo "4. Test the 'Save & Launch' functionality"
echo ""
echo "Note: The helper is now properly code signed for development"