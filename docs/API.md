# API Reference

Ansuz provides a **scoped layout API** for immediate-mode TUI development in Odin.

## Scoped Layout API (Primary API)

The scoped API uses Odin's `@(deferred_in_out)` attribute to automatically close containers when the scope exits.

```odin
// Import scoped API (automatically included in ansuz package)
import ansuz "ansuz"
```

### Layout Management

```odin
// Start a complete layout pass for the screen
// Usage: if ansuz.layout(ctx) { ... }
layout :: proc(ctx: ^Context) -> bool

// Generic container with children
// Usage: if ansuz.container(ctx, config) { ... }
container :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) -> bool

// Bordered box container
// Usage: if ansuz.box(ctx, config, style, box_style) { ... }
box :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG, style: Style = {}, box_style: BoxStyle = .Sharp) -> bool

// Convenience shortcuts
// Usage: if ansuz.vstack(ctx, config) { ... }  // Vertical (TopToBottom)
vstack :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) -> bool
// Usage: if ansuz.hstack(ctx, config) { ... }  // Horizontal (LeftToRight)
hstack :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) -> bool

// Overlay stacking container (children stack on top of each other)
// Usage: if ansuz.zstack(ctx, config) { ... }
zstack :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) -> bool

// Filled rectangle container
// Usage: if ansuz.rect(ctx, config, style, char) { ... }
rect :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG, style: Style = {}, char: rune = ' ') -> bool

// Flexible space filler (grows to fill remaining space)
// Usage: ansuz.spacer(ctx, config)
spacer :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG)
```

### Leaf Elements

```odin
// Text element (leaf node)
// Usage: ansuz.label(ctx, "text")
label :: proc(ctx: ^Context, txt: string)

// Generic element (leaf node)
// Usage: ansuz.element(ctx, Element{...})
element :: proc(ctx: ^Context, el: Element)
```

### Interactive Widgets

```odin
// Button - returns true if clicked
// Usage: if ansuz.widget_button(ctx, "label") { ... }
widget_button :: proc(ctx: ^Context, lbl: string) -> bool

// Checkbox - returns true if toggled
// Usage: checked := true; if ansuz.widget_checkbox(ctx, "label", &checked) { ... }
widget_checkbox :: proc(ctx: ^Context, lbl: string, checked: ^bool) -> bool

// Input - returns true if value was modified this frame
// Usage: value := ""; cursor := 0; if ansuz.widget_input(ctx, "id", &value, &cursor, "placeholder") { ... }
widget_input :: proc(ctx: ^Context, lbl: string, value: ^string, cursor_pos: ^int, placeholder: string = "") -> bool

// Select dropdown - returns true if selection changed
// Usage: selected := 0; is_open := false; options := []string{"A", "B", "C"}; if ansuz.widget_select(ctx, "id", options, &selected, &is_open) { ... }
widget_select :: proc(ctx: ^Context, lbl: string, options: []string, selected_idx: ^int, is_open: ^bool) -> bool
```

#### Input Widget

The input widget provides text entry with full keyboard navigation:

- **Typing**: Any printable character is inserted at cursor position
- **Backspace**: Deletes character before cursor
- **Delete**: Deletes character at cursor
- **Left/Right Arrows**: Move cursor one character
- **Home**: Move cursor to start of text
- **End**: Move cursor to end of text
- **Placeholder**: Shown when value is empty

**State Management**: The caller manages both the `value` string and `cursor_pos`. The widget modifies these directly based on keyboard input.

**Memory Management**: The widget clones strings to persistent memory (ctx.allocator) so they survive across frames. The caller is responsible for freeing the string memory when no longer needed using `delete(value, ctx.allocator)`. Note that string literals like `""` should not be freed.

#### Select Widget

The select widget provides a dropdown menu for choosing from a list:

