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
			ansuz.begin_element(
				ctx,
				{
					direction = .TopToBottom,
					sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
					padding = {2, 2, 1, 1},
					gap = 1,
				},
			)

			ansuz.label(
				ctx,
				"Ansuz Text Wrapping Demo (Press 'q' to quit)",
				{style = ansuz.style(.Cyan, .Default, {.Bold})},
			)
			ansuz.label(
				ctx,
				"Resize the terminal to see dynamic wrapping",
				{style = ansuz.style(.White, .Default, {})},
			)

			// Flexible Box with Wrapped Text
			ansuz.begin_element(
				ctx,
				{
					box_style = .Rounded, // Using Rounded instead of just box for better look
					style = ansuz.style(.Green, .Default, {}),
					layout = {
						direction = .TopToBottom,
						sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
						padding = {1, 1, 1, 1},
					},
				},
			)
			ansuz.label(
				ctx,
				"This is a long paragraph that should wrap automatically when the terminal is resized. It demonstrates the new 'wrap_text' capability in functionality. The height of this element should adjust dynamically based on the width available, ensuring all text is visible without horizontal scrolling.",
				{
					style = ansuz.style(.White, .Default, {}),
					layout = {sizing = {.X = ansuz.grow(), .Y = ansuz.fit()}, wrap_text = true},
				},
			)

			ansuz.label(ctx, "--- Separator ---", {style = ansuz.style(.Black, .Default, {.Bold})})

			ansuz.label(
				ctx,
				"Another paragraph with different styling. Wrapping allows for rich text layouts that adapt to any screen size, which is critical for modern TUI applications.",
				{
					style = ansuz.style(.Yellow, .Default, {.Italic}),
					layout = {sizing = {.X = ansuz.grow(), .Y = ansuz.fit()}, wrap_text = true},
				},
			)
			ansuz.end_element(ctx) // End Flexible Box

			// Fixed Width Column Test
			ansuz.begin_element(
				ctx,
				{
					box_style = .Rounded,
					style = ansuz.style(.Blue, .Default, {}),
					layout = {
						direction = .TopToBottom,
						sizing = {.X = ansuz.fixed(40), .Y = ansuz.fit()},
						padding = {1, 1, 0, 0},
						gap = 0,
					},
				},
			)
			ansuz.label(
				ctx,
				"Fixed Width (40) Column with Wrapping",
				{style = ansuz.style(.Blue, .Default, {.Bold})},
			)
			ansuz.label(
				ctx,
				"This text is constrained to a fixed width of 40 characters. It should wrap within this column regardless of window size.",
				{
					style = ansuz.style(.White, .Default, {}),
					layout = {
						sizing = {.X = ansuz.fixed(36), .Y = ansuz.fit()}, // 36 + padding
						wrap_text = true,
					},
				},
			)
			ansuz.end_element(ctx) // End Fixed Width Column

			ansuz.end_element(ctx) // End Root
			ansuz.end_layout(ctx)

			return true
		},
	)
}
