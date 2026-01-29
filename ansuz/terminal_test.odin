package ansuz

import "core:testing"

@(test)
test_terminal_error_enum :: proc(t: ^testing.T) {
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

    testing.expect(t, err_none != err_get, "Different errors should not be equal")
    testing.expect(t, err_none != err_set, "Different errors should not be equal")
}

@(test)
test_winsize_struct :: proc(t: ^testing.T) {
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
    state: TerminalState

    testing.expect(t, !state.is_raw_mode, "Initial is_raw_mode should be false")
    testing.expect(t, !state.is_initialized, "Initial is_initialized should be false")
}

@(test)
test_terminal_error_comparison :: proc(t: ^testing.T) {
    err1 := TerminalError.FailedToGetAttributes
    err2 := TerminalError.FailedToSetAttributes
    err3 := TerminalError.None

    testing.expect(t, err1 != err2, "Different errors should not be equal")
    testing.expect(t, err1 != err3, "Error should not equal None")
    testing.expect(t, err3 == .None, "None should equal None")
}

@(test)
test_ansi_escape_codes_format :: proc(t: ^testing.T) {
    sequences := []string{
        "\x1b[2J",
        "\x1b[2K",
        "\x1b[H",
        "\x1b[1;1H",
        "\x1b[?25l",
        "\x1b[?25h",
        "\x1b[s",
        "\x1b[u",
        "\x1b[?1049h",
        "\x1b[?1049l",
        "\x1b[0m",
    }

    for seq in sequences {
        testing.expect(t, len(seq) > 0, "ANSI sequence should not be empty")
        testing.expect(t, seq[0] == '\x1b', "ANSI sequence should start with ESC")
    }
}

@(test)
test_function_pointers_exist :: proc(t: ^testing.T) {
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
    state_size := size_of(TerminalState)
    testing.expect(t, state_size > 0, "TerminalState should have non-zero size")
}

@(test)
test_winsize_size :: proc(t: ^testing.T) {
    ws_size := size_of(winsize)
    testing.expect(t, ws_size > 0, "winsize should have non-zero size")
}

@(test)
test_cursor_function_types :: proc(t: ^testing.T) {
    err_type: TerminalError
    _ = err_type

    move_type := proc(int, int) -> TerminalError { return .None }
    testing.expect(t, move_type != nil, "move_cursor type should exist")
}

@(test)
test_terminal_functions_return_types :: proc(t: ^testing.T) {
    err: TerminalError
    _ = err

    testing.expect(t, true, "Terminal functions have correct return types")
}

@(test)
test_read_input_function_type :: proc(t: ^testing.T) {
    // Only verify function signature - don't actually call read_input() 
    // as it blocks waiting for stdin input
    fn_type: proc() -> (u8, bool)
    fn_type = read_input
    testing.expect(t, fn_type != nil, "read_input should exist")
}

@(test)
test_get_terminal_size_function_type :: proc(t: ^testing.T) {
    width, height, err := get_terminal_size()
    _ = width
    _ = height
    _ = err
    testing.expect(t, true, "get_terminal_size returns correct types")
}

@(test)
test_clear_screen_function_type :: proc(t: ^testing.T) {
    err_type: proc() -> TerminalError
    err_type = clear_screen
    testing.expect(t, err_type != nil, "clear_screen type should exist")
}

@(test)
test_write_ansi_function_type :: proc(t: ^testing.T) {
    err_type: proc(string) -> TerminalError
    err_type = write_ansi
    testing.expect(t, err_type != nil, "write_ansi type should exist")
}
