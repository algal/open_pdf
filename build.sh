#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Cleaning the build cache..."
swift package clean

echo "Building the 'open_pdf' executable..."

# Build the release version. The linker flags are now in Package.swift.
swift build -c release

# Define the source and destination paths
EXECUTABLE_PATH="./.build/release/open_pdf"
BUNDLE_PATH="./.build/release/open_pdf.app"
CONTENTS_PATH="$BUNDLE_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"

echo "Creating app bundle structure..."
mkdir -p "$MACOS_PATH"

echo "Copying executable to app bundle..."
cp "$EXECUTABLE_PATH" "$MACOS_PATH/open_pdf"

echo "Copying Info.plist to app bundle..."
cp "Info.plist" "$CONTENTS_PATH/Info.plist"

echo "Code signing the executable..."
# Sign with entitlements for development
codesign --force --options=runtime --entitlements open_pdf.entitlements --sign "-" "$MACOS_PATH/open_pdf"

echo "Code signing the app bundle..."
codesign --force --options=runtime --entitlements open_pdf.entitlements --sign "-" "$BUNDLE_PATH"

echo ""
echo "Build complete!"
echo "Executable is located at: $EXECUTABLE_PATH"
echo "App bundle is located at: $BUNDLE_PATH"
echo "You can run the tool with: $MACOS_PATH/open_pdf"
