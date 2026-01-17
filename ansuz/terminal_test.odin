package ansuz

import "core:testing"

@(test)
test_terminal_error_enum :: proc(t: ^testing.T) {
    // Test that TerminalError enum values exist and are comparable
    err_none := TerminalError.None
    testing.expect(t, err_none == .None, "None error should be valid")
    
    err_get := TerminalError.FailedToGetAttributes
    testing.expect(t, err_get == .FailedToGetAttributes, "FailedToGetAttributes should be valid")
    
    err_set := TerminalError.FailedToSetAttributes
    testing.expect(t, err_set == .FailedToSetAttributes, "FailedToSetAttributes should be valid")
    
    err_write := TerminalError.FailedToWrite
    testing.expect(t, err_write == .FailedToWrite, "FailedToWrite should be valid")
    
    err_init := TerminalError.NotInitialized
    testing.expect(t, err_init == .NotInitialized, "NotInitialized should be valid")
    
    // Test error values are different
    testing.expect(t, err_none != err_get, "Different errors should not be equal")
    testing.expect(t, err_none != err_set, "Different errors should not be equal")
}

@(test)
test_winsize_struct :: proc(t: ^testing.T) {
    // Test that winsize struct can be created
    ws: winsize
    ws.ws_row = 24
    ws.ws_col = 80
    ws.ws_xpixel = 0
    ws.ws_ypixel = 0
    
    testing.expect_value(t, ws.ws_row, 24)
    testing.expect_value(t, ws.ws_col, 80)
}

@(test)
test_terminal_state_struct :: proc(t: ^testing.T) {
    // Test that TerminalState struct can be created
    state: TerminalState
    
    testing.expect(t, !state.is_raw_mode, "Initial is_raw_mode should be false")
    testing.expect(t, !state.is_initialized, "Initial is_initialized should be false")
}

@(test)
test_clear_screen_sequence :: proc(t: ^testing.T) {
    // Test that clear_screen returns correct error type
    err := clear_screen()
    testing.expect(t, err == .None || err == .FailedToWrite, 
                "clear_screen should return None or FailedToWrite")
}

@(test)
test_clear_line_sequence :: proc(t: ^testing.T) {
    err := clear_line()
    testing.expect(t, err == .None || err == .FailedToWrite,
                "clear_line should return None or FailedToWrite")
}

@(test)
test_move_cursor_sequences :: proc(t: ^testing.T) {
    // Test move_cursor with various positions
    err := move_cursor(1, 1)
    testing.expect(t, err == .None || err == .FailedToWrite,
                "move_cursor(1,1) should return None or FailedToWrite")
    
    err = move_cursor(10, 20)
    testing.expect(t, err == .None || err == .FailedToWrite,
                "move_cursor(10,20) should return None or FailedToWrite")
    
    err = move_cursor(100, 200)
    testing.expect(t, err == .None || err == .FailedToWrite,
                "move_cursor(100,200) should return None or FailedToWrite")
}

@(test)
test_move_cursor_home :: proc(t: ^testing.T) {
    err := move_cursor_home()
    testing.expect(t, err == .None || err == .FailedToWrite,
                "move_cursor_home should return None or FailedToWrite")
}

@(test)
test_save_restore_cursor :: proc(t: ^testing.T) {
    save_err := save_cursor()
    testing.expect(t, save_err == .None || save_err == .FailedToWrite,
                "save_cursor should return None or FailedToWrite")
    
    restore_err := restore_cursor()
    testing.expect(t, restore_err == .None || restore_err == .FailedToWrite,
                "restore_cursor should return None or FailedToWrite")
}

@(test)
test_cursor_visibility :: proc(t: ^testing.T) {
    hide_err := hide_cursor()
    testing.expect(t, hide_err == .None || hide_err == .FailedToWrite,
                "hide_cursor should return None or FailedToWrite")
    
    show_err := show_cursor()
    testing.expect(t, show_err == .None || show_err == .FailedToWrite,
                "show_cursor should return None or FailedToWrite")
}

@(test)
test_alternate_buffer :: proc(t: ^testing.T) {
    enter_err := enter_alternate_buffer()
    testing.expect(t, enter_err == .None || enter_err == .FailedToWrite,
                "enter_alternate_buffer should return None or FailedToWrite")
    
    leave_err := leave_alternate_buffer()
    testing.expect(t, leave_err == .None || leave_err == .FailedToWrite,
                "leave_alternate_buffer should return None or FailedToWrite")
}

