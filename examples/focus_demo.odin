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
				"Focus & Tab Navigation Demo",
				ansuz.style(.BrightWhite, .Default, {.Bold, .Underline}),
			)

			ansuz.layout_text(
				ctx,
				"Press TAB to cycle focus. Press ENTER to 'click'.",
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

			// Helper for buttons
			button :: proc(ctx: ^ansuz.Context, label: string) {
				id := ansuz.id(ctx, label)
				focused := ansuz.is_focused(ctx, id)

				// Register for navigation
				ansuz.register_focusable(ctx, id)

				style := ansuz.style(.White, .Default, {})
				prefix := "[ ] "

				if focused {
					style = ansuz.style(.Black, .BrightCyan, {.Bold})
					prefix = "[*] "
				}

				ansuz.layout_text(
					ctx,
					fmt.tprintf("%s%s", prefix, label),
					style,
					{sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)}},
				)
			}

			button(ctx, "Button 1")
			button(ctx, "Button 2")
			button(ctx, "Button 3")
			button(ctx, "Middle Button")
			button(ctx, "Button 4")
			button(ctx, "Button 5")

			ansuz.layout_end_container(ctx)
			ansuz.layout_end_container(ctx) // End Root
			ansuz.end_layout(ctx)

			return true
		},
	)
}
