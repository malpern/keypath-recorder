#!/bin/bash

# Notarization script for KeypathRecorder
# Run this after setting up credentials with setup_notarization.sh

set -e

PROFILE_NAME="KeypathRecorder"
APP_BUNDLE="build/KeypathRecorder.app"
ZIP_FILE="build/KeypathRecorder.zip"

echo "Starting notarization process for KeypathRecorder"
echo "==============================================="

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found at $APP_BUNDLE"
    echo "Please run './build_app_bundle.sh' first"
    exit 1
fi

# Verify the app is properly signed
echo "Verifying code signature..."
codesign --verify --deep --strict "$APP_BUNDLE"
if [ $? -eq 0 ]; then
    echo "✅ Code signature is valid"
else
    echo "❌ Code signature verification failed"
    exit 1
fi

# Create zip file for notarization
echo "Creating zip file for notarization..."
rm -f "$ZIP_FILE"
cd build
zip -r KeypathRecorder.zip KeypathRecorder.app
cd ..

echo "✅ Created $ZIP_FILE"

# Submit for notarization
echo "Submitting to Apple for notarization..."
echo "This may take a few minutes..."

xcrun notarytool submit "$ZIP_FILE" \
    --keychain-profile "$PROFILE_NAME" \
    --wait

if [ $? -eq 0 ]; then
    echo "✅ Notarization successful!"
    
    # Staple the notarization
    echo "Stapling notarization to app bundle..."
    xcrun stapler staple "$APP_BUNDLE"
    
    if [ $? -eq 0 ]; then
        echo "✅ Notarization stapled successfully"
        
        # Verify notarization
        echo "Verifying notarization..."
        spctl -a -t exec -vv "$APP_BUNDLE"
        
        if [ $? -eq 0 ]; then
            echo "✅ App is properly notarized and ready for distribution"
            echo ""
            echo "You can now test the privileged helper registration!"
            echo "The app should pass all security checks."
        else
            echo "❌ Notarization verification failed"
            exit 1
        fi
    else
        echo "❌ Failed to staple notarization"
        exit 1
    fi
else
    echo "❌ Notarization failed"
    echo "Check the output above for error details"
    exit 1
fi

# Clean up
rm -f "$ZIP_FILE"

echo ""
echo "Notarization complete! Your app is ready for testing."