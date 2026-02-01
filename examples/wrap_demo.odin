package main

import "../ansuz"
import "core:fmt"
import "core:os"
import "core:strings"

// Demo state (Global to avoid closure capture issues)
State :: struct {
	width:  int,
	height: int,
}

var_state := State{}

main :: proc() {
	// Initialize library
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to initialize Ansuz:", err)
		os.exit(1)
	}
	defer ansuz.shutdown(ctx)

	// Run main loop
	ansuz.run(
		ctx,
		proc(ctx: ^ansuz.Context) -> bool {
			// Event handling
			for event in ansuz.poll_events(ctx) {
				switch e in event {
				case ansuz.KeyEvent:
					if e.key == .Char && e.rune == 'q' {
						return false
					}
					if e.key == .Escape {
						return false
					}
				case ansuz.ResizeEvent:
				// Handled automatically by library, but we could update state here if needed immediately
				case ansuz.MouseEvent:
				}
			}

			// Update state
			var_state.width, var_state.height = ansuz.get_size(ctx)

			// Layout
			ansuz.begin_layout(ctx)

			// Root container
			ansuz.Layout_begin_container(
				ctx,
				{
					direction = .TopToBottom,
					sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
					padding = {2, 2, 1, 1},
					gap = 1,
				},
			)

			ansuz.Layout_text(
				ctx,
				"Ansuz Text Wrapping Demo (Press 'q' to quit)",
				{fg = .Cyan, bg = .Default, flags = {.Bold}},
			)
			ansuz.Layout_text(
				ctx,
				"Resize the terminal to see dynamic wrapping",
				{fg = .White, bg = .Default},
			)

			// Flexible Box with Wrapped Text
			ansuz.Layout_box(
				ctx,
				{fg = .Green, bg = .Default},
				{
					direction = .TopToBottom,
					sizing    = {ansuz.Sizing_grow(), ansuz.Sizing_grow()}, // Grow width, Grow height
					padding   = {1, 1, 1, 1},
				},
			)
			ansuz.Layout_text(
				ctx,
				"This is a long paragraph that should wrap automatically when the terminal is resized. It demonstrates the new 'wrap_text' capability in functionality. The height of this element should adjust dynamically based on the width available, ensuring all text is visible without horizontal scrolling.",
				{fg = .White, bg = .Default},
				{
					sizing    = {ansuz.Sizing_grow(), ansuz.Sizing_fit()}, // Width fits parent (Grow), Height fits content
					wrap_text = true,
				},
			)

			ansuz.Layout_text(
				ctx,
				"--- Separator ---",
				{fg = .Black, bg = .Default, flags = {.Bold}},
			)

			ansuz.Layout_text(
				ctx,
				"Another paragraph with different styling. Wrapping allows for rich text layouts that adapt to any screen size, which is critical for modern TUI applications.",
				{fg = .Yellow, bg = .Default, flags = {.Italic}},
				{sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fit()}, wrap_text = true},
			)
			ansuz.Layout_end_box(ctx)

			// Fixed Width Column Test
			ansuz.Layout_box(
				ctx,
				{fg = .Blue, bg = .Default},
				{
					direction = .TopToBottom,
					sizing = {ansuz.Sizing_fixed(40), ansuz.Sizing_fit()},
					padding = {1, 1, 0, 0},
					gap = 0,
				},
			)
			ansuz.Layout_text(
				ctx,
				"Fixed Width (40) Column with Wrapping",
				{fg = .Blue, bg = .Default, flags = {.Bold}},
			)
			ansuz.Layout_text(
				ctx,
				"This text is constrained to a fixed width of 40 characters. It should wrap within this column regardless of window size.",
				{fg = .White, bg = .Default},
				{
					sizing    = {ansuz.Sizing_fixed(36), ansuz.Sizing_fit()}, // 36 + padding
					wrap_text = true,
				},
			)
			ansuz.Layout_end_box(ctx)

			ansuz.Layout_end_container(ctx)
			ansuz.end_layout(ctx)

			return true
		},
	)
}
