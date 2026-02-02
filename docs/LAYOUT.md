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

## Example Usage

```odin
// Create a container
ansuz.layout_begin_container(ctx, {
    direction = .TopToBottom,
    sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
    padding = ansuz.padding_all(1),
    gap = 1,
})

    // Add child items
    ansuz.layout_text(ctx, "Header", ansuz.style(.Default, .Default, {.Bold}))
    
    // Flexible content area
    ansuz.layout_begin_container(ctx, {
        direction = .LeftToRight,
        sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
    })
        // Left sidebar (takes 1 share)
        ansuz.layout_box(ctx, ansuz.default_style(), {
            sizing = {ansuz.sizing_grow(1), ansuz.sizing_grow()},
        })
        ansuz.layout_end_container(ctx)
        
        // Main content (takes 3 shares)
        ansuz.layout_box(ctx, ansuz.default_style(), {
            sizing = {ansuz.sizing_grow(3), ansuz.sizing_grow()},
        })
        ansuz.layout_end_container(ctx)
        
    ansuz.layout_end_container(ctx)

ansuz.layout_end_container(ctx)
```
