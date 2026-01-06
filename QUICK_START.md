# Ansuz Quick Start Guide

This guide gets you up and running with Ansuz in minutes.

## Installation

### 1. Install Odin

```bash
# Clone Odin repository
git clone https://github.com/odin-lang/Odin
cd Odin

# Build Odin (requires LLVM)
./build_odin.sh

# Add to PATH
export PATH=$PATH:/path/to/Odin
```

For detailed instructions, see: https://odin-lang.org/docs/install/

### 2. Clone Ansuz

```bash
git clone <ansuz-repo-url>
cd ansuz
```

## Your First TUI App

### Minimal Example

```odin
package main

import ansuz "../ansuz"

main :: proc() {
    ctx, _ := ansuz.init()
    defer ansuz.shutdown(ctx)

    for {
        // Handle input
        for event in ansuz.poll_events(ctx) {
            if ansuz.is_quit_key(event) {
                return
            }
        }

        // Render
        ansuz.begin_frame(ctx)
        ansuz.text(ctx, 5, 5, "Hello, World!", ansuz.STYLE_BOLD)
        ansuz.end_frame(ctx)
    }
}
```

### Build & Run

```bash
odin build main.odin -file -out:myapp
./myapp
```

## Core Pattern

Ansuz follows the **immediate-mode** pattern:

```odin
for !quit {
    // 1. Handle events
    for event in ansuz.poll_events(ctx) {
        // Process input, update state
    }

    // 2. Render UI (declare what should be visible)
    ansuz.begin_frame(ctx)
    
    // Your UI code here - runs every frame
    // UI is a function of your application state
    
    ansuz.end_frame(ctx)
}
```

## Common Operations

### Drawing Text

```odin
// Simple text
ansuz.text(ctx, x, y, "Hello", ansuz.STYLE_NORMAL)

// Colored text
ansuz.text(ctx, x, y, "Error!", ansuz.Style{
    fg_color = .Red,
    bg_color = .Default,
    flags = {.Bold},
})

// Formatted text
import "core:fmt"
text := fmt.tprintf("Count: %d", counter)
ansuz.text(ctx, x, y, text, style)
```

### Drawing Boxes

```odin
// Simple box
ansuz.box(ctx, x, y, width, height, ansuz.Style{
    fg_color = .Cyan,
    bg_color = .Default,
    flags = {},
})

// Filled rectangle
ansuz.rect(ctx, x, y, width, height, ' ', ansuz.Style{
    bg_color = .Blue,
    fg_color = .Default,
    flags = {},
})
```

### Handling Input

```odin
for event in ansuz.poll_events(ctx) {
    switch e in event {
    case ansuz.KeyEvent:
        switch e.key {
        case .Ctrl_C, .Ctrl_D:
            quit = true
        case .Enter:
            submit_input()
        case .Up:
            move_up()
        case .Down:
            move_down()
        case .Char:
            // e.rune contains the character
            handle_char(e.rune)
        }
    }
}
```

### Terminal Size

```odin
width, height := ansuz.get_size(ctx)

// Center text
text := "Hello"
text_x := (width - len(text)) / 2
text_y := height / 2
ansuz.text(ctx, text_x, text_y, text, style)
```

## Predefined Styles

```odin
ansuz.STYLE_NORMAL      // Default styling
ansuz.STYLE_BOLD        // Bold text
ansuz.STYLE_DIM         // Dimmed text
ansuz.STYLE_UNDERLINE   // Underlined text
ansuz.STYLE_ERROR       // Bold red (for errors)
ansuz.STYLE_SUCCESS     // Green (for success messages)
ansuz.STYLE_WARNING     // Yellow (for warnings)
ansuz.STYLE_INFO        // Cyan (for info messages)
```

## Complete Example: Counter App

