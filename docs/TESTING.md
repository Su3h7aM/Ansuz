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

- **buffer_test.odin** - Frame buffer operations (init/destroy, cell ops, fill/draw, resize, edge cases)
- **colors_test.odin** - Color and style conversions, ANSI sequence generation
- **event_test.odin** - Input parsing, control keys, escape sequences, and event utilities
- **layout_test.odin** - Layout sizing, directions, padding/gap, alignment, nested containers
- **layout_test_wrapping.odin** - Wrapped text sizing and layout behavior
- **api_test.odin** - High-level API integration and context initialization
- **terminal_test.odin** - ANSI escape sequences, cursor ops, alternate buffer handling
- **element_test.odin** - Element API configuration and rendering
- **focus_test.odin** - Focus tracking and navigation helpers
- **edge_case_test.odin** - Bounds checks, empty inputs, Unicode handling, error enums

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
