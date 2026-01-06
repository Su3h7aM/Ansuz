# Ansuz TUI Library - Architectural Documentation

## Executive Summary

Ansuz is a Terminal User Interface (TUI) library for the Odin programming language, designed with an immediate-mode API pattern inspired by Clay and architectural concepts from OpenTUI. This document provides comprehensive technical research and architectural design for building a high-performance, developer-friendly TUI library.

## Table of Contents

1. [ANSI Codes & Terminal Rendering](#ansi-codes--terminal-rendering)
2. [TUI Architecture Fundamentals](#tui-architecture-fundamentals)
3. [Immediate Mode Pattern](#immediate-mode-pattern)
4. [OpenTUI Reference Analysis](#opentui-reference-analysis)
5. [Proposed Ansuz Architecture](#proposed-ansuz-architecture)
6. [Implementation Strategy](#implementation-strategy)

---

## 1. ANSI Codes & Terminal Rendering

### 1.1 Introduction to ANSI Escape Sequences

ANSI escape sequences are special character sequences that terminals interpret as commands rather than text to display. They enable control over cursor positioning, text styling, and screen manipulation without requiring a graphical interface.

The basic format is:
```
ESC [ <parameters> <command>
```

Where `ESC` is the escape character (ASCII 27, or `\x1b` in hexadecimal).

### 1.2 Essential ANSI Codes

#### Color Codes

**Foreground Colors (Text Color):**
- `30` - Black
- `31` - Red
- `32` - Green
- `33` - Yellow
- `34` - Blue
- `35` - Magenta
- `36` - Cyan
- `37` - White
- `39` - Default

**Bright Foreground Colors:**
- `90` - Bright Black (Gray)
- `91` - Bright Red
- `92` - Bright Green
- `93` - Bright Yellow
- `94` - Bright Blue
- `95` - Bright Magenta
- `96` - Bright Cyan
- `97` - Bright White

**Background Colors:**
- `40-47` - Standard background colors (same order as foreground)
- `49` - Default background
- `100-107` - Bright background colors

**Example:**
```
\x1b[31m        # Red text
\x1b[42m        # Green background
\x1b[31;42m     # Red text on green background
```

#### Text Attributes

- `0` - Reset/Normal (clears all attributes)
- `1` - Bold or increased intensity
- `2` - Dim or decreased intensity
- `3` - Italic (not widely supported)
- `4` - Underline
- `5` - Slow blink
- `6` - Rapid blink
- `7` - Reverse video (swap foreground/background)
- `8` - Conceal/Hide
- `9` - Crossed-out/Strike-through

**Example:**
```
\x1b[1;31m      # Bold red text
\x1b[4;34m      # Underlined blue text
\x1b[0m         # Reset all attributes
```

#### Cursor Movement

- `\x1b[<n>A` - Move cursor up n lines
- `\x1b[<n>B` - Move cursor down n lines
- `\x1b[<n>C` - Move cursor right n columns
- `\x1b[<n>D` - Move cursor left n columns
- `\x1b[<row>;<col>H` - Move cursor to position (row, col)
- `\x1b[H` - Move cursor to home (1,1)

#### Screen Manipulation

- `\x1b[2J` - Clear entire screen
- `\x1b[1J` - Clear from cursor to beginning of screen
- `\x1b[0J` - Clear from cursor to end of screen
- `\x1b[2K` - Clear entire line
- `\x1b[1K` - Clear from cursor to beginning of line
- `\x1b[0K` - Clear from cursor to end of line

#### Cursor Visibility

- `\x1b[?25h` - Show cursor
- `\x1b[?25l` - Hide cursor

#### Cursor Position Save/Restore

- `\x1b[s` or `\x1b7` - Save cursor position
- `\x1b[u` or `\x1b8` - Restore cursor position

### 1.3 Standard Rendering Pattern

A typical TUI rendering cycle follows this pattern:

1. **Save cursor position** - `\x1b[s`
2. **Clear screen or region** - `\x1b[2J` or selective clearing
3. **Move cursor to target position** - `\x1b[<row>;<col>H`
4. **Write styled text** - Apply colors/styles, then write content
5. **Restore cursor** - `\x1b[u` (if needed)

**Example rendering sequence:**
```odin
// Pseudo-code
write("\x1b[s")              // Save cursor
write("\x1b[2J")             // Clear screen
write("\x1b[H")              // Move to home
write("\x1b[1;31m")          // Bold red
write("Hello, World!")       // Content
write("\x1b[0m")             // Reset styles
write("\x1b[u")              // Restore cursor
```

### 1.4 Raw Mode vs Cooked Mode

#### Cooked Mode (Canonical Mode)
The default terminal mode where:
- Input is line-buffered (requires Enter key)
- Special characters are processed (Ctrl+C, Ctrl+D, etc.)
- Line editing is available (backspace, arrow keys)
- Input echoing is enabled

#### Raw Mode
A mode where:
- Input is available immediately (character-by-character)
- No automatic line editing
- Special characters are passed through as raw data
- No automatic echoing
- Full control over terminal behavior

**Why TUI libraries need raw mode:**
- Immediate response to keypresses
- Capture special keys (arrows, function keys)
- Custom input handling
- Direct control over display

### 1.5 Enabling Raw Mode on Unix/Linux

Raw mode is enabled by modifying terminal attributes using the `termios` API:

**Key functions:**
- `tcgetattr(fd, &old_termios)` - Get current terminal attributes
- `tcsetattr(fd, TCSAFLUSH, &new_termios)` - Set new attributes

**Critical termios flags to modify:**

```c
// Input flags (c_iflag)
termios.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);

// Output flags (c_oflag)  
termios.c_oflag &= ~(OPOST);

// Control flags (c_cflag)
termios.c_cflag |= (CS8);

// Local flags (c_lflag) - Most important
termios.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);

// Read timing
termios.c_cc[VMIN] = 0;   // Non-blocking reads
termios.c_cc[VTIME] = 0;  // No timeout
```

**Flag explanations:**
- `ECHO` - Disable input echoing
- `ICANON` - Disable canonical mode (line buffering)
- `ISIG` - Disable signal generation (Ctrl+C, Ctrl+Z)
- `IEXTEN` - Disable extended input processing
- `IXON` - Disable software flow control (Ctrl+S, Ctrl+Q)
- `ICRNL` - Disable CR to NL translation
- `OPOST` - Disable output processing

---

## 2. TUI Architecture Fundamentals

### 2.1 Core Components

A modern TUI library consists of these essential components:

#### 2.1.1 Render Buffer
A 2D grid structure that represents the terminal screen in memory. Each cell contains:
- Character/rune to display
- Foreground color
- Background color
- Text attributes (bold, underline, etc.)
- Dirty flag (for optimization)

#### 2.1.2 Event Loop
The main application loop that:
1. Captures and processes input events
2. Updates application state
3. Renders UI to buffer
4. Outputs buffer to terminal
5. Repeats

#### 2.1.3 Input Handler
Processes raw terminal input and converts it into structured events:
- Key presses (characters, special keys)
- Mouse events (if supported)
- Terminal resize events
- Focus events

#### 2.1.4 Layout Engine
Calculates widget positions and sizes based on:
- Container constraints
- Content requirements
- Layout rules (flexbox-like, grid, etc.)

#### 2.1.5 Widget System
Reusable UI components:
- Text labels
- Buttons
- Input fields
- Lists
- Panels/containers

### 2.2 Complete Rendering Flow

```
┌─────────────────────────────────────────────────┐
│  Input Events                                   │
│  (keyboard, mouse, resize)                      │
└─────────────┬───────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────┐
│  Event Processing & State Update                │
│  (application logic)                            │
└─────────────┬───────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────┐
│  Layout Phase                                   │
│  • Calculate widget positions                   │
│  • Resolve constraints                          │
│  • Determine sizes                              │
└─────────────┬───────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────┐
│  Rendering Phase                                │
│  • Write widgets to render buffer               │
│  • Apply styles and colors                      │
│  • Mark dirty cells                             │
└─────────────┬───────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────┐
│  Diff & Optimization                            │
│  • Compare with previous frame                  │
│  • Identify changed cells                       │
│  • Generate minimal ANSI sequences              │
└─────────────┬───────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────┐
│  Output to Terminal                             │
│  • Write ANSI escape sequences                  │
│  • Update only changed regions                  │
│  • Flush output buffer                          │
└─────────────────────────────────────────────────┘
```

### 2.3 Dirty Flag Optimization

**Problem:** Redrawing the entire terminal every frame is wasteful.

**Solution:** Track which cells have changed since the last frame.

**Implementation:**
1. Each cell in the buffer has a `dirty` boolean flag
2. During rendering, mark cells as dirty when their content changes
3. During output, only generate ANSI codes for dirty cells
4. After output, clear all dirty flags

**Benefits:**
- Reduced output bandwidth
- Faster rendering
- Less terminal flicker
- Better performance over SSH

**Example optimization:**
```
Frame 1: Render 2000 cells (full screen)
Frame 2: Only 50 cells changed → Render only 50 cells
Savings: 97.5% reduction in output
```

### 2.4 Double Buffering

TUI libraries typically use double buffering:
- **Front buffer:** Currently displayed on screen
- **Back buffer:** Being rendered for next frame

**Process:**
1. Render to back buffer
2. Compare back buffer with front buffer
3. Output only differences
4. Swap buffers (or copy back to front)

This prevents tearing and enables efficient diffing.

### 2.5 Performance Considerations

#### Critical Optimizations:
1. **Minimize ANSI sequences** - Reuse styles when possible
2. **Batch writes** - Buffer output before flushing to terminal
3. **Dirty region tracking** - Only redraw changed areas
4. **String allocation** - Pre-allocate buffers, avoid unnecessary allocations
5. **Event throttling** - Limit render rate (e.g., 60 FPS max)

#### Memory Layout:
- Use contiguous arrays for cell buffers (cache-friendly)
- Pool allocations for temporary rendering data
- Avoid dynamic allocations in hot paths

---

## 3. Immediate Mode Pattern

### 3.1 Concept: UI = f(State)

Immediate mode treats the UI as a pure function of application state:

```
UI = render(state)
```

Every frame, you declare what the UI should look like based on current state. The framework handles the rest.

**Contrast with Retained Mode:**

| Aspect | Immediate Mode | Retained Mode |
|--------|---------------|---------------|
| State | Application owns all state | UI framework owns widget state |
| Each frame | Redeclare entire UI | Update specific widgets |
| Complexity | Low (stateless) | High (synchronization needed) |
| Reactivity | Natural | Requires bindings/observers |

### 3.2 Advantages

#### Simplicity
No widget tree to maintain. No complex state synchronization. The UI code directly reflects application state.

```odin
// Immediate mode - simple and direct
if app.show_dialog {
    dialog("Confirm", "Are you sure?")
}
```

vs.

```odin
// Retained mode - complex state management
if app.show_dialog && !dialog_widget.created {
    dialog_widget = create_dialog("Confirm", "Are you sure?")
    dialog_widget.show()
} else if !app.show_dialog && dialog_widget.visible {
    dialog_widget.hide()
}
```

#### Reactivity
State changes automatically reflect in the UI on next frame. No need for observers, bindings, or update methods.

#### No State Desynchronization
The source of truth is always your application state. UI can't get "out of sync" because it's regenerated each frame.

#### Easy to Reason About
The rendering code is purely declarative. Given the same state, you always get the same UI.

### 3.3 Frame Flow

```
┌──────────────────────────────────────────┐
│ 1. begin_frame()                         │
│    • Clear layout state                  │
│    • Reset widget ID counter             │
│    • Prepare render buffer               │
└────────────────┬─────────────────────────┘
                 ↓
┌──────────────────────────────────────────┐
│ 2. Layout Declarations                   │
│    • Call widget functions               │
│    • Specify layout properties           │
│    • Build layout tree (internal)        │
│                                           │
│    container({.horizontal}) {            │
│        text("Hello")                     │
│        button("Click")                   │
│    }                                     │
└────────────────┬─────────────────────────┘
                 ↓
┌──────────────────────────────────────────┐
│ 3. render()                              │
│    • Solve layout constraints            │
│    • Calculate positions                 │
│    • Rasterize widgets to buffer         │
│    • Generate ANSI output                │
└────────────────┬─────────────────────────┘
                 ↓
┌──────────────────────────────────────────┐
│ 4. handle_input()                        │
│    • Process events                      │
│    • Update application state            │
│    • Detect interactions (clicks, etc.)  │
└────────────────┬─────────────────────────┘
                 ↓
┌──────────────────────────────────────────┐
│ 5. end_frame()                           │
│    • Flush output                        │
│    • Swap buffers                        │
│    • Prepare for next frame              │
└──────────────────────────────────────────┘
```

### 3.4 Comparison with Traditional GUI

**Immediate Mode (Clay-style):**
```odin
main_loop :: proc() {
    for !should_quit {
        begin_frame()
        
        // Declare UI based on current state
        container({.centered}) {
            text("Counter: %d", app.counter)
            if button("Increment") {
                app.counter += 1
            }
        }
        
        render()
        end_frame()
    }
}
```

**Retained Mode (Traditional):**
```odin
setup :: proc() {
    counter_label = create_label("Counter: 0")
    increment_button = create_button("Increment")
    increment_button.on_click = on_increment_clicked
    container.add(counter_label)
    container.add(increment_button)
}

on_increment_clicked :: proc() {
    app.counter += 1
    counter_label.set_text(fmt.tprintf("Counter: %d", app.counter))
}

main_loop :: proc() {
    for !should_quit {
        process_events()
        render() // Framework handles rendering
    }
}
```

The immediate mode version is more declarative and easier to understand.

### 3.5 Clay-Specific Patterns

Clay introduces several powerful patterns:

#### ID Generation
Widgets are identified by their declaration context (source location + index), not explicit IDs.

#### Parent-Child Relationships
Use nested scopes or blocks to declare hierarchy:

```odin
container({}) {
    child1()
    child2()
}
```

#### Return Values for Interaction
Widgets return interaction state:

```odin
if button("Click me").clicked {
    // Handle click
}
```

---

## 4. OpenTUI Reference Analysis

### 4.1 Overview

OpenTUI is a TUI framework written in Zig that provides:
- Terminal abstraction layer
- Event handling system
- Rich styling capabilities
- Widget system
- Layout engine

**Key insight:** While OpenTUI includes JavaScript interop for advanced features, its core rendering and terminal handling are instructive for Ansuz.

### 4.2 OpenTUI Structure

#### Core Components:

**Terminal Backend**
- Abstraction over platform-specific terminal APIs
- Raw mode management
- Input parsing (VT sequences)
- Output buffering

**Buffer System**
- Double-buffered cell grid
- Efficient diffing algorithm
- Attribute compression

**Event System**
- Key events with modifiers
- Mouse events (click, drag, scroll)
- Resize events
- Focus events

**Style System**
- Named colors with palette support
- RGB/256-color modes
- Style attributes (bold, italic, etc.)
- Style inheritance

### 4.3 Rendering Architecture

OpenTUI separates concerns:

1. **Widget Layer** - High-level components
2. **Layout Layer** - Position calculation
3. **Buffer Layer** - Intermediate representation
4. **Terminal Layer** - ANSI output

**Data flow:**
```
Widgets → Layout Tree → Cell Buffer → ANSI Sequences → Terminal
```

### 4.4 Lessons for Ansuz

#### What to Adopt:

1. **Clean separation of concerns**
   - Terminal I/O as its own module
   - Buffer as intermediate representation
   - Widget logic separate from rendering

2. **Efficient diffing**
   - Compare buffers cell-by-cell
   - Generate minimal ANSI output
   - Track cursor position to minimize movement codes

3. **Event abstraction**
   - Parse raw terminal input into structured events
   - Normalize across platforms (Unix, Windows)
   - Support both blocking and non-blocking modes

4. **Flexible styling**
   - Separate color from attributes
   - Allow style inheritance
   - Support both named and RGB colors

#### What to Simplify:

1. **Skip JavaScript interop** - Ansuz is pure Odin
2. **Start with 16 colors** - Expand to 256/RGB later
3. **Defer mouse support** - Focus on keyboard for MVP
4. **Simpler layout** - Box model before flex/grid

### 4.5 Key Algorithms

#### Efficient Diffing Algorithm (from OpenTUI):
```
for each cell in new_buffer:
    if new_buffer[cell] != old_buffer[cell]:
        if cursor_position != cell_position:
            output cursor_move(cell_position)
            update cursor_position
        
        if current_style != cell.style:
            output style_sequence(cell.style)
            update current_style
        
        output cell.char
        cursor_position.x += 1
```

This minimizes output by:
- Only moving cursor when necessary
- Reusing styles across consecutive cells
- Batching writes

---

## 5. Proposed Ansuz Architecture

### 5.1 Directory Structure

```
ansuz/
├── src/
│   ├── core/
│   │   ├── terminal.odin      # Raw mode, ANSI I/O
│   │   ├── buffer.odin        # Frame buffer & cell grid
│   │   ├── event.odin         # Event types & input parsing
│   │   └── platform/
│   │       ├── unix.odin      # Unix/Linux terminal APIs
│   │       └── windows.odin   # Windows console APIs (future)
│   │
│   ├── rendering/
│   │   ├── colors.odin        # Color enums & ANSI codes
│   │   ├── style.odin         # Text attributes
│   │   ├── rasterizer.odin    # Buffer → ANSI conversion
│   │   └── diff.odin          # Buffer diffing algorithm
│   │
│   ├── layout/
│   │   ├── constraint.odin    # Layout constraints
│   │   ├── solver.odin        # Layout calculation
│   │   └── types.odin         # Rect, Size, Position
│   │
│   ├── widgets/
│   │   ├── text.odin          # Text rendering
│   │   ├── container.odin     # Containers/panels
│   │   ├── button.odin        # Interactive button
│   │   ├── input.odin         # Text input field
│   │   └── list.odin          # Scrollable list
│   │
│   ├── api.odin               # Public API surface
│   └── context.odin           # Global context & state
│
├── examples/
│   ├── hello_world.odin       # Basic example
│   ├── counter.odin           # Interactive example
│   └── layout_demo.odin       # Layout showcase
│
├── research/
│   └── ARCHITECTURE.md        # This document
│
└── tests/
    ├── buffer_test.odin
    └── color_test.odin
```

### 5.2 Core Data Structures

#### Cell
Represents a single character cell in the terminal:

```odin
Cell :: struct {
    rune:       rune,        // Character to display (Unicode)
    fg_color:   Color,       // Foreground color
    bg_color:   Color,       // Background color
    style:      StyleFlags,  // Text attributes (bold, etc.)
    dirty:      bool,        // Changed since last frame
}
```

#### FrameBuffer
The 2D grid representing the terminal screen:

```odin
FrameBuffer :: struct {
    width:      int,
    height:     int,
    cells:      []Cell,      // width × height array
    allocator:  mem.Allocator,
}
```

Access pattern: `cells[y * width + x]`

#### LayoutContext
State for immediate mode layout declarations:

```odin
LayoutContext :: struct {
    current_parent:     ^LayoutNode,
    node_stack:         [dynamic]^LayoutNode,
    next_widget_id:     u64,
    
    // For layout solving
    constraints:        Constraint,
    cursor_position:    Position,
}
```

#### WidgetResult
Return value from widget functions:

```odin
WidgetResult :: struct {
    clicked:    bool,
    hovered:    bool,
    focused:    bool,
    rect:       Rect,      // Final position/size
}
```

#### Event
Input events:

```odin
EventType :: enum {
    None,
    Key,
    Resize,
    Mouse,  // Future
}

KeyEvent :: struct {
    key:        Key,
    modifiers:  KeyModifiers,
    rune:       rune,  // For printable characters
}

Event :: union {
    KeyEvent,
    ResizeEvent,
    // MouseEvent (future)
}
```

### 5.3 Immediate Mode API Design

#### Basic Pattern

```odin
import ansuz

main :: proc() {
    ctx := ansuz.init() or_return
    defer ansuz.shutdown(ctx)
    
    app_state := AppState{}
    
    for !app_state.should_quit {
        ansuz.begin_frame(ctx)
        
        // Declare UI
        ui_root(ctx, &app_state)
        
        ansuz.end_frame(ctx)
        
        // Handle events
        for event in ansuz.poll_events(ctx) {
            handle_event(&app_state, event)
        }
    }
}

ui_root :: proc(ctx: ^ansuz.Context, app: ^AppState) {
    ansuz.container(.{
        layout = .Vertical,
        padding = 2,
        bg_color = .Blue,
    }) {
        ansuz.text("Hello, Ansuz!", .{
            fg_color = .Yellow,
            style = .Bold,
        })
        
        if ansuz.button("Increment").clicked {
            app.counter += 1
        }
        
        ansuz.text("Count: %d", app.counter)
    }
}
```

#### Core API Functions

```odin
// Context management
init :: proc() -> (^Context, Error)
shutdown :: proc(ctx: ^Context)

// Frame lifecycle
begin_frame :: proc(ctx: ^Context)
end_frame :: proc(ctx: ^Context)

// Events
poll_events :: proc(ctx: ^Context) -> []Event

// Widgets
text :: proc(fmt_string: string, args: ..any, style: TextStyle = {})
button :: proc(label: string, style: ButtonStyle = {}) -> WidgetResult
container :: proc(style: ContainerStyle, content: proc())
input :: proc(buffer: ^string, style: InputStyle = {}) -> WidgetResult

// Layout
push_layout :: proc(constraints: Constraint)
pop_layout :: proc()
```

### 5.4 Rendering Flow

#### Phase 1: Begin Frame
```odin
begin_frame :: proc(ctx: ^Context) {
    // Clear layout context
    clear(&ctx.layout.node_stack)
    ctx.layout.next_widget_id = 0
    ctx.layout.cursor_position = {0, 0}
    
    // Clear back buffer dirty flags
    for &cell in ctx.back_buffer.cells {
        cell.dirty = false
    }
}
```

#### Phase 2: Layout Declaration
User code calls widget functions, which:
1. Generate unique widget ID
2. Build layout tree (internal)
3. Record constraints
4. Return widget result

#### Phase 3: Layout Solving
```odin
solve_layout :: proc(ctx: ^Context) {
    // Calculate actual positions and sizes
    // Based on constraints and terminal size
    
    root := ctx.layout.root
    available := Rect{0, 0, ctx.width, ctx.height}
    
    layout_node(root, available)
}
```

#### Phase 4: Rasterization
```odin
rasterize :: proc(ctx: ^Context) {
    // Write widgets to back buffer
    for node in ctx.layout.tree {
        rasterize_node(ctx, node, ctx.back_buffer)
    }
}
```

#### Phase 5: Diff & Output
```odin
render_to_terminal :: proc(ctx: ^Context) {
    output: strings.Builder
    
    // Compare back buffer with front buffer
    for y in 0..<ctx.height {
        for x in 0..<ctx.width {
            back_cell := get_cell(ctx.back_buffer, x, y)
            front_cell := get_cell(ctx.front_buffer, x, y)
            
            if !cells_equal(back_cell, front_cell) {
                // Generate ANSI codes
                append_cursor_move(&output, x, y)
                append_style(&output, back_cell.style, back_cell.fg_color, back_cell.bg_color)
                strings.write_rune(&output, back_cell.rune)
            }
        }
    }
    
    // Write to terminal
    write_to_terminal(strings.to_string(output))
    
    // Swap buffers
    ctx.front_buffer, ctx.back_buffer = ctx.back_buffer, ctx.front_buffer
}
```

### 5.5 Terminal Abstraction

```odin
TerminalState :: struct {
    original_termios: os.termios,  // For restoration
    is_raw_mode:      bool,
    width:            int,
    height:           int,
}

enter_raw_mode :: proc(state: ^TerminalState) -> Error {
    // Get current settings
    tcgetattr(os.STDIN_FILENO, &state.original_termios)
    
    // Modify for raw mode
    raw := state.original_termios
    raw.c_lflag &= ~(ECHO | ICANON | ISIG | IEXTEN)
    raw.c_iflag &= ~(IXON | ICRNL | BRKINT | INPCK | ISTRIP)
    raw.c_oflag &= ~(OPOST)
    raw.c_cflag |= CS8
    raw.c_cc[VMIN] = 0
    raw.c_cc[VTIME] = 0
    
    // Apply
    tcsetattr(os.STDIN_FILENO, TCSAFLUSH, &raw)
    
    state.is_raw_mode = true
    return .None
}

leave_raw_mode :: proc(state: ^TerminalState) {
    if state.is_raw_mode {
        tcsetattr(os.STDIN_FILENO, TCSAFLUSH, &state.original_termios)
        state.is_raw_mode = false
    }
}
```

---

## 6. Implementation Strategy

### 6.1 MVP Phase 1: Core Infrastructure

**Goal:** Get basic rendering working

**Deliverables:**
- ✅ Terminal I/O with raw mode
- ✅ Frame buffer with cell grid
- ✅ Basic ANSI code generation
- ✅ Color and style enums
- ✅ Simple render loop

**Example:** Display colored text at specific positions

### 6.2 MVP Phase 2: Immediate Mode API

**Goal:** Implement basic immediate mode pattern

**Deliverables:**
- Context management
- begin_frame/end_frame
- Simple text widget
- Container widget
- Basic layout (vertical stacking)

**Example:** Hello World with nested containers

### 6.3 MVP Phase 3: Interactivity

**Goal:** Handle input and respond to user actions

**Deliverables:**
- Event parsing (keyboard)
- Button widget with click detection
- Input focus system
- Simple event loop

**Example:** Counter app with increment button

### 6.4 Phase 4: Advanced Layout

**Goal:** Sophisticated layout system

**Deliverables:**
- Constraint-based layout solver
- Flexbox-like behavior
- Alignment and spacing
- Responsive sizing

**Example:** Complex dashboard layout

### 6.5 Phase 5: Rich Widgets

**Goal:** Complete widget library

**Deliverables:**
- Text input field
- Scrollable list
- Tabs
- Progress bar
- Table

**Example:** Feature-complete TUI app

### 6.6 Testing Strategy

1. **Unit tests** for core algorithms (buffer, diff, layout solver)
2. **Integration tests** for widget rendering
3. **Manual testing** for terminal compatibility
4. **Example apps** as living documentation

### 6.7 Performance Targets

- **Frame time:** < 16ms (60 FPS)
- **Startup time:** < 100ms
- **Memory:** < 10MB for typical app
- **Output efficiency:** > 90% reduction via diffing

---

## 7. Conclusion

Ansuz aims to bring the simplicity and power of immediate mode UI to terminal applications in Odin. By combining proven patterns from Clay with efficient terminal rendering techniques from OpenTUI, we can create a library that is:

- **Simple** - Immediate mode API is intuitive and direct
- **Efficient** - Smart diffing and optimization minimize overhead
- **Powerful** - Rich layout and widget system for complex UIs
- **Idiomatic** - Feels natural in Odin

The architecture outlined in this document provides a clear roadmap from basic terminal I/O to a full-featured TUI framework. The MVP phase focuses on core functionality, ensuring we have a solid foundation before building advanced features.

Next steps:
1. Implement core terminal I/O and raw mode handling
2. Build frame buffer and basic rendering
3. Create hello world example
4. Iterate on immediate mode API design
5. Expand widget library and layout engine

---

## References

- ANSI Escape Codes: https://en.wikipedia.org/wiki/ANSI_escape_code
- OpenTUI: https://github.com/neurocyte/opentui
- Clay: https://github.com/nicbarker/clay
- Termios manual: https://man7.org/linux/man-pages/man3/termios.3.html
- Immediate Mode GUI: https://caseymuratori.com/blog_0001

---

*Document Version: 1.0*  
*Last Updated: 2024*  
*Author: Ansuz Architecture Team*
