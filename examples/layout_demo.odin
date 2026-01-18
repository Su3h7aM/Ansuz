package main

import ansuz "../ansuz"
import "core:fmt"

main :: proc() {
    ctx, err := ansuz.init()
    if err != .None {
        fmt.printf("Failed to initialize Ansuz: %v\n", err)
        return
    }
    defer ansuz.shutdown(ctx)

    running := true
    scroll_y := 0

    for running {
        // Handle input
        events := ansuz.poll_events(ctx)
        for ev in events {
            #partial switch e in ev {
            case ansuz.KeyEvent:
                if e.key == .Escape || (e.key == .Char && e.rune == 'q') {
                    running = false
                }
                if e.key == .Up {
                    scroll_y = max(0, scroll_y - 1)
                }
                if e.key == .Down {
                    scroll_y += 1
                }
            }
        }

        // Render
        ansuz.begin_frame(ctx)
        
        ansuz.begin_layout(ctx)
        
        // Header
        ansuz.Layout_begin_container(ctx, {
            direction = .LeftToRight,
            sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(3)},
            padding = ansuz.Padding_all(1),
            alignment = {horizontal = .Center, vertical = .Center},
            gap = 2,
        })
        ansuz.Layout_text(ctx, "ANSUZ LAYOUT SYSTEM", ansuz.STYLE_BOLD)
        ansuz.Layout_text(ctx, "(Press 'q' to quit, Arrows to Scroll)", ansuz.STYLE_DIM)
        ansuz.Layout_end_container(ctx)
        
        // Main content area
        ansuz.Layout_begin_container(ctx, {
            direction = .LeftToRight,
            sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
            gap = 1,
            padding = ansuz.Padding_all(1),
        })
        
            // Sidebar (Weighted Grow Example)
            ansuz.Layout_begin_container(ctx, {
                direction = .TopToBottom,
                sizing = {ansuz.Sizing_grow(1), ansuz.Sizing_grow()}, // Weight 1
                gap = 1,
            })
                ansuz.Layout_box(ctx, ansuz.STYLE_INFO, {
                    sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
                    padding = ansuz.Padding_all(1),
                })
                ansuz.Layout_end_box(ctx)
                ansuz.Layout_text(ctx, "Sidebar (Weight 1)", ansuz.STYLE_DIM)
            ansuz.Layout_end_container(ctx)
            
            // Content (Weighted Grow Example)
            ansuz.Layout_begin_container(ctx, {
                direction = .TopToBottom,
                sizing = {ansuz.Sizing_grow(3), ansuz.Sizing_grow()}, // Weight 3
                gap = 1,
            })
                ansuz.Layout_begin_container(ctx, {
                    direction = .TopToBottom,
                    sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
                    padding = ansuz.Padding_all(1),
                    alignment = {horizontal = .Center, vertical = .Center},
                })
                    ansuz.Layout_text(ctx, "Weighted Grow Example (Weight 3)", ansuz.STYLE_SUCCESS)
                    
                    // Scrolling Container Example
                    ansuz.Layout_text(ctx, "Scrolling Container (arrows):", ansuz.STYLE_NORMAL)
                    ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
                        sizing = {ansuz.Sizing_percent(0.8), ansuz.Sizing_fixed(10)},
                        overflow = .Scroll,
                        scroll_offset = {0, scroll_y},
                    })
                        // Scrollable content
                        for i in 1..=20 {
                            ansuz.Layout_text(ctx, fmt.tprintf("Scrollable Item %d", i), ansuz.STYLE_DIM)
                        }
                    ansuz.Layout_end_box(ctx)
                    
                ansuz.Layout_end_container(ctx)
                
            ansuz.Layout_end_container(ctx)
            
        ansuz.Layout_end_container(ctx)
        
        // Footer
        ansuz.Layout_begin_container(ctx, {
            direction = .LeftToRight,
            sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
            padding = {left = 2, right = 2, top = 0, bottom = 0},
            alignment = {horizontal = .Right, vertical = .Top},
        })
            ansuz.Layout_text(ctx, fmt.tprintf("Scroll Y: %d", scroll_y), ansuz.STYLE_INFO)
        ansuz.Layout_end_container(ctx)
        
        ansuz.end_layout(ctx)
        
        ansuz.end_frame(ctx)
    }
}
