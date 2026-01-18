# Ansuz

**A Terminal User Interface (TUI) Library for Odin**

Ansuz is an immediate-mode TUI library inspired by [Clay](https://github.com/nicbarker/clay) and [OpenTUI](https://github.com/neurocyte/opentui), designed specifically for the Odin programming language.

## Features

- **True Immediate Mode API** - Simple, declarative UI that's easy to reason about
- **Full Frame Rendering** - Complete screen redraw each frame for maximum simplicity
- **Raw Terminal Control** - Direct ANSI escape sequence management
- **16-Color Support** - Standard ANSI color palette
- **Text Styling** - Bold, dim, underline, and more
- **Single Buffer** - Simplified architecture without diff complexity
- **Cross-Platform** - Unix/Linux support (Windows planned)

## Project Structure

```
ansuz/
├── ansuz/                  # Core library package
│   ├── api.odin           # High-level API
│   ├── terminal.odin      # Terminal I/O and raw mode
│   ├── buffer.odin        # Frame buffer and rendering
│   ├── colors.odin        # Color and style system
│   ├── event.odin         # Input event handling
│   ├── layout.odin        # Layout system (Clay-inspired)
│   └── *_test.odin        # Unit tests
├── examples/
│   ├── hello_world.odin   # Basic example
│   ├── features_demo.odin  # Layout and features demo
│   ├── layout_demo.odin     # Layout system demo
│   ├── complex_demo.odin   # Complex UI demo
│   └── btop_demo.odin      # Dashboard-style demo (in progress)
├── docs/                  # Documentation
│   ├── ARCHITECTURE.md     # Technical documentation
│   ├── API.md             # API reference
│   ├── LAYOUT.md          # Layout system docs
│   ├── TESTING.md          # Testing guide
│   └── ODIN_PATTERNS.md   # Odin patterns used
└── .beads/               # Issue tracking configuration
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

### Testing

```bash
# Run all tests
./build.sh test

# Or run directly with Odin
odin test ansuz -file

# Run specific test
odin test ansuz -file -define:ODIN_TEST_NAMES=ansuz.test_buffer_init_destroy
```

**Test Coverage:**
- **buffer_test.odin**: 25 tests - Frame buffer operations
- **colors_test.odin**: 56 tests - Color and style conversions
- **event_test.odin**: 110 tests - Input event parsing and handling
- **layout_test.odin**: 24 tests - Layout system calculations
- **api_test.odin**: 18 tests - High-level API integration
- **terminal_test.odin**: 27 tests - Terminal I/O operations
- **edge_case_test.odin**: 38 tests - Edge cases and error handling

**Total: 210 tests**

All tests can be run locally and are designed to pass in headless environments where possible.

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

Ansuz follows a **pure immediate-mode** pattern:

1. **begin_frame()** - Clear the buffer
2. **Declare UI** - Call functions to describe what should be visible
3. **end_frame()** - Render entire buffer to terminal
4. **Handle events** - Process input and update state

Each frame, you declare the entire UI based on your application state. The entire screen is re-rendered every frame, making the library extremely simple and predictable.

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

Ansuz maintains a single buffer that represents the terminal screen:
- Each frame starts by clearing the buffer
- Widgets draw into this buffer
- At the end of the frame, the entire buffer is rendered to the terminal

This simple approach makes the code easy to understand and maintain, with performance that's more than adequate for typical TUI applications.

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

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for:
- Detailed technical documentation
- ANSI escape sequence reference
- TUI architecture patterns
- Immediate mode concepts
- Implementation details

See also:
- [docs/LAYOUT.md](docs/LAYOUT.md) - Layout system documentation
- [docs/API.md](docs/API.md) - API reference
- [docs/TESTING.md](docs/TESTING.md) - Testing guide
- [docs/ODIN_PATTERNS.md](docs/ODIN_PATTERNS.md) - Odin patterns used

## Essential Features Roadmap

Based on analysis of modern TUI libraries (Ratatui, Textual, BubbleTea, TUI.zig), here are the essential features yet to be implemented:

### 🟢 High Priority - Core Features

#### 1. Widget Library (Most Critical)
**Basic Interactive Widgets:**
- [ ] `TextInput` - Text field with cursor, editing, password mask
- [ ] `Button` - Clickable with variants (primary/secondary/danger/success)
- [ ] `CheckBox`/`Switch` - Toggle widgets
- [ ] `ListBox`/`ListView` - List with selection and navigation
- [ ] `Select`/`OptionList` - Dropdown options

**Advanced Interactive Widgets:**
- [ ] `ProgressBar`/`Gauge` - Progress indicator (block + line)
- [ ] `Scrollbar` - Interactive visual scrollbar
- [ ] `Tabs`/`TabbedContent` - Tab system
- [ ] `Table` - Table with columns, sorting, selection

#### 2. Mouse Support (Critical for Modern UX)
- [ ] Click events (left/right/middle buttons)
- [ ] Mouse wheel scrolling
- [ ] Hover states
- [ ] Drag and drop (basic)
- [ ] Text selection

#### 3. Focus Management (Essential for Interactivity)
- [ ] Focus system (can_focus, focus, blur)
- [ ] Tab/Shift+Tab navigation
- [ ] Visual focus indicators
- [ ] Focus trap in modals
- [ ] Focus events (gain/loss)

#### 4. Modal/Dialog System
- [ ] Popups and dialogs
- [ ] Backdrop overlay
- [ ] Keyboard blocking in modals
- [ ] Exclusive focus management

#### 5. Virtualization (Performance Critical)
- [ ] Lazy rendering for large lists
- [ ] Virtual scrolling
- [ ] Widget recycling

#### 6. Context Menus & Popups
- [ ] Widget context menus
- [ ] Dropdown menus
- [ ] Command palette

### 🟡 Medium Priority - Important Features

#### 7. Advanced Color System
- [ ] 256-color palette
- [ ] True color (RGB hex)
- [ ] Color gradients
- [ ] Theme system (light/dark)
- [ ] Color variables

#### 8. Clipboard Integration
- [ ] Copy/paste operations
- [ ] Bracketed paste mode
- [ ] Multi-line paste handling

#### 9. Animations
- [ ] Smooth transitions
- [ ] Loading indicators
- [ ] Toast notifications
- [ ] Fade/slide effects

#### 10. Advanced Layout
- [ ] Grid layout
- [ ] Responsive design (breakpoints)
- [ ] Split panes
- [ ] Docking system

#### 11. Advanced Input Handling
- [ ] Command history
- [ ] Autocomplete/suggestions
- [ ] Multi-key bindings
- [ ] Bracketed paste
- [ ] Complete special sequence parsing

#### 12. Tooltips
- [ ] Hover tooltips
- [ ] Rich content support
- [ ] Custom positioning
- [ ] Timer delays

#### 13. Forms & Validation
- [ ] Form widget integration
- [ ] Validation framework
- [ ] Error feedback
- [ ] Auto-save

#### 14. Region Updates (Performance)
- [ ] Partial redraws
- [ ] Optimized dirty tracking
- [ ] Region-based refreshing

#### 15. Unicode & Complex Text
- [ ] Emoji rendering
- [ ] RTL (right-to-left) support
- [ ] Text wrapping/truncation
- [ ] Hyphenation

#### 16. Tree Widget
- [ ] Hierarchical data display
- [ ] Expand/collapse
- [ ] Keyboard/mouse selection

#### 17. Data Display Widgets
- [ ] `Sparkline` - Compact graph
- [ ] `BarChart` - Data visualization
- [ ] `RichLog` - Log with syntax highlighting
- [ ] `Calendar` - Calendar widget

#### 18. File Picker
- [ ] Integrated file browser
- [ ] Directory navigation
- [ ] File preview
- [ ] Bookmarks

### 🟠 Low Priority - Nice-to-Have

#### 19. Windows Platform Support
- [ ] Windows Terminal compatibility
- [ ] Console API
- [ ] ANSI fallbacks

#### 20. DevTools
- [ ] Widget inspector
- [ ] Layout tree visualization
- [ ] Performance profiler
- [ ] Debug overlay

#### 21. Plugin System
- [ ] Widget registry
- [ ] Extension API
- [ ] Middleware hooks

#### 22. Advanced Animation
- [ ] Canvas drawing
- [ ] Shape rendering
- [ ] Sprite animations
- [ ] Keyframe animations

#### 23. Z-Index & Layers
- [ ] Layer stacking
- [ ] Transparency/alpha blending
- [ ] Compositing

#### 24. Testing Utilities
- [ ] Event mocks
- [ ] Snapshot testing
- [ ] Widget test helpers

#### 25. State Management
- [ ] Reactive variables
- [ ] Data binding
- [ ] Persistence
- [ ] Save/restore

### 📊 Current Status

**✅ Already Implemented:**
- Terminal raw mode & ANSI codes
- Frame buffer system
- 16-color + styles (bold, dim, underline, etc.)
- Basic event system (keyboard, resize)
- Advanced layout system (Clay-inspired)
  - Containers (row/column)
  - Sizing (fixed, percent, grow, fit-content)
  - Padding, gap, alignment
  - 3-pass algorithm
- Drawing API (text, box, rect)
- Box styles (sharp, rounded, double)
- FPS tracking
- Basic scrolling with offset

### 🎯 Recommended Implementation Order

**Phase 1 (Core Widgets):**
1. Mouse support (basic)
2. Focus management
3. Button, TextInput, CheckBox, ListBox
4. Modal/Dialog system

**Phase 2 (Advanced Widgets):**
5. ProgressBar, Scrollbar, Tabs, Table
6. Context menus
7. Tooltips
8. Clipboard integration

**Phase 3 (Polish & Performance):**
9. 256-color/RGB colors
10. Theme system
11. Basic animations
12. Virtualization
13. Region updates

**Phase 4 (Platform & Tools):**
14. Windows support
15. DevTools
16. Advanced features (calendar, file picker, etc.)

## Contributing

Ansuz is in early development. Contributions are welcome!

### Version Control

This project uses **jj** (jujutsu) as the version control system instead of git.

```bash
# Clone the repository
jj git clone https://github.com/yourusername/ansuz.git
cd ansuz

# View status
jj status

# View commit history
jj log

# Create a new commit
jj new "your message"

# Amend the current commit
jj squash

# View changes
jj diff

# Push to remote
jj git push
```

### Issue Tracking

This project uses **bd** (beads) for issue tracking.

```bash
# Get started with bd
bd onboard

# Find available work
bd ready

# View issue details
bd show <id>

# Claim work
bd update <id> --status in_progress

# Complete work
bd close <id>

# Sync with jj
bd sync
```

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
