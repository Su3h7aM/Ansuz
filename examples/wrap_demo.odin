package main

import ansuz "../ansuz/core"
import "core:fmt"
import "core:os"

main :: proc() {
	// Initialize library
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to initialize Ansuz:", err)
		os.exit(1)
	}
	defer ansuz.shutdown(ctx)

	// Main loop
	for {
		// Event handling
		for event in ansuz.poll_events(ctx) {
			switch e in event {
			case ansuz.KeyEvent:
				if e.key == .Char && e.rune == 'q' {
					return
				}
				if e.key == .Escape {
					return
				}
			case ansuz.ResizeEvent:
			// Handled automatically by library
			case ansuz.MouseEvent:
			}
		}

		// Render
		if ansuz.render(ctx) {
			// Root container
			if ansuz.container(ctx, {
				direction = .TopToBottom,
				sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
				padding = {2, 2, 1, 1},
				gap = 1,
			}) {
				ansuz.label(
					ctx,
					"Ansuz Text Wrapping Demo (Press 'q' to quit)",
					{style = ansuz.style(.Cyan, .Default, {.Bold})},
				)
				ansuz.label(
					ctx,
					"Resize terminal to see dynamic wrapping",
					{style = ansuz.style(.White, .Default, {})},
				)

				// Flexible Box with Wrapped Text
				if ansuz.box(ctx, {
					direction = .TopToBottom,
					sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
					padding = {1, 1, 1, 1},
				}, ansuz.style(.Green, .Default, {}), .Rounded) {
					ansuz.label(
						ctx,
						"This is a long paragraph that should wrap automatically when terminal is resized. It demonstrates new 'wrap_text' capability in functionality. The height of this element should adjust dynamically based on width available, ensuring all text is visible without horizontal scrolling.",
						{
							style = ansuz.style(.White, .Default, {}),
							sizing = {.X = ansuz.grow(), .Y = ansuz.fit()},
							wrap_text = true,
						},
					)

					ansuz.label(ctx, "--- Separator ---", {style = ansuz.style(.Black, .Default, {.Bold})})

					ansuz.label(
						ctx,
						"Another paragraph with different styling. Wrapping allows for rich text layouts that adapt to any screen size, which is critical for modern TUI applications.",
						{
							style = ansuz.style(.Yellow, .Default, {.Italic}),
							sizing = {.X = ansuz.grow(), .Y = ansuz.fit()},
							wrap_text = true,
						},
					)
				}

				// Fixed Width Column Test
				if ansuz.box(ctx, {
					direction = .TopToBottom,
					sizing = {.X = ansuz.fixed(40), .Y = ansuz.fit()},
					padding = {1, 1, 0, 0},
					gap = 0,
				}, ansuz.style(.Blue, .Default, {}), .Rounded) {
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
							sizing = {.X = ansuz.fixed(36), .Y = ansuz.fit()}, // 36 + padding
							wrap_text = true,
						},
					)
				}
			}
		}

		// Wait for next event
		ansuz.wait_for_event(ctx)
	}
}
