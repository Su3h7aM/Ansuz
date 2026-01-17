#!/usr/bin/env bash

# Test runner script for Ansuz TUI library
# Runs all tests using Odin test runner

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if ODIN_ROOT is set
if [ -z "$ODIN_ROOT" ]; then
    echo -e "${YELLOW}Warning: ODIN_ROOT environment variable is not set${NC}"
    echo "Attempting to use system Odin installation..."
fi

# Run tests
echo "Running Ansuz test suite..."
echo ""

# Build and run tests
echo "Running Ansuz test suite..."
echo ""

# Run tests
if odin test ansuz -file 2>&1; then
    echo ""
    echo "All tests passed!"
    exit 0
else
    echo ""
    echo "Tests failed"
    exit 1
fi
