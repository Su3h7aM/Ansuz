package ansuz

import "core:mem"
import "core:math"

// Sizing rules for layout elements
SizingType :: enum {
    Fixed,      // Fixed size in cells
    Percent,    // Percentage of parent's available space (0.0 to 1.0)
    FitContent, // Size according to children or content
    Grow,       // Grow to fill remaining space
}

Sizing :: struct {
    type:  SizingType,
    value: f32,
}

// Convenience constructors for Sizing
Sizing_fixed :: proc(value: int) -> Sizing {
    return Sizing{.Fixed, f32(value)}
}

Sizing_percent :: proc(value: f32) -> Sizing {
    return Sizing{.Percent, value}
}

Sizing_fit :: proc() -> Sizing {
    return Sizing{.FitContent, 0}
}

Sizing_grow :: proc() -> Sizing {
    return Sizing{.Grow, 0}
}

LayoutDirection :: enum {
    LeftToRight,
    TopToBottom,
}

HorizontalAlignment :: enum {
    Left,
    Center,
    Right,
}

VerticalAlignment :: enum {
    Top,
    Center,
    Bottom,
}

Alignment :: struct {
    horizontal: HorizontalAlignment,
    vertical:   VerticalAlignment,
}

Padding :: struct {
    left:   int,
    right:  int,
    top:    int,
    bottom: int,
}

Padding_all :: proc(value: int) -> Padding {
    return Padding{value, value, value, value}
}

LayoutConfig :: struct {
    direction:  LayoutDirection,
    sizing:     [2]Sizing, // [0] = width, [1] = height
    padding:    Padding,
    gap:        int,
    alignment:  Alignment,
}

DEFAULT_LAYOUT_CONFIG :: LayoutConfig{
    direction = .TopToBottom,
    sizing    = {Sizing{.FitContent, 0}, Sizing{.FitContent, 0}},
    padding   = {0, 0, 0, 0},
    gap       = 0,
    alignment = {.Left, .Top},
}

Rect :: struct {
    x, y, w, h: int,
}

// RenderCommand represents a drawing operation based on layout
RenderCommandType :: enum {
    None,
    Text,
    Box,
    Rect,
}

RenderCommand :: struct {
    type:   RenderCommandType,
    rect:   Rect,
    text:   string,
    style:  Style,
    char:   rune, // For Rect command
}

// LayoutNode represents an element in the layout tree
LayoutNode :: struct {
    id:             u32,
    config:         LayoutConfig,
    rect:           Rect,
    parent_index:   int,
    first_child:    int,
    next_sibling:   int,
    is_container:   bool,
    render_cmd:     RenderCommand,
}

LayoutContext :: struct {
    nodes:          [dynamic]LayoutNode,
    stack:          [dynamic]int, // Stack of parent indices
    allocator:      mem.Allocator,
    root_rect:      Rect,
}

init_layout_context :: proc(allocator := context.allocator) -> LayoutContext {
    l_ctx := LayoutContext{
        nodes     = make([dynamic]LayoutNode, allocator),
        stack     = make([dynamic]int, allocator),
        allocator = allocator,
    }
    return l_ctx
}

destroy_layout_context :: proc(ctx: ^LayoutContext) {
    delete(ctx.nodes)
    delete(ctx.stack)
}

reset_layout_context :: proc(ctx: ^LayoutContext, root_rect: Rect) {
    clear(&ctx.nodes)
    clear(&ctx.stack)
    ctx.root_rect = root_rect
    append(&ctx.stack, -1) // Root parent
}

// Internal: adds a node to the tree
_add_node :: proc(l_ctx: ^LayoutContext, config: LayoutConfig, is_container: bool) -> int {
    parent_idx := len(l_ctx.stack) > 0 ? l_ctx.stack[len(l_ctx.stack) - 1] : -1

    node := LayoutNode{
        id           = u32(len(l_ctx.nodes)),
        config       = config,
        parent_index = parent_idx,
        first_child  = -1,
        next_sibling = -1,
        is_container = is_container,
    }

    node_idx := len(l_ctx.nodes)

    if parent_idx != -1 && node_idx < len(l_ctx.nodes) {
        parent := &l_ctx.nodes[parent_idx]
        if parent.first_child == -1 {
            parent.first_child = node_idx
        } else {
            curr := parent.first_child
            for curr >= 0 && curr < len(l_ctx.nodes) && l_ctx.nodes[curr].next_sibling != -1 {
                curr = l_ctx.nodes[curr].next_sibling
            }
            if curr >= 0 && curr < len(l_ctx.nodes) {
                l_ctx.nodes[curr].next_sibling = node_idx
            }
        }
    }

    append(&l_ctx.nodes, node)
    return node_idx
}

begin_container :: proc(l_ctx: ^LayoutContext, config: LayoutConfig) -> int {
    node_idx := _add_node(l_ctx, config, true)
    append(&l_ctx.stack, node_idx)
    return node_idx
}

