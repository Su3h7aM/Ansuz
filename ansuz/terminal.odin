package ansuz

import "core:fmt"
import "core:os"

// Foreign imports for POSIX system calls
// This is the standard and idiomatic way in Odin to access low-level system APIs
// These functions are not exposed by Odin's core:os or core:sys/unix packages
foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
    tcgetattr :: proc(fd: int, termios_p: ^Termios) -> int ---
    tcsetattr :: proc(fd: int, optional_actions: int, termios_p: ^Termios) -> int ---
    ioctl     :: proc(fd: int, request: u64, ...) -> int ---
    fsync     :: proc(fd: int) -> int ---
}

// Termios structure (POSIX terminal control)
Termios :: struct {
    c_iflag:  u32,  // Input modes
    c_oflag:  u32,  // Output modes
    c_cflag:  u32,  // Control modes
    c_lflag:  u32,  // Local modes
    c_line:   u8,   // Line discipline
    c_cc:     [32]u8,  // Control characters
    c_ispeed: u32,  // Input speed
    c_ospeed: u32,  // Output speed
}

// Window size structure for terminal dimensions
WinSize :: struct {
    ws_row:    u16,
    ws_col:    u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
}

// POSIX termios constants
TCSAFLUSH :: 2    // Flush pending input and output

// Input mode flags (c_iflag)
BRKINT :: u32(1 << 0)
ICRNL  :: u32(1 << 1)
INPCK  :: u32(1 << 2)
ISTRIP :: u32(1 << 3)
IXON   :: u32(1 << 4)

// Output mode flags (c_oflag)
OPOST :: u32(1 << 0)

// Control mode flags (c_cflag)
CS8 :: u32(0x60)  // 8 data bits

// Local mode flags (c_lflag) - most important for raw mode
ECHO   :: u32(1 << 0)  // Echo input characters
ICANON :: u32(1 << 1)  // Canonical mode (line buffering)
IEXTEN :: u32(1 << 2)  // Extended input processing
ISIG   :: u32(1 << 3)  // Signal generation (Ctrl+C, etc.)

// Control character indices (c_cc)
VMIN  :: 0  // Minimum number of characters to read
VTIME :: 1  // Timeout in deciseconds

// Terminal size query ioctl request code
TIOCGWINSZ :: 0x5413

// TerminalState maintains the state of terminal configuration
// It stores the original termios settings for restoration on exit
TerminalState :: struct {
    original_termios: Termios,
    is_raw_mode:      bool,
    is_initialized:   bool,
}

// TerminalError represents errors that can occur during terminal operations
TerminalError :: enum {
    None,
    FailedToGetAttributes,
    FailedToSetAttributes,
    FailedToWrite,
    NotInitialized,
}

// Global terminal state (simplifies API for single-terminal programs)
_terminal_state: TerminalState

// init_terminal initializes the terminal system and stores original settings
init_terminal :: proc() -> TerminalError {
    if _terminal_state.is_initialized {
        return .None
    }

    // Get current terminal attributes for later restoration
    result := tcgetattr(os.stdin, &_terminal_state.original_termios)
    if result != 0 {
        return .FailedToGetAttributes
    }

    _terminal_state.is_initialized = true
    return .None
}

// enter_raw_mode switches the terminal to raw mode for immediate input
// This disables line buffering, echo, and signal processing
// Must be called after init_terminal()
enter_raw_mode :: proc() -> TerminalError {
    if !_terminal_state.is_initialized {
        return .NotInitialized
    }

    if _terminal_state.is_raw_mode {
        return .None // Already in raw mode
    }

    // Copy original settings and modify for raw mode
    raw := _terminal_state.original_termios

    // Input flags: disable software flow control, CR->NL translation
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON)

    // Output flags: disable output processing (raw output)
    raw.c_oflag &= ~OPOST

    // Control flags: set 8-bit character size
    raw.c_cflag |= CS8

    // Local flags: disable canonical mode, echo, signals, and extended input
    // This is the most critical part for raw mode
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG)

    // Control characters: non-blocking reads
    raw.c_cc[VMIN] = 0  // Minimum characters to read
    raw.c_cc[VTIME] = 0 // Timeout in deciseconds

    // Apply the modified settings
    result := tcsetattr(os.stdin, TCSAFLUSH, &raw)
    if result != 0 {
        return .FailedToSetAttributes
    }

    _terminal_state.is_raw_mode = true
    return .None
}

