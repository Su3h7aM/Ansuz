package ansuz

import "core:fmt"
import "core:os"
import "core:sys/posix"
import "core:sys/linux"

// winsize struct for TIOCGWINSZ ioctl
winsize :: struct {
	ws_row:    u16,  // rows, in characters
	ws_col:    u16,  // columns, in characters
	ws_xpixel: u16,  // horizontal size, pixels (unused)
	ws_ypixel: u16,  // vertical size, pixels (unused)
}

// TerminalState maintains state of terminal configuration
// It stores original termios settings for restoration on exit
TerminalState :: struct {
	original_termios: posix.termios,
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

// init_terminal initializes terminal system and stores original settings
init_terminal :: proc() -> TerminalError {
	if _terminal_state.is_initialized {
		return .None
	}

	stdin_fd := posix.FD(os.stdin)

	if !posix.isatty(stdin_fd) {
		return .FailedToGetAttributes
	}

	result := posix.tcgetattr(stdin_fd, &_terminal_state.original_termios)
	if result != .OK {
		return .FailedToGetAttributes
	}

	_terminal_state.is_initialized = true
	return .None
}

// enter_raw_mode switches terminal to raw mode for immediate input
// This disables line buffering, echo, and signal processing
// Must be called after init_terminal()
enter_raw_mode :: proc() -> TerminalError {
	if !_terminal_state.is_initialized {
		return .NotInitialized
	}

	if _terminal_state.is_raw_mode {
		return .None
	}

	raw := _terminal_state.original_termios

	// Input flags: disable break processing, CR->NL translation, parity checking,
	// stripping, and software flow control.
	raw.c_iflag -= {.BRKINT, .ICRNL, .INPCK, .ISTRIP, .IXON}

	// Output flags: disable output post-processing.
	raw.c_oflag -= {.OPOST}

	// Control flags: set 8-bit characters.
	raw.c_cflag += {.CS8}

	// Local flags: disable echo, canonical mode, signals, and extended input processing.
	raw.c_lflag -= {.ECHO, .ICANON, .IEXTEN, .ISIG}

	// Control characters: non-blocking reads.
	raw.c_cc[.VMIN] = posix.cc_t(0)
	raw.c_cc[.VTIME] = posix.cc_t(0)

	stdin_fd := posix.FD(os.stdin)

	result := posix.tcsetattr(stdin_fd, .TCSAFLUSH, &raw)
	if result != .OK {
		return .FailedToSetAttributes
	}

	_terminal_state.is_raw_mode = true
	return .None
}

// leave_raw_mode restores terminal to its original state
// Should be called before program exit to avoid corrupting terminal
leave_raw_mode :: proc() -> TerminalError {
	if !_terminal_state.is_raw_mode {
		return .None
	}

	stdin_fd := posix.FD(os.stdin)

	result := posix.tcsetattr(stdin_fd, .TCSAFLUSH, &_terminal_state.original_termios)
	if result != .OK {
		return .FailedToSetAttributes
	}

	_terminal_state.is_raw_mode = false
	return .None
}

// write_ansi writes ANSI escape sequences directly to stdout
// Returns TerminalError if write fails
write_ansi :: proc(sequence: string) -> TerminalError {
	_, err := os.write_string(os.stdout, sequence)
	if err != os.ERROR_NONE {
		return .FailedToWrite
	}
	return .None
}

// flush_output ensures all buffered output is written to terminal
flush_output :: proc() {
	_ = os.flush(os.stdout)
}

// clear_screen clears entire terminal screen
clear_screen :: proc() -> TerminalError {
	return write_ansi("\x1b[2J")
}

// clear_line clears current line
clear_line :: proc() -> TerminalError {
	return write_ansi("\x1b[2K")
}

// move_cursor moves cursor to specified position (1-indexed)
// Terminal coordinates are 1-based, not 0-based
move_cursor :: proc(row, col: int) -> TerminalError {
	sequence := fmt.tprintf("\x1b[%d;%dH", row, col)
	return write_ansi(sequence)
}

// move_cursor_home moves cursor to top-left corner (1,1)
move_cursor_home :: proc() -> TerminalError {
	return write_ansi("\x1b[H")
}

// save_cursor saves current cursor position
// Can be restored later with restore_cursor()
save_cursor :: proc() -> TerminalError {
	return write_ansi("\x1b[s")
}

// restore_cursor restores previously saved cursor position
restore_cursor :: proc() -> TerminalError {
	return write_ansi("\x1b[u")
}

// hide_cursor makes cursor invisible
// Useful during rendering to prevent flicker
hide_cursor :: proc() -> TerminalError {
	return write_ansi("\x1b[?25l")
}

// show_cursor makes cursor visible again
// Should be called before program exit
show_cursor :: proc() -> TerminalError {
	return write_ansi("\x1b[?25h")
}

// enter_alternate_buffer switches to alternate screen buffer
// This hides the original terminal content and prevents frames from appearing in history
enter_alternate_buffer :: proc() -> TerminalError {
	return write_ansi("\x1b[?1049h")
}

// leave_alternate_buffer restores original screen buffer
// Should be called before exiting to restore terminal to original state
leave_alternate_buffer :: proc() -> TerminalError {
	return write_ansi("\x1b[?1049l")
}

// get_terminal_size retrieves current terminal dimensions
// Returns (width, height) in characters
//
// This function uses ioctl(TIOCGWINSZ) which is non-blocking and doesn't interfere
// with stdin input, making it safe to call during the render loop.
// Uses native Odin ioctl from core:sys/linux.
get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
	stdin_fd := linux.Fd(posix.FD(os.stdin))

	ws: winsize
	result := linux.ioctl(stdin_fd, linux.TIOCGWINSZ, transmute(uintptr)&ws)

	if result < 0 {
		// ioctl failed, return error
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
	leave_alternate_buffer()
	clear_screen()
	move_cursor_home()
	flush_output()
}
