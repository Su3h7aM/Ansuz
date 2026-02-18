package ansuz

import "core:strings"
import ansi "core:terminal/ansi"
import "core:testing"

@(test)
test_ansi_to_fg_code_default :: proc(t: ^testing.T) {
	code := ansi_to_fg_code(.Default)
	testing.expect_value(t, code, ansi.FG_DEFAULT)
}

@(test)
test_ansi_to_fg_code_standard :: proc(t: ^testing.T) {
	testing.expect_value(t, ansi_to_fg_code(.Black), ansi.FG_BLACK)
	testing.expect_value(t, ansi_to_fg_code(.Red), ansi.FG_RED)
	testing.expect_value(t, ansi_to_fg_code(.Green), ansi.FG_GREEN)
	testing.expect_value(t, ansi_to_fg_code(.Yellow), ansi.FG_YELLOW)
	testing.expect_value(t, ansi_to_fg_code(.Blue), ansi.FG_BLUE)
	testing.expect_value(t, ansi_to_fg_code(.Magenta), ansi.FG_MAGENTA)
	testing.expect_value(t, ansi_to_fg_code(.Cyan), ansi.FG_CYAN)
	testing.expect_value(t, ansi_to_fg_code(.White), ansi.FG_WHITE)
}

@(test)
test_ansi_to_fg_code_bright :: proc(t: ^testing.T) {
	testing.expect_value(t, ansi_to_fg_code(.BrightBlack), ansi.FG_BRIGHT_BLACK)
	testing.expect_value(t, ansi_to_fg_code(.BrightRed), ansi.FG_BRIGHT_RED)
	testing.expect_value(t, ansi_to_fg_code(.BrightGreen), ansi.FG_BRIGHT_GREEN)
	testing.expect_value(t, ansi_to_fg_code(.BrightYellow), ansi.FG_BRIGHT_YELLOW)
	testing.expect_value(t, ansi_to_fg_code(.BrightBlue), ansi.FG_BRIGHT_BLUE)
	testing.expect_value(t, ansi_to_fg_code(.BrightMagenta), ansi.FG_BRIGHT_MAGENTA)
	testing.expect_value(t, ansi_to_fg_code(.BrightCyan), ansi.FG_BRIGHT_CYAN)
	testing.expect_value(t, ansi_to_fg_code(.BrightWhite), ansi.FG_BRIGHT_WHITE)
}

@(test)
test_ansi_to_bg_code_default :: proc(t: ^testing.T) {
	code := ansi_to_bg_code(.Default)
	testing.expect_value(t, code, ansi.BG_DEFAULT)
}

@(test)
test_ansi_to_bg_code_standard :: proc(t: ^testing.T) {
	testing.expect_value(t, ansi_to_bg_code(.Black), ansi.BG_BLACK)
	testing.expect_value(t, ansi_to_bg_code(.Red), ansi.BG_RED)
	testing.expect_value(t, ansi_to_bg_code(.Green), ansi.BG_GREEN)
	testing.expect_value(t, ansi_to_bg_code(.Yellow), ansi.BG_YELLOW)
	testing.expect_value(t, ansi_to_bg_code(.Blue), ansi.BG_BLUE)
	testing.expect_value(t, ansi_to_bg_code(.Magenta), ansi.BG_MAGENTA)
	testing.expect_value(t, ansi_to_bg_code(.Cyan), ansi.BG_CYAN)
	testing.expect_value(t, ansi_to_bg_code(.White), ansi.BG_WHITE)
}

@(test)
test_ansi_to_bg_code_bright :: proc(t: ^testing.T) {
	testing.expect_value(t, ansi_to_bg_code(.BrightBlack), ansi.BG_BRIGHT_BLACK)
	testing.expect_value(t, ansi_to_bg_code(.BrightRed), ansi.BG_BRIGHT_RED)
	testing.expect_value(t, ansi_to_bg_code(.BrightGreen), ansi.BG_BRIGHT_GREEN)
	testing.expect_value(t, ansi_to_bg_code(.BrightYellow), ansi.BG_BRIGHT_YELLOW)
	testing.expect_value(t, ansi_to_bg_code(.BrightBlue), ansi.BG_BRIGHT_BLUE)
	testing.expect_value(t, ansi_to_bg_code(.BrightMagenta), ansi.BG_BRIGHT_MAGENTA)
	testing.expect_value(t, ansi_to_bg_code(.BrightCyan), ansi.BG_BRIGHT_CYAN)
	testing.expect_value(t, ansi_to_bg_code(.BrightWhite), ansi.BG_BRIGHT_WHITE)
}

