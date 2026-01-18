# Testing Guide for Ansuz

## Running Tests

Ansuz uses Odin's native testing framework. All tests are written using the `@(test)` attribute and use the `testing.expect` family of functions for assertions.

### Quick Start

We use `mise` to manage tasks.

```bash
# Run all tests
mise run test

# Or directly with Odin
odin test ansuz -file
```

### Running Specific Tests

```bash
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

1. **Use `defer` for Cleanup**: Always use `defer` for cleanup operations.
2. **Test Positive and Negative Cases**: Verify success and expected failure modes.
3. **Test Edge Cases**: Out of bounds, zero/empty values, max values.
4. **Keep Tests Focused**: One concept per test.
5. **Use Descriptive Test Names**: Explain what is being tested in the name.
6. **Test Error Returns**: Verify specific error enums are returned.
7. **Avoid Testing Implementation Details**: Test the behavior/API, not the internals.

## Coverage Goals

Target coverage for Ansuz library:
- **Core modules**: 80%+ code coverage
- **Public APIs**: 100% coverage
- **Critical paths**: Full coverage

Currently covered:
- ✅ All color and style conversions
- ✅ All event parsing logic
- ✅ All buffer operations
- ✅ All layout calculations
- ✅ All high-level API functions
- ✅ Terminal I/O operations
