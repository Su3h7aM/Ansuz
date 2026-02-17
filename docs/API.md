# API Reference

Ansuz provides a **scoped callback API** and Clay-style element helpers for immediate-mode TUI development in Odin.

## Scoped Layout API (Primary API)

The scoped API uses callbacks to define UI structure without explicit begin/end calls.

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

        ansuz.layout(ctx, proc(ctx: ^ansuz.Context) {
            ansuz.container(ctx, {
                direction = .TopToBottom,
                sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
                padding = ansuz.padding_all(1),
            }, proc(ctx: ^ansuz.Context) {
                ansuz.box(ctx, {
                    sizing = {.X = ansuz.fixed(40), .Y = ansuz.fixed(10)},
                }, ansuz.style(.BrightCyan, .Default, {}), .Rounded, proc(ctx: ^ansuz.Context) {
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
