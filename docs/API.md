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
```

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
// Import the scoped API
import "ansuz/scoped"
```

### Layout Management

```odin
// Start a complete layout definition (replaces begin_layout/end_layout)
layout :: proc(ctx: ^Context, body: proc(^Context))

// Generic container (replaces begin_element/end_element)
container :: proc(ctx: ^Context, config: LayoutConfig, body: proc(^Context))

// Bordered box container
box :: proc(ctx: ^Context, config: LayoutConfig, box_style: BoxStyle, body: proc(^Context))

// Convenience shortcuts
vstack :: proc(ctx: ^Context, config: LayoutConfig, body: proc(^Context))  // Vertical (TopToBottom)
hstack :: proc(ctx: ^Context, config: LayoutConfig, body: proc(^Context))  // Horizontal (LeftToRight)

// Filled rectangle container
rect :: proc(ctx: ^Context, config: LayoutConfig, char: rune, body: proc(^Context))
```

### Leaf Elements

```odin
// Text element (leaf node)
label :: proc(ctx: ^Context, txt: string, el: Element = {})

// Generic element (leaf node)
element :: proc(ctx: ^Context, el: Element = {})
```

### Interactive Widgets

```odin
// Button - returns true if clicked
widget_button :: proc(ctx: ^Context, lbl: string) -> bool

// Checkbox - returns true if toggled
widget_checkbox :: proc(ctx: ^Context, lbl: string, checked: ^bool) -> bool
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
color256 :: proc(index: u8) -> TerminalColor   // 256-color palette

// Style flags
StyleFlags :: bit_set[StyleFlag]
StyleFlag :: enum { Bold, Dim, Italic, Underline, Blink, Reverse }
```

## Complete Example

```odin
import ansuz "../ansuz"

main :: proc() {
    ctx, err := ansuz.init()
    if err != .None do return
    defer ansuz.shutdown(ctx)

    ansuz.run(ctx, proc(ctx: ^ansuz.Context) -> bool {
        for event in ansuz.poll_events(ctx) {
            if ansuz.is_quit_key(event) do return false
        }

        ansuz.layout(ctx, proc(ctx: ^ansuz.Context) {
            ansuz.container(ctx, {
                direction = .TopToBottom,
                sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
                padding = ansuz.padding_all(1),
            }, proc(ctx: ^ansuz.Context) {
                ansuz.box(ctx, {
                    style = ansuz.style(.BrightCyan, .Default, {}),
                    sizing = {.X = ansuz.fixed(40), .Y = ansuz.fixed(10)},
                }, .Rounded, proc(ctx: ^ansuz.Context) {
                    ansuz.label(ctx, "Hello, Ansuz!", {})
                    ansuz.label(ctx, "Scoped API is clean!", {})
                })
            })
        })

        return true
    })
}
```

## Important Notes

1. **Callback Limitation**: Odin callbacks do NOT capture variables from the enclosing scope. Use global variables or explicit parameters to share state with callbacks.

2. **Event-Driven Loop**: Use `ansuz.run()` for most applications. Only use manual `begin_frame`/`end_frame` loops if you need continuous rendering (e.g., animations).

3. **Focus System**: Use `widget_button` and `widget_checkbox` for automatic focus management. Tab navigation is handled automatically with `handle_tab_navigation`.
