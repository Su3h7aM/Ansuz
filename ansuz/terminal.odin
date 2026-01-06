package ansuz

import "core:fmt"
import "core:os"
import "core:sys/posix"

foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
    tcgetattr :: proc(fd: int, termios_p: ^posix.termios) -> int ---
    tcsetattr :: proc(fd: int, optional_actions: int, termios_p: ^posix.termios) -> int ---
    cfmakeraw :: proc(termios_p: ^posix.termios) ---
    ioctl     :: proc(fd: int, request: u64, ...) -> int ---
    fsync     :: proc(fd: int) -> int ---
}

TCSAFLUSH :: 2

TIOCGWINSZ_LINUX :: u64 = u64(0x5413)
TIOCGWINSZ_BSD   :: u64 = u64(0x40087468)

winsize :: struct {
    ws_row:    u16,
    ws_col:    u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
}

TerminalState :: struct {
    original_termios: posix.termios,
    is_raw_mode:      bool,
    is_initialized:   bool,
}

TerminalError :: enum {
    None,
    FailedToGetAttributes,
    FailedToSetAttributes,
    FailedToWrite,
    NotInitialized,
}

_terminal_state: TerminalState

init_terminal :: proc() -> TerminalError {
    if _terminal_state.is_initialized {
        return .None
    }

    stdin_fd := int(posix.FD(os.stdin))

    result := libc.tcgetattr(stdin_fd, &_terminal_state.original_termios)
    if result != 0 {
        return .FailedToGetAttributes
    }

    _terminal_state.is_initialized = true
    return .None
}

enter_raw_mode :: proc() -> TerminalError {
    if !_terminal_state.is_initialized {
        return .NotInitialized
    }

    if _terminal_state.is_raw_mode {
        return .None
    }

    raw := _terminal_state.original_termios
    libc.cfmakeraw(&raw)

    raw.c_cc[posix.VMIN] = 0
    raw.c_cc[posix.VTIME] = 0

    stdin_fd := int(posix.FD(os.stdin))

    result := libc.tcsetattr(stdin_fd, TCSAFLUSH, &raw)
    if result != 0 {
        return .FailedToSetAttributes
    }

    _terminal_state.is_raw_mode = true
    return .None
}

leave_raw_mode :: proc() -> TerminalError {
    if !_terminal_state.is_raw_mode {
        return .None
    }

    stdin_fd := int(posix.FD(os.stdin))

    result := libc.tcsetattr(stdin_fd, TCSAFLUSH, &_terminal_state.original_termios)
    if result != 0 {
        return .FailedToSetAttributes
    }

    _terminal_state.is_raw_mode = false
    return .None
}

write_ansi :: proc(sequence: string) -> TerminalError {
    _, err := os.write_string(os.stdout, sequence)
    if err != os.ERROR_NONE {
        return .FailedToWrite
    }
    return .None
}

flush_output :: proc() {
    stdout_fd := int(posix.FD(os.stdout))
    _ = libc.fsync(stdout_fd)
}

clear_screen :: proc() -> TerminalError {
    return write_ansi("\x1b[2J")
}

clear_line :: proc() -> TerminalError {
    return write_ansi("\x1b[2K")
}

move_cursor :: proc(row, col: int) -> TerminalError {
    sequence := fmt.tprintf("\x1b[%d;%dH", row, col)
    return write_ansi(sequence)
}

move_cursor_home :: proc() -> TerminalError {
    return write_ansi("\x1b[H")
}

save_cursor :: proc() -> TerminalError {
    return write_ansi("\x1b[s")
}

restore_cursor :: proc() -> TerminalError {
    return write_ansi("\x1b[u")
}

hide_cursor :: proc() -> TerminalError {
    return write_ansi("\x1b[?25l")
}

show_cursor :: proc() -> TerminalError {
    return write_ansi("\x1b[?25h")
}

get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
    ws: winsize
    stdout_fd := int(posix.FD(os.stdout))

    result := libc.ioctl(stdout_fd, TIOCGWINSZ_LINUX, &ws)
    if result != 0 {
        result = libc.ioctl(stdout_fd, TIOCGWINSZ_BSD, &ws)
    }

    if result != 0 {
        return 0, 0, .FailedToGetAttributes
    }

    return int(ws.ws_col), int(ws.ws_row), .None
}

read_input :: proc() -> (byte: u8, available: bool) {
    buffer: [1]u8
    n, err := os.read(os.stdin, buffer[:])

    if err != os.ERROR_NONE || n == 0 {
        return 0, false
    }

    return buffer[0], true
}

reset_terminal :: proc() {
    leave_raw_mode()
    show_cursor()
    clear_screen()
    move_cursor_home()
    flush_output()
}
