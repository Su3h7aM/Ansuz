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
    for running {
        // Handle input
        events := ansuz.poll_events(ctx)
        for ev in events {
            #partial switch e in ev {
            case ansuz.KeyEvent:
                if e.key == .Escape || (e.key == .Char && e.rune == 'q') {
                    running = false
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
        ansuz.Layout_text(ctx, "(Press 'q' to quit)", ansuz.STYLE_DIM)
        ansuz.Layout_end_container(ctx)
        
        // Main content area
        ansuz.Layout_begin_container(ctx, {
            direction = .LeftToRight,
            sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
            gap = 1,
            padding = ansuz.Padding_all(1),
        })
        
            // Sidebar
            ansuz.Layout_begin_container(ctx, {
                direction = .TopToBottom,
                sizing = {ansuz.Sizing_percent(0.2), ansuz.Sizing_grow()},
                gap = 1,
            })
                ansuz.Layout_box(ctx, ansuz.STYLE_INFO, {
                    sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
                    padding = ansuz.Padding_all(1),
                })
                // We'd need a way to put text inside that box in the layout system...
                // Currently box is a leaf node. 
                // In clay, you'd use a container with a border.
            ansuz.Layout_end_container(ctx)
            
            // Content
            ansuz.Layout_begin_container(ctx, {
                direction = .TopToBottom,
                sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
                gap = 1,
            })
                ansuz.Layout_begin_container(ctx, {
                    direction = .TopToBottom,
                    sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
                    padding = ansuz.Padding_all(1),
                    alignment = {horizontal = .Center, vertical = .Center},
                })
                    ansuz.Layout_text(ctx, "Centered Content", ansuz.STYLE_SUCCESS)
                    ansuz.Layout_rect(ctx, '-', ansuz.STYLE_DIM, {
                        sizing = {ansuz.Sizing_fixed(20), ansuz.Sizing_fixed(1)},
                    })
                    ansuz.Layout_text(ctx, "This layout is calculated using a Clay-inspired system.", ansuz.STYLE_NORMAL)
                ansuz.Layout_end_container(ctx)
                
                ansuz.Layout_begin_container(ctx, {
                    direction = .LeftToRight,
                    sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(5)},
                    gap = 3,
                })
                    ansuz.Layout_box(ctx, ansuz.STYLE_WARNING, {sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()}})
                    ansuz.Layout_box(ctx, ansuz.STYLE_ERROR, {sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()}})
                    ansuz.Layout_box(ctx, ansuz.STYLE_INFO, {sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()}})
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
            ansuz.Layout_text(ctx, "Status: OK", ansuz.STYLE_INFO)
        ansuz.Layout_end_container(ctx)
        
        ansuz.end_layout(ctx)
        
        ansuz.end_frame(ctx)
    }
}
