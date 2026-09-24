#!/bin/bash

# ============================================================================
# Rate Monotonic Scheduling - Test Runner Script
# ============================================================================
# This script compiles and runs the comprehensive test suite for the
# Rate_Monotonic Ada package.
#
# Usage: ./run_tests.sh
# ============================================================================

echo "=========================================================================="
echo "Rate Monotonic Scheduling - Test Runner"
echo "=========================================================================="
echo ""

# Check if we're in the right directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check for Ada compiler
echo "Checking for Ada compiler..."
if command -v gnatmake &> /dev/null; then
    echo "Found: gnatmake"
    GNATMAKE="gnatmake"
elif command -v gprbuild &> /dev/null; then
    echo "Found: gprbuild"
    GNATMAKE="gprbuild"
else
    echo "ERROR: No Ada compiler found!"
    echo "Please install GNAT (GNU Ada Compiler) or GPRbuild."
    echo ""
    echo "On Ubuntu/Debian: sudo apt-get install gnat gprbuild"
    echo "On Fedora: sudo dnf install gcc-gnat gprbuild"
    exit 1
fi

# Find GNAT library path
GNAT_LIB_PATH=""
if [ -d "/usr/lib/gcc/x86_64-linux-gnu/*/adalib" ]; then
    GNAT_LIB_PATH="$(ls -d /usr/lib/gcc/x86_64-linux-gnu/*/adalib | head -1)"
elif [ -d "/usr/lib/gcc/*/adalib" ]; then
    GNAT_LIB_PATH="$(ls -d /usr/lib/gcc/*/adalib | head -1)"
fi

if [ -n "$GNAT_LIB_PATH" ]; then
    echo "Found GNAT libraries at: $GNAT_LIB_PATH"
    export ADA_OBJECTS_PATH="$GNAT_LIB_PATH"
    export LD_LIBRARY_PATH="$GNAT_LIB_PATH:$LD_LIBRARY_PATH"
fi

echo ""
echo "Creating necessary directories..."
# Create directories if they don't exist
mkdir -p tests/obj
mkdir -p tests/bin
mkdir -p obj

echo "Compiling test suite..."
echo "=========================================================================="

# Compile using gprbuild if available, otherwise gnatmake
if [ "$GNATMAKE" = "gprbuild" ]; then
    cd tests
    gprbuild -P tests.gpr 2>&1 | grep -v "^  " | grep -v "^$" || true
    cd ..
else
    cd tests
    gnatmake -P tests.gpr 2>&1 | grep -v "^  " | grep -v "^$" || true
    cd ..
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo ""
echo "Compilation successful!"
echo ""
echo "Running tests..."
echo "=========================================================================="

# Run the tests
cd tests
if [ -f ./bin/rate_monotonic_tests ]; then
    ./bin/rate_monotonic_tests
    EXIT_CODE=$?
else
    echo "ERROR: Executable not found in ./bin/"
    echo "Trying alternative locations..."
    if [ -f rate_monotonic_tests ]; then
        ./rate_monotonic_tests
        EXIT_CODE=$?
    else
        echo "ERROR: Could not find executable!"
        EXIT_CODE=1
    fi
fi
cd ..

echo ""
echo "=========================================================================="
echo "Tests completed with exit code: $EXIT_CODE"
echo "=========================================================================="

exit $EXIT_CODE
