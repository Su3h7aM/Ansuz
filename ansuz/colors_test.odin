package ansuz

import "core:testing"
import "core:fmt"

@(test)
test_color_to_ansi_fg :: proc(t: ^testing.T) {
    // Test basic colors
    testing.expect(t, color_to_ansi_fg(.Black) == "30", "Black fg should be 30")
    testing.expect(t, color_to_ansi_fg(.Red) == "31", "Red fg should be 31")
    testing.expect(t, color_to_ansi_fg(.Green) == "32", "Green fg should be 32")
    testing.expect(t, color_to_ansi_fg(.Yellow) == "33", "Yellow fg should be 33")
    testing.expect(t, color_to_ansi_fg(.Blue) == "34", "Blue fg should be 34")
    testing.expect(t, color_to_ansi_fg(.Magenta) == "35", "Magenta fg should be 35")
    testing.expect(t, color_to_ansi_fg(.Cyan) == "36", "Cyan fg should be 36")
    testing.expect(t, color_to_ansi_fg(.White) == "37", "White fg should be 37")
    testing.expect(t, color_to_ansi_fg(.Default) == "39", "Default fg should be 39")

    // Test bright colors
    testing.expect(t, color_to_ansi_fg(.BrightBlack) == "90", "BrightBlack fg should be 90")
    testing.expect(t, color_to_ansi_fg(.BrightRed) == "91", "BrightRed fg should be 91")
    testing.expect(t, color_to_ansi_fg(.BrightGreen) == "92", "BrightGreen fg should be 92")
    testing.expect(t, color_to_ansi_fg(.BrightYellow) == "93", "BrightYellow fg should be 93")
    testing.expect(t, color_to_ansi_fg(.BrightBlue) == "94", "BrightBlue fg should be 94")
    testing.expect(t, color_to_ansi_fg(.BrightMagenta) == "95", "BrightMagenta fg should be 95")
    testing.expect(t, color_to_ansi_fg(.BrightCyan) == "96", "BrightCyan fg should be 96")
    testing.expect(t, color_to_ansi_fg(.BrightWhite) == "97", "BrightWhite fg should be 97")
}

@(test)
test_color_to_ansi_bg :: proc(t: ^testing.T) {
    // Test basic colors
    testing.expect(t, color_to_ansi_bg(.Black) == "40", "Black bg should be 40")
    testing.expect(t, color_to_ansi_bg(.Red) == "41", "Red bg should be 41")
    testing.expect(t, color_to_ansi_bg(.Green) == "42", "Green bg should be 42")
    testing.expect(t, color_to_ansi_bg(.Yellow) == "43", "Yellow bg should be 43")
    testing.expect(t, color_to_ansi_bg(.Blue) == "44", "Blue bg should be 44")
    testing.expect(t, color_to_ansi_bg(.Magenta) == "45", "Magenta bg should be 45")
    testing.expect(t, color_to_ansi_bg(.Cyan) == "46", "Cyan bg should be 46")
    testing.expect(t, color_to_ansi_bg(.White) == "47", "White bg should be 47")
    testing.expect(t, color_to_ansi_bg(.Default) == "49", "Default bg should be 49")

    // Test bright colors
    testing.expect(t, color_to_ansi_bg(.BrightBlack) == "100", "BrightBlack bg should be 100")
    testing.expect(t, color_to_ansi_bg(.BrightRed) == "101", "BrightRed bg should be 101")
    testing.expect(t, color_to_ansi_bg(.BrightGreen) == "102", "BrightGreen bg should be 102")
    testing.expect(t, color_to_ansi_bg(.BrightYellow) == "103", "BrightYellow bg should be 103")
    testing.expect(t, color_to_ansi_bg(.BrightBlue) == "104", "BrightBlue bg should be 104")
}

@(test)
test_to_ansi :: proc(t: ^testing.T) {
    // Test simple style
    style := Style{.Red, .Black, {}}
    ansi := to_ansi(style)
    testing.expect(t, contains(anssi, "[31;40m"),
                  fmt.tprintf("Should contain fg and bg codes, got: %s", ansi))

    // Test style with flags
    style = Style{.Red, .Black, {.Bold, .Underline}}
    ansi = to_ansi(style)
    testing.expect(t, contains(ansi, "[31;40;1;4m"),
                  fmt.tprintf("Should contain fg, bg, and style flags, got: %s", ansi))
}

@(test)
test_style_equality :: proc(t: ^testing.T) {
    style1 := Style{.Red, .Black, {.Bold}}
    style2 := Style{.Red, .Black, {.Bold}}
    testing.expect(t, style1 == style2, "Identical styles should be equal")

    style2.fg_color = .Blue
    testing.expect(t, style1 != style2, "Different fg color should not be equal")

    style2.fg_color = .Red
    style2.bg_color = .White
    testing.expect(t, style1 != style2, "Different bg color should not be equal")

    style2.bg_color = .Black
    style2.flags = {.Bold, .Underline}
    testing.expect(t, style1 != style2, "Different style flags should not be equal")
}

@(test)
test_predefined_styles :: proc(t: ^testing.T) {
    testing.expect(t, STYLE_NORMAL.fg_color == .Default, "STYLE_NORMAL fg should be default")
    testing.expect(t, STYLE_NORMAL.bg_color == .Default, "STYLE_NORMAL bg should be default")
    testing.expect(t, card(STYLE_NORMAL.flags) == 0, "STYLE_NORMAL should have no flags")

    testing.expect(t, STYLE_BOLD.fg_color == .Default, "STYLE_BOLD fg should be default")
    testing.expect(t, card(STYLE_BOLD.flags) == 1, "STYLE_BOLD should have 1 flag")
    testing.expect(t, .Bold in STYLE_BOLD.flags, "STYLE_BOLD should have Bold flag")

    testing.expect(t, STYLE_ERROR.fg_color == .Red, "STYLE_ERROR fg should be Red")
    testing.expect(t, .Bold in STYLE_ERROR.flags, "STYLE_ERROR should have Bold flag")

    testing.expect(t, STYLE_SUCCESS.fg_color == .Green, "STYLE_SUCCESS fg should be Green")

    testing.expect(t, STYLE_WARNING.fg_color == .Yellow, "STYLE_WARNING fg should be Yellow")

    testing.expect(t, STYLE_INFO.fg_color == .Cyan, "STYLE_INFO fg should be Cyan")
}

// Helper function to check if string contains substring
contains :: proc(s, substr: string) -> bool {
    if len(s) < len(substr) do return false
    for i in 0..len(s)-len(substr) {
        if s[i:i+len(substr)] == substr do return true
    }
    return false
}
