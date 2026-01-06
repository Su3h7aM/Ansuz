package main

import "core:fmt"
import "core:time"
import ansuz "../ansuz"

// AppState holds the application state
// In immediate mode, your application owns all state
AppState :: struct {
    should_quit: bool,
    frame_count: int,
}

main :: proc() {
    // Initialize the Ansuz context
    ctx, err := ansuz.init()
    if err != .None {
        fmt.eprintln("Failed to initialize Ansuz:", err)
        return
    }
    defer ansuz.shutdown(ctx)

    // Application state
    app := AppState{
        should_quit = false,
        frame_count = 0,
    }

    fmt.println("Ansuz Hello World - Press Ctrl+C to exit")

    // Main event loop
    for !app.should_quit {
        // Handle input events
        events := ansuz.poll_events(ctx)
        for event in events {
            handle_event(&app, event)
        }

        // Render UI
        render_ui(ctx, &app)

        // Small delay to avoid consuming too much CPU
        // In a real application, you'd implement proper frame timing
        time.sleep(16 * time.Millisecond) // ~60 FPS
    }
}

// handle_event processes input events and updates application state
handle_event :: proc(app: ^AppState, event: ansuz.Event) {
    switch e in event {
    case ansuz.KeyEvent:
        // Check for quit keys
        if e.key == .Ctrl_C || e.key == .Ctrl_D {
            app.should_quit = true
        }
    case ansuz.ResizeEvent:
        // Handle resize events if needed
        // For now, just ignore - the next frame will handle it
    case ansuz.MouseEvent:
        // Handle mouse events if needed
        // For now, just ignore
    }
}

// render_ui draws the user interface
// This follows the immediate mode pattern: declare what should be visible based on current state
render_ui :: proc(ctx: ^ansuz.Context, app: ^AppState) {
    ansuz.begin_frame(ctx)
    defer ansuz.end_frame(ctx)

    width, height := ansuz.get_size(ctx)

    // Calculate centered position for our box
    box_width :: 50
    box_height :: 10
    box_x := (width - box_width) / 2
    box_y := (height - box_height) / 2

    // Draw a colored background box
    ansuz.rect(ctx, box_x, box_y, box_width, box_height, ' ', 
        ansuz.Style{
            fg_color = .Default,
            bg_color = .Blue,
            flags = {},
        })

    // Draw a border around the box
    ansuz.box(ctx, box_x, box_y, box_width, box_height,
        ansuz.Style{
            fg_color = .BrightCyan,
            bg_color = .Blue,
            flags = {.Bold},
        })

    // Draw the main title
    title :: "Hello, Ansuz!"
    title_x := box_x + (box_width - len(title)) / 2
    title_y := box_y + 2
    ansuz.text(ctx, title_x, title_y, title, 
        ansuz.Style{
            fg_color = .BrightYellow,
            bg_color = .Blue,
            flags = {.Bold},
        })

    // Draw subtitle
    subtitle :: "A TUI Library for Odin"
    subtitle_x := box_x + (box_width - len(subtitle)) / 2
    subtitle_y := box_y + 4
    ansuz.text(ctx, subtitle_x, subtitle_y, subtitle,
        ansuz.Style{
            fg_color = .White,
            bg_color = .Blue,
            flags = {},
        })

    // Draw frame counter
    frame_text := fmt.tprintf("Frame: %d", app.frame_count)
    frame_x := box_x + (box_width - len(frame_text)) / 2
    frame_y := box_y + 6
    ansuz.text(ctx, frame_x, frame_y, frame_text,
        ansuz.Style{
            fg_color = .BrightGreen,
            bg_color = .Blue,
            flags = {},
        })

    // Draw instructions
    instruction :: "Press Ctrl+C to exit"
    instruction_x := box_x + (box_width - len(instruction)) / 2
    instruction_y := box_y + box_height - 2
    ansuz.text(ctx, instruction_x, instruction_y, instruction,
        ansuz.Style{
            fg_color = .BrightBlack,
            bg_color = .Blue,
            flags = {.Dim},
        })

    // Draw a status bar at the bottom of the screen
    status :: "Ansuz MVP - Immediate Mode TUI"
    status_y := height - 1
    ansuz.rect(ctx, 0, status_y, width, 1, ' ',
        ansuz.Style{
            fg_color = .White,
            bg_color = .Magenta,
            flags = {},
        })
    ansuz.text(ctx, 2, status_y, status,
        ansuz.Style{
            fg_color = .White,
            bg_color = .Magenta,
            flags = {.Bold},
        })

    // Terminal size indicator
    size_text := fmt.tprintf("Terminal: %dx%d", width, height)
    size_x := width - len(size_text) - 2
    ansuz.text(ctx, size_x, status_y, size_text,
        ansuz.Style{
            fg_color = .White,
            bg_color = .Magenta,
            flags = {},
        })

    app.frame_count += 1
}