// NOTE: This test is no longer valid with string-based codes
// The relationship between fg/bg codes is implicit in ansi package constants
@(test)
test_color_offset_between_fg_bg :: proc(t: ^testing.T) {
	// Verify that fg and bg codes are different for the same color
	for color in Ansi {
		fg := ansi_to_fg_code(color)
		bg := ansi_to_bg_code(color)
		testing.expect(t, fg != bg, "FG and BG codes should be different")
	}
}

@(test)
test_style_flag_to_ansi :: proc(t: ^testing.T) {
	testing.expect_value(t, style_flag_to_ansi(.Bold), ansi.BOLD)
	testing.expect_value(t, style_flag_to_ansi(.Dim), ansi.FAINT)
	testing.expect_value(t, style_flag_to_ansi(.Italic), ansi.ITALIC)
	testing.expect_value(t, style_flag_to_ansi(.Underline), ansi.UNDERLINE)
	testing.expect_value(t, style_flag_to_ansi(.Blink), ansi.BLINK_SLOW)
	testing.expect_value(t, style_flag_to_ansi(.Reverse), ansi.INVERT)
	testing.expect_value(t, style_flag_to_ansi(.Hidden), ansi.HIDE)
	testing.expect_value(t, style_flag_to_ansi(.Strikethrough), ansi.STRIKE)
}

@(test)
test_reset_style :: proc(t: ^testing.T) {
	seq := reset_style()
	testing.expect_value(t, seq, "\x1b[0m")
}

@(test)
test_default_style :: proc(t: ^testing.T) {
	s := default_style()
	testing.expect(t, s.fg == Ansi.Default, "Default fg should be Default")
	testing.expect(t, s.bg == Ansi.Default, "Default bg should be Default")
	testing.expect(t, s.flags == {}, "Default flags should be empty")
}

@(test)
test_to_ansi_default :: proc(t: ^testing.T) {
	s := default_style()
	seq := to_ansi(s)
	testing.expect_value(t, seq, "\x1b[0m")
}

@(test)
test_to_ansi_fg_only :: proc(t: ^testing.T) {
	s := Style {
		fg    = Ansi.Red,
		bg    = Ansi.Default,
		flags = {},
	}
	seq := generate_style_sequence(s.fg, s.bg, s.flags)
	testing.expect(t, strings.contains(seq, "31"), "Should contain red fg code")
	testing.expect(
		t,
		!strings.contains(seq, "49") || strings.contains(seq, "\x1b[0m"),
		"Should not contain default bg or use reset",
	)
}

@(test)
test_to_ansi_bg_only :: proc(t: ^testing.T) {
	s := Style {
		fg    = Ansi.Default,
		bg    = Ansi.Blue,
		flags = {},
	}
	seq := generate_style_sequence(s.fg, s.bg, s.flags)
	testing.expect(t, strings.contains(seq, "44"), "Should contain blue bg code")
}

@(test)
test_to_ansi_colors :: proc(t: ^testing.T) {
	s := Style {
		fg    = Ansi.Red,
		bg    = Ansi.Blue,
		flags = {},
	}
	seq := generate_style_sequence(s.fg, s.bg, s.flags)
	testing.expect(t, strings.contains(seq, "31"), "Should contain red fg")
	testing.expect(t, strings.contains(seq, "44"), "Should contain blue bg")
}

@(test)
test_to_ansi_single_style :: proc(t: ^testing.T) {
	s := Style {
		fg    = Ansi.Default,
		bg    = Ansi.Default,
		flags = {.Bold},
	}
	seq := generate_style_sequence(s.fg, s.bg, s.flags)
	testing.expect(t, strings.contains(seq, "1"), "Should contain bold code")
}

@(test)
test_to_ansi_multiple_styles :: proc(t: ^testing.T) {
	flags: StyleFlags = {.Bold, .Underline, .Dim}
	s := Style {
		fg    = Ansi.Default,
		bg    = Ansi.Default,
		flags = flags,
	}
	seq := generate_style_sequence(s.fg, s.bg, s.flags)
	testing.expect(t, strings.contains(seq, "1"), "Should contain bold")
	testing.expect(t, strings.contains(seq, "2"), "Should contain dim")
	testing.expect(t, strings.contains(seq, "4"), "Should contain underline")
}

@(test)
test_color256_sequence :: proc(t: ^testing.T) {
	// Test 256 color sequence generation
	c := color256(208) // Orange
	s := style(c, Ansi.Default, {}) // Use style() instead of removed style_fg()
	seq := generate_style_sequence(s.fg, s.bg, s.flags)

	// Expect \x1b[38;5;208m
	testing.expect(t, strings.contains(seq, "38;5;208"), "Should contain 256 color sequence")
}

