package ansuz

import "core:mem"
import "core:strings"
import "core:testing"

import ab "../buffer"
import ac "../color"
import at "../terminal"
import al "../layout"

@(test)
test_buffer_out_of_bounds_negative :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Test negative indices
	cell := ab.get_cell(&buffer, -1, 0)
	testing.expect(t, cell == nil, "Negative x should return nil")

	cell = ab.get_cell(&buffer, 0, -1)
	testing.expect(t, cell == nil, "Negative y should return nil")

	cell = ab.get_cell(&buffer, -5, -5)
	testing.expect(t, cell == nil, "Both negative should return nil")
}

@(test)
test_buffer_out_of_bounds_large :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Test indices equal to dimensions
	cell := ab.get_cell(&buffer, 10, 0)
	testing.expect(t, cell == nil, "x == width should return nil")

	cell = ab.get_cell(&buffer, 0, 10)
	testing.expect(t, cell == nil, "y == height should return nil")

	// Test indices greater than dimensions
	cell = ab.get_cell(&buffer, 100, 0)
	testing.expect(t, cell == nil, "Large x should return nil")

	cell = ab.get_cell(&buffer, 0, 100)
	testing.expect(t, cell == nil, "Large y should return nil")
}

@(test)
test_buffer_set_cell_out_of_bounds :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	err := ab.set_cell(&buffer, -1, 0, 'X', .Red, .Blue, {})
	testing.expect(t, err == .OutOfBounds, "Negative x should return OutOfBounds")

	err = ab.set_cell(&buffer, 0, -1, 'X', .Red, .Blue, {})
	testing.expect(t, err == .OutOfBounds, "Negative y should return OutOfBounds")

	err = ab.set_cell(&buffer, 10, 0, 'X', .Red, .Blue, {})
	testing.expect(t, err == .OutOfBounds, "x == width should return OutOfBounds")

	err = ab.set_cell(&buffer, 0, 10, 'X', .Red, .Blue, {})
	testing.expect(t, err == .OutOfBounds, "y == height should return OutOfBounds")

	err = ab.set_cell(&buffer, 100, 100, 'X', .Red, .Blue, {})
	testing.expect(t, err == .OutOfBounds, "Large indices should return OutOfBounds")
}

@(test)
test_edge_buffer_write_string_empty :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	chars := ab.write_string(&buffer, 5, 5, "", .Red, .Blue, {})
	testing.expect_value(t, chars, 0)

	// Buffer should remain unchanged
	cell := ab.get_cell(&buffer, 5, 5)
	testing.expect(t, cell.rune == ' ', "Cell should still be space")
}

@(test)
test_edge_buffer_write_string_at_edge :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Write string that starts at edge
	chars := ab.write_string(&buffer, 9, 5, "ABC", .Red, .Blue, {})
	testing.expect_value(t, chars, 1)

	cell := ab.get_cell(&buffer, 9, 5)
	testing.expect(t, cell.rune == 'A', "Should write 'A' at edge")
}

@(test)
test_edge_buffer_write_string_beyond :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Write string that starts beyond buffer
	chars := ab.write_string(&buffer, 20, 5, "ABC", .Red, .Blue, {})
	testing.expect_value(t, chars, 0)
}

@(test)
test_buffer_fill_rect_zero_size :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	ab.fill_rect(&buffer, 5, 5, 0, 0, 'X', .Red, .Blue, {})
	// Should not crash
	cell := ab.get_cell(&buffer, 5, 5)
	testing.expect(t, cell.rune == ' ', "Zero-size rect should not modify buffer")
}

@(test)
test_buffer_fill_rect_out_of_bounds :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Fill rect that goes beyond buffer
	// set_cell will handle out of bounds silently
	ab.fill_rect(&buffer, 8, 8, 5, 5, 'X', .Red, .Blue, {})
	// Should not crash
}

@(test)
test_buffer_draw_box_min_size :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Draw boxes that are too small
	ab.draw_box(&buffer, 5, 5, 1, 5, .Red, .Blue, {})
	ab.draw_box(&buffer, 5, 5, 5, 1, .Red, .Blue, {})
	ab.draw_box(&buffer, 5, 5, 1, 1, .Red, .Blue, {})
	ab.draw_box(&buffer, 5, 5, 0, 0, .Red, .Blue, {})
	// Should not crash
}

@(test)
test_buffer_draw_box_out_of_bounds :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Draw box that extends beyond buffer
	ab.draw_box(&buffer, 8, 8, 10, 10, .Red, .Blue, {})
	// Should not crash
}

@(test)
test_buffer_resize_to_zero :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	err := ab.resize_buffer(&buffer, 0, 10)
	testing.expect(t, err == .InvalidDimensions, "Resize to width 0 should fail")

	err = ab.resize_buffer(&buffer, 10, 0)
	testing.expect(t, err == .InvalidDimensions, "Resize to height 0 should fail")
}

