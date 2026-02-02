package ansuz

import "core:fmt"
import "core:mem"
import "core:strings"

// Cell represents a single character cell in the terminal
// Each cell has a character, colors, and style attributes
Cell :: struct {
	rune:  rune, // Unicode character to display
	fg:    TerminalColor, // Foreground (text) color
	bg:    TerminalColor, // Background color
	style: StyleFlags, // Text attributes (bold, underline, etc.)
}

// FrameBuffer is a 2D grid representing the terminal screen
// It uses a flat array for cache-friendly access: cells[y * width + x]
FrameBuffer :: struct {
	width:     int,
	height:    int,
	cells:     []Cell,
	allocator: mem.Allocator,
	clip_rect: Rect, // x, y, w, h. If w/h <= 0, clipping is disabled.
}

// BufferError represents errors that can occur during buffer operations
BufferError :: enum {
	None,
	InvalidDimensions,
	OutOfBounds,
	AllocationFailed,
}

// BoxStyle defines the style of box border characters
BoxStyle :: enum {
	Sharp, // ┌─┐│└┘ (default)
	Rounded, // ╭╮╰╯─│
	Double, // ╔═╗║╚╝
}

// init_buffer creates a new FrameBuffer with the specified dimensions
// All cells are initialized with default values (space character, default colors)
init_buffer :: proc(
	width, height: int,
	allocator := context.allocator,
) -> (
	buffer: FrameBuffer,
	err: BufferError,
) {
	if width <= 0 || height <= 0 {
		return buffer, .InvalidDimensions
	}

	buffer.width = width
	buffer.height = height
	buffer.allocator = allocator

	// Allocate the cell array
	buffer.cells = make([]Cell, width * height, allocator)
	if len(buffer.cells) != width * height {
		return buffer, .AllocationFailed
	}

	// Initialize all cells to default state
	clear_buffer(&buffer)
	clear_clip_rect(&buffer)

	return buffer, .None
}

// set_clip_rect sets the clipping region. Only drawing within this rect will occur.
set_clip_rect :: proc(buffer: ^FrameBuffer, rect: Rect) {
	buffer.clip_rect = rect
}

// clear_clip_rect disables clipping checks (sets clip rect to full buffer)
clear_clip_rect :: proc(buffer: ^FrameBuffer) {
	buffer.clip_rect = Rect{0, 0, buffer.width, buffer.height}
}

// _is_clipped checks if a point is outside the current clip rect
_is_clipped :: proc(buffer: ^FrameBuffer, x, y: int) -> bool {
	// If clip rect has no area (or inverted), valid range is empty -> everything is clipped
	// But we use width/height check instead.

	// Check clip rect bounds
	if x < buffer.clip_rect.x || x >= buffer.clip_rect.x + buffer.clip_rect.w {
		return true
	}
	if y < buffer.clip_rect.y || y >= buffer.clip_rect.y + buffer.clip_rect.h {
		return true
	}
	return false
}

// destroy_buffer frees the memory used by a FrameBuffer
destroy_buffer :: proc(buffer: ^FrameBuffer) {
	if buffer.cells != nil {
		delete(buffer.cells, buffer.allocator)
		buffer.cells = nil
	}
	buffer.width = 0
	buffer.height = 0
}

// clear_buffer resets all cells to default state
// Sets all cells to space character with default colors
clear_buffer :: proc(buffer: ^FrameBuffer) {
	for &cell in buffer.cells {
		cell.rune = ' '
		cell.fg = Ansi.Default
		cell.bg = Ansi.Default
		cell.style = {}
	}
}

// get_cell returns a pointer to the cell at the specified position
// Returns nil if the position is out of bounds
get_cell :: proc(buffer: ^FrameBuffer, x, y: int) -> ^Cell {
	if x < 0 || x >= buffer.width || y < 0 || y >= buffer.height {
		return nil
	}
	index := y * buffer.width + x
	return &buffer.cells[index]
}



// set_cell sets the character and style for a cell at the specified position
set_cell :: proc(
	buffer: ^FrameBuffer,
	x, y: int,
	r: rune,
	fg, bg: TerminalColor,
	style: StyleFlags,
) -> BufferError {
	cell := get_cell(buffer, x, y)
	if cell == nil {
		return .OutOfBounds
	}

	if _is_clipped(buffer, x, y) {
		return .None // Clipped out, not an error
	}

	cell.rune = r
	cell.fg = fg
	cell.bg = bg
	cell.style = style

	return .None
}



