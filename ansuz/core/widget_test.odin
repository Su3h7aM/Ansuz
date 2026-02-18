package ansuz

import "core:testing"

import at "../terminal"

// ============================================================================
// Input Widget Tests
// ============================================================================

@(test)
test_widget_input_basic_render :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	value := "test"
	cursor_pos := 4

	if _test_render(ctx) {
		widget_input(ctx, "input1", &value, &cursor_pos, "")
	}

	// Should have created at least one node
	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
}

@(test)
test_widget_input_placeholder :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	value := ""
	cursor_pos := 0
	placeholder := "Enter text..."

	if _test_render(ctx) {
		widget_input(ctx, "input2", &value, &cursor_pos, placeholder)
	}

	// Should render successfully with placeholder
	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
}

@(test)
test_widget_input_registers_focusable :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	value := ""
	cursor_pos := 0

	if _test_render(ctx) {
		widget_input(ctx, "input3", &value, &cursor_pos, "")
	}

	// Should register as focusable
	testing.expect(t, len(ctx.focusable_items) == 1)
}

@(test)
test_widget_input_character_typing :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	value := "hel"
	cursor_pos := 3

	// Simulate typing 'l' and 'o'
	append(&ctx.input_keys, at.KeyEvent{key = .Char, rune = 'l'})
	append(&ctx.input_keys, at.KeyEvent{key = .Char, rune = 'o'})

	// Set focus on the input
	set_focus(ctx, u64(element_id("input4")))

	modified := false
	if _test_render(ctx) {
		modified = widget_input(ctx, "input4", &value, &cursor_pos, "")
	}

	testing.expect(t, modified, "Input should report modification")
	testing.expect(t, value == "hello", "Value should be 'hello' after typing")
	testing.expect(t, cursor_pos == 5, "Cursor should be at position 5")
}

@(test)
test_widget_input_backspace :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	value := "hello"
	cursor_pos := 5

	// Simulate backspace
	append(&ctx.input_keys, at.KeyEvent{key = .Backspace})

	// Set focus
	set_focus(ctx, u64(element_id("input5")))

	modified := false
	if _test_render(ctx) {
		modified = widget_input(ctx, "input5", &value, &cursor_pos, "")
	}

	testing.expect(t, modified, "Input should report modification")
	testing.expect(t, value == "hell", "Value should be 'hell' after backspace")
	testing.expect(t, cursor_pos == 4, "Cursor should move back to position 4")
}

@(test)
test_widget_input_cursor_navigation :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	value := "hello"
	cursor_pos := 5

	// Move cursor to start
	append(&ctx.input_keys, at.KeyEvent{key = .Home})

	// Set focus
	set_focus(ctx, u64(element_id("input6")))

	if _test_render(ctx) {
		widget_input(ctx, "input6", &value, &cursor_pos, "")
	}

	testing.expect(t, cursor_pos == 0, "Cursor should be at position 0 after Home")

	// Reset and move right
	cursor_pos = 0
	clear(&ctx.input_keys)
	append(&ctx.input_keys, at.KeyEvent{key = .Right})

	if _test_render(ctx) {
		widget_input(ctx, "input6", &value, &cursor_pos, "")
	}

	testing.expect(t, cursor_pos == 1, "Cursor should be at position 1 after Right")
}

// ============================================================================
// Select Widget Tests
// ============================================================================

@(test)
test_widget_select_basic_render :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	options := []string{"Option A", "Option B", "Option C"}
	selected_idx := 0
	is_open := false

	if _test_render(ctx) {
		widget_select(ctx, "select1", options, &selected_idx, &is_open)
	}

	// Should have created at least one node
	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
}

@(test)
test_widget_select_registers_focusable :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	options := []string{"A", "B", "C"}
	selected_idx := 0
	is_open := false

	if _test_render(ctx) {
		widget_select(ctx, "select2", options, &selected_idx, &is_open)
	}

	// Should register as focusable
	testing.expect(t, len(ctx.focusable_items) == 1)
}

@(test)
test_widget_select_open_toggle :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	options := []string{"A", "B", "C"}
	selected_idx := 0
	is_open := false

	// Set focus and simulate Enter key
	set_focus(ctx, u64(element_id("select3")))
	append(&ctx.input_keys, at.KeyEvent{key = .Enter})

	// Need to simulate the interact() call by checking input_keys
	// For now just test that widget renders without error
	if _test_render(ctx) {
		widget_select(ctx, "select3", options, &selected_idx, &is_open)
	}

	// Widget should render successfully
	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
}

@(test)
test_widget_select_navigation_when_open :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	options := []string{"A", "B", "C"}
	selected_idx := 0
	is_open := true

	// Set focus and navigate down
	set_focus(ctx, u64(element_id("select4")))
	append(&ctx.input_keys, at.KeyEvent{key = .Down})
	append(&ctx.input_keys, at.KeyEvent{key = .Down})

	changed := false
	if _test_render(ctx) {
		changed = widget_select(ctx, "select4", options, &selected_idx, &is_open)
	}

	testing.expect(t, selected_idx == 2, "Should navigate to index 2")
	testing.expect(t, !changed, "Navigation should not trigger change event")
}

@(test)
test_widget_select_selection_when_open :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	options := []string{"A", "B", "C"}
	selected_idx := 1
	is_open := true

	// Set focus and press Enter to confirm
	set_focus(ctx, u64(element_id("select5")))
	append(&ctx.input_keys, at.KeyEvent{key = .Enter})

	changed := false
	if _test_render(ctx) {
		changed = widget_select(ctx, "select5", options, &selected_idx, &is_open)
	}

	testing.expect(t, changed, "Enter should trigger selection change")
	testing.expect(t, !is_open, "Dropdown should close after selection")
}

@(test)
test_widget_select_escape_closes :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	options := []string{"A", "B", "C"}
	selected_idx := 1
	is_open := true

	// Set focus and press Escape
	set_focus(ctx, u64(element_id("select6")))
	append(&ctx.input_keys, at.KeyEvent{key = .Escape})

	if _test_render(ctx) {
		widget_select(ctx, "select6", options, &selected_idx, &is_open)
	}

	testing.expect(t, !is_open, "Dropdown should close on Escape")
	testing.expect(t, selected_idx == 1, "Selection should not change on Escape")
}

@(test)
test_widget_select_bounds_checking :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	options := []string{"A", "B", "C"}
	selected_idx := 2  // Last item
	is_open := true

	// Try to navigate past the end
	set_focus(ctx, u64(element_id("select7")))
	append(&ctx.input_keys, at.KeyEvent{key = .Down})

	if _test_render(ctx) {
		widget_select(ctx, "select7", options, &selected_idx, &is_open)
	}

	testing.expect(t, selected_idx == 2, "Should stay at last index")

	// Try to navigate before start
	selected_idx = 0
	clear(&ctx.input_keys)
	append(&ctx.input_keys, at.KeyEvent{key = .Up})

	if _test_render(ctx) {
		widget_select(ctx, "select7", options, &selected_idx, &is_open)
	}

	testing.expect(t, selected_idx == 0, "Should stay at first index")
}

@(test)
test_widget_select_empty_options :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	options := []string{}
	selected_idx := 0
	is_open := false

	if _test_render(ctx) {
		widget_select(ctx, "select8", options, &selected_idx, &is_open)
	}

	// Should handle empty options gracefully
	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
}
