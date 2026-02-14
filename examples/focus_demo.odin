package examples

import ansuz "../ansuz"
import "core:fmt"
import "core:os"

// Global log file for debugging
g_log_file: os.Handle

log_debug :: proc(msg: string) {
	if g_log_file != os.INVALID_HANDLE {
		fmt.fprintln(g_log_file, msg)
		os.flush(g_log_file)
	}
}

main :: proc() {
	// Open debug log file
	log_file, log_err := os.open("/tmp/focus_demo_debug.log", os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
	if log_err == os.ERROR_NONE {
		g_log_file = log_file
		defer os.close(g_log_file)
	}

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
			// IMPORTANT: poll_events() clears input_keys and captures new keys.
			// Widgets check input_keys during render for Enter/Space activation.
			// So we MUST call poll_events() BEFORE render_ui().
			events := ansuz.poll_events(ctx)

			// Render UI - widgets will check input_keys for activation
			render_ui(ctx)

			// Process events AFTER rendering
			// TAB navigation uses prev_focusable_items (from last frame)
			log_debug(fmt.tprintf("DEBUG: Processing %d events", len(events)))
			for event, i in events {
				log_debug(fmt.tprintf("DEBUG: Event %d type", i))
				
				if ansuz.is_quit_key(event) {
					return false
				}

				// Handle Tab key
				#partial switch e in event {
				case ansuz.KeyEvent:
					log_debug(fmt.tprintf("DEBUG: Key pressed: %v", e.key))
					if e.key == .Tab {
						log_debug("DEBUG: TAB detected!")
						shift_held := .Shift in e.modifiers
						result := ansuz.handle_tab_navigation(ctx, shift_held)
						log_debug(fmt.tprintf("DEBUG: handle_tab_navigation returned: %v", result))
						log_debug(fmt.tprintf("DEBUG: focus_id: %d", ctx.focus_id))
						log_debug(fmt.tprintf("DEBUG: prev_focusable_items count: %d", len(ctx.prev_focusable_items)))
						log_debug(fmt.tprintf("DEBUG: focusable_items count: %d", len(ctx.focusable_items)))
					}
				}
			}

			return true
		},
	)
}

// Global state for demo simplicity
checkbox_state := false

render_ui :: proc(ctx: ^ansuz.Context) {
	// API 100% scoped - sem begin/end explícitos
	ansuz.layout(ctx, proc(ctx: ^ansuz.Context) {
		// Root container
		ansuz.container(ctx, {
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			padding = {1, 1, 1, 1},
			gap = 1,
		}, proc(ctx: ^ansuz.Context) {
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
			ansuz.container(ctx, {
				direction = .TopToBottom,
				sizing = {.X = ansuz.fixed(50), .Y = ansuz.fit()},
				padding = {2, 2, 1, 1},
				gap = 1,
			}, proc(ctx: ^ansuz.Context) {
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
						ansuz.Element{
							style = ansuz.style(.Green, .Default, {}),
							sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
						},
					)
				}

				ansuz.widget_button(ctx, "Another Button")
				ansuz.widget_button(ctx, "Exit")
			})
		})
	})
}