```odin
package main

import ansuz "../ansuz"
import "core:fmt"

State :: struct {
    counter: int,
    quit:    bool,
}

main :: proc() {
    ctx, err := ansuz.init()
    if err != .None {
        return
    }
    defer ansuz.shutdown(ctx)

    state := State{counter = 0}

    for !state.quit {
        // Handle input
        for event in ansuz.poll_events(ctx) {
            if key, ok := event.(ansuz.KeyEvent); ok {
                switch key.key {
                case .Ctrl_C:
                    state.quit = true
                case .Up:
                    state.counter += 1
                case .Down:
                    state.counter -= 1
                }
            }
        }

        // Render UI
        ansuz.begin_frame(ctx)
        
        width, height := ansuz.get_size(ctx)
        
        // Title
        title := "Counter App"
        ansuz.text(ctx, (width - len(title)) / 2, 3, 
                   title, ansuz.STYLE_BOLD)
        
        // Counter value
        counter_text := fmt.tprintf("Value: %d", state.counter)
        ansuz.text(ctx, (width - len(counter_text)) / 2, 5,
                   counter_text, ansuz.Style{
                       fg_color = .BrightGreen,
                       bg_color = .Default,
                       flags = {.Bold},
                   })
        
        // Instructions
        ansuz.text(ctx, (width - 20) / 2, 7,
                   "Up/Down: Change", ansuz.STYLE_DIM)
        ansuz.text(ctx, (width - 18) / 2, 8,
                   "Ctrl+C: Quit", ansuz.STYLE_DIM)
        
        ansuz.end_frame(ctx)
    }
}
```

## Tips & Best Practices

### 1. Always Clean Up

```odin
ctx, _ := ansuz.init()
defer ansuz.shutdown(ctx)  // Restores terminal automatically
```

### 2. Keep State Separate

```odin
// Good: Application state separate from UI
AppState :: struct {
    counter: int,
    selected: int,
    items: []string,
}

// Bad: Mixing UI and state
// (Don't do this in immediate mode)
```

### 3. Throttle Frame Rate

```odin
import "core:time"

for !quit {
    // ... event handling and rendering ...
    
    time.sleep(16 * time.Millisecond)  // ~60 FPS
}
```

### 4. Handle Terminal Resize

```odin
// Check for resize events (not fully implemented yet)
for event in ansuz.poll_events(ctx) {
    if resize, ok := event.(ansuz.ResizeEvent); ok {
        ansuz.handle_resize(ctx, resize.width, resize.height)
    }
}
```

## Common Patterns

### Status Bar

```odin
width, height := ansuz.get_size(ctx)
status_y := height - 1

// Background
ansuz.rect(ctx, 0, status_y, width, 1, ' ', ansuz.Style{
    bg_color = .Blue,
    fg_color = .White,
    flags = {},
})

// Text
ansuz.text(ctx, 2, status_y, "Status: Ready", ansuz.Style{
    fg_color = .White,
    bg_color = .Blue,
    flags = {.Bold},
})
```

### Centered Dialog

```odin
width, height := ansuz.get_size(ctx)
dialog_w :: 40
dialog_h :: 10
dialog_x := (width - dialog_w) / 2
dialog_y := (height - dialog_h) / 2

// Background
ansuz.rect(ctx, dialog_x, dialog_y, dialog_w, dialog_h, ' ',
           ansuz.Style{bg_color = .Blue, fg_color = .Default, flags = {}})

// Border
ansuz.box(ctx, dialog_x, dialog_y, dialog_w, dialog_h,
          ansuz.Style{fg_color = .Cyan, bg_color = .Blue, flags = {}})

// Title
title := "Dialog"
ansuz.text(ctx, dialog_x + (dialog_w - len(title)) / 2, dialog_y + 1,
           title, ansuz.Style{fg_color = .White, bg_color = .Blue, flags = {.Bold}})
```

### List

```odin
items := []string{"Item 1", "Item 2", "Item 3"}
selected := 0

for item, idx in items {
    style := ansuz.STYLE_NORMAL
    if idx == selected {
        style = ansuz.Style{
            fg_color = .Black,
            bg_color = .White,
            flags = {.Bold},
        }
    }
    ansuz.text(ctx, 5, 5 + idx, item, style)
}
```

## Troubleshooting

### Terminal Not Restored

If your program crashes and leaves the terminal corrupted:

```bash
reset
```

Or:

```bash
stty sane
```

### No Output Visible

- Check that `ansuz.end_frame()` is called
- Verify coordinates are within terminal bounds
- Try clearing the screen manually first

### Input Not Working

- Ensure `ansuz.poll_events()` is called each frame
- Check that terminal is in raw mode (automatic with `init()`)
- Verify event parsing for your key

## Next Steps

- Read [ARCHITECTURE.md](research/ARCHITECTURE.md) for deep dive
- See [examples/hello_world.odin](examples/hello_world.odin) for full example
- Check README.md for complete API reference

## Getting Help

- Read the architectural documentation
- Check inline code comments
- Examine the hello_world example
- Review this quick start guide

---

Happy TUI building with Ansuz! 🎨
