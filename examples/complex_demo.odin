package main

import ansuz "../ansuz"
import "core:fmt"
import "core:time"
import "core:strings"

// DemoState holds the application state
DemoState :: struct {
	running:             bool,
	selected_tab:        int,
	theme_color:          int,
	progress:             f32,
	anim_direction:        int,
	progress_start_time:   time.Time,
}

main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to initialize Ansuz:", err)
		return
	}
	defer ansuz.shutdown(ctx)

	state := DemoState{
		running = true,
		selected_tab = 0,
		theme_color = 0,
		progress = 0.0,
		anim_direction = 1,
		progress_start_time = time.now(),
	}

	// Enable FPS limiting at 60 FPS
	ansuz.set_target_fps(ctx, 60)

	for state.running {
		start_time := time.now()

		// Handle input
		events := ansuz.poll_events(ctx)
		for ev in events {
			handle_input(&state, ev)
		}

		// Update state (animate progress)
		update_state(&state)

		// Render
		render_demo(ctx, &state)
	}
}

handle_input :: proc(state: ^DemoState, event: ansuz.Event) {
	#partial switch e in event {
	case ansuz.KeyEvent:
		#partial switch e.key {
		case .Ctrl_C, .Ctrl_D, .Escape:
			state.running = false
		case .Tab:
			state.selected_tab = (state.selected_tab + 1) % 3
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
	// Animate progress bar - takes exactly 10 seconds to complete
	current_time := time.now()
	elapsed := f32(time.diff(state.progress_start_time, current_time)) / f32(time.Second)

	if state.anim_direction == 1 {
		// Growing: 0% -> 100%
		state.progress = min(elapsed / 10.0, 1.0)
		if state.progress >= 1.0 {
			state.progress = 1.0
			state.anim_direction = -1
			state.progress_start_time = current_time
		}
	} else {
		// Shrinking: 100% -> 0%
		state.progress = 1.0 - min(elapsed / 10.0, 1.0)
		if state.progress <= 0.0 {
			state.progress = 0.0
			state.anim_direction = 1
			state.progress_start_time = current_time
		}
	}
}

render_demo :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.begin_frame(ctx)
	defer ansuz.end_frame(ctx)

	ansuz.begin_layout(ctx)
	defer ansuz.end_layout(ctx)

	width, height := ansuz.get_size(ctx)

	// Main container
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
		padding = {left = 1, right = 1, top = 0, bottom = 0},
		gap = 1,
	}, .Rounded)

		// Header
		render_header(ctx, state)

		// Content area
		ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
			direction = .LeftToRight,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
			gap = 2,
			padding = {left = 0, right = 0, top = 0, bottom = 1},
		}, .Rounded)

			// Left sidebar
			render_sidebar(ctx, state)

			// Main content (tabbed)
			render_content_area(ctx, state)

		ansuz.Layout_end_box(ctx)

		// Footer
		render_footer(ctx, state)

	ansuz.Layout_end_box(ctx)
}

render_header :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.Layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
		direction = .LeftToRight,
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(3)},
		gap = 2,
		padding = ansuz.Padding_all(1),
		alignment = {horizontal = .Center, vertical = .Center},
	}, .Rounded)

		// Title
		ansuz.Layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
			direction = .TopToBottom,
			sizing = {ansuz.Sizing_fit(), ansuz.Sizing_fixed(3)},
			alignment = {horizontal = .Center, vertical = .Center},
		}, .Rounded)
			ansuz.Layout_text(ctx, "ANSUZ COMPLEX DEMO", get_theme_style(.Bold, state.theme_color))
			ansuz.Layout_text(ctx, "Terminal UI Library for Odin", ansuz.STYLE_DIM)
		ansuz.Layout_end_box(ctx)

		// Stats
		fps_text := fmt.tprintf("FPS: %.1f", ansuz.get_fps(ctx))
		frame_text := fmt.tprintf("Frame Time: %s", format_duration(ansuz.get_last_frame_time(ctx)))
		size_width, size_height := ansuz.get_size(ctx)
		size_text := fmt.tprintf("Size: %dx%d", size_width, size_height)

		ansuz.Layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
			direction = .TopToBottom,
			sizing = {ansuz.Sizing_fixed(25), ansuz.Sizing_fixed(3)},
			alignment = {horizontal = .Right, vertical = .Center},
			gap = 0,
		}, .Rounded)
			ansuz.Layout_text(ctx, fps_text, get_stat_style())
			ansuz.Layout_text(ctx, frame_text, get_stat_style())
			ansuz.Layout_text(ctx, size_text, get_stat_style())
		ansuz.Layout_end_box(ctx)

	ansuz.Layout_end_box(ctx)

	// Separator
	ansuz.Layout_rect(ctx, '─', ansuz.STYLE_DIM, {
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
	})
	ansuz.Layout_end_rect(ctx)
}