end_container :: proc(l_ctx: ^LayoutContext) {
    pop(&l_ctx.stack)
}

add_text :: proc(l_ctx: ^LayoutContext, content: string, style: Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    cfg := config
    if cfg.sizing[0].type == .FitContent {
        cfg.sizing[0].value = f32(len(content))
    }
    if cfg.sizing[1].type == .FitContent {
        cfg.sizing[1].value = 1
    }
    
    node_idx := _add_node(l_ctx, cfg, false)
    node := &l_ctx.nodes[node_idx]
    node.render_cmd = RenderCommand{
        type = .Text,
        text = content,
        style = style,
    }
}

add_box :: proc(l_ctx: ^LayoutContext, style: Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    node_idx := _add_node(l_ctx, config, false)
    node := &l_ctx.nodes[node_idx]
    node.render_cmd = RenderCommand{
        type = .Box,
        style = style,
    }
}

add_box_container :: proc(l_ctx: ^LayoutContext, style: Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    node_idx := _add_node(l_ctx, config, true)
    node := &l_ctx.nodes[node_idx]
    node.render_cmd = RenderCommand{
        type = .Box,
        style = style,
    }
    append(&l_ctx.stack, node_idx)
}

end_box_container :: proc(l_ctx: ^LayoutContext) {
    if len(l_ctx.stack) > 0 {
        pop(&l_ctx.stack)
    }
}

add_rect :: proc(l_ctx: ^LayoutContext, char: rune, style: Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    node_idx := _add_node(l_ctx, config, false)
    node := &l_ctx.nodes[node_idx]
    node.render_cmd = RenderCommand{
        type = .Rect,
        char = char,
        style = style,
    }
}

add_rect_container :: proc(l_ctx: ^LayoutContext, char: rune, style: Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
    node_idx := _add_node(l_ctx, config, true)
    node := &l_ctx.nodes[node_idx]
    node.render_cmd = RenderCommand{
        type = .Rect,
        char = char,
        style = style,
    }
    append(&l_ctx.stack, node_idx)
}

end_rect_container :: proc(l_ctx: ^LayoutContext) {
    if len(l_ctx.stack) > 0 {
        pop(&l_ctx.stack)
    }
}

// finish_layout performs calculation and rendering
finish_layout :: proc(l_ctx: ^LayoutContext, ansuz_ctx: ^Context) {
    if len(l_ctx.nodes) == 0 do return

    // Pass 1: Calculate minimum sizes (bottom-up)
    _calculate_min_sizes(l_ctx, 0)

    // Pass 2: Calculate actual positions and sizes (top-down)
    l_ctx.nodes[0].rect = l_ctx.root_rect
    _calculate_positions(l_ctx, 0)

    // Pass 3: Rendering
    for &node in l_ctx.nodes {
        cmd := &node.render_cmd
        if cmd.type == .None && !node.is_container do continue
        
        // Update cmd rect from calculated layout
        cmd.rect = node.rect

        switch cmd.type {
        case .None:
            // Do nothing for container itself unless we add container styling
        case .Text:
            text(ansuz_ctx, cmd.rect.x, cmd.rect.y, cmd.text, cmd.style)
        case .Box:
            box(ansuz_ctx, cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h, cmd.style)
        case .Rect:
            rect(ansuz_ctx, cmd.rect.x, cmd.rect.y, cmd.rect.w, cmd.rect.h, cmd.char, cmd.style)
        }
    }
}

_calculate_min_sizes :: proc(l_ctx: ^LayoutContext, node_idx: int) {
    node := &l_ctx.nodes[node_idx]
    
    // Recursively calculate children's min sizes first
    child_idx := node.first_child
    for child_idx != -1 {
        _calculate_min_sizes(l_ctx, child_idx)
        child_idx = l_ctx.nodes[child_idx].next_sibling
    }

    // Calculate this node's size based on its sizing config and children
    if node.config.sizing[0].type == .Fixed {
        node.rect.w = int(node.config.sizing[0].value)
    } else if node.config.sizing[0].type == .FitContent {
        if node.is_container {
            min_w := 0
            child_idx = node.first_child
            for child_idx != -1 {
                child := l_ctx.nodes[child_idx]
                if node.config.direction == .LeftToRight {
                    min_w += child.rect.w
                    if child.next_sibling != -1 do min_w += node.config.gap
                } else {
                    min_w = max(min_w, child.rect.w)
                }
                child_idx = child.next_sibling
            }
            node.rect.w = min_w + node.config.padding.left + node.config.padding.right
        } else {
            node.rect.w = int(node.config.sizing[0].value)
        }
    }

    if node.config.sizing[1].type == .Fixed {
        node.rect.h = int(node.config.sizing[1].value)
    } else if node.config.sizing[1].type == .FitContent {
        if node.is_container {
            min_h := 0
            child_idx = node.first_child
            for child_idx != -1 {
                child := l_ctx.nodes[child_idx]
                if node.config.direction == .TopToBottom {
                    min_h += child.rect.h
                    if child.next_sibling != -1 do min_h += node.config.gap
                } else {
                    min_h = max(min_h, child.rect.h)
                }
                child_idx = child.next_sibling
            }
            node.rect.h = min_h + node.config.padding.top + node.config.padding.bottom
        } else {
            node.rect.h = int(node.config.sizing[1].value)
        }
    }
}

