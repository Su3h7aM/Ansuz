# Ansuz TUI Library - Architectural Documentation

## Executive Summary

Ansuz is a Terminal User Interface (TUI) library for the Odin programming language, designed with an immediate-mode API pattern inspired by Clay and architectural concepts from OpenTUI.

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
- `39`: Default

**Background Colors:**
- `40`-`47`: Standard
- `100`-`107`: Bright Variants
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

1.  **Render Buffer**: 2D grid of cells (rune + style).
2.  **Event Loop**: Capture input -> Update State -> Layout -> Render -> Output.
3.  **Layout Engine**: Calculates widget positions/sizes.
4.  **Diffing**: Only writes changed cells to the terminal to minimize bandwidth and flickering.

### 2.2 Rendering Flow

```
Input -> Event Processing -> Layout -> Rendering (to Buffer) -> Diff -> Output (ANSI)
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
│   ├── buffer.odin    # Frame buffer algorithms
│   ├── colors.odin    # Color system
│   ├── event.odin     # Event handling
│   ├── layout.odin    # Layout engine implementation
│   └── terminal.odin  # Lower-level terminal I/O (termios)
├── examples/          # Example programs
├── docs/              # Documentation
└── .mise/tasks/       # Build/Test scripts
```

### 4.2 Core Modules

- **api.odin**: The high-level entry point. Manages the `Context` and frame lifecycle (`begin_frame`, `end_frame`).
- **buffer.odin**: Manages the double-buffered rendering grid. Handles resizing and diffing.
- **layout.odin**: Implements the layout solver (Measure -> Resolve -> Position).
- **terminal.odin**: Handles platform-specific system calls (`tcgetattr`, `tcsetattr`) and raw ANSI output.
- **event.odin**: Parses raw bytes from stdin into structured `Event` enums (Keys, Resizes).

### 4.3 Data Structures

**Cell**:
```odin
Cell :: struct {
    rune:       rune,
    fg_color:   Color,
    bg_color:   Color,
    style:      StyleFlags,
    dirty:      bool,
}
```

**Context**:
Holds the global state for the library (buffers, input queue, layout stack).
