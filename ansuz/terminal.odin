package ansuz

import "core:fmt"
import "core:os"
import "core:sys/posix"
import "core:time"

// TerminalState maintains the state of terminal configuration
// It stores the original termios settings for restoration on exit
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

// init_terminal initializes the terminal system and stores original settings
init_terminal :: proc() -> TerminalError {
	if _terminal_state.is_initialized {
		return .None
	}

	stdin_fd := posix.FD(os.stdin)

	result := posix.tcgetattr(stdin_fd, &_terminal_state.original_termios)
	if result != .OK {
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

// leave_raw_mode restores the terminal to its original state
// Should be called before program exit to avoid corrupting the terminal
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

// flush_output ensures all buffered output is written to the terminal
flush_output :: proc() {
	stdout_fd := posix.FD(os.stdout)
	_ = posix.fsync(stdout_fd)
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
//
// Odin's core:sys/posix does not expose ioctl/TIOCGWINSZ, so we query the
// terminal using ANSI DSR (Device Status Report): ESC [ 6 n.
get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
	term_err := save_cursor()
	if term_err != .None {
		return 0, 0, term_err
	}
	defer restore_cursor()

	term_err = write_ansi("\x1b[999;999H\x1b[6n")
	if term_err != .None {
		return 0, 0, term_err
	}
	flush_output()

	response: [64]u8
	resp_len := 0

	start := time.tick_now()
	for time.tick_since(start) < 50*time.Millisecond {
		buffer: [32]u8
		n, os_err := os.read(os.stdin, buffer[:])
		if os_err != os.ERROR_NONE {
			break
		}

		if n == 0 {
			time.accurate_sleep(1 * time.Millisecond)
			continue
		}

		for i in 0 ..< n {
			if resp_len < len(response) {
				response[resp_len] = buffer[i]
				resp_len += 1
			}
			if buffer[i] == 'R' {
				break
			}
		}

		if resp_len > 0 && response[resp_len-1] == 'R' {
			break
		}
	}

	// Parse ESC [ rows ; cols R
	row := 0
	col := 0
	state: int = 0
	for b in response[:resp_len] {
		switch state {
		case 0:
			if b == '[' {
				state = 1
			}
		case 1:
			if b >= '0' && b <= '9' {
				row = row*10 + int(b-'0')
			} else if b == ';' {
				state = 2
			}
		case 2:
			if b >= '0' && b <= '9' {
				col = col*10 + int(b-'0')
			} else if b == 'R' {
				break
			}
		}
	}

	if row <= 0 || col <= 0 {
		return 0, 0, .FailedToGetAttributes
	}

	return col, row, .None
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
