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
if odin test ansuz -file; then
    echo ""
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi
