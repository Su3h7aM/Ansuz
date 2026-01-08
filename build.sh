#!/usr/bin/env bash

# Build script for Ansuz TUI Library

set -e

echo "Building Ansuz TUI Library..."

# Build examples
echo "Building hello_world example..."
odin build examples/hello_world.odin -file -out:examples/hello_world -debug

echo "Building layout_demo example..."
odin build examples/layout_demo.odin -file -out:examples/layout_demo -debug

# Run tests
echo ""
echo "Running tests..."
odin test ansuz -file -debug

echo ""
echo "Build complete!"
echo "Run examples:"
echo "  ./examples/hello_world"
echo "  ./examples/layout_demo"
