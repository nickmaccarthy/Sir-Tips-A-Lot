#!/bin/bash
# Build and install Tip Calculator to connected iPhone
# Use this if Xcode IDE has issues

set -e

DEVICE_ID="00008150-001C395614C0401C"
PROJECT_DIR="$(dirname "$0")"

cd "$PROJECT_DIR"

echo "🔨 Building Tip Calculator..."
xcodebuild -project "Tip Calculator.xcodeproj" \
    -scheme "Tip Calculator" \
    -destination 'generic/platform=iOS' \
    -configuration Debug \
    -allowProvisioningUpdates \
    build

# Find the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/Tip_Calculator*/Build/Products/Debug-iphoneos -name "Tip Calculator.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Build failed - app not found"
    exit 1
fi

echo "📱 Installing to device..."
xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

echo "🚀 Launching app..."
xcrun devicectl device process launch --device "$DEVICE_ID" nmac.Tip-Calculator

echo "✅ Done!"