// write_string writes a string to the buffer starting at the specified position
// Returns the number of characters written (may be less than string length if out of bounds)
write_string :: proc(
	buffer: ^FrameBuffer,
	x, y: int,
	text: string,
	fg, bg: TerminalColor,
	style: StyleFlags,
) -> int {
	chars_written := 0
	current_x := x

	// Check bounds once
	if y < 0 || y >= buffer.height {
		return 0
	}

	for r in text {
		if current_x >= buffer.width {
			break // Reached end of line
		}

		if current_x >= 0 {
			// Check clipping
			if !_is_clipped(buffer, current_x, y) {
				// Direct array access - faster than set_cell()
				index := y * buffer.width + current_x
				buffer.cells[index].rune = r
				buffer.cells[index].fg = fg
				buffer.cells[index].bg = bg
				buffer.cells[index].style = style
				chars_written += 1
			}
		}

		current_x += 1
	}

	return chars_written
}

// measure_text_wrapped calculates the dimensions of text if it were wrapped
// Returns: width (max line width), height (number of lines)
measure_text_wrapped :: proc(text: string, max_width: int) -> (width, height: int) {
	if len(text) == 0 {
		return 0, 0
	}
	if max_width <= 0 {
		return 0, 0 // Or decide if 0 width means everything is hidden
	}

	max_line_w := 0
	line_count := 1
	current_line_w := 0

	// iterate by words
	// simplistic approach: split by space.
	// robust approach: iterate rune by rune, tracking last space.

	last_space_idx := -1
	line_start_idx := 0
	current_idx := 0

	// We'll iterate words for simplicity and standard behavior
	// "Hello World" max 5 -> "Hello" (5), "World" (5)

	words := strings.split(text, " ")
	defer delete(words)

	for word, i in words {
		word_len := len(word)

		// If this is not the first word on the line, we need a space
		space_needed := current_line_w > 0 ? 1 : 0

		if current_line_w + space_needed + word_len <= max_width {
			// Fits on current line
			current_line_w += space_needed + word_len
		} else {
			// Must wrap
			max_line_w = max(max_line_w, current_line_w)
			line_count += 1
			current_line_w = word_len

			// Edge case: Word itself is wider than max_width
			// We force it to wrap but it will just overflow effectively or take full width
			if current_line_w > max_width {
				current_line_w = max_width
				// In reality it would clip, but for metric we treat it as taking full line
				// Or we could split the word? For now, stick to standard word wrap.
			}
		}
	}

	max_line_w = max(max_line_w, current_line_w)

	return max_line_w, line_count
}

// write_string_wrapped writes text with automatic word wrapping
write_string_wrapped :: proc(
	buffer: ^FrameBuffer,
	x, y: int,
	max_width: int,
	text: string,
	fg, bg: TerminalColor,
	style: StyleFlags,
) -> int {
	if max_width <= 0 {
		return 0
	}

	words := strings.split(text, " ")
	defer delete(words)

	current_x := x
	current_y := y

	chars_written := 0

	for word, i in words {
		word_len := len(word)

		// If this is not the first word on the line, we check space
		space_needed := current_x > x ? 1 : 0

		// Check if word fits
		remaining_space := max_width - (current_x - x)

		if space_needed + word_len > remaining_space {
			// Wrap to next line
			current_y += 1
			current_x = x
			space_needed = 0 // New line, no leading space
		}

		// Write space if needed
		if space_needed > 0 {
			_ = set_cell(buffer, current_x, current_y, ' ', fg, bg, style)
			current_x += 1
			chars_written += 1
		}

		// Write word
		// If word itself is longer than max_width, it will be clipped by set_cell internally (via clip rect or bounds)
		// But we should just write it out.
		written := write_string(buffer, current_x, current_y, word, fg, bg, style)
		chars_written += written
		current_x += word_len
	}

	return chars_written
}

// fill_rect fills a rectangular region with a character and style
fill_rect :: proc(
	buffer: ^FrameBuffer,
	x, y, width, height: int,
	r: rune,
	fg, bg: TerminalColor,
	style: StyleFlags,
) {
	for dy in 0 ..< height {
		for dx in 0 ..< width {
			set_cell(buffer, x + dx, y + dy, r, fg, bg, style)
		}
	}
}

