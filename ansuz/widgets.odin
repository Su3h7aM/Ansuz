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
button :: proc(ctx: ^Context, label: string) -> bool {
	id := id(ctx, label)
	register_focusable(ctx, id)

	focused := is_focused(ctx, id)

	// Create dummy rect for interaction
	interaction := interact(ctx, id, Rect{})

	// Determine style
	btn_style := style(.White, .Default, {})
	prefix := "[ ] "

	if focused {
		btn_style = style(.Black, .BrightCyan, {.Bold})
		prefix = "[*] "
	}

	// Render
	layout_text(
		ctx,
		fmt.tprintf("%s%s", prefix, label),
		btn_style,
		{sizing = {.X = grow(), .Y = fixed(1)}},
	)

	return interaction == .Clicked
}

// checkbox renders a checkbox widget
checkbox :: proc(ctx: ^Context, label: string, checked: ^bool) -> bool {
	id := id(ctx, label)
	register_focusable(ctx, id)

	focused := is_focused(ctx, id)
	interaction := interact(ctx, id, Rect{})

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
	layout_text(
		ctx,
		fmt.tprintf("%s %s", icon, label),
		chk_style,
		{sizing = {.X = grow(), .Y = fixed(1)}},
	)

	return interaction == .Clicked
}