// leave_raw_mode restores the terminal to its original state
// Should be called before program exit to avoid corrupting the terminal
leave_raw_mode :: proc() -> TerminalError {
    if !_terminal_state.is_raw_mode {
        return .None // Already in cooked mode
    }

    result := tcsetattr(os.stdin, TCSAFLUSH, &_terminal_state.original_termios)
    if result != 0 {
        return .FailedToSetAttributes
    }

    _terminal_state.is_raw_mode = false
    return .None
}

// write_ansi writes ANSI escape sequences directly to stdout
// Returns TerminalError if write fails
write_ansi :: proc(sequence: string) -> TerminalError {
    bytes_written, err := os.write_string(os.stdout, sequence)
    if err != os.ERROR_NONE {
        return .FailedToWrite
    }
    return .None
}

// flush_output ensures all buffered output is written to the terminal
flush_output :: proc() {
    // In Odin, stdout is typically line-buffered, but we can force a flush
    // by writing directly through the file descriptor
    _ = fsync(os.stdout)
}

// clear_screen clears the entire terminal screen
clear_screen :: proc() -> TerminalError {
    return write_ansi("\x1b[2J")
}

// clear_line clears the current line
clear_line :: proc() -> TerminalError {
    return write_ansi("\x1b[2K")
}

// move_cursor moves the cursor to the specified position (1-indexed)
// Terminal coordinates are 1-based, not 0-based
move_cursor :: proc(row, col: int) -> TerminalError {
    sequence := fmt.tprintf("\x1b[%d;%dH", row, col)
    return write_ansi(sequence)
}

// move_cursor_home moves the cursor to the top-left corner (1,1)
move_cursor_home :: proc() -> TerminalError {
    return write_ansi("\x1b[H")
}

// save_cursor saves the current cursor position
// Can be restored later with restore_cursor()
save_cursor :: proc() -> TerminalError {
    return write_ansi("\x1b[s")
}

// restore_cursor restores the previously saved cursor position
restore_cursor :: proc() -> TerminalError {
    return write_ansi("\x1b[u")
}

// hide_cursor makes the cursor invisible
// Useful during rendering to prevent flicker
hide_cursor :: proc() -> TerminalError {
    return write_ansi("\x1b[?25l")
}

// show_cursor makes the cursor visible again
// Should be called before program exit
show_cursor :: proc() -> TerminalError {
    return write_ansi("\x1b[?25h")
}

// get_terminal_size retrieves the current terminal dimensions
// Returns (width, height) in characters
get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
    ws: WinSize
    result := ioctl(os.stdout, TIOCGWINSZ, &ws)

    if result != 0 {
        return 0, 0, .FailedToGetAttributes
    }

    return int(ws.ws_col), int(ws.ws_row), .None
}

// read_input reads a single byte from stdin without blocking
// Returns (byte, true) if data available, or (0, false) if no data
read_input :: proc() -> (byte: u8, available: bool) {
    buffer: [1]u8
    n, err := os.read(os.stdin, buffer[:])

    if err != os.ERROR_NONE || n == 0 {
        return 0, false
    }

    return buffer[0], true
}

// reset_terminal performs full terminal cleanup
// Should be called before exiting the program
reset_terminal :: proc() {
    leave_raw_mode()
    show_cursor()
    clear_screen()
    move_cursor_home()
    flush_output()
}
