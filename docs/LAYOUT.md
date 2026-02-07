# Ansuz Layout System

The Ansuz layout system is a high-performance, flex-box inspired layout engine designed for TUI (Text User Interface) applications. It roughly follows the principles of the **Clay** layout algorithm, using a 3-pass approach to resolve sizes and positions.

## Core Concepts

### 1. Data-Oriented Design
The layout tree is stored as a flat array of `LayoutNode` structures. This improves cache locality and simplifies memory management (using a simple arena/linear allocator).

### 2. Axis Abstraction
Instead of writing separate logic for Horizontal (`Row`) and Vertical (`Column`) layouts, the engine abstracts dimensions into:
- **Main Axis**: The primary direction of flow (e.g., Width/X for `LeftToRight`).
- **Cross Axis**: The perpendicular direction (e.g., Height/Y for `LeftToRight`).

This reduces code duplication significantly.

### 3. The 3-Pass Algorithm

The layout calculation occurs in three distinct passes:

#### Pass 1: Measure (Bottom-Up)
Calculates the minimum required size for every node based on its content and children.
- **FitContent**: Sum of children's sizes (Main Axis) or Max of children's sizes (Cross Axis).
- **Fixed**: Explicit size provided by configuration.
- **Percent/Grow**: Initialized to 0 (resolved in Pass 2).

#### Pass 2: Resolve (Top-Down)
Distributes available space to flexible elements.
- **Grow**: Children marked as `Grow` divide the remaining space in the parent.
    - Supports **Weighted Grow** (e.g., `Grow(2.0)` gets twice the space of `Grow(1.0)`).
- **Percent**: Resolves percentages against the parent's resolved size.
- **Cross Axis Stretch**: `Grow` on the cross axis implies stretching to fill the parent's width/height.

#### Pass 3: Position (Top-Down)
Calculates the final absolute (X, Y) coordinates.
- Applies **Padding** and **Gap**.
- Handles **Alignment** (Start, Center, End) by distributing free space on the Main Axis and Cross Axis.
- Generates the final `RenderCommand` for each node.

## Sizing Rules

- **Fixed(n)**: Exact size in cells.
- **Percent(n)**: Fraction of parent size (0.0 to 1.0).
- **FitContent**: Shrink-wraps to fit children.
- **Grow(w)**: Expands to fill remaining space, weighted by `w`.

## Scoped API Usage

Ansuz uses a **100% scoped callback API** for layout definition. This eliminates explicit begin/end pairs and makes the UI structure more readable.

### Basic Structure

```odin
ansuz.layout(ctx, proc(ctx: ^ansuz.Context) {
    // Root container
    ansuz.container(ctx, {
        direction = .TopToBottom,
        sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
        padding = ansuz.padding_all(1),
    }, proc(ctx: ^ansuz.Context) {
        // Children go here
        ansuz.label(ctx, "Hello", {})
        ansuz.label(ctx, "World", {})
    })
})
```

### Container Types

**Generic Container:**
```odin
ansuz.container(ctx, {
    direction = .TopToBottom,
    sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
}, proc(ctx: ^ansuz.Context) {
    // Children
})
```

**Bordered Box:**
```odin
ansuz.box(ctx, {
    style = ansuz.style(.BrightCyan, .Default, {}),
    sizing = {.X = ansuz.fixed(40), .Y = ansuz.fixed(10)},
}, .Rounded, proc(ctx: ^ansuz.Context) {
    // Children (automatically padded for border)
})
```

**Vertical Stack:**
```odin
ansuz.vstack(ctx, {
    sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
}, proc(ctx: ^ansuz.Context) {
    // Children stacked vertically
})
```

**Horizontal Stack:**
```odin
ansuz.hstack(ctx, {
    sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
}, proc(ctx: ^ansuz.Context) {
    // Children stacked horizontally
})
```

## Complete Example