- **Closed State**: Shows the currently selected option
- **Open State (Enter/Space)**: Shows all options with the current one highlighted
- **Navigation (Up/Down)**: Move selection within the dropdown
- **Confirm (Enter)**: Select the highlighted option and close
- **Cancel (Escape)**: Close without changing selection

**State Management**: The caller manages both `selected_idx` (current selection) and `is_open` (dropdown visibility). The widget modifies these based on interaction.

Both widgets support focus-based styling from the theme system and integrate with Tab navigation.

## Layout Configuration

```odin
LayoutConfig :: struct {
    direction: LayoutDirection,      // .LeftToRight, .TopToBottom, .ZStack
    sizing: [Axis]Sizing,            // Size constraints for X and Y
    padding: Padding,                // Internal spacing
    gap: int,                        // Space between children
    alignment: Alignment,            // Positioning
    overflow: Overflow,              // .Hidden, .Visible, .Scroll
    scroll_offset: [2]int,           // x, y scroll position
    wrap_text: bool,                 // Enable text wrapping
    min_width: int,                   // Minimum width constraint
    min_height: int,                  // Minimum height constraint
    max_width: int,                   // Maximum width constraint (0 = no max)
    max_height: int,                  // Maximum height constraint (0 = no max)
}

// Sizing helpers
fixed :: proc(value: int) -> Sizing       // Exact size
grow :: proc(weight: f32 = 1.0) -> Sizing  // Fill remaining space
fit :: proc() -> Sizing                    // Shrink to content
percent :: proc(value: f32) -> Sizing     // Percentage of parent (0.0-1.0)

// Padding helpers
padding_all :: proc(value: int) -> Padding
```

## Context Management

```odin
import ansuz "ansuz"
```

### Layout Management

```odin
// Start a complete layout definition (replaces begin_layout/end_layout)
layout :: proc(ctx: ^Context, body: proc(^Context))

// Generic container (replaces begin_element/end_element)
container :: proc(ctx: ^Context, config: LayoutConfig, body: proc(^Context))

// Bordered box container
box :: proc(ctx: ^Context, config: LayoutConfig, style: Style, box_style: BoxStyle, body: proc(^Context))

// Convenience shortcuts
vstack :: proc(ctx: ^Context, config: LayoutConfig, body: proc(^Context))  // Vertical (TopToBottom)
hstack :: proc(ctx: ^Context, config: LayoutConfig, body: proc(^Context))  // Horizontal (LeftToRight)

// Filled rectangle container
rect :: proc(ctx: ^Context, config: LayoutConfig, style: Style, char: rune, body: proc(^Context))
```

### Leaf Elements

```odin
// Text element (leaf node)
label :: proc(ctx: ^Context, txt: string, el: Element = {})

// Generic element (leaf node)
element :: proc(ctx: ^Context, el: Element = {})
```

### Element Configuration

```odin
Element :: struct {
    using layout: LayoutConfig
    style:        Style
    box_style:    Maybe(BoxStyle)
    fill_char:    Maybe(rune)
    content:      Maybe(string)
    focusable:    bool
    id_source:    string
}

element_default :: proc() -> Element
```

Use `content` for text nodes, `box_style` for bordered elements, and `fill_char` for filled rectangles. Focusable elements should set `focusable = true` and provide `id_source` for stable IDs.

### Interactive Widgets

```odin
// Themed widgets built on the Element API
widget_button :: proc(ctx: ^Context, lbl: string) -> bool
widget_checkbox :: proc(ctx: ^Context, lbl: string, checked: ^bool) -> bool

// Lightweight helpers (no theme lookups)
button :: proc(ctx: ^Context, label_text: string) -> bool
checkbox :: proc(ctx: ^Context, label_str: string, checked: ^bool) -> bool
```

## Layout Configuration

