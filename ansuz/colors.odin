package ansuz

import "core:fmt"
import ansi "core:terminal/ansi"

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

// ansi_to_fg_code converts an Ansi color to its foreground ANSI code string
ansi_to_fg_code :: proc(color: Ansi) -> string {
	switch color {
	case .Default:
		return ansi.FG_DEFAULT
	case .Black:
		return ansi.FG_BLACK
	case .Red:
		return ansi.FG_RED
	case .Green:
		return ansi.FG_GREEN
	case .Yellow:
		return ansi.FG_YELLOW
	case .Blue:
		return ansi.FG_BLUE
	case .Magenta:
		return ansi.FG_MAGENTA
	case .Cyan:
		return ansi.FG_CYAN
	case .White:
		return ansi.FG_WHITE
	case .BrightBlack:
		return ansi.FG_BRIGHT_BLACK
	case .BrightRed:
		return ansi.FG_BRIGHT_RED
	case .BrightGreen:
		return ansi.FG_BRIGHT_GREEN
	case .BrightYellow:
		return ansi.FG_BRIGHT_YELLOW
	case .BrightBlue:
		return ansi.FG_BRIGHT_BLUE
	case .BrightMagenta:
		return ansi.FG_BRIGHT_MAGENTA
	case .BrightCyan:
		return ansi.FG_BRIGHT_CYAN
	case .BrightWhite:
		return ansi.FG_BRIGHT_WHITE
	}
	return ansi.FG_DEFAULT
}

// ansi_to_bg_code converts an Ansi color to its background ANSI code string
ansi_to_bg_code :: proc(color: Ansi) -> string {
	switch color {
	case .Default:
		return ansi.BG_DEFAULT
	case .Black:
		return ansi.BG_BLACK
	case .Red:
		return ansi.BG_RED
	case .Green:
		return ansi.BG_GREEN
	case .Yellow:
		return ansi.BG_YELLOW
	case .Blue:
		return ansi.BG_BLUE
	case .Magenta:
		return ansi.BG_MAGENTA
	case .Cyan:
		return ansi.BG_CYAN
	case .White:
		return ansi.BG_WHITE
	case .BrightBlack:
		return ansi.BG_BRIGHT_BLACK
	case .BrightRed:
		return ansi.BG_BRIGHT_RED
	case .BrightGreen:
		return ansi.BG_BRIGHT_GREEN
	case .BrightYellow:
		return ansi.BG_BRIGHT_YELLOW
	case .BrightBlue:
		return ansi.BG_BRIGHT_BLUE
	case .BrightMagenta:
		return ansi.BG_BRIGHT_MAGENTA
	case .BrightCyan:
		return ansi.BG_BRIGHT_CYAN
	case .BrightWhite:
		return ansi.BG_BRIGHT_WHITE
	}
	return ansi.BG_DEFAULT
}

// style_flag_to_ansi converts a StyleFlag to its ANSI code string
style_flag_to_ansi :: proc(flag: StyleFlag) -> string {
	switch flag {
	case .Bold:
		return ansi.BOLD
	case .Dim:
		return ansi.FAINT
	case .Italic:
		return ansi.ITALIC
	case .Underline:
		return ansi.UNDERLINE
	case .Blink:
		return ansi.BLINK_SLOW
	case .Reverse:
		return ansi.INVERT
	case .Hidden:
		return ansi.HIDE
	case .Strikethrough:
		return ansi.STRIKE
	}
	return ansi.RESET
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
		return ansi.CSI + ansi.RESET + ansi.SGR
	}

	builder := fmt.tprintf("%s", ansi.CSI)
	first := true

	// Add style flags
	for flag in StyleFlag {
		if flag in styles {
			if !first {
				builder = fmt.tprintf("%s;", builder)
			}
			builder = fmt.tprintf("%s%s", builder, style_flag_to_ansi(flag))
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

	return fmt.tprintf("%s%s", builder, ansi.SGR)
}

// _append_fg_color appends the foreground color sequence to builder
_append_fg_color :: proc(builder: string, color: TerminalColor) -> string {
	switch c in color {
	case Ansi:
		return fmt.tprintf("%s%s", builder, ansi_to_fg_code(c))
	case Color256:
		return fmt.tprintf("%s%s;%d", builder, ansi.FG_COLOR_8_BIT, u8(c))
	case RGB:
		return fmt.tprintf("%s%s;%d;%d;%d", builder, ansi.FG_COLOR_24_BIT, c.r, c.g, c.b)
	}
	return builder
}

// _append_bg_color appends the background color sequence to builder
_append_bg_color :: proc(builder: string, color: TerminalColor) -> string {
	switch c in color {
	case Ansi:
		return fmt.tprintf("%s%s", builder, ansi_to_bg_code(c))
	case Color256:
		return fmt.tprintf("%s%s;%d", builder, ansi.BG_COLOR_8_BIT, u8(c))
	case RGB:
		return fmt.tprintf("%s%s;%d;%d;%d", builder, ansi.BG_COLOR_24_BIT, c.r, c.g, c.b)
	}
	return builder
}

// reset_style returns the ANSI sequence to reset all styling
reset_style :: proc() -> string {
	return ansi.CSI + ansi.RESET + ansi.SGR
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
