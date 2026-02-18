package ansuz

import ac "../color"
import ab "../buffer"

WidgetTheme :: struct {
	style:  ac.Style,
	prefix: string,
}

Theme :: struct {
	button:                   WidgetTheme,
	button_focused:           WidgetTheme,
	checkbox:                 WidgetTheme,
	checkbox_checked:         WidgetTheme,
	checkbox_focused:         WidgetTheme,
	checkbox_checked_focused: WidgetTheme,
	input:                    WidgetTheme,
	input_focused:            WidgetTheme,
	input_placeholder:        ac.Style,
	select:                   WidgetTheme,
	select_focused:           WidgetTheme,
	select_open:              WidgetTheme,
	select_open_focused:      WidgetTheme,
	container:                ac.Style,
	box:                      ab.BoxStyle,
	box_style:                ac.Style,
	text_primary:             ac.Style,
	text_secondary:           ac.Style,
	text_muted:               ac.Style,
	text_accent:              ac.Style,
	text_success:             ac.Style,
	text_warning:             ac.Style,
	text_error:               ac.Style,
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
			style = ac.Style{fg = ac.Ansi.White, bg = ac.Ansi.Default, flags = {}},
			prefix = "[ ] ",
		},
		button_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.Black, bg = ac.Ansi.BrightCyan, flags = {.Bold}},
			prefix = "[*] ",
		},

		// Checkboxes
		checkbox = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.White, bg = ac.Ansi.Default, flags = {}},
			prefix = "[ ] ",
		},
		checkbox_checked = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.White, bg = ac.Ansi.Default, flags = {}},
			prefix = "[x] ",
		},
		checkbox_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.Black, bg = ac.Ansi.BrightCyan, flags = {.Bold}},
			prefix = "[ ] ",
		},
		checkbox_checked_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.Black, bg = ac.Ansi.BrightCyan, flags = {.Bold}},
			prefix = "[x] ",
		},

		// Input
		input = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.White, bg = ac.Ansi.Default, flags = {}},
			prefix = "",
		},
		input_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.Default, flags = {.Underline}},
			prefix = "",
		},
		input_placeholder = ac.Style{fg = ac.Ansi.BrightBlack, bg = ac.Ansi.Default, flags = {.Dim}},

		// Select
		select = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.White, bg = ac.Ansi.Default, flags = {}},
			prefix = "[v] ",
		},
		select_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.BrightCyan, flags = {.Bold}},
			prefix = "[v] ",
		},
		select_open = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.BrightCyan, flags = {.Bold}},
			prefix = "[^] ",
		},
		select_open_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.Black, bg = ac.Ansi.BrightCyan, flags = {.Bold}},
			prefix = "[^] ",
		},

		// Container
		container = ac.Style{fg = ac.Ansi.Default, bg = ac.Ansi.Default, flags = {}},

		// Box
		box = .Sharp,
		box_style = ac.Style{fg = ac.Ansi.White, bg = ac.Ansi.Default, flags = {}},

		// Text
		text_primary = ac.Style{fg = ac.Ansi.White, bg = ac.Ansi.Default, flags = {}},
		text_secondary = ac.Style{fg = ac.Ansi.BrightBlack, bg = ac.Ansi.Default, flags = {}},
		text_muted = ac.Style{fg = ac.Ansi.BrightBlack, bg = ac.Ansi.Default, flags = {.Dim}},
		text_accent = ac.Style{fg = ac.Ansi.BrightCyan, bg = ac.Ansi.Default, flags = {}},

		// Status
		text_success = ac.Style{fg = ac.Ansi.Green, bg = ac.Ansi.Default, flags = {}},
		text_warning = ac.Style{fg = ac.Ansi.Yellow, bg = ac.Ansi.Default, flags = {}},
		text_error = ac.Style{fg = ac.Ansi.Red, bg = ac.Ansi.Default, flags = {.Bold}},
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
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.Default, flags = {}},
			prefix = "[ ] ",
		},
		button_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.Black, bg = ac.Ansi.Cyan, flags = {.Bold}},
			prefix = "[>] ",
		},

		// Checkboxes
		checkbox = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.Default, flags = {}},
			prefix = "[ ] ",
		},
		checkbox_checked = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.Green, bg = ac.Ansi.Default, flags = {}},
			prefix = "[x] ",
		},
		checkbox_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.Black, bg = ac.Ansi.Cyan, flags = {.Bold}},
			prefix = "[ ] ",
		},
		checkbox_checked_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.Black, bg = ac.Ansi.Green, flags = {.Bold}},
			prefix = "[x] ",
		},

		// Input
		input = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.Default, flags = {}},
			prefix = "",
		},
		input_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.Default, flags = {.Underline}},
			prefix = "",
		},
		input_placeholder = ac.Style{fg = ac.Ansi.BrightBlack, bg = ac.Ansi.Default, flags = {.Dim}},

		// Select
		select = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.Default, flags = {}},
			prefix = "[v] ",
		},
		select_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.Cyan, flags = {.Bold}},
			prefix = "[v] ",
		},
		select_open = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.Cyan, flags = {.Bold}},
			prefix = "[^] ",
		},
		select_open_focused = WidgetTheme {
			style = ac.Style{fg = ac.Ansi.Black, bg = ac.Ansi.Cyan, flags = {.Bold}},
			prefix = "[^] ",
		},

		// Container
		container = ac.Style{fg = ac.Ansi.Default, bg = ac.Ansi.Default, flags = {}},

		// Box - rounded corners
		box = .Rounded,
		box_style = ac.Style{fg = ac.Ansi.BrightBlack, bg = ac.Ansi.Default, flags = {}},

		// Text
		text_primary = ac.Style{fg = ac.Ansi.BrightWhite, bg = ac.Ansi.Default, flags = {}},
		text_secondary = ac.Style{fg = ac.Ansi.White, bg = ac.Ansi.Default, flags = {}},
		text_muted = ac.Style{fg = ac.Ansi.BrightBlack, bg = ac.Ansi.Default, flags = {}},
		text_accent = ac.Style{fg = ac.Ansi.Cyan, bg = ac.Ansi.Default, flags = {}},

		// Status
		text_success = ac.Style{fg = ac.Ansi.BrightGreen, bg = ac.Ansi.Default, flags = {}},
		text_warning = ac.Style{fg = ac.Ansi.BrightYellow, bg = ac.Ansi.Default, flags = {}},
		text_error = ac.Style{fg = ac.Ansi.BrightRed, bg = ac.Ansi.Default, flags = {.Bold}},
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

// get_input_theme returns the appropriate input theme for the current state
get_input_theme :: proc(theme: ^Theme, focused: bool) -> WidgetTheme {
	return focused ? theme.input_focused : theme.input
}

// get_select_theme returns the appropriate select theme for the current state
get_select_theme :: proc(theme: ^Theme, is_open, focused: bool) -> WidgetTheme {
	if is_open {
		return focused ? theme.select_open_focused : theme.select_open
	}
	return focused ? theme.select_focused : theme.select
}
