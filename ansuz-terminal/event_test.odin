package ansuz_terminal

import "core:strings"
import "core:testing"

@(test)
test_parse_input_empty :: proc(t: ^testing.T) {
	input: []u8
	event, parsed := parse_input(input)
	testing.expect(t, !parsed, "Empty input should not parse")
}

@(test)
test_parse_input_ctrl_c :: proc(t: ^testing.T) {
	input: []u8 = {3}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Ctrl+C should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Ctrl_C, "Should be Ctrl+C")
}

@(test)
test_parse_input_ctrl_d :: proc(t: ^testing.T) {
	input: []u8 = {4}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Ctrl+D should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Ctrl_D, "Should be Ctrl+D")
}

@(test)
test_parse_input_ctrl_z :: proc(t: ^testing.T) {
	input: []u8 = {26}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Ctrl+Z should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Ctrl_Z, "Should be Ctrl+Z")
}

@(test)
test_parse_input_escape :: proc(t: ^testing.T) {
	input: []u8 = {27}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "ESC should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Escape, "Should be Escape")
}

@(test)
test_parse_input_enter_cr :: proc(t: ^testing.T) {
	input: []u8 = {13}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "CR (Enter) should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Enter, "Should be Enter")
}

@(test)
test_parse_input_enter_lf :: proc(t: ^testing.T) {
	input: []u8 = {10}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "LF (Enter) should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Enter, "Should be Enter")
}

@(test)
test_parse_input_tab :: proc(t: ^testing.T) {
	input: []u8 = {9}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Tab should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Tab, "Should be Tab")
}

@(test)
test_parse_input_backspace_127 :: proc(t: ^testing.T) {
	input: []u8 = {127}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Backspace (127) should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Backspace, "Should be Backspace")
}

@(test)
test_parse_input_backspace_8 :: proc(t: ^testing.T) {
	input: []u8 = {8}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Backspace (8) should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Backspace, "Should be Backspace")
}

@(test)
test_parse_input_printable_ascii :: proc(t: ^testing.T) {
	for i in 32 ..< 127 {
		input: []u8 = {u8(i)}
		event, parsed := parse_input(input)
		testing.expect(t, parsed, "Printable ASCII should parse")

		key_event, ok := event.(KeyEvent)
		testing.expect(t, ok, "Should return KeyEvent")
		testing.expect(t, key_event.key == .Char, "Should be Char type")
		testing.expect_value(t, key_event.rune, rune(i))
	}
}

@(test)
test_parse_input_printable_specific :: proc(t: ^testing.T) {
	input: []u8 = {'A'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "'A' should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Char, "Should be Char type")
	testing.expect_value(t, key_event.rune, 'A')
}

@(test)
test_parse_input_space :: proc(t: ^testing.T) {
	input: []u8 = {32}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Space should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Char, "Should be Char type")
	testing.expect_value(t, key_event.rune, ' ')
}

@(test)
test_parse_input_arrow_up :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', 'A'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Arrow Up should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Up, "Should be Up arrow")
}

@(test)
test_parse_input_arrow_down :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', 'B'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Arrow Down should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Down, "Should be Down arrow")
}

@(test)
test_parse_input_arrow_left :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', 'D'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Arrow Left should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Left, "Should be Left arrow")
}

@(test)
test_parse_input_arrow_right :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', 'C'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Arrow Right should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Right, "Should be Right arrow")
}

@(test)
test_parse_input_home :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', 'H'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Home should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Home, "Should be Home")
}

@(test)
test_parse_input_end :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', 'F'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "End should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .End, "Should be End")
}

@(test)
test_parse_input_delete :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', '3', '~'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Delete should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Delete, "Should be Delete")
}

@(test)
test_parse_input_insert :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', '2', '~'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "Insert should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .Insert, "Should be Insert")
}

@(test)
test_parse_input_page_up :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', '5', '~'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "PageUp should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .PageUp, "Should be PageUp")
}

@(test)
test_parse_input_page_down :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', '6', '~'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "PageDown should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .PageDown, "Should be PageDown")
}