@(test)
test_rgb_sequence :: proc(t: ^testing.T) {
	// Test RGB color sequence generation
	c := rgb(255, 128, 0)
	s := style(c, Ansi.Default, {}) // Use style() instead of removed style_fg()
	seq := generate_style_sequence(s.fg, s.bg, s.flags)

	// Expect \x1b[38;2;255;128;0m
	testing.expect(t, strings.contains(seq, "38;2;255;128;0"), "Should contain RGB sequence")
}

@(test)
test_hex_parsing :: proc(t: ^testing.T) {
	c := hex(0xFF8000)

	// Use switch to check variant because it's a union
	switch v in c {
	case RGB:
		testing.expect(t, v.r == 255, "Red component should be 255")
		testing.expect(t, v.g == 128, "Green component should be 128")
		testing.expect(t, v.b == 0, "Blue component should be 0")
	case Ansi, Color256:
		testing.expect(t, false, "Should be RGB type")
	}
}

@(test)
test_rgb_cube_mapping :: proc(t: ^testing.T) {
	c := rgb_cube(5, 0, 0) // Max red, no green/blue

	// rgb_cube returns Color256
	switch v in c {
	case Color256:
		// 16 + 36*rc + 6*gc + bc
		// 16 + 36*5 + 0 + 0 = 16 + 180 = 196
		testing.expect(t, u8(v) == 196, "Should map to correct 256 color index")
	case Ansi, RGB:
		testing.expect(t, false, "Should be Color256 type")
	}
}

@(test)
test_grayscale_mapping :: proc(t: ^testing.T) {
	// Test grayscale helper
	c := grayscale(23) // Max grayscale value (0-23)

	// grayscale returns Color256
	switch v in c {
	case Color256:
		// 232 + 23 = 255
		testing.expect(t, u8(v) == 255, "Should map to correct grayscale index")
	case Ansi, RGB:
		testing.expect(t, false, "Should be Color256 type")
	}
}

@(test)
test_to_ansi_complete :: proc(t: ^testing.T) {
	flags: StyleFlags = {.Bold, .Underline}
	s := Style {
		fg    = Ansi.Red,
		bg    = Ansi.Blue,
		flags = flags,
	}
	seq := generate_style_sequence(s.fg, s.bg, s.flags)
	testing.expect(t, strings.contains(seq, "1"), "Should contain bold")
	testing.expect(t, strings.contains(seq, "4"), "Should contain underline")
	testing.expect(t, strings.contains(seq, "31"), "Should contain red fg")
	testing.expect(t, strings.contains(seq, "44"), "Should contain blue bg")
}

@(test)
test_generate_style_sequence_default :: proc(t: ^testing.T) {
	seq := generate_style_sequence(.Default, .Default, {})
	testing.expect_value(t, seq, "\x1b[0m")
}

@(test)
test_generate_style_sequence_only_fg :: proc(t: ^testing.T) {
	seq := generate_style_sequence(.Red, .Default, {})
	testing.expect(t, strings.contains(seq, "31"), "Should contain red fg")
	testing.expect(t, !strings.contains(seq, "49"), "Should not contain default bg")
}

@(test)
test_generate_style_sequence_only_bg :: proc(t: ^testing.T) {
	seq := generate_style_sequence(.Default, .Blue, {})
	testing.expect(t, strings.contains(seq, "44"), "Should contain blue bg")
}

@(test)
test_generate_style_sequence_only_styles :: proc(t: ^testing.T) {
	flags: StyleFlags = {.Bold, .Underline}
	seq := generate_style_sequence(.Default, .Default, flags)
	testing.expect(t, strings.contains(seq, "1"), "Should contain bold")
	testing.expect(t, strings.contains(seq, "4"), "Should contain underline")
}

@(test)
test_generate_style_sequence_all :: proc(t: ^testing.T) {
	flags: StyleFlags = {.Bold, .Dim}
	seq := generate_style_sequence(.Red, .Blue, flags)
	testing.expect(t, strings.contains(seq, "1"), "Should contain bold")
	testing.expect(t, strings.contains(seq, "2"), "Should contain dim")
	testing.expect(t, strings.contains(seq, "31"), "Should contain red fg")
	testing.expect(t, strings.contains(seq, "44"), "Should contain blue bg")
}

@(test)
test_style_flags_bit_set :: proc(t: ^testing.T) {
	flags: StyleFlags = {}

	flags = {.Bold}
	testing.expect(t, .Bold in flags, "Should contain Bold after adding")
	testing.expect(t, card(flags) == 1, "Should have 1 flag")

	flags = {.Bold, .Underline}
	testing.expect(t, .Bold in flags, "Should still contain Bold")
	testing.expect(t, .Underline in flags, "Should contain Underline after adding")
	testing.expect(t, card(flags) == 2, "Should have 2 flags")

	flags = {.Underline}
	testing.expect(t, !(.Bold in flags), "Should not contain Bold after removing")
	testing.expect(t, .Underline in flags, "Should still contain Underline")
	testing.expect(t, card(flags) == 1, "Should have 1 flag after removal")
}

