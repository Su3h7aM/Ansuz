package ansuz

import "core:fmt"

// EventType categorizes different kinds of terminal events
EventType :: enum {
    None,
    Key,
    Resize,
    Mouse,     // Future: mouse support
    Focus,     // Future: focus events
}

// Key represents keyboard keys
// Includes both printable characters and special keys
Key :: enum {
    Unknown,
    
    // Control keys
    Ctrl_C,
    Ctrl_D,
    Ctrl_Z,
    Escape,
    Enter,
    Tab,
    Backspace,
    Delete,
    
    // Arrow keys
    Up,
    Down,
    Left,
    Right,
    
    // Function keys
    F1, F2, F3, F4, F5, F6,
    F7, F8, F9, F10, F11, F12,
    
    // Other special keys
    Home,
    End,
    PageUp,
    PageDown,
    Insert,
    
    // Printable character (use rune field)
    Char,
}

// KeyModifier represents keyboard modifiers
KeyModifier :: enum {
    Shift,
    Alt,
    Ctrl,
}

// KeyModifiers is a set of active modifiers
KeyModifiers :: bit_set[KeyModifier]

// KeyEvent represents a keyboard input event
KeyEvent :: struct {
    key:       Key,
    modifiers: KeyModifiers,
    rune:      rune,  // For Key.Char, the actual character
}

// ResizeEvent represents a terminal size change
ResizeEvent :: struct {
    width:  int,
    height: int,
}

// MouseButton represents mouse buttons
MouseButton :: enum {
    None,
    Left,
    Right,
    Middle,
}

// MouseEvent represents mouse input (future expansion)
MouseEvent :: struct {
    button:    MouseButton,
    x:         int,
    y:         int,
    pressed:   bool,
    modifiers: KeyModifiers,
}

// Event is a tagged union of all possible event types
Event :: union {
    KeyEvent,
    ResizeEvent,
    MouseEvent,
}

// parse_input attempts to parse raw terminal input into an Event
// This is a simplified parser for the MVP - handles basic keys and Ctrl+C
// A full implementation would parse complete ANSI escape sequences
parse_input :: proc(bytes: []byte) -> (event: Event, parsed: bool) {
    if len(bytes) == 0 {
        return nil, false
    }

    // Single byte - either control character or regular char
    if len(bytes) == 1 {
        b := bytes[0]
        
        // Control characters (Ctrl+A = 1, Ctrl+B = 2, etc.)
        switch b {
        case 3:  // Ctrl+C
            return KeyEvent{key = .Ctrl_C}, true
        case 4:  // Ctrl+D
            return KeyEvent{key = .Ctrl_D}, true
        case 26: // Ctrl+Z
            return KeyEvent{key = .Ctrl_Z}, true
        case 27: // ESC
            return KeyEvent{key = .Escape}, true
        case 13, 10: // Enter (CR or LF)
            return KeyEvent{key = .Enter}, true
        case 9:  // Tab
            return KeyEvent{key = .Tab}, true
        case 127, 8: // Backspace/Delete
            return KeyEvent{key = .Backspace}, true
        }

        // Printable ASCII character
        if b >= 32 && b < 127 {
            return KeyEvent{key = .Char, rune = rune(b)}, true
        }

        return nil, false
    }

    // Multi-byte sequences - typically escape sequences
    // ESC [ sequences for arrow keys, function keys, etc.
    if len(bytes) >= 3 && bytes[0] == 27 && bytes[1] == '[' {
        switch bytes[2] {
        case 'A':
            return KeyEvent{key = .Up}, true
        case 'B':
            return KeyEvent{key = .Down}, true
        case 'C':
            return KeyEvent{key = .Right}, true
        case 'D':
            return KeyEvent{key = .Left}, true
        case 'H':
            return KeyEvent{key = .Home}, true
        case 'F':
            return KeyEvent{key = .End}, true
        }

        // Handle sequences like ESC[3~ (Delete), ESC[5~ (PageUp), etc.
        if len(bytes) >= 4 && bytes[3] == '~' {
            switch bytes[2] {
            case '1': return KeyEvent{key = .Home}, true
            case '2': return KeyEvent{key = .Insert}, true
            case '3': return KeyEvent{key = .Delete}, true
            case '4': return KeyEvent{key = .End}, true
            case '5': return KeyEvent{key = .PageUp}, true
            case '6': return KeyEvent{key = .PageDown}, true
            }
        }
    }

    // Function keys: ESC O P through ESC O S (F1-F4)
    if len(bytes) >= 3 && bytes[0] == 27 && bytes[1] == 'O' {
        switch bytes[2] {
        case 'P': return KeyEvent{key = .F1}, true
        case 'Q': return KeyEvent{key = .F2}, true
        case 'R': return KeyEvent{key = .F3}, true
        case 'S': return KeyEvent{key = .F4}, true
        }
    }

    // Unrecognized sequence
    return nil, false
}

// is_quit_key checks if an event is a quit signal (Ctrl+C or Ctrl+D)
is_quit_key :: proc(event: Event) -> bool {
    if key_event, ok := event.(KeyEvent); ok {
        return key_event.key == .Ctrl_C || key_event.key == .Ctrl_D
    }
    return false
}

// event_to_string converts an event to a human-readable string (for debugging)
event_to_string :: proc(event: Event) -> string {
    switch e in event {
    case KeyEvent:
        if e.key == .Char {
            return fmt.tprintf("Key: '%c'", e.rune)
        }
        return fmt.tprintf("Key: %v", e.key)
    case ResizeEvent:
        return fmt.tprintf("Resize: %dx%d", e.width, e.height)
    case MouseEvent:
        return fmt.tprintf("Mouse: button=%v pos=(%d,%d)", e.button, e.x, e.y)
    }
    return "Unknown Event"
}

// EventBuffer manages a queue of events
// Useful for buffering input events between frames
EventBuffer :: struct {
    events:  [dynamic]Event,
    max_size: int,
}

// init_event_buffer creates a new event buffer
init_event_buffer :: proc(max_size := 128) -> EventBuffer {
    return EventBuffer{
        events = make([dynamic]Event, 0, max_size),
        max_size = max_size,
    }
}

// destroy_event_buffer frees the event buffer
destroy_event_buffer :: proc(buffer: ^EventBuffer) {
    delete(buffer.events)
}

// push_event adds an event to the buffer
// Returns false if buffer is full
push_event :: proc(buffer: ^EventBuffer, event: Event) -> bool {
    if len(buffer.events) >= buffer.max_size {
        return false
    }
    append(&buffer.events, event)
    return true
}

// pop_event removes and returns the next event
// Returns (event, true) if available, (nil, false) if empty
pop_event :: proc(buffer: ^EventBuffer) -> (event: Event, available: bool) {
    if len(buffer.events) == 0 {
        return nil, false
    }
    event = buffer.events[0]
    ordered_remove(&buffer.events, 0)
    return event, true
}

// clear_events removes all events from the buffer
clear_events :: proc(buffer: ^EventBuffer) {
    clear(&buffer.events)
}

// has_events checks if there are any events in the buffer
has_events :: proc(buffer: ^EventBuffer) -> bool {
    return len(buffer.events) > 0
}