@(test)
test_buffer_resize_negative :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	err := ab.resize_buffer(&buffer, -10, 10)
	testing.expect(t, err == .InvalidDimensions, "Resize to negative width should fail")

	err = ab.resize_buffer(&buffer, 10, -10)
	testing.expect(t, err == .InvalidDimensions, "Resize to negative height should fail")
}

@(test)
test_buffer_resize_preserves_content :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Set some content
	ab.set_cell(&buffer, 5, 5, 'X', .Red, .Blue, {})
	ab.set_cell(&buffer, 9, 9, 'Y', .Green, .Yellow, {})
	ab.set_cell(&buffer, 0, 0, 'Z', .Magenta, .Cyan, {})

	// Resize
	err := ab.resize_buffer(&buffer, 20, 20)
	testing.expect(t, err == .None, "Resize should succeed")

	// Verify content preserved
	cell := ab.get_cell(&buffer, 5, 5)
	testing.expect(t, cell.rune == 'X', "Content at (5,5) should be preserved")

	cell = ab.get_cell(&buffer, 9, 9)
	testing.expect(t, cell.rune == 'Y', "Content at (9,9) should be preserved")

	cell = ab.get_cell(&buffer, 0, 0)
	testing.expect(t, cell.rune == 'Z', "Content at (0,0) should be preserved")
}

@(test)
test_buffer_resize_shrinker :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Fill entire buffer
	for y in 0 ..< 10 {
		for x in 0 ..< 10 {
			ab.set_cell(&buffer, x, y, 'X', .Red, .Blue, {})
		}
	}

	// Resize smaller
	err := ab.resize_buffer(&buffer, 5, 5)
	testing.expect(t, err == .None, "Resize to smaller should succeed")

	// Verify all cells in new size are 'X'
	for y in 0 ..< 5 {
		for x in 0 ..< 5 {
			cell := ab.get_cell(&buffer, x, y)
			testing.expect(t, cell.rune == 'X', "Preserved content should be 'X'")
		}
	}
}

// === Color/Style Edge Cases ===

@(test)
test_color_enum_values :: proc(t: ^testing.T) {
	// Test all ac.Ansi enum values
	colors := [?]ac.Ansi {
		.Default,
		.Black,
		.Red,
		.Green,
		.Yellow,
		.Blue,
		.Magenta,
		.Cyan,
		.White,
		.BrightBlack,
		.BrightRed,
		.BrightGreen,
		.BrightYellow,
		.BrightBlue,
		.BrightMagenta,
		.BrightCyan,
		.BrightWhite,
	}

	for color in colors {
		fg_code := ac.ansi_to_fg_code(color)
		bg_code := ac.ansi_to_bg_code(color)

		// Codes are now strings, verify they are not empty
		testing.expect(t, len(fg_code) > 0, "Foreground code should not be empty")
		testing.expect(t, len(bg_code) > 0, "Background code should not be empty")
	}
}

@(test)
test_style_flags_empty :: proc(t: ^testing.T) {
	flags: ac.StyleFlags = {}

	testing.expect(t, card(flags) == 0, "Empty bit_set should have 0 elements")
	testing.expect(t, !(.Bold in flags), "Empty bit_set should not contain any flag")
}

@(test)
test_style_flags_all :: proc(t: ^testing.T) {
	flags: ac.StyleFlags = {
		.Bold,
		.Dim,
		.Italic,
		.Underline,
		.Blink,
		.Reverse,
		.Hidden,
		.Strikethrough,
	}

	testing.expect(t, card(flags) == 8, "Should have all 8 flags")
	testing.expect(t, .Bold in flags, "Should contain Bold")
	testing.expect(t, .Dim in flags, "Should contain Dim")
	testing.expect(t, .Italic in flags, "Should contain Italic")
	testing.expect(t, .Underline in flags, "Should contain Underline")
	testing.expect(t, .Blink in flags, "Should contain Blink")
	testing.expect(t, .Reverse in flags, "Should contain Reverse")
	testing.expect(t, .Hidden in flags, "Should contain Hidden")
	testing.expect(t, .Strikethrough in flags, "Should contain Strikethrough")
}

@(test)
test_generate_style_sequence_edge_cases :: proc(t: ^testing.T) {
	// Test with only flags
	seq1 := ac.generate_style_sequence(.Default, .Default, {.Bold, .Underline})
	testing.expect(t, strings.contains(seq1, "1"), "Should contain bold code")
	testing.expect(t, strings.contains(seq1, "4"), "Should contain underline code")

	// Test with only foreground
	seq2 := ac.generate_style_sequence(.Red, .Default, {})
	testing.expect(t, strings.contains(seq2, "31"), "Should contain red fg")

	// Test with only background
	seq3 := ac.generate_style_sequence(.Default, .Blue, {})
	testing.expect(t, strings.contains(seq3, "44"), "Should contain blue bg")
}

