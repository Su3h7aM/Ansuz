package main

import ansuz "../ansuz"
import "core:fmt"
import "core:time"
import "core:strings"

// DemoState holds the application state
DemoState :: struct {
	fps:           f32,
	frame_time:     time.Duration,
	frame_count:    u64,
	last_time:      time.Time,
	running:        bool,
	selected_tab:   int,
	theme_color:    int,
	progress:       f32,
	anim_direction: int,
}

main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to initialize Ansuz:", err)
		return
	}
	defer ansuz.shutdown(ctx)

	state := DemoState{
		fps = 0.0,
		frame_time = 0,
		frame_count = 0,
		last_time = time.now(),
		running = true,
		selected_tab = 0,
		theme_color = 0,
		progress = 0.0,
		anim_direction = 1,
	}

	fmt.println("\x1b[?25l") // Hide cursor before demo starts
	defer fmt.println("\x1b[?25h") // Show cursor on exit

	for state.running {
		start_time := time.now()

		// Handle input
		events := ansuz.poll_events(ctx)
		for ev in events {
			handle_input(&state, ev)
		}

		// Update state
		update_state(&state)

		// Render
		render_demo(ctx, &state)

		// Calculate FPS
		end_time := time.now()
		frame_duration := time.diff(end_time, start_time)
		frame_elapsed := time.diff(end_time, state.last_time)

		state.frame_count += 1
		if frame_elapsed >= time.Second {
			state.fps = f32(state.frame_count) / f32(frame_elapsed / time.Second)
			state.frame_count = 0
			state.last_time = end_time
		}
		state.frame_time = frame_duration
	}
}

handle_input :: proc(state: ^DemoState, event: ansuz.Event) {
	#partial switch e in event {
	case ansuz.KeyEvent:
		#partial switch e.key {
		case .Ctrl_C, .Ctrl_D, .Escape:
			state.running = false
		case .Right:
			state.selected_tab = (state.selected_tab + 1) % 3
		case .Left:
			state.selected_tab = (state.selected_tab - 1 + 3) % 3
		case .Up:
			state.theme_color = (state.theme_color + 1) % 4
		case .Down:
			state.theme_color = (state.theme_color - 1 + 4) % 4
		case .Char:
			switch e.rune {
			case '1', '2', '3':
				state.selected_tab = int(e.rune) - '1'
			case 'l', 'L':
				state.selected_tab = (state.selected_tab + 1) % 3
			case 'h', 'H':
				state.selected_tab = (state.selected_tab - 1 + 3) % 3
			case 'k', 'K':
				state.theme_color = (state.theme_color + 1) % 4
			case 'j', 'J':
				state.theme_color = (state.theme_color - 1 + 4) % 4
			case 'q', 'Q':
				state.running = false
			}
		}
	case ansuz.ResizeEvent:
		// Handled automatically in begin_frame
	case ansuz.MouseEvent:
		// Not implemented
	}
}

update_state :: proc(state: ^DemoState) {
	// Animate progress bar
	state.progress += 0.02 * f32(state.anim_direction)
	if state.progress >= 1.0 {
		state.progress = 1.0
		state.anim_direction = -1
	} else if state.progress <= 0.0 {
		state.progress = 0.0
		state.anim_direction = 1
	}
}

render_demo :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.begin_frame(ctx)
	defer ansuz.end_frame(ctx)

	ansuz.begin_layout(ctx)
	defer ansuz.end_layout(ctx)

	width, height := ansuz.get_size(ctx)

	// Main container
	ansuz.layout_begin_container(ctx, {
		direction = .TopToBottom,
		sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
		padding = {left = 1, right = 1, top = 0, bottom = 0},
		gap = 1,
	})

		// Header
		render_header(ctx, state)

		// Content area
		ansuz.layout_begin_container(ctx, {
			direction = .LeftToRight,
			sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
			gap = 2,
			padding = {left = 0, right = 0, top = 0, bottom = 1},
		})

			// Left sidebar
			render_sidebar(ctx, state)

			// Main content (tabbed)
			render_content_area(ctx, state)

		ansuz.layout_end_container(ctx)

		// Footer
		render_footer(ctx, state)

	ansuz.layout_end_container(ctx)
}

