# Testing Guide for Ansuz

## Running Tests

Ansuz uses Odin's native testing framework. All tests are written using the `@(test)` attribute and use the `testing.expect` family of functions for assertions.

### Quick Start

```bash
# Run all tests
./build.sh test

# Or directly with Odin
odin test ansuz -file

# Run specific test
odin test ansuz -file -define:ODIN_TEST_NAMES=ansuz.test_buffer_init_destroy

# Run specific test file
odin test ansuz/buffer_test.odin -file
```

## Test Organization

Tests are organized by module and functionality:

### Test Files

- **buffer_test.odin** (25 tests) - Frame buffer operations
  - Initialization and destruction
  - Cell operations (get, set, write_string)
  - Fill and draw operations
  - Resize functionality
  - Edge cases (out-of-bounds, negative dimensions)

- **colors_test.odin** (56 tests) - Color and style conversions
  - All 17 Color enum values (foreground and background)
  - All 9 StyleFlag values
  - Style sequences and combinations
  - Predefined styles

- **event_test.odin** (110 tests) - Input event parsing and handling
  - Control keys (Ctrl+C, Ctrl+D, Ctrl+Z, ESC, Enter, Tab, Backspace)
  - Printable ASCII characters
  - Escape sequences (arrow keys, Home, End, PageUp/PageDown, Delete/Insert, F1-F4)
  - Event buffer operations (push, pop, clear, has_events)
  - Event type casting and validation

- **layout_test.odin** (24 tests) - Layout system calculations
  - Sizing constructors (fixed, percent, fit, grow)
  - Layout directions (horizontal, vertical)
  - Padding and gap handling
  - Alignment variations
  - Nested containers
  - Edge cases

- **api_test.odin** (18 tests) - High-level API integration
  - API function signatures
  - Context structure verification
  - Predefined styles
  - Error handling flow

- **terminal_test.odin** (27 tests) - Terminal I/O operations
  - ANSI escape sequences
  - Cursor operations
  - Alternate buffer management
  - Function existence verification

- **edge_case_test.odin** (38 tests) - Edge cases and error handling
  - Out-of-bounds access
  - Empty strings and zero-length buffers
  - Negative dimensions
  - Buffer overflow scenarios
  - Unicode characters
  - Error enum values

**Total: 210 tests**

## Writing Tests

### Basic Test Structure

```odin
@(test)
test_feature_name :: proc(t: ^testing.T) {
    // Test code here
    testing.expect(t, condition, "Optional message")
    testing.expect_value(t, actual, expected)
}
```

### Common Testing Patterns

#### Testing Simple Values

```odin
@(test)
test_value_comparison :: proc(t: ^testing.T) {
    value := 42
    testing.expect_value(t, value, 42)
}
```

#### Testing Error Conditions

```odin
@(test)
test_error_handling :: proc(t: ^testing.T) {
    buffer, err := init_buffer(-10, 10, context.allocator)
    testing.expect(t, err == .InvalidDimensions)
}
```

#### Testing with Setup/Teardown

```odin
@(test)
test_with_cleanup :: proc(t: ^testing.T) {
    buffer, _ := init_buffer(10, 10, context.allocator)
    defer destroy_buffer(&buffer)

    // Test code that uses buffer
    set_cell(&buffer, 5, 5, 'X', .Red, .Blue, {})

    // buffer is automatically destroyed
    cell := get_cell(&buffer, 5, 5)
    testing.expect(t, cell.rune == 'X')
}
```

#### Testing Iterations

```odin
@(test)
test_multiple_values :: proc(t: ^testing.T) {
    for i in 0 ..< 10 {
        value := i * 2
        testing.expect(t, value >= 0)
    }
}
```

#### Testing Enum Values

```odin
@(test)
test_all_colors :: proc(t: ^testing.T) {
    for color in Color {
        fg := color_to_ansi_fg(color)
        testing.expect(t, fg >= 30 && fg <= 107)
    }
}
```

## Test Assertions

### `testing.expect`

For boolean conditions:

```odin
testing.expect(t, condition, "Optional message")
```

### `testing.expect_value`

For value comparison:

```odin
testing.expect_value(t, actual, expected)
```

**Note:** In Odin's testing framework, `testing.expect_value` does NOT accept a message parameter. If you need a message, use a separate `testing.expect` call or add a comment.

### Memory Testing

Odin's testing framework automatically enables memory tracking. Tests will log their memory usage if there's a leak or other memory issue:

```
[WARN ] --- <        0B/      400B> <      400B> (    1/    1) :: package.test_name
        +++ bad free        @ 0x7F0000DE3048 [file:line:col]
```

## Best Practices

### 1. Use `defer` for Cleanup

Always use `defer` for cleanup operations to ensure they run even if the test fails:

```odin
buffer, _ := init_buffer(10, 10, context.allocator)
defer destroy_buffer(&buffer)
```

### 2. Test Positive and Negative Cases

Test both that things work correctly and that they fail appropriately:

