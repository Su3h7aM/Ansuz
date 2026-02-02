package ansuz

import "core:mem"
import "core:strings"
import "core:testing"

@(test)
test_buffer_init_destroy :: proc(t: ^testing.T) {
	buffer, err := init_buffer(80, 24, context.allocator)
	testing.expect(t, err == .None, "Buffer initialization should succeed")
	testing.expect(t, buffer.width == 80, "Buffer width should be 80")
	testing.expect(t, buffer.height == 24, "Buffer height should be 24")
	testing.expect(t, len(buffer.cells) == 80 * 24, "Buffer should have correct number of cells")

	destroy_buffer(&buffer)
	testing.expect(t, buffer.cells == nil, "Buffer cells should be nil after destroy")
	testing.expect(t, buffer.width == 0, "Buffer width should be 0 after destroy")
	testing.expect(t, buffer.height == 0, "Buffer height should be 0 after destroy")
}

@(test)
test_buffer_init_invalid_dimensions :: proc(t: ^testing.T) {
	buffer_zero_width, err1 := init_buffer(0, 24, context.allocator)
	testing.expect(t, err1 == .InvalidDimensions, "Zero width should return InvalidDimensions")
	testing.expect(t, buffer_zero_width.width == 0, "Zero width buffer should have width 0")

	buffer_zero_height, err2 := init_buffer(80, 0, context.allocator)
	testing.expect(t, err2 == .InvalidDimensions, "Zero height should return InvalidDimensions")

	buffer_negative_width, err3 := init_buffer(-10, 24, context.allocator)
	testing.expect(t, err3 == .InvalidDimensions, "Negative width should return InvalidDimensions")

	buffer_negative_height, err4 := init_buffer(80, -10, context.allocator)
	testing.expect(
		t,
		err4 == .InvalidDimensions,
		"Negative height should return InvalidDimensions",
	)
}

@(test)
test_buffer_clear :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	buffer.cells[0].rune = 'X'
	buffer.cells[0].fg = Ansi.Red

	clear_buffer(&buffer)

	testing.expect(t, buffer.cells[0].rune == ' ', "Cell should be space after clear")
	testing.expect(
		t,
		buffer.cells[0].fg == Ansi.Default,
		"Cell color should be default after clear",
	)
	testing.expect(t, buffer.cells[0].bg == Ansi.Default, "Cell bg should be default after clear")
	testing.expect(t, buffer.cells[0].style == {}, "Cell style should be empty after clear")
}

@(test)
test_buffer_get_cell :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	cell := get_cell(&buffer, 5, 5)
	testing.expect(t, cell != nil, "Should get valid cell at (5,5)")
	testing.expect(t, cell.rune == ' ', "Cell should have default rune")

	cell_out_x := get_cell(&buffer, 10, 5)
	testing.expect(t, cell_out_x == nil, "Should return nil for x >= width")

	cell_out_y := get_cell(&buffer, 5, 10)
	testing.expect(t, cell_out_y == nil, "Should return nil for y >= height")

	cell_neg_x := get_cell(&buffer, -1, 5)
	testing.expect(t, cell_neg_x == nil, "Should return nil for negative x")

	cell_neg_y := get_cell(&buffer, 5, -1)
	testing.expect(t, cell_neg_y == nil, "Should return nil for negative y")
}

@(test)
test_buffer_set_cell :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	err := set_cell(&buffer, 5, 5, 'A', Ansi.Red, Ansi.Blue, {.Bold})
	testing.expect(t, err == .None, "Setting valid cell should succeed")

	cell := get_cell(&buffer, 5, 5)
	testing.expect(t, cell.rune == 'A', "Cell should have correct rune")
	testing.expect(t, cell.fg == Ansi.Red, "Cell should have correct fg color")
	testing.expect(t, cell.bg == Ansi.Blue, "Cell should have correct bg color")
	testing.expect(t, .Bold in cell.style, "Cell should have bold style")

	err = set_cell(&buffer, 10, 5, 'B', Ansi.Red, Ansi.Blue, {})
	testing.expect(t, err == .OutOfBounds, "Setting out of bounds cell should return error")

	err = set_cell(&buffer, 5, 10, 'C', Ansi.Red, Ansi.Blue, {})
	testing.expect(t, err == .OutOfBounds, "Setting y out of bounds should return error")

	err = set_cell(&buffer, -1, 5, 'D', Ansi.Red, Ansi.Blue, {})
	testing.expect(t, err == .OutOfBounds, "Setting negative x should return error")
}

