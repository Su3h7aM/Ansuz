package ansuz

import "core:fmt"
import "core:hash"
import "core:mem"
import "core:strings"
import "core:time"

// Context maintains the global state for the TUI library
// This follows the immediate-mode pattern where the context is passed to widget functions
Context :: struct {
	// Terminal state
	terminal:         TerminalState,

	// Single buffer (immediate mode - redraws every frame)
	buffer:           FrameBuffer,


	// Terminal dimensions
	width:            int,
	height:           int,

	// Frame timing
	frame_count:      u64,

	// Frame time measurement (for debug purposes)
	frame_start_time: time.Time,
	last_frame_time:  time.Duration,

	// Reusable string builder for rendering (avoids per-frame allocations)
	render_buffer:    strings.Builder,

	// Layout system
	layout_ctx:       LayoutContext,

	// Allocator for internal allocations
	allocator:        mem.Allocator,

	// Focus state
	focus_id:         u64,
	last_focus_id:    u64,
	focusable_items:  [dynamic]u64,
}

// ContextError represents errors during context operations
ContextError :: enum {
	None,
	TerminalInitFailed,
	BufferInitFailed,
	RawModeFailed,
}

// init creates and initializes a new Ansuz context
// This sets up the terminal, creates buffers, and prepares for rendering
// Call shutdown() when done to clean up resources
init :: proc(allocator := context.allocator) -> (ctx: ^Context, err: ContextError) {
	ctx = new(Context, allocator)
	ctx.allocator = allocator

	// Initialize terminal
	term_err := init_terminal()
	if term_err != .None {
		fmt.eprintln("Error: This program requires a terminal (TTY) to run.")
		fmt.eprintln("Please run it from a command line terminal, not from an IDE or pipe.")
		return ctx, .TerminalInitFailed
	}

	// Enter raw mode for immediate input
	raw_err := enter_raw_mode()
	if raw_err != .None {
		return ctx, .RawModeFailed
	}

	// Enter alternate screen buffer (prevents frames in history)
	alt_err := enter_alternate_buffer()
	if alt_err != .None {
		return ctx, .TerminalInitFailed
	}

	// Get terminal size
	width, height, size_err := get_terminal_size()
	if size_err != .None {
		return ctx, .TerminalInitFailed
	}

	ctx.width = width
	ctx.height = height

	// Initialize buffer
	buf, buf_err := init_buffer(width, height, allocator)
	if buf_err != .None {
		return ctx, .BufferInitFailed
	}
	ctx.buffer = buf


	// Initialize layout context
	ctx.layout_ctx = init_layout_context(allocator)

	// Initialize reusable render buffer with pre-allocated capacity
	// For 80x24 terminal with ANSI codes: ~1920 chars + styles, use 16KB for safety
	render_buf, render_buf_err := strings.builder_make_len_cap(0, 16384, allocator)
	if render_buf_err != .None {
		return ctx, .BufferInitFailed
	}
	ctx.render_buffer = render_buf

	// Initialize focus tracking
	ctx.focusable_items = make([dynamic]u64, allocator)

	// Initial terminal setup
	disable_auto_wrap()
	hide_cursor()
	clear_screen()

	// Initialize frame timing
	ctx.frame_start_time = time.now()

	return ctx, .None
}

// shutdown cleans up the context and restores terminal state
// Always call this before exiting to avoid corrupting the terminal
shutdown :: proc(ctx: ^Context) {
	if ctx == nil {
		return
	}

	// Clean up buffer
	destroy_buffer(&ctx.buffer)


	// Clean up layout context
	destroy_layout_context(&ctx.layout_ctx)

	// Clean up render buffer
	strings.builder_destroy(&ctx.render_buffer)

	// Restore terminal
	reset_terminal()

	// Free context
	delete(ctx.focusable_items)
	free(ctx, ctx.allocator)
}

// begin_frame starts a new frame
// Call this at the beginning of your render loop
// In immediate mode, we clear the entire buffer each frame
begin_frame :: proc(ctx: ^Context) {
	// Record frame start time for FPS/frame time calculation
	ctx.frame_start_time = time.now()

	// Check for terminal size changes (every frame)
	// Since we now use ioctl() which is non-blocking, this is safe and efficient
	current_width, current_height, size_err := get_terminal_size()
	if size_err == .None && (current_width != ctx.width || current_height != ctx.height) {
		// Terminal was resized - update context
		_handle_resize(ctx, current_width, current_height)
	}

	// Clear buffer for new frame
	clear_buffer(&ctx.buffer)

	// Reset focusable items for this frame
	clear(&ctx.focusable_items)
}

// end_frame finishes the current frame and outputs to terminal
// In immediate mode, we render the entire buffer every frame
end_frame :: proc(ctx: ^Context) {
	// Begin synchronized update to prevent flickering (Mode 2026)
	// This is especially important for Ghostty terminal emulator
	begin_sync_update()

	// Check terminal size one last time before rendering
	// This handles the race condition where terminal shrinks *during* the frame
	// If we don't do this, we might write a line that no longer exists, causing scroll/flicker
	real_w, real_h, _ := get_terminal_size()

	// Generate full render output, clipping to actual terminal size
	// Reusable builder avoids per-frame allocations
	output := render_to_string(&ctx.buffer, &ctx.render_buffer, real_w, real_h)

	// Write to terminal
	write_ansi(output)
	// Move cursor to home (1,1) to prevent scrolling on shrink if cursor was at bottom
	write_ansi("\x1b[H")

	// End synchronized update - terminal atomically displays the frame
	end_sync_update()
	flush_output()

	// Calculate frame time (for debug purposes)
	frame_end_time := time.now()
	ctx.last_frame_time = time.diff(ctx.frame_start_time, frame_end_time)

	ctx.frame_count += 1
}