// === Event Edge Cases ===


@(test)
test_parse_empty_input :: proc(t: ^testing.T) {
	input: []u8
	event, parsed := at.parse_input(input)
	testing.expect(t, !parsed, "Empty input should not parse")
}

@(test)
test_parse_input_single_unrecognized :: proc(t: ^testing.T) {
	input: []u8 = {1, 2, 128, 255}

	for byte_val in input {
		single: []u8 = {byte_val}
		event, parsed := at.parse_input(single)
		// Most unrecognized bytes should not parse
		_ = event
		_ = parsed
	}
}

@(test)
test_parse_input_malformed_escape :: proc(t: ^testing.T) {
	// Malformed escape sequences
	inputs := [][]u8 {
		{27, '['}, // Incomplete
		{27, '[', '['}, // Double bracket
		{27, 'Z'}, // Invalid following char
		{27, '[', 'A', 'B'}, // Too long
	}

	for input in inputs {
		event, parsed := at.parse_input(input)
		_ = event
		// May or may not parse, but shouldn't crash
		_ = parsed
	}
}

@(test)
test_event_to_string_all_types :: proc(t: ^testing.T) {
	// Test at.event_to_string with all event types

	// at.KeyEvent
	key_event := at.KeyEvent {
		key  = .Char,
		rune = 'A',
	}
	str1 := at.event_to_string(key_event)
	testing.expect(t, len(str1) > 0, "at.KeyEvent string should not be empty")

	// at.ResizeEvent
	resize_event := at.ResizeEvent {
		width  = 80,
		height = 24,
	}
	str2 := at.event_to_string(resize_event)
	testing.expect(t, len(str2) > 0, "at.ResizeEvent string should not be empty")

	// at.MouseEvent
	mouse_event := at.MouseEvent {
		button  = .Left,
		x       = 10,
		y       = 20,
		pressed = true,
	}
	str3 := at.event_to_string(mouse_event)
	testing.expect(t, len(str3) > 0, "at.MouseEvent string should not be empty")
}

// === Layout Edge Cases ===

@(test)
test_layout_no_children :: proc(t: ^testing.T) {
	l_ctx := al.init_layout_context(context.allocator)
	defer al.destroy_layout_context(&l_ctx)

	root_rect := al.Rect{0, 0, 80, 24}
	al.reset_layout_context(&l_ctx, root_rect)

	// Add and immediately close container
	al.begin_container(&l_ctx, al.DEFAULT_LAYOUT_CONFIG)
	al.end_container(&l_ctx)

	al.finish_layout(&l_ctx)

	// Should not crash
	testing.expect(t, len(l_ctx.nodes) == 1, "Should have 1 node")
}

@(test)
test_layout_one_child :: proc(t: ^testing.T) {
	l_ctx := al.init_layout_context(context.allocator)
	defer al.destroy_layout_context(&l_ctx)

	root_rect := al.Rect{0, 0, 80, 24}
	al.reset_layout_context(&l_ctx, root_rect)

	al.begin_container(&l_ctx, al.DEFAULT_LAYOUT_CONFIG)
	al.add_text(&l_ctx, "Single", ac.default_style(), {sizing = {.X = al.grow(), .Y = al.grow()}})
	al.end_container(&l_ctx)

	al.finish_layout(&l_ctx)

	testing.expect(t, len(l_ctx.nodes) == 2, "Should have 2 nodes")
}

@(test)
test_layout_zero_sizing :: proc(t: ^testing.T) {
	l_ctx := al.init_layout_context(context.allocator)
	defer al.destroy_layout_context(&l_ctx)

	root_rect := al.Rect{0, 0, 80, 24}
	al.reset_layout_context(&l_ctx, root_rect)

	al.begin_container(&l_ctx, al.DEFAULT_LAYOUT_CONFIG)
	al.add_text(&l_ctx, "", ac.default_style(), {sizing = {.X = al.fixed(0), .Y = al.fixed(0)}})
	al.end_container(&l_ctx)

	al.finish_layout(&l_ctx)

	// Should not crash
	testing.expect(t, len(l_ctx.nodes) == 2, "Should have 2 nodes")
}

@(test)
test_layout_very_large_sizing :: proc(t: ^testing.T) {
	l_ctx := al.init_layout_context(context.allocator)
	defer al.destroy_layout_context(&l_ctx)

	root_rect := al.Rect{0, 0, 80, 24}
	al.reset_layout_context(&l_ctx, root_rect)

	al.begin_container(&l_ctx, al.DEFAULT_LAYOUT_CONFIG)
	al.add_text(&l_ctx, "Large", ac.default_style(), {sizing = {.X = al.fixed(10000), .Y = al.fixed(10000)}})
	al.end_container(&l_ctx)

	al.finish_layout(&l_ctx)

	// Should not crash, sizing will be clamped by container
	testing.expect(t, len(l_ctx.nodes) == 2, "Should have 2 nodes")
}

