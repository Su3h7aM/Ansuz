package ansuz

import "core:mem"
import "core:math"

// --- Public API ---

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

Sizing_grow :: proc(weight: f32 = 1.0) -> Sizing {
	return Sizing{.Grow, weight}
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

Overflow :: enum {
    Visible,
    Hidden,
    Scroll,
}

LayoutConfig :: struct {
    direction:     LayoutDirection,
    sizing:        [2]Sizing,
    padding:       Padding,
    gap:           int,
    alignment:     Alignment,
    overflow:      Overflow,
    scroll_offset: [2]int, // x, y offset
}

DEFAULT_LAYOUT_CONFIG :: LayoutConfig{
    direction     = .TopToBottom,
    sizing        = {Sizing{.FitContent, 0}, Sizing{.FitContent, 0}},
    padding       = {0, 0, 0, 0},
    gap           = 0,
    alignment     = {.Left, .Top},
    overflow      = .Visible,
    scroll_offset = {0, 0},
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
	type:      RenderCommandType,
	rect:      Rect,
	text:      string,
	style:     Style,
	char:      rune,     // For Rect command
	box_style: BoxStyle, // For Box command
}

// LayoutNode represents an element in the layout tree
LayoutNode :: struct {
	id:           u32,
	config:       LayoutConfig,
	
    // Structure
    parent_index: int,
	first_child:  int,
	next_sibling: int,
	is_container: bool,
    
    // Computed Layout computed in phases
    min_w, min_h: int, // From Pass 1 (Fit)
    final_rect:   Rect, // Final result
    
	render_cmd:   RenderCommand,
}

LayoutContext :: struct {
	nodes:     [dynamic]LayoutNode,
	stack:     [dynamic]int, // Stack of parent indices
	allocator: mem.Allocator,
	root_rect: Rect,
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
	append(&ctx.stack, -1) // Root parent marker
}

// --- Node Management ---

// Internal: adds a node to the tree
_add_node :: proc(l_ctx: ^LayoutContext, config: LayoutConfig, is_container: bool) -> int {
	parent_idx := len(l_ctx.stack) > 0 ? l_ctx.stack[len(l_ctx.stack)-1] : -1

	node := LayoutNode{
		id           = u32(len(l_ctx.nodes)),
		config       = config,
		parent_index = parent_idx,
		first_child  = -1,
		next_sibling = -1,
		is_container = is_container,
	}

	node_idx := len(l_ctx.nodes)

	if parent_idx != -1 && parent_idx < len(l_ctx.nodes) {
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
	if len(l_ctx.stack) > 1 { // Don't pop -1
        pop(&l_ctx.stack)
    }
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
		type  = .Text,
		text  = content,
		style = style,
	}
}

add_box :: proc(l_ctx: ^LayoutContext, style: Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
	node_idx := _add_node(l_ctx, config, false)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand{
		type  = .Box,
		style = style,
	}
}

add_box_container :: proc(l_ctx: ^LayoutContext, style: Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG, box_style: BoxStyle = .Sharp) {
	node_idx := _add_node(l_ctx, config, true)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand{
		type      = .Box,
		style     = style,
		box_style = box_style,
	}
	append(&l_ctx.stack, node_idx)
}

end_box_container :: proc(l_ctx: ^LayoutContext) {
	end_container(l_ctx)
}

add_rect :: proc(l_ctx: ^LayoutContext, char: rune, style: Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
	node_idx := _add_node(l_ctx, config, false)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand{
		type  = .Rect,
		char  = char,
		style = style,
	}
}

add_rect_container :: proc(l_ctx: ^LayoutContext, char: rune, style: Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
	node_idx := _add_node(l_ctx, config, true)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand{
		type  = .Rect,
		char  = char,
		style = style,
	}
	append(&l_ctx.stack, node_idx)
}

end_rect_container :: proc(l_ctx: ^LayoutContext) {
	end_container(l_ctx)
}

// --- Layout Engine (Clay-based) ---

// Constants for axis indexing to enable generic logic
AXIS_X :: 0
AXIS_Y :: 1

_get_main_axis :: proc(dir: LayoutDirection) -> int {
    return dir == .LeftToRight ? AXIS_X : AXIS_Y
}

_get_cross_axis :: proc(dir: LayoutDirection) -> int {
    return dir == .LeftToRight ? AXIS_Y : AXIS_X
}

rect_intersection :: proc(r1, r2: Rect) -> Rect {
    x1 := max(r1.x, r2.x)
    y1 := max(r1.y, r2.y)
    x2 := min(r1.x + r1.w, r2.x + r2.w)
    y2 := min(r1.y + r1.h, r2.y + r2.h)
    
    w := max(0, x2 - x1)
    h := max(0, y2 - y1)
    
    return Rect{x1, y1, w, h}
}

finish_layout :: proc(l_ctx: ^LayoutContext, ansuz_ctx: ^Context) {
	if len(l_ctx.nodes) == 0 do return

	// Pass 1: Measure `Fit`, Bottom-Up
	_pass1_measure(l_ctx, 0)

	// Pass 2: Resolve `Grow`, Top-Down
    // Root takes the context root rect size
    l_ctx.nodes[0].final_rect = l_ctx.root_rect
	_pass2_resolve(l_ctx, 0)

	// Pass 3: Position, Top-Down
	_pass3_position(l_ctx, 0)

	// Rendering (Recursive for Clipping)
    initial_clip := Rect{0, 0, ansuz_ctx.width, ansuz_ctx.height}
    
    // Find absolute roots (usually just 0, but safe to check)
    // Actually nodes[0] is strictly the root in our usage.
    if len(l_ctx.nodes) > 0 {
        _render_recursive(l_ctx, ansuz_ctx, 0, initial_clip)
    }
}

_render_recursive :: proc(l_ctx: ^LayoutContext, ansuz_ctx: ^Context, node_idx: int, parent_clip: Rect) {
    node := &l_ctx.nodes[node_idx]
    
    // 1. Render Self
    // Ensure clip rect is set to what we expect
    set_clip_rect(&ansuz_ctx.buffer, parent_clip)
    
    cmd := &node.render_cmd
    if cmd.type != .None || node.is_container {
        cmd.rect = node.final_rect
        
        switch cmd.type {
        case .None:
        case .Text:
            text(ansuz_ctx, cmd.rect.x, cmd.rect.y, cmd.text, cmd.style)
        case .Box:
            w := max(0, cmd.rect.w)
            h := max(0, cmd.rect.h)
            box(ansuz_ctx, cmd.rect.x, cmd.rect.y, w, h, cmd.style, cmd.box_style)
        case .Rect:
            w := max(0, cmd.rect.w)
            h := max(0, cmd.rect.h)
            rect(ansuz_ctx, cmd.rect.x, cmd.rect.y, w, h, cmd.char, cmd.style)
        }
    }
    
    // 2. Determine Clip for Children
    child_clip := parent_clip
    if node.config.overflow != .Visible {
        child_clip = rect_intersection(parent_clip, node.final_rect)
    }
    
    // 3. Recurse
    child_idx := node.first_child
    for child_idx != -1 {
        _render_recursive(l_ctx, ansuz_ctx, child_idx, child_clip)
        child_idx = l_ctx.nodes[child_idx].next_sibling
    }
}

_pass1_measure :: proc(l_ctx: ^LayoutContext, node_idx: int) {
	node := &l_ctx.nodes[node_idx]

    // Recurse first (Bottom-Up)
	child_idx := node.first_child
	for child_idx != -1 {
		_pass1_measure(l_ctx, child_idx)
		child_idx = l_ctx.nodes[child_idx].next_sibling
	}
    
    // Now calculate size for THIS node
    // We treat X and Y independently initially
    for axis in 0..=1 {
        size_config := node.config.sizing[axis]
        
        switch size_config.type {
        case .Fixed:
            val := int(size_config.value)
            if axis == AXIS_X do node.min_w = val
            else do node.min_h = val
            
        case .Percent: 
            // Cannot determine in this pass, set to 0 for now
             if axis == AXIS_X do node.min_w = 0
             else do node.min_h = 0
             
        case .Grow:
            // Cannot determine in this pass
             if axis == AXIS_X do node.min_w = 0
             else do node.min_h = 0
            
        case .FitContent:
            // This is where standard layout logic happens (Sum vs Max)
            if !node.is_container {
                // Leaf node fit content: should have been set by add_text etc.
                // If not (e.g. empty container marked fit), defaults to 0
                val := int(size_config.value)
                if axis == AXIS_X do node.min_w = val 
                else do node.min_h = val
            } else {
                // Container logic
                main_axis := _get_main_axis(node.config.direction)
                
                // If current axis is the main axis of the container, we SUM children
                if axis == main_axis {
                    total := 0
                    c_idx := node.first_child
                    child_count := 0
                    for c_idx != -1 {
                        child := l_ctx.nodes[c_idx]
                        total += (axis == AXIS_X ? child.min_w : child.min_h)
                        c_idx = child.next_sibling
                        child_count += 1
                    }
                    if child_count > 1 {
                        total += (child_count - 1) * node.config.gap
                    }
                    padding := axis == AXIS_X ? (node.config.padding.left + node.config.padding.right) : (node.config.padding.top + node.config.padding.bottom)
                    val := total + padding
                     if axis == AXIS_X do node.min_w = val 
                     else do node.min_h = val
                } else {
                    // If current axis is the CROSS axis, we take MAX of children
                    max_val := 0
                    c_idx := node.first_child
                    for c_idx != -1 {
                       child := l_ctx.nodes[c_idx]
                       val := (axis == AXIS_X ? child.min_w : child.min_h)
                       max_val = max(max_val, val)
                       c_idx = child.next_sibling
                    }
                     padding := axis == AXIS_X ? (node.config.padding.left + node.config.padding.right) : (node.config.padding.top + node.config.padding.bottom)
                     val := max_val + padding
                     if axis == AXIS_X do node.min_w = val 
                     else do node.min_h = val
                }
            }
        }
    }
}

_pass2_resolve :: proc(l_ctx: ^LayoutContext, node_idx: int) {
    node := &l_ctx.nodes[node_idx]
    
    // Node now has a final_rect (from parent or root). 
    // We need to resolve children's sizes based on this available space.
    
    if !node.is_container {
         // Even if not container, if it has children (which shouldn't happen much but possible), 
         // we should recurse. But for safety, standard containers only.
         return
    }
    
    // Calculate inner content box
    pad_w := node.config.padding.left + node.config.padding.right
    pad_h := node.config.padding.top + node.config.padding.bottom
    available_w := max(0, node.final_rect.w - pad_w)
    available_h := max(0, node.final_rect.h - pad_h)
    
    main_axis := _get_main_axis(node.config.direction)
    cross_axis := _get_cross_axis(node.config.direction)
    
    // 1. Calculate allocated space (fixed/fit items) and count growers
    used_main := 0
    grow_total_weight: f32 = 0
    child_count := 0
    
    child_idx := node.first_child
    for child_idx != -1 {
        child := &l_ctx.nodes[child_idx]
        child_count += 1
        
        // Handle Cross Axis Grow/Stretch immediately here? 
        // Or wait. Let's calculate main axis logic first.
        
        // MAIN AXIS logic
        if child.config.sizing[main_axis].type == .Grow {
            grow_total_weight += child.config.sizing[main_axis].value
            // Grow items start with base size 0 in main calculations usually, unless we support flex-basis.
            // For now, 0.
        } else if child.config.sizing[main_axis].type == .Percent {
             // Resolve Percent now
             val_f := child.config.sizing[main_axis].value
             avail := main_axis == AXIS_X ? available_w : available_h
             resolved := int(f32(avail) * val_f)
             if main_axis == AXIS_X do child.min_w = resolved
             else do child.min_h = resolved
             used_main += resolved
        } else {
            // Fixed or Fit (already calculated in Pass 1)
            used_main += (main_axis == AXIS_X ? child.min_w : child.min_h)
        }
        
        // CROSS AXIS logic - mostly just Percent needs resolving here, or Stretches
        if child.config.sizing[cross_axis].type == .Percent {
             val_f := child.config.sizing[cross_axis].value
             avail := cross_axis == AXIS_X ? available_w : available_h
             resolved := int(f32(avail) * val_f)
             if cross_axis == AXIS_X do child.min_w = resolved
             else do child.min_h = resolved
        }
        // Grow on Cross is "Stretch" usually, implies filling the parent's cross size.
        if child.config.sizing[cross_axis].type == .Grow {
            avail := cross_axis == AXIS_X ? available_w : available_h
            if cross_axis == AXIS_X do child.min_w = avail
            else do child.min_h = avail
        }
        
        child_idx = child.next_sibling
    }
    
    // Add Gaps to used space
    if child_count > 1 {
        used_main += (child_count - 1) * node.config.gap
    }
    
    // 2. Distribute remaining space to Growers
    avail_main := (main_axis == AXIS_X ? available_w : available_h)
    remaining_main := max(0, avail_main - used_main)
    
    if grow_total_weight > 0 {
        remaining_f := f32(remaining_main)
        
        c_idx := node.first_child
        for c_idx != -1 {
            child := &l_ctx.nodes[c_idx]
            if child.config.sizing[main_axis].type == .Grow {
                weight := child.config.sizing[main_axis].value
                share := int(remaining_f * (weight / grow_total_weight))
                
                if main_axis == AXIS_X do child.min_w = share
                else do child.min_h = share
            }
            c_idx = child.next_sibling
        }
    }
    
    // 3. Commit determined sizes to final_rect and Recurse
    child_idx = node.first_child
    for child_idx != -1 {
        child := &l_ctx.nodes[child_idx]
        child.final_rect.w = child.min_w
        child.final_rect.h = child.min_h
        
        _pass2_resolve(l_ctx, child_idx)
        
        child_idx = child.next_sibling
    }
}

_pass3_position :: proc(l_ctx: ^LayoutContext, node_idx: int) {
    node := &l_ctx.nodes[node_idx]
    
     if !node.is_container {
        return
    }
    
    // We have the node's final rect (x,y,w,h).
    // Now place children inside.
    
    // Padding offsets
    start_x := node.final_rect.x + node.config.padding.left
    start_y := node.final_rect.y + node.config.padding.top
    
    content_w := max(0, node.final_rect.w - node.config.padding.left - node.config.padding.right)
    content_h := max(0, node.final_rect.h - node.config.padding.top - node.config.padding.bottom)
    
    main_axis := _get_main_axis(node.config.direction)
    cross_axis := _get_cross_axis(node.config.direction)
    
    // Alignment logic
    // Calculate total size used by children on main axis to determine free space for alignment
    total_children_main := 0
    child_idx := node.first_child
    child_count := 0
    for child_idx != -1 {
         child := l_ctx.nodes[child_idx]
         total_children_main += (main_axis == AXIS_X ? child.final_rect.w : child.final_rect.h)
         child_idx = child.next_sibling
         child_count += 1
    }
    if child_count > 1 {
        total_children_main += (child_count - 1) * node.config.gap
    }
    
    free_main := max(0, (main_axis == AXIS_X ? content_w : content_h) - total_children_main)
    
    main_offset := 0
    
    // Map alignment to offset
    align_main := main_axis == AXIS_X ? node.config.alignment.horizontal : cast(HorizontalAlignment)node.config.alignment.vertical
    
    // Enum casting trick assumes Horizontal/Vertical enums have compatible order (Left/Top=0, Center=1, Right/Bottom=2)
    // Actually they are distinct types, so manual check is safer/cleaner
    
    is_center := false
    is_end := false
    
    if main_axis == AXIS_X {
        // Horizontal Main
        if node.config.alignment.horizontal == .Center do is_center = true
        if node.config.alignment.horizontal == .Right do is_end = true
    } else {
        // Vertical Main
        if node.config.alignment.vertical == .Center do is_center = true
        if node.config.alignment.vertical == .Bottom do is_end = true
    }
    
    if is_center do main_offset = free_main / 2
    if is_end do main_offset = free_main
    
    // Place children
    current_pos := main_offset
    
    child_idx = node.first_child
    for child_idx != -1 {
        child := &l_ctx.nodes[child_idx]
        
        // Main Axis Position
        if main_axis == AXIS_X {
            child.final_rect.x = start_x + current_pos - node.config.scroll_offset.x
            current_pos += child.final_rect.w + node.config.gap
        } else {
            child.final_rect.y = start_y + current_pos - node.config.scroll_offset.y
            current_pos += child.final_rect.h + node.config.gap
        }
        
        // Cross Axis Position (Alignment)
        // Default is Start (Top/Left)
        cross_offset := 0
        free_cross := max(0, (cross_axis == AXIS_X ? content_w : content_h) - (cross_axis == AXIS_X ? child.final_rect.w : child.final_rect.h))
        
        is_cross_center := false
        is_cross_end := false
        
        if cross_axis == AXIS_X {
            // Horizontal Cross (Vertical Layout)
            if node.config.alignment.horizontal == .Center do is_cross_center = true
            if node.config.alignment.horizontal == .Right do is_cross_end = true
        } else {
            // Vertical Cross (Horizontal Layout)
            if node.config.alignment.vertical == .Center do is_cross_center = true
            if node.config.alignment.vertical == .Bottom do is_cross_end = true
        }
        
        if is_cross_center do cross_offset = free_cross / 2
        if is_cross_end do cross_offset = free_cross
        
        if cross_axis == AXIS_X {
             child.final_rect.x = start_x + cross_offset - node.config.scroll_offset.x
        } else {
             child.final_rect.y = start_y + cross_offset - node.config.scroll_offset.y
        }
        
        // Recurse
        _pass3_position(l_ctx, child_idx)
        
        child_idx = child.next_sibling
    }
}
