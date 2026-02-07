package ansuz

import "core:fmt"
import "core:hash"

// ============================================================================
// Element ID - Type-safe identifier for elements
// ============================================================================

ElementId :: distinct u64

// Generate element ID from string label (like Clay's CLAY_ID)
element_id :: proc(label: string) -> ElementId {
	return ElementId(hash.fnv64a(transmute([]u8)label))
}

// ============================================================================
// Element Declaration - Clay-style unified struct for all elements
// ============================================================================

// Element is the unified configuration for any UI element.
// Uses `using layout` for direct field access to layout properties.
Element :: struct {
	// Layout configuration (using for direct field access)
	using layout: LayoutConfig,

	// Visual styling
	style:        Style,
	box_style:    Maybe(BoxStyle),
	fill_char:    Maybe(rune), // Fill character for rect elements

	// Content
	content:      Maybe(string),

	// Behavior
	focusable:    bool,
	id_source:    string, // String for ID generation (required for focusable elements)
}

// element_default returns the default element configuration
// (proc because Style contains union types which aren't compile-time constants)
element_default :: proc() -> Element {
	return Element {
		layout = DEFAULT_LAYOUT_CONFIG,
		style = default_style(),
		box_style = nil,
		fill_char = nil,
		content = nil,
		focusable = false,
		id_source = "",
	}
}

// ============================================================================
// Element API - Clay-style immediate mode element creation
// ============================================================================

// begin_element starts a container element.
// Must be paired with end_element().
begin_element :: proc(ctx: ^Context, el: Element = {}) {
	_process_element_start(ctx, el, true)
}

// end_element ends the current container element.
end_element :: proc(ctx: ^Context) {
	end_container(&ctx.layout_ctx)
}


// element adds a leaf element (non-container)
element :: proc(ctx: ^Context, el: Element = {}) {
	_process_element_start(ctx, el, false)
}

// label is a convenience function for text elements (renamed from text to avoid conflict)
label :: proc(ctx: ^Context, txt: string, el: Element = {}) {
	modified := el
	modified.content = txt
	if el.sizing[.Y].type == .FitContent {
		modified.sizing[.Y] = fixed(1)
	}
	element(ctx, modified)
}

// ============================================================================
// Internal Element Processing
// ============================================================================

@(private)
_process_element_start :: proc(ctx: ^Context, el: Element, is_container: bool) {
	l_ctx := &ctx.layout_ctx

	// Handle focusable elements
	if el.focusable && el.id_source != "" {
		elem_id := u64(element_id(el.id_source))
		register_focusable(ctx, elem_id)
	}

	// Determine render command
	render_cmd := _element_to_render_cmd(el)

	// Add to layout tree
	if is_container {
		// For containers with box_style, add border padding
		config := el.layout
		if bs, ok := el.box_style.?; ok {
			_ = bs // Box style present - add border padding
			config.padding.left += 1
			config.padding.right += 1
			config.padding.top += 1
			config.padding.bottom += 1
		}

		node_idx := begin_container(l_ctx, config)
		node := &l_ctx.nodes[node_idx]
		node.render_cmd = render_cmd
	} else {
		// Adjust sizing for content
		config := el.layout
		if txt, ok := el.content.?; ok {
			if config.sizing[.X].type == .FitContent {
				config.sizing[.X].value = f32(len(txt))
			}
			if config.sizing[.Y].type == .FitContent {
				config.sizing[.Y].value = 1
			}
		}

		node_idx := _add_node(l_ctx, config, false)
		node := &l_ctx.nodes[node_idx]
		node.render_cmd = render_cmd
	}
}

@(private)
_element_to_render_cmd :: proc(el: Element) -> RenderCommand {
	// Priority: content > box > fill_char > none
	if txt, ok := el.content.?; ok {
		return RenderCommand{type = .Text, text = txt, style = el.style}
	}

	if bs, ok := el.box_style.?; ok {
		return RenderCommand{type = .Box, style = el.style, box_style = bs}
	}

	if char, ok := el.fill_char.?; ok {
		return RenderCommand{type = .Rect, style = el.style, char = char}
	}

	return RenderCommand{type = .None}
}

// ============================================================================
// High-Level Widget Helpers (using Element internally)
// ============================================================================

// widget_button creates a button using the Element API
// Returns true if clicked
widget_button :: proc(ctx: ^Context, lbl: string) -> bool {
	elem_id := u64(element_id(lbl))
	register_focusable(ctx, elem_id)

	focused := is_focused(ctx, elem_id)
	interaction := interact(ctx, elem_id, Rect{})

	// Get theme for current state
	theme := get_button_theme(ctx.theme, focused)

	element(
		ctx,
		Element {
			content = fmt.tprintf("%s%s", theme.prefix, lbl),
			style = theme.style,
			sizing = {.X = grow(), .Y = fixed(1)},
			focusable = true,
			id_source = lbl,
		},
	)

	return interaction == .Clicked
}

// widget_checkbox creates a checkbox using the Element API
// Returns true if toggled this frame
widget_checkbox :: proc(ctx: ^Context, lbl: string, checked: ^bool) -> bool {
	elem_id := u64(element_id(lbl))
	register_focusable(ctx, elem_id)

	focused := is_focused(ctx, elem_id)
	interaction := interact(ctx, elem_id, Rect{})

	if interaction == .Clicked {
		checked^ = !checked^
	}

	// Get theme for current state
	theme := get_checkbox_theme(ctx.theme, checked^, focused)

	element(
		ctx,
		Element {
			content = fmt.tprintf("%s%s", theme.prefix, lbl),
			style = theme.style,
			sizing = {.X = grow(), .Y = fixed(1)},
			focusable = true,
			id_source = lbl,
		},
	)

	return interaction == .Clicked
}
