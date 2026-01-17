package ansuz

import "core:testing"
import "core:fmt"

@(test)
test_layout_basic :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    // Simple vertical layout with two growing items
    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "Item 1", STYLE_NORMAL, {sizing = {sizing_grow(), sizing_grow()}})
    add_text(&l_ctx, "Item 2", STYLE_NORMAL, {sizing = {sizing_grow(), sizing_grow()}})
    end_container(&l_ctx)

    // Pass 1: Min sizes
    _calculate_min_sizes(&l_ctx, 0)
    // Pass 2: Positions
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    // Check results
    testing.expect_value(t, l_ctx.nodes[1].rect.h, 12)
    testing.expect_value(t, l_ctx.nodes[2].rect.h, 12)
    testing.expect_value(t, l_ctx.nodes[1].rect.y, 0)
    testing.expect_value(t, l_ctx.nodes[2].rect.y, 12)
}

@(test)
test_layout_padding_gap :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .LeftToRight,
        sizing = {sizing_grow(), sizing_grow()},
        padding = {left = 2, right = 2, top = 1, bottom = 1},
        gap = 1,
    })
    add_box(&l_ctx, STYLE_NORMAL, {sizing = {sizing_grow(), sizing_grow()}})
    add_box(&l_ctx, STYLE_NORMAL, {sizing = {sizing_grow(), sizing_grow()}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    // Available width = 80 - 2 (left) - 2 (right) = 76
    // Available width for items = 76 - 1 (gap) = 75
    // Item 1 width = 75 / 2 = 37
    // Item 2 width = 75 / 2 = 37
    // Actually 37 + 37 = 74, one cell lost to integer division
    
    testing.expect_value(t, l_ctx.nodes[1].rect.w, 37)
    testing.expect_value(t, l_ctx.nodes[2].rect.w, 37)
    testing.expect_value(t, l_ctx.nodes[1].rect.x, 2)
    testing.expect_value(t, l_ctx.nodes[2].rect.x, 2 + 37 + 1) // padding + item1 + gap
}

@(test)
test_layout_alignment :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
        alignment = {horizontal = .Center, vertical = .Center},
    })
    // Fixed size item in a growing container should be centered
    add_text(&l_ctx, "Centered", STYLE_NORMAL, {sizing = {sizing_fixed(10), sizing_fixed(1)}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    // Horizontal: (80 - 10) / 2 = 35
    // Vertical: (24 - 1) / 2 = 11
    
    testing.expect_value(t, l_ctx.nodes[1].rect.x, 35)
    testing.expect_value(t, l_ctx.nodes[1].rect.y, 11)
}

@(test)
test_sizing_constructors :: proc(t: ^testing.T) {
    fixed := sizing_fixed(100)
    testing.expect(t, fixed.type == .Fixed)
    testing.expect_value(t, fixed.value, 100.0)

    percent := sizing_percent(0.5)
    testing.expect(t, percent.type == .Percent)
    testing.expect_value(t, percent.value, 0.5)

    fit := sizing_fit()
    testing.expect(t, fit.type == .FitContent)

    grow := sizing_grow()
    testing.expect(t, grow.type == .Grow)
}

@(test)
test_padding_all :: proc(t: ^testing.T) {
    padding := padding_all(5)
    testing.expect_value(t, padding.left, 5)
    testing.expect_value(t, padding.right, 5)
    testing.expect_value(t, padding.top, 5)
    testing.expect_value(t, padding.bottom, 5)

    padding2 := padding_all(0)
    testing.expect_value(t, padding2.left, 0)
    testing.expect_value(t, padding2.right, 0)
}

@(test)
test_layout_horizontal_direction :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .LeftToRight,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "A", STYLE_NORMAL, {sizing = {sizing_fixed(5), sizing_fixed(1)}})
    add_text(&l_ctx, "B", STYLE_NORMAL, {sizing = {sizing_fixed(5), sizing_fixed(1)}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect_value(t, l_ctx.nodes[1].rect.x, 0)
    testing.expect_value(t, l_ctx.nodes[2].rect.x, 5)
    testing.expect_value(t, l_ctx.nodes[1].rect.y, 0)
    testing.expect_value(t, l_ctx.nodes[2].rect.y, 0)
}

@(test)
test_layout_mixed_sizing :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .LeftToRight,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "Fixed", STYLE_NORMAL, {sizing = {sizing_fixed(20), sizing_fixed(1)}})
    add_text(&l_ctx, "Grow", STYLE_NORMAL, {sizing = {sizing_grow(), sizing_grow()}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect_value(t, l_ctx.nodes[1].rect.w, 20)
    testing.expect_value(t, l_ctx.nodes[2].rect.w, 60)
}

@(test)
test_layout_percent_sizing :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 100, 20}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .LeftToRight,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "Half", STYLE_NORMAL, {sizing = {sizing_percent(0.5), sizing_grow()}})
    add_text(&l_ctx, "Half", STYLE_NORMAL, {sizing = {sizing_percent(0.5), sizing_grow()}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect_value(t, l_ctx.nodes[1].rect.w, 50)
    testing.expect_value(t, l_ctx.nodes[2].rect.w, 50)
}

@(test)
test_layout_nested_containers :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "Top", STYLE_NORMAL, {sizing = {sizing_fixed(10), sizing_fixed(1)}})

    begin_container(&l_ctx, {
        direction = .LeftToRight,
        sizing = {sizing_grow(), sizing_grow()},
        padding = {left = 2, right = 2},
    })
    add_text(&l_ctx, "A", STYLE_NORMAL, {sizing = {sizing_fixed(5), sizing_fixed(1)}})
    add_text(&l_ctx, "B", STYLE_NORMAL, {sizing = {sizing_fixed(5), sizing_fixed(1)}})
    end_container(&l_ctx)

    add_text(&l_ctx, "Bottom", STYLE_NORMAL, {sizing = {sizing_fixed(10), sizing_fixed(1)}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect(t, len(l_ctx.nodes) == 6, "Should have 6 nodes")
    testing.expect_value(t, l_ctx.nodes[1].rect.y, 0)
}

@(test)
test_layout_single_child :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "Only Child", STYLE_NORMAL, {sizing = {sizing_grow(), sizing_grow()}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect(t, len(l_ctx.nodes) == 2, "Should have 2 nodes")
    testing.expect_value(t, l_ctx.nodes[1].rect.w, 80)
    testing.expect_value(t, l_ctx.nodes[1].rect.h, 24)
}

@(test)
test_layout_empty_container :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
    })
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect(t, len(l_ctx.nodes) == 1, "Should have 1 node (container only)")
}