```odin
LayoutConfig :: struct {
    direction: LayoutDirection,      // .LeftToRight or .TopToBottom
    sizing: [Axis]Sizing,            // Size constraints for X and Y
    padding: Padding,                // Internal spacing
    gap: int,                        // Space between children
    alignment: Alignment,            // Positioning
    overflow: Overflow,              // .Hidden, .Visible, .Scroll
    scroll_offset: [2]int,           // x, y scroll position
    wrap_text: bool,                 // Enable text wrapping
}

// Sizing helpers
fixed :: proc(value: int) -> Sizing       // Exact size
grow :: proc(weight: f32 = 1.0) -> Sizing  // Fill remaining space
fit :: proc() -> Sizing                    // Shrink to content
percent :: proc(value: f32) -> Sizing     // Percentage of parent (0.0-1.0)

// Padding helpers
padding_all :: proc(value: int) -> Padding
```

## Context Management

```odin
// Initialize the library
init :: proc(allocator := context.allocator) -> (^Context, ContextError)

// Cleanup resources
shutdown :: proc(ctx: ^Context)

// Frame lifecycle (for manual rendering loops)
begin_frame :: proc(ctx: ^Context)
end_frame :: proc(ctx: ^Context)

// Event-driven main loop (recommended)
run :: proc(ctx: ^Context, update: proc(ctx: ^Context) -> bool)
```

## Input & Events

```odin
// Poll for input events
poll_events :: proc(ctx: ^Context) -> []Event

// Check for quit key (q or Escape)
is_quit_key :: proc(event: Event) -> bool
```

## Focus Management

```odin
// Generate stable ID from string
id :: proc(ctx: ^Context, label: string) -> u64

// Set/get focus
set_focus :: proc(ctx: ^Context, id: u64)
is_focused :: proc(ctx: ^Context, id: u64) -> bool

// Handle Tab navigation
handle_tab_navigation :: proc(ctx: ^Context, reverse: bool) -> bool
```

## Styling

```odin
// Create a style
style :: proc(fg: TerminalColor, bg: TerminalColor, flags: StyleFlags) -> Style

// Color helpers
rgb :: proc(r, g, b: u8) -> TerminalColor      // TrueColor
hex :: proc(value: u32) -> TerminalColor       // 0xRRGGBB
color256 :: proc(index: u8) -> TerminalColor   // 256-color palette
rgb_cube :: proc(r, g, b: u8) -> TerminalColor // 6×6×6 palette cube
grayscale :: proc(level: u8) -> TerminalColor  // 24-step grayscale

// Style flags
StyleFlags :: bit_set[StyleFlag]
StyleFlag :: enum { Bold, Dim, Italic, Underline, Blink, Reverse, Hidden, Strikethrough }
```

## Complete Example

```odin
import ansuz "ansuz"

main :: proc() {
    ctx, err := ansuz.init()
    if err != .None do return
    defer ansuz.shutdown(ctx)

    ansuz.run(ctx, proc(ctx: ^ansuz.Context) -> bool {
        for event in ansuz.poll_events(ctx) {
            if ansuz.is_quit_key(event) do return false
        }

        if ansuz.layout(ctx) {
            if ansuz.container(ctx, {
                direction = .TopToBottom,
                sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
                padding = ansuz.padding_all(1),
            }) {
                if ansuz.box(ctx, {
                    sizing = {.X = ansuz.fixed(40), .Y = ansuz.fixed(10)},
                }, ansuz.style(.BrightCyan, .Default, {}), .Rounded) {
                    ansuz.label(ctx, "Hello, Ansuz!")
                    ansuz.label(ctx, "Scoped API is clean!")
                }
            }
        }

        return true
    })
}
```

## Important Notes

1. **Scoped API**: The `if ansuz.container(ctx) { ... }` pattern allows local variables to be accessed inside blocks. No callback limitations.

2. **Event-Driven Loop**: Use `ansuz.run()` for most applications. Only use manual `begin_frame`/`end_frame` loops if you need continuous rendering (e.g., animations).

3. **Focus System**: Use `widget_button` and `widget_checkbox` for automatic focus management. Tab navigation is handled automatically with `handle_tab_navigation`.
