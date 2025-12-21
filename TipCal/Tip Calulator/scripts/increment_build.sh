#!/bin/bash

# Auto-increment build number script
# Add this as a Build Phase in Xcode

# Get the current build number
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")

# Increment it
BUILD_NUMBER=$((BUILD_NUMBER + 1))

# Write it back
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "${PROJECT_DIR}/${INFOPLIST_FILE}"

echo "Build number incremented to $BUILD_NUMBER"

