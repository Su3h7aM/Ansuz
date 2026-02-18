package ansuz_layout

import "core:math"
import "core:mem"
import "core:strings"

import ac "../color"
import ab "../buffer"

Rect :: ab.Rect

SizingType :: enum {
	FitContent,
	Fixed,
	Percent,
	Grow,
}

Sizing :: struct {
	type:  SizingType,
	value: f32,
}

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

LayoutDirection :: enum {
	LeftToRight,
	TopToBottom,
	ZStack,
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

LayoutConfig :: struct {
	direction:     LayoutDirection,
	sizing:        [Axis]Sizing,
	padding:       Padding,
	gap:           int,
	alignment:     Alignment,
	overflow:      Overflow,
	scroll_offset: [2]int,
	wrap_text:     bool,
	min_width:     int,
	min_height:    int,
	max_width:     int,
	max_height:    int,
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
	min_width = 0,
	min_height = 0,
	max_width = 0,
	max_height = 0,
}

LayoutNodeId :: distinct int
INVALID_NODE :: LayoutNodeId(-1)

RenderCommandType :: enum {
	None,
	Text,
	Box,
	Rect,
}

RenderCommand :: struct {
	type:      RenderCommandType,
	rect:      ab.Rect,
	text:      string,
	style:     ac.Style,
	char:      rune,
	box_style: ab.BoxStyle,
}

LayoutNode :: struct {
	id:           LayoutNodeId,
	config:       LayoutConfig,
	parent_index: LayoutNodeId,
	first_child:  LayoutNodeId,
	next_sibling: LayoutNodeId,
	is_container: bool,
	min_w, min_h: int,
	final_rect:   Rect,
	render_cmd:   RenderCommand,
}

LayoutContext :: struct {
	nodes:     [dynamic]LayoutNode,
	stack:     [dynamic]LayoutNodeId,
	allocator: mem.Allocator,
	root_rect: Rect,
}

init_layout_context :: proc(allocator := context.allocator) -> LayoutContext {
	return LayoutContext {
		nodes     = make([dynamic]LayoutNode, allocator),
		stack     = make([dynamic]LayoutNodeId, allocator),
		allocator = allocator,
	}
}

destroy_layout_context :: proc(ctx: ^LayoutContext) {
	delete(ctx.nodes)
	delete(ctx.stack)
}

reset_layout_context :: proc(ctx: ^LayoutContext, root_rect: Rect) {
	clear(&ctx.nodes)
	clear(&ctx.stack)
	ctx.root_rect = root_rect
	append(&ctx.stack, INVALID_NODE)
}

_add_node :: proc(l_ctx: ^LayoutContext, config: LayoutConfig, is_container: bool) -> LayoutNodeId {
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
			for int(curr) >= 0 && int(curr) < len(l_ctx.nodes) && l_ctx.nodes[int(curr)].next_sibling != INVALID_NODE {
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
	if len(l_ctx.stack) > 1 {
		pop(&l_ctx.stack)
	}
}

add_text :: proc(l_ctx: ^LayoutContext, content: string, style: ac.Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
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

add_box :: proc(l_ctx: ^LayoutContext, style: ac.Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
	node_idx := _add_node(l_ctx, config, false)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand {
		type  = .Box,
		style = style,
	}
}

add_box_container :: proc(l_ctx: ^LayoutContext, style: ac.Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG, box_style: ab.BoxStyle = .Sharp) {
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

add_rect :: proc(l_ctx: ^LayoutContext, char: rune, style: ac.Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
	node_idx := _add_node(l_ctx, config, false)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand {
		type  = .Rect,
		char = char,
		style = style,
	}
}

add_rect_container :: proc(l_ctx: ^LayoutContext, char: rune, style: ac.Style, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
	node_idx := _add_node(l_ctx, config, true)
	node := &l_ctx.nodes[node_idx]
	node.render_cmd = RenderCommand {
		type = .Rect,
		char  = char,
		style = style,
	}
	append(&l_ctx.stack, node_idx)
}

end_rect_container :: proc(l_ctx: ^LayoutContext) {
	end_container(l_ctx)
}

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

_rect_is_visible :: proc(rect: Rect) -> bool {
	return rect.w > 0 && rect.h > 0
}

_clamp_rect :: proc(rect: ^Rect, bounds_x, bounds_y, bounds_w, bounds_h: int, overflow: Overflow) {
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

finish_layout :: proc(l_ctx: ^LayoutContext) -> []RenderCommand {
	if len(l_ctx.nodes) == 0 {
		return nil
	}
	_pass1_measure(l_ctx, LayoutNodeId(0))
	l_ctx.nodes[0].final_rect = l_ctx.root_rect
	_pass2_resolve(l_ctx, LayoutNodeId(0))
	_pass3_position(l_ctx, LayoutNodeId(0))
	return _collect_render_commands(l_ctx)
}

_collect_render_commands :: proc(l_ctx: ^LayoutContext) -> []RenderCommand {
	commands := make([]RenderCommand, len(l_ctx.nodes), context.temp_allocator)
	for i in 0 ..< len(l_ctx.nodes) {
		node := &l_ctx.nodes[i]
		if node.render_cmd.type != .None || node.is_container {
			commands[i] = node.render_cmd
			commands[i].rect = node.final_rect
		}
	}
	return commands
}

_pass1_measure :: proc(l_ctx: ^LayoutContext, node_idx: LayoutNodeId) {
	node := &l_ctx.nodes[int(node_idx)]

	child_idx := node.first_child
	for child_idx != INVALID_NODE {
		_pass1_measure(l_ctx, child_idx)
		child_idx = l_ctx.nodes[int(child_idx)].next_sibling
	}

	for axis in Axis {
		size_config := node.config.sizing[axis]
		switch size_config.type {
		case .Fixed:
			val := int(size_config.value)
			if axis == .X do node.min_w = val
			else do node.min_h = val

		case .Percent:
			if axis == .X do node.min_w = 0
			else do node.min_h = 0

		case .Grow:
			if axis == .X do node.min_w = 0
			else do node.min_h = 0

		case .FitContent:
			if !node.is_container {
				val := int(size_config.value)
				if node.config.wrap_text && axis == .Y {
					if node.config.sizing[.X].type == .Fixed {
						w := int(node.config.sizing[.X].value)
						_, h := ab.measure_text_wrapped(node.render_cmd.text, w)
						val = h
					}
				}
				if axis == .X do node.min_w = val
				else do node.min_h = val
			} else {
				if node.config.direction == .ZStack {
					max_w := 0
					max_h := 0
					c_idx := node.first_child
					for c_idx != INVALID_NODE {
						child := l_ctx.nodes[int(c_idx)]
						max_w = max(max_w, child.min_w)
						max_h = max(max_h, child.min_h)
						c_idx = child.next_sibling
					}
					padding := node.config.padding.left + node.config.padding.right
					node.min_w = max_w + padding
					padding_v := node.config.padding.top + node.config.padding.bottom
					node.min_h = max_h + padding_v
				} else {
					main_axis := _get_main_axis(node.config.direction)
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
						padding := axis == .X ? (node.config.padding.left + node.config.padding.right) : (node.config.padding.top + node.config.padding.bottom)
						val := total + padding
						if axis == .X do node.min_w = val
						else do node.min_h = val
					} else {
						max_val := 0
						c_idx := node.first_child
						for c_idx != INVALID_NODE {
							child := l_ctx.nodes[int(c_idx)]
							val := (axis == .X ? child.min_w : child.min_h)
							max_val = max(max_val, val)
							c_idx = child.next_sibling
						}
						padding := axis == .X ? (node.config.padding.left + node.config.padding.right) : (node.config.padding.top + node.config.padding.bottom)
						val := max_val + padding
						if axis == .X do node.min_w = val
						else do node.min_h = val
					}
				}
			}
		}
	}
}

_pass2_resolve :: proc(l_ctx: ^LayoutContext, node_idx: LayoutNodeId) {
	node := &l_ctx.nodes[int(node_idx)]

	if !node.is_container {
		return
	}

	pad_w := node.config.padding.left + node.config.padding.right
	pad_h := node.config.padding.top + node.config.padding.bottom
	available_w := max(0, node.final_rect.w - pad_w)
	available_h := max(0, node.final_rect.h - pad_h)

	if node.config.direction == .ZStack {
		child_idx := node.first_child
		for child_idx != INVALID_NODE {
			child := &l_ctx.nodes[int(child_idx)]
			child.final_rect.w = available_w
			child.final_rect.h = available_h
			_pass2_resolve(l_ctx, child_idx)
			child_idx = child.next_sibling
		}
		return
	}

	main_axis := _get_main_axis(node.config.direction)
	cross_axis := _get_cross_axis(node.config.direction)

	used_main := 0
	grow_total_weight: f32 = 0
	child_count := 0

	child_idx := node.first_child
	for child_idx != INVALID_NODE {
		child := &l_ctx.nodes[int(child_idx)]
		child_count += 1

		if child.config.sizing[main_axis].type == .Grow {
			grow_total_weight += child.config.sizing[main_axis].value
		} else if child.config.sizing[main_axis].type == .Percent {
			val_f := child.config.sizing[main_axis].value
			avail := main_axis == .X ? available_w : available_h
			resolved := int(f32(avail) * val_f)
			if main_axis == .X do child.min_w = resolved
			else do child.min_h = resolved
			used_main += resolved
		} else {
			used_main += (main_axis == .X ? child.min_w : child.min_h)
		}

		if child.config.sizing[cross_axis].type == .Percent {
			val_f := child.config.sizing[cross_axis].value
			avail := cross_axis == .X ? available_w : available_h
			resolved := int(f32(avail) * val_f)
			if cross_axis == .X do child.min_w = resolved
			else do child.min_h = resolved
		}

		if child.config.sizing[cross_axis].type == .Grow {
			avail := cross_axis == .X ? available_w : available_h
			if cross_axis == .X do child.min_w = avail
			else do child.min_h = avail
		}

		child_idx = child.next_sibling
	}

	if child_count > 1 {
		used_main += (child_count - 1) * node.config.gap
	}

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

	child_idx = node.first_child
	for child_idx != INVALID_NODE {
		child := &l_ctx.nodes[int(child_idx)]
		child.final_rect.w = child.min_w
		child.final_rect.h = child.min_h

		if child.config.min_width > 0 {
			child.final_rect.w = max(child.final_rect.w, child.config.min_width)
		}
		if child.config.min_height > 0 {
			child.final_rect.h = max(child.final_rect.h, child.config.min_height)
		}
		if child.config.max_width > 0 {
			child.final_rect.w = min(child.final_rect.w, child.config.max_width)
		}
		if child.config.max_height > 0 {
			child.final_rect.h = min(child.final_rect.h, child.config.max_height)
		}

		if child.config.wrap_text && !child.is_container {
			if child.config.sizing[.Y].type == .FitContent {
				_, h := ab.measure_text_wrapped(child.render_cmd.text, child.min_w)
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

	start_x := node.final_rect.x + node.config.padding.left
	start_y := node.final_rect.y + node.config.padding.top

	content_w := max(0, node.final_rect.w - node.config.padding.left - node.config.padding.right)
	content_h := max(0, node.final_rect.h - node.config.padding.top - node.config.padding.bottom)

	if node.config.direction == .ZStack {
		child_idx := node.first_child
		for child_idx != INVALID_NODE {
			child := &l_ctx.nodes[int(child_idx)]
			child.final_rect.x = start_x - node.config.scroll_offset.x
			child.final_rect.y = start_y - node.config.scroll_offset.y
			_clamp_rect(
				&child.final_rect,
				start_x,
				start_y,
				content_w,
				content_h,
				node.config.overflow,
			)
			_pass3_position(l_ctx, child_idx)
			child_idx = child.next_sibling
		}
		return
	}

	main_axis := _get_main_axis(node.config.direction)
	cross_axis := _get_cross_axis(node.config.direction)

	total_children_main := 0
	child_count := 0
	child_idx := node.first_child
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
	align_main := main_axis == .X ? node.config.alignment.horizontal : cast(HorizontalAlignment)node.config.alignment.vertical

	is_center := false
	is_end := false
	if main_axis == .X {
		if node.config.alignment.horizontal == .Center do is_center = true
		if node.config.alignment.horizontal == .Right do is_end = true
	} else {
		if node.config.alignment.vertical == .Center do is_center = true
		if node.config.alignment.vertical == .Bottom do is_end = true
	}

	if is_center do main_offset = free_main / 2
	if is_end do main_offset = free_main

	current_pos := main_offset
	child_idx = node.first_child
	for child_idx != INVALID_NODE {
		child := &l_ctx.nodes[int(child_idx)]

		if main_axis == .X {
			child.final_rect.x = start_x + current_pos - node.config.scroll_offset.x
			current_pos += child.final_rect.w + node.config.gap
		} else {
			child.final_rect.y = start_y + current_pos - node.config.scroll_offset.y
			current_pos += child.final_rect.h + node.config.gap
		}

		cross_offset := 0
		free_cross := max(0, (cross_axis == .X ? content_w : content_h) - (cross_axis == .X ? child.final_rect.w : child.final_rect.h))

		is_cross_center := false
		is_cross_end := false
		if cross_axis == .X {
			if node.config.alignment.horizontal == .Center do is_cross_center = true
			if node.config.alignment.horizontal == .Right do is_cross_end = true
		} else {
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

		_pass3_position(l_ctx, child_idx)
		child_idx = child.next_sibling
	}
}
