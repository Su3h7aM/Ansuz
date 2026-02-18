# ansuz-buffer

Frame buffer management for terminal applications.

## Overview

`ansuz-buffer` provides a 2D grid (framebuffer) for building terminal UIs. It handles:

- **Cell-based rendering**: Each terminal cell stores character, colors, and style
- **Efficient storage**: Flat array for cache-friendly access
- **Clipping support**: Draw only within specified regions
- **Box drawing**: Unicode box-drawing characters
- **Text rendering**: String writing with word wrapping
- **ANSI output**: Convert buffer to terminal-ready strings

## Usage

```odin
import "ansuz-buffer"
import "ansuz-color"

// Create a buffer
buffer, err := ansuz_buffer.init_buffer(80, 24, context.allocator)
if err != .None {
    // Handle error
}
defer ansuz_buffer.destroy_buffer(&buffer)

// Clear and setup
ansuz_buffer.clear_buffer(&buffer)

// Write text
ansuz_buffer.write_string(&buffer, 0, 0, "Hello, World!", 
    ansuz_color.Ansi.Red, ansuz_color.Ansi.Default, {})

// Draw a box
ansuz_buffer.draw_box(&buffer, 5, 5, 20, 10,
    ansuz_color.Ansi.Green, ansuz_color.Ansi.Default, {}, .Rounded)

// Fill a rectangle
ansuz_buffer.fill_rect(&buffer, 10, 10, 5, 3, 'X',
    ansuz_color.Ansi.Blue, ansuz_color.Ansi.Default, {.Bold})

// Render to string with ANSI codes
builder := strings.builder_make(context.temp_allocator)
output := ansuz_buffer.render_to_string(&buffer, &builder)
fmt.print(output)

// Resize while preserving content
ansuz_buffer.resize_buffer(&buffer, 100, 30)
```

## Types

- `FrameBuffer`: 2D grid of cells with width, height, and clipping
- `Cell`: Single terminal cell with rune, fg, bg, and style
- `Rect`: Rectangle with x, y, w, h
- `BoxStyle`: Sharp, Rounded, or Double line styles

## Drawing Operations

- `write_string()` - Write text at position
- `write_string_wrapped()` - Write with automatic word wrapping
- `draw_box()` - Draw Unicode box borders
- `fill_rect()` - Fill region with character
- `set_cell()` / `get_cell()` - Direct cell access
- `set_clip_rect()` / `clear_clip_rect()` - Clipping control

## Rendering

The `render_to_string()` function converts the buffer to a terminal-ready string:
- Uses absolute cursor positioning (prevents scrollback)
- Generates minimal ANSI sequences (only on style change)
- Resets style at end

## Dependencies

- `ansuz-color` - For TerminalColor, Style, and ANSI generation
- `core:strings` - For string building
- `core:unicode/utf8` - For grapheme width calculation

## Integration

This package is typically used by higher-level packages like `ansuz-layout` and
`ansuz-core` to render UI elements to the terminal.