```odin
// Positive case
testing.expect(t, len(events) > 0, "Should have events")

// Negative case
testing.expect(t, !has_events(&empty_buffer), "Empty buffer should have no events")
```

### 3. Test Edge Cases

Test boundary conditions:

```odin
// Out of bounds
testing.expect(t, get_cell(&buffer, -1, 0) == nil)
testing.expect(t, get_cell(&buffer, 100, 0) == nil)

// At bounds
testing.expect(t, get_cell(&buffer, 0, 0) != nil)
testing.expect(t, get_cell(&buffer, 9, 9) != nil)
```

### 4. Keep Tests Focused

Each test should test one specific thing:

```odin
// Good: Tests only cell initialization
test_cell_default_values :: proc(t: ^testing.T) {
    buffer, _ := init_buffer(10, 10, context.allocator)
    defer destroy_buffer(&buffer)

    cell := get_cell(&buffer, 5, 5)
    testing.expect(t, cell.rune == ' ')
}

// Bad: Tests too many things
test_buffer_all_at_once :: proc(t: ^testing.T) {
    // Tests initialization, write, read, and destroy
    // Hard to debug when it fails
}
```

### 5. Use Descriptive Test Names

Test names should clearly describe what they test:

```odin
// Good
test_buffer_write_string_wraps_at_buffer_boundary :: proc(t: ^testing.T)

// Bad
test_buffer_string :: proc(t: ^testing.T)
```

### 6. Test Error Returns

When functions return errors, verify they're correctly returned:

```odin
buffer, err := init_buffer(0, 10, context.allocator)
testing.expect(t, err == .InvalidDimensions, "Zero width should return InvalidDimensions")
```

### 7. Avoid Testing Implementation Details

Focus on behavior, not implementation:

```odin
// Good: Tests that get_cell returns correct value
test_get_cell_returns_correct_rune :: proc(t: ^testing.T)

// Bad: Tests that get_cell accesses specific array index
test_get_cell_accesses_array_index :: proc(t: ^testing.T)
```

## What Not to Test

### 1. Don't Test Private Implementation Details

Avoid testing internal private functions that aren't part of the public API.

### 2. Don't Test the Testing Framework

Don't write tests that verify the testing framework itself works.

### 3. Don't Test Trivial Code

Don't write tests for simple getters/setters that just return a value without logic.

### 4. Don't Test External Libraries

Don't write tests for functions from `core:`, `core:mem`, etc. - trust those libraries.

## Running Specific Tests

### By Pattern

```bash
# Run all buffer tests
odin test ansuz -file -define:ODIN_TEST_NAMES=ansuz.test_buffer_*
```

### By Name

```bash
# Run specific test
odin test ansuz -file -define:ODIN_TEST_NAMES=ansuz.test_buffer_init_destroy
```

## CI/CD Integration

The `build.sh` script includes a test target:

```bash
./build.sh test
```

This will:
1. Check if ODIN_ROOT is set
2. Run all tests with `odin test ansuz -file`
3. Return appropriate exit code (0 for success, 1 for failure)

For CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run Tests
  run: |
    export ODIN_ROOT=/path/to/odin
    ./build.sh test
```

## Debugging Failed Tests

### View Test Output

```bash
# Run with more verbose output
odin test ansuz -file

# Run only failed tests (from last run)
odin test ansuz -file -define:ODIN_TEST_NAMES=ansuz.test_buffer_write_string_bounds
```

### Common Issues

**Out-of-Bounds Access:**
- Check array indices before accessing
- Use `get_cell_safe()` instead of `get_cell()` for testing boundaries

**Memory Leaks:**
- Ensure all allocations use appropriate allocators
- Use `defer` for cleanup
- Check that dynamic arrays are deleted

**Type Mismatches:**
- Verify enum values are correctly cast
- Check union type casting (type assertions)

## Coverage Goals

Target coverage for Ansuz library:
- **Core modules**: 80%+ code coverage
- **Public APIs**: 100% coverage
- **Critical paths**: Full coverage

Currently covered:
- ✅ All color and style conversions
- ✅ All event parsing logic
- ✅ All buffer operations
- ✅ All layout calculations (basic and edge cases)
- ✅ All high-level API functions
- ✅ Terminal I/O operations

## Adding New Tests

When adding new functionality, follow these steps:

1. **Write tests first** (Test-Driven Development)
   - Create failing tests for the new feature
   - Implement the feature to make tests pass

2. **Follow existing patterns**
   - Use similar naming conventions
   - Follow the structure of existing test files
   - Use appropriate test file (module_name_test.odin)

3. **Test edge cases**
   - What happens with empty input?
   - What happens with maximum values?
   - What happens with invalid input?

4. **Run all tests**
   - Ensure new tests don't break existing functionality
   - Run the full test suite before committing

## Resources

- [Odin Testing Documentation](https://odin-lang.org/docs/testing/)
- [Odin Standard Library - core:testing](https://odin-lang.org/docs/core/testing/)
- [Ansuz README](./README.md) - General project documentation
- [Ansuz AGENTS.md](./AGENTS.md) - Agent instructions and workflows
