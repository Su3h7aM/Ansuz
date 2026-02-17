# TUI Library Comparison: Ansuz vs Ratatui vs Charm

This document compares how to implement a simple interface (a centered rounded box with text) using three different libraries: **Ansuz** (Odin), **Ratatui** (Rust), and **Charm/Bubbletea** (Go).

## 1. Ansuz (Our Library - Odin)

Ansuz uses an **Immediate Mode** approach with a flexible layout system. Positioning is done declaratively in the render call using the scoped API.

### Code
```odin
// Inside the render loop or update function
if ansuz.layout(ctx) {
    if ansuz.container(ctx, {
        direction = .TopToBottom,
        sizing = {.X = ansuz.grow(), .Y = ansuz.grow()}, // Fill entire screen
        alignment = {.horizontal = .Center, .vertical = .Center}, // Center children
    }) {
        // Rounded box container
        if ansuz.box(ctx, {
            sizing = {.X = ansuz.fixed(40), .Y = ansuz.fixed(10)},
            alignment = {.horizontal = .Center, .vertical = .Center}, // Center text inside box
        }, ansuz.style(.White, .Default, {}), .Rounded) {
            ansuz.label(ctx, "Hello Ansuz!", ansuz.style(.BrightYellow, .Default, {.Bold}))
        }
    }
}
```

### Features
- **Paradigm**: Immediate Mode with scoped blocks.
- **Layout**: Flexbox-inspired (`sizing`, `alignment`, `direction`).
- **Borders**: Container property (`.Rounded`), styling via `Style` parameter.
- **Centering**: Done via `alignment` property on parent/container.
- **Local variables**: Accessible inside scoped blocks (no closures needed)
- **Auto-cleanup**: Guaranteed via `@(deferred_in_out)` attribute

---

## 2. Ratatui (Rust)

Ratatui uses a separation between Layout (calculating `Rect` areas) and Rendering (drawing `Widgets` in those areas). Centering generally requires a helper function to calculate the centered `Rect`.

### Code
```rust
use ratatui::{prelude::*, widgets::*};

fn draw(f: &mut Frame) {
    let area = f.size();
    
    // Helper function needed to create centered Rect
    let popup_area = centered_rect(area, 40, 10); 
    
    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .title("Ratatui");
    
    let paragraph = Paragraph::new("Hello Rust!")
        .block(block) // Border belongs to widget
        .alignment(Alignment::Center); // Text alignment
    
    f.render_widget(paragraph, popup_area);
}

// Helper not in the ecosystem
fn centered_rect(r: Rect, w: u16, h: u16) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length((r.height - h) / 2),
            Constraint::Length(h),
            Constraint::Length((r.height - h) / 2),
        ])
        .split(r);
    
    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Length((r.width - w) / 2),
            Constraint::Length(w),
            Constraint::Length((r.width - w) / 2),
        ])
        .split(popup_layout[1])[1]
}
```

### Features
- **Paradigm**: Retained/Immediate hybrid (re-calculates layout every frame).
- **Layout**: Based on `Constraints` that divide areas.
- **Borders**: Component `Block` that wraps other widgets.
- **Centering**: Manual or via layout constraint helpers.
- **State management**: Widget tree retained between frames.

---

## 3. Charm / Bubbletea + Lipgloss (Go)

Charm uses the **The Elm Architecture** (Model-View-Update). Layout and styling are built on **Lipgloss**, which works similarly to CSS.

### Code
```go
import "github.com/charmbracelet/lipgloss"

// Style definition (CSS-like)
var style = lipgloss.NewStyle().
    BorderStyle(lipgloss.RoundedBorder()).
    BorderForeground(lipgloss.Color("63")).
    Width(40).
    Height(10).
    Align(lipgloss.Center). // Align text horizontally
    Padding(1)

func (m Model) View() string {
    // Render content (box with border)
    content := style.Render("Hello Go!")
    
    // Center content on entire screen
    return lipgloss.Place(
        m.width, m.height,
        lipgloss.Center, lipgloss.Center,
        content,
    )
}
```

### Features
- **Paradigm**: Declarative / Component-based (String-based return).
- **Layout**: CSS-like (`Padding`, `Margin`, `Align`).
- **Borders**: Defined in style (`BorderStyle`).
- **Centering**: Using `lipgloss.Place` to position rendered strings in a larger space.
- **Verbosity**: Low (Style separated, view concise).

---

## Comparison Summary

| Feature | Ansuz (Odin) | Ratatui (Rust) | Charm (Go) |
| :--- | :--- | :--- | :--- |
| **Borders** | Container param (`.Rounded`) | Widget `Block` wrapper | Style Lipgloss (`BorderStyle`) |
| **Layout** | Container props (`grow`, `fixed`) | Constraints Solver (`Layout::split`) | CSS-like properties |
| **Centering** | `alignment` on parent | Manual `Rect` calculation or helpers | `lipgloss.Place` for strings |
| **Verbosity** | Medium (Explicit layout logic) | High (Layout separate from render) | Low (Style separated, view concise) |

Ansuz aims for a middle-ground approach, offering the ease of layout of CSS (like Charm) while maintaining the performance and structure of Immediate Mode, avoiding the complexity of manual `Rect` calculations from Ratatui.
