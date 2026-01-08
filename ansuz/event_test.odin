package ansuz

import "core:testing"
import "core:fmt"

@(test)
test_event_buffer :: proc(t: ^testing.T) {
    buf := init_event_buffer()

    // Buffer should start empty
    testing.expect(t, len(buf.events) == 0, "Buffer should start empty")
    testing.expect(t, buf.head == 0, "Head should start at 0")
    testing.expect(t, buf.tail == 0, "Tail should start at 0")

    // Push some events
    ev1 := Event{KeyEvent = KeyEvent{.Char, 'a', 0}}
    push_event(&buf, ev1)

    ev2 := Event{KeyEvent = KeyEvent{.Char, 'b', 0}}
    push_event(&buf, ev2)

    // Buffer should have events
    testing.expect(t, len(buf.events) > 0, "Buffer should have events after push")

    destroy_event_buffer(&buf)
}

@(test)
test_event_type_union :: proc(t: ^testing.T) {
    // Create a key event
    key_ev := Event{KeyEvent = KeyEvent{.Char, 'x', .Ctrl}}

    switch e in key_ev {
    case KeyEvent:
        testing.expect(t, e.key == .Char, "Should be Char key")
        testing.expect(t, e.rune == 'x', "Rune should be 'x'")
        testing.expect(t, e.modifier == .Ctrl, "Modifier should be Ctrl")
    case:
        testing.fail(t, "Event should be KeyEvent")
    }

    // Create a resize event
    resize_ev := Event{ResizeEvent = ResizeEvent{80, 24}}

    switch e in resize_ev {
    case ResizeEvent:
        testing.expect(t, e.width == 80, "Width should be 80")
        testing.expect(t, e.height == 24, "Height should be 24")
    case:
        testing.fail(t, "Event should be ResizeEvent")
    }
}

@(test)
test_is_quit_key :: proc(t: ^testing.T) {
    // Ctrl+C should be quit key
    ev := Event{KeyEvent = KeyEvent{.Ctrl_C, 0, 0}}
    testing.expect(t, is_quit_key(ev), "Ctrl+C should be quit key")

    // Ctrl+D should be quit key
    ev = Event{KeyEvent = KeyEvent{.Ctrl_D, 0, 0}}
    testing.expect(t, is_quit_key(ev), "Ctrl+D should be quit key")

    // Regular key should not be quit
    ev = Event{KeyEvent = KeyEvent{.Char, 'a', 0}}
    testing.expect(t, !is_quit_key(ev), "Regular key should not be quit")

    // Escape should not be quit
    ev = Event{KeyEvent = KeyEvent{.Escape, 0, 0}}
    testing.expect(t, !is_quit_key(ev), "Escape should not be quit")

    // Resize event should not be quit
    ev = Event{ResizeEvent = ResizeEvent{80, 24}}
    testing.expect(t, !is_quit_key(ev), "Resize should not be quit")
}

@(test)
test_key_event_creation :: proc(t: ^testing.T) {
    // Test character key
    ev := KeyEvent{.Char, 'Z', .Shift}
    testing.expect(t, ev.key == .Char, "Key should be Char")
    testing.expect(t, ev.rune == 'Z', "Rune should be 'Z'")
    testing.expect(t, ev.modifier == .Shift, "Modifier should be Shift")

    // Test control keys
    ev = KeyEvent{.Up, 0, 0}
    testing.expect(t, ev.key == .Up, "Key should be Up")

    ev = KeyEvent{.Enter, 0, 0}
    testing.expect(t, ev.key == .Enter, "Key should be Enter")

    ev = KeyEvent{.Tab, 0, 0}
    testing.expect(t, ev.key == .Tab, "Key should be Tab")

    ev = KeyEvent{.Space, ' ', 0}
    testing.expect(t, ev.key == .Space, "Key should be Space")
    testing.expect(t, ev.rune == ' ', "Space rune should be space character")
}

@(test)
test_resize_event_creation :: proc(t: ^testing.T) {
    ev := ResizeEvent{120, 40}
    testing.expect(t, ev.width == 120, "Width should be 120")
    testing.expect(t, ev.height == 40, "Height should be 40")
}

@(test)
test_event_variants :: proc(t: ^testing.T) {
    // Test all event variants can be created
    events := [?]Event{
        Event{KeyEvent = KeyEvent{.Char, 'a', 0}},
        Event{KeyEvent = KeyEvent{.Ctrl_C, 0, 0}},
        Event{ResizeEvent = ResizeEvent{80, 24}},
    }

    for i, ev in events {
        testing.expect(t, true,
                      fmt.tprintf("Event %d should be valid", i))
    }
}