@(test)
test_buffer_set_cell_with_defaults :: proc(t: ^testing.T) {
	// Test set_cell with default values (replaces removed set_cell_simple)
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	err := set_cell(&buffer, 5, 5, 'X', Ansi.Default, Ansi.Default, {})
	testing.expect(t, err == .None, "Setting cell should succeed")

	cell := get_cell(&buffer, 5, 5)
	testing.expect(t, cell.rune == 'X', "Cell should have correct rune")
	testing.expect(t, cell.fg == Ansi.Default, "Cell should have default fg")
	testing.expect(t, cell.bg == Ansi.Default, "Cell should have default bg")
	testing.expect(t, cell.style == {}, "Cell should have no styles")
}

@(test)
test_buffer_write_string :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(20, 10, context.allocator)
	defer destroy_buffer(&buffer)

	chars := write_string(&buffer, 0, 0, "Hello, World!", Ansi.Red, Ansi.Blue, {})
	testing.expect(t, chars == 13, "Should write 13 characters")

	cell := get_cell(&buffer, 0, 0)
	testing.expect(t, cell.rune == 'H', "First char should be 'H'")
	testing.expect(t, cell.fg == Ansi.Red, "First char should have red fg")

	cell2 := get_cell(&buffer, 5, 0)
	testing.expect(t, cell2.rune == ',', "Fifth char should be comma")

	cell3 := get_cell(&buffer, 12, 0)
	testing.expect(t, cell3.rune == '!', "Last char should be '!'")
}

@(test)
test_buffer_write_string_bounds :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 5, context.allocator)
	defer destroy_buffer(&buffer)

	chars := write_string(&buffer, 0, 0, "0123456789", Ansi.Red, Ansi.Blue, {})
	testing.expect(t, chars == 10, "Should write all 10 chars")

	chars = write_string(&buffer, 0, 0, "01234567890", Ansi.Red, Ansi.Blue, {})
	testing.expect(t, chars == 10, "Should truncate to buffer width")

	chars = write_string(&buffer, 5, 0, "0123456789", Ansi.Red, Ansi.Blue, {})
	testing.expect(t, chars == 5, "Should write only 5 chars from x=5")

	chars = write_string(&buffer, -5, 0, "ABC", Ansi.Red, Ansi.Blue, {})
	testing.expect(t, chars == 0, "Should write 0 chars with negative x starting outside buffer")
}

@(test)
test_buffer_write_string_out_of_bounds_y :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 5, context.allocator)
	defer destroy_buffer(&buffer)

	chars := write_string(&buffer, 0, 5, "Test", Ansi.Red, Ansi.Blue, {})
	testing.expect(t, chars == 0, "Should write 0 chars for y >= height")

	chars = write_string(&buffer, 0, 10, "Test", Ansi.Red, Ansi.Blue, {})
	testing.expect(t, chars == 0, "Should write 0 chars for y > height")

	chars = write_string(&buffer, 0, -1, "Test", Ansi.Red, Ansi.Blue, {})
	testing.expect(t, chars == 0, "Should write 0 chars for negative y")
}

@(test)
test_buffer_write_string_empty :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 5, context.allocator)
	defer destroy_buffer(&buffer)

	chars := write_string(&buffer, 0, 0, "", Ansi.Red, Ansi.Blue, {})
	testing.expect(t, chars == 0, "Empty string should write 0 chars")
}

@(test)
test_buffer_fill_rect :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(20, 20, context.allocator)
	defer destroy_buffer(&buffer)

	fill_rect(&buffer, 5, 5, 10, 5, 'X', Ansi.Red, Ansi.Blue, {.Bold})

	for y in 5 ..< 10 {
		for x in 5 ..< 15 {
			cell := get_cell(&buffer, x, y)
			testing.expect(t, cell != nil, "Cell should exist")
			testing.expect(t, cell.rune == 'X', "Cell should have 'X'")
			testing.expect(t, cell.fg == Ansi.Red, "Cell should have red fg")
			testing.expect(t, cell.bg == Ansi.Blue, "Cell should have blue bg")
			testing.expect(t, .Bold in cell.style, "Cell should be bold")
		}
	}

	outside := get_cell(&buffer, 4, 5)
	testing.expect(t, outside.rune != 'X', "Cells outside rect should not be modified")

	outside = get_cell(&buffer, 15, 5)
	testing.expect(t, outside.rune != 'X', "Cells outside rect should not be modified")
}