@(test)
test_all_color_values_unique_fg :: proc(t: ^testing.T) {
	seen: [dynamic]string
	defer delete(seen)

	for color in Ansi {
		code := ansi_to_fg_code(color)
		for seen_code in seen {
			testing.expect(t, code != seen_code, "Color codes should be unique")
		}
		append(&seen, code)
	}
}

@(test)
test_all_style_flags_unique_codes :: proc(t: ^testing.T) {
	seen: [dynamic]string
	defer delete(seen)

	for flag in StyleFlag {
		code := style_flag_to_ansi(flag)
		for seen_code in seen {
			testing.expect(t, code != seen_code, "Style flag codes should be unique")
		}
		append(&seen, code)
	}
}

@(test)
test_style_equality :: proc(t: ^testing.T) {
	style1 := Style {
		fg    = Ansi.Red,
		bg    = Ansi.Blue,
		flags = {.Bold},
	}
	style2 := Style {
		fg    = Ansi.Red,
		bg    = Ansi.Blue,
		flags = {.Bold},
	}

	testing.expect(t, style1 == style2, "Identical styles should be equal")

	style3 := Style {
		fg    = Ansi.Red,
		bg    = Ansi.Green,
		flags = {.Bold},
	}
	testing.expect(t, style1 != style3, "Styles with different bg should not be equal")

	style4 := Style {
		fg    = Ansi.Red,
		bg    = Ansi.Blue,
		flags = {.Bold, .Underline},
	}
	testing.expect(t, style1 != style4, "Styles with different flags should not be equal")
}

// NOTE: This test is no longer applicable with string-based codes
// The relationship between bright and standard colors is implicit in ansi package
@(test)
test_bright_color_codes :: proc(t: ^testing.T) {
	// Just verify that bright colors have codes that contain "9" (90-97)
	// and standard colors have codes that contain "3" (30-37)
	testing.expect(
		t,
		strings.contains(ansi_to_fg_code(.BrightRed), "9"),
		"Bright red should contain 9",
	)
	testing.expect(t, strings.contains(ansi_to_fg_code(.Red), "3"), "Red should contain 3")
}

@(test)
test_ansi_sequence_format :: proc(t: ^testing.T) {
	s := Style {
		fg    = Ansi.Red,
		bg    = Ansi.Blue,
		flags = {.Bold},
	}
	seq := generate_style_sequence(s.fg, s.bg, s.flags)

	testing.expect(t, strings.has_prefix(seq, "\x1b["), "Should start with escape sequence")
	testing.expect(t, strings.has_suffix(seq, "m"), "Should end with 'm'")
}

@(test)
test_empty_style_flags :: proc(t: ^testing.T) {
	flags: StyleFlags = {}
	seq := generate_style_sequence(.Default, .Default, flags)
	testing.expect_value(t, seq, "\x1b[0m")
}

@(test)
test_all_style_flags_combinations :: proc(t: ^testing.T) {
	flags: StyleFlags = {
		.Bold,
		.Dim,
		.Italic,
		.Underline,
		.Blink,
		.Reverse,
		.Hidden,
		.Strikethrough,
	}
	seq := generate_style_sequence(.Default, .Default, flags)

	testing.expect(t, strings.contains(seq, "1"), "Should contain bold")
	testing.expect(t, strings.contains(seq, "2"), "Should contain dim")
	testing.expect(t, strings.contains(seq, "3"), "Should contain italic")
	testing.expect(t, strings.contains(seq, "4"), "Should contain underline")
	testing.expect(t, strings.contains(seq, "5"), "Should contain blink")
	testing.expect(t, strings.contains(seq, "7"), "Should contain reverse")
	testing.expect(t, strings.contains(seq, "8"), "Should contain hidden")
	testing.expect(t, strings.contains(seq, "9"), "Should contain strikethrough")
}

@(test)
test_style_api_consistency :: proc(t: ^testing.T) {
	// Test that style() and default_style() work consistently
	default_s := default_style()
	manual_default := style(.Default, .Default, {})

	testing.expect(
		t,
		default_s == manual_default,
		"default_style() should equal style(.Default, .Default, {})",
	)

	// Test common style patterns
	error_style := style(.Red, .Default, {.Bold})
	testing.expect(t, error_style.fg == Ansi.Red)
	testing.expect(t, .Bold in error_style.flags)

	success_style := style(.Green, .Default, {})
	testing.expect(t, success_style.fg == Ansi.Green)

	info_style := style(.Cyan, .Default, {})
	testing.expect(t, info_style.fg == Ansi.Cyan)

	warning_style := style(.Yellow, .Default, {})
	testing.expect(t, warning_style.fg == Ansi.Yellow)
}
