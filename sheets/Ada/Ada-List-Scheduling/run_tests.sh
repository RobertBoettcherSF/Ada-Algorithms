#!/bin/bash

# Root-level test runner for Ada List Scheduling
# This script runs the tests from the project root directory

echo "=========================================="
echo "  Ada List Scheduling Test Runner"
echo "=========================================="
echo ""

# Simply delegate to the tests directory script
exec tests/run_tests.sh
