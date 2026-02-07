package ansuz

import "core:testing"

// ============================================================================
// Element ID Tests
// ============================================================================

@(test)
test_element_id_unique :: proc(t: ^testing.T) {
	id1 := element_id("button1")
	id2 := element_id("button2")
	id3 := element_id("button1") // Same as id1

	testing.expect(t, id1 != id2, "Different labels should produce different IDs")
	testing.expect(t, id1 == id3, "Same labels should produce same IDs")
}

@(test)
test_element_id_deterministic :: proc(t: ^testing.T) {
	// Same label should always produce same ID
	label := "consistent_label"
	id1 := element_id(label)
	id2 := element_id(label)
	id3 := element_id(label)

	testing.expect(t, id1 == id2, "element_id should be deterministic")
	testing.expect(t, id2 == id3, "element_id should be deterministic")
}

// ============================================================================
// Element Struct Tests
// ============================================================================

@(test)
test_element_default :: proc(t: ^testing.T) {
	el := element_default()

	testing.expect(t, el.direction == .TopToBottom, "Default direction should be TopToBottom")
	testing.expect(t, el.focusable == false, "Default focusable should be false")
	testing.expect(t, el.id_source == "", "Default id_source should be empty")
	testing.expect(t, el.box_style == nil, "Default box_style should be nil")
	testing.expect(t, el.content == nil, "Default content should be nil")
}

@(test)
test_element_using_layout :: proc(t: ^testing.T) {
	// Test that 'using layout' allows direct field access
	el := Element {
		sizing = {.X = grow(), .Y = fixed(1)},
		direction = .LeftToRight,
		gap = 2,
	}

	testing.expect(t, el.sizing[.X].type == .Grow, "sizing should be accessible directly")
	testing.expect(t, el.sizing[.Y].type == .Fixed, "sizing Y should be Fixed")
	testing.expect(t, el.sizing[.Y].value == 1, "sizing Y value should be 1")
	testing.expect(t, el.direction == .LeftToRight, "direction should be LeftToRight")
	testing.expect(t, el.gap == 2, "gap should be 2")
}

@(test)
test_element_with_content :: proc(t: ^testing.T) {
	el := Element {
		content = "Hello World",
		style   = style(.White, .Default, {}),
	}

	content, ok := el.content.?
	testing.expect(t, ok, "content should be set")
	testing.expect(t, content == "Hello World", "content should match")
}

@(test)
test_element_with_box_style :: proc(t: ^testing.T) {
	el := Element {
		box_style = BoxStyle.Rounded,
		style     = style(.Cyan, .Default, {}),
	}

	bs, ok := el.box_style.?
	testing.expect(t, ok, "box_style should be set")
	testing.expect(t, bs == .Rounded, "box_style should be Rounded")
}

// ============================================================================
// Render Command Generation Tests
// ============================================================================

@(test)
test_element_to_render_cmd_text :: proc(t: ^testing.T) {
	el := Element {
		content = "Test text",
		style   = style(.Green, .Default, {}),
	}

	cmd := _element_to_render_cmd(el)

	testing.expect(t, cmd.type == .Text, "command type should be Text")
	testing.expect(t, cmd.text == "Test text", "command text should match")
}

@(test)
test_element_to_render_cmd_box :: proc(t: ^testing.T) {
	el := Element {
		box_style = BoxStyle.Sharp,
		style     = style(.White, .Blue, {}),
	}

	cmd := _element_to_render_cmd(el)

	testing.expect(t, cmd.type == .Box, "command type should be Box")
	testing.expect(t, cmd.box_style == .Sharp, "command box_style should be Sharp")
}

@(test)
test_element_to_render_cmd_rect :: proc(t: ^testing.T) {
	el := Element {
		fill_char = '#',
		style     = style(.Red, .Default, {}),
	}

	cmd := _element_to_render_cmd(el)

	testing.expect(t, cmd.type == .Rect, "command type should be Rect")
	testing.expect(t, cmd.char == '#', "command char should be #")
}

@(test)
test_element_to_render_cmd_none :: proc(t: ^testing.T) {
	el := Element{}

	cmd := _element_to_render_cmd(el)

	testing.expect(t, cmd.type == .None, "command type should be None for empty element")
}

@(test)
test_element_priority_content_over_box :: proc(t: ^testing.T) {
	// Content should take priority over box_style
	el := Element {
		content   = "Text wins",
		box_style = BoxStyle.Rounded,
	}

	cmd := _element_to_render_cmd(el)

	testing.expect(t, cmd.type == .Text, "content should take priority over box_style")
}

// ============================================================================
// Integration Tests
// ============================================================================

@(test)
test_element_layout_integration :: proc(t: ^testing.T) {
	l_ctx := init_layout_context()
	defer destroy_layout_context(&l_ctx)

	reset_layout_context(&l_ctx, Rect{0, 0, 80, 24})

	// Add root container
	begin_container(&l_ctx, LayoutConfig{sizing = {.X = grow(), .Y = grow()}})

	// Add text node using internal element processing
	el := Element {
		content = "Test",
		sizing = {.X = fit(), .Y = fixed(1)},
	}
	config := el.layout
	if txt, ok := el.content.?; ok {
		if config.sizing[.X].type == .FitContent {
			config.sizing[.X].value = f32(len(txt))
		}
	}
	node_idx := _add_node(&l_ctx, config, false)
	l_ctx.nodes[node_idx].render_cmd = _element_to_render_cmd(el)

	end_container(&l_ctx)

	testing.expect(t, len(l_ctx.nodes) == 2, "Should have 2 nodes (container + text)")
}

@(test)
test_widget_theme_integration :: proc(t: ^testing.T) {
	// Initialize minimal context
	ctx := new(Context)
	defer free(ctx)
	defer delete(ctx.focusable_items) // Clean up focusable items allocated by register_focusable
	ctx.layout_ctx = init_layout_context()
	defer destroy_layout_context(&ctx.layout_ctx)


	// Initialize theme
	ctx.theme = new(Theme)
	ctx.theme^ = default_theme_full()
	defer free(ctx.theme)

	// Customize theme
	ctx.theme.button.prefix = "[CUSTOM] "

	// Create button
	reset_layout_context(&ctx.layout_ctx, Rect{0, 0, 80, 24})
	widget_button(ctx, "Test")

	// Check the last added node (widget_button adds one node for the element)
	// element() adds a leaf node.
	node := ctx.layout_ctx.nodes[0] // Should be the button

	// Expected text: "[CUSTOM] Test"
	expected := "[CUSTOM] Test"

	testing.expect(
		t,
		node.render_cmd.text == expected,
		"Button identifier should use theme prefix",
	)
}