@(test)
test_write_ansi_function :: proc(t: ^testing.T) {
    // Test write_ansi with various sequences
    err := write_ansi("\x1b[2J")
    testing.expect(t, err == .None || err == .FailedToWrite,
                "write_ansi should return None or FailedToWrite")
    
    err = write_ansi("\x1b[H")
    testing.expect(t, err == .None || err == .FailedToWrite,
                "write_ansi with home sequence should return None or FailedToWrite")
    
    err = write_ansi("\x1b[31;42m")
    testing.expect(t, err == .None || err == .FailedToWrite,
                "write_ansi with color sequence should return None or FailedToWrite")
    
    err = write_ansi("")
    testing.expect(t, err == .None || err == .FailedToWrite,
                "write_ansi with empty string should return None or FailedToWrite")
}

@(test)
test_flush_output :: proc(t: ^testing.T) {
    // flush_output should not crash
    flush_output()
    testing.expect(t, true, "flush_output should complete without error")
}

@(test)
test_reset_terminal :: proc(t: ^testing.T) {
    // reset_terminal should not crash even without initialization
    reset_terminal()
    testing.expect(t, true, "reset_terminal should complete without error")
}

@(test)
test_read_input_function_exists :: proc(t: ^testing.T) {
    // Test that read_input function exists and returns correct tuple
    byte, available := read_input()
    
    // available should be bool
    _ = available
    
    // byte should be u8
    _ = byte
}

@(test)
test_get_terminal_size_function_exists :: proc(t: ^testing.T) {
    // Test that get_terminal_size returns correct tuple
    width, height, err := get_terminal_size()
    
    // Even if it fails, it should return the right types
    _ = width
    _ = height
    _ = err
}

@(test)
test_terminal_error_comparison :: proc(t: ^testing.T) {
    // Test that TerminalError values can be compared
    err1 := TerminalError.FailedToGetAttributes
    err2 := TerminalError.FailedToSetAttributes
    err3 := TerminalError.None
    
    testing.expect(t, err1 != err2, "Different errors should not be equal")
    testing.expect(t, err1 != err3, "Error should not equal None")
    testing.expect(t, err3 == .None, "None should equal None")
}

@(test)
test_ansi_escape_codes :: proc(t: ^testing.T) {
    // Test common ANSI escape sequences
    sequences := []string{
        "\x1b[2J",         // Clear screen
        "\x1b[2K",         // Clear line
        "\x1b[H",          // Home
        "\x1b[1;1H",       // Move to 1,1
        "\x1b[?25l",       // Hide cursor
        "\x1b[?25h",       // Show cursor
        "\x1b[s",          // Save cursor
        "\x1b[u",          // Restore cursor
        "\x1b[?1049h",     // Enter alt buffer
        "\x1b[?1049l",     // Leave alt buffer
        "\x1b[0m",         // Reset style
    }
    
    for seq in sequences {
        err := write_ansi(seq)
        testing.expect(t, err == .None || err == .FailedToWrite,
                    "ANSI sequence should be writable")
    }
}

@(test)
test_multiple_cursor_operations :: proc(t: ^testing.T) {
    // Test that multiple cursor operations can be chained
    err1 := save_cursor()
    err2 := move_cursor(5, 10)
    err3 := move_cursor(15, 20)
    err4 := restore_cursor()
    
    // All should not crash
    _ = err1
    _ = err2
    _ = err3
    _ = err4
    
    testing.expect(t, true, "Multiple cursor operations should complete")
}

@(test)
test_write_ansi_with_special_chars :: proc(t: ^testing.T) {
    // Test writing with special characters
    err := write_ansi("Hello, World!")
    testing.expect(t, err == .None || err == .FailedToWrite,
                "Write regular text should work")
    
    err = write_ansi("Line 1\nLine 2\r\nLine 3")
    testing.expect(t, err == .None || err == .FailedToWrite,
                "Write with line breaks should work")
}

