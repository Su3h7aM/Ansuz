package ansuz

import "core:mem"
import "core:fmt"
import "core:strings"

// Cell represents a single character cell in the terminal
// Each cell has a character, colors, and style attributes
Cell :: struct {
    rune:     rune,        // Unicode character to display
    fg_color: Color,       // Foreground (text) color
    bg_color: Color,       // Background color
    style:    StyleFlags,  // Text attributes (bold, underline, etc.)
    dirty:    bool,        // Changed since last render
}

// FrameBuffer is a 2D grid representing the terminal screen
// It uses a flat array for cache-friendly access: cells[y * width + x]
FrameBuffer :: struct {
    width:     int,
    height:    int,
    cells:     []Cell,
    allocator: mem.Allocator,
}

// BufferError represents errors that can occur during buffer operations
BufferError :: enum {
    None,
    InvalidDimensions,
    OutOfBounds,
    AllocationFailed,
}

// init_buffer creates a new FrameBuffer with the specified dimensions
// All cells are initialized with default values (space character, default colors)
init_buffer :: proc(width, height: int, allocator := context.allocator) -> (buffer: FrameBuffer, err: BufferError) {
    if width <= 0 || height <= 0 {
        return buffer, .InvalidDimensions
    }

    buffer.width = width
    buffer.height = height
    buffer.allocator = allocator

    // Allocate the cell array
    buffer.cells = make([]Cell, width * height, allocator) or_return
    if buffer.cells == nil {
        return buffer, .AllocationFailed
    }

    // Initialize all cells to default state
    clear_buffer(&buffer)

    return buffer, .None
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
        cell.fg_color = .Default
        cell.bg_color = .Default
        cell.style = {}
        cell.dirty = true // Mark as dirty to force redraw
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

// get_cell_safe returns a copy of the cell at the specified position
// Returns a default cell if the position is out of bounds
get_cell_safe :: proc(buffer: ^FrameBuffer, x, y: int) -> Cell {
    cell := get_cell(buffer, x, y)
    if cell == nil {
        return Cell{rune = ' ', fg_color = .Default, bg_color = .Default}
    }
    return cell^
}

// set_cell sets the character and style for a cell at the specified position
// Marks the cell as dirty if any values changed
set_cell :: proc(buffer: ^FrameBuffer, x, y: int, r: rune, fg, bg: Color, style: StyleFlags) -> BufferError {
    cell := get_cell(buffer, x, y)
    if cell == nil {
        return .OutOfBounds
    }

    // Check if anything changed to avoid unnecessary dirty marking
    changed := cell.rune != r || 
               cell.fg_color != fg || 
               cell.bg_color != bg || 
               cell.style != style

    if changed {
        cell.rune = r
        cell.fg_color = fg
        cell.bg_color = bg
        cell.style = style
        cell.dirty = true
    }

    return .None
}

// set_cell_simple sets just the character at a position (using default styling)
set_cell_simple :: proc(buffer: ^FrameBuffer, x, y: int, r: rune) -> BufferError {
    return set_cell(buffer, x, y, r, .Default, .Default, {})
}

// write_string writes a string to the buffer starting at the specified position
// Returns the number of characters written (may be less than string length if out of bounds)
write_string :: proc(buffer: ^FrameBuffer, x, y: int, text: string, fg, bg: Color, style: StyleFlags) -> int {
    chars_written := 0
    current_x := x

    for r in text {
        if current_x >= buffer.width {
            break // Reached end of line
        }

        if current_x >= 0 && y >= 0 && y < buffer.height {
            set_cell(buffer, current_x, y, r, fg, bg, style)
            chars_written += 1
        }

        current_x += 1
    }

    return chars_written
}

// fill_rect fills a rectangular region with a character and style
fill_rect :: proc(buffer: ^FrameBuffer, x, y, width, height: int, r: rune, fg, bg: Color, style: StyleFlags) {
    for dy in 0..<height {
        for dx in 0..<width {
            set_cell(buffer, x + dx, y + dy, r, fg, bg, style)
        }
    }
}

// draw_box draws a box border using box-drawing characters
// Uses Unicode box-drawing characters for clean borders
draw_box :: proc(buffer: ^FrameBuffer, x, y, width, height: int, fg, bg: Color, style: StyleFlags) {
    if width < 2 || height < 2 {
        return // Too small to draw a box
    }

    // Box drawing characters
    TOP_LEFT :: '┌'
    TOP_RIGHT :: '┐'
    BOTTOM_LEFT :: '└'
    BOTTOM_RIGHT :: '┘'
    HORIZONTAL :: '─'
    VERTICAL :: '│'

    // Corners
    set_cell(buffer, x, y, TOP_LEFT, fg, bg, style)
    set_cell(buffer, x + width - 1, y, TOP_RIGHT, fg, bg, style)
    set_cell(buffer, x, y + height - 1, BOTTOM_LEFT, fg, bg, style)
    set_cell(buffer, x + width - 1, y + height - 1, BOTTOM_RIGHT, fg, bg, style)

    // Top and bottom edges
    for dx in 1..<width-1 {
        set_cell(buffer, x + dx, y, HORIZONTAL, fg, bg, style)
        set_cell(buffer, x + dx, y + height - 1, HORIZONTAL, fg, bg, style)
    }

    // Left and right edges
    for dy in 1..<height-1 {
        set_cell(buffer, x, y + dy, VERTICAL, fg, bg, style)
        set_cell(buffer, x + width - 1, y + dy, VERTICAL, fg, bg, style)
    }
}

// clear_dirty_flags resets the dirty flag on all cells
// Should be called after rendering to terminal
clear_dirty_flags :: proc(buffer: ^FrameBuffer) {
    for &cell in buffer.cells {
        cell.dirty = false
    }
}

// cells_equal compares two cells for equality (ignoring dirty flag)
cells_equal :: proc(a, b: Cell) -> bool {
    return a.rune == b.rune &&
           a.fg_color == b.fg_color &&
           a.bg_color == b.bg_color &&
           a.style == b.style
}

// render_to_string converts the entire buffer to a string with ANSI codes
// This is a simple renderer that outputs the entire buffer
// For production, use a diffing renderer that only outputs changed cells
render_to_string :: proc(buffer: ^FrameBuffer, allocator := context.temp_allocator) -> string {
    builder := strings.builder_make(allocator)

    // Start from home position
    strings.write_string(&builder, "\x1b[H")

    current_style := default_style()
    needs_style_reset := false

    for y in 0..<buffer.height {
        for x in 0..<buffer.width {
            cell := get_cell_safe(buffer, x, y)

            // Generate style sequence if style changed
            new_style := Style{
                fg_color = cell.fg_color,
                bg_color = cell.bg_color,
                flags = cell.style,
            }

            if new_style != current_style {
                style_seq := to_ansi(new_style)
                strings.write_string(&builder, style_seq)
                current_style = new_style
                needs_style_reset = true
            }

            // Write the character
            strings.write_rune(&builder, cell.rune)
        }

        // Move to next line (unless it's the last line)
        if y < buffer.height - 1 {
            strings.write_string(&builder, "\r\n")
        }
    }

    // Reset style at the end
    if needs_style_reset {
        strings.write_string(&builder, reset_style())
    }

    return strings.to_string(builder)
}

// render_diff generates ANSI output for only the changed cells
// This is much more efficient than rendering the entire buffer
render_diff :: proc(new_buffer, old_buffer: ^FrameBuffer, allocator := context.temp_allocator) -> string {
    if new_buffer.width != old_buffer.width || new_buffer.height != old_buffer.height {
        // Dimensions changed, fall back to full render
        return render_to_string(new_buffer, allocator)
    }

    builder := strings.builder_make(allocator)
    
    current_style := default_style()
    cursor_x := 0
    cursor_y := 0

    for y in 0..<new_buffer.height {
        for x in 0..<new_buffer.width {
            new_cell := get_cell_safe(new_buffer, x, y)
            old_cell := get_cell_safe(old_buffer, x, y)

            // Skip if cell hasn't changed
            if cells_equal(new_cell, old_cell) && !new_cell.dirty {
                continue
            }

            // Move cursor if needed (1-indexed for ANSI)
            if cursor_x != x || cursor_y != y {
                move_seq := fmt.tprintf("\x1b[%d;%dH", y + 1, x + 1)
                strings.write_string(&builder, move_seq)
                cursor_x = x
                cursor_y = y
            }

            // Update style if needed
            new_style := Style{
                fg_color = new_cell.fg_color,
                bg_color = new_cell.bg_color,
                flags = new_cell.style,
            }

            if new_style != current_style {
                style_seq := to_ansi(new_style)
                strings.write_string(&builder, style_seq)
                current_style = new_style
            }

            // Write the character
            strings.write_rune(&builder, new_cell.rune)
            cursor_x += 1
        }
    }

    // Reset style at the end
    strings.write_string(&builder, reset_style())

    return strings.to_string(builder)
}

// resize_buffer changes the dimensions of an existing buffer
// Preserves as much content as possible
resize_buffer :: proc(buffer: ^FrameBuffer, new_width, new_height: int) -> BufferError {
    if new_width <= 0 || new_height <= 0 {
        return .InvalidDimensions
    }

    // Create new cell array
    new_cells := make([]Cell, new_width * new_height, buffer.allocator) or_return
    if new_cells == nil {
        return .AllocationFailed
    }

    // Initialize new cells
    for &cell in new_cells {
        cell.rune = ' '
        cell.fg_color = .Default
        cell.bg_color = .Default
        cell.style = {}
        cell.dirty = true
    }

    // Copy old content (as much as fits)
    copy_width := min(buffer.width, new_width)
    copy_height := min(buffer.height, new_height)

    for y in 0..<copy_height {
        for x in 0..<copy_width {
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