render_sidebar :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.Layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
		direction = .TopToBottom,
		sizing = {ansuz.Sizing_percent(0.25), ansuz.Sizing_grow()},
		gap = 1,
		padding = ansuz.Padding_all(1),
	}, .Rounded)

		// Navigation
		render_tab(ctx, "Dashboard", 0, state.selected_tab, state.theme_color)
		render_tab(ctx, "Terminal", 1, state.selected_tab, state.theme_color)
		render_tab(ctx, "Settings", 2, state.selected_tab, state.theme_color)

		// Theme selector
		ansuz.Layout_text(ctx, "", ansuz.STYLE_DIM)
		ansuz.Layout_text(ctx, "Theme Colors", ansuz.STYLE_BOLD)
		render_theme_option(ctx, "Red Theme", 0, state.theme_color, state.theme_color)
		render_theme_option(ctx, "Green Theme", 1, state.theme_color, state.theme_color)
		render_theme_option(ctx, "Blue Theme", 2, state.theme_color, state.theme_color)
		render_theme_option(ctx, "Yellow Theme", 3, state.theme_color, state.theme_color)

	ansuz.Layout_end_box(ctx)
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

	ansuz.Layout_text(ctx, strings.to_string(builder), style)
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

	ansuz.Layout_text(ctx, strings.to_string(builder), style)
}

render_content_area :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
		gap = 1,
		padding = ansuz.Padding_all(1),
	}, .Rounded)

		switch state.selected_tab {
		case 0:
			render_dashboard_tab(ctx, state)
		case 1:
			render_terminal_tab(ctx, state)
		case 2:
			render_settings_tab(ctx, state)
		}

	ansuz.Layout_end_box(ctx)
}

render_dashboard_tab :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	// Progress section
	ansuz.Layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
		direction = .TopToBottom,
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fit()},
		padding = ansuz.Padding_all(1),
	}, .Rounded)

		ansuz.Layout_text(ctx, "System Status", ansuz.STYLE_BOLD)
		ansuz.Layout_text(ctx, "", ansuz.STYLE_DIM)

		// Progress bar
		ansuz.Layout_text(ctx, "Processing:", ansuz.STYLE_NORMAL)

		ansuz.Layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
			direction = .LeftToRight,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
		}, .Rounded)

			// Progress fill (draws first, fills from left)
			if state.progress > 0 {
				ansuz.Layout_rect(ctx, '█', get_theme_style(.Normal, state.theme_color), {
					sizing = {ansuz.Sizing_percent(state.progress), ansuz.Sizing_fixed(1)},
				})
				ansuz.Layout_end_rect(ctx)
			}
			// Progress background (empty space to the right)
			ansuz.Layout_rect(ctx, '░', ansuz.STYLE_DIM, {
				sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
			})
			ansuz.Layout_end_rect(ctx)

		ansuz.Layout_end_box(ctx)

		// Percentage text
		ansuz.Layout_text(ctx, fmt.tprintf("%.0f%% Complete", state.progress * 100), ansuz.STYLE_NORMAL)

	ansuz.Layout_end_box(ctx)

	// Stats boxes
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .LeftToRight,
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fit()},
		gap = 1,
		padding = ansuz.Padding_all(1),
	}, .Rounded)

		render_stat_box(ctx, "CPU Usage", "45%", ansuz.STYLE_INFO)
		render_stat_box(ctx, "Memory", "2.4 GB", ansuz.STYLE_SUCCESS)
		render_stat_box(ctx, "Network", "1.2 MB/s", ansuz.STYLE_WARNING)

	ansuz.Layout_end_box(ctx)
}

