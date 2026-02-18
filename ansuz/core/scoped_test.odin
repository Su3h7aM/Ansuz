package ansuz

import "core:testing"
import "core:fmt"
import "core:mem"
import "core:strings"

import ab "../buffer"
import ac "../color"
import al "../layout"
import at "../terminal"

_make_test_context :: proc(allocator := context.allocator) -> ^Context {
	ctx := new(Context, allocator)
	ctx.allocator = allocator
	ctx.width = 80
	ctx.height = 24
	
	buf, _ := ab.init_buffer(ctx.width, ctx.height, allocator)
	ctx.buffer = buf
	
	ctx.layout_ctx = al.init_layout_context(allocator)
	
	ctx.theme = new(Theme, allocator)
	ctx.theme^ = default_theme_full()
	
	// Initialize render buffer
	render_buf, _ := strings.builder_make_len_cap(0, 16384, allocator)
	ctx.render_buffer = render_buf
	
	// Initialize focus tracking
	ctx.focusable_items = make([dynamic]u64, allocator)
	ctx.prev_focusable_items = make([dynamic]u64, allocator)
	ctx.input_keys = make([dynamic]at.KeyEvent, allocator)
	
	return ctx
}

// Helper function to clean up test context
_free_test_context :: proc(ctx: ^Context) {
	if ctx == nil do return
	
	delete(ctx.focusable_items)
	delete(ctx.prev_focusable_items)
	delete(ctx.input_keys)
	strings.builder_destroy(&ctx.render_buffer)
	al.destroy_layout_context(&ctx.layout_ctx)
	ab.destroy_buffer(&ctx.buffer)
	free(ctx.theme)
	free(ctx)
}

// _test_render is a test-only layout pass without terminal I/O.
// Mirrors the public render() API but skips frame setup and terminal output.
@(deferred_in_out = _test_end_render)
_test_render :: proc(ctx: ^Context) -> bool {
	ab.clear_buffer(&ctx.buffer)
	al.reset_layout_context(&ctx.layout_ctx, al.Rect{0, 0, ctx.width, ctx.height})
	return true
}

_test_end_render :: proc(ctx: ^Context, ok: bool) {
	if ok {
		commands := al.finish_layout(&ctx.layout_ctx)
	_execute_render_commands(ctx, commands)
	}
}

// --- Single Container Tests ---

