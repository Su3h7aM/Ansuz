package ansuz

// This file provides the public API for the Ansuz TUI library
// It combines all the low-level components into a high-level immediate-mode API

import "core:mem"

// Context maintains the global state for the TUI library
// This follows the immediate-mode pattern where the context is passed to widget functions
Context :: struct {
    // Terminal state
    terminal:      TerminalState,
    
    // Double buffering
    front_buffer:  FrameBuffer,
    back_buffer:   FrameBuffer,
    
    // Event handling
    event_buffer:  EventBuffer,
    
    // Terminal dimensions
    width:         int,
    height:        int,
    
    // Frame timing (for future FPS limiting)
    frame_count:   u64,
    
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
        return ctx, .TerminalInitFailed
    }
    
    // Enter raw mode for immediate input
    raw_err := enter_raw_mode()
    if raw_err != .None {
        return ctx, .RawModeFailed
    }
    
    // Get terminal size
    width, height, size_err := get_terminal_size()
    if size_err != .None {
        return ctx, .TerminalInitFailed
    }
    
    ctx.width = width
    ctx.height = height

    // Initialize buffers
    front_buf, front_err := init_buffer(width, height, allocator)
    if front_err != .None {
        return ctx, .BufferInitFailed
    }
    ctx.front_buffer = front_buf

    back_buf, back_err := init_buffer(width, height, allocator)
    if back_err != .None {
        return ctx, .BufferInitFailed
    }
    ctx.back_buffer = back_buf

    // Initialize event buffer
    ctx.event_buffer = init_event_buffer()

    // Initialize layout context
    ctx.layout_ctx = init_layout_context(allocator)

    // Initial terminal setup
    hide_cursor()
    clear_screen()
    
    return ctx, .None
}

// shutdown cleans up the context and restores terminal state
// Always call this before exiting to avoid corrupting the terminal
shutdown :: proc(ctx: ^Context) {
    if ctx == nil {
        return
    }

    // Clean up buffers
    destroy_buffer(&ctx.front_buffer)
    destroy_buffer(&ctx.back_buffer)
    
    // Clean up event buffer
    destroy_event_buffer(&ctx.event_buffer)

    // Clean up layout context
    destroy_layout_context(&ctx.layout_ctx)

    // Restore terminal
    reset_terminal()

    // Free context
    free(ctx, ctx.allocator)
}

// begin_frame starts a new frame
// Call this at the beginning of your render loop
begin_frame :: proc(ctx: ^Context) {
    // Clear back buffer for new frame
    clear_buffer(&ctx.back_buffer)
    
    // Clear dirty flags from previous frame
    clear_dirty_flags(&ctx.back_buffer)
}

// end_frame finishes the current frame and outputs to terminal
// This performs diffing and only updates changed cells
end_frame :: proc(ctx: ^Context) {
    // Generate diff output
    output := render_diff(&ctx.back_buffer, &ctx.front_buffer, context.temp_allocator)
    
    // Write to terminal
    write_ansi(output)
    flush_output()
    
    // Swap buffers (copy back to front for next frame comparison)
    // Note: We could optimize this by swapping pointers instead
    copy(ctx.front_buffer.cells, ctx.back_buffer.cells)
    
    ctx.frame_count += 1
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

// text is a convenience function to write styled text to the back buffer
// This is a building block for more complex widget functions
text :: proc(ctx: ^Context, x, y: int, content: string, style: Style) {
    write_string(&ctx.back_buffer, x, y, content, style.fg_color, style.bg_color, style.flags)
}

// box draws a bordered box
box :: proc(ctx: ^Context, x, y, width, height: int, style: Style) {
    draw_box(&ctx.back_buffer, x, y, width, height, style.fg_color, style.bg_color, style.flags)
}

// rect fills a rectangular region with a character
rect :: proc(ctx: ^Context, x, y, width, height: int, char: rune, style: Style) {
    fill_rect(&ctx.back_buffer, x, y, width, height, char, style.fg_color, style.bg_color, style.flags)
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
    
    resize_buffer(&ctx.front_buffer, new_width, new_height)
    resize_buffer(&ctx.back_buffer, new_width, new_height)
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
layout_text :: proc(ctx: ^Context, content: string, style: Style = STYLE_NORMAL, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    add_text(&ctx.layout_ctx, content, style, config)
}

// layout_box adds a bordered box node to the current layout container
layout_box :: proc(ctx: ^Context, style: Style = STYLE_NORMAL, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    add_box(&ctx.layout_ctx, style, config)
}

// layout_rect adds a filled rectangular node to the current layout container
layout_rect :: proc(ctx: ^Context, char: rune, style: Style = STYLE_NORMAL, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    add_rect(&ctx.layout_ctx, char, style, config)
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