render_stat_box :: proc(ctx: ^ansuz.Context, label: string, value: string, style: ansuz.Style) {
	ansuz.Layout_box(ctx, style, {
		direction = .TopToBottom,
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fit()},
		padding = ansuz.Padding_all(1),
		alignment = {horizontal = .Center, vertical = .Center},
	}, .Rounded)

		ansuz.Layout_text(ctx, label, ansuz.STYLE_DIM)
		ansuz.Layout_text(ctx, value, style)

	ansuz.Layout_end_box(ctx)
}

render_terminal_tab :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.Layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
		direction = .TopToBottom,
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
		padding = ansuz.Padding_all(1),
	}, .Rounded)

		ansuz.Layout_text(ctx, "Terminal Output", ansuz.STYLE_BOLD)
		ansuz.Layout_text(ctx, "", ansuz.STYLE_DIM)
		ansuz.Layout_text(ctx, "$ ./ansuz_demo", ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, "> Initializing system...", ansuz.STYLE_SUCCESS)
		ansuz.Layout_text(ctx, "> Loading modules...", ansuz.STYLE_SUCCESS)
		ansuz.Layout_text(ctx, "> Starting services...", ansuz.STYLE_SUCCESS)
		ansuz.Layout_text(ctx, "> Ready!", ansuz.STYLE_SUCCESS)
		ansuz.Layout_text(ctx, "", ansuz.STYLE_DIM)
		ansuz.Layout_text(ctx, "Press Tab to cycle views", ansuz.STYLE_DIM)
		ansuz.Layout_text(ctx, "Press Arrow keys to navigate", ansuz.STYLE_DIM)

	ansuz.Layout_end_box(ctx)
}

render_settings_tab :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.Layout_box(ctx, get_theme_style(.Normal, state.theme_color), {
		direction = .TopToBottom,
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
		padding = ansuz.Padding_all(1),
	}, .Rounded)

		ansuz.Layout_text(ctx, "Settings", ansuz.STYLE_BOLD)
		ansuz.Layout_text(ctx, "", ansuz.STYLE_DIM)
		ansuz.Layout_text(ctx, "[x] Enable animations", ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, "[ ] Enable sounds", ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, "[x] Show FPS counter", ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, "[ ] Debug mode", ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, "", ansuz.STYLE_DIM)
		theme_names := [?]string{"Red", "Green", "Blue", "Yellow"}
		theme_text := fmt.tprintf("Theme: %s", theme_names[state.theme_color])
		ansuz.Layout_text(ctx, theme_text, ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, "Font size: 12px", ansuz.STYLE_NORMAL)

	ansuz.Layout_end_box(ctx)
}

render_footer :: proc(ctx: ^ansuz.Context, state: ^DemoState) {
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .LeftToRight,
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
		padding = {left = 1, right = 1, top = 0, bottom = 0},
	}, .Rounded)

		// Left side: Controls
		ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
			direction = .LeftToRight,
			sizing = {ansuz.Sizing_fit(), ansuz.Sizing_grow()},
			gap = 2,
			alignment = {horizontal = .Left, vertical = .Center},
		}, .Rounded)
			ansuz.Layout_text(ctx, "[Tab] Views", ansuz.STYLE_DIM)
			ansuz.Layout_text(ctx, "[←→] Tabs", ansuz.STYLE_DIM)
			ansuz.Layout_text(ctx, "[↑↓] Theme", ansuz.STYLE_DIM)
			ansuz.Layout_text(ctx, "[Q] Quit", ansuz.STYLE_WARNING)
		ansuz.Layout_end_box(ctx)

		// Right side: Status
		ansuz.Layout_text(ctx, "● Connected", ansuz.STYLE_SUCCESS)

	ansuz.Layout_end_box(ctx)
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
	millis := f32(d) / f32(time.Millisecond)
	return fmt.tprintf("%.2fms", millis)
}
