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

echo ""
echo "Build complete!"
echo "Executable is located at: $EXECUTABLE_PATH"