render_header :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.layout_begin_container(ctx, {
		direction = .LeftToRight,
		sizing = {ansuz.sizing_grow(), ansuz.sizing_fixed(3)},
		gap = 2,
		padding = ansuz.padding_all(1),
		alignment = {horizontal = .Center, vertical = .Center},
	})

		// Title
		ansuz.layout_begin_container(ctx, {
			direction = .TopToBottom,
			sizing = {ansuz.sizing_fit(), ansuz.sizing_fixed(3)},
			alignment = {horizontal = .Center, vertical = .Center},
		})
		ansuz.layout_text(ctx, "ANSUZ COMPLEX DEMO", get_theme_style(.Bold, state.theme_color))
		ansuz.layout_text(ctx, "Terminal UI Library for Odin", ansuz.STYLE_DIM)
		ansuz.layout_end_container(ctx)

		// Stats
		fps_text := fmt.tprintf("FPS: %.1f", state.fps)
		frame_text := fmt.tprintf("Frame: %s", format_duration(state.frame_time))
		size_width, size_height := ansuz.get_size(ctx)
		size_text := fmt.tprintf("Size: %dx%d", size_width, size_height)

		ansuz.layout_begin_container(ctx, {
			direction = .TopToBottom,
			sizing = {ansuz.sizing_fixed(25), ansuz.sizing_fixed(3)},
			alignment = {horizontal = .Right, vertical = .Center},
			gap = 0,
		})
		ansuz.layout_text(ctx, fps_text, get_stat_style())
		ansuz.layout_text(ctx, frame_text, get_stat_style())
		ansuz.layout_text(ctx, size_text, get_stat_style())
		ansuz.layout_end_container(ctx)

	ansuz.layout_end_container(ctx)

	// Separator
	ansuz.layout_rect(ctx, '─', ansuz.STYLE_DIM, {
		sizing = {ansuz.sizing_grow(), ansuz.sizing_fixed(1)},
	})
}

render_sidebar :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.layout_begin_container(ctx, {
		direction = .TopToBottom,
		sizing = {ansuz.sizing_percent(0.25), ansuz.sizing_grow()},
		gap = 1,
		padding = ansuz.padding_all(1),
	})

		// Navigation
		ansuz.layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
			sizing = {ansuz.sizing_grow(), ansuz.sizing_fixed(7)},
			padding = ansuz.padding_all(1),
		})
		ansuz.layout_begin_container(ctx, {
			direction = .TopToBottom,
			sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
			gap = 1,
		})
		render_tab(ctx, "Dashboard", 0, state.selected_tab, state.theme_color)
		render_tab(ctx, "Terminal", 1, state.selected_tab, state.theme_color)
		render_tab(ctx, "Settings", 2, state.selected_tab, state.theme_color)
		ansuz.layout_end_container(ctx)

		// Theme selector
		ansuz.layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
			sizing = {ansuz.sizing_grow(), ansuz.sizing_fit()},
			padding = ansuz.padding_all(1),
		})
		ansuz.layout_text(ctx, "Theme Colors", ansuz.STYLE_BOLD)
		ansuz.layout_text(ctx, "", ansuz.STYLE_DIM)
		render_theme_option(ctx, "Red Theme", 0, state.theme_color, state.theme_color)
		render_theme_option(ctx, "Green Theme", 1, state.theme_color, state.theme_color)
		render_theme_option(ctx, "Blue Theme", 2, state.theme_color, state.theme_color)
		render_theme_option(ctx, "Yellow Theme", 3, state.theme_color, state.theme_color)

	ansuz.layout_end_container(ctx)
}

	render_tab :: proc(ctx: ^ansuz.Context, label: string, index, selected, theme_color: int) {
	style := ansuz.STYLE_NORMAL
	builder := strings.builder_make(context.temp_allocator)

	if index == selected {
		style = get_theme_style(.Bold, theme_color)
		strings.write_string(&builder, "► ")
	} else {
		strings.write_string(&builder, "  ")
	}
	strings.write_string(&builder, label)

	ansuz.layout_text(ctx, strings.to_string(builder), style)
}

	render_theme_option :: proc(ctx: ^ansuz.Context, label: string, index, selected, theme_color: int) {
	style := ansuz.STYLE_NORMAL
	builder := strings.builder_make(context.temp_allocator)

	if index == selected {
		strings.write_string(&builder, "✓ ")
		style = get_theme_style(.Normal, theme_color)
	} else {
		strings.write_string(&builder, "  ")
	}
	strings.write_string(&builder, label)

	ansuz.layout_text(ctx, strings.to_string(builder), style)
}

