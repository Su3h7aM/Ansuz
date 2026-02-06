package ansuz

import "core:math"
import "core:mem"

// --- Public API ---

// Sizing rules for layout elements
SizingType :: enum {
	Fixed, // Fixed size in cells
	Percent, // Percentage of parent's available space (0.0 to 1.0)
	FitContent, // Size according to children or content
	Grow, // Grow to fill remaining space
}

Sizing :: struct {
	type:  SizingType,
	value: f32,
}

// Convenience constructors for Sizing

fixed :: proc(value: int) -> Sizing {
	return Sizing{.Fixed, f32(value)}
}

percent :: proc(value: f32) -> Sizing {
	return Sizing{.Percent, value}
}

fit :: proc() -> Sizing {
	return Sizing{.FitContent, 0}
}

grow :: proc(weight: f32 = 1.0) -> Sizing {
	return Sizing{.Grow, weight}
}

// Deprecated legacy constructors


LayoutDirection :: enum {
	LeftToRight,
	TopToBottom,
}

Axis :: enum {
	X,
	Y,
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

padding_all :: proc(value: int) -> Padding {
	return Padding{value, value, value, value}
}

Overflow :: enum {
	Hidden,
	Visible,
	Scroll,
}

_clamp_rect :: proc(rect: ^Rect, bounds_x, bounds_y, bounds_w, bounds_h: int, overflow: Overflow) {
	// Only clamp for Hidden overflow - Scroll and Visible allow content outside bounds
	if overflow != .Hidden do return

	rect.x = max(bounds_x, rect.x)
	rect.y = max(bounds_y, rect.y)

	max_x := bounds_x + bounds_w
	max_y := bounds_y + bounds_h

	if rect.x + rect.w > max_x {
		rect.w = max(0, max_x - rect.x)
	}
	if rect.y + rect.h > max_y {
		rect.h = max(0, max_y - rect.y)
	}
}

LayoutConfig :: struct {
	direction:     LayoutDirection,
	sizing:        [Axis]Sizing,
	padding:       Padding,
	gap:           int,
	alignment:     Alignment,
	overflow:      Overflow,
	scroll_offset: [2]int, // x, y offset
	wrap_text:     bool, // Enable text wrapping
}

DEFAULT_LAYOUT_CONFIG :: LayoutConfig {
	direction = .TopToBottom,
	sizing = {.X = Sizing{.FitContent, 0}, .Y = Sizing{.FitContent, 0}},
	padding = {0, 0, 0, 0},
	gap = 0,
	alignment = {.Left, .Top},
	overflow = .Hidden,
	scroll_offset = {0, 0},
	wrap_text = false,
}

Rect :: struct {
	x, y, w, h: int,
}

LayoutNodeId :: distinct int
INVALID_NODE :: LayoutNodeId(-1)

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
	char:      rune, // For Rect command
	box_style: BoxStyle, // For Box command
}

// LayoutNode represents an element in the layout tree
LayoutNode :: struct {
	id:           LayoutNodeId,
	config:       LayoutConfig,

	// Structure
	parent_index: LayoutNodeId,
	first_child:  LayoutNodeId,
	next_sibling: LayoutNodeId,
	is_container: bool,

	// Computed Layout computed in phases
	min_w, min_h: int, // From Pass 1 (Fit)
	final_rect:   Rect, // Final result
	render_cmd:   RenderCommand,
}

LayoutContext :: struct {
	nodes:     [dynamic]LayoutNode,
	stack:     [dynamic]LayoutNodeId, // Stack of parent indices
	allocator: mem.Allocator,
	root_rect: Rect,
}

