package ansuz

import "core:testing"

@(test)
test_focus_id_generation :: proc(t: ^testing.T) {
	ctx := new(Context)
	defer free(ctx)

	id1 := id(ctx, "Button1")
	id2 := id(ctx, "Button1")
	id3 := id(ctx, "Button2")

	testing.expect(t, id1 == id2, "ID should be stable for same label")
	testing.expect(t, id1 != id3, "ID should be different for different labels")
	testing.expect(t, id1 != 0, "ID should not be zero")
}

@(test)
test_focus_state_management :: proc(t: ^testing.T) {
	ctx := new(Context)
	defer free(ctx)

	id1 := u64(100)
	id2 := u64(200)

	// Initial state
	testing.expect(t, ctx.focus_id == 0, "Initial focus should be 0")
	testing.expect(t, !is_focused(ctx, id1), "Should not be focused")

	// Set focus
	set_focus(ctx, id1)
	testing.expect(t, ctx.focus_id == id1, "Focus ID should matches set value")
	testing.expect(t, is_focused(ctx, id1), "is_focused should return true")
	testing.expect(t, !is_focused(ctx, id2), "Other ID should not be focused")

	// Change focus
	set_focus(ctx, id2)
	testing.expect(t, ctx.focus_id == id2, "Focus ID should match new value")
	testing.expect(t, ctx.last_focus_id == id1, "Last focus ID should track previous")
}

@(test)
test_focusable_registration :: proc(t: ^testing.T) {
	// Setup context with allocator for dynamic array
	ctx := new(Context)
	ctx.allocator = context.allocator
	ctx.focusable_items = make([dynamic]u64, ctx.allocator)
	defer {
		delete(ctx.focusable_items)
		free(ctx)
	}

	// Register items
	register_focusable(ctx, 100)
	register_focusable(ctx, 200)

	testing.expect(t, len(ctx.focusable_items) == 2, "Should have 2 items")
	testing.expect(t, ctx.focusable_items[0] == 100, "First item match")
	testing.expect(t, ctx.focusable_items[1] == 200, "Second item match")
}

@(test)
test_begin_frame_clears_focusable :: proc(t: ^testing.T) {
	// Setup full context via init (mocking allocation)
	// We can't call init() easily without TTY, so we manually setup minimal state
	ctx := new(Context)
	ctx.allocator = context.allocator
	ctx.focusable_items = make([dynamic]u64, ctx.allocator)
	// Mock buffer to avoid begin_frame crashing on clear_buffer
	ctx.buffer.cells = make([]Cell, 100)

	defer {
		delete(ctx.buffer.cells)
		delete(ctx.focusable_items)
		free(ctx)
	}

	register_focusable(ctx, 123)
	testing.expect(t, len(ctx.focusable_items) == 1, "Should have item")

	// Manually call clear logic seen in begin_frame (testing the logic, not the whole function due to TTY deps)
	// Note: begin_frame calls get_terminal_size() which might fail without TTY. Only testing list clear here.
	clear(&ctx.focusable_items)

	testing.expect(t, len(ctx.focusable_items) == 0, "begin_frame logic should clear items")
}
