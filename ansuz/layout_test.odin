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