// draw_box draws a box border using box-drawing characters
// Uses Unicode box-drawing characters for clean borders
// Box style can be Sharp (┌─┐│└┘), Rounded (╭╮╰╯─│), or Double (╔═╗║╚╝)
draw_box :: proc(
	buffer: ^FrameBuffer,
	x, y, width, height: int,
	fg, bg: TerminalColor,
	style: StyleFlags,
	box_style: BoxStyle = .Sharp,
) {
	if width < 2 || height < 2 {
		return // Too small to draw a box
	}

	// Box drawing characters based on style
	TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT, HORIZONTAL, VERTICAL: rune
	switch box_style {
	case .Sharp:
		TOP_LEFT = '┌'
		TOP_RIGHT = '┐'
		BOTTOM_LEFT = '└'
		BOTTOM_RIGHT = '┘'
		HORIZONTAL = '─'
		VERTICAL = '│'
	case .Rounded:
		TOP_LEFT = '╭'
		TOP_RIGHT = '╮'
		BOTTOM_LEFT = '╰'
		BOTTOM_RIGHT = '╯'
		HORIZONTAL = '─'
		VERTICAL = '│'
	case .Double:
		TOP_LEFT = '╔'
		TOP_RIGHT = '╗'
		BOTTOM_LEFT = '╚'
		BOTTOM_RIGHT = '╝'
		HORIZONTAL = '═'
		VERTICAL = '║'
	}

	// Corners - direct array access for speed (with clipping check)
	if x >= 0 && x < buffer.width && y >= 0 && y < buffer.height && !_is_clipped(buffer, x, y) {
		index := y * buffer.width + x
		buffer.cells[index].rune = TOP_LEFT
		buffer.cells[index].fg = fg
		buffer.cells[index].bg = bg
		buffer.cells[index].style = style
	}
	if x + width - 1 >= 0 &&
	   x + width - 1 < buffer.width &&
	   y >= 0 &&
	   y < buffer.height &&
	   !_is_clipped(buffer, x + width - 1, y) {
		index := y * buffer.width + (x + width - 1)
		buffer.cells[index].rune = TOP_RIGHT
		buffer.cells[index].fg = fg
		buffer.cells[index].bg = bg
		buffer.cells[index].style = style
	}
	if x >= 0 &&
	   x < buffer.width &&
	   y + height - 1 >= 0 &&
	   y + height - 1 < buffer.height &&
	   !_is_clipped(buffer, x, y + height - 1) {
		index := (y + height - 1) * buffer.width + x
		buffer.cells[index].rune = BOTTOM_LEFT
		buffer.cells[index].fg = fg
		buffer.cells[index].bg = bg
		buffer.cells[index].style = style
	}
	if x + width - 1 >= 0 &&
	   x + width - 1 < buffer.width &&
	   y + height - 1 >= 0 &&
	   y + height - 1 < buffer.height &&
	   !_is_clipped(buffer, x + width - 1, y + height - 1) {
		index := (y + height - 1) * buffer.width + (x + width - 1)
		buffer.cells[index].rune = BOTTOM_RIGHT
		buffer.cells[index].fg = fg
		buffer.cells[index].bg = bg
		buffer.cells[index].style = style
	}

	// Top and bottom edges - direct array access
	for dx in 1 ..< width - 1 {
		px := x + dx
		if px >= 0 &&
		   px < buffer.width &&
		   y >= 0 &&
		   y < buffer.height &&
		   !_is_clipped(buffer, px, y) {
			index := y * buffer.width + px
			buffer.cells[index].rune = HORIZONTAL
			buffer.cells[index].fg = fg
			buffer.cells[index].bg = bg
			buffer.cells[index].style = style
		}
		if px >= 0 &&
		   px < buffer.width &&
		   y + height - 1 >= 0 &&
		   y + height - 1 < buffer.height &&
		   !_is_clipped(buffer, px, y + height - 1) {
			index := (y + height - 1) * buffer.width + px
			buffer.cells[index].rune = HORIZONTAL
			buffer.cells[index].fg = fg
			buffer.cells[index].bg = bg
			buffer.cells[index].style = style
		}
	}

	// Left and right edges - direct array access
	for dy in 1 ..< height - 1 {
		py := y + dy
		if x >= 0 &&
		   x < buffer.width &&
		   py >= 0 &&
		   py < buffer.height &&
		   !_is_clipped(buffer, x, py) {
			index := py * buffer.width + x
			buffer.cells[index].rune = VERTICAL
			buffer.cells[index].fg = fg
			buffer.cells[index].bg = bg
			buffer.cells[index].style = style
		}
		if x + width - 1 >= 0 &&
		   x + width - 1 < buffer.width &&
		   py >= 0 &&
		   py < buffer.height &&
		   !_is_clipped(buffer, x + width - 1, py) {
			index := py * buffer.width + (x + width - 1)
			buffer.cells[index].rune = VERTICAL
			buffer.cells[index].fg = fg
			buffer.cells[index].bg = bg
			buffer.cells[index].style = style
		}
	}
}