```odin
ansuz.layout(ctx, proc(ctx: ^ansuz.Context) {
    // Root container fills screen
    ansuz.container(ctx, {
        direction = .TopToBottom,
        sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
        padding = {1, 1, 1, 1},
        gap = 1,
    }, proc(ctx: ^ansuz.Context) {
        // Header
        ansuz.box(ctx, {
            style = ansuz.style(.BrightBlue, .Default, {.Bold}),
            sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(3)},
        }, .Double, proc(ctx: ^ansuz.Context) {
            ansuz.label(ctx, "My Application", {})
        })

        // Content area with sidebar
        ansuz.hstack(ctx, {
            sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
            gap = 1,
        }, proc(ctx: ^ansuz.Context) {
            // Sidebar (30% width)
            ansuz.container(ctx, {
                sizing = {.X = ansuz.percent(0.3), .Y = ansuz.grow()},
            }, proc(ctx: ^ansuz.Context) {
                ansuz.label(ctx, "Sidebar", {})
            })

            // Main content (70% width)
            ansuz.container(ctx, {
                sizing = {.X = ansuz.percent(0.7), .Y = ansuz.grow()},
            }, proc(ctx: ^ansuz.Context) {
                ansuz.label(ctx, "Main Content", {})
            })
        })

        // Footer
        ansuz.container(ctx, {
            sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)},
        }, proc(ctx: ^ansuz.Context) {
            ansuz.label(ctx, "Press Q to quit", {})
        })
    })
})
```

## Layout Alignment

Containers support both horizontal and vertical alignment:

```odin
ansuz.container(ctx, {
    sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
    alignment = {.Center, .Center},  // Center both axes
}, proc(ctx: ^ansuz.Context) {
    ansuz.label(ctx, "Centered", {})
})
```

Alignment options:
- **Horizontal**: `.Left`, `.Center`, `.Right`
- **Vertical**: `.Top`, `.Center`, `.Bottom`

## Padding and Gap

```odin
ansuz.container(ctx, {
    padding = {1, 1, 2, 2},  // top, right, bottom, left
    gap = 1,                  // Space between children
}, proc(ctx: ^ansuz.Context) {
    // Children
})
```

## Text Wrapping

The layout system supports automatic text wrapping for leaf elements:

```odin
ansuz.container(ctx, {
    sizing = {.X = ansuz.fixed(40), .Y = ansuz.fit()},
}, proc(ctx: ^ansuz.Context) {
    ansuz.label(ctx, long_text, {
        wrap_text = true,  // Enable wrapping
    })
})
```

## Nested Layouts

You can nest containers arbitrarily:

```odin
ansuz.layout(ctx, proc(ctx: ^ansuz.Context) {
    ansuz.container(ctx, {direction = .TopToBottom}, proc(ctx: ^ansuz.Context) {
        ansuz.container(ctx, {direction = .LeftToRight}, proc(ctx: ^ansuz.Context) {
            ansuz.label(ctx, "Left", {})
            ansuz.label(ctx, "Right", {})
        })
        ansuz.container(ctx, {direction = .LeftToRight}, proc(ctx: ^ansuz.Context) {
            ansuz.label(ctx, "A", {})
            ansuz.label(ctx, "B", {})
        })
    })
})
```

## Performance Considerations

1. **3-Pass Algorithm**: The layout is calculated in 3 passes (Measure → Resolve → Position), which is O(n) where n is the number of nodes.

2. **Immediate Mode**: The layout tree is rebuilt every frame. This is acceptable for TUI applications where the element count is typically low (hundreds, not thousands).

3. **Flat Storage**: Layout nodes are stored in a flat array for cache efficiency.

4. **Full Redraw**: The entire screen is redrawn each frame. This is simpler and still performant for typical TUI use cases.

## Important Notes

1. **Callback Limitation**: Odin callbacks do NOT capture variables from the enclosing scope. Use global variables or explicit parameters to share state with callbacks.

2. **Automatic Sizing**: The `box()` container automatically adds padding for the border (1 cell on each side).

3. **Overflow Handling**: By default, content outside container bounds is clipped (`.Hidden` overflow). Use `.Visible` to allow content to overflow.

4. **Scroll Support**: The layout system supports scroll offsets (`scroll_offset: [2]int`), but you must manage scroll state in your application.