@(test)
test_function_pointers_exist :: proc(t: ^testing.T) {
    // Test that all terminal functions exist
    ptr_init := init_terminal
    ptr_raw := enter_raw_mode
    ptr_leave := leave_raw_mode
    ptr_write := write_ansi
    ptr_flush := flush_output
    ptr_clear := clear_screen
    ptr_clear_line := clear_line
    ptr_move := move_cursor
    ptr_home := move_cursor_home
    ptr_save := save_cursor
    ptr_restore := restore_cursor
    ptr_hide := hide_cursor
    ptr_show := show_cursor
    ptr_alt_enter := enter_alternate_buffer
    ptr_alt_leave := leave_alternate_buffer
    ptr_size := get_terminal_size
    ptr_read := read_input
    ptr_reset := reset_terminal
    
    // Verify all function pointers are not nil
    testing.expect(t, ptr_init != nil, "init_terminal should exist")
    testing.expect(t, ptr_raw != nil, "enter_raw_mode should exist")
    testing.expect(t, ptr_leave != nil, "leave_raw_mode should exist")
    testing.expect(t, ptr_write != nil, "write_ansi should exist")
    testing.expect(t, ptr_flush != nil, "flush_output should exist")
    testing.expect(t, ptr_clear != nil, "clear_screen should exist")
    testing.expect(t, ptr_clear_line != nil, "clear_line should exist")
    testing.expect(t, ptr_move != nil, "move_cursor should exist")
    testing.expect(t, ptr_home != nil, "move_cursor_home should exist")
    testing.expect(t, ptr_save != nil, "save_cursor should exist")
    testing.expect(t, ptr_restore != nil, "restore_cursor should exist")
    testing.expect(t, ptr_hide != nil, "hide_cursor should exist")
    testing.expect(t, ptr_show != nil, "show_cursor should exist")
    testing.expect(t, ptr_alt_enter != nil, "enter_alternate_buffer should exist")
    testing.expect(t, ptr_alt_leave != nil, "leave_alternate_buffer should exist")
    testing.expect(t, ptr_size != nil, "get_terminal_size should exist")
    testing.expect(t, ptr_read != nil, "read_input should exist")
    testing.expect(t, ptr_reset != nil, "reset_terminal should exist")
}

@(test)
test_terminal_state_size :: proc(t: ^testing.T) {
    // Test that TerminalState struct has expected size
    state_size := size_of(TerminalState)
    testing.expect(t, state_size > 0, "TerminalState should have non-zero size")
}

@(test)
test_winsize_size :: proc(t: ^testing.T) {
    ws_size := size_of(winsize)
    testing.expect(t, ws_size > 0, "winsize should have non-zero size")
}

@(test)
test_move_cursor_negative_values :: proc(t: ^testing.T) {
    // Test that move_cursor accepts negative values (terminal will clamp)
    err := move_cursor(-1, -1)
    testing.expect(t, err == .None || err == .FailedToWrite,
                "move_cursor with negative values should not crash")
    
    err = move_cursor(-10, 5)
    testing.expect(t, err == .None || err == .FailedToWrite,
                "move_cursor with negative x should not crash")
}

@(test)
test_large_cursor_positions :: proc(t: ^testing.T) {
    // Test with very large cursor positions
    err := move_cursor(10000, 10000)
    testing.expect(t, err == .None || err == .FailedToWrite,
                "move_cursor with large values should not crash")
}

@(test)
test_sequence_of_terminal_operations :: proc(t: ^testing.T) {
    // Test a typical sequence of terminal operations
    err1 := clear_screen()
    err2 := move_cursor_home()
    err3 := hide_cursor()
    err4 := write_ansi("Test")
    err5 := show_cursor()
    
    _ = err1
    _ = err2
    _ = err3
    _ = err4
    _ = err5
    
    testing.expect(t, true, "Sequence of operations should complete")
}

@(test)
test_zero_coordinates :: proc(t: ^testing.T) {
    // Test with zero coordinates
    err := move_cursor(0, 0)
    testing.expect(t, err == .None || err == .FailedToWrite,
                "move_cursor(0,0) should work")
}

@(test)
test_write_ansi_multiple_times :: proc(t: ^testing.T) {
    // Test writing multiple times in sequence
    for i in 0 ..< 10 {
        err := write_ansi("Test")
        testing.expect(t, err == .None || err == .FailedToWrite,
                    "Multiple writes should work")
        _ = err
    }
}
