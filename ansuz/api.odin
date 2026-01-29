package ansuz

// This file provides the public API for the Ansuz TUI library
// It combines all the low-level components into a high-level immediate-mode API

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:time"

// Context maintains the global state for the TUI library
// This follows the immediate-mode pattern where the context is passed to widget functions
Context :: struct {
    // Terminal state
    terminal:      TerminalState,

    // Single buffer (immediate mode - redraws every frame)
    buffer:        FrameBuffer,

    // Event handling
    event_buffer:  EventBuffer,

    // Terminal dimensions
    width:         int,
    height:        int,

    // Frame timing
    frame_count:   u64,

    // Frame time measurement (for debug purposes)
    frame_start_time:     time.Time,
    last_frame_time:      time.Duration,

    // Reusable string builder for rendering (avoids per-frame allocations)
    render_buffer: strings.Builder,

    // Layout system
    layout_ctx:    LayoutContext,

    // Allocator for internal allocations
    allocator:     mem.Allocator,
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

    // Initialize event buffer
    ctx.event_buffer = init_event_buffer(128, allocator)

    // Initialize layout context
    ctx.layout_ctx = init_layout_context(allocator)

    // Initialize reusable render buffer with pre-allocated capacity
    // For 80x24 terminal with ANSI codes: ~1920 chars + styles, use 16KB for safety
    render_buf, render_buf_err := strings.builder_make_len_cap(0, 16384, allocator)
    if render_buf_err != .None {
        return ctx, .BufferInitFailed
    }
    ctx.render_buffer = render_buf

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
    
    // Clean up event buffer
    destroy_event_buffer(&ctx.event_buffer)

    // Clean up layout context
    destroy_layout_context(&ctx.layout_ctx)

    // Clean up render buffer
    strings.builder_destroy(&ctx.render_buffer)

    // Restore terminal
    reset_terminal()

    // Free context
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
        handle_resize(ctx, current_width, current_height)
    }

    // Clear buffer for new frame
    clear_buffer(&ctx.buffer)
}

// end_frame finishes the current frame and outputs to terminal
// In immediate mode, we render the entire buffer every frame
end_frame :: proc(ctx: ^Context) {
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
    for {
        // Wait for events (input or resize) - blocks until something happens
        result, new_w, new_h := wait_for_event(ctx.width, ctx.height)
        
        // Handle resize
        if result == .Resize {
            handle_resize(ctx, new_w, new_h)
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

// request_redraw can be used to force a re-render on the next wait_for_event cycle
// Currently a no-op placeholder for future timer-based animations
request_redraw :: proc(ctx: ^Context) {
    // Future: set a flag that causes wait_for_event to return immediately
    // For now, the 100ms poll timeout ensures periodic refreshes
}

// get_last_frame_time returns the duration of the most recent frame
get_last_frame_time :: proc(ctx: ^Context) -> time.Duration {
    return ctx.last_frame_time
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
    write_string(&ctx.buffer, x, y, content, style.fg_color, style.bg_color, style.flags)
}

// box draws a bordered box
box :: proc(ctx: ^Context, x, y, width, height: int, style: Style, box_style: BoxStyle = .Sharp) {
    draw_box(&ctx.buffer, x, y, width, height, style.fg_color, style.bg_color, style.flags, box_style)
}

// rect fills a rectangular region with a character
rect :: proc(ctx: ^Context, x, y, width, height: int, char: rune, style: Style) {
    fill_rect(&ctx.buffer, x, y, width, height, char, style.fg_color, style.bg_color, style.flags)
}

// get_size returns the current terminal dimensions
get_size :: proc(ctx: ^Context) -> (width, height: int) {
    return ctx.width, ctx.height
}

// handle_resize updates the context when terminal size changes
// Should be called when a resize event is detected
handle_resize :: proc(ctx: ^Context, new_width, new_height: int) {
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

// Layout_begin_container starts a new layout container
Layout_begin_container :: proc(ctx: ^Context, config: LayoutConfig) {
    begin_container(&ctx.layout_ctx, config)
}

// Layout_end_container ends the current layout container
Layout_end_container :: proc(ctx: ^Context) {
    end_container(&ctx.layout_ctx)
}

// Layout_text adds a text node to the current layout container
Layout_text :: proc(ctx: ^Context, content: string, style: Style = STYLE_NORMAL, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    add_text(&ctx.layout_ctx, content, style, config)
}

// Layout_box adds a bordered box node to the current layout container
Layout_box :: proc(ctx: ^Context, style: Style = STYLE_NORMAL, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG, box_style: BoxStyle = .Sharp) {
    add_box_container(&ctx.layout_ctx, style, config, box_style)
}

// Layout_rect adds a filled rectangular node to the current layout container
Layout_rect :: proc(ctx: ^Context, char: rune, style: Style = STYLE_NORMAL, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    add_rect_container(&ctx.layout_ctx, char, style, config)
}

// Layout_end_box ends the current layout box
Layout_end_box :: proc(ctx: ^Context) {
    end_box_container(&ctx.layout_ctx)
}

// Layout_end_rect ends the current layout rect
Layout_end_rect :: proc(ctx: ^Context) {
    end_rect_container(&ctx.layout_ctx)
}

// Predefined styles for convenience
STYLE_NORMAL :: Style{.Default, .Default, {}}
STYLE_BOLD :: Style{.Default, .Default, {.Bold}}
STYLE_DIM :: Style{.Default, .Default, {.Dim}}
STYLE_UNDERLINE :: Style{.Default, .Default, {.Underline}}
STYLE_ERROR :: Style{.Red, .Default, {.Bold}}
STYLE_SUCCESS :: Style{.Green, .Default, {}}
STYLE_WARNING :: Style{.Yellow, .Default, {}}
STYLE_INFO :: Style{.Cyan, .Default, {}}
