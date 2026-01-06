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
        ansuz.layout_begin_container(ctx, {
            direction = .LeftToRight,
            sizing = {ansuz.sizing_grow(), ansuz.sizing_fixed(3)},
            padding = ansuz.padding_all(1),
            alignment = {horizontal = .Center, vertical = .Center},
            gap = 2,
        })
        ansuz.layout_text(ctx, "ANSUZ LAYOUT SYSTEM", ansuz.STYLE_BOLD)
        ansuz.layout_text(ctx, "(Press 'q' to quit)", ansuz.STYLE_DIM)
        ansuz.layout_end_container(ctx)
        
        // Main content area
        ansuz.layout_begin_container(ctx, {
            direction = .LeftToRight,
            sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
            gap = 1,
            padding = ansuz.padding_all(1),
        })
        
            // Sidebar
            ansuz.layout_begin_container(ctx, {
                direction = .TopToBottom,
                sizing = {ansuz.sizing_percent(0.2), ansuz.sizing_grow()},
                gap = 1,
            })
                ansuz.layout_box(ctx, ansuz.STYLE_INFO, {
                    sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
                    padding = ansuz.padding_all(1),
                })
                // We'd need a way to put text inside that box in the layout system...
                // Currently box is a leaf node. 
                // In clay, you'd use a container with a border.
            ansuz.layout_end_container(ctx)
            
            // Content
            ansuz.layout_begin_container(ctx, {
                direction = .TopToBottom,
                sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
                gap = 1,
            })
                ansuz.layout_begin_container(ctx, {
                    direction = .TopToBottom,
                    sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
                    padding = ansuz.padding_all(1),
                    alignment = {horizontal = .Center, vertical = .Center},
                })
                    ansuz.layout_text(ctx, "Centered Content", ansuz.STYLE_SUCCESS)
                    ansuz.layout_rect(ctx, '-', ansuz.STYLE_DIM, {
                        sizing = {ansuz.sizing_fixed(20), ansuz.sizing_fixed(1)},
                    })
                    ansuz.layout_text(ctx, "This layout is calculated using a Clay-inspired system.", ansuz.STYLE_NORMAL)
                ansuz.layout_end_container(ctx)
                
                ansuz.layout_begin_container(ctx, {
                    direction = .LeftToRight,
                    sizing = {ansuz.sizing_grow(), ansuz.sizing_fixed(5)},
                    gap = 3,
                })
                    ansuz.layout_box(ctx, ansuz.STYLE_WARNING, {sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()}})
                    ansuz.layout_box(ctx, ansuz.STYLE_ERROR, {sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()}})
                    ansuz.layout_box(ctx, ansuz.STYLE_INFO, {sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()}})
                ansuz.layout_end_container(ctx)
                
            ansuz.layout_end_container(ctx)
            
        ansuz.layout_end_container(ctx)
        
        // Footer
        ansuz.layout_begin_container(ctx, {
            direction = .LeftToRight,
            sizing = {ansuz.sizing_grow(), ansuz.sizing_fixed(1)},
            padding = {left = 2, right = 2, top = 0, bottom = 0},
            alignment = {horizontal = .Right, vertical = .Top},
        })
            ansuz.layout_text(ctx, "Status: OK", ansuz.STYLE_INFO)
        ansuz.layout_end_container(ctx)
        
        ansuz.end_layout(ctx)
        
        ansuz.end_frame(ctx)
    }
}
