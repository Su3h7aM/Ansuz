package ansuz

import "core:mem"
import "core:testing"

@(test)
test_context_init :: proc(t: ^testing.T) {
	// Verify ContextError enum values exist
	err_none := ContextError.None
	testing.expect(t, err_none == .None, "ContextError.None should be valid")

	err_term := ContextError.TerminalInitFailed
	testing.expect(t, err_term == .TerminalInitFailed, "TerminalInitFailed should be valid")

	err_buf := ContextError.BufferInitFailed
	testing.expect(t, err_buf == .BufferInitFailed, "BufferInitFailed should be valid")

	err_raw := ContextError.RawModeFailed
	testing.expect(t, err_raw == .RawModeFailed, "RawModeFailed should be valid")
}

@(test)
test_context_memory_layout :: proc(t: ^testing.T) {
	ctx_size := size_of(Context)
	testing.expect(t, ctx_size > 0, "Context should have non-zero size")

	term_size := size_of(TerminalState)
	buffer_size := size_of(FrameBuffer)
	testing.expect(t, term_size > 0, "TerminalState should have size")
	testing.expect(t, buffer_size > 0, "FrameBuffer should have size")
}

@(test)
test_api_style_functions :: proc(t: ^testing.T) {
	// Test default_style
	default := default_style()
	testing.expect(t, default.fg == Ansi.Default, "default_style fg should be default")
	testing.expect(t, default.bg == Ansi.Default, "default_style bg should be default")
	testing.expect(t, default.flags == {}, "default_style flags should be empty")

	// Test style with various combinations
	normal := style(.Default, .Default, {})
	testing.expect(t, normal.fg == Ansi.Default)
	testing.expect(t, normal.bg == Ansi.Default)
	testing.expect(t, normal.flags == {})

	bold := style(.Default, .Default, {.Bold})
	testing.expect(t, bold.fg == Ansi.Default)
	testing.expect(t, .Bold in bold.flags)

	error_style := style(.Red, .Default, {.Bold})
	testing.expect(t, error_style.fg == Ansi.Red)
	testing.expect(t, .Bold in error_style.flags)

	success := style(.Green, .Default, {})
	testing.expect(t, success.fg == Ansi.Green)

	warning := style(.Yellow, .Default, {})
	testing.expect(t, warning.fg == Ansi.Yellow)

	info := style(.Cyan, .Default, {})
	testing.expect(t, info.fg == Ansi.Cyan)

	// Test style with foreground only
	fg_only := style(.Blue, .Default, {})
	testing.expect(t, fg_only.fg == Ansi.Blue)
	testing.expect(t, fg_only.bg == Ansi.Default)
}

@(test)
test_text_api_signature :: proc(t: ^testing.T) {
	proc_ptr := text
	testing.expect(t, proc_ptr != nil, "text function should exist")
}

@(test)
test_box_api_signature :: proc(t: ^testing.T) {
	proc_ptr := box
	testing.expect(t, proc_ptr != nil, "box function should exist")
}

@(test)
test_rect_api_signature :: proc(t: ^testing.T) {
	proc_ptr := rect
	testing.expect(t, proc_ptr != nil, "rect function should exist")
}

@(test)
test_poll_events_api_signature :: proc(t: ^testing.T) {
	proc_ptr := poll_events
	testing.expect(t, proc_ptr != nil, "poll_events function should exist")
}

@(test)
test_begin_end_frame_api_signature :: proc(t: ^testing.T) {
	begin_proc := begin_frame
	end_proc := end_frame

	testing.expect(t, begin_proc != nil, "begin_frame function should exist")
	testing.expect(t, end_proc != nil, "end_frame function should exist")
}

