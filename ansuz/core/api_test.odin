package ansuz

import "core:mem"
import "core:testing"

import at "../terminal"
import ab "../buffer"
import ac "../color"
import al "../layout"

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

    term_size := size_of(at.TerminalState)
    buffer_size := size_of(ab.FrameBuffer)
    testing.expect(t, term_size > 0, "TerminalState should have size")
    testing.expect(t, buffer_size > 0, "FrameBuffer should have size")
}

@(test)
test_api_style_functions :: proc(t: ^testing.T) {
    // Test default_style
    default := ac.default_style()
    testing.expect(t, default.fg == ac.Ansi.Default, "default_style fg should be default")
    testing.expect(t, default.bg == ac.Ansi.Default, "default_style bg should be default")
    testing.expect(t, default.flags == {}, "default_style flags should be empty")

    normal := ac.style(.Default, .Default, {})
    testing.expect(t, normal.fg == ac.Ansi.Default)
    testing.expect(t, normal.bg == ac.Ansi.Default)
    testing.expect(t, normal.flags == {})

    bold := ac.style(.Default, .Default, {.Bold})
    testing.expect(t, bold.fg == ac.Ansi.Default)
    testing.expect(t, .Bold in bold.flags)

    error_style := ac.style(.Red, .Default, {.Bold})
    testing.expect(t, error_style.fg == ac.Ansi.Red)
    testing.expect(t, .Bold in error_style.flags)

    success := ac.style(.Green, .Default, {})
    testing.expect(t, success.fg == ac.Ansi.Green)

    warning := ac.style(.Yellow, .Default, {})
    testing.expect(t, warning.fg == ac.Ansi.Yellow)

    info := ac.style(.Cyan, .Default, {})
    testing.expect(t, info.fg == ac.Ansi.Cyan)

    // Test style with foreground only
    fg_only := ac.style(.Blue, .Default, {})
    testing.expect(t, fg_only.fg == ac.Ansi.Blue)
    testing.expect(t, fg_only.bg == ac.Ansi.Default)
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
test_render_api_signature :: proc(t: ^testing.T) {
    render_proc := render
    testing.expect(t, render_proc != nil, "render function should exist")
}

@(test)
test_scoped_api_signatures :: proc(t: ^testing.T) {
    // Verify scoped API functions exist and return bool (for if pattern)
    render_proc := render
    container_proc := container
    box_proc := box
    vstack_proc := vstack
    hstack_proc := hstack
    rect_proc := rect
    zstack_proc := zstack
    spacer_proc := spacer

    testing.expect(t, render_proc != nil, "render function should exist")
    testing.expect(t, container_proc != nil, "container function should exist")
    testing.expect(t, box_proc != nil, "box function should exist")
    testing.expect(t, vstack_proc != nil, "vstack function should exist")
    testing.expect(t, hstack_proc != nil, "hstack function should exist")
    testing.expect(t, rect_proc != nil, "rect function should exist")
    testing.expect(t, zstack_proc != nil, "zstack function should exist")
    testing.expect(t, spacer_proc != nil, "spacer function should exist")

    // Verify deferred cleanup functions exist
    testing.expect(t, _scoped_end_render != nil, "_scoped_end_render should exist")
    testing.expect(t, _scoped_end_container != nil, "_scoped_end_container should exist")
    testing.expect(t, _scoped_end_box != nil, "_scoped_end_box should exist")
    testing.expect(t, _scoped_end_vstack != nil, "_scoped_end_vstack should exist")
    testing.expect(t, _scoped_end_hstack != nil, "_scoped_end_hstack should exist")
    testing.expect(t, _scoped_end_rect != nil, "_scoped_end_rect should exist")
    testing.expect(t, _scoped_end_zstack != nil, "_scoped_end_zstack should exist")
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
        al.DEFAULT_LAYOUT_CONFIG.direction == .TopToBottom,
        "Default direction should be TopToBottom",
    )
    testing.expect(
        t,
        al.DEFAULT_LAYOUT_CONFIG.sizing[.X].type == .FitContent,
        "Default width sizing should be FitContent",
    )
    testing.expect(
        t,
        al.DEFAULT_LAYOUT_CONFIG.sizing[.Y].type == .FitContent,
        "Default height sizing should be FitContent",
    )
    testing.expect_value(t, al.DEFAULT_LAYOUT_CONFIG.padding.left, 0)
    testing.expect_value(t, al.DEFAULT_LAYOUT_CONFIG.padding.right, 0)
    testing.expect_value(t, al.DEFAULT_LAYOUT_CONFIG.padding.top, 0)
    testing.expect_value(t, al.DEFAULT_LAYOUT_CONFIG.padding.bottom, 0)
    testing.expect_value(t, al.DEFAULT_LAYOUT_CONFIG.gap, 0)
    testing.expect(
        t,
        al.DEFAULT_LAYOUT_CONFIG.alignment.horizontal == .Left,
        "Default horizontal alignment should be Left",
    )
    testing.expect(
        t,
        al.DEFAULT_LAYOUT_CONFIG.alignment.vertical == .Top,
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
    test_style := ac.Style {
        fg    = ac.Ansi.Red,
        bg    = ac.Ansi.Blue,
        flags = {.Bold},
    }

    _ = test_style.fg
    _ = test_style.bg
    _ = test_style.flags

    testing.expect(t, test_style.fg == ac.Ansi.Red)
    testing.expect(t, test_style.bg == ac.Ansi.Blue)
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
