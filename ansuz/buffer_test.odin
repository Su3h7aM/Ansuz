package ansuz

import "core:testing"
import "core:fmt"
import "core:mem"

@(test)
test_buffer_init :: proc(t: ^testing.T) {
    buf, err := init_buffer(10, 5, testing.allocator)
    defer destroy_buffer(&buf)

    testing.expect(t, err == .None, "Buffer init should succeed")
    testing.expect(t, buf.width == 10, "Buffer width should be 10")
    testing.expect(t, buf.height == 5, "Buffer height should be 5")
    testing.expect(t, len(buf.cells) == 50, "Buffer should have 50 cells")
}

@(test)
test_buffer_clear :: proc(t: ^testing.T) {
    buf, _ := init_buffer(10, 5, testing.allocator)
    defer destroy_buffer(&buf)

    // Set some cells
    set_cell(&buf, 0, 0, 'X', .Red, .Black, {.Bold})
    set_cell(&buf, 5, 3, 'Y', .Blue, .White, {.Underline})

    // Clear buffer
    clear_buffer(&buf)

    // Check all cells are reset
    for y in 0..<buf.height {
        for x in 0..<buf.width {
            cell := get_cell_safe(&buf, x, y)
            testing.expect(t, cell.rune == ' ',
                          fmt.tprintf("Cell (%d, %d) should be space", x, y))
            testing.expect(t, cell.fg_color == .Default,
                          fmt.tprintf("Cell (%d, %d) fg should be default", x, y))
            testing.expect(t, cell.bg_color == .Default,
                          fmt.tprintf("Cell (%d, %d) bg should be default", x, y))
        }
    }
}

@(test)
test_set_cell :: proc(t: ^testing.T) {
    buf, _ := init_buffer(10, 5, testing.allocator)
    defer destroy_buffer(&buf)

    // Set a cell
    err := set_cell(&buf, 3, 2, 'A', .Red, .Black, {.Bold})
    testing.expect(t, err == .None, "set_cell should succeed")

    // Read it back
    cell := get_cell_safe(&buf, 3, 2)
    testing.expect(t, cell.rune == 'A', "Cell should contain 'A'")
    testing.expect(t, cell.fg_color == .Red, "Cell fg should be Red")
    testing.expect(t, cell.bg_color == .Black, "Cell bg should be Black")
    testing.expect(t, card(cell.style) == 1, "Cell should have 1 style flag")
}

@(test)
test_set_cell_out_of_bounds :: proc(t: ^testing.T) {
    buf, _ := init_buffer(10, 5, testing.allocator)
    defer destroy_buffer(&buf)

    err := set_cell(&buf, 20, 20, 'X', .Red, .Black, {})
    testing.expect(t, err == .OutOfBounds, "Out of bounds should return error")
}

@(test)
test_write_string :: proc(t: ^testing.T) {
    buf, _ := init_buffer(20, 5, testing.allocator)
    defer destroy_buffer(&buf)

    written := write_string(&buf, 0, 0, "Hello", .Red, .Black, {})
    testing.expect(t, written == 5, "Should write 5 characters")

    // Check characters
    text := "Hello"
    for i, r in text {
        cell := get_cell_safe(&buf, i, 0)
        testing.expect(t, cell.rune == r,
                      fmt.tprintf("Cell %d should have '%c'", i, r))
    }
}

@(test)
test_fill_rect :: proc(t: ^testing.T) {
    buf, _ := init_buffer(20, 20, testing.allocator)
    defer destroy_buffer(&buf)

    fill_rect(&buf, 5, 5, 5, 3, 'X', .Red, .Black, {})

    // Check filled cells
    for y in 5..=<7 {
        for x in 5..=<9 {
            cell := get_cell_safe(&buf, x, y)
            testing.expect(t, cell.rune == 'X',
                          fmt.tprintf("Cell (%d, %d) should be 'X'", x, y))
            testing.expect(t, cell.fg_color == .Red,
                          fmt.tprintf("Cell (%d, %d) fg should be Red", x, y))
        }
    }

    // Check cells outside rect
    cell := get_cell_safe(&buf, 4, 5)
    testing.expect(t, cell.rune != 'X', "Cell outside rect should not be 'X'")
}

@(test)
test_draw_box :: proc(t: ^testing.T) {
    buf, _ := init_buffer(20, 20, testing.allocator)
    defer destroy_buffer(&buf)

    draw_box(&buf, 5, 5, 5, 3, .Red, .Black, {})

    // Check corners
    testing.expect(t, get_cell_safe(&buf, 5, 5).rune == '┌', "Top-left corner")
    testing.expect(t, get_cell_safe(&buf, 9, 5).rune == '┐', "Top-right corner")
    testing.expect(t, get_cell_safe(&buf, 5, 7).rune == '└', "Bottom-left corner")
    testing.expect(t, get_cell_safe(&buf, 9, 7).rune == '┘', "Bottom-right corner")

    // Check top edge
    testing.expect(t, get_cell_safe(&buf, 6, 5).rune == '─', "Top edge")
    testing.expect(t, get_cell_safe(&buf, 7, 5).rune == '─', "Top edge")
    testing.expect(t, get_cell_safe(&buf, 8, 5).rune == '─', "Top edge")

    // Check bottom edge
    testing.expect(t, get_cell_safe(&buf, 6, 7).rune == '─', "Bottom edge")
    testing.expect(t, get_cell_safe(&buf, 7, 7).rune == '─', "Bottom edge")
    testing.expect(t, get_cell_safe(&buf, 8, 7).rune == '─', "Bottom edge")

    // Check left edge
    testing.expect(t, get_cell_safe(&buf, 5, 6).rune == '│', "Left edge")

    // Check right edge
    testing.expect(t, get_cell_safe(&buf, 9, 6).rune == '│', "Right edge")
}

@(test)
test_resize_buffer :: proc(t: ^testing.T) {
    buf, _ := init_buffer(10, 10, testing.allocator)
    defer destroy_buffer(&buf)

    // Set some data
    set_cell(&buf, 0, 0, 'A', .Red, .Black, {})
    set_cell(&buf, 5, 5, 'B', .Blue, .White, {})

    // Resize
    err := resize_buffer(&buf, 15, 20)
    testing.expect(t, err == .None, "Resize should succeed")
    testing.expect(t, buf.width == 15, "Width should be 15")
    testing.expect(t, buf.height == 20, "Height should be 20")

    // Check preserved data
    testing.expect(t, get_cell_safe(&buf, 0, 0).rune == 'A',
                  "Cell (0, 0) should be preserved")
    testing.expect(t, get_cell_safe(&buf, 5, 5).rune == 'B',
                  "Cell (5, 5) should be preserved")

    // Check new cells are default
    testing.expect(t, get_cell_safe(&buf, 14, 19).rune == ' ',
                  "New cell should be space")
}

@(test)
test_resize_buffer_smaller :: proc(t: ^testing.T) {
    buf, _ := init_buffer(10, 10, testing.allocator)
    defer destroy_buffer(&buf)

    // Set data
    set_cell(&buf, 0, 0, 'A', .Red, .Black, {})
    set_cell(&buf, 8, 8, 'B', .Blue, .White, {})

    // Resize smaller
    resize_buffer(&buf, 5, 5)

    // Check preserved data (only what fits)
    testing.expect(t, get_cell_safe(&buf, 0, 0).rune == 'A',
                  "Cell (0, 0) should be preserved")

    // Old cell at (8, 8) should be gone (reset to default)
    testing.expect(t, get_cell_safe(&buf, 0, 0).rune != 'B',
                  "Old out-of-bounds data should be lost")
}