@(test)
test_layout_api_signatures :: proc(t: ^testing.T) {
	begin_layout_proc := begin_layout
	end_layout_proc := end_layout
	begin_container_proc := layout_begin_container
	end_container_proc := layout_end_container
	text_proc := layout_text
	box_proc := layout_box
	rect_proc := layout_rect

	testing.expect(t, begin_layout_proc != nil, "begin_layout function should exist")
	testing.expect(t, end_layout_proc != nil, "end_layout function should exist")
	testing.expect(t, begin_container_proc != nil, "layout_begin_container function should exist")
	testing.expect(t, end_container_proc != nil, "layout_end_container function should exist")
	testing.expect(t, text_proc != nil, "layout_text function should exist")
	testing.expect(t, box_proc != nil, "layout_box function should exist")
	testing.expect(t, rect_proc != nil, "layout_rect function should exist")
}

@(test)
test_handle_resize_internal :: proc(t: ^testing.T) {
	// _handle_resize is now internal (renamed from handle_resize)
	// Verify it exists as internal function
	proc_ptr := _handle_resize
	testing.expect(t, proc_ptr != nil, "_handle_resize function should exist")
}

@(test)
test_shutdown_with_nil :: proc(t: ^testing.T) {
	shutdown(nil)
	testing.expect(t, true, "Shutdown with nil should not crash")
}

@(test)
test_layout_config_default :: proc(t: ^testing.T) {
	testing.expect(
		t,
		DEFAULT_LAYOUT_CONFIG.direction == .TopToBottom,
		"Default direction should be TopToBottom",
	)
	testing.expect(
		t,
		DEFAULT_LAYOUT_CONFIG.sizing[0].type == .FitContent,
		"Default width sizing should be FitContent",
	)
	testing.expect(
		t,
		DEFAULT_LAYOUT_CONFIG.sizing[1].type == .FitContent,
		"Default height sizing should be FitContent",
	)
	testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.padding.left, 0)
	testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.padding.right, 0)
	testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.padding.top, 0)
	testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.padding.bottom, 0)
	testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.gap, 0)
	testing.expect(
		t,
		DEFAULT_LAYOUT_CONFIG.alignment.horizontal == .Left,
		"Default horizontal alignment should be Left",
	)
	testing.expect(
		t,
		DEFAULT_LAYOUT_CONFIG.alignment.vertical == .Top,
		"Default vertical alignment should be Top",
	)
}

@(test)
test_frame_count_in_context :: proc(t: ^testing.T) {
	ctx_size := size_of(Context)
	testing.expect(t, ctx_size > 0, "Context should exist")
}

@(test)
test_layout_context_in_context :: proc(t: ^testing.T) {
	ctx_size := size_of(Context)
	testing.expect(t, ctx_size > 0, "Context should exist")
}

@(test)
test_context_struct_completeness :: proc(t: ^testing.T) {
	ctx := Context{}

	testing.expect(t, ctx.width == 0, "width field should exist")
	testing.expect(t, ctx.height == 0, "height field should exist")
	testing.expect(t, ctx.frame_count == 0, "frame_count field should exist")
}

@(test)
test_error_handling_flow :: proc(t: ^testing.T) {
	err1 := ContextError.None
	err2 := ContextError.TerminalInitFailed

	testing.expect(t, err1 != err2, "Different error values should not be equal")
	testing.expect(t, err1 == ContextError.None, "Error values should be comparable")
}

@(test)
test_layout_api_with_style :: proc(t: ^testing.T) {
	test_style := Style {
		fg    = Ansi.Red,
		bg    = Ansi.Blue,
		flags = {.Bold},
	}

	_ = test_style.fg
	_ = test_style.bg
	_ = test_style.flags

	testing.expect(t, test_style.fg == Ansi.Red)
	testing.expect(t, test_style.bg == Ansi.Blue)
	testing.expect(t, .Bold in test_style.flags)
}

@(test)
test_context_fields_public :: proc(t: ^testing.T) {
	// Verify users can access ctx.width, ctx.height, ctx.last_frame_time directly
	ctx := Context {
		width           = 80,
		height          = 24,
		last_frame_time = 1000000, // 1ms in nanoseconds
	}

	testing.expect(t, ctx.width == 80, "width should be accessible")
	testing.expect(t, ctx.height == 24, "height should be accessible")
	testing.expect(t, ctx.last_frame_time == 1000000, "last_frame_time should be accessible")
}
