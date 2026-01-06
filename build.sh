#!/usr/bin/env bash

# Build script for Ansuz TUI Library

set -e

echo "Building Ansuz Hello World example..."

# Build the hello_world example
odin build examples/hello_world.odin -file -out:examples/hello_world -debug

echo "Build complete! Run with: ./examples/hello_world"