_calculate_positions :: proc(l_ctx: ^LayoutContext, node_idx: int) {
    node := &l_ctx.nodes[node_idx]
    if !node.is_container do return

    inner_rect := Rect{
        node.rect.x + node.config.padding.left,
        node.rect.y + node.config.padding.top,
        node.rect.w - node.config.padding.left - node.config.padding.right,
        node.rect.h - node.config.padding.top - node.config.padding.bottom,
    }

    grow_count_x, grow_count_y := 0, 0
    total_non_grow_w, total_non_grow_h := 0, 0
    child_count := 0

    child_idx := node.first_child
    for child_idx != -1 {
        child := &l_ctx.nodes[child_idx]
        child_count += 1
        
        if child.config.sizing[0].type == .Grow {
            grow_count_x += 1
        } else if child.config.sizing[0].type == .Percent {
            child.rect.w = int(f32(inner_rect.w) * child.config.sizing[0].value)
            if node.config.direction == .LeftToRight do total_non_grow_w += child.rect.w
        } else {
            if node.config.direction == .LeftToRight do total_non_grow_w += child.rect.w
        }

        if child.config.sizing[1].type == .Grow {
            grow_count_y += 1
        } else if child.config.sizing[1].type == .Percent {
            child.rect.h = int(f32(inner_rect.h) * child.config.sizing[1].value)
            if node.config.direction == .TopToBottom do total_non_grow_h += child.rect.h
        } else {
            if node.config.direction == .TopToBottom do total_non_grow_h += child.rect.h
        }

        child_idx = child.next_sibling
    }

    if child_count > 1 {
        if node.config.direction == .LeftToRight do total_non_grow_w += (child_count - 1) * node.config.gap
        else do total_non_grow_h += (child_count - 1) * node.config.gap
    }

    remaining_w := max(0, inner_rect.w - total_non_grow_w)
    remaining_h := max(0, inner_rect.h - total_non_grow_h)

    // Assign size to growing children
    child_idx = node.first_child
    for child_idx != -1 {
        child := &l_ctx.nodes[child_idx]
        if child.config.sizing[0].type == .Grow {
            if node.config.direction == .LeftToRight {
                if grow_count_x > 0 do child.rect.w = remaining_w / grow_count_x
            } else {
                child.rect.w = inner_rect.w
            }
        }
        if child.config.sizing[1].type == .Grow {
            if node.config.direction == .TopToBottom {
                if grow_count_y > 0 do child.rect.h = remaining_h / grow_count_y
            } else {
                child.rect.h = inner_rect.h
            }
        }
        child_idx = child.next_sibling
    }

    // Adjust remaining space after assigning grows (to handle integer division remainders)
    // For now, let's keep it simple.

    // Final position assignment with alignment
    curr_x := inner_rect.x
    curr_y := inner_rect.y

    // Calculate start positions based on alignment
    if node.config.direction == .LeftToRight {
        if node.config.alignment.horizontal == .Center {
            curr_x += remaining_w / 2
        } else if node.config.alignment.horizontal == .Right {
            curr_x += remaining_w
        }
    } else {
        if node.config.alignment.vertical == .Center {
            curr_y += remaining_h / 2
        } else if node.config.alignment.vertical == .Bottom {
            curr_y += remaining_h
        }
    }

    child_idx = node.first_child
    for child_idx != -1 {
        child := &l_ctx.nodes[child_idx]
        
        child.rect.x = curr_x
        child.rect.y = curr_y

        // Cross-axis alignment
        if node.config.direction == .LeftToRight {
            switch node.config.alignment.vertical {
            case .Top:    // Already at curr_y
            case .Center: child.rect.y += (inner_rect.h - child.rect.h) / 2
            case .Bottom: child.rect.y += (inner_rect.h - child.rect.h)
            }
            curr_x += child.rect.w + node.config.gap
        } else {
            switch node.config.alignment.horizontal {
            case .Left:   // Already at curr_x
            case .Center: child.rect.x += (inner_rect.w - child.rect.w) / 2
            case .Right:  child.rect.x += (inner_rect.w - child.rect.w)
            }
            curr_y += child.rect.h + node.config.gap
        }

        _calculate_positions(l_ctx, child_idx)
        child_idx = child.next_sibling
    }
}
