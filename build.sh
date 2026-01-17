#!/usr/bin/env bash

# Build script for Ansuz TUI Library

set -e

# Parse command line arguments
COMMAND=${1:-build}

case $COMMAND in
    build)
        echo "Building Ansuz Hello World example..."
        # Build the hello_world example
        odin build examples/hello_world.odin -file -out:examples/hello_world -debug
        echo "Build complete! Run with: ./examples/hello_world"
        ;;

    test)
        echo "Running test suite..."
        ./test.sh
        ;;

    *)
        echo "Usage: $0 {build|test}"
        echo "  build  - Build examples (default)"
        echo "  test   - Run test suite"
        exit 1
        ;;
esac