// render_to_string converts the entire buffer to a string with ANSI codes
// Renders the complete buffer every frame (immediate mode)
// optional max_width/height allow clipping to actual terminal size to prevent scrolling on shrink
// Builder is reused to avoid per-frame allocations - caller should reset before calling
render_to_string :: proc(
	buffer: ^FrameBuffer,
	builder: ^strings.Builder,
	max_width: int = -1,
	max_height: int = -1,
) -> string {
	// Reset and reuse builder
	strings.builder_reset(builder)

	// Clear string builder with standard clear logic if needed, or just start new
	// builder is new here so it's empty.

	current_style := default_style()
	needs_style_reset := false

	// Determine render limits
	render_w := buffer.width
	if max_width >= 0 && max_width < render_w {
		render_w = max_width
	}

	render_h := buffer.height
	if max_height >= 0 && max_height < render_h {
		render_h = max_height
	}

	for y in 0 ..< render_h {
		// ABSOLUTE POSITIONING STRATEGY
		// Instead of writing a newline, we explicitly move the cursor to the start of the current line.
		// This prevents the terminal from scrolling if we accidentally write to the last line
		// when the terminal has shrunk.
		// Format: ESC [ <y+1> ; 1 H  (1-based coordinates)
		fmt.sbprintf(builder, "\x1b[%d;1H", y + 1)

		for x in 0 ..< render_w {
			cell := get_cell(buffer, x, y)

			if cell == nil {
				// Out of bounds - write space with default style
				if current_style != default_style() {
					style_seq := to_ansi(default_style())
					strings.write_string(builder, style_seq)
					current_style = default_style()
					needs_style_reset = true
				}
				strings.write_rune(builder, ' ')
			} else {

				// Generate style sequence if style changed
				new_style := Style {
					fg    = cell.fg,
					bg    = cell.bg,
					flags = cell.style,
				}

				if new_style != current_style {
					style_seq := to_ansi(new_style)
					strings.write_string(builder, style_seq)
					current_style = new_style
					needs_style_reset = true
				}

				// Write the character
				strings.write_rune(builder, cell.rune)
			}
		}
		// No newline emission here!
	}

	// Reset style at the end
	if needs_style_reset {
		strings.write_string(builder, reset_style())
	}

	return strings.to_string(builder^)
}

// resize_buffer changes the dimensions of an existing buffer
// Preserves as much content as possible
resize_buffer :: proc(buffer: ^FrameBuffer, new_width, new_height: int) -> BufferError {
	if new_width <= 0 || new_height <= 0 {
		return .InvalidDimensions
	}

	// Create new cell array
	new_cells := make([]Cell, new_width * new_height, buffer.allocator)
	if new_cells == nil {
		return .AllocationFailed
	}

	// Initialize new cells
	for &cell in new_cells {
		cell.rune = ' '
		cell.fg = Ansi.Default
		cell.bg = Ansi.Default
		cell.style = {}
	}

	// Copy old content (as much as fits)
	copy_width := min(buffer.width, new_width)
	copy_height := min(buffer.height, new_height)

	for y in 0 ..< copy_height {
		for x in 0 ..< copy_width {
			old_index := y * buffer.width + x
			new_index := y * new_width + x
			new_cells[new_index] = buffer.cells[old_index]
		}
	}

	// Replace old buffer
	delete(buffer.cells, buffer.allocator)
	buffer.cells = new_cells
	buffer.width = new_width
	buffer.height = new_height

	return .None
}
