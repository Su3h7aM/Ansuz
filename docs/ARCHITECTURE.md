# Ansuz TUI Library - Architectural Documentation

## Executive Summary

Ansuz is a Terminal User Interface (TUI) library for the Odin programming language, designed with an immediate-mode API pattern inspired by Clay.

## Table of Contents

1. [ANSI Codes & Terminal Rendering](#ansi-codes--terminal-rendering)
2. [TUI Architecture Fundamentals](#tui-architecture-fundamentals)
3. [Immediate Mode Pattern](#immediate-mode-pattern)
4. [Ansuz Architecture](#ansuz-architecture)

---

## 1. ANSI Codes & Terminal Rendering

### 1.1 Introduction to ANSI Escape Sequences

ANSI escape sequences are special character sequences that terminals interpret as commands rather than text to display. They enable control over cursor positioning, text styling, and screen manipulation without requiring a graphical interface.

The basic format is: `ESC [ <parameters> <command>`
Where `ESC` is the escape character (ASCII 27, or `\x1b` in hexadecimal).

### 1.2 Essential ANSI Codes

#### Color Codes

**Foreground Colors:**
- `30`-`37`: Standard (Black, Red, Green, Yellow, Blue, Magenta, Cyan, White)
- `90`-`97`: Bright Variants
- `38;5;n`: 256-color palette (n=0-255)
- `38;2;r;g;b`: 24-bit TrueColor (RGB)
- `39`: Default

**Background Colors:**
- `40`-`47`: Standard
- `100`-`107`: Bright Variants
- `48;5;n`: 256-color palette
- `48;2;r;g;b`: 24-bit TrueColor
- `49`: Default

#### Text Attributes
- `0`: Reset
- `1`: Bold
- `2`: Dim
- `4`: Underline
- `5`: Blink
- `7`: Reverse

#### Cursor & Screen
- `\x1b[2J`: Clear screen
- `\x1b[H`: Move to home (1,1)
- `\x1b[?25l` / `\x1b[?25h`: Hide/Show cursor

### 1.3 Raw Mode
Ansuz operates in **Raw Mode**, disabling canonical line buffering and echoing to gain full control over the terminal. This involves modifying `termios` flags on Unix systems (disabling `ECHO`, `ICANON`, `ISIG`, etc.).

---

## 2. TUI Architecture Fundamentals

### 2.1 Core Components

1.  **Render Buffer**: Single 2D grid of cells (rune + style) that is cleared every frame.
2.  **Event Loop**: Capture input -> Update State -> Layout -> Render -> Output.
3.  **Layout Engine**: Calculates widget positions/sizes.
4.  **Full-Frame Renderer**: The entire buffer is converted to ANSI output each frame (no diffing).

### 2.2 Rendering Flow

```
Input -> Event Processing -> Layout -> Rendering (to Buffer) -> Full Redraw Output (ANSI)
```

---

## 3. Immediate Mode Pattern

### 3.1 Concept

`UI = f(State)`

Ansuz uses an immediate mode paradigm where the UI is declared every frame based on the current state.

**Advantages:**
- **Simplicity**: No widget tree to manage.
- **Reactivity**: Changes instantly reflected.
- **Stateless UI**: Logic stays in your application.

### 3.2 Comparison

**Immediate Mode (Ansuz):**
```odin
if button("Click Me") { do_something() }
```

**Retained Mode (Classic):**
```odin
btn := create_button("Click Me")
btn.on_click = do_something
container.add(btn)
```

---

## 4. Ansuz Architecture

### 4.1 Directory Structure

The project follows a flat structure for the core library to keep imports simple and compilation fast.

```
ansuz/
├── ansuz/             # Core library source
│   ├── api.odin       # Public API & Context
│   ├── scoped.odin    # Scoped callback API (primary interface)
│   ├── element.odin    # Element and widget definitions
│   ├── buffer.odin    # Frame buffer algorithms
│   ├── colors.odin    # Color system
│   ├── event.odin     # Event handling
│   ├── layout.odin    # Layout engine implementation
│   ├── terminal.odin  # Lower-level terminal I/O (termios)
│   ├── theme.odin     # Theme definitions
│   └── widgets.odin   # High-level widget implementations
├── examples/          # Example programs
├── docs/              # Documentation
└── .mise/tasks/       # Build/Test scripts
```

### 4.2 Core Modules

- **api.odin**: The high-level entry point. Manages the `Context`, frame lifecycle (`begin_frame`, `end_frame`), event loop (`run`), and focus utilities.
- **scoped.odin**: The primary UI declaration API. Provides scoped callbacks with `layout()`, `container()`, `box()`, `rect()`, `vstack()`, `hstack()`.
- **element.odin**: Element definitions and leaf nodes (`label()`, `element()`), plus themed widgets (`widget_button`, `widget_checkbox`).
- **buffer.odin**: Manages the rendering grid, clipping, text wrapping, and ANSI output generation.
- **layout.odin**: Implements the 3-pass layout solver (Measure -> Resolve -> Position) with Clay-inspired algorithms.
- **terminal.odin**: Handles raw terminal mode, alternate buffer, synchronized updates, and resize detection via native Odin POSIX/Linux calls.
- **event.odin**: Parses raw bytes from stdin into structured `Event` enums (keys, resizes).
- **theme.odin**: Theme definitions and style helpers for widgets.
- **widgets.odin**: Lightweight widget helpers (`button`, `checkbox`) using the lower-level element primitives.

### 4.3 Data Structures

**Cell**:
```odin
Cell :: struct {
    rune:  rune,
    fg:    TerminalColor, // Union: Ansi, Color256, RGB
    bg:    TerminalColor,
    style: StyleFlags,
}
```

**Context**:
Holds the global state for the library (buffers, input queue, layout stack).
