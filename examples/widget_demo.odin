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

	// Set initial focus to first widget
	ansuz.set_focus(ctx, u64(ansuz.element_id("Name Input")))

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

// Global state for demo
name_value: string = ""
name_cursor: int = 0
email_value: string = ""
email_cursor: int = 0
country_idx: int = 0
country_open: bool = false
subscribe_checked: bool = false
notification_idx: int = 1
notification_open: bool = false

// Option arrays for select widgets
COUNTRIES := []string{"United States", "United Kingdom", "Canada", "Australia", "Germany", "France", "Japan", "Brazil", "Other"}
NOTIFICATIONS := []string{"Daily", "Weekly", "Monthly", "Never"}

render_ui :: proc(ctx: ^ansuz.Context) {
	// Root container
	if ansuz.container(ctx, {
		direction = .TopToBottom,
		sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
		padding = {2, 2, 2, 2},
		gap = 1,
	}) {
		// Title
		ansuz.label(
			ctx,
			"Widget Demo - Form Example",
			ansuz.Element{
				style = ansuz.style(.BrightWhite, .Default, {.Bold, .Underline}),
				sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
			},
		)

		ansuz.label(
			ctx,
			"Press TAB to cycle focus. Enter/Space to activate. Esc to close dropdowns.",
			ansuz.Element{
				style = ansuz.style(.White, .Default, {.Dim}),
				sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
			},
		)

		ansuz.label(ctx, "", ansuz.Element{sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)}})

		// Form section
		if ansuz.container(ctx, {
			direction = .TopToBottom,
			sizing = {.X = ansuz.fixed(60), .Y = ansuz.fit()},
			padding = {2, 2, 2, 2},
			gap = 1,
		}) {
			// Name field
			ansuz.label(
				ctx,
				"Name:",
				ansuz.Element{
					style = ansuz.style(.BrightWhite, .Default, {.Bold}),
					sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
				},
			)
			ansuz.widget_input(ctx, "Name Input", &name_value, &name_cursor, "Enter your name...")

			ansuz.label(ctx, "", ansuz.Element{sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)}})

			// Email field
			ansuz.label(
				ctx,
				"Email:",
				ansuz.Element{
					style = ansuz.style(.BrightWhite, .Default, {.Bold}),
					sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
				},
			)
			ansuz.widget_input(ctx, "Email Input", &email_value, &email_cursor, "Enter your email...")

			ansuz.label(ctx, "", ansuz.Element{sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)}})

			// Country select
			ansuz.label(
				ctx,
				"Country:",
				ansuz.Element{
					style = ansuz.style(.BrightWhite, .Default, {.Bold}),
					sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
				},
			)
			if ansuz.widget_select(ctx, "Country Select", COUNTRIES, &country_idx, &country_open) {
				// Selection changed
			}

			ansuz.label(ctx, "", ansuz.Element{sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)}})

			// Subscribe checkbox
			ansuz.widget_checkbox(ctx, "Subscribe to newsletter", &subscribe_checked)

			// Notification preference (only show if subscribed)
			if subscribe_checked {
				ansuz.label(ctx, "", ansuz.Element{sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)}})
				ansuz.label(
					ctx,
					"Notification preference:",
					ansuz.Element{
						style = ansuz.style(.BrightWhite, .Default, {.Bold}),
						sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
					},
				)
					ansuz.widget_select(ctx, "Notification Select", NOTIFICATIONS, &notification_idx, &notification_open)
			}

			ansuz.label(ctx, "", ansuz.Element{sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)}})

			// Submit button
			if ansuz.widget_button(ctx, "Submit Form") {
				// Button clicked - in a real app, process the form here
			}
		}

		// Status bar at bottom
		if ansuz.container(ctx, {
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)},
			padding = {0, 0, 0, 0},
		}) {
			// Show current state
			status_msg := fmt.tprintf(
				"Name: %s | Email: %s | Country: %s | Subscribed: %v",
				name_value if len(name_value) > 0 else "(empty)",
				email_value if len(email_value) > 0 else "(empty)",
				COUNTRIES[country_idx] if country_idx >= 0 && country_idx < len(COUNTRIES) else "None",
				subscribe_checked,
			)
			ansuz.label(
				ctx,
				status_msg,
				ansuz.Element{
					style = ansuz.style(.White, .Default, {.Dim}),
					sizing = {.X = ansuz.fit(), .Y = ansuz.fixed(1)},
				},
			)
		}
	}
}
