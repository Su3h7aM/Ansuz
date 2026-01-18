package main

import ansuz "../ansuz"
import "core:fmt"
import "core:strings"

main :: proc() {
    ctx, err := ansuz.init()
    if err != .None {
        fmt.eprintln("Failed to init:", err)
        return
    }
    defer ansuz.shutdown(ctx)

    state := DemoState{
        running = true,
        scroll_y = 0,
        active_tab = 0,
    }

    for state.running {
        // Input
        events := ansuz.poll_events(ctx)
        for ev in events {
            #partial switch e in ev {
            case ansuz.KeyEvent:
                if e.key == .Escape || (e.key == .Char && e.rune == 'q') {
                    state.running = false
                }
                if e.key == .Up {
                    state.scroll_y = max(0, state.scroll_y - 1)
                }
                if e.key == .Down {
                    state.scroll_y += 1
                }
                if e.key == .Tab {
                    state.active_tab = (state.active_tab + 1) % 3
                }
            }
        }

        // Draw
        ansuz.begin_frame(ctx)
        ansuz.begin_layout(ctx)

        // Root Container: Column, cleaning filling screen
        ansuz.Layout_begin_container(ctx, {
            direction = .TopToBottom,
            sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
            padding = ansuz.Padding_all(1),
            gap = 1,
        })

            // 1. Header (Fixed Height)
            ansuz.Layout_box(ctx, ansuz.STYLE_INFO, {
                direction = .LeftToRight,
                sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(3)},
                padding = ansuz.Padding_all(1),
                alignment = {horizontal = .Center, vertical = .Center},
            })
                ansuz.Layout_text(ctx, "ANSUZ FEATURES DEMO", ansuz.STYLE_BOLD)
                ansuz.Layout_text(ctx, "| Tab: Switch View | Arrows: Scroll", ansuz.STYLE_DIM)
            ansuz.Layout_end_box(ctx)

            // 2. Main Content (Grow)
            ansuz.Layout_begin_container(ctx, {
                direction = .LeftToRight,
                sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
                gap = 2,
            })
            
                // Sidebar (Fixed Width)
                ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
                   direction = .TopToBottom,
                   sizing = {ansuz.Sizing_fixed(20), ansuz.Sizing_grow()},
                   padding = ansuz.Padding_all(1),
                   gap = 1,
                }, .Double) // Double border
                    ansuz.Layout_text(ctx, "Navigation", ansuz.STYLE_UNDERLINE)
                    render_nav_item(ctx, "Weighted Grow", 0, state.active_tab)
                    render_nav_item(ctx, "Scrolling", 1, state.active_tab)
                    render_nav_item(ctx, "Alignment", 2, state.active_tab)
                ansuz.Layout_end_box(ctx)

                // View Area (Grow)
                ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
                    direction = .TopToBottom,
                    sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
                    padding = ansuz.Padding_all(1),
                }, .Rounded)
                
                    switch state.active_tab {
                    case 0: render_weighted_grow_view(ctx)
                    case 1: render_scrolling_view(ctx, &state)
                    case 2: render_alignment_view(ctx)
                    }
                    
                ansuz.Layout_end_box(ctx)
            
            ansuz.Layout_end_container(ctx)

            // 3. Footer (Fixed Height)
            ansuz.Layout_box(ctx, ansuz.STYLE_DIM, {
                sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
            })
                ansuz.Layout_text(ctx, "Status: Ready", ansuz.STYLE_NORMAL)
            ansuz.Layout_end_box(ctx)

        ansuz.Layout_end_container(ctx)

        ansuz.end_layout(ctx)
        ansuz.end_frame(ctx)
    }
}

DemoState :: struct {
    running:    bool,
    scroll_y:   int,
    active_tab: int,
}

render_nav_item :: proc(ctx: ^ansuz.Context, label: string, index, active: int) {
    style := ansuz.STYLE_DIM
    prefix := "  "
    if index == active {
        style = ansuz.STYLE_BOLD
        prefix = "> "
    }
    ansuz.Layout_text(ctx, fmt.tprintf("%s%s", prefix, label), style)
}

