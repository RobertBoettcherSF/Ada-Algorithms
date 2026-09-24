#!/bin/bash

# Test runner script for Ada List Scheduling
# This script can be run from the tests/ directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "  Ada List Scheduling Test Runner"
echo "=========================================="
echo ""

# Check if gnatmake is available
if ! command -v gnatmake &> /dev/null; then
    echo "ERROR: gnatmake (GNAT Ada compiler) is not installed."
    echo "Please install GNAT Ada compiler to run tests."
    exit 1
fi

# Navigate to project root
cd "$PROJECT_ROOT"

# Check if we're in the right directory
if [ ! -f "list_scheduling.gpr" ]; then
    echo "ERROR: Not in the project root directory."
    echo "Project root: $PROJECT_ROOT"
    exit 1
fi

# Create directories if they don't exist
mkdir -p obj
mkdir -p tests

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf obj/*.o obj/*.ali obj/test_list_scheduling obj/test_list_scheduling.exe
rm -f tests/test_list_scheduling tests/test_list_scheduling.exe

# Compile the project
echo "Compiling List_Scheduling library..."
gnatmake -P list_scheduling.gpr

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed."
    exit 1
fi

echo ""
echo "Compiling test suite..."
cd tests
rm -f test_list_scheduling test_list_scheduling.exe
gnatmake -P ../list_scheduling.gpr test_list_scheduling.adb

if [ $? -ne 0 ]; then
    echo "ERROR: Test compilation failed."
    exit 1
fi

# Check if executable was created in current directory or obj directory
EXEC_FOUND=0
if [ -f "./test_list_scheduling" ]; then
    EXEC_FOUND=1
elif [ -f "./test_list_scheduling.exe" ]; then
    EXEC_FOUND=1
elif [ -f "../obj/test_list_scheduling" ]; then
    cp ../obj/test_list_scheduling ./
    EXEC_FOUND=1
elif [ -f "../obj/test_list_scheduling.exe" ]; then
    cp ../obj/test_list_scheduling.exe ./
    EXEC_FOUND=1
fi

if [ $EXEC_FOUND -eq 0 ]; then
    echo "ERROR: Executable not created. Checking what happened..."
    echo "Current directory: $(pwd)"
    echo "Files in current dir:"
    ls -la | grep test_list
    echo "Files in ../obj:"
    ls -la ../obj/ | grep test_list
    exit 1
fi

echo ""
echo "Running tests..."
echo "=========================================="
echo ""

# Run the tests
if [ -f "./test_list_scheduling" ]; then
    ./test_list_scheduling
elif [ -f "./test_list_scheduling.exe" ]; then
    ./test_list_scheduling.exe
else
    echo "ERROR: test_list_scheduling executable not found!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Test run complete."
echo "=========================================="
