package ansuz

import "core:testing"
import "core:strings"

@(test)
test_color_to_ansi_fg_default :: proc(t: ^testing.T) {
    code := color_to_ansi_fg(.Default)
    testing.expect_value(t, code, 39)
}

@(test)
test_color_to_ansi_fg_standard :: proc(t: ^testing.T) {
    testing.expect_value(t, color_to_ansi_fg(.Black), 30)
    testing.expect_value(t, color_to_ansi_fg(.Red), 31)
    testing.expect_value(t, color_to_ansi_fg(.Green), 32)
    testing.expect_value(t, color_to_ansi_fg(.Yellow), 33)
    testing.expect_value(t, color_to_ansi_fg(.Blue), 34)
    testing.expect_value(t, color_to_ansi_fg(.Magenta), 35)
    testing.expect_value(t, color_to_ansi_fg(.Cyan), 36)
    testing.expect_value(t, color_to_ansi_fg(.White), 37)
}

@(test)
test_color_to_ansi_fg_bright :: proc(t: ^testing.T) {
    testing.expect_value(t, color_to_ansi_fg(.BrightBlack), 90)
    testing.expect_value(t, color_to_ansi_fg(.BrightRed), 91)
    testing.expect_value(t, color_to_ansi_fg(.BrightGreen), 92)
    testing.expect_value(t, color_to_ansi_fg(.BrightYellow), 93)
    testing.expect_value(t, color_to_ansi_fg(.BrightBlue), 94)
    testing.expect_value(t, color_to_ansi_fg(.BrightMagenta), 95)
    testing.expect_value(t, color_to_ansi_fg(.BrightCyan), 96)
    testing.expect_value(t, color_to_ansi_fg(.BrightWhite), 97)
}

@(test)
test_color_to_ansi_bg_default :: proc(t: ^testing.T) {
    code := color_to_ansi_bg(.Default)
    testing.expect_value(t, code, 49)
}

@(test)
test_color_to_ansi_bg_standard :: proc(t: ^testing.T) {
    testing.expect_value(t, color_to_ansi_bg(.Black), 40)
    testing.expect_value(t, color_to_ansi_bg(.Red), 41)
    testing.expect_value(t, color_to_ansi_bg(.Green), 42)
    testing.expect_value(t, color_to_ansi_bg(.Yellow), 43)
    testing.expect_value(t, color_to_ansi_bg(.Blue), 44)
    testing.expect_value(t, color_to_ansi_bg(.Magenta), 45)
    testing.expect_value(t, color_to_ansi_bg(.Cyan), 46)
    testing.expect_value(t, color_to_ansi_bg(.White), 47)
}

@(test)
test_color_to_ansi_bg_bright :: proc(t: ^testing.T) {
    testing.expect_value(t, color_to_ansi_bg(.BrightBlack), 100)
    testing.expect_value(t, color_to_ansi_bg(.BrightRed), 101)
    testing.expect_value(t, color_to_ansi_bg(.BrightGreen), 102)
    testing.expect_value(t, color_to_ansi_bg(.BrightYellow), 103)
    testing.expect_value(t, color_to_ansi_bg(.BrightBlue), 104)
    testing.expect_value(t, color_to_ansi_bg(.BrightMagenta), 105)
    testing.expect_value(t, color_to_ansi_bg(.BrightCyan), 106)
    testing.expect_value(t, color_to_ansi_bg(.BrightWhite), 107)
}

@(test)
test_color_offset_between_fg_bg :: proc(t: ^testing.T) {
    for color in Color {
        if color == .Default do continue
        fg := color_to_ansi_fg(color)
        bg := color_to_ansi_bg(color)
        testing.expect_value(t, bg - fg, 10)
    }
}

@(test)
test_style_flag_to_ansi :: proc(t: ^testing.T) {
    testing.expect_value(t, style_flag_to_ansi(.Bold), 1)
    testing.expect_value(t, style_flag_to_ansi(.Dim), 2)
    testing.expect_value(t, style_flag_to_ansi(.Italic), 3)
    testing.expect_value(t, style_flag_to_ansi(.Underline), 4)
    testing.expect_value(t, style_flag_to_ansi(.Blink), 5)
    testing.expect_value(t, style_flag_to_ansi(.Reverse), 7)
    testing.expect_value(t, style_flag_to_ansi(.Hidden), 8)
    testing.expect_value(t, style_flag_to_ansi(.Strikethrough), 9)
}

