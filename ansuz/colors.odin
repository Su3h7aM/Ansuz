package ansuz

import "core:fmt"

// =============================================================================
// Terminal Color System
// =============================================================================
// Supports three color modes:
// - ANSI 16-color: Standard terminal colors (universal compatibility)
// - 256-color palette: Extended palette (0-255 index)
// - 24-bit RGB: True color (16M+ colors, modern terminals)

// RGB represents a 24-bit true color
RGB :: struct {
	r, g, b: u8,
}

// Color256 represents a color from the 256-color palette
// 0-15: Standard ANSI colors
// 16-231: 6×6×6 RGB cube (216 colors)
// 232-255: 24-step grayscale
Color256 :: distinct u8

// TerminalColor is the universal color type supporting all modes
TerminalColor :: union {
	Ansi, // 16-color ANSI palette
	Color256, // 256-color palette index
	RGB, // 24-bit true color
}

// Ansi represents the 16 standard ANSI terminal colors
Ansi :: enum {
	Default, // Use terminal's default color
	Black,
	Red,
	Green,
	Yellow,
	Blue,
	Magenta,
	Cyan,
	White,
	BrightBlack, // Also called "Gray"
	BrightRed,
	BrightGreen,
	BrightYellow,
	BrightBlue,
	BrightMagenta,
	BrightCyan,
	BrightWhite,
}

// =============================================================================
// Color Constructors
// =============================================================================

// rgb creates an RGB true color
rgb :: proc(r, g, b: u8) -> TerminalColor {
	return RGB{r, g, b}
}

// hex creates an RGB color from a hex value (0xRRGGBB)
hex :: proc(value: u32) -> TerminalColor {
	return RGB{r = u8((value >> 16) & 0xFF), g = u8((value >> 8) & 0xFF), b = u8(value & 0xFF)}
}

// color256 creates a 256-palette color by index
color256 :: proc(index: u8) -> TerminalColor {
	return Color256(index)
}

// grayscale creates a grayscale color (0=black, 23=white)
// Maps to 256-color palette range 232-255
grayscale :: proc(level: u8) -> TerminalColor {
	clamped := min(level, 23)
	return Color256(232 + clamped)
}

// rgb_cube creates a color from the 6×6×6 RGB cube (r,g,b each 0-5)
// Maps to 256-color palette range 16-231
rgb_cube :: proc(r, g, b: u8) -> TerminalColor {
	rc := min(r, 5)
	gc := min(g, 5)
	bc := min(b, 5)
	return Color256(16 + 36 * rc + 6 * gc + bc)
}

// =============================================================================
// Style Flags
// =============================================================================

// StyleFlag represents text attributes that can be combined
StyleFlag :: enum {
	Bold,
	Dim,
	Italic,
	Underline,
	Blink,
	Reverse, // Swap foreground and background
	Hidden,
	Strikethrough,
}

// StyleFlags is a set of style attributes
StyleFlags :: bit_set[StyleFlag]

// =============================================================================
// Style Struct
// =============================================================================

// Style combines foreground, background, and text attributes
Style :: struct {
	fg:    TerminalColor,
	bg:    TerminalColor,
	flags: StyleFlags,
}

// default_style returns a Style with terminal defaults
default_style :: proc() -> Style {
	return Style{fg = Ansi.Default, bg = Ansi.Default, flags = {}}
}

// =============================================================================
// Style API
// =============================================================================

// style creates a complete style with foreground, background and flags
// Examples:
//   style(.Default, .Default, {})          // Normal text
//   style(.Default, .Default, {.Bold})     // Bold text
//   style(.Red, .Default, {.Bold})         // Error style
//   style(.Green, .Default, {})            // Success style
style :: proc(fg, bg: TerminalColor, flags: StyleFlags) -> Style {return Style{fg, bg, flags}}

// =============================================================================
// ANSI Code Generation
// =============================================================================

// ansi_to_fg_code converts an Ansi color to its foreground ANSI code
ansi_to_fg_code :: proc(color: Ansi) -> int {
	switch color {
	case .Default:
		return 39
	case .Black:
		return 30
	case .Red:
		return 31
	case .Green:
		return 32
	case .Yellow:
		return 33
	case .Blue:
		return 34
	case .Magenta:
		return 35
	case .Cyan:
		return 36
	case .White:
		return 37
	case .BrightBlack:
		return 90
	case .BrightRed:
		return 91
	case .BrightGreen:
		return 92
	case .BrightYellow:
		return 93
	case .BrightBlue:
		return 94
	case .BrightMagenta:
		return 95
	case .BrightCyan:
		return 96
	case .BrightWhite:
		return 97
	}
	return 39
}

