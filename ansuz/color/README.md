# ansuz-color

Independent color system for terminal applications.

## Overview

`ansuz-color` is a standalone package for handling terminal colors in Odin. It supports:

- **ANSI 16-color**: Standard terminal colors (universal compatibility)
- **256-color palette**: Extended palette (0-255 index)
- **24-bit RGB**: True color (16M+ colors, modern terminals)

## Usage

```odin
import "ansuz-color"

// Create colors
c1 := ansuz_color.rgb(255, 128, 0)          // RGB true color
c2 := ansuz_color.hex(0xFF8000)             // Hex color
c3 := ansuz_color.color256(208)             // 256-color palette
c4 := ansuz_color.grayscale(12)             // Grayscale (0-23)
c5 := ansuz_color.Ansi.Red                  // ANSI color

// Create styles
style := ansuz_color.style(.Red, .Default, {.Bold})
default := ansuz_color.default_style()

// Generate ANSI sequences
seq := ansuz_color.to_ansi(style)
fmt.print(seq)  // Outputs: \x1b[31;1m
```

## Types

- `TerminalColor`: Union of `Ansi`, `Color256`, and `RGB`
- `Style`: Struct with foreground, background, and style flags
- `StyleFlags`: Bit set of `StyleFlag` (Bold, Dim, Italic, etc.)

## Dependencies

- `core:fmt`
- `core:terminal/ansi`

## No External Dependencies

This package has zero dependencies on other ansuz packages and can be used
independently in any Odin project requiring terminal color support.
