#!/bin/bash

# Build script to create proper app bundle structure for SMAppService privileged helper

set -e

echo "Building KeypathRecorder with privileged helper..."

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

echo "App bundle created at: $APP_BUNDLE"
echo ""
echo "To test the privileged helper:"
echo "1. Open $APP_BUNDLE (double-click in Finder)"
echo "2. Go to Helper Settings and register the helper" 
echo "3. Approve in System Settings > General > Login Items"
echo "4. Test the 'Save & Launch' functionality"
echo ""
echo "Note: The helper requires proper code signing in production"