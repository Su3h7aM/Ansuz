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
	for {
		// IMPORTANT: poll_events() clears input_keys and captures new keys.
		// Widgets check input_keys during render for Enter/Space activation.
		// So we MUST call poll_events() BEFORE render_ui().
		events := ansuz.poll_events(ctx)

		// Render UI - widgets will check input_keys for activation
		if ansuz.render(ctx) {
			render_ui(ctx)
		}

		// Process events AFTER rendering
		// TAB navigation uses prev_focusable_items (from last frame)
		for event in events {
			if ansuz.is_quit_key(event) do return

			// Handle Tab key
			#partial switch e in event {
			case ansuz.KeyEvent:
				if e.key == .Tab {
					shift_held := .Shift in e.modifiers
					ansuz.handle_tab_navigation(ctx, shift_held)
				}
			}
		}

		ansuz.wait_for_event(ctx)
	}
}

// Global state for demo simplicity
checkbox_state := false

render_ui :: proc(ctx: ^ansuz.Context) {
	// Root container
	if ansuz.container(ctx, {
		direction = .TopToBottom,
		sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
		padding = {1, 1, 1, 1},
		gap = 1,
	}) {
		// Title using label()
		ansuz.label(
			ctx,
			"Native Widgets Demo (Scoped API)",
			ansuz.Element{
				style = ansuz.style(.BrightWhite, .Default, {.Bold, .Underline}),
				sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
			},
		)

		ansuz.label(
			ctx,
			"Press TAB to cycle focus. Enter/Space to activate.",
			ansuz.Element{
				style = ansuz.style(.White, .Default, {}),
				sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
			},
		)

		// Nested container for buttons
		if ansuz.container(ctx, {
			direction = .TopToBottom,
			sizing = {.X = ansuz.fixed(50), .Y = ansuz.fit()},
			padding = {2, 2, 1, 1},
			gap = 1,
		}) {
			// Use new widget_button API
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
					ansuz.Element{
						style = ansuz.style(.Green, .Default, {}),
						sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
					},
				)
			}

			ansuz.widget_button(ctx, "Another Button")
			ansuz.widget_button(ctx, "Exit")
		}
	}
}
