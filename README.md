# Ansuz

**A Terminal User Interface (TUI) Library for Odin**

Ansuz is an immediate-mode TUI library inspired by [Clay](https://github.com/nicbarker/clay) and [OpenTUI](https://github.com/neurocyte/opentui), designed specifically for the Odin programming language.

## Features

- **True Immediate Mode API** - Simple, declarative UI that's easy to reason about
- **Full Frame Rendering** - Complete screen redraw each frame for maximum simplicity
- **Raw Terminal Control** - Direct ANSI escape sequence management
- **16-Color Support** - Standard ANSI color palette
- **Layout System** - Flexible layout engine inspired by Clay (flex-like)
- **Cross-Platform** - Unix/Linux support (Windows planned)

## Quick Start

### Prerequisites
- [Odin compiler](https://odin-lang.org/) (latest)
- Unix/Linux terminal

### Building and Running
This project uses `mise` for task management, but tasks are standard bash scripts that can be run directly.

**Using mise (Recommended):**
```bash
mise run build        # Build all examples
mise run build -- -c  # Clean and build
./bin/hello_world     # Run example
```

**Using Odin directly:**
```bash
odin build examples/hello_world.odin -file -out:bin/hello_world
./bin/hello_world
```

## Documentation

- **[Architecture](docs/ARCHITECTURE.md)** - Technical overview, immediate mode concepts, and ANSI reference.
- **[API Reference](docs/API.md)** - Detailed API documentation for context management, drawing, and input.
- **[Layout System](docs/LAYOUT.md)** - Guide to the flex-box inspired layout engine.
- **[Testing](docs/TESTING.md)** - Testing patterns and guide.
- **[Odin Patterns](docs/ODIN_PATTERNS.md)** - Common idioms used in the codebase.

## Example Usage

```odin
package main

import ansuz "ansuz"
import "core:fmt"

main :: proc() {
    ctx, _ := ansuz.init()
    defer ansuz.shutdown(ctx)

    for !ansuz.should_close(ctx) {
        // Handle events
        for event in ansuz.poll_events(ctx) {
            // ... handle input
        }

        // Render UI
        ansuz.begin_frame(ctx)
        
        ansuz.write_text(ctx, 10, 5, "Hello, Ansuz!", 
            ansuz.Style{fg_color = .BrightYellow, flags = {.Bold}})
        
        ansuz.end_frame(ctx)
    }
}
```

## Current Status

**Status**: Early Development / MVP Phase
**Platform**: Unix/Linux

**Key implemented features:**
- ✅ Core immediate mode architecture
- ✅ Flexible Layout System
- ✅ Basic Drawing (Text, Rects, Boxes)
- ✅ Input Handling (Keys, Resize)

See `AGENTS.md` for internal development workflows and contribution guidelines.

## License

MIT - See [LICENSE](LICENSE) for details.
