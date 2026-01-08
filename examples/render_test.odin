package main

// Simple render test to verify immediate mode rendering
// This example demonstrates the simplified immediate mode approach

import "core:fmt"
import ansuz "../ansuz"

main :: proc() {
    ctx, err := ansuz.init()
    if err != .None {
        fmt.eprintln("Failed to initialize Ansuz:", err)
        return
    }
    defer ansuz.shutdown(ctx)

    fmt.println("Ansuz Render Test")
    fmt.println("This demonstrates immediate mode - each frame is complete")
    fmt.println("Press Ctrl+C to exit")

    frame_count := 0

    for {
        // Handle input
        events := ansuz.poll_events(ctx)
        for event in events {
            switch e in event {
            case ansuz.KeyEvent:
                if e.key == .Ctrl_C || e.key == .Escape {
                    return
                }
            case:
                // Ignore other events
            }
        }

        // Render frame
        ansuz.begin_frame(ctx)

        width, height := ansuz.get_size(ctx)

        // Draw status header
        status := fmt.tprintf("Immediate Mode TUI - Frame: %d - Terminal: %dx%d",
                              frame_count, width, height)
        ansuz.text(ctx, 0, 0, status, ansuz.STYLE_BOLD)

        // Draw separator
        for i in 0..<width {
            ansuz.rect(ctx, i, 1, 1, 1, '=', .Default,
                       ansuz.Style{.Cyan, .Default, {}})
        }

        // Draw some colored boxes to demonstrate immediate mode
        // Each frame, these boxes are drawn fresh - no diffing needed
        box_width := 20
        box_height := 5

        // Box 1 - Red theme
        y := 3
        ansuz.rect(ctx, 2, y, box_width, box_height, ' ',
                   ansuz.Style{.White, .Red, {}})
        ansuz.box(ctx, 2, y, box_width, box_height,
                  ansuz.Style{.BrightRed, .Red, {.Bold}})
        ansuz.text(ctx, (2 + box_width - 7) / 2, y + 2, "BOX 1",
                   ansuz.Style{.White, .Red, {.Bold}})

        // Box 2 - Green theme
        ansuz.rect(ctx, 2 + box_width + 2, y, box_width, box_height, ' ',
                   ansuz.Style{.White, .Green, {}})
        ansuz.box(ctx, 2 + box_width + 2, y, box_width, box_height,
                  ansuz.Style{.BrightGreen, .Green, {.Bold}})
        ansuz.text(ctx, (2 + box_width + 2 + box_width - 7) / 2, y + 2, "BOX 2",
                   ansuz.Style{.White, .Green, {.Bold}})

        // Box 3 - Blue theme
        ansuz.rect(ctx, 2 + (box_width + 2) * 2, y, box_width, box_height, ' ',
                   ansuz.Style{.White, .Blue, {}})
        ansuz.box(ctx, 2 + (box_width + 2) * 2, y, box_width, box_height,
                  ansuz.Style{.BrightCyan, .Blue, {.Bold}})
        ansuz.text(ctx, (2 + (box_width + 2) * 2 + box_width - 7) / 2, y + 2, "BOX 3",
                   ansuz.Style{.White, .Blue, {.Bold}})

        // Draw text styles demo
        y = 10
        ansuz.text(ctx, 2, y, "Text Styles Demo:", ansuz.STYLE_BOLD)

        y += 2
        ansuz.text(ctx, 4, y, "Normal text", ansuz.STYLE_NORMAL)
        y += 1
        ansuz.text(ctx, 4, y, "Bold text", ansuz.STYLE_BOLD)
        y += 1
        ansuz.text(ctx, 4, y, "Dim text", ansuz.STYLE_DIM)
        y += 1
        ansuz.text(ctx, 4, y, "Underline text", ansuz.STYLE_UNDERLINE)
        y += 1
        ansuz.text(ctx, 4, y, "Error style", ansuz.STYLE_ERROR)
        y += 1
        ansuz.text(ctx, 4, y, "Success style", ansuz.STYLE_SUCCESS)
        y += 1
        ansuz.text(ctx, 4, y, "Warning style", ansuz.STYLE_WARNING)
        y += 1
        ansuz.text(ctx, 4, y, "Info style", ansuz.STYLE_INFO)

        // Draw footer
        footer_y := height - 1
        ansuz.rect(ctx, 0, footer_y, width, 1, ' ',
                   ansuz.Style{.White, .Black, {}})
        ansuz.text(ctx, 2, footer_y,
                   "Rendering complete screen each frame (no diffing)",
                   ansuz.Style{.BrightGreen, .Black, {}})

        // Finish frame - this will render the complete buffer to terminal
        ansuz.end_frame(ctx)

        frame_count += 1
    }
}
