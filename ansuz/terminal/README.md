# ansuz-terminal

Independent terminal I/O package for Odin.

## Overview

`ansuz-terminal` provides low-level terminal control and event handling for building TUIs (Terminal User Interfaces). It handles:

- Raw mode terminal input/output
- ANSI escape sequence generation
- Terminal size detection
- Input event parsing (keyboard, mouse, resize)
- Terminal state management

## Usage

```odin
import "ansuz-terminal"

// Initialize terminal
err := ansuz_terminal.init_terminal()
if err != .None {
    // Handle error
}

// Enter raw mode (non-blocking, no echo)
ansuz_terminal.enter_raw_mode()
defer ansuz_terminal.leave_raw_mode()

// Clear screen and hide cursor
ansuz_terminal.clear_screen()
ansuz_terminal.hide_cursor()
defer ansuz_terminal.show_cursor()

// Use alternate buffer (prevents scrollback pollution)
ansuz_terminal.enter_alternate_buffer()
defer ansuz_terminal.leave_alternate_buffer()

// Get terminal size
width, height, err := ansuz_terminal.get_terminal_size()

// Read and parse input
data, available := ansuz_terminal.read_input()
if available {
    // Parse the byte sequence
    event, parsed := ansuz_terminal.parse_input([]u8{data})
    if parsed {
        // Handle event
    }
}

// Wait for events with resize detection
result, new_w, new_h := ansuz_terminal.wait_for_event(
    current_width, current_height, timeout_ms=-1
)
```

## Key Features

### Terminal Control

- `init_terminal()` - Initialize terminal system
- `enter_raw_mode()` / `leave_raw_mode()` - Raw mode for immediate input
- `get_terminal_size()` - Get terminal dimensions via ioctl
- `reset_terminal()` - Full cleanup before exit

### ANSI Sequences

- `clear_screen()` / `clear_line()` - Screen/line clearing
- `move_cursor(row, col)` - Position cursor
- `hide_cursor()` / `show_cursor()` - Cursor visibility
- `enter_alternate_buffer()` / `leave_alternate_buffer()` - Alt buffer
- `begin_sync_update()` / `end_sync_update()` - Sync output (Mode 2026)

### Event Handling

- `read_input()` - Non-blocking byte read from stdin
- `parse_input([]u8)` - Parse escape sequences into events
- `wait_for_event()` - Poll-based event waiting with resize detection
- `is_quit_key(event)` - Check for quit signals (Ctrl+C, ESC, 'q')

### Event Types

- `KeyEvent` - Keyboard input with modifiers
- `ResizeEvent` - Terminal size change
- `MouseEvent` - Mouse button/position (experimental)

## Event Parsing

The package parses standard ANSI escape sequences:

- **Arrow keys**: ESC[A, ESC[B, ESC[C, ESC[D
- **Function keys**: ESCOP (F1), ESCOQ (F2), ESCOR (F3), ESCOS (F4)
- **Special keys**: Home, End, Insert, Delete, PageUp, PageDown
- **Modifiers**: Support for Shift, Alt, Ctrl in key combinations
- **Mouse**: X10 encoding (ESC[M...)

## Dependencies

- `core:sys/linux` - ioctl for terminal size
- `core:sys/posix` - termios, signals, poll
- `core:terminal/ansi` - ANSI constants
- `core:os` - stdin/stdout I/O
- `core:c` - C types for poll

## No External Dependencies

This package has zero dependencies on other ansuz packages and can be used
independently for any terminal-based application.
