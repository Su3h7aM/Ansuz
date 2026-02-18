package ansuz

import "core:fmt"
import "core:hash"
import "core:strings"

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

// @(private)
// _begin_element starts a container element (internal).
// Must be paired with _end_element().
_begin_element :: proc(ctx: ^Context, el: Element = {}) {
    _process_element_start(ctx, el, true)
}

// @(private)
// _end_element ends the current container element (internal).
_end_element :: proc(ctx: ^Context) {
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
    if el.sizing[.Y].type == .FitContent && !el.wrap_text {
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

// Interaction state for a widget
Interaction :: enum {
	None,
	Hovered, // For future mouse support
	Clicked,
}

// interact handles standard widget interaction logic (focus, clicks)
// rect argument is currently unused but reserved for mouse hit testing
interact :: proc(ctx: ^Context, id: u64, rect: Rect) -> Interaction {
	if !is_focused(ctx, id) {
		return .None
	}

	// Check for activation keys (Enter or Space)
	// NOTE: We consume the key by removing it from input_keys after detection
	// to prevent multiple widgets from processing the same key in one frame
	for i := 0; i < len(ctx.input_keys); i += 1 {
		k := ctx.input_keys[i]
		if k.key == .Enter {
			// Consume the key
			unordered_remove(&ctx.input_keys, i)
			return .Clicked
		}
		if k.key == .Char && k.rune == ' ' {
			// Consume the key
			unordered_remove(&ctx.input_keys, i)
			return .Clicked
		}
	}

	return .Hovered
}

// widget_button creates a button using the Element API
// Returns true if clicked
widget_button :: proc(ctx: ^Context, lbl: string) -> bool {
    elem_id := u64(element_id(lbl))
    // NOTE: register_focusable is called automatically by _process_element_start
    // when the Element has focusable=true, so we don't call it here

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
	// NOTE: register_focusable is called automatically by _process_element_start
	// when the Element has focusable=true, so we don't call it here

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

// ============================================================================
// Input Widget
// ============================================================================

// widget_input creates a text input field using the Element API
// - value: pointer to the current text value (managed by caller)
// - cursor_pos: pointer to cursor position (managed by caller)
// - placeholder: text to show when value is empty (optional)
// - Returns true if value was modified this frame
widget_input :: proc(ctx: ^Context, lbl: string, value: ^string, cursor_pos: ^int, placeholder: string = "") -> bool {
	elem_id := u64(element_id(lbl))
	focused := is_focused(ctx, elem_id)
	modified := false

	// Process input keys only when focused
	if focused {
		for i := 0; i < len(ctx.input_keys); i += 1 {
			k := ctx.input_keys[i]

			#partial switch k.key {
			case .Char:
				// Insert character at cursor position
				if k.rune != 0 {
					new_value := fmt.tprintf("%s%c%s", value[:cursor_pos^], k.rune, value[cursor_pos^:])
					// Clone to persistent allocator since temp_allocator gets freed each frame
					// Note: Caller is responsible for freeing the old value if it was dynamically allocated
					value^ = strings.clone(new_value, ctx.allocator)
					cursor_pos^ += 1
					modified = true
					// Consume the key
					unordered_remove(&ctx.input_keys, i)
					i -= 1
				}

			case .Backspace:
				// Delete character before cursor
				if cursor_pos^ > 0 {
					new_value := fmt.tprintf("%s%s", value[:cursor_pos^-1], value[cursor_pos^:])
					// Clone to persistent allocator since temp_allocator gets freed each frame
					// Note: Caller is responsible for freeing the old value if it was dynamically allocated
					value^ = strings.clone(new_value, ctx.allocator)
					cursor_pos^ -= 1
					modified = true
				}
				// Consume the key
				unordered_remove(&ctx.input_keys, i)
				i -= 1

			case .Delete:
				// Delete character at cursor
				if cursor_pos^ < len(value^) {
					new_value := fmt.tprintf("%s%s", value[:cursor_pos^], value[cursor_pos^+1:])
					// Clone to persistent allocator since temp_allocator gets freed each frame
					// Note: Caller is responsible for freeing the old value if it was dynamically allocated
					value^ = strings.clone(new_value, ctx.allocator)
					modified = true
				}
				// Consume the key
				unordered_remove(&ctx.input_keys, i)
				i -= 1

			case .Left:
				// Move cursor left
				if cursor_pos^ > 0 {
					cursor_pos^ -= 1
				}
				// Consume the key
				unordered_remove(&ctx.input_keys, i)
				i -= 1

			case .Right:
				// Move cursor right
				if cursor_pos^ < len(value^) {
					cursor_pos^ += 1
				}
				// Consume the key
				unordered_remove(&ctx.input_keys, i)
				i -= 1

			case .Home:
				// Move cursor to start
				cursor_pos^ = 0
				// Consume the key
				unordered_remove(&ctx.input_keys, i)
				i -= 1

			case .End:
				// Move cursor to end
				cursor_pos^ = len(value^)
				// Consume the key
				unordered_remove(&ctx.input_keys, i)
				i -= 1
			}
		}
	}

	// Get theme for current state
	theme := get_input_theme(ctx.theme, focused)

	// Determine what to display
	display_text := value^
	if len(display_text) == 0 && len(placeholder) > 0 {
		display_text = placeholder
		// Use placeholder style instead
		theme.style = ctx.theme.input_placeholder
	}

	// Render the input field
	element(
		ctx,
		Element {
			content = display_text,
			style = theme.style,
			sizing = {.X = grow(), .Y = fixed(1)},
			focusable = true,
			id_source = lbl,
		},
	)

	return modified
}

// ============================================================================
// Select Widget
// ============================================================================

// widget_select creates a dropdown select widget using the Element API
// - options: array of option labels
// - selected_idx: pointer to the currently selected index (managed by caller)
// - is_open: pointer to track if dropdown is open (managed by caller)
// - Returns true if selection changed this frame
widget_select :: proc(ctx: ^Context, lbl: string, options: []string, selected_idx: ^int, is_open: ^bool) -> bool {
	elem_id := u64(element_id(lbl))
	focused := is_focused(ctx, elem_id)
	selection_changed := false

	// Ensure selected_idx is valid
	if selected_idx^ < 0 {
		selected_idx^ = 0
	}
	if selected_idx^ >= len(options) {
		selected_idx^ = len(options) - 1
	}
	if selected_idx^ < 0 {
		selected_idx^ = 0
	}

	// Get display text for current selection
	display_text := ""
	if selected_idx^ >= 0 && selected_idx^ < len(options) {
		display_text = options[selected_idx^]
	} else {
		display_text = "Select..."
	}

	// Process interaction when focused
	if focused {
		// Handle navigation when dropdown is open
		if is_open^ {
			for i := 0; i < len(ctx.input_keys); i += 1 {
				k := ctx.input_keys[i]

				#partial switch k.key {
				case .Up:
					// Move selection up
					if selected_idx^ > 0 {
						selected_idx^ -= 1
					}
					// Don't consume - let user keep navigating

				case .Down:
					// Move selection down
					if selected_idx^ < len(options) - 1 {
						selected_idx^ += 1
					}
					// Don't consume - let user keep navigating

				case .Enter:
					// Confirm selection and close
					selection_changed = true
					is_open^ = false
					unordered_remove(&ctx.input_keys, i)
					i -= 1

			case .Escape:
				// Close dropdown without changing
				is_open^ = false
				unordered_remove(&ctx.input_keys, i)
				i -= 1
			}
		}
		} else {
			// Check for activation (Enter/Space) to toggle dropdown when closed
			interaction := interact(ctx, elem_id, Rect{})
			if interaction == .Clicked {
				is_open^ = !is_open^
			}
		}
	}

	// Get theme for current state
	theme := get_select_theme(ctx.theme, is_open^, focused)

	// Render the select field
	element(
		ctx,
		Element {
			content = fmt.tprintf("%s%s", theme.prefix, display_text),
			style = theme.style,
			sizing = {.X = grow(), .Y = fixed(1)},
			focusable = true,
			id_source = lbl,
		},
	)

	// Render dropdown options if open
	if is_open^ {
		for opt, idx in options {
			is_selected := idx == selected_idx^
			prefix := "  "
			if is_selected {
				prefix = "> "
			}

			opt_style := Style{fg = Ansi.White, bg = Ansi.Default, flags = {}}
			if is_selected {
				opt_style = Style{fg = Ansi.Black, bg = Ansi.BrightCyan, flags = {.Bold}}
			}

			element(
				ctx,
				Element {
					content = fmt.tprintf("%s%s", prefix, opt),
					style = opt_style,
					sizing = {.X = grow(), .Y = fixed(1)},
					focusable = false,
					id_source = "",
				},
			)
		}
	}

	return selection_changed
}