render_content_area :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.layout_begin_container(ctx, {
		direction = .TopToBottom,
		sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
		gap = 1,
		padding = ansuz.padding_all(1),
	})

		switch state.selected_tab {
		case 0:
			render_dashboard_tab(ctx, state)
		case 1:
			render_terminal_tab(ctx, state)
		case 2:
			render_settings_tab(ctx, state)
		}

	ansuz.layout_end_container(ctx)
}

render_dashboard_tab :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	// Progress section
		ansuz.layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
			sizing = {ansuz.sizing_grow(), ansuz.sizing_fit()},
			padding = ansuz.padding_all(1),
		})
	ansuz.layout_begin_container(ctx, {
		direction = .TopToBottom,
		sizing = {ansuz.sizing_grow(), ansuz.sizing_fit()},
		gap = 1,
	})
		ansuz.layout_text(ctx, "System Status", ansuz.STYLE_BOLD)
		ansuz.layout_text(ctx, "", ansuz.STYLE_DIM)

		// Progress bar
		ansuz.layout_text(ctx, "Processing:", ansuz.STYLE_NORMAL)
		ansuz.layout_begin_container(ctx, {
			direction = .LeftToRight,
			sizing = {ansuz.sizing_grow(), ansuz.sizing_fixed(1)},
		})
			// Progress background
			ansuz.layout_rect(ctx, '░', ansuz.STYLE_DIM, {
				sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
			})
			// Progress fill
			fill_width := int(state.progress * 100)
			if fill_width > 0 {
				ansuz.layout_rect(ctx, '█', get_theme_style(.Normal, state.theme_color), {
					sizing = {ansuz.sizing_percent(state.progress), ansuz.sizing_grow()},
				})
			}
		ansuz.layout_end_container(ctx)
		ansuz.layout_text(ctx, fmt.tprintf("%.0f%% Complete", state.progress * 100), ansuz.STYLE_DIM)

	ansuz.layout_end_container(ctx)

	// Stats boxes
	ansuz.layout_begin_container(ctx, {
		direction = .LeftToRight,
		sizing = {ansuz.sizing_grow(), ansuz.sizing_fit()},
		gap = 1,
	})
		render_stat_box(ctx, "CPU Usage", "45%", ansuz.STYLE_INFO)
		render_stat_box(ctx, "Memory", "2.4 GB", ansuz.STYLE_SUCCESS)
		render_stat_box(ctx, "Network", "1.2 MB/s", ansuz.STYLE_WARNING)
	ansuz.layout_end_container(ctx)
}

render_stat_box :: proc(ctx: ^ansuz.Context, label: string, value: string, style: ansuz.Style) {
	ansuz.layout_box(ctx, style, {
		sizing = {ansuz.sizing_grow(), ansuz.sizing_fit()},
		padding = ansuz.padding_all(1),
	})
	ansuz.layout_begin_container(ctx, {
		direction = .TopToBottom,
		sizing = {ansuz.sizing_grow(), ansuz.sizing_fit()},
		alignment = {horizontal = .Center, vertical = .Center},
	})
		ansuz.layout_text(ctx, label, ansuz.STYLE_DIM)
		ansuz.layout_text(ctx, value, style)
	ansuz.layout_end_container(ctx)
}

render_terminal_tab :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
		sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
		padding = ansuz.padding_all(1),
	})
	ansuz.layout_begin_container(ctx, {
		direction = .TopToBottom,
		sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
	})
		ansuz.layout_text(ctx, "Terminal Output", ansuz.STYLE_BOLD)
		ansuz.layout_text(ctx, "", ansuz.STYLE_DIM)
		ansuz.layout_text(ctx, "$ ./ansuz_demo", ansuz.STYLE_NORMAL)
		ansuz.layout_text(ctx, "> Initializing system...", ansuz.STYLE_SUCCESS)
		ansuz.layout_text(ctx, "> Loading modules...", ansuz.STYLE_SUCCESS)
		ansuz.layout_text(ctx, "> Starting services...", ansuz.STYLE_SUCCESS)
		ansuz.layout_text(ctx, "> Ready!", ansuz.STYLE_SUCCESS)
		ansuz.layout_text(ctx, "", ansuz.STYLE_DIM)
		ansuz.layout_text(ctx, "Press Tab to cycle views", ansuz.STYLE_DIM)
		ansuz.layout_text(ctx, "Press Arrow keys to navigate", ansuz.STYLE_DIM)
	ansuz.layout_end_container(ctx)
}

