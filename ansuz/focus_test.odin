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

@(test)
test_button_theme_focused_vs_unfocused :: proc(t: ^testing.T) {
	// Test that button theme changes correctly based on focus state
	theme := default_theme_full()
	
	// Unfocused button
	unfocused_theme := get_button_theme(&theme, false)
	testing.expect(t, unfocused_theme.prefix == "[ ] ", "Unfocused button should have [ ] prefix")
	testing.expect(t, unfocused_theme.style.fg == .White, "Unfocused button should have White fg")
	testing.expect(t, unfocused_theme.style.bg == .Default, "Unfocused button should have Default bg")
	
	// Focused button  
	focused_theme := get_button_theme(&theme, true)
	testing.expect(t, focused_theme.prefix == "[*] ", "Focused button should have [*] prefix")
	testing.expect(t, focused_theme.style.fg == .Black, "Focused button should have Black fg")
	testing.expect(t, focused_theme.style.bg == .BrightCyan, "Focused button should have BrightCyan bg")
	testing.expect(t, .Bold in focused_theme.style.flags, "Focused button should have Bold flag")
}

@(test)
test_checkbox_theme_states :: proc(t: ^testing.T) {
	// Test all 4 checkbox theme states
	theme := default_theme_full()
	
	// Unchecked, unfocused
	state1 := get_checkbox_theme(&theme, false, false)
	testing.expect(t, state1.prefix == "[ ] ", "Unchecked unfocused should have [ ] prefix")
	
	// Checked, unfocused
	state2 := get_checkbox_theme(&theme, true, false)
	testing.expect(t, state2.prefix == "[x] ", "Checked unfocused should have [x] prefix")
	
	// Unchecked, focused
	state3 := get_checkbox_theme(&theme, false, true)
	testing.expect(t, state3.prefix == "[ ] ", "Unchecked focused should have [ ] prefix")
	testing.expect(t, state3.style.bg == .BrightCyan, "Unchecked focused should have BrightCyan bg")
	
	// Checked, focused
	state4 := get_checkbox_theme(&theme, true, true)
	testing.expect(t, state4.prefix == "[x] ", "Checked focused should have [x] prefix")
	testing.expect(t, state4.style.bg == .BrightCyan, "Checked focused should have BrightCyan bg")
}

@(test)
test_initial_focus_with_empty_prev_list :: proc(t: ^testing.T) {
	// This test verifies the initial focus scenario:
	// When set_focus() is called before any rendering, and prev_focusable_items is empty,
	// the focus should still work correctly
	ctx := new(Context)
	ctx.allocator = context.allocator
	ctx.focusable_items = make([dynamic]u64, ctx.allocator)
	ctx.prev_focusable_items = make([dynamic]u64, ctx.allocator)
	defer {
		delete(ctx.focusable_items)
		delete(ctx.prev_focusable_items)
		free(ctx)
	}
	
	// Set initial focus before any rendering (simulating the demo scenario)
	initial_focus_id := u64(100)
	set_focus(ctx, initial_focus_id)
	testing.expect(t, ctx.focus_id == initial_focus_id, "Focus should be set correctly")
	testing.expect(t, is_focused(ctx, initial_focus_id), "is_focused should return true for initial focus")
	
	// Now simulate that widgets register during first render
	register_focusable(ctx, 100)
	register_focusable(ctx, 200)
	register_focusable(ctx, 300)
	
	// Simulate begin_frame (swap lists)
	temp := ctx.prev_focusable_items
	ctx.prev_focusable_items = ctx.focusable_items
	ctx.focusable_items = temp
	clear(&ctx.focusable_items)
	
	// prev_focusable_items should now have the items from first frame
	testing.expect(t, len(ctx.prev_focusable_items) == 3, "Should have 3 items in prev list")
	
	// Focus should still be on initial element
	testing.expect(t, ctx.focus_id == 100, "Focus should persist after frame swap")
	
	// Tab navigation should work from initial focus
	changed := handle_tab_navigation(ctx, false)
	testing.expect(t, changed, "Tab should change focus from initial")
	testing.expect(t, ctx.focus_id == 200, "Should move to next focusable item")
}

@(test)
test_is_focused_with_actual_element_id :: proc(t: ^testing.T) {
	// Test that is_focused works with element IDs generated from strings
	ctx := new(Context)
	defer free(ctx)
	
	button_id := u64(element_id("Button 1"))
	other_id := u64(element_id("Button 2"))
	
	set_focus(ctx, button_id)
	
	testing.expect(t, is_focused(ctx, button_id), "Should be focused")
	testing.expect(t, !is_focused(ctx, other_id), "Other button should not be focused")
}

@(test)
test_focus_navigation_after_frame_swap :: proc(t: ^testing.T) {
	// Test that focus navigation works correctly after multiple frame swaps
	ctx := new(Context)
	ctx.allocator = context.allocator
	ctx.focusable_items = make([dynamic]u64, ctx.allocator)
	ctx.prev_focusable_items = make([dynamic]u64, ctx.allocator)
	defer {
		delete(ctx.focusable_items)
		delete(ctx.prev_focusable_items)
		free(ctx)
	}
	
	// Frame 1: Register items
	register_focusable(ctx, 100)
	register_focusable(ctx, 200)
	set_focus(ctx, 100)
	
	// Simulate begin_frame (Frame 1 -> Frame 2)
	temp := ctx.prev_focusable_items
	ctx.prev_focusable_items = ctx.focusable_items
	ctx.focusable_items = temp
	clear(&ctx.focusable_items)
	
	// Tab navigation should work
	handle_tab_navigation(ctx, false)
	testing.expect(t, ctx.focus_id == 200, "Should navigate to 200")
	
	// Register items for frame 2
	register_focusable(ctx, 100)
	register_focusable(ctx, 200)
	register_focusable(ctx, 300)
	
	// Simulate begin_frame (Frame 2 -> Frame 3)
	temp = ctx.prev_focusable_items
	ctx.prev_focusable_items = ctx.focusable_items
	ctx.focusable_items = temp
	clear(&ctx.focusable_items)
	
	// Should now have 3 items in prev list
	testing.expect(t, len(ctx.prev_focusable_items) == 3, "Should have 3 items")
	
	// Navigation should wrap
	handle_tab_navigation(ctx, false)
	testing.expect(t, ctx.focus_id == 300, "Should wrap to 300")
}

@(test)
test_focus_on_missing_element :: proc(t: ^testing.T) {
	// Test behavior when focused element is no longer in the list
	ctx := new(Context)
	ctx.allocator = context.allocator
	ctx.focusable_items = make([dynamic]u64, ctx.allocator)
	ctx.prev_focusable_items = make([dynamic]u64, ctx.allocator)
	defer {
		delete(ctx.focusable_items)
		delete(ctx.prev_focusable_items)
		free(ctx)
	}
	
	// Set focus to an element
	set_focus(ctx, 999)
	
	// Register different elements
	register_focusable(ctx, 100)
	register_focusable(ctx, 200)
	
	// Simulate begin_frame
	temp := ctx.prev_focusable_items
	ctx.prev_focusable_items = ctx.focusable_items
	ctx.focusable_items = temp
	clear(&ctx.focusable_items)
	
	// Focus is on 999 but only 100 and 200 exist
	// Tab should start from beginning since focused element not found
	changed := handle_tab_navigation(ctx, false)
	testing.expect(t, changed, "Should change focus")
	testing.expect(t, ctx.focus_id == 100, "Should select first available item")
}