@(test)
test_buffer_draw_box :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(20, 10, context.allocator)
	defer destroy_buffer(&buffer)

	draw_box(&buffer, 5, 3, 10, 5, Ansi.Red, Ansi.Blue, {})

	testing.expect_value(t, get_cell(&buffer, 5, 3).rune, '┌')
	testing.expect_value(t, get_cell(&buffer, 14, 3).rune, '┐')
	testing.expect_value(t, get_cell(&buffer, 5, 7).rune, '└')
	testing.expect_value(t, get_cell(&buffer, 14, 7).rune, '┘')

	for x in 6 ..< 14 {
		testing.expect_value(t, get_cell(&buffer, x, 3).rune, '─')
		testing.expect_value(t, get_cell(&buffer, x, 7).rune, '─')
	}

	for y in 4 ..< 7 {
		testing.expect_value(t, get_cell(&buffer, 5, y).rune, '│')
		testing.expect_value(t, get_cell(&buffer, 14, y).rune, '│')
	}
}

@(test)
test_buffer_draw_box_too_small :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(20, 10, context.allocator)
	defer destroy_buffer(&buffer)

	draw_box(&buffer, 5, 3, 1, 5, Ansi.Red, Ansi.Blue, {})
	draw_box(&buffer, 5, 3, 5, 1, Ansi.Red, Ansi.Blue, {})

	center := get_cell(&buffer, 5, 3)
	testing.expect(t, center.rune != '┌', "Too small box should not draw")
}

@(test)
test_buffer_render_to_string :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(5, 3, context.allocator)
	defer destroy_buffer(&buffer)

	write_string(&buffer, 0, 0, "ABC", Ansi.Red, Ansi.Blue, {})

	builder := strings.builder_make(context.temp_allocator)
	defer strings.builder_destroy(&builder)

	output := render_to_string(&buffer, &builder)
	testing.expect(t, len(output) > 0, "Render output should not be empty")
	testing.expect(
		t,
		strings.contains(output, "\x1b[1;1H"),
		"Output should contain absolute positioning",
	)
}

@(test)
test_buffer_resize :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	set_cell(&buffer, 5, 5, 'X', Ansi.Red, Ansi.Blue, {})
	set_cell(&buffer, 9, 9, 'Y', Ansi.Green, Ansi.Yellow, {})

	err := resize_buffer(&buffer, 20, 15)
	testing.expect(t, err == .None, "Resize should succeed")
	testing.expect(t, buffer.width == 20, "Width should be updated")
	testing.expect(t, buffer.height == 15, "Height should be updated")

	cell := get_cell(&buffer, 5, 5)
	testing.expect(t, cell.rune == 'X', "Content should be preserved")
	testing.expect(t, cell.fg == Ansi.Red, "Color should be preserved")

	cell = get_cell(&buffer, 9, 9)
	testing.expect(t, cell.rune == 'Y', "Content should be preserved")

	cell = get_cell(&buffer, 15, 12)
	testing.expect(t, cell.rune == ' ', "New area should be empty")
}

@(test)
test_buffer_resize_invalid :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	err := resize_buffer(&buffer, 0, 15)
	testing.expect(t, err == .InvalidDimensions, "Resize to zero width should fail")

	err = resize_buffer(&buffer, 20, 0)
	testing.expect(t, err == .InvalidDimensions, "Resize to zero height should fail")

	err = resize_buffer(&buffer, -10, 15)
	testing.expect(t, err == .InvalidDimensions, "Resize to negative width should fail")

	testing.expect(t, buffer.width == 10, "Width should remain unchanged")
	testing.expect(t, buffer.height == 10, "Height should remain unchanged")
}

