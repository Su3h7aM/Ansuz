package examples

import ansuz "../ansuz"
import "core:fmt"

main :: proc() {
	// Initialize context
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to init:", err)
		return
	}
	defer ansuz.shutdown(ctx)

	// Set initial focus
	ansuz.set_focus(ctx, u64(ansuz.element_id("Button 1")))

	// Main loop
	ansuz.run(
		ctx,
		proc(ctx: ^ansuz.Context) -> bool {
			// 1. Process Input
			events := ansuz.poll_events(ctx)
			for event in events {
				if ansuz.is_quit_key(event) {
					return false
				}

				// Handle Tab key
				#partial switch e in event {
				case ansuz.KeyEvent:
					if e.key == .Tab {
						shift_held := .Shift in e.modifiers
						ansuz.handle_tab_navigation(ctx, shift_held)
					}
				}
			}

			render_ui(ctx)
			return true
		},
	)
}

// Global state for demo simplicity
checkbox_state := false

render_ui :: proc(ctx: ^ansuz.Context) {
	ansuz.begin_layout(ctx)

	// Root container
	ansuz.begin_element(
		ctx,
		{
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			padding = {1, 1, 1, 1},
			gap = 1,
		},
	)

	// Title using label()
	ansuz.label(
		ctx,
		"Native Widgets Demo (Explicit API)",
		{
			style = ansuz.style(.BrightWhite, .Default, {.Bold, .Underline}),
			sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
		},
	)

	ansuz.label(
		ctx,
		"Press TAB to cycle focus. Enter/Space to activate.",
		{
			style = ansuz.style(.White, .Default, {}),
			sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
		},
	)

	// Nested container for buttons
	ansuz.begin_element(
		ctx,
		{
			direction = .TopToBottom,
			sizing = {.X = ansuz.fixed(50), .Y = ansuz.fit()},
			padding = {2, 2, 1, 1},
			gap = 1,
		},
	)

	// Use the new widget_button API
	if ansuz.widget_button(ctx, "Button 1") {
		// Clicked!
	}

	if ansuz.widget_button(ctx, "Button 2") {
		// Clicked!
	}

	ansuz.widget_checkbox(ctx, "Toggle Me", &checkbox_state)

	if checkbox_state {
		ansuz.label(
			ctx,
			"  (Toggle is ON)",
			{
				style = ansuz.style(.Green, .Default, {}),
				sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
			},
		)
	}

	ansuz.widget_button(ctx, "Another Button")
	ansuz.widget_button(ctx, "Exit")

	ansuz.end_element(ctx) // End Buttons Container

	ansuz.end_element(ctx) // End Root Container

	ansuz.end_layout(ctx)
}
