#!/bin/bash

# Build script for SSTF Project
# This script compiles and runs the SSTF algorithm, tests, and demo

echo "SSTF Project Build Script"
echo "========================"
echo ""

# Create directories if they don't exist
mkdir -p obj bin

# Function to build and run tests
test() {
    echo "Building and running tests..."
    gprbuild -P tests/test_runner.gpr -j0
    if [ $? -eq 0 ]; then
        echo "Running test suite..."
        ./bin/test_runner
    else
        echo "Test build failed!"
    fi
}

# Function to build and run demo
demo() {
    echo "Building and running demo..."
    gprbuild -P demo/sstf_demo.gpr -j0
    if [ $? -eq 0 ]; then
        echo "Running demo..."
        ./bin/sstf_demo "$@"
    else
        echo "Demo build failed!"
    fi
}

# Function to clean
clean() {
    echo "Cleaning build artifacts..."
    rm -rf obj/ bin/
    echo "Clean completed!"
}

# Function to show help
help() {
    echo "Usage: ./build.sh [command]"
    echo ""
    echo "Commands:"
    echo "  test     - Build and run tests"
    echo "  demo     - Build and run demo"
    echo "  clean    - Clean build artifacts"
    echo "  help     - Show this help"
    echo ""
    echo "Examples:"
    echo "  ./build.sh test"
    echo "  ./build.sh demo"
    echo "  ./build.sh demo interactive"
    echo "  ./build.sh clean"
}

# Main logic
case "$1" in
    test)
        test
        ;;
    demo)
        shift
        demo "$@"
        ;;
    clean)
        clean
        ;;
    help|--help|-h|"")
        help
        ;;
    *)
        echo "Unknown command: $1"
        help
        ;;
esac