@(test)
test_buffer_resize_smaller :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	for y in 0 ..< 5 {
		for x in 0 ..< 5 {
			set_cell(&buffer, x, y, 'A', Ansi.Red, Ansi.Blue, {})
		}
	}

	err := resize_buffer(&buffer, 5, 5)
	testing.expect(t, err == .None, "Resize to smaller should succeed")
	testing.expect(t, buffer.width == 5, "Width should be 5")
	testing.expect(t, buffer.height == 5, "Height should be 5")

	for y in 0 ..< 5 {
		for x in 0 ..< 5 {
			cell := get_cell(&buffer, x, y)
			testing.expect(t, cell.rune == 'A', "Preserved content should be 'A'")
		}
	}
}

@(test)
test_buffer_cell_index_calculation :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	set_cell(&buffer, 0, 0, 'A', Ansi.Red, Ansi.Blue, {})
	testing.expect(t, buffer.cells[0].rune == 'A', "Cell at (0,0) should be at index 0")

	set_cell(&buffer, 5, 0, 'B', Ansi.Red, Ansi.Blue, {})
	testing.expect(t, buffer.cells[5].rune == 'B', "Cell at (5,0) should be at index 5")

	set_cell(&buffer, 0, 1, 'C', Ansi.Red, Ansi.Blue, {})
	testing.expect(t, buffer.cells[10].rune == 'C', "Cell at (0,1) should be at index 10")

	set_cell(&buffer, 9, 9, 'D', Ansi.Red, Ansi.Blue, {})
	testing.expect(t, buffer.cells[99].rune == 'D', "Cell at (9,9) should be at index 99")
}

@(test)
test_buffer_multiple_styles :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	styles: StyleFlags = {.Bold, .Underline, .Dim}
	set_cell(&buffer, 5, 5, 'X', Ansi.Red, Ansi.Blue, styles)

	cell := get_cell(&buffer, 5, 5)
	testing.expect(t, .Bold in cell.style, "Cell should have Bold")
	testing.expect(t, .Underline in cell.style, "Cell should have Underline")
	testing.expect(t, .Dim in cell.style, "Cell should have Dim")
}

@(test)
test_buffer_large_dimensions :: proc(t: ^testing.T) {
	buffer, err := init_buffer(200, 100, context.allocator)
	defer destroy_buffer(&buffer)

	testing.expect(t, err == .None, "Large buffer initialization should succeed")
	testing.expect(
		t,
		len(buffer.cells) == 200 * 100,
		"Large buffer should have correct cell count",
	)

	set_cell(&buffer, 199, 99, 'X', Ansi.Red, Ansi.Blue, {})
	cell := get_cell(&buffer, 199, 99)
	testing.expect(t, cell.rune == 'X', "Should set cell at edge of large buffer")
}

@(test)
test_buffer_write_multiple_lines :: proc(t: ^testing.T) {
	buffer, _ := init_buffer(10, 3, context.allocator)
	defer destroy_buffer(&buffer)

	write_string(&buffer, 0, 0, "Line0", Ansi.Red, Ansi.Blue, {})
	write_string(&buffer, 0, 1, "Line1", Ansi.Red, Ansi.Blue, {})
	write_string(&buffer, 0, 2, "Line2", Ansi.Red, Ansi.Blue, {})

	cell := get_cell(&buffer, 0, 0)
	testing.expect(t, cell.rune == 'L', "First char of line 0 should be 'L'")

	cell = get_cell(&buffer, 0, 1)
	testing.expect(t, cell.rune == 'L', "First char of line 1 should be 'L'")

	cell = get_cell(&buffer, 0, 2)
	testing.expect(t, cell.rune == 'L', "First char of line 2 should be 'L'")
}

@(test)
test_buffer_get_cell_returns_nil_out_of_bounds :: proc(t: ^testing.T) {
	// Test that get_cell returns nil for out-of-bounds access
	// Users should check for nil before dereferencing
	buffer, _ := init_buffer(10, 10, context.allocator)
	defer destroy_buffer(&buffer)

	cell := get_cell(&buffer, 100, 100)
	testing.expect(t, cell == nil, "Should return nil for way out of bounds")

	cell = get_cell(&buffer, -5, -5)
	testing.expect(t, cell == nil, "Should return nil for negative indices")
}
