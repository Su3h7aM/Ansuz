package ansuz

import "core:testing"

@(test)
test_text_wrap_fixed_width :: proc(t: ^testing.T) {
	l_ctx := init_layout_context(context.allocator)
	defer destroy_layout_context(&l_ctx)

	root_rect := Rect{0, 0, 80, 24}
	reset_layout_context(&l_ctx, root_rect)

	begin_container(&l_ctx, {direction = .TopToBottom, sizing = {sizing_grow(), sizing_grow()}})

	// "Hello World" (11 chars). Width 5.
	// Should wrap: "Hello" (5), "World" (5). 2 Lines.
	add_text(
		&l_ctx,
		"Hello World",
		default_style(),
		{sizing = {sizing_fixed(5), sizing_fit()}, wrap_text = true},
	)

	end_container(&l_ctx)

	_run_layout_passes(&l_ctx)

	testing.expect_value(t, l_ctx.nodes[1].final_rect.h, 2)
	testing.expect_value(t, l_ctx.nodes[1].final_rect.w, 5)
}

@(test)
test_text_wrap_grow_width :: proc(t: ^testing.T) {
	l_ctx := init_layout_context(context.allocator)
	defer destroy_layout_context(&l_ctx)

	root_rect := Rect{0, 0, 10, 24} // Root width 10
	reset_layout_context(&l_ctx, root_rect)

	// Container fills width (10)
	begin_container(&l_ctx, {direction = .TopToBottom, sizing = {sizing_grow(), sizing_grow()}})

	// "Hello World" (11 chars). Parent width 10.
	// "Hello World" -> "Hello" (5) + " " + "World" (5) = 11 > 10.
	// Wait, simple space splitting:
	// "Hello" (5) + Space (1) + "World" (5) = 11.
	// Max width 10.
	// "Hello " (6) fits. "World" (5) fits? 6+5=11 > 10.
	// So "Hello" on line 1. "World" on line 2?
	// Let's allow for flexible wrapping logic check.
	// The previous implementation splits by words.
	// "Hello" (5) + Space (1) + "World" (5).
	// Loop:
	// 1. "Hello". fits 5 <= 10. current_w = 5.
	// 2. "World". needs space. current_w + 1 + 5 = 11 > 10.
	// Wrap.
	// So 2 lines expected.

	add_text(
		&l_ctx,
		"Hello World",
		default_style(),
		{sizing = {sizing_grow(), sizing_fit()}, wrap_text = true},
	)

	end_container(&l_ctx)

	_run_layout_passes(&l_ctx)

	// Width should resolve to 10 (parent width)
	testing.expect_value(t, l_ctx.nodes[1].final_rect.w, 10)
	// Height should range to 2 lines
	testing.expect_value(t, l_ctx.nodes[1].final_rect.h, 2)
}
