package ansuz

import "core:c"
import "core:fmt"
import "core:os"
import "core:sys/linux"
import "core:sys/posix"
import "core:terminal"
import ansi "core:terminal/ansi"

// winsize struct for TIOCGWINSZ ioctl (not available in core:sys/posix)
winsize :: struct {
	ws_row:    u16, // rows, in characters
	ws_col:    u16, // columns, in characters
	ws_xpixel: u16, // horizontal size, pixels (unused)
	ws_ypixel: u16, // vertical size, pixels (unused)
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

	if !terminal.is_terminal(os.stdin) {
		return .FailedToGetAttributes
	}

	stdin_fd := posix.FD(os.stdin)

	result := posix.tcgetattr(stdin_fd, &_terminal_state.original_termios)
	if result != .OK {
		return .FailedToGetAttributes
	}

	_terminal_state.is_initialized = true

	// Setup signal handler for resize events
	setup_sigwinch()

	return .None
}

// Signal handler with "c" calling convention
// Just receiving the signal is enough to interrupt syscalls
handle_sigwinch :: proc "c" (sig: posix.Signal) {
	// No-op
}

setup_sigwinch :: proc() {
	sa: posix.sigaction_t
	sa.sa_handler = handle_sigwinch
	sa.sa_flags = {} // No SA_RESTART, we want to interrupt poll

	posix.sigaction(posix.Signal(posix.SIGWINCH), &sa, nil)
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
	return write_ansi(ansi.CSI + "2" + ansi.ED)
}

// clear_line clears current line
clear_line :: proc() -> TerminalError {
	return write_ansi(ansi.CSI + "2" + ansi.EL)
}

// move_cursor moves cursor to specified position (1-indexed)
// Terminal coordinates are 1-based, not 0-based
move_cursor :: proc(row, col: int) -> TerminalError {
	sequence := fmt.tprintf("%s%d;%d%s", ansi.CSI, row, col, ansi.CUP)
	return write_ansi(sequence)
}

// move_cursor_home moves cursor to top-left corner (1,1)
move_cursor_home :: proc() -> TerminalError {
	return write_ansi(ansi.CSI + ansi.CUP)
}

// save_cursor saves current cursor position
// Can be restored later with restore_cursor()
save_cursor :: proc() -> TerminalError {
	return write_ansi(ansi.CSI + ansi.SCP)
}

// restore_cursor restores previously saved cursor position
restore_cursor :: proc() -> TerminalError {
	return write_ansi(ansi.CSI + ansi.RCP)
}

// hide_cursor makes cursor invisible
// Useful during rendering to prevent flicker
hide_cursor :: proc() -> TerminalError {
	return write_ansi(ansi.CSI + ansi.DECTCEM_HIDE)
}