// ansi_to_bg_code converts an Ansi color to its background ANSI code
ansi_to_bg_code :: proc(color: Ansi) -> int {
	switch color {
	case .Default:
		return 49
	case .Black:
		return 40
	case .Red:
		return 41
	case .Green:
		return 42
	case .Yellow:
		return 43
	case .Blue:
		return 44
	case .Magenta:
		return 45
	case .Cyan:
		return 46
	case .White:
		return 47
	case .BrightBlack:
		return 100
	case .BrightRed:
		return 101
	case .BrightGreen:
		return 102
	case .BrightYellow:
		return 103
	case .BrightBlue:
		return 104
	case .BrightMagenta:
		return 105
	case .BrightCyan:
		return 106
	case .BrightWhite:
		return 107
	}
	return 49
}

// style_flag_to_ansi converts a StyleFlag to its ANSI code
style_flag_to_ansi :: proc(flag: StyleFlag) -> int {
	switch flag {
	case .Bold:
		return 1
	case .Dim:
		return 2
	case .Italic:
		return 3
	case .Underline:
		return 4
	case .Blink:
		return 5
	case .Reverse:
		return 7
	case .Hidden:
		return 8
	case .Strikethrough:
		return 9
	}
	return 0
}

// =============================================================================
// Sequence Generation
// =============================================================================

// Helper to check if a color is default
_is_default_color :: proc(color: TerminalColor) -> bool {
	if ansi, ok := color.(Ansi); ok {
		return ansi == .Default
	}
	return false
}

// generate_style_sequence creates a complete ANSI escape sequence
generate_style_sequence :: proc(fg, bg: TerminalColor, styles: StyleFlags) -> string {
	// Check if everything is default
	if _is_default_color(fg) && _is_default_color(bg) && card(styles) == 0 {
		return "\x1b[0m"
	}

	builder := fmt.tprintf("\x1b[")
	first := true

	// Add style flags
	for flag in StyleFlag {
		if flag in styles {
			if !first {
				builder = fmt.tprintf("%s;", builder)
			}
			builder = fmt.tprintf("%s%d", builder, style_flag_to_ansi(flag))
			first = false
		}
	}

	// Add foreground color
	if !_is_default_color(fg) {
		if !first {
			builder = fmt.tprintf("%s;", builder)
		}
		builder = _append_fg_color(builder, fg)
		first = false
	}

	// Add background color
	if !_is_default_color(bg) {
		if !first {
			builder = fmt.tprintf("%s;", builder)
		}
		builder = _append_bg_color(builder, bg)
		first = false
	}

	return fmt.tprintf("%sm", builder)
}

// _append_fg_color appends the foreground color sequence to builder
_append_fg_color :: proc(builder: string, color: TerminalColor) -> string {
	switch c in color {
	case Ansi:
		return fmt.tprintf("%s%d", builder, ansi_to_fg_code(c))
	case Color256:
		return fmt.tprintf("%s38;5;%d", builder, u8(c))
	case RGB:
		return fmt.tprintf("%s38;2;%d;%d;%d", builder, c.r, c.g, c.b)
	}
	return builder
}

// _append_bg_color appends the background color sequence to builder
_append_bg_color :: proc(builder: string, color: TerminalColor) -> string {
	switch c in color {
	case Ansi:
		return fmt.tprintf("%s%d", builder, ansi_to_bg_code(c))
	case Color256:
		return fmt.tprintf("%s48;5;%d", builder, u8(c))
	case RGB:
		return fmt.tprintf("%s48;2;%d;%d;%d", builder, c.r, c.g, c.b)
	}
	return builder
}

// reset_style returns the ANSI sequence to reset all styling
reset_style :: proc() -> string {
	return "\x1b[0m"
}

// to_ansi converts a Style to its ANSI escape sequence
to_ansi :: proc(style: Style) -> string {
	return generate_style_sequence(style.fg, style.bg, style.flags)
}

// =============================================================================
// Legacy Compatibility (Deprecated - will be removed)
// =============================================================================

// Color is an alias for Ansi (backward compatibility)
// Color is an alias for Ansi (backward compatibility)
// Color is an alias for Ansi (backward compatibility)
Color :: Ansi

// color_to_ansi_fg is deprecated, use ansi_to_fg_code instead
