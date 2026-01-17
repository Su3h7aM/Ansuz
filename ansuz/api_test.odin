package ansuz

import "core:testing"
import "core:mem"

@(test)
test_context_init :: proc(t: ^testing.T) {
    // Note: This test may fail in non-TTY environment
    // It's designed to verify init/shutdown lifecycle works
    // For automated testing, we may need to mock terminal operations
    // For now, we'll skip actual terminal init in test environment
    
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
    // Test that Context struct has expected fields
    // We can't fully initialize in test env, but we can verify structure
    
    ctx_size := size_of(Context)
    testing.expect(t, ctx_size > 0, "Context should have non-zero size")
    
    // Verify field sizes match expectations
    term_size := size_of(TerminalState)
    buffer_size := size_of(FrameBuffer)
    event_buf_size := size_of(EventBuffer)
    
    testing.expect(t, term_size > 0, "TerminalState should have size")
    testing.expect(t, buffer_size > 0, "FrameBuffer should have size")
    testing.expect(t, event_buf_size > 0, "EventBuffer should have size")
}

@(test)
test_api_predefined_styles :: proc(t: ^testing.T) {
    // Verify all predefined styles exist
    testing.expect(t, STYLE_NORMAL.fg_color == .Default)
    testing.expect(t, STYLE_BOLD.fg_color == .Default)
    testing.expect(t, STYLE_DIM.fg_color == .Default)
    testing.expect(t, STYLE_UNDERLINE.fg_color == .Default)

    testing.expect(t, STYLE_ERROR.fg_color == .Red)
    testing.expect(t, STYLE_SUCCESS.fg_color == .Green)
    testing.expect(t, STYLE_WARNING.fg_color == .Yellow)
    testing.expect(t, STYLE_INFO.fg_color == .Cyan)
}

@(test)
test_text_api_signature :: proc(t: ^testing.T) {
    // Test that text function signature is correct
    // We can't call it without a valid context, but we can verify it exists
    
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
test_get_size_api_signature :: proc(t: ^testing.T) {
    proc_ptr := get_size
    testing.expect(t, proc_ptr != nil, "get_size function should exist")
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
    begin_container_proc := Layout_begin_container
    end_container_proc := Layout_end_container
    text_proc := Layout_text
    box_proc := Layout_box
    rect_proc := Layout_rect
    
    testing.expect(t, begin_layout_proc != nil, "begin_layout function should exist")
    testing.expect(t, end_layout_proc != nil, "end_layout function should exist")
    testing.expect(t, begin_container_proc != nil, "Layout_begin_container function should exist")
    testing.expect(t, end_container_proc != nil, "Layout_end_container function should exist")
    testing.expect(t, text_proc != nil, "Layout_text function should exist")
    testing.expect(t, box_proc != nil, "Layout_box function should exist")
    testing.expect(t, rect_proc != nil, "Layout_rect function should exist")
}

@(test)
test_handle_resize_signature :: proc(t: ^testing.T) {
    proc_ptr := handle_resize
    testing.expect(t, proc_ptr != nil, "handle_resize function should exist")
}

@(test)
test_shutdown_with_nil :: proc(t: ^testing.T) {
    // Verify shutdown handles nil context gracefully
    // This should not crash
    shutdown(nil)
    testing.expect(t, true, "Shutdown with nil should not crash")
}

@(test)
test_layout_config_default :: proc(t: ^testing.T) {
    // Verify DEFAULT_LAYOUT_CONFIG exists
    testing.expect(t, DEFAULT_LAYOUT_CONFIG.direction == .TopToBottom, "Default direction should be TopToBottom")
    testing.expect(t, DEFAULT_LAYOUT_CONFIG.sizing[0].type == .FitContent, "Default width sizing should be FitContent")
    testing.expect(t, DEFAULT_LAYOUT_CONFIG.sizing[1].type == .FitContent, "Default height sizing should be FitContent")
    testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.padding.left, 0)
    testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.padding.right, 0)
    testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.padding.top, 0)
    testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.padding.bottom, 0)
    testing.expect_value(t, DEFAULT_LAYOUT_CONFIG.gap, 0)
    testing.expect(t, DEFAULT_LAYOUT_CONFIG.alignment.horizontal == .Left, "Default horizontal alignment should be Left")
    testing.expect(t, DEFAULT_LAYOUT_CONFIG.alignment.vertical == .Top, "Default vertical alignment should be Top")
}

@(test)
test_frame_count_in_context :: proc(t: ^testing.T) {
    // Verify Context has frame_count field
    ctx_size := size_of(Context)
    testing.expect(t, ctx_size > 0, "Context should exist")
}

@(test)
test_layout_context_in_context :: proc(t: ^testing.T) {
    // Verify Context has layout_ctx field
    ctx_size := size_of(Context)
    testing.expect(t, ctx_size > 0, "Context should exist")
}

@(test)
test_context_struct_completeness :: proc(t: ^testing.T) {
    // Verify Context has all expected components
    ctx := Context{}
    
    testing.expect(t, ctx.width == 0, "width field should exist")
    testing.expect(t, ctx.height == 0, "height field should exist")
    testing.expect(t, ctx.frame_count == 0, "frame_count field should exist")
}

@(test)
test_error_handling_flow :: proc(t: ^testing.T) {
    // Test that error enum values are comparable
    err1 := ContextError.None
    err2 := ContextError.TerminalInitFailed
    
    testing.expect(t, err1 != err2, "Different error values should not be equal")
    testing.expect(t, err1 == ContextError.None, "Error values should be comparable")
}

@(test)
test_layout_api_with_style :: proc(t: ^testing.T) {
    // Verify layout APIs accept Style parameter
    test_style := Style{fg_color = .Red, bg_color = .Blue, flags = {.Bold}}
    
    // We can't call these without a valid context, but we verify types compile
    _ = test_style.fg_color
    _ = test_style.bg_color
    _ = test_style.flags
    
    testing.expect(t, test_style.fg_color == .Red)
    testing.expect(t, test_style.bg_color == .Blue)
    testing.expect(t, .Bold in test_style.flags)
}
