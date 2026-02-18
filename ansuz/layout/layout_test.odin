package ansuz_layout

import "core:testing"
import ac "../color"

@(test)
test_sizing_constructors :: proc(t: ^testing.T) {
	fixed_sizing := fixed(100)
	testing.expect(t, fixed_sizing.type == .Fixed)
	testing.expect_value(t, fixed_sizing.value, 100)

	percent_sizing := percent(0.5)
	testing.expect(t, percent_sizing.type == .Percent)
	testing.expect_value(t, percent_sizing.value, 0.5)

	fit_sizing := fit()
	testing.expect(t, fit_sizing.type == .FitContent)

	grow_sizing := grow(2.0)
	testing.expect(t, grow_sizing.type == .Grow)
	testing.expect_value(t, grow_sizing.value, 2.0)
}

@(test)
test_padding_all :: proc(t: ^testing.T) {
	padding := padding_all(5)
	testing.expect_value(t, padding.left, 5)
	testing.expect_value(t, padding.right, 5)
	testing.expect_value(t, padding.top, 5)
	testing.expect_value(t, padding.bottom, 5)
}

@(test)
test_rect_intersection :: proc(t: ^testing.T) {
	r1 := Rect{0, 0, 10, 10}
	r2 := Rect{5, 5, 10, 10}

	result := rect_intersection(r1, r2)
	testing.expect_value(t, result.x, 5)
	testing.expect_value(t, result.y, 5)
	testing.expect_value(t, result.w, 5)
	testing.expect_value(t, result.h, 5)
}

@(test)
test_rect_is_visible :: proc(t: ^testing.T) {
	r1 := Rect{0, 0, 10, 10}
	testing.expect(t, _rect_is_visible(r1), "Positive dimensions should be visible")

	r2 := Rect{0, 0, 0, 10}
	testing.expect(t, !_rect_is_visible(r2), "Zero width should not be visible")

	r3 := Rect{0, 0, 10, 0}
	testing.expect(t, !_rect_is_visible(r3), "Zero height should not be visible")
}

@(test)
test_clamp_rect :: proc(t: ^testing.T) {
	rect := Rect{5, 5, 10, 10}

	_clamp_rect(&rect, 0, 0, 20, 20, .Hidden)
	testing.expect_value(t, rect.x, 5)
	testing.expect_value(t, rect.y, 5)
	testing.expect_value(t, rect.w, 10)
	testing.expect_value(t, rect.h, 10)

	_clamp_rect(&rect, 0, 0, 20, 20, .Hidden)
	testing.expect_value(t, rect.x, 5)
	testing.expect_value(t, rect.w, 5)
	testing.expect_value(t, rect.h, 10)
}

@(test)
test_layout_context_init_destroy :: proc(t: ^testing.T) {
	l_ctx := init_layout_context()
	defer destroy_layout_context(&l_ctx)

	testing.expect(t, len(l_ctx.nodes) == 0, "Should start with no nodes")
	testing.expect(t, len(l_ctx.stack) == 0, "Should start with empty stack")

	reset_layout_context(&l_ctx, Rect{0, 0, 80, 24})
	testing.expect(t, len(l_ctx.stack) == 1, "Stack should have root marker")
}

@(test)
test_add_text :: proc(t: ^testing.T) {
	l_ctx := init_layout_context()
	defer destroy_layout_context(&l_ctx)

	reset_layout_context(&l_ctx, Rect{0, 0, 80, 24})

	style := ac.default_style()
	add_text(&l_ctx, "Hello", style)
	testing.expect(t, len(l_ctx.nodes) == 1, "Should have one node")

	node := l_ctx.nodes[0]
	testing.expect(t, !node.is_container, "Text node should not be a container")
	testing.expect(t, node.render_cmd.type == .Text, "Should be text render command")
	testing.expect(t, node.render_cmd.text == "Hello", "Should have correct text")
}

@(test)
test_container_stack :: proc(t: ^testing.T) {
	l_ctx := init_layout_context()
	defer destroy_layout_context(&l_ctx)

	reset_layout_context(&l_ctx, Rect{0, 0, 80, 24})

	config := DEFAULT_LAYOUT_CONFIG
	begin_container(&l_ctx, config)
	add_text(&l_ctx, "Child", ac.default_style())
	end_container(&l_ctx)

	testing.expect(t, len(l_ctx.nodes) == 2, "Should have 2 nodes")
	testing.expect(t, len(l_ctx.stack) == 1, "Stack should be back to root")
}

@(test)
test_default_layout_config :: proc(t: ^testing.T) {
	cfg := DEFAULT_LAYOUT_CONFIG
	testing.expect(t, cfg.direction == .TopToBottom)
	testing.expect(t, cfg.gap == 0)
	testing.expect(t, cfg.alignment.horizontal == .Left)
	testing.expect(t, cfg.alignment.vertical == .Top)
	testing.expect(t, cfg.overflow == .Hidden)
}

@(test)
test_invalid_node_constant :: proc(t: ^testing.T) {
	testing.expect(t, INVALID_NODE == LayoutNodeId(-1), "INVALID_NODE should be -1")
}

@(test)
test_render_command_types :: proc(t: ^testing.T) {
	testing.expect(t, RenderCommandType.None == .None)
	testing.expect(t, RenderCommandType.Text == .Text)
	testing.expect(t, RenderCommandType.Box == .Box)
	testing.expect(t, RenderCommandType.Rect == .Rect)
}

@(test)
test_layout_config_sizing :: proc(t: ^testing.T) {
	cfg := DEFAULT_LAYOUT_CONFIG
	cfg.sizing[.X] = fixed(100)
	cfg.sizing[.Y] = grow()

	testing.expect(t, cfg.sizing[.X].type == .Fixed)
	testing.expect_value(t, cfg.sizing[.X].value, 100)
	testing.expect(t, cfg.sizing[.Y].type == .Grow)
	testing.expect_value(t, cfg.sizing[.Y].value, 1.0)
}

@(test)
test_layout_config_alignment :: proc(t: ^testing.T) {
	cfg := DEFAULT_LAYOUT_CONFIG
	cfg.alignment = Alignment{.Center, .Bottom}

	testing.expect(t, cfg.alignment.horizontal == .Center)
	testing.expect(t, cfg.alignment.vertical == .Bottom)
}

@(test)
test_axis_enums :: proc(t: ^testing.T) {
	testing.expect(t, Axis.X == .X)
	testing.expect(t, Axis.Y == .Y)
}

@(test)
test_direction_enums :: proc(t: ^testing.T) {
	testing.expect(t, LayoutDirection.LeftToRight == .LeftToRight)
	testing.expect(t, LayoutDirection.TopToBottom == .TopToBottom)
	testing.expect(t, LayoutDirection.ZStack == .ZStack)
}
