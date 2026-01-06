package ansuz

import "core:fmt"

// Color represents terminal colors (16-color palette)
// We use the standard ANSI color set that's widely supported
Color :: enum {
    Default,        // Use terminal's default color
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    White,
    BrightBlack,    // Also called "Gray"
    BrightRed,
    BrightGreen,
    BrightYellow,
    BrightBlue,
    BrightMagenta,
    BrightCyan,
    BrightWhite,
}

// StyleFlag represents text attributes that can be combined
// Multiple flags can be active simultaneously using bit flags
StyleFlag :: enum {
    Bold,
    Dim,
    Italic,
    Underline,
    Blink,
    Reverse,    // Swap foreground and background
    Hidden,
    Strikethrough,
}

// StyleFlags is a set of style attributes
StyleFlags :: bit_set[StyleFlag]

// color_to_ansi_fg converts a Color to its ANSI foreground color code
// Returns the numeric code used in ANSI escape sequences
color_to_ansi_fg :: proc(color: Color) -> int {
    switch color {
    case .Default:        return 39
    case .Black:          return 30
    case .Red:            return 31
    case .Green:          return 32
    case .Yellow:         return 33
    case .Blue:           return 34
    case .Magenta:        return 35
    case .Cyan:           return 36
    case .White:          return 37
    case .BrightBlack:    return 90
    case .BrightRed:      return 91
    case .BrightGreen:    return 92
    case .BrightYellow:   return 93
    case .BrightBlue:     return 94
    case .BrightMagenta:  return 95
    case .BrightCyan:     return 96
    case .BrightWhite:    return 97
    }
    return 39 // Fallback to default
}

// color_to_ansi_bg converts a Color to its ANSI background color code
// Background codes are offset by 10 from foreground codes
color_to_ansi_bg :: proc(color: Color) -> int {
    switch color {
    case .Default:        return 49
    case .Black:          return 40
    case .Red:            return 41
    case .Green:          return 42
    case .Yellow:         return 43
    case .Blue:           return 44
    case .Magenta:        return 45
    case .Cyan:           return 46
    case .White:          return 47
    case .BrightBlack:    return 100
    case .BrightRed:      return 101
    case .BrightGreen:    return 102
    case .BrightYellow:   return 103
    case .BrightBlue:     return 104
    case .BrightMagenta:  return 105
    case .BrightCyan:     return 106
    case .BrightWhite:    return 107
    }
    return 49 // Fallback to default
}

// style_flag_to_ansi converts a single StyleFlag to its ANSI code
style_flag_to_ansi :: proc(flag: StyleFlag) -> int {
    switch flag {
    case .Bold:           return 1
    case .Dim:            return 2
    case .Italic:         return 3
    case .Underline:      return 4
    case .Blink:          return 5
    case .Reverse:        return 7
    case .Hidden:         return 8
    case .Strikethrough:  return 9
    }
    return 0
}

// generate_style_sequence creates a complete ANSI escape sequence
// for the given foreground color, background color, and style flags
// Returns a string like "\x1b[1;31;42m" for bold red on green
generate_style_sequence :: proc(fg: Color, bg: Color, styles: StyleFlags) -> string {
    if fg == .Default && bg == .Default && len(styles) == 0 {
        // No styling needed, return reset
        return "\x1b[0m"
    }

    // Build the sequence: ESC [ code1 ; code2 ; ... m
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
    if fg != .Default {
        if !first {
            builder = fmt.tprintf("%s;", builder)
        }
        builder = fmt.tprintf("%s%d", builder, color_to_ansi_fg(fg))
        first = false
    }

    // Add background color
    if bg != .Default {
        if !first {
            builder = fmt.tprintf("%s;", builder)
        }
        builder = fmt.tprintf("%s%d", builder, color_to_ansi_bg(bg))
        first = false
    }

    // Close the sequence
    builder = fmt.tprintf("%sm", builder)
    return builder
}

// reset_style returns the ANSI sequence to reset all styling
// This clears all colors and attributes back to terminal defaults
reset_style :: proc() -> string {
    return "\x1b[0m"
}

// Style is a convenience struct for passing style information
Style :: struct {
    fg_color: Color,
    bg_color: Color,
    flags:    StyleFlags,
}

// default_style returns a Style with all default values
default_style :: proc() -> Style {
    return Style{
        fg_color = .Default,
        bg_color = .Default,
        flags = {},
    }
}

// to_ansi converts a Style to its ANSI escape sequence
to_ansi :: proc(style: Style) -> string {
    return generate_style_sequence(style.fg_color, style.bg_color, style.flags)
}

// Predefined common styles for convenience
STYLE_NORMAL :: Style{.Default, .Default, {}}
STYLE_BOLD :: Style{.Default, .Default, {.Bold}}
STYLE_DIM :: Style{.Default, .Default, {.Dim}}
STYLE_UNDERLINE :: Style{.Default, .Default, {.Underline}}
STYLE_ERROR :: Style{.Red, .Default, {.Bold}}
STYLE_SUCCESS :: Style{.Green, .Default, {}}
STYLE_WARNING :: Style{.Yellow, .Default, {}}
STYLE_INFO :: Style{.Cyan, .Default, {}}
