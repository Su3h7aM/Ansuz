package ansuz

// ============================================================================
// Theme System - Centralized styling for widgets
// ============================================================================

// WidgetTheme holds styling for a widget in a specific state
WidgetTheme :: struct {
	style:  Style,
	prefix: string, // Icon/prefix for the widget (e.g., "[ ] ", "[x] ")
}

// Theme defines the complete visual appearance for all widgets
Theme :: struct {
	// Button styles
	button:                   WidgetTheme,
	button_focused:           WidgetTheme,

	// Checkbox styles
	checkbox:                 WidgetTheme,
	checkbox_checked:         WidgetTheme,
	checkbox_focused:         WidgetTheme,
	checkbox_checked_focused: WidgetTheme,

	// Container styles
	container:                Style,

	// Box styles
	box:                      BoxStyle,
	box_style:                Style,

	// Text styles
	text_primary:             Style,
	text_secondary:           Style,
	text_muted:               Style,
	text_accent:              Style,

	// Status styles
	text_success:             Style,
	text_warning:             Style,
	text_error:               Style,
}

// ============================================================================
// Default Theme
// ============================================================================

// default_theme returns the default theme
// (proc because Style contains union types which aren't compile-time constants)
default_theme_full :: proc() -> Theme {
	return Theme {
		// Buttons
		button = WidgetTheme {
			style = Style{fg = Ansi.White, bg = Ansi.Default, flags = {}},
			prefix = "[ ] ",
		},
		button_focused = WidgetTheme {
			style = Style{fg = Ansi.Black, bg = Ansi.BrightCyan, flags = {.Bold}},
			prefix = "[*] ",
		},

		// Checkboxes
		checkbox = WidgetTheme {
			style = Style{fg = Ansi.White, bg = Ansi.Default, flags = {}},
			prefix = "[ ] ",
		},
		checkbox_checked = WidgetTheme {
			style = Style{fg = Ansi.White, bg = Ansi.Default, flags = {}},
			prefix = "[x] ",
		},
		checkbox_focused = WidgetTheme {
			style = Style{fg = Ansi.Black, bg = Ansi.BrightCyan, flags = {.Bold}},
			prefix = "[ ] ",
		},
		checkbox_checked_focused = WidgetTheme {
			style = Style{fg = Ansi.Black, bg = Ansi.BrightCyan, flags = {.Bold}},
			prefix = "[x] ",
		},

		// Container
		container = Style{fg = Ansi.Default, bg = Ansi.Default, flags = {}},

		// Box
		box = .Sharp,
		box_style = Style{fg = Ansi.White, bg = Ansi.Default, flags = {}},

		// Text
		text_primary = Style{fg = Ansi.White, bg = Ansi.Default, flags = {}},
		text_secondary = Style{fg = Ansi.BrightBlack, bg = Ansi.Default, flags = {}},
		text_muted = Style{fg = Ansi.BrightBlack, bg = Ansi.Default, flags = {.Dim}},
		text_accent = Style{fg = Ansi.BrightCyan, bg = Ansi.Default, flags = {}},

		// Status
		text_success = Style{fg = Ansi.Green, bg = Ansi.Default, flags = {}},
		text_warning = Style{fg = Ansi.Yellow, bg = Ansi.Default, flags = {}},
		text_error = Style{fg = Ansi.Red, bg = Ansi.Default, flags = {.Bold}},
	}
}

// ============================================================================
// Dark Theme
// ============================================================================

// dark_theme returns a dark mode theme
dark_theme :: proc() -> Theme {
	return Theme {
		// Buttons - cyan accent on dark
		button = WidgetTheme {
			style = Style{fg = Ansi.BrightWhite, bg = Ansi.Default, flags = {}},
			prefix = "[ ] ",
		},
		button_focused = WidgetTheme {
			style = Style{fg = Ansi.Black, bg = Ansi.Cyan, flags = {.Bold}},
			prefix = "[>] ",
		},

		// Checkboxes
		checkbox = WidgetTheme {
			style = Style{fg = Ansi.BrightWhite, bg = Ansi.Default, flags = {}},
			prefix = "[ ] ",
		},
		checkbox_checked = WidgetTheme {
			style = Style{fg = Ansi.Green, bg = Ansi.Default, flags = {}},
			prefix = "[x] ",
		},
		checkbox_focused = WidgetTheme {
			style = Style{fg = Ansi.Black, bg = Ansi.Cyan, flags = {.Bold}},
			prefix = "[ ] ",
		},
		checkbox_checked_focused = WidgetTheme {
			style = Style{fg = Ansi.Black, bg = Ansi.Green, flags = {.Bold}},
			prefix = "[x] ",
		},

		// Container
		container = Style{fg = Ansi.Default, bg = Ansi.Default, flags = {}},

		// Box - rounded corners
		box = .Rounded,
		box_style = Style{fg = Ansi.BrightBlack, bg = Ansi.Default, flags = {}},

		// Text
		text_primary = Style{fg = Ansi.BrightWhite, bg = Ansi.Default, flags = {}},
		text_secondary = Style{fg = Ansi.White, bg = Ansi.Default, flags = {}},
		text_muted = Style{fg = Ansi.BrightBlack, bg = Ansi.Default, flags = {}},
		text_accent = Style{fg = Ansi.Cyan, bg = Ansi.Default, flags = {}},

		// Status
		text_success = Style{fg = Ansi.BrightGreen, bg = Ansi.Default, flags = {}},
		text_warning = Style{fg = Ansi.BrightYellow, bg = Ansi.Default, flags = {}},
		text_error = Style{fg = Ansi.BrightRed, bg = Ansi.Default, flags = {.Bold}},
	}
}

// ============================================================================
// Theme Helpers
// ============================================================================

// get_button_theme returns the appropriate button theme for the current state
get_button_theme :: proc(theme: ^Theme, focused: bool) -> WidgetTheme {
	return focused ? theme.button_focused : theme.button
}

// get_checkbox_theme returns the appropriate checkbox theme for the current state
get_checkbox_theme :: proc(theme: ^Theme, checked, focused: bool) -> WidgetTheme {
	if focused {
		return checked ? theme.checkbox_checked_focused : theme.checkbox_focused
	}
	return checked ? theme.checkbox_checked : theme.checkbox
}
