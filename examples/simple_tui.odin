package main

import ansuz "../ansuz"
import "core:fmt"

main :: proc() {
    ctx, err := ansuz.init()
    if err != .None {
        fmt.eprintln("Failed to init:", err)
        return
    }
    defer ansuz.shutdown(ctx)

    running := true
    for running {
        // Input
        events := ansuz.poll_events(ctx)
        for ev in events {
            #partial switch e in ev {
            case ansuz.KeyEvent:
                if e.key == .Ctrl_C || (e.key == .Char && e.rune == 'q') {
                    running = false
                }
            }
        }

        ansuz.begin_frame(ctx)
        ansuz.begin_layout(ctx)

        // Root container - filling the screen
        ansuz.Layout_begin_container(ctx, {
            direction = .TopToBottom,
            sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
            alignment = {horizontal = .Center, vertical = .Center},
        })

            // Centered Box with Rounded Borders
            ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
                sizing = {ansuz.Sizing_fixed(40), ansuz.Sizing_fixed(10)},
                alignment = {horizontal = .Center, vertical = .Center}, // Center text inside box
            }, .Rounded)
                ansuz.Layout_text(ctx, "Hello from Ansuz!", ansuz.STYLE_BOLD)
                ansuz.Layout_text(ctx, "Press 'q' to quit", ansuz.STYLE_DIM)
            ansuz.Layout_end_box(ctx)

        ansuz.Layout_end_container(ctx)

        ansuz.end_layout(ctx)
        ansuz.end_frame(ctx)
    }
}
