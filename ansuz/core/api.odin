package ansuz

import "core:fmt"
import "core:hash"
import "core:mem"
import "core:strings"
import "core:time"

import at "../terminal"
import ab "../buffer"
import ac "../color"
import al "../layout"

// Context maintains the global state for the TUI library
// This follows the immediate-mode pattern where the context is passed to widget functions
Context :: struct {
    terminal:             at.TerminalState,
    buffer:               ab.FrameBuffer,


    // Terminal dimensions
    width:                int,
    height:               int,

    // Frame timing
    frame_count:          u64,

    // Frame time measurement (for debug purposes)
    frame_start_time:     time.Time,
    last_frame_time:      time.Duration,

    // Reusable string builder for rendering (avoids per-frame allocations)
    render_buffer:        strings.Builder,

    layout_ctx:           al.LayoutContext,
    allocator:            mem.Allocator,
    theme:                ^Theme,

    // Focus state
    focus_id:             u64,
    last_focus_id:        u64,
    focusable_items:      [dynamic]u64,
    prev_focusable_items: [dynamic]u64,
    input_keys:           [dynamic]at.KeyEvent,
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

    term_err := at.init_terminal()
    if term_err != .None {
        fmt.eprintln("Error: This program requires a terminal (TTY) to run.")
        fmt.eprintln("Please run it from a command line terminal, not from an IDE or pipe.")
        return ctx, .TerminalInitFailed
    }

    raw_err := at.enter_raw_mode()
    if raw_err != .None {
        return ctx, .RawModeFailed
    }

    alt_err := at.enter_alternate_buffer()
    if alt_err != .None {
        return ctx, .TerminalInitFailed
    }

    width, height, size_err := at.get_terminal_size()
    if size_err != .None {
        return ctx, .TerminalInitFailed
    }

    ctx.width = width
    ctx.height = height

    buf, buf_err := ab.init_buffer(width, height, allocator)
    if buf_err != .None {
        return ctx, .BufferInitFailed
    }
    ctx.buffer = buf

    ctx.layout_ctx = al.init_layout_context(allocator)

    ctx.theme = new(Theme, allocator)
    ctx.theme^ = default_theme_full()

    render_buf, render_buf_err := strings.builder_make_len_cap(0, 16384, allocator)
    if render_buf_err != .None {
        return ctx, .BufferInitFailed
    }
    ctx.render_buffer = render_buf

    ctx.focusable_items = make([dynamic]u64, allocator)
    ctx.prev_focusable_items = make([dynamic]u64, allocator)
    ctx.input_keys = make([dynamic]at.KeyEvent, allocator)

    at.disable_auto_wrap()
    at.hide_cursor()
    at.clear_screen()

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

    ab.destroy_buffer(&ctx.buffer)

    al.destroy_layout_context(&ctx.layout_ctx)

    strings.builder_destroy(&ctx.render_buffer)

    at.reset_terminal()

    // Free context
    delete(ctx.focusable_items)
    delete(ctx.prev_focusable_items)
    delete(ctx.input_keys)
    free(ctx, ctx.allocator)
}

// render starts and completes a full frame using @(deferred_in_out).
// This is the single entry point for rendering a frame.
// The deferred _scoped_end_render runs automatically when the scope exits,
// processing layout and flushing output to the terminal.
//
// Usage:
//   if ansuz.render(ctx) {
//       if ansuz.container(ctx, { ... }) {
//           ansuz.label(ctx, "Hello!")
//       }
//   }
//
@(deferred_in_out = _scoped_end_render)
render :: proc(ctx: ^Context) -> bool {
    // --- Frame setup ---

    // Record frame start time for FPS/frame time calculation
    ctx.frame_start_time = time.now()

    // Clear per-frame temporary allocations (strings from fmt.tprintf, etc.)
    free_all(context.temp_allocator)

    current_width, current_height, size_err := at.get_terminal_size()
    if size_err == .None && (current_width != ctx.width || current_height != ctx.height) {
        _handle_resize(ctx, current_width, current_height)
    }

    ab.clear_buffer(&ctx.buffer)

    // Swap focus lists: current becomes prev, reused prev becomes new current (and cleared)
    // This gives us the complete list of focusable items from the LAST frame to use for navigation
    temp := ctx.prev_focusable_items
    ctx.prev_focusable_items = ctx.focusable_items
    ctx.focusable_items = temp
    clear(&ctx.focusable_items)

    al.reset_layout_context(&ctx.layout_ctx, al.Rect{0, 0, ctx.width, ctx.height})

    return true
}

_scoped_end_render :: proc(ctx: ^Context, ok: bool) {
    if ok {
        commands := al.finish_layout(&ctx.layout_ctx)
        _execute_render_commands(ctx, commands)

        at.begin_sync_update()

        real_w, real_h, _ := at.get_terminal_size()

        output := ab.render_to_string(&ctx.buffer, &ctx.render_buffer, real_w, real_h)

        at.write_ansi(output)
        at.write_ansi("\x1b[H")

        at.end_sync_update()
        at.flush_output()

        // Calculate frame time
        ctx.last_frame_time = time.diff(ctx.frame_start_time, time.now())
        ctx.frame_count += 1

        // Clear input keys at the END of frame (after all widgets have checked them)
        clear(&ctx.input_keys)
    }
}