render_settings_tab :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
		sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
		padding = ansuz.padding_all(1),
	})
	ansuz.layout_begin_container(ctx, {
		direction = .TopToBottom,
		sizing = {ansuz.sizing_grow(), ansuz.sizing_grow()},
		gap = 1,
	})
		ansuz.layout_text(ctx, "Settings", ansuz.STYLE_BOLD)
		ansuz.layout_text(ctx, "", ansuz.STYLE_DIM)
		ansuz.layout_text(ctx, "[x] Enable animations", ansuz.STYLE_NORMAL)
		ansuz.layout_text(ctx, "[ ] Enable sounds", ansuz.STYLE_NORMAL)
		ansuz.layout_text(ctx, "[x] Show FPS counter", ansuz.STYLE_NORMAL)
		ansuz.layout_text(ctx, "[ ] Debug mode", ansuz.STYLE_NORMAL)
		ansuz.layout_text(ctx, "", ansuz.STYLE_DIM)
		theme_names := [?]string{"Red", "Green", "Blue", "Yellow"}
		theme_text := fmt.tprintf("Theme: %s", theme_names[state.theme_color])
		ansuz.layout_text(ctx, theme_text, ansuz.STYLE_NORMAL)
		ansuz.layout_text(ctx, "Font size: 12px", ansuz.STYLE_NORMAL)
	ansuz.layout_end_container(ctx)
}

render_footer :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.layout_begin_container(ctx, {
		direction = .LeftToRight,
		sizing = {ansuz.sizing_grow(), ansuz.sizing_fixed(1)},
		padding = {left = 1, right = 1, top = 0, bottom = 0},
	})

		// Left side: Controls
		ansuz.layout_begin_container(ctx, {
			direction = .LeftToRight,
			sizing = {ansuz.sizing_fit(), ansuz.sizing_grow()},
			gap = 2,
			alignment = {horizontal = .Left, vertical = .Center},
		})
		ansuz.layout_text(ctx, "[Tab] Views", ansuz.STYLE_DIM)
		ansuz.layout_text(ctx, "[←→] Tabs", ansuz.STYLE_DIM)
		ansuz.layout_text(ctx, "[↑↓] Theme", ansuz.STYLE_DIM)
		ansuz.layout_text(ctx, "[Q] Quit", ansuz.STYLE_WARNING)
		ansuz.layout_end_container(ctx)

		// Right side: Status
		ansuz.layout_text(ctx, "● Connected", ansuz.STYLE_SUCCESS)

	ansuz.layout_end_container(ctx)
}

// Helper functions

ThemeStyle :: enum {
	Normal,
	Bold,
}

get_theme_style :: proc(variant: ThemeStyle, theme_color: int) -> ansuz.Style {
	theme_colors := [?]ansuz.Color{
		ansuz.Color.Red,      // 0: Red theme
		ansuz.Color.Green,    // 1: Green theme
		ansuz.Color.Blue,     // 2: Blue theme
		ansuz.Color.Yellow,   // 3: Yellow theme
	}

	colors := [?]ansuz.Color{
		ansuz.Color.Red,
		ansuz.Color.BrightRed,
		ansuz.Color.Green,
		ansuz.Color.BrightGreen,
		ansuz.Color.Blue,
		ansuz.Color.BrightBlue,
		ansuz.Color.Yellow,
		ansuz.Color.BrightYellow,
	}

	base_idx := theme_color * 2
	if variant == .Bold {
		return ansuz.Style{
			fg_color = colors[base_idx + 1],
			bg_color = .Default,
			flags = {.Bold},
		}
	}
	return ansuz.Style{
		fg_color = colors[base_idx],
		bg_color = .Default,
		flags = {},
	}
}

get_stat_style :: proc() -> ansuz.Style {
	return ansuz.Style{
		fg_color = .Cyan,
		bg_color = .Default,
		flags = {.Dim},
	}
}

format_duration :: proc(d: time.Duration) -> string {
	micros := d / time.Microsecond
	if micros < 1000 {
		return fmt.tprintf("%dμs", micros)
	}
	millis := d / time.Millisecond
	if millis < 1000 {
		return fmt.tprintf("%dms", millis)
	}
	seconds := f32(d) / f32(time.Second)
	return fmt.tprintf("%.2fs", seconds)
}