// show_cursor makes cursor visible again
// Should be called before program exit
show_cursor :: proc() -> TerminalError {
	return write_ansi(ansi.CSI + ansi.DECTCEM_SHOW)
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

// disable_auto_wrap disables automatic line wrapping (DECAWM)
// Prevents screen scrolling when writing to the last column
disable_auto_wrap :: proc() -> TerminalError {
	return write_ansi(ansi.CSI + ansi.DECAWM_OFF)
}

// enable_auto_wrap enables automatic line wrapping (DECAWM)
// Restores default terminal behavior
enable_auto_wrap :: proc() -> TerminalError {
	return write_ansi(ansi.CSI + ansi.DECAWM_ON)
}

// begin_sync_update begins a synchronized output update (Mode 2026)
// Terminals that support this will buffer all output until end_sync_update()
// This prevents flickering/tearing during screen updates (especially in Ghostty)
// Terminals that don't support it will safely ignore this sequence
begin_sync_update :: proc() -> TerminalError {
	return write_ansi("\x1b[?2026h")
}

// end_sync_update ends a synchronized output update (Mode 2026)
// This causes the terminal to flush all buffered output atomically
end_sync_update :: proc() -> TerminalError {
	return write_ansi("\x1b[?2026l")
}

// get_terminal_size retrieves current terminal dimensions
// Returns (width, height) in characters
//
// This function uses ioctl(TIOCGWINSZ) which is non-blocking and doesn't interfere
// with stdin input, making it safe to call during the render loop.
// Uses native Odin ioctl from core:sys/linux.
get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
	// Use stdout for ioctl as it's more likely to be the controlling terminal
	stdout_fd := linux.Fd(posix.FD(os.stdout))

	ws: winsize
	result := linux.ioctl(stdout_fd, linux.TIOCGWINSZ, uintptr(&ws))

	if result < 0 || ws.ws_col == 0 || ws.ws_row == 0 {
		// ioctl failed or returned 0, try stdin as fallback
		stdin_fd := linux.Fd(posix.FD(os.stdin))
		result = linux.ioctl(stdin_fd, linux.TIOCGWINSZ, uintptr(&ws))
		if result < 0 || ws.ws_col == 0 || ws.ws_row == 0 {
			// ioctl failed on both, use reasonable defaults
			return 80, 24, .None
		}
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
// WaitResult indicates what caused wait_for_event to return
WaitResult :: enum {
	None, // Timeout with no events
	Input, // Input available on stdin
	Resize, // Terminal size changed
	Error, // Error occurred
}

// wait_for_event blocks until an event occurs (input, resize, or timeout)
// Uses poll() on stdin with periodic timeout to detect terminal resize via ioctl
//
// Parameters:
//   last_width, last_height: Previous terminal dimensions (to detect resize)
//   timeout_ms: Maximum time to wait (-1 = infinite, but will use internal timeout for resize detection)
//
// Returns: (result, new_width, new_height)
wait_for_event :: proc(
	last_width, last_height: int,
	timeout_ms: i32 = -1,
) -> (
	WaitResult,
	int,
	int,
) {
	for {
		// Use 100ms internal timeout for resize detection if infinite wait requested
		poll_timeout := timeout_ms == -1 ? c.int(100) : c.int(timeout_ms)

		fds: [1]posix.pollfd
		fds[0] = posix.pollfd {
			fd      = posix.FD(os.stdin),
			events  = {.IN},
			revents = {},
		}

		// Use official posix.poll()
		ret := posix.poll(&fds[0], 1, poll_timeout)

		// Check for terminal resize by querying current size
		new_width, new_height, _ := get_terminal_size()
		if new_width != last_width || new_height != last_height {
			return .Resize, new_width, new_height
		}

		// Check poll result
		if ret < 0 {
			return .Error, new_width, new_height
		}

		if ret > 0 && .IN in fds[0].revents {
			return .Input, new_width, new_height
		}

		// Timeout - if explicit timeout requested, return
		if timeout_ms != -1 {
			return .None, new_width, new_height
		}

		// If infinite wait requested (timeout_ms == -1), loop again
	}
}

// wait_for_input blocks until stdin has data available or timeout expires
// timeout_ms: -1 for infinite wait, 0 for immediate return, >0 for milliseconds
// Returns: true if data is available, false if timeout or error
// DEPRECATED: Use wait_for_event() for event-driven rendering
wait_for_input :: proc(timeout_ms: i32 = -1) -> bool {
	fds: [1]posix.pollfd
	fds[0] = posix.pollfd {
		fd      = posix.FD(os.stdin),
		events  = {.IN},
		revents = {},
	}

	// Use official posix.poll()
	ret := posix.poll(&fds[0], 1, c.int(timeout_ms))

	// ret > 0: number of fds with events
	// ret = 0: timeout
	// ret < 0: error
	return ret > 0 && .IN in fds[0].revents
}

// reset_terminal performs full terminal cleanup
// Should be called before exiting the program
reset_terminal :: proc() {
	leave_raw_mode()
	// Restore terminal state
	enable_auto_wrap()
	show_cursor()
	leave_alternate_buffer()
	clear_screen()
	move_cursor_home()
	flush_output()
}
