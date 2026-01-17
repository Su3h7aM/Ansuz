package main

import ansuz "../ansuz"
import "core:fmt"

main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to initialize Ansuz:", err)
		return
	}
	defer ansuz.shutdown(ctx)

	ansuz.set_target_fps(ctx, 30)

	running := true
	for running {
		ansuz.begin_frame(ctx)

		events := ansuz.poll_events(ctx)
		for ev in events {
			#partial switch e in ev {
			case ansuz.KeyEvent:
				#partial switch e.key {
				case .Ctrl_C, .Ctrl_D, .Escape:
					running = false
				}
			}
		}

		// Simple test layout
		ansuz.begin_layout(ctx)

		// Create a box container (main container)
		ansuz.Layout_box(ansuz.STYLE_NORMAL, {
			direction = .TopToBottom,
			padding = {2, 2, 2, 2},
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
		})

		// Add some text inside the box
		ansuz.Layout_text(ctx, "This text should be inside the box", ansuz.STYLE_BOLD)
		ansuz.Layout_text(ctx, "Line 2 inside the box", ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, "Line 3 inside the box", ansuz.STYLE_NORMAL)

		ansuz.Layout_end_box(ctx)

		ansuz.end_layout(ctx)

		ansuz.end_frame(ctx)
	}
}