@(test)
test_layout_deep_nesting :: proc(t: ^testing.T) {
	l_ctx := al.init_layout_context(context.allocator)
	defer al.destroy_layout_context(&l_ctx)

	root_rect := al.Rect{0, 0, 80, 24}
	al.reset_layout_context(&l_ctx, root_rect)

	// Create deeply nested containers
	al.begin_container(&l_ctx, al.DEFAULT_LAYOUT_CONFIG)
	al.begin_container(&l_ctx, al.DEFAULT_LAYOUT_CONFIG)
	al.begin_container(&l_ctx, al.DEFAULT_LAYOUT_CONFIG)
	al.begin_container(&l_ctx, al.DEFAULT_LAYOUT_CONFIG)
	al.add_text(&l_ctx, "Deep", ac.default_style(), al.DEFAULT_LAYOUT_CONFIG)
	al.end_container(&l_ctx)
	al.end_container(&l_ctx)
	al.end_container(&l_ctx)
	al.end_container(&l_ctx)

	al.finish_layout(&l_ctx)

	testing.expect(t, len(l_ctx.nodes) == 5, "Should have 5 nodes")
}

// === Error Handling ===

@(test)
test_buffer_error_enum_values :: proc(t: ^testing.T) {
	// Test all ab.BufferError enum values
	errors := [?]ab.BufferError{.None, .InvalidDimensions, .OutOfBounds, .AllocationFailed}

	for err in errors {
		testing.expect(t, err == err, "Error should be comparable")
	}

	testing.expect(
		t,
		ab.BufferError.None != .InvalidDimensions,
		"Different errors should not be equal",
	)
}

@(test)
test_context_error_enum_values :: proc(t: ^testing.T) {
	// Test all ContextError enum values
	errors := [?]ContextError{.None, .TerminalInitFailed, .BufferInitFailed, .RawModeFailed}

	for err in errors {
		testing.expect(t, err == err, "Error should be comparable")
	}
}

@(test)
test_terminal_error_enum_values :: proc(t: ^testing.T) {
	// Test all at.TerminalError enum values
	errors := [?]at.TerminalError {
		.None,
		.FailedToGetAttributes,
		.FailedToSetAttributes,
		.FailedToWrite,
		.NotInitialized,
	}

	for err in errors {
		testing.expect(t, err == err, "Error should be comparable")
	}
}

// === Memory Edge Cases ===

@(test)
test_buffer_very_large :: proc(t: ^testing.T) {
	// Test allocating a very large buffer
	buffer, err := ab.init_buffer(500, 500, context.allocator)
	defer ab.destroy_buffer(&buffer)

	testing.expect(t, err == .None, "Large buffer allocation should succeed")
	testing.expect(t, buffer.width == 500, "Width should be 500")
	testing.expect(t, buffer.height == 500, "Height should be 500")
	testing.expect(t, len(buffer.cells) == 500 * 500, "Should have correct cell count")
}

@(test)
test_buffer_destroy_nil :: proc(t: ^testing.T) {
	// Test destroying buffer with nil cells
	// This should not crash
	nil_buffer: ab.FrameBuffer
	nil_buffer.cells = nil
	ab.destroy_buffer(&nil_buffer)
}

// === Unicode Edge Cases ===

@(test)
test_buffer_unicode_characters :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Test various Unicode characters
	unicode_chars := []rune{'é', 'ñ', 'ü', '©', '€', '日', '本', '語'}

	for idx in 0 ..< len(unicode_chars) {
		char := unicode_chars[idx]
		ab.set_cell(&buffer, idx, 0, char, .Red, .Blue, {})
		cell := ab.get_cell(&buffer, idx, 0)
		testing.expect(t, cell.rune == char, "Unicode char should be preserved")
	}
}

@(test)
test_buffer_box_drawing_chars :: proc(t: ^testing.T) {
	buffer, _ := ab.init_buffer(10, 10, context.allocator)
	defer ab.destroy_buffer(&buffer)

	// Test box-drawing Unicode characters
	box_chars := []rune{'┌', '┐', '└', '┘', '─', '│'}

	for idx in 0 ..< len(box_chars) {
		char := box_chars[idx]
		ab.set_cell(&buffer, idx, 0, char, .Red, .Blue, {})
		cell := ab.get_cell(&buffer, idx, 0)
		testing.expect(t, cell.rune == char, "Box char should be preserved")
	}
}

// === API Edge Cases ===

@(test)
test_context_shutdown_nil :: proc(t: ^testing.T) {
	// Test shutdown with nil context
	// This should not crash
	shutdown(nil)
}
