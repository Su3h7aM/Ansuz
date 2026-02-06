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
	ctx.prev_focusable_items = make([dynamic]u64, ctx.allocator)
	defer {
		delete(ctx.focusable_items)
		delete(ctx.prev_focusable_items)
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
test_begin_frame_swaps_focusable :: proc(t: ^testing.T) {
	ctx := new(Context)
	ctx.allocator = context.allocator
	ctx.focusable_items = make([dynamic]u64, ctx.allocator)
	ctx.prev_focusable_items = make([dynamic]u64, ctx.allocator)
	// Minimal mock
	ctx.buffer.cells = make([]Cell, 10)
	defer {
		delete(ctx.buffer.cells)
		delete(ctx.focusable_items)
		delete(ctx.prev_focusable_items)
		free(ctx)
	}

	register_focusable(ctx, 123)
	register_focusable(ctx, 456)

	// Simulate "begin_frame" logic manually since full begin_frame needs TTY
	// Logic: Swap current->prev, clear current
	temp := ctx.prev_focusable_items
	ctx.prev_focusable_items = ctx.focusable_items
	ctx.focusable_items = temp
	clear(&ctx.focusable_items)

	testing.expect(
		t,
		len(ctx.prev_focusable_items) == 2,
		"Prev items should contain last frame items",
	)
	testing.expect(t, ctx.prev_focusable_items[0] == 123, "Order preserved")
	testing.expect(t, len(ctx.focusable_items) == 0, "Current items should be cleared")
}

@(test)
test_tab_navigation :: proc(t: ^testing.T) {
	ctx := new(Context)
	ctx.allocator = context.allocator
	ctx.prev_focusable_items = make([dynamic]u64, ctx.allocator)
	defer {
		delete(ctx.prev_focusable_items)
		free(ctx)
	}

	// Setup prev items (simulation of previous frame)
	append(&ctx.prev_focusable_items, 100)
	append(&ctx.prev_focusable_items, 200)
	append(&ctx.prev_focusable_items, 300)

	// Case 1: No focus -> First item (Forward)
	ctx.focus_id = 0
	changed := handle_tab_navigation(ctx, false) // Forward
	testing.expect(t, changed, "Should change focus")
	testing.expect(t, ctx.focus_id == 100, "Should select first item")

	// Case 2: 100 -> 200 (Forward)
	changed = handle_tab_navigation(ctx, false)
	testing.expect(t, ctx.focus_id == 200, "Should select next item")

	// Case 3: 200 -> 300 (Forward)
	handle_tab_navigation(ctx, false)
	testing.expect(t, ctx.focus_id == 300, "Should select last item")

	// Case 4: 300 -> 100 (Wrap Forward)
	handle_tab_navigation(ctx, false)
	testing.expect(t, ctx.focus_id == 100, "Should wrap to first item")

	// Case 5: 100 -> 300 (Reverse)
	handle_tab_navigation(ctx, true) // Reverse
	testing.expect(t, ctx.focus_id == 300, "Should wrap back to last item")

	// Case 6: 300 -> 200 (Reverse)
	handle_tab_navigation(ctx, true)
	testing.expect(t, ctx.focus_id == 200, "Should go to prev item")
}