@(test)
test_single_container :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		container(ctx, {
			sizing = {.X = al.fixed(40), .Y = al.fixed(10)},
		})
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_single_box :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if box(ctx, {
			sizing = {.X = al.fixed(20), .Y = al.fixed(5)},
		}, ac.style(ac.Ansi.White, ac.Ansi.Black, {}), .Sharp) {
			label(ctx, "Test")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_single_vstack :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {
			sizing = {.X = al.fixed(30), .Y = al.fixed(10)},
		}) {
			label(ctx, "Item 1")
			label(ctx, "Item 2")
			label(ctx, "Item 3")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_single_hstack :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if hstack(ctx, {
			sizing = {.X = al.fixed(30), .Y = al.fixed(5)},
		}) {
			label(ctx, "A")
			label(ctx, "B")
			label(ctx, "C")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_single_rect :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if rect(ctx, {
			sizing = {.X = al.fixed(20), .Y = al.fixed(5)},
		}, ac.style(ac.Ansi.Red, ac.Ansi.Default, {}), '█') {
			label(ctx, "Filled")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

// --- Nested Container Tests ---

@(test)
test_nested_vstack :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {
			sizing = {.X = al.fixed(40), .Y = al.fixed(20)},
		}) {
			if vstack(ctx, {
				sizing = {.X = al.fixed(30), .Y = al.fixed(10)},
			}) {
				label(ctx, "Inner 1")
				label(ctx, "Inner 2")
			}
			label(ctx, "Outer 2")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_nested_hstack_in_vstack :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {
			sizing = {.X = al.fixed(40), .Y = al.fixed(20)},
		}) {
			label(ctx, "Top")
			if hstack(ctx, {
				sizing = {.X = al.fixed(30), .Y = al.fixed(5)},
			}) {
				label(ctx, "Left")
				label(ctx, "Right")
			}
			label(ctx, "Bottom")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_deeply_nested :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {}) {
			if hstack(ctx, {}) {
				if vstack(ctx, {}) {
					if hstack(ctx, {}) {
						label(ctx, "Deep")
					}
				}
			}
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_nested_boxes :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if box(ctx, {
			sizing = {.X = al.fixed(30), .Y = al.fixed(15)},
		}, ac.style(ac.Ansi.White, ac.Ansi.Black, {}), .Sharp) {
			if box(ctx, {
				sizing = {.X = al.fixed(20), .Y = al.fixed(10)},
			}, ac.style(.Cyan, ac.Ansi.Black, {}), .Rounded) {
				label(ctx, "Nested Box")
			}
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

// --- Early Exit Tests ---

@(test)
test_early_exit_with_return :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	_test_early_exit_helper :: proc(ctx: ^Context) -> int {
		if _test_render(ctx) {
			if vstack(ctx, {}) {
				label(ctx, "Before")
				if false {
					label(ctx, "Not reached")
				}
				label(ctx, "After")
			}
		}
		return 42
	}

	result := _test_early_exit_helper(ctx)
	testing.expect(t, result == 42)
	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_conditional_container :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	show_box := true

	if _test_render(ctx) {
		if show_box {
			if box(ctx, {
				sizing = {.X = al.fixed(20), .Y = al.fixed(5)},
			}, ac.style(ac.Ansi.White, ac.Ansi.Black, {}), .Sharp) {
				label(ctx, "Conditional")
			}
		}
		label(ctx, "Always shown")
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

// --- Local Variable Tests ---

@(test)
test_local_variables_in_container :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {
			sizing = {.X = al.fixed(30), .Y = al.fit()},
		}) {
			count := 0
			for i in 0 ..< 5 {
				count += 1
				label(ctx, fmt.tprintf("Item %d", i))
			}
			testing.expect(t, count == 5)
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_modify_local_variable :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {}) {
			value := 10
			label(ctx, fmt.tprintf("Value: %d", value))
			value = 20
			label(ctx, fmt.tprintf("Value: %d", value))
			value = 30
			label(ctx, fmt.tprintf("Value: %d", value))
			testing.expect(t, value == 30)
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

// --- Container State Tests ---

@(test)
test_container_sizing_preserved :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if container(ctx, {
			sizing = {.X = al.fixed(50), .Y = al.fixed(25)},
			padding = al.padding_all(2),
		}) {
			label(ctx, "Test")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	if len(ctx.layout_ctx.nodes) > 0 {
		node := ctx.layout_ctx.nodes[0]
		testing.expect(t, node.config.sizing[.X].type == .Fixed)
		testing.expect(t, node.config.sizing[.Y].type == .Fixed)
		testing.expect(t, node.config.padding.left == 2)
		testing.expect(t, node.config.padding.right == 2)
		testing.expect(t, node.config.padding.top == 2)
		testing.expect(t, node.config.padding.bottom == 2)
	}
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_container_gap_preserved :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {
			sizing = {.X = al.fixed(30), .Y = al.fixed(20)},
			gap = 2,
		}) {
			label(ctx, "One")
			label(ctx, "Two")
			label(ctx, "Three")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	if len(ctx.layout_ctx.nodes) > 0 {
		node := ctx.layout_ctx.nodes[0]
		testing.expect(t, node.config.gap == 2)
	}
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_container_alignment_preserved :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {
			sizing = {.X = al.fixed(40), .Y = al.fixed(20)},
			alignment = al.Alignment{.Center, .Center},
		}) {
			label(ctx, "Centered")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	if len(ctx.layout_ctx.nodes) > 0 {
		node := ctx.layout_ctx.nodes[0]
		testing.expect(t, node.config.alignment.horizontal == .Center)
		testing.expect(t, node.config.alignment.vertical == .Center)
	}
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

// --- ZStack Tests ---

@(test)
test_zstack_basic :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if zstack(ctx, {
			sizing = {.X = al.fixed(30), .Y = al.fixed(10)},
		}) {
			label(ctx, "Bottom")
			label(ctx, "Middle")
			label(ctx, "Top")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	if len(ctx.layout_ctx.nodes) > 0 {
		node := ctx.layout_ctx.nodes[0]
		testing.expect(t, node.config.direction == .ZStack)
	}
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

// --- Spacer Tests ---

@(test)
test_spacer_basic :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if hstack(ctx, {
			sizing = {.X = al.fixed(40), .Y = al.fixed(5)},
		}) {
			label(ctx, "Left")
			spacer(ctx, {})
			label(ctx, "Right")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_multiple_spacers :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if hstack(ctx, {
			sizing = {.X = al.fixed(40), .Y = al.fixed(5)},
		}) {
			spacer(ctx, {})
			label(ctx, "Center")
			spacer(ctx, {})
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

// --- Edge Cases ---

@(test)
test_empty_container :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {
			sizing = {.X = al.fixed(20), .Y = al.fixed(10)},
		}) {
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_many_nested_levels :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	_nested_levels_helper :: proc(ctx: ^Context, level: int) {
		if level == 0 do return
		if vstack(ctx, {}) {
			_nested_levels_helper(ctx, level - 1)
		}
	}

	if _test_render(ctx) {
		_nested_levels_helper(ctx, 10)
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}

@(test)
test_multiple_layouts :: proc(t: ^testing.T) {
	ctx := _make_test_context()
	defer _free_test_context(ctx)

	if _test_render(ctx) {
		if vstack(ctx, {}) {
			label(ctx, "First Layout")
		}
	}

	if _test_render(ctx) {
		if hstack(ctx, {}) {
			label(ctx, "Second Layout")
		}
	}

	if _test_render(ctx) {
		if box(ctx, {}, ac.style(ac.Ansi.White, ac.Ansi.Black, {}), .Sharp) {
			label(ctx, "Third Layout")
		}
	}

	testing.expect(t, len(ctx.layout_ctx.nodes) > 0)
	testing.expect(t, ctx.layout_ctx.stack[0] == al.INVALID_NODE)
}