render_weighted_grow_view :: proc(ctx: ^ansuz.Context) {
    ansuz.Layout_text(ctx, "Weighted Grow (Flex-basis)", ansuz.STYLE_BOLD)
    ansuz.Layout_text(ctx, "Ratio 1:2:1", ansuz.STYLE_DIM)
    
    // Row with 1:2:1 ratio
    ansuz.Layout_begin_container(ctx, {
        direction = .LeftToRight,
        sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(10)}, // Container 10 height
        gap = 1,
    })
        // Weight 1
        ansuz.Layout_box(ctx, ansuz.STYLE_ERROR, {
            sizing = {ansuz.Sizing_grow(1), ansuz.Sizing_grow()},
            alignment = {horizontal = .Center, vertical = .Center},
        })
            ansuz.Layout_text(ctx, "1", ansuz.STYLE_BOLD)
        ansuz.Layout_end_box(ctx)

        // Weight 2
        ansuz.Layout_box(ctx, ansuz.STYLE_SUCCESS, {
            sizing = {ansuz.Sizing_grow(2), ansuz.Sizing_grow()},
            alignment = {horizontal = .Center, vertical = .Center},
        })
            ansuz.Layout_text(ctx, "2", ansuz.STYLE_BOLD)
        ansuz.Layout_end_box(ctx)
        
        // Weight 1
        ansuz.Layout_box(ctx, ansuz.STYLE_ERROR, {
            sizing = {ansuz.Sizing_grow(1), ansuz.Sizing_grow()},
            alignment = {horizontal = .Center, vertical = .Center},
        })
            ansuz.Layout_text(ctx, "1", ansuz.STYLE_BOLD)
        ansuz.Layout_end_box(ctx)
        
    ansuz.Layout_end_container(ctx)
}

render_scrolling_view :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
    ansuz.Layout_text(ctx, "Scrolling Container", ansuz.STYLE_BOLD)
    ansuz.Layout_text(ctx, "Use Up/Down arrows to scroll the box below", ansuz.STYLE_DIM)
    
    // Scrolling Box
    ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
        direction = .TopToBottom,
        sizing = {ansuz.Sizing_percent(0.8), ansuz.Sizing_grow()},
        overflow = .Scroll,
        scroll_offset = {0, state.scroll_y},
        padding = ansuz.Padding_all(1),
    }, .Double)
        for i in 1..=30 {
            style := i % 2 == 0 ? ansuz.STYLE_NORMAL : ansuz.STYLE_DIM
            ansuz.Layout_text(ctx, fmt.tprintf("Line %d: The quick brown fox jumps over the lazy dog", i), style)
        }
    ansuz.Layout_end_box(ctx)
}

render_alignment_view :: proc(ctx: ^ansuz.Context) {
    ansuz.Layout_text(ctx, "Alignment & Centering", ansuz.STYLE_BOLD)
    
    // Grid of alignments
    ansuz.Layout_begin_container(ctx, {
        direction = .LeftToRight,
        sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
        gap = 1,
    })
        // Top Left
        ansuz.Layout_box(ctx, ansuz.STYLE_DIM, {
            sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
            alignment = {horizontal = .Left, vertical = .Top},
        })
            ansuz.Layout_text(ctx, "TL", ansuz.STYLE_NORMAL)
        ansuz.Layout_end_box(ctx)

        // Center
        ansuz.Layout_box(ctx, ansuz.STYLE_SUCCESS, {
            sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
            alignment = {horizontal = .Center, vertical = .Center},
        })
            ansuz.Layout_text(ctx, "Center", ansuz.STYLE_BOLD)
        ansuz.Layout_end_box(ctx)
        
        // Bottom Right
        ansuz.Layout_box(ctx, ansuz.STYLE_DIM, {
            sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
            alignment = {horizontal = .Right, vertical = .Bottom},
        })
            ansuz.Layout_text(ctx, "BR", ansuz.STYLE_NORMAL)
        ansuz.Layout_end_box(ctx)
        
    ansuz.Layout_end_container(ctx)
}