// run executes the event-driven main loop
// This is the primary entry point for event-driven TUI applications.
// The callback is called whenever an event occurs (input or resize).
//
// The callback receives the context and returns true to continue, false to exit.
// Inside the callback, you should:
//   1. Call poll_events() to get pending input events
//   2. Process events and update your application state
//   3. Use Layout API to define your UI
//
// Example:
//   ansuz.run(ctx, proc(ctx: ^ansuz.Context) -> bool {
//       for event in ansuz.poll_events(ctx) {
//           if is_quit(event) do return false
//       }
//       render_my_ui(ctx)
//       return true
//   })
//
run :: proc(ctx: ^Context, update: proc(ctx: ^Context) -> bool) {
	// Initial render pass (to show UI immediately)
	begin_frame(ctx)
	if !update(ctx) {
		end_frame(ctx)
		return
	}
	end_frame(ctx)

	for {
		// Wait for events (input or resize) - blocks until something happens
		result, new_w, new_h := wait_for_event(ctx.width, ctx.height)

		// Handle resize
		if result == .Resize {
			_handle_resize(ctx, new_w, new_h)
		}

		// Start frame
		begin_frame(ctx)

		// Call user's update/render callback
		should_continue := update(ctx)

		// End frame (renders to terminal)
		end_frame(ctx)

		if !should_continue {
			break
		}
	}
}


// poll_events reads and parses input events from the terminal
// Returns a slice of events that occurred since last poll
// Events are consumed from the internal buffer
poll_events :: proc(ctx: ^Context) -> []Event {
	// Read raw input and parse into events
	// This is a simplified version - production would buffer partial sequences
	events: [dynamic]Event

	input_buffer: [32]u8
	bytes_read := 0

	// Read all available input
	for {
		b, available := read_input()
		if !available {
			break
		}

		input_buffer[bytes_read] = b
		bytes_read += 1

		// Try to parse what we have
		if bytes_read >= len(input_buffer) {
			break
		}
	}

	// Parse the input if we got any
	if bytes_read > 0 {
		ev, parsed := parse_input(input_buffer[:bytes_read])
		if parsed {
			append(&events, ev)
		}
	}

	return events[:]
}

// text is a convenience function to write styled text to the buffer
// This is a building block for more complex widget functions
text :: proc(ctx: ^Context, x, y: int, content: string, style: Style) {
	write_string(&ctx.buffer, x, y, content, style.fg, style.bg, style.flags)
}

// box draws a bordered box
box :: proc(ctx: ^Context, x, y, width, height: int, style: Style, box_style: BoxStyle = .Sharp) {
	draw_box(&ctx.buffer, x, y, width, height, style.fg, style.bg, style.flags, box_style)
}

// rect fills a rectangular region with a character
rect :: proc(ctx: ^Context, x, y, width, height: int, char: rune, style: Style) {
	fill_rect(&ctx.buffer, x, y, width, height, char, style.fg, style.bg, style.flags)
}

// _handle_resize updates the context when terminal size changes
// Called automatically by begin_frame and run()
_handle_resize :: proc(ctx: ^Context, new_width, new_height: int) {
	ctx.width = new_width
	ctx.height = new_height

	// Ensure terminal state is clean on resize
	disable_auto_wrap()
	move_cursor_home()

	resize_buffer(&ctx.buffer, new_width, new_height)
}

// --- Layout API (Clay-like) ---

// begin_layout starts a layout definition for the entire screen
begin_layout :: proc(ctx: ^Context) {
	reset_layout_context(&ctx.layout_ctx, Rect{0, 0, ctx.width, ctx.height})
}

// end_layout calculates the layout and renders all nodes
end_layout :: proc(ctx: ^Context) {
	finish_layout(&ctx.layout_ctx, ctx)
}

// layout_begin_container starts a new layout container
layout_begin_container :: proc(ctx: ^Context, config: LayoutConfig) {
	begin_container(&ctx.layout_ctx, config)
}

// layout_end_container ends the current layout container
layout_end_container :: proc(ctx: ^Context) {
	end_container(&ctx.layout_ctx)
}

// layout_text adds a text node to the current layout container
layout_text :: proc(
	ctx: ^Context,
	content: string,
	style: Style,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
) {
	add_text(&ctx.layout_ctx, content, style, config)
}

// layout_box adds a bordered box node to the current layout container
layout_box :: proc(
	ctx: ^Context,
	style: Style,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
	box_style: BoxStyle = .Sharp,
) {
	add_box_container(&ctx.layout_ctx, style, config, box_style)
}

// layout_rect adds a filled rectangular node to the current layout container
layout_rect :: proc(
	ctx: ^Context,
	char: rune,
	style: Style,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
) {
	add_rect_container(&ctx.layout_ctx, char, style, config)
}

// --- Focus API ---

// id generates a stable ID from a string label (using FNV-1a hash)
id :: proc(ctx: ^Context, label: string) -> u64 {
	return hash.fnv64a(transmute([]u8)label)
}

// set_focus explicitly sets the focused element
set_focus :: proc(ctx: ^Context, id: u64) {
	ctx.last_focus_id = ctx.focus_id
	ctx.focus_id = id
}

// is_focused checks if the given ID currently has focus
is_focused :: proc(ctx: ^Context, id: u64) -> bool {
	return ctx.focus_id == id
}

// register_focusable registers an item as focusable for the current frame.
// This is used to build the tab navigation order.
register_focusable :: proc(ctx: ^Context, id: u64) {
	append(&ctx.focusable_items, id)
}