@(test)
test_reset_style :: proc(t: ^testing.T) {
    seq := reset_style()
    testing.expect_value(t, seq, "[0m")
}

@(test)
test_default_style :: proc(t: ^testing.T) {
    style := default_style()
    testing.expect(t, style.fg_color == .Default, "Default fg should be Default")
    testing.expect(t, style.bg_color == .Default, "Default bg should be Default")
    testing.expect(t, style.flags == {}, "Default flags should be empty")
}

@(test)
test_to_ansi_default :: proc(t: ^testing.T) {
    style := default_style()
    seq := to_ansi(style)
    testing.expect_value(t, seq, "[0m")
}

@(test)
test_to_ansi_fg_only :: proc(t: ^testing.T) {
    style := Style{fg_color = .Red, bg_color = .Default, flags = {}}
    seq := to_ansi(style)
    testing.expect(t, strings.contains(seq, "31"), "Should contain red fg code")
    testing.expect(t, !strings.contains(seq, "49") || strings.contains(seq, "\x1b[0m"), 
                "Should not contain default bg or use reset")
}

@(test)
test_to_ansi_bg_only :: proc(t: ^testing.T) {
    style := Style{fg_color = .Default, bg_color = .Blue, flags = {}}
    seq := to_ansi(style)
    testing.expect(t, strings.contains(seq, "44"), "Should contain blue bg code")
}

@(test)
test_to_ansi_colors :: proc(t: ^testing.T) {
    style := Style{fg_color = .Red, bg_color = .Blue, flags = {}}
    seq := to_ansi(style)
    testing.expect(t, strings.contains(seq, "31"), "Should contain red fg")
    testing.expect(t, strings.contains(seq, "44"), "Should contain blue bg")
}

@(test)
test_to_ansi_single_style :: proc(t: ^testing.T) {
    style := Style{fg_color = .Default, bg_color = .Default, flags = {.Bold}}
    seq := to_ansi(style)
    testing.expect(t, strings.contains(seq, "1"), "Should contain bold code")
}

@(test)
test_to_ansi_multiple_styles :: proc(t: ^testing.T) {
    flags: StyleFlags = {.Bold, .Underline, .Dim}
    style := Style{fg_color = .Default, bg_color = .Default, flags = flags}
    seq := to_ansi(style)
    testing.expect(t, strings.contains(seq, "1"), "Should contain bold")
    testing.expect(t, strings.contains(seq, "2"), "Should contain dim")
    testing.expect(t, strings.contains(seq, "4"), "Should contain underline")
}

@(test)
test_to_ansi_complete :: proc(t: ^testing.T) {
    flags: StyleFlags = {.Bold, .Underline}
    style := Style{fg_color = .Red, bg_color = .Blue, flags = flags}
    seq := to_ansi(style)
    testing.expect(t, strings.contains(seq, "1"), "Should contain bold")
    testing.expect(t, strings.contains(seq, "4"), "Should contain underline")
    testing.expect(t, strings.contains(seq, "31"), "Should contain red fg")
    testing.expect(t, strings.contains(seq, "44"), "Should contain blue bg")
}

@(test)
test_generate_style_sequence_default :: proc(t: ^testing.T) {
    seq := generate_style_sequence(.Default, .Default, {})
    testing.expect_value(t, seq, "[0m")
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

    flags = { .Bold }
    testing.expect(t, .Bold in flags, "Should contain Bold after adding")
    testing.expect(t, card(flags) == 1, "Should have 1 flag")

    flags = { .Bold, .Underline }
    testing.expect(t, .Bold in flags, "Should still contain Bold")
    testing.expect(t, .Underline in flags, "Should contain Underline after adding")
    testing.expect(t, card(flags) == 2, "Should have 2 flags")

    flags = { .Underline }
    testing.expect(t, !(.Bold in flags), "Should not contain Bold after removing")
    testing.expect(t, .Underline in flags, "Should still contain Underline")
    testing.expect(t, card(flags) == 1, "Should have 1 flag after removal")
}

@(test)
test_all_color_values_unique_fg :: proc(t: ^testing.T) {
    seen: [dynamic]int
    defer delete(seen)
    
    for color in Color {
        code := color_to_ansi_fg(color)
        for seen_code in seen {
            testing.expect(t, code != seen_code, "Color codes should be unique")
        }
        append(&seen, code)
    }
}

