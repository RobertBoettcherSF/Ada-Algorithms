#!/bin/bash

# Verification script for Bakery Algorithm Test Suite
# This script demonstrates how to run the tests

echo "=========================================="
echo "Bakery Algorithm Test Suite Verification"
echo "=========================================="
echo ""

# Check if gnatmake is available
if ! command -v gnatmake &> /dev/null; then
    echo "ERROR: gnatmake (GNAT Ada compiler) is not installed."
    echo ""
    echo "To install on Ubuntu/Debian:"
    echo "  sudo apt-get install gnat"
    echo ""
    echo "To install on Fedora:"
    echo "  sudo dnf install gcc-gnat"
    echo ""
    echo "To install on macOS (with Homebrew):"
    echo "  brew install gnat"
    echo ""
    exit 1
fi

echo "GNAT Ada compiler found: $(gnatmake --version | head -1)"
echo ""

# Create build directories
echo "Creating build directories..."
mkdir -p obj bin
echo ""

# Build the test suite
echo "Building test suite..."
gnatmake -P tests/bakery_tests.gpr
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed!"
    exit 1
fi
echo "Build successful!"
echo ""

# Run the tests
echo "Running tests..."
echo "=========================================="
./bin/bakery_tests
echo "=========================================="
echo ""

# Clean up
echo "Cleaning up..."
rm -rf obj bin
echo "Done!"