@(test)
test_parse_input_f1 :: proc(t: ^testing.T) {
	input: []u8 = {27, 'O', 'P'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "F1 should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .F1, "Should be F1")
}

@(test)
test_parse_input_f2 :: proc(t: ^testing.T) {
	input: []u8 = {27, 'O', 'Q'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "F2 should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .F2, "Should be F2")
}

@(test)
test_parse_input_f3 :: proc(t: ^testing.T) {
	input: []u8 = {27, 'O', 'R'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "F3 should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .F3, "Should be F3")
}

@(test)
test_parse_input_f4 :: proc(t: ^testing.T) {
	input: []u8 = {27, 'O', 'S'}
	event, parsed := parse_input(input)
	testing.expect(t, parsed, "F4 should parse")

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, key_event.key == .F4, "Should be F4")
}

@(test)
test_parse_input_invalid_sequence :: proc(t: ^testing.T) {
	input: []u8 = {27, '[', 'Z'}
	event, parsed := parse_input(input)
	testing.expect(t, !parsed, "Invalid escape sequence should not parse")
}

@(test)
test_parse_input_unrecognized :: proc(t: ^testing.T) {
	input: []u8 = {0, 1, 2}
	event, parsed := parse_input(input)
	testing.expect(t, !parsed, "Unrecognized control codes should not parse")
}

@(test)
test_is_quit_key_ctrl_c :: proc(t: ^testing.T) {
	event: Event = KeyEvent {
		key = .Ctrl_C,
	}
	testing.expect(t, is_quit_key(event), "Ctrl+C should be quit key")
}

@(test)
test_is_quit_key_ctrl_d :: proc(t: ^testing.T) {
	event: Event = KeyEvent {
		key = .Ctrl_D,
	}
	testing.expect(t, is_quit_key(event), "Ctrl+D should be quit key")
}

@(test)
test_is_quit_key_escape :: proc(t: ^testing.T) {
	event: Event = KeyEvent {
		key = .Escape,
	}
	testing.expect(t, is_quit_key(event), "Escape should be quit key")
}

@(test)
test_is_quit_key_q :: proc(t: ^testing.T) {
	event: Event = KeyEvent {
		key  = .Char,
		rune = 'q',
	}
	testing.expect(t, is_quit_key(event), "'q' should be quit key")

	event = KeyEvent {
		key  = .Char,
		rune = 'Q',
	}
	testing.expect(t, is_quit_key(event), "'Q' should be quit key")
}

@(test)
test_is_quit_key_other :: proc(t: ^testing.T) {
	event: Event = KeyEvent {
		key = .Enter,
	}
	testing.expect(t, !is_quit_key(event), "Enter should not be quit key")

	event = KeyEvent {
		key  = .Char,
		rune = 'a',
	}
	testing.expect(t, !is_quit_key(event), "'a' should not be quit key")
}

@(test)
test_is_quit_key_non_key_event :: proc(t: ^testing.T) {
	event: Event = ResizeEvent {
		width  = 80,
		height = 24,
	}
	testing.expect(t, !is_quit_key(event), "ResizeEvent should not be quit key")
}

@(test)
test_event_to_string_key :: proc(t: ^testing.T) {
	event: Event = KeyEvent {
		key = .Enter,
	}
	str := event_to_string(event)
	testing.expect(t, strings.contains(str, "Key"), "Should contain 'Key'")
	testing.expect(t, strings.contains(str, "Enter"), "Should contain 'Enter'")
}

@(test)
test_event_to_string_char :: proc(t: ^testing.T) {
	event: Event = KeyEvent {
		key  = .Char,
		rune = 'A',
	}
	str := event_to_string(event)
	testing.expect(t, strings.contains(str, "Key"), "Should contain 'Key'")
	testing.expect(t, strings.contains(str, "'A'"), "Should contain 'A'")
}

@(test)
test_event_to_string_resize :: proc(t: ^testing.T) {
	event: Event = ResizeEvent {
		width  = 80,
		height = 24,
	}
	str := event_to_string(event)
	testing.expect(t, strings.contains(str, "Resize"), "Should contain 'Resize'")
	testing.expect(t, strings.contains(str, "80"), "Should contain width")
	testing.expect(t, strings.contains(str, "24"), "Should contain height")
}

@(test)
test_event_to_string_mouse :: proc(t: ^testing.T) {
	event: Event = MouseEvent {
		button  = .Left,
		x       = 10,
		y       = 20,
		pressed = true,
	}
	str := event_to_string(event)
	testing.expect(t, strings.contains(str, "Mouse"), "Should contain 'Mouse'")
	testing.expect(t, strings.contains(str, "Left"), "Should contain button name")
	testing.expect(t, strings.contains(str, "10"), "Should contain x position")
	testing.expect(t, strings.contains(str, "20"), "Should contain y position")
}

@(test)
test_key_modifiers_bit_set :: proc(t: ^testing.T) {
	modifiers: KeyModifiers = {}

	testing.expect(t, !(.Shift in modifiers), "Should not have Shift initially")

	modifiers = {.Shift, .Ctrl}
	testing.expect(t, .Shift in modifiers, "Should have Shift")
	testing.expect(t, .Ctrl in modifiers, "Should have Ctrl")
	testing.expect(t, card(modifiers) == 2, "Should have 2 modifiers")
}

@(test)
test_key_event_modifiers :: proc(t: ^testing.T) {
	modifiers: KeyModifiers = {.Shift, .Alt}
	event: Event = KeyEvent {
		key       = .Char,
		rune      = 'A',
		modifiers = modifiers,
	}

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should be KeyEvent")
	testing.expect(t, .Shift in key_event.modifiers, "Should have Shift modifier")
	testing.expect(t, .Alt in key_event.modifiers, "Should have Alt modifier")
	testing.expect(t, .Ctrl in key_event.modifiers == false, "Should not have Ctrl")
}

@(test)
test_resize_event :: proc(t: ^testing.T) {
	event: Event = ResizeEvent {
		width  = 120,
		height = 40,
	}

	resize, ok := event.(ResizeEvent)
	testing.expect(t, ok, "Should be ResizeEvent")
	testing.expect_value(t, resize.width, 120)
	testing.expect_value(t, resize.height, 40)
}

@(test)
test_mouse_event :: proc(t: ^testing.T) {
	modifiers: KeyModifiers = {.Ctrl}
	event: Event = MouseEvent {
		button    = .Right,
		x         = 42,
		y         = 13,
		pressed   = false,
		modifiers = modifiers,
	}

	mouse, ok := event.(MouseEvent)
	testing.expect(t, ok, "Should be MouseEvent")
	testing.expect(t, mouse.button == .Right, "Should preserve button")
	testing.expect_value(t, mouse.x, 42)
	testing.expect_value(t, mouse.y, 13)
	testing.expect(t, !mouse.pressed, "Should preserve pressed state")
	testing.expect(t, .Ctrl in mouse.modifiers, "Should preserve modifiers")
}

@(test)
test_parse_input_preserves_modifiers_default :: proc(t: ^testing.T) {
	input: []u8 = {'A'}
	event, parsed := parse_input(input)

	key_event, ok := event.(KeyEvent)
	testing.expect(t, ok, "Should return KeyEvent")
	testing.expect(t, card(key_event.modifiers) == 0, "Default modifiers should be empty")
}
