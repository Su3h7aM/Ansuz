package ansuz

// This file provides the public API for the Ansuz TUI library
// It combines all the low-level components into a high-level immediate-mode API

import "core:fmt"
import "core:mem"
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

    // Frame timing (for future FPS limiting)
    frame_count:   u64,

    // FPS and frame time measurement
    frame_start_time:     time.Time,
    last_frame_time:      time.Duration,
    fps:                  f32,
    avg_frame_time:       time.Duration,
    frame_time_history:   [dynamic]time.Duration,
    max_history_samples:  int,

    // FPS limiting
    target_fps:           f32,

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

    // Initial terminal setup
    hide_cursor()
    clear_screen()

    // Initialize timing for FPS/frame time measurement
    ctx.frame_time_history = make([dynamic]time.Duration, 0, 60, allocator)
    ctx.max_history_samples = 60
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

    // Clean up timing history
    delete(ctx.frame_time_history)

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
    // Hide cursor during render to prevent flicker
    hide_cursor()

    // Generate full render output
    output := render_to_string(&ctx.buffer, context.temp_allocator)

    // Write to terminal
    write_ansi(output)
    flush_output()

    // Show cursor again
    show_cursor()

    // Calculate frame time and FPS
    frame_end_time := time.now()
    frame_duration := time.diff(ctx.frame_start_time, frame_end_time)
    ctx.last_frame_time = frame_duration

    // Update rolling average
    append(&ctx.frame_time_history, frame_duration)
    if len(ctx.frame_time_history) > ctx.max_history_samples {
        ordered_remove(&ctx.frame_time_history, 0)
    }

    // Calculate FPS
    if len(ctx.frame_time_history) > 0 {
        total_time := time.Duration(0)
        for t in ctx.frame_time_history {
            total_time += t
        }
        avg_time := total_time / time.Duration(len(ctx.frame_time_history))
        ctx.avg_frame_time = avg_time
        ctx.fps = 1.0 / f32(time.duration_seconds(avg_time))
    }

    // FPS limiting
    if ctx.target_fps > 0 {
        target_frame_time_ns := time.Duration(i64(1000000000.0 / ctx.target_fps))
        if frame_duration < target_frame_time_ns {
            time.sleep(target_frame_time_ns - frame_duration)
        }
    }

    ctx.frame_count += 1
}

// get_fps returns the current calculated FPS based on rolling average
get_fps :: proc(ctx: ^Context) -> f32 {
    return ctx.fps
}

// get_avg_frame_time returns the average frame time over recent frames
get_avg_frame_time :: proc(ctx: ^Context) -> time.Duration {
    return ctx.avg_frame_time
}

// get_last_frame_time returns the duration of the most recent frame
get_last_frame_time :: proc(ctx: ^Context) -> time.Duration {
    return ctx.last_frame_time
}

// set_target_fps sets the target FPS for frame rate limiting
// Set to 0 to disable limiting
set_target_fps :: proc(ctx: ^Context, fps: f32) {
    ctx.target_fps = fps
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
box :: proc(ctx: ^Context, x, y, width, height: int, style: Style) {
    draw_box(&ctx.buffer, x, y, width, height, style.fg_color, style.bg_color, style.flags)
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

    // Re-enter alternate screen to ensure proper resize behavior
    // This prevents flicker when resizing
    leave_alternate_buffer()
    enter_alternate_buffer()

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
Layout_box :: proc(ctx: ^Context, style: Style = STYLE_NORMAL, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    add_box(&ctx.layout_ctx, style, config)
}

// Layout_rect adds a filled rectangular node to the current layout container
Layout_rect :: proc(ctx: ^Context, char: rune, style: Style = STYLE_NORMAL, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    add_rect(&ctx.layout_ctx, char, style, config)
}

// Layout_end_box ends the current layout box
Layout_end_box :: proc(ctx: ^Context) {
    Layout_end_container(ctx)
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