@(test)
test_layout_alignment_left :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
        alignment = {horizontal = .Left, vertical = .Top},
    })
    add_text(&l_ctx, "Small", STYLE_NORMAL, {sizing = {sizing_fixed(10), sizing_fixed(1)}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect_value(t, l_ctx.nodes[1].rect.x, 0)
    testing.expect_value(t, l_ctx.nodes[1].rect.y, 0)
}

@(test)
test_layout_alignment_right :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
        alignment = {horizontal = .Right, vertical = .Top},
    })
    add_text(&l_ctx, "Small", STYLE_NORMAL, {sizing = {sizing_fixed(10), sizing_fixed(1)}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect_value(t, l_ctx.nodes[1].rect.x, 70)
}

@(test)
test_layout_alignment_bottom :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .LeftToRight,
        sizing = {sizing_grow(), sizing_grow()},
        alignment = {horizontal = .Left, vertical = .Bottom},
    })
    add_text(&l_ctx, "Small", STYLE_NORMAL, {sizing = {sizing_fixed(10), sizing_fixed(1)}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect_value(t, l_ctx.nodes[1].rect.y, 23)
}

@(test)
test_layout_context_init_destroy :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    testing.expect(t, len(l_ctx.nodes) == 0, "New context should have no nodes")
    testing.expect(t, len(l_ctx.stack) == 0, "New context should have empty stack")

    destroy_layout_context(&l_ctx)
    testing.expect(t, len(l_ctx.nodes) == 0, "Should be cleared after destroy")
}

@(test)
test_layout_reset_context :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    testing.expect_value(t, l_ctx.root_rect.w, 80)
    testing.expect_value(t, l_ctx.root_rect.h, 24)
    testing.expect(t, len(l_ctx.stack) == 1, "Stack should have root parent")
    testing.expect_value(t, l_ctx.stack[0], -1)
}

@(test)
test_layout_multiple_containers :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "Container 1", STYLE_NORMAL, {sizing = {sizing_grow(), sizing_grow()}})
    end_container(&l_ctx)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "Container 2", STYLE_NORMAL, {sizing = {sizing_grow(), sizing_grow()}})
    end_container(&l_ctx)

    testing.expect(t, len(l_ctx.nodes) == 4, "Should have 4 nodes (2 containers + 2 children)")
}

@(test)
test_layout_fit_content_width :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "Hello", STYLE_NORMAL, {sizing = {sizing_fit(), sizing_grow()}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect_value(t, l_ctx.nodes[1].rect.w, 5)
}

@(test)
test_layout_fit_content_height :: proc(t: ^testing.T) {
    l_ctx := init_layout_context(context.allocator)
    defer destroy_layout_context(&l_ctx)

    root_rect := Rect{0, 0, 80, 24}
    reset_layout_context(&l_ctx, root_rect)

    begin_container(&l_ctx, {
        direction = .TopToBottom,
        sizing = {sizing_grow(), sizing_grow()},
    })
    add_text(&l_ctx, "Line1", STYLE_NORMAL, {sizing = {sizing_grow(), sizing_fit()}})
    end_container(&l_ctx)

    _calculate_min_sizes(&l_ctx, 0)
    l_ctx.nodes[0].rect = root_rect
    _calculate_positions(&l_ctx, 0)

    testing.expect_value(t, l_ctx.nodes[1].rect.h, 1)
}

@(test)
test_layout_rect :: proc(t: ^testing.T) {
    rect := Rect{10, 20, 30, 40}
    testing.expect_value(t, rect.x, 10)
    testing.expect_value(t, rect.y, 20)
    testing.expect_value(t, rect.w, 30)
    testing.expect_value(t, rect.h, 40)
}