init_layout_context :: proc(allocator := context.allocator) -> LayoutContext {
	l_ctx := LayoutContext {
		nodes     = make([dynamic]LayoutNode, allocator),
		stack     = make([dynamic]LayoutNodeId, allocator),
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
	append(&ctx.stack, INVALID_NODE) // Root parent marker
}

// --- Node Management ---

// Internal: adds a node to the tree
_add_node :: proc(
	l_ctx: ^LayoutContext,
	config: LayoutConfig,
	is_container: bool,
) -> LayoutNodeId {
	parent_idx := len(l_ctx.stack) > 0 ? l_ctx.stack[len(l_ctx.stack) - 1] : INVALID_NODE

	node := LayoutNode {
		id           = LayoutNodeId(len(l_ctx.nodes)),
		config       = config,
		parent_index = parent_idx,
		first_child  = INVALID_NODE,
		next_sibling = INVALID_NODE,
		is_container = is_container,
	}

	node_idx := LayoutNodeId(len(l_ctx.nodes))

	if parent_idx != INVALID_NODE && int(parent_idx) < len(l_ctx.nodes) {
		parent := &l_ctx.nodes[int(parent_idx)]
		if parent.first_child == INVALID_NODE {
			parent.first_child = node_idx
		} else {
			curr := parent.first_child
			for int(curr) >= 0 &&
			    int(curr) < len(l_ctx.nodes) &&
			    l_ctx.nodes[int(curr)].next_sibling != INVALID_NODE {
				curr = l_ctx.nodes[int(curr)].next_sibling
			}
			if int(curr) >= 0 && int(curr) < len(l_ctx.nodes) {
				l_ctx.nodes[int(curr)].next_sibling = node_idx
			}
		}
	}

	append(&l_ctx.nodes, node)
	return node_idx
}

begin_container :: proc(l_ctx: ^LayoutContext, config: LayoutConfig) -> LayoutNodeId {
	node_idx := _add_node(l_ctx, config, true)
	append(&l_ctx.stack, node_idx)
	return node_idx
}

end_container :: proc(l_ctx: ^LayoutContext) {
	if len(l_ctx.stack) > 1 { 	// Don't pop -1
		pop(&l_ctx.stack)
	}
}

add_text :: proc(
	l_ctx: ^LayoutContext,
	content: string,
	style: Style,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
) {
	cfg := config
	if cfg.sizing[.X].type == .FitContent {
		cfg.sizing[.X].value = f32(len(content))
	}
	if cfg.sizing[.Y].type == .FitContent {
		cfg.sizing[.Y].value = 1
	}

	node_idx := _add_node(l_ctx, cfg, false)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand {
		type  = .Text,
		text  = content,
		style = style,
	}
}

add_box :: proc(
	l_ctx: ^LayoutContext,
	style: Style,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
) {
	node_idx := _add_node(l_ctx, config, false)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand {
		type  = .Box,
		style = style,
	}
}

add_box_container :: proc(
	l_ctx: ^LayoutContext,
	style: Style,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
	box_style: BoxStyle = .Sharp,
) {
	// Automatically add padding for the border so content doesn't overlap it
	modified_config := config
	modified_config.padding.left += 1
	modified_config.padding.right += 1
	modified_config.padding.top += 1
	modified_config.padding.bottom += 1

	node_idx := _add_node(l_ctx, modified_config, true)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand {
		type      = .Box,
		style     = style,
		box_style = box_style,
	}
	append(&l_ctx.stack, node_idx)
}

end_box_container :: proc(l_ctx: ^LayoutContext) {
	end_container(l_ctx)
}

add_rect :: proc(
	l_ctx: ^LayoutContext,
	char: rune,
	style: Style,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
) {
	node_idx := _add_node(l_ctx, config, false)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand {
		type  = .Rect,
		char  = char,
		style = style,
	}
}

add_rect_container :: proc(
	l_ctx: ^LayoutContext,
	char: rune,
	style: Style,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
) {
	node_idx := _add_node(l_ctx, config, true)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand {
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


_get_main_axis :: proc(dir: LayoutDirection) -> Axis {
	return dir == .LeftToRight ? .X : .Y
}

_get_cross_axis :: proc(dir: LayoutDirection) -> Axis {
	return dir == .LeftToRight ? .Y : .X
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

// Check if a rect has positive dimensions and is visible
_rect_is_visible :: proc(rect: Rect) -> bool {
	return rect.w > 0 && rect.h > 0
}

finish_layout :: proc(l_ctx: ^LayoutContext, ansuz_ctx: ^Context) {
	if len(l_ctx.nodes) == 0 do return

	// Pass 1: Measure `Fit`, Bottom-Up
	_pass1_measure(l_ctx, LayoutNodeId(0))

	// Pass 2: Resolve `Grow`, Top-Down
	// Root takes the context root rect size
	l_ctx.nodes[0].final_rect = l_ctx.root_rect
	_pass2_resolve(l_ctx, LayoutNodeId(0))

	// Pass 3: Position, Top-Down
	_pass3_position(l_ctx, LayoutNodeId(0))

	// Rendering (Recursive for Clipping)
	initial_clip := Rect{0, 0, ansuz_ctx.width, ansuz_ctx.height}

	// Find absolute roots (usually just 0, but safe to check)
	// Actually nodes[0] is strictly the root in our usage.
	if len(l_ctx.nodes) > 0 {
		_render_recursive(l_ctx, ansuz_ctx, LayoutNodeId(0), initial_clip)
	}
}

_render_recursive :: proc(
	l_ctx: ^LayoutContext,
	ansuz_ctx: ^Context,
	node_idx: LayoutNodeId,
	parent_clip: Rect,
) {
	node := &l_ctx.nodes[int(node_idx)]

	// Early exit: compute visible rect and skip if completely invisible
	visible_rect := rect_intersection(node.final_rect, parent_clip)
	if !_rect_is_visible(visible_rect) {
		return // Element is completely outside clip bounds, skip entirely
	}

	// Set clip rect for rendering
	set_clip_rect(&ansuz_ctx.buffer, parent_clip)

	cmd := &node.render_cmd
	if cmd.type != .None || node.is_container {
		cmd.rect = node.final_rect

		switch cmd.type {
		case .None:
		case .Text:
			if node.config.wrap_text {
				write_string_wrapped(
					&ansuz_ctx.buffer,
					cmd.rect.x,
					cmd.rect.y,
					cmd.rect.w,
					cmd.text,
					cmd.style.fg,
					cmd.style.bg,
					cmd.style.flags,
				)
			} else {
				text(ansuz_ctx, cmd.rect.x, cmd.rect.y, cmd.text, cmd.style)
			}
		case .Box:
			w := max(0, cmd.rect.w)
			h := max(0, cmd.rect.h)
			if w > 0 && h > 0 {
				box(ansuz_ctx, cmd.rect.x, cmd.rect.y, w, h, cmd.style, cmd.box_style)
			}
		case .Rect:
			w := max(0, cmd.rect.w)
			h := max(0, cmd.rect.h)
			if w > 0 && h > 0 {
				rect(ansuz_ctx, cmd.rect.x, cmd.rect.y, w, h, cmd.char, cmd.style)
			}
		}
	}

	// Determine clip for children
	child_clip := parent_clip
	if node.config.overflow != .Visible {
		clip_source := node.final_rect

		// If this node draws a box, inset the clip rect so children
		// don't draw over the border
		if node.render_cmd.type == .Box {
			clip_source.x += 1
			clip_source.y += 1
			clip_source.w = max(0, clip_source.w - 2)
			clip_source.h = max(0, clip_source.h - 2)
		}

		child_clip = rect_intersection(parent_clip, clip_source)
	}

	// Early exit for children if child clip is invalid
	if !_rect_is_visible(child_clip) {
		return
	}

	// Recurse into children
	child_idx := node.first_child
	for child_idx != INVALID_NODE {
		_render_recursive(l_ctx, ansuz_ctx, child_idx, child_clip)
		child_idx = l_ctx.nodes[int(child_idx)].next_sibling
	}
}

_pass1_measure :: proc(l_ctx: ^LayoutContext, node_idx: LayoutNodeId) {
	node := &l_ctx.nodes[int(node_idx)]

	// Recurse first (Bottom-Up)
	child_idx := node.first_child
	for child_idx != INVALID_NODE {
		_pass1_measure(l_ctx, child_idx)
		child_idx = l_ctx.nodes[int(child_idx)].next_sibling
	}

	// Now calculate size for THIS node
	// We treat X and Y independently initially
	for axis in Axis {
		size_config := node.config.sizing[axis]

		switch size_config.type {
		case .Fixed:
			val := int(size_config.value)
			if axis == .X do node.min_w = val
			else do node.min_h = val

		case .Percent:
			// Cannot determine in this pass, set to 0 for now
			if axis == .X do node.min_w = 0
			else do node.min_h = 0

		case .Grow:
			// Cannot determine in this pass
			if axis == .X do node.min_w = 0
			else do node.min_h = 0

		case .FitContent:
			// This is where standard layout logic happens (Sum vs Max)
			if !node.is_container {
				// Leaf node fit content: should have been set by add_text etc.
				// If not (e.g. empty container marked fit), defaults to 0
				val := int(size_config.value)

				// Special handling for wrapped text with fixed width
				if node.config.wrap_text && axis == .Y {
					// If Width is Fixed, we can calculate height now
					if node.config.sizing[.X].type == .Fixed {
						w := int(node.config.sizing[.X].value)
						_, h := measure_text_wrapped(node.render_cmd.text, w)
						val = h
					}
					// If Width is Grow/Percent, we can't calculate height yet (Wait for Pass 2)
					// Keep val as is (likely 1 or based on len) - or set to 0?
					// Usually add_text sets it to 1.
				}

				if axis == .X do node.min_w = val
				else do node.min_h = val
			} else {
				// Container logic
				main_axis := _get_main_axis(node.config.direction)

				// If current axis is the main axis of the container, we SUM children
				if axis == main_axis {
					total := 0
					c_idx := node.first_child
					child_count := 0
					for c_idx != INVALID_NODE {
						child := l_ctx.nodes[int(c_idx)]
						total += (axis == .X ? child.min_w : child.min_h)
						c_idx = child.next_sibling
						child_count += 1
					}
					if child_count > 1 {
						total += (child_count - 1) * node.config.gap
					}
					padding :=
						axis == .X ? (node.config.padding.left + node.config.padding.right) : (node.config.padding.top + node.config.padding.bottom)
					val := total + padding
					if axis == .X do node.min_w = val
					else do node.min_h = val
				} else {
					// If current axis is the CROSS axis, we take MAX of children
					max_val := 0
					c_idx := node.first_child
					for c_idx != INVALID_NODE {
						child := l_ctx.nodes[int(c_idx)]
						val := (axis == .X ? child.min_w : child.min_h)
						max_val = max(max_val, val)
						c_idx = child.next_sibling
					}
					padding :=
						axis == .X ? (node.config.padding.left + node.config.padding.right) : (node.config.padding.top + node.config.padding.bottom)
					val := max_val + padding
					if axis == .X do node.min_w = val
					else do node.min_h = val
				}
			}
		}
	}
}

_pass2_resolve :: proc(l_ctx: ^LayoutContext, node_idx: LayoutNodeId) {
	node := &l_ctx.nodes[int(node_idx)]

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
	for child_idx != INVALID_NODE {
		child := &l_ctx.nodes[int(child_idx)]
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
			avail := main_axis == .X ? available_w : available_h
			resolved := int(f32(avail) * val_f)
			if main_axis == .X do child.min_w = resolved
			else do child.min_h = resolved
			used_main += resolved
		} else {
			// Fixed or Fit (already calculated in Pass 1)
			used_main += (main_axis == .X ? child.min_w : child.min_h)
		}

		// CROSS AXIS logic - mostly just Percent needs resolving here, or Stretches
		if child.config.sizing[cross_axis].type == .Percent {
			val_f := child.config.sizing[cross_axis].value
			avail := cross_axis == .X ? available_w : available_h
			resolved := int(f32(avail) * val_f)
			if cross_axis == .X do child.min_w = resolved
			else do child.min_h = resolved
		}
		// Grow on Cross is "Stretch" usually, implies filling the parent's cross size.
		if child.config.sizing[cross_axis].type == .Grow {
			avail := cross_axis == .X ? available_w : available_h
			if cross_axis == .X do child.min_w = avail
			else do child.min_h = avail
		}

		child_idx = child.next_sibling
	}

	// Add Gaps to used space
	if child_count > 1 {
		used_main += (child_count - 1) * node.config.gap
	}

	// 2. Distribute remaining space to Growers
	avail_main := (main_axis == .X ? available_w : available_h)
	remaining_main := max(0, avail_main - used_main)

	if grow_total_weight > 0 {
		remaining_f := f32(remaining_main)

		c_idx := node.first_child
		for c_idx != INVALID_NODE {
			child := &l_ctx.nodes[int(c_idx)]
			if child.config.sizing[main_axis].type == .Grow {
				weight := child.config.sizing[main_axis].value
				share := int(remaining_f * (weight / grow_total_weight))

				if main_axis == .X do child.min_w = share
				else do child.min_h = share
			}
			c_idx = child.next_sibling
		}
	}

	// 3. Commit determined sizes to final_rect and Recurse
	child_idx = node.first_child
	for child_idx != INVALID_NODE {
		child := &l_ctx.nodes[int(child_idx)]
		child.final_rect.w = child.min_w
		child.final_rect.h = child.min_h

		// DYNAMIC HEIGHT RESOLUTION FOR WRAPPED TEXT
		// If this child needs wrapping and logic deferred to here (Grow/Percent Width)
		if child.config.wrap_text && !child.is_container {
			// If height is FitContent (it should be for wrapping to work naturally)
			// We now know the width (child.min_w), so we can calculate height
			// Note: We only do this if height is NOT fixed.
			// Ideally we check if sizing[Y] is FitContent.
			// Just checking fit content for now.
			if child.config.sizing[.Y].type == .FitContent {
				_, h := measure_text_wrapped(child.render_cmd.text, child.min_w)
				child.min_h = h
				child.final_rect.h = h
			}
		}

		_pass2_resolve(l_ctx, child_idx)

		child_idx = child.next_sibling
	}
}

_pass3_position :: proc(l_ctx: ^LayoutContext, node_idx: LayoutNodeId) {
	node := &l_ctx.nodes[int(node_idx)]

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
	for child_idx != INVALID_NODE {
		child := l_ctx.nodes[int(child_idx)]
		total_children_main += (main_axis == .X ? child.final_rect.w : child.final_rect.h)
		child_idx = child.next_sibling
		child_count += 1
	}
	if child_count > 1 {
		total_children_main += (child_count - 1) * node.config.gap
	}

	free_main := max(0, (main_axis == .X ? content_w : content_h) - total_children_main)

	main_offset := 0

	// Map alignment to offset
	align_main :=
		main_axis == .X ? node.config.alignment.horizontal : cast(HorizontalAlignment)node.config.alignment.vertical

	// Enum casting trick assumes Horizontal/Vertical enums have compatible order (Left/Top=0, Center=1, Right/Bottom=2)
	// Actually they are distinct types, so manual check is safer/cleaner

	is_center := false
	is_end := false

	if main_axis == .X {
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
	for child_idx != INVALID_NODE {
		child := &l_ctx.nodes[int(child_idx)]

		// Main Axis Position
		if main_axis == .X {
			child.final_rect.x = start_x + current_pos - node.config.scroll_offset.x
			current_pos += child.final_rect.w + node.config.gap
		} else {
			child.final_rect.y = start_y + current_pos - node.config.scroll_offset.y
			current_pos += child.final_rect.h + node.config.gap
		}

		// Cross Axis Position (Alignment)
		// Default is Start (Top/Left)
		cross_offset := 0
		free_cross := max(
			0,
			(cross_axis == .X ? content_w : content_h) -
			(cross_axis == .X ? child.final_rect.w : child.final_rect.h),
		)

		is_cross_center := false
		is_cross_end := false

		if cross_axis == .X {
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

		if cross_axis == .X {
			child.final_rect.x = start_x + cross_offset - node.config.scroll_offset.x
		} else {
			child.final_rect.y = start_y + cross_offset - node.config.scroll_offset.y
		}

		_clamp_rect(
			&child.final_rect,
			start_x,
			start_y,
			content_w,
			content_h,
			node.config.overflow,
		)

		// Recurse
		_pass3_position(l_ctx, child_idx)

		child_idx = child.next_sibling
	}
}
