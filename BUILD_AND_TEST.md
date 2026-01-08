# Build and Test Instructions

## Prerequisites

You need the Odin compiler installed to build and test the Ansuz library.

### Installing Odin

#### Linux (Ubuntu/Debian)
```bash
# Clone Odin repository
git clone https://github.com/odin-lang/Odin.git
cd Odin

# Build the compiler
make

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH=$PATH:$PWD/odin
```

#### macOS
```bash
# Using Homebrew
brew install odin-lang

# Or build from source (same as Linux)
git clone https://github.com/odin-lang/Odin.git
cd Odin
make
export PATH=$PATH:$PWD/odin
```

## Building Examples

### Using the build script
```bash
./build.sh
```

This will:
1. Compile all examples
2. Run all tests
3. Output executables to the `examples/` directory

### Building individual examples
```bash
# Build hello_world example
odin build examples/hello_world.odin -file -out:examples/hello_world

# Build layout_demo example
odin build examples/layout_demo.odin -file -out:examples/layout_demo

# Build render_test example
odin build examples/render_test.odin -file -out:examples/render_test
```

### Build options
- `-file`: Treat input as a single file (needed for single-file examples)
- `-out`: Specify output file path
- `-debug`: Include debug information
- `-opt:none`: No optimizations (for debugging)
- `-opt:speed`: Speed optimizations (for release builds)

## Running Examples

```bash
# Hello World - Basic TUI example
./examples/hello_world

# Layout Demo - Flexbox-style layout system
./examples/layout_demo

# Render Test - Immediate mode rendering demonstration
./examples/render_test
```

Press `Ctrl+C` or `q` to exit any example.

## Running Tests

### Run all tests
```bash
odin test ansuz -file
```

### Run tests with debug info
```bash
odin test ansuz -file -debug
```

### Run tests with verbose output
```bash
odin test ansuz -file -debug -vet
```

### Running specific test files
You can run tests from specific test files:
```bash
# Run buffer tests
odin test ansuz/buffer_test.odin -file

# Run colors tests
odin test ansuz/colors_test.odin -file

# Run event tests
odin test ansuz/event_test.odin -file

# Run layout tests
odin test ansuz/layout_test.odin -file
```

## Test Coverage

The test suite includes:

### Buffer Tests (`buffer_test.odin`)
- Buffer initialization
- Cell manipulation
- String writing
- Rectangle filling
- Box drawing with Unicode characters
- Buffer resizing

### Colors Tests (`colors_test.odin`)
- Color to ANSI code conversion
- Style generation
- Style equality
- Predefined style constants

### Event Tests (`event_test.odin`)
- Event buffer operations
- Event type unions
- Key events
- Resize events
- Quit key detection

### Layout Tests (`layout_test.odin`)
- Basic layout calculations
- Padding and gap handling
- Alignment logic
- Sizing rules (fixed, percent, grow, fit-content)

## Troubleshooting

### "odin: command not found"
The Odin compiler is not in your PATH. Either:
1. Install Odin using the instructions above
2. Add the Odin binary directory to your PATH
3. Use the full path to the Odin binary

### "File not found" errors
Make sure you're running commands from the project root directory where the `ansuz/` and `examples/` directories are located.

### Terminal issues
- Make sure you're running in a proper terminal emulator (not through SSH without PTY)
- Some online terminals may not support all ANSI escape sequences
- If you see garbled output, try running in a different terminal (GNOME Terminal, iTerm2, etc.)

### Compilation errors
If you encounter compilation errors:
1. Ensure you're using the latest version of Odin
2. Check that all files have proper line endings (LF, not CRLF)
3. Verify that imports use the correct relative paths

## Development Workflow

### Typical development cycle
```bash
# 1. Make code changes
vim ansuz/buffer.odin

# 2. Run tests to verify
odin test ansuz -file

# 3. Build and test an example
odin build examples/hello_world.odin -file -out:examples/hello_world
./examples/hello_world

# 4. Run all tests before committing
odin test ansuz -file -debug
```

### Adding new tests
1. Create a new test file: `ansuz/new_feature_test.odin`
2. Write test procedures with `@(test)` attribute
3. Use `testing.expect()` for assertions
4. Run with: `odin test ansuz/new_feature_test.odin -file`

### Creating new examples
1. Create file: `examples/my_example.odin`
2. Import ansuz: `import ansuz "../ansuz"`
3. Initialize context: `ctx, _ := ansuz.init()`
4. Remember to cleanup: `defer ansuz.shutdown(ctx)`
5. Build: `odin build examples/my_example.odin -file -out:examples/my_example`

## Continuous Integration

If you're setting up CI/CD, here's an example GitHub Actions workflow:

```yaml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Odin
        run: |
          git clone https://github.com/odin-lang/Odin.git
          cd Odin
          make
          echo "$PWD/odin" >> $GITHUB_PATH
      - name: Run Tests
        run: odin test ansuz -file
```

## Performance Tips

- Use `-opt:speed` for release builds
- Use `-opt:none` during development for faster compilation
- Disable tests in release builds (add build tags if needed)
- Profile with `-profiler` flag to identify bottlenecks

## Additional Resources

- [Odin Documentation](https://odin-lang.org/docs/)
- [Odin GitHub](https://github.com/odin-lang/Odin)
- [Ansuz README](README.md)
- [Quick Start Guide](QUICK_START.md)
