// Hello World Example for Ansuz TUI Library
// Demonstrates event-driven rendering with the run() API

package main

import "core:fmt"
import ansuz "../ansuz"

// AppState holds application state
AppState :: struct {
    frame_count: u64,
}

// Global app state (needed for closure capture in Odin)
g_app: AppState

main :: proc() {
    // Initialize Ansuz
    ctx, err := ansuz.init()
    if err != .None {
        return
    }
    defer ansuz.shutdown(ctx)

    // Initialize application state
    g_app = AppState{
        frame_count = 0,
    }

    // Event-driven main loop
    // Callback is called whenever an event occurs (input, resize)
    ansuz.run(ctx, update)
}

// update handles events and renders - called by ansuz.run()
update :: proc(ctx: ^ansuz.Context) -> bool {
    // Handle input events
    for event in ansuz.poll_events(ctx) {
        switch e in event {
        case ansuz.KeyEvent:
            // Quit on Ctrl+C or Ctrl+D
            if e.key == .Ctrl_C || e.key == .Ctrl_D {
                return false
            }
        case ansuz.ResizeEvent:
            // Resize handled automatically by run()
        case ansuz.MouseEvent:
            // Ignore mouse for now
        }
    }

    // Render UI - run() handles begin_frame/end_frame
    render_content(ctx)
    g_app.frame_count += 1
    
    return true  // Continue running
}

// render_content draws the UI content
render_content :: proc(ctx: ^ansuz.Context) {
    width, height := ansuz.get_size(ctx)

    // Calculate centered position for box
    box_width :: 50
    box_height :: 10
    box_x := (width - box_width) / 2
    box_y := (height - box_height) / 2

    // Draw blue background
    ansuz.rect(ctx, box_x, box_y, box_width, box_height, ' ', 
        ansuz.Style{
            fg_color = .Default,
            bg_color = .Blue,
            flags = {},
        })

    // Draw border
    ansuz.box(ctx, box_x, box_y, box_width, box_height,
        ansuz.Style{
            fg_color = .BrightCyan,
            bg_color = .Blue,
            flags = {},
        })

    // Draw title
    title := "Hello, Ansuz!"
    title_x := box_x + (box_width - len(title)) / 2
    title_y := box_y + 2
    ansuz.text(ctx, title_x, title_y, title,
        ansuz.Style{
            fg_color = .BrightWhite,
            bg_color = .Blue,
            flags = {.Bold},
        })

    // Draw instructions
    instructions := "Press Ctrl+C to exit"
    inst_x := box_x + (box_width - len(instructions)) / 2
    inst_y := box_y + 4
    ansuz.text(ctx, inst_x, inst_y, instructions,
        ansuz.Style{
            fg_color = .White,
            bg_color = .Blue,
            flags = {},
        })

    // Display dimensions
    size_text := fmt.tprintf("Size: %dx%d | Frame: %d", width, height, g_app.frame_count)
    size_x := box_x + (box_width - len(size_text)) / 2
    size_y := box_y + 6
    ansuz.text(ctx, size_x, size_y, size_text,
        ansuz.Style{
            fg_color = .Yellow,
            bg_color = .Blue,
            flags = {},
        })
}
