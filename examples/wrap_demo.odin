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
			var_state.width, var_state.height = ctx.width, ctx.height

			// Layout
			ansuz.begin_layout(ctx)

			// Root container
			ansuz.layout_begin_container(
				ctx,
				{
					direction = .TopToBottom,
					sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
					padding = {2, 2, 1, 1},
					gap = 1,
				},
			)

			ansuz.layout_text(
				ctx,
				"Ansuz Text Wrapping Demo (Press 'q' to quit)",
				ansuz.style(.Cyan, .Default, {.Bold}),
			)
			ansuz.layout_text(
				ctx,
				"Resize the terminal to see dynamic wrapping",
				ansuz.style(.White, .Default, {}),
			)

			// Flexible Box with Wrapped Text
			ansuz.layout_box(
				ctx,
				ansuz.style(.Green, .Default, {}),
				{
					direction = .TopToBottom,
					sizing    = {ansuz.sizing_grow(), ansuz.sizing_grow()}, // Grow width, Grow height
					padding   = {1, 1, 1, 1},
				},
			)
			ansuz.layout_text(
				ctx,
				"This is a long paragraph that should wrap automatically when the terminal is resized. It demonstrates the new 'wrap_text' capability in functionality. The height of this element should adjust dynamically based on the width available, ensuring all text is visible without horizontal scrolling.",
				ansuz.style(.White, .Default, {}),
				{
					sizing    = {ansuz.sizing_grow(), ansuz.sizing_fit()}, // Width fits parent (Grow), Height fits content
					wrap_text = true,
				},
			)

			ansuz.layout_text(
				ctx,
				"--- Separator ---",
				ansuz.style(.Black, .Default, {.Bold}),
			)

			ansuz.layout_text(
				ctx,
				"Another paragraph with different styling. Wrapping allows for rich text layouts that adapt to any screen size, which is critical for modern TUI applications.",
				ansuz.style(.Yellow, .Default, {.Italic}),
				{sizing = {ansuz.sizing_grow(), ansuz.sizing_fit()}, wrap_text = true},
			)
			ansuz.layout_end_container(ctx)

			// Fixed Width Column Test
			ansuz.layout_box(
				ctx,
				ansuz.style(.Blue, .Default, {}),
				{
					direction = .TopToBottom,
					sizing = {ansuz.sizing_fixed(40), ansuz.sizing_fit()},
					padding = {1, 1, 0, 0},
					gap = 0,
				},
			)
			ansuz.layout_text(
				ctx,
				"Fixed Width (40) Column with Wrapping",
				ansuz.style(.Blue, .Default, {.Bold}),
			)
			ansuz.layout_text(
				ctx,
				"This text is constrained to a fixed width of 40 characters. It should wrap within this column regardless of window size.",
				ansuz.style(.White, .Default, {}),
				{
					sizing    = {ansuz.sizing_fixed(36), ansuz.sizing_fit()}, // 36 + padding
					wrap_text = true,
				},
			)
			ansuz.layout_end_container(ctx)

			ansuz.layout_end_container(ctx)
			ansuz.end_layout(ctx)

			return true
		},
	)
}