// poll_events reads and parses input events from the terminal
// Returns a slice of events that occurred since last poll
// Events are consumed from the internal buffer
// NOTE: This clears input_keys before reading, so call BEFORE rendering
poll_events :: proc(ctx: ^Context) -> []at.Event {
	clear(&ctx.input_keys)

	events: [dynamic]at.Event

	input_buffer: [32]u8
	bytes_read := 0

	for {
		b, available := at.read_input()
		if !available {
			break
		}

		input_buffer[bytes_read] = b
		bytes_read += 1

		if bytes_read >= len(input_buffer) {
			break
		}
	}

	if bytes_read > 0 {
		ev, parsed := at.parse_input(input_buffer[:bytes_read])
		if parsed {
			append(&events, ev)

			#partial switch e in ev {
			case at.KeyEvent:
				append(&ctx.input_keys, e)
			}
		}
	}

	return events[:]
}

text :: proc(ctx: ^Context, x, y: int, content: string, style: ac.Style) {
    ab.write_string(&ctx.buffer, x, y, content, style.fg, style.bg, style.flags)
}

_box :: proc(ctx: ^Context, x, y, width, height: int, style: ac.Style, box_style: ab.BoxStyle = .Sharp) {
    ab.draw_box(&ctx.buffer, x, y, width, height, style.fg, style.bg, style.flags, box_style)
}

_rect :: proc(ctx: ^Context, x, y, width, height: int, char: rune, style: ac.Style) {
    ab.fill_rect(&ctx.buffer, x, y, width, height, char, style.fg, style.bg, style.flags)
}

_handle_resize :: proc(ctx: ^Context, new_width, new_height: int) {
    ctx.width = new_width
    ctx.height = new_height

    at.disable_auto_wrap()
    at.move_cursor_home()

    ab.resize_buffer(&ctx.buffer, new_width, new_height)
}

// --- Layout API (Clay-like) ---
// NOTE: The preferred API is now in scoped.odin - use layout(), container(), box(), etc.
// These lower-level functions are kept for internal use or advanced scenarios.

@(private)
_execute_render_commands :: proc(ctx: ^Context, commands: []al.RenderCommand) {
    for cmd in commands {
        switch cmd.type {
        case .Text:
            if len(cmd.text) > 0 {
                ab.write_string(&ctx.buffer, cmd.rect.x, cmd.rect.y, cmd.text, cmd.style.fg, cmd.style.bg, cmd.style.flags)
            }
        case .Box:
            ab.draw_box(&ctx.buffer, cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h, cmd.style.fg, cmd.style.bg, cmd.style.flags, cmd.box_style)
        case .Rect:
            ab.fill_rect(&ctx.buffer, cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h, cmd.char, cmd.style.fg, cmd.style.bg, cmd.style.flags)
        case .None:
        }
    }
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

// handle_tab_navigation processes Tab/Shift+Tab to cycle focus
// Returns true if focus was changed
// NOTE: Falls back to current frame's focusable_items if prev_focusable_items is empty (first frame)
handle_tab_navigation :: proc(ctx: ^Context, reverse: bool) -> bool {
	// Use prev_focusable_items if available, otherwise fallback to current frame's items
	items := ctx.prev_focusable_items
	if len(items) == 0 && len(ctx.focusable_items) > 0 {
		items = ctx.focusable_items
	}

	if len(items) == 0 {
		return false
	}

	// Find current index
	idx := -1
	for id, i in items {
		if id == ctx.focus_id {
			idx = i
			break
		}
	}

	next_idx := 0
	if idx == -1 {
		// Not currently focused, or focused item gone -> start at 0 (or end if reverse)
		if reverse {
			next_idx = len(items) - 1
		} else {
			next_idx = 0
		}
	} else {
		// Move to next/prev
		if reverse {
			next_idx = idx - 1
			if next_idx < 0 {
				next_idx = len(items) - 1
			}
		} else {
			next_idx = idx + 1
			if next_idx >= len(items) {
				next_idx = 0
			}
		}
	}

	new_id := items[next_idx]
	set_focus(ctx, new_id)
	return true
}

// --- Re-exports from subpackages ---

// Terminal
is_quit_key :: at.is_quit_key
wait_for_event :: proc(ctx: ^Context, timeout_ms: i32 = -1) -> (result: at.WaitResult, new_width: int, new_height: int) {
	return at.wait_for_event(ctx.width, ctx.height, timeout_ms)
}
Event :: at.Event
KeyEvent :: at.KeyEvent
Key :: at.Key
KeyModifiers :: at.KeyModifiers
ResizeEvent :: at.ResizeEvent
MouseEvent :: at.MouseEvent

// Layout
grow :: al.grow
fixed :: al.fixed
fit :: al.fit
percent :: al.percent
padding_all :: al.padding_all

// Color
style :: ac.style
default_style :: ac.default_style
Ansi :: ac.Ansi
Style :: ac.Style
StyleFlags :: ac.StyleFlags
TerminalColor :: ac.TerminalColor
rgb :: ac.rgb
hex :: ac.hex
color256 :: ac.color256
grayscale :: ac.grayscale
RGB :: ac.RGB

// Buffer
BoxStyle :: ab.BoxStyle
Rect :: al.Rect

// Layout types
LayoutConfig :: al.LayoutConfig
DEFAULT_LAYOUT_CONFIG :: al.DEFAULT_LAYOUT_CONFIG
Alignment :: al.Alignment
LayoutDirection :: al.LayoutDirection
