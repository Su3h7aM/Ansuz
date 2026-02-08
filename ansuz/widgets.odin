package ansuz

import "core:fmt"

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
	for k in ctx.input_keys {
		if k.key == .Enter {
			return .Clicked
		}
		if k.key == .Char && k.rune == ' ' {
			return .Clicked
		}
	}

	return .Hovered
}

// button renders a button widget and returns true if clicked
button :: proc(ctx: ^Context, label_text: string) -> bool {
	button_id := id(ctx, label_text)
	register_focusable(ctx, button_id)

	focused := is_focused(ctx, button_id)

	// Create dummy rect for interaction
	interaction := interact(ctx, button_id, Rect{})

	// Determine style
	btn_style := style(.White, .Default, {})
	prefix := "[ ] "

	if focused {
		btn_style = style(.Black, .BrightCyan, {.Bold})
		prefix = "[*] "
	}

	// Render
	label(ctx, fmt.tprintf("%s%s", prefix, label_text), Element{sizing = {.X = grow(), .Y = fixed(1)}, style = btn_style})

	return interaction == .Clicked
}

// checkbox renders a checkbox widget
checkbox :: proc(ctx: ^Context, label_str: string, checked: ^bool) -> bool {
	check_id := id(ctx, label_str)
	register_focusable(ctx, check_id)

	focused := is_focused(ctx, check_id)
	interaction := interact(ctx, check_id, Rect{})

	if interaction == .Clicked {
		checked^ = !checked^
	}

	// Style
	chk_style := style(.White, .Default, {})
	icon := checked^ ? "[x]" : "[ ]"

	if focused {
		chk_style = style(.Black, .BrightCyan, {.Bold})
	}

	// Render
	label(ctx, fmt.tprintf("%s %s", icon, label_str), Element{sizing = {.X = grow(), .Y = fixed(1)}, style = chk_style})

	return interaction == .Clicked
}
