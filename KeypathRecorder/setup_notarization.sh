#!/bin/bash

# Setup script for notarization credentials
# This script will help you configure notarization for KeypathRecorder

echo "Setting up notarization for KeypathRecorder"
echo "==========================================="
echo ""

APPLE_ID="malpern@me.com"
TEAM_ID="X2RKZ5TG99"
PROFILE_NAME="KeypathRecorder"

echo "You need to create an app-specific password for notarization:"
echo "1. Go to https://appleid.apple.com/account/manage"
echo "2. Sign in with your Apple ID: $APPLE_ID"
echo "3. Go to 'App-Specific Passwords' section"
echo "4. Click 'Generate Password'"
echo "5. Enter a label like 'KeypathRecorder Notarization'"
echo "6. Copy the generated password"
echo ""
echo "Once you have the app-specific password, run:"
echo "xcrun notarytool store-credentials \"$PROFILE_NAME\" \\"
echo "    --apple-id \"$APPLE_ID\" \\"
echo "    --team-id \"$TEAM_ID\" \\"
echo "    --password \"YOUR_APP_SPECIFIC_PASSWORD\""
echo ""
echo "This will store the credentials securely in your keychain."
echo ""
echo "After setting up credentials, you can notarize with:"
echo "./notarize_app.sh"