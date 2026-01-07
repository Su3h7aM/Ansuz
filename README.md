# Ansuz

**A Terminal User Interface (TUI) Library for Odin**

Ansuz is an immediate-mode TUI library inspired by [Clay](https://github.com/nicbarker/clay) and [OpenTUI](https://github.com/neurocyte/opentui), designed specifically for the Odin programming language.

## Features

- **Immediate Mode API** - Simple, declarative UI that's easy to reason about
- **Full Frame Redraw** - Each frame renders completely, simplifying the render logic
- **Raw Terminal Control** - Direct ANSI escape sequence management
- **16-Color Support** - Standard ANSI color palette
- **Text Styling** - Bold, dim, underline, and more
- **Frame Buffering** - Single buffer with clear-and-redraw cycle
- **Cross-Platform** - Unix/Linux support (Windows planned)

## Project Structure

```
ansuz/
├── ansuz/                  # Core library package
│   ├── api.odin           # High-level API
│   ├── terminal.odin      # Terminal I/O and raw mode
│   ├── buffer.odin        # Frame buffer and rendering
│   ├── colors.odin        # Color and style system
│   └── event.odin         # Input event handling
├── examples/
│   └── hello_world.odin   # Basic example
├── research/
│   └── ARCHITECTURE.md    # Technical documentation
└── build.sh               # Build script
```

## Quick Start

### Prerequisites

- [Odin compiler](https://odin-lang.org/) installed and in PATH
- Unix/Linux terminal (macOS, Linux)
- GCC or Clang (for Odin compilation)

### Building

```bash
# Build the hello world example
./build.sh

# Or manually
odin build examples/hello_world.odin -file -out:examples/hello_world
```

### Running

```bash
./examples/hello_world
```

Press `Ctrl+C` to exit.

## Example Usage

```odin
package main

import ansuz "../ansuz"
import "core:fmt"

main :: proc() {
    // Initialize Ansuz context
    ctx, err := ansuz.init()
    if err != .None {
        fmt.eprintln("Failed to initialize:", err)
        return
    }
    defer ansuz.shutdown(ctx)

    quit := false
    
    // Main loop
    for !quit {
        // Handle input
        for event in ansuz.poll_events(ctx) {
            if key, ok := event.(ansuz.KeyEvent); ok {
                if key.key == .Ctrl_C {
                    quit = true
                }
            }
        }

        // Render UI (immediate mode)
        ansuz.begin_frame(ctx)
        
        ansuz.write_text(ctx, 10, 5, "Hello, Ansuz!", 
            ansuz.Style{
                fg_color = .BrightYellow,
                bg_color = .Blue,
                flags = {.Bold},
            })
        
        ansuz.end_frame(ctx)
    }
}
```

## Architecture

Ansuz follows an **immediate-mode** pattern:

1. **begin_frame()** - Clear the back buffer
2. **Declare UI** - Call functions to describe what should be visible
3. **end_frame()** - Diff buffers and output only changes
4. **Handle events** - Process input and update state

Each frame, you declare the entire UI based on your application state. The library handles efficient rendering automatically.

## Core Concepts

### Immediate Mode

Unlike retained-mode GUI frameworks, Ansuz doesn't maintain a widget tree. Instead, you declare what should be visible each frame:

```odin
// Your state
counter := 0

// Each frame, declare UI based on state
ansuz.begin_frame(ctx)
ansuz.write_text(ctx, 10, 5, fmt.tprintf("Count: %d", counter), style)
ansuz.end_frame(ctx)
```

### Frame Buffer

Ansuz maintains two buffers:
- **Back buffer** - Currently being rendered
- **Front buffer** - What's on screen

The library diffs these buffers and only outputs changed cells, minimizing terminal I/O.

### Raw Mode

The terminal is placed in "raw mode" which:
- Disables line buffering (immediate key response)
- Disables echo (no duplicate characters)
- Captures special keys (Ctrl+C, arrows, etc.)
- Gives full control over the terminal

Ansuz automatically restores the terminal on exit.

## API Reference

### Context Management

- `init() -> (^Context, ContextError)` - Initialize Ansuz
- `shutdown(^Context)` - Clean up and restore terminal
- `get_size(^Context) -> (width, height: int)` - Get terminal dimensions

### Frame Lifecycle

- `begin_frame(^Context)` - Start a new frame
- `end_frame(^Context)` - Render and output changes

### Drawing

- `write_text(^Context, x, y, text, Style)` - Draw styled text
- `fill_rect(^Context, x, y, width, height, rune, Style)` - Fill region
- `draw_box(^Context, x, y, width, height, Style)` - Draw bordered box

### Input

- `poll_events(^Context) -> []Event` - Get pending input events

### Colors

```odin
Color :: enum {
    Default, Black, Red, Green, Yellow,
    Blue, Magenta, Cyan, White,
    BrightBlack, BrightRed, BrightGreen, BrightYellow,
    BrightBlue, BrightMagenta, BrightCyan, BrightWhite,
}
```

### Styles

```odin
StyleFlag :: enum {
    Bold, Dim, Italic, Underline,
    Blink, Reverse, Hidden, Strikethrough,
}

Style :: struct {
    fg_color: Color,
    bg_color: Color,
    flags:    StyleFlags, // bit_set[StyleFlag]
}
```

## Documentation

See [research/ARCHITECTURE.md](research/ARCHITECTURE.md) for:
- Detailed technical documentation
- ANSI escape sequence reference
- TUI architecture patterns
- Immediate mode concepts
- Implementation details

## Roadmap

### MVP (Current)
- [x] Terminal raw mode control
- [x] Frame buffer system
- [x] Basic rendering
- [x] Color and style support
- [x] Hello World example

### Phase 2
- [ ] Complete event parsing (arrow keys, function keys)
- [ ] Basic widgets (button, text input)
- [ ] Layout system (containers, alignment)
- [ ] Focus management

### Phase 3
- [ ] Rich widget library (list, table, progress bar)
- [ ] Mouse support
- [ ] 256-color and RGB color modes
- [ ] Windows support

### Phase 4
- [ ] Advanced layout (flexbox-like)
- [ ] Animation support
- [ ] Themes and styling system
- [ ] Documentation and examples

## Contributing

Ansuz is in early development. Contributions are welcome!

Areas where help is needed:
- Windows terminal support
- Complete ANSI sequence parsing
- Widget implementations
- Testing on different terminals
- Documentation improvements

## License

See [LICENSE](LICENSE) for details.

## Credits

Inspired by:
- [Clay](https://github.com/nicbarker/clay) - Immediate mode UI library
- [OpenTUI](https://github.com/neurocyte/opentui) - TUI framework in Zig
- The Odin programming language community

## Resources

- [Odin Language](https://odin-lang.org/)
- [ANSI Escape Codes](https://en.wikipedia.org/wiki/ANSI_escape_code)
- [Immediate Mode GUI](https://caseymuratori.com/blog_0001)

---

**Status**: Early Development / MVP Phase  
**Platform**: Unix/Linux  
**License**: MIT  