@(test)
test_all_style_flags_unique_codes :: proc(t: ^testing.T) {
    seen: [dynamic]int
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
    style1 := Style{fg_color = .Red, bg_color = .Blue, flags = {.Bold}}
    style2 := Style{fg_color = .Red, bg_color = .Blue, flags = {.Bold}}
    
    testing.expect(t, style1 == style2, "Identical styles should be equal")
    
    style3 := Style{fg_color = .Red, bg_color = .Green, flags = {.Bold}}
    testing.expect(t, style1 != style3, "Styles with different bg should not be equal")
    
    style4 := Style{fg_color = .Red, bg_color = .Blue, flags = {.Bold, .Underline}}
    testing.expect(t, style1 != style4, "Styles with different flags should not be equal")
}

@(test)
test_bright_color_codes :: proc(t: ^testing.T) {
    bright_fg: [8]int
    bright_fg[0] = color_to_ansi_fg(.BrightBlack)
    bright_fg[1] = color_to_ansi_fg(.BrightRed)
    bright_fg[2] = color_to_ansi_fg(.BrightGreen)
    bright_fg[3] = color_to_ansi_fg(.BrightYellow)
    bright_fg[4] = color_to_ansi_fg(.BrightBlue)
    bright_fg[5] = color_to_ansi_fg(.BrightMagenta)
    bright_fg[6] = color_to_ansi_fg(.BrightCyan)
    bright_fg[7] = color_to_ansi_fg(.BrightWhite)
    
    standard_fg: [8]int
    standard_fg[0] = color_to_ansi_fg(.Black)
    standard_fg[1] = color_to_ansi_fg(.Red)
    standard_fg[2] = color_to_ansi_fg(.Green)
    standard_fg[3] = color_to_ansi_fg(.Yellow)
    standard_fg[4] = color_to_ansi_fg(.Blue)
    standard_fg[5] = color_to_ansi_fg(.Magenta)
    standard_fg[6] = color_to_ansi_fg(.Cyan)
    standard_fg[7] = color_to_ansi_fg(.White)
    
    for i in 0 ..< 8 {
        testing.expect_value(t, bright_fg[i], standard_fg[i] + 60)
    }
}

@(test)
test_ansi_sequence_format :: proc(t: ^testing.T) {
    style := Style{fg_color = .Red, bg_color = .Blue, flags = {.Bold}}
    seq := to_ansi(style)
    
    testing.expect(t, strings.has_prefix(seq, "\x1b["), "Should start with escape sequence")
    testing.expect(t, strings.has_suffix(seq, "m"), "Should end with 'm'")
}

@(test)
test_empty_style_flags :: proc(t: ^testing.T) {
    flags: StyleFlags = {}
    seq := generate_style_sequence(.Default, .Default, flags)
    testing.expect_value(t, seq, "[0m")
}

@(test)
test_all_style_flags_combinations :: proc(t: ^testing.T) {
    flags: StyleFlags = {.Bold, .Dim, .Italic, .Underline, .Blink, .Reverse, .Hidden, .Strikethrough}
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
test_predefined_styles :: proc(t: ^testing.T) {
    testing.expect(t, STYLE_NORMAL.fg_color == .Default, "STYLE_NORMAL fg should be default")
    testing.expect(t, STYLE_NORMAL.bg_color == .Default, "STYLE_NORMAL bg should be default")
    testing.expect(t, STYLE_NORMAL.flags == {}, "STYLE_NORMAL flags should be empty")
    
    testing.expect(t, STYLE_BOLD.fg_color == .Default, "STYLE_BOLD fg should be default")
    testing.expect(t, STYLE_BOLD.flags == {.Bold}, "STYLE_BOLD should have bold")
    
    testing.expect(t, STYLE_DIM.flags == {.Dim}, "STYLE_DIM should have dim")
    testing.expect(t, STYLE_UNDERLINE.flags == {.Underline}, "STYLE_UNDERLINE should have underline")
    
    testing.expect(t, STYLE_ERROR.fg_color == .Red, "STYLE_ERROR should be red")
    testing.expect(t, STYLE_ERROR.flags == {.Bold}, "STYLE_ERROR should be bold")
    
    testing.expect(t, STYLE_SUCCESS.fg_color == .Green, "STYLE_SUCCESS should be green")
    
    testing.expect(t, STYLE_WARNING.fg_color == .Yellow, "STYLE_WARNING should be yellow")
    
    testing.expect(t, STYLE_INFO.fg_color == .Cyan, "STYLE_INFO should be cyan")
}
