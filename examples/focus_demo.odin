package examples

import ansuz "../ansuz"
import "core:fmt"
import "core:strings"

main :: proc() {
	// Initialize context
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to init:", err)
		return
	}
	defer ansuz.shutdown(ctx)

	// Set initial focus
	ansuz.set_focus(ctx, ansuz.id(ctx, "Button 1"))

	// State for checkbox
	checkbox_state := false

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

			// Capture checkbox state from outer scope (simple closure capture simulation for this demo)
			// In a real app, you'd pass a state struct or similar.
			// Since Odin procs can't capture easily without context, we'll assume global or passed state.
			// Ideally, we'd pass `user_data` to run(). For now, using a static variable simulation or careful struct usage.
			// But wait, `run` takes a proc.
			// We can't capture local `checkbox_state` in a raw proc unless `run` supports user_data.
			// `ansuz.run` signature is `proc(ctx: ^Context, update: proc(ctx: ^Context) -> bool)`.
			// So we cannot capture `checkbox_state` if it's local to `main`.
			//
			// Workaround: Make `checkbox_state` global for this example file.

			render_ui(ctx)
			return true
		},
	)
}

// Global state for demo simplicity
checkbox_state := false

render_ui :: proc(ctx: ^ansuz.Context) {
	// 2. Render UI
	ansuz.begin_layout(ctx)

	// Root container (full screen, vertical layout)
	ansuz.layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			padding = {1, 1, 1, 1},
			gap = 1,
		},
	)

	// Title
	ansuz.layout_text(
		ctx,
		"Native Widgets Demo",
		ansuz.style(.BrightWhite, .Default, {.Bold, .Underline}),
	)

	ansuz.layout_text(
		ctx,
		"Press TAB to cycle focus. Enter/Space to activate.",
		ansuz.style(.White, .Default, {}),
	)

	// Container for buttons
	ansuz.layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			sizing = {.X = ansuz.fixed(40), .Y = ansuz.fit()},
			padding = {2, 2, 1, 1},
			gap = 1,
		},
	)

	if ansuz.button(ctx, "Button 1") {
		// Clicked!
	}

	if ansuz.button(ctx, "Button 2") {
		// Clicked!
	}

	ansuz.checkbox(ctx, "Toggle Me", &checkbox_state)

	if checkbox_state {
		ansuz.layout_text(ctx, "  (Toggle is ON)", ansuz.style(.Green, .Default, {}))
	}

	ansuz.button(ctx, "Another Button")
	ansuz.button(ctx, "Exit")

	ansuz.layout_end_container(ctx)
	ansuz.layout_end_container(ctx) // End Root
	ansuz.end_layout(ctx)
}
