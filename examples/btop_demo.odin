package main

import ansuz "../ansuz"
import "core:fmt"
import "core:time"
import "core:strings"
import "core:math"
import "core:math/rand"

// BtopDemoState holds the simulated system state
BtopDemoState :: struct {
	running:              bool,
	selected_tab:         int,
	// CPU data
	cpu_usage:            [8]f32,  // 8 CPU cores
	// Memory data
	mem_used:             f32,
	mem_total:            f32,
	swap_used:            f32,
	swap_total:           f32,
	mem_history:          [dynamic]f32,
	// Network data
	net_rx:               f32,  // MB/s
	net_tx:               f32,
	net_rx_history:       [dynamic]f32,
	net_tx_history:       [dynamic]f32,
	// Process data
	processes:           [dynamic]ProcessInfo,
	// Timing
	last_update:          time.Time,
}

ProcessInfo :: struct {
	pid:     int,
	name:    string,
	cpu:     f32,
	mem:     f32,
}

// Predefined color styles for each section
STYLE_CPU :: ansuz.Style{.Cyan, .Default, {}}
STYLE_CPU_DIM :: ansuz.Style{.Cyan, .Default, {.Dim}}
STYLE_MEM :: ansuz.Style{.Green, .Default, {}}
STYLE_MEM_DIM :: ansuz.Style{.Green, .Default, {.Dim}}
STYLE_NET :: ansuz.Style{.Yellow, .Default, {}}
STYLE_NET_DIM :: ansuz.Style{.Yellow, .Default, {.Dim}}
STYLE_PROC :: ansuz.Style{.Magenta, .Default, {}}
STYLE_PROC_DIM :: ansuz.Style{.Magenta, .Default, {.Dim}}
STYLE_HEADER :: ansuz.Style{.BrightCyan, .Default, {.Bold}}
STYLE_FOOTER :: ansuz.Style{.BrightBlack, .Default, {.Dim}}
	
	main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to initialize Ansuz:", err)
		return
	}
	defer ansuz.shutdown(ctx)

	// Enable FPS limiting
	ansuz.set_target_fps(ctx, 30)

	state := BtopDemoState{
		running = true,
		selected_tab = 0,
		mem_total = 16.0,  // 16 GB
		swap_total = 8.0,  // 8 GB
		last_update = time.now(),
	}

	// Initialize histories
	state.mem_history = make([dynamic]f32, 0, 60, context.allocator)
	state.net_rx_history = make([dynamic]f32, 0, 60, context.allocator)
	state.net_tx_history = make([dynamic]f32, 0, 60, context.allocator)
	state.processes = make([dynamic]ProcessInfo, 0, 20, context.allocator)

	// Generate initial fake data
	generate_fake_data(&state)

	for state.running {
		ansuz.begin_frame(ctx)

		// Handle input
		events := ansuz.poll_events(ctx)
		for ev in events {
			handle_input(&state, ev)
		}

		// Update data occasionally
		now := time.now()
		if time.diff(state.last_update, now) >= 500 * time.Millisecond {
			update_fake_data(&state)
			state.last_update = now
		}

		// Render
		render_btop(ctx, &state)

		ansuz.end_frame(ctx)
	}
}

	handle_input :: proc(state: ^BtopDemoState, event: ansuz.Event) {
	#partial switch e in event {
	case ansuz.KeyEvent:
		#partial switch e.key {
		case .Ctrl_C, .Ctrl_D, .Escape:
			state.running = false
		case .Char:
			if e.rune == 'q' || e.rune == 'Q' {
				state.running = false
			}
		}
	}
}

render_btop :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.begin_layout(ctx)

	// Main container for all content
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
	}, .Rounded)

	// Header
	render_header(ctx, state)

	// Container for all 4 sections in 2x2 grid
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .LeftToRight,
		padding = {1, 1, 1, 1},
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
	}, .Rounded)

	// Left column: CPU and Memory
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		padding = {0, 0, 0, 0},
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
	}, .Rounded)

	render_cpu_view(ctx, state)
	render_mem_view(ctx, state)

	ansuz.Layout_end_box(ctx)

	// Right column: Network and Processes
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		padding = {0, 0, 0, 0},
		sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
	}, .Rounded)

	render_net_view(ctx, state)
	render_proc_view(ctx, state)

	ansuz.Layout_end_box(ctx)

	ansuz.Layout_end_box(ctx)

	// Footer with controls
	render_footer(ctx, state)

	ansuz.Layout_end_box(ctx)

	ansuz.end_layout(ctx)
}

render_header :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, STYLE_HEADER, {
		direction = .LeftToRight,
		padding = {1, 1, 1, 1},
	}, .Rounded)

	ansuz.Layout_text(ctx, "BTOP SIMULATOR", STYLE_HEADER)

	// FPS display
	fps_text := fmt.tprintf("FPS: %.1f", ansuz.get_fps(ctx))
	ansuz.Layout_text(ctx, fps_text, STYLE_HEADER)

	ansuz.Layout_end_box(ctx)
}

render_footer :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, STYLE_FOOTER, {
		direction = .LeftToRight,
		padding = {0, 1, 0, 1},
	}, .Rounded)

	ansuz.Layout_text(ctx, "[q] Quit", STYLE_FOOTER)

	ansuz.Layout_end_box(ctx)
}

// Placeholder functions for each view
render_cpu_view :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, STYLE_CPU, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
	}, .Rounded)

	// Title
	ansuz.Layout_text(ctx, "CPU", STYLE_CPU_DIM)

	// CPU bars
	ansuz.Layout_box(ctx, STYLE_CPU, {
		direction = .TopToBottom,
		padding = {0, 0, 0, 0},
	}, .Rounded)

	for i in 0..<8 {
		usage := state.cpu_usage[i]

		// CPU label and percentage
		label := fmt.tprintf("Core %d: %.1f%%", i, usage)
		ansuz.Layout_text(ctx, label, STYLE_CPU)

		// Progress bar
	ansuz.Layout_box(ctx, STYLE_CPU, {
		direction = .LeftToRight,
		padding = {0, 0, 0, 0},
	})

	// Filled portion
	if usage > 0 {
		fill_width := int(usage / 100.0 * 20.0)  // 20 chars wide
		if fill_width > 0 {
			ansuz.Layout_rect(ctx, '█', STYLE_CPU, {
				sizing = {ansuz.Sizing_fixed(fill_width), ansuz.Sizing_fixed(1)},
			})
			ansuz.Layout_end_rect(ctx)
		}
	}

	// Empty portion
	empty_width := 20 - int(usage / 100.0 * 20.0)
	if empty_width > 0 {
		ansuz.Layout_rect(ctx, '░', STYLE_CPU_DIM, {
			sizing = {ansuz.Sizing_fixed(empty_width), ansuz.Sizing_fixed(1)},
		})
		ansuz.Layout_end_rect(ctx)
	}

	ansuz.Layout_end_box(ctx)  // End horizontal box
	}

	ansuz.Layout_end_box(ctx)  // End vertical box

	ansuz.Layout_end_box(ctx)  // End main box
}

render_mem_view :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, STYLE_MEM, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
	}, .Rounded)

	// Title
	ansuz.Layout_text(ctx, "MEMORY", STYLE_MEM_DIM)

	// Memory info
	mem_percent := state.mem_used / state.mem_total * 100.0
	mem_text := fmt.tprintf("%.1f/%.1f GB", state.mem_used, state.mem_total)
	ansuz.Layout_text(ctx, mem_text, STYLE_MEM)

	// Memory bar
	render_progress_bar(ctx, mem_percent, STYLE_MEM, STYLE_MEM_DIM)

	// Swap info
	if state.swap_total > 0 {
		swap_percent := state.swap_used / state.swap_total * 100.0
		swap_text := fmt.tprintf("SWAP: %.1f/%.1f GB", state.swap_used, state.swap_total)
		ansuz.Layout_text(ctx, swap_text, STYLE_MEM_DIM)

		// Swap bar
		render_progress_bar(ctx, swap_percent, STYLE_MEM_DIM, STYLE_MEM_DIM)
	}

	ansuz.Layout_end_box(ctx)
}

// Helper for progress bars
render_progress_bar :: proc(ctx: ^ansuz.Context, percent: f32, fill_style: ansuz.Style, empty_style: ansuz.Style) {
	ansuz.Layout_box(ctx, fill_style, {
		direction = .LeftToRight,
		padding = {0, 0, 0, 0},
	})

	bar_width := 40
	fill_width := int(percent / 100.0 * f32(bar_width))
	empty_width := bar_width - fill_width

	if fill_width > 0 {
		ansuz.Layout_rect(ctx, '█', fill_style, {
			sizing = {ansuz.Sizing_fixed(fill_width), ansuz.Sizing_fixed(1)},
		})
		ansuz.Layout_end_rect(ctx)
	}
	if empty_width > 0 {
		ansuz.Layout_rect(ctx, '░', empty_style, {
			sizing = {ansuz.Sizing_fixed(empty_width), ansuz.Sizing_fixed(1)},
		})
		ansuz.Layout_end_rect(ctx)
	}

	ansuz.Layout_end_box(ctx)
}

render_net_view :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, STYLE_NET, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
	}, .Rounded)

	// Title
	ansuz.Layout_text(ctx, "NETWORK", STYLE_NET_DIM)

	// Current rates
	rx_text := fmt.tprintf("RX: %.1f MB/s", state.net_rx)
	tx_text := fmt.tprintf("TX: %.1f MB/s", state.net_tx)

	ansuz.Layout_text(ctx, rx_text, STYLE_NET)
	ansuz.Layout_text(ctx, tx_text, STYLE_NET)

	// Simple sparkline graphs
	if len(state.net_rx_history) > 0 {
		ansuz.Layout_text(ctx, "RX:", STYLE_NET_DIM)
		render_sparkline(ctx, state.net_rx_history[:], STYLE_NET, STYLE_NET_DIM)

		ansuz.Layout_text(ctx, "TX:", STYLE_NET_DIM)
		render_sparkline(ctx, state.net_tx_history[:], STYLE_NET, STYLE_NET_DIM)
	}

	ansuz.Layout_end_box(ctx)
}

// Simple sparkline renderer
render_sparkline :: proc(ctx: ^ansuz.Context, values: []f32, fill_style: ansuz.Style, empty_style: ansuz.Style) {
	if len(values) == 0 {
		return
	}

	ansuz.Layout_box(ctx, fill_style, {
		direction = .LeftToRight,
		padding = {0, 0, 0, 0},
	})

	max_val: f32 = 0.0
	for v in values {
		if v > max_val {
			max_val = v
		}
	}

	width := 40
	if len(values) < width {
		width = len(values)
	}

	for i in 0..<width {
		idx := len(values) - width + i
		if idx < 0 {
			continue
		}

		val := values[idx]
		height := int(val / max_val * 4.0) if max_val > 0.0 else 0
		char: rune
		switch height {
		case 0: char = '▁'
		case 1: char = '▂'
		case 2: char = '▃'
		case 3: char = '▄'
		case: char = '█'
		}

		ansuz.Layout_text(ctx, fmt.tprintf("%c", char), fill_style)
	}

	ansuz.Layout_end_box(ctx)
}

render_proc_view :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, STYLE_PROC, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
	}, .Rounded)

	// Title
	ansuz.Layout_text(ctx, "PROCESSES", STYLE_PROC_DIM)

// Header
	ansuz.Layout_box(ctx, STYLE_PROC, {
		direction = .LeftToRight,
		padding = {1, 1, 1, 1},
	}, .Rounded)
	ansuz.Layout_text(ctx, "PID", STYLE_PROC_DIM)
	ansuz.Layout_text(ctx, "     NAME", STYLE_PROC_DIM)
	ansuz.Layout_text(ctx, "   CPU%", STYLE_PROC_DIM)
	ansuz.Layout_text(ctx, "   MEM%", STYLE_PROC_DIM)
	ansuz.Layout_end_box(ctx)

	// Process list (show first 10)
	display_count := math.min(10, len(state.processes))
	for i in 0..<display_count {
		process := state.processes[i]

		ansuz.Layout_box(ctx, STYLE_PROC, {
			direction = .LeftToRight,
			padding = {0, 0, 0, 0},
		})

		pid_text := fmt.tprintf("%d", process.pid)
		name_text := fmt.tprintf("%10s", process.name)
		cpu_text := fmt.tprintf("%6.1f", process.cpu)
		mem_text := fmt.tprintf("%6.1f", process.mem)

		ansuz.Layout_text(ctx, pid_text, STYLE_PROC)
		ansuz.Layout_text(ctx, name_text, STYLE_PROC)
		ansuz.Layout_text(ctx, cpu_text, STYLE_PROC)
		ansuz.Layout_text(ctx, mem_text, STYLE_PROC)

		ansuz.Layout_end_box(ctx)
	}

	if len(state.processes) > 10 {
		more_text := fmt.tprintf("... and %d more", len(state.processes) - 10)
		ansuz.Layout_text(ctx, more_text, STYLE_PROC_DIM)
	}

	ansuz.Layout_end_box(ctx)
}

// Fake data generation
generate_fake_data :: proc(state: ^BtopDemoState) {
	// CPU
	for i in 0..<8 {
		state.cpu_usage[i] = rand.float32() * 100.0
	}

	// Memory
	state.mem_used = 8.0 + rand.float32() * 8.0  // 8-16 GB
	state.swap_used = rand.float32() * 4.0       // 0-4 GB

	// Network
	state.net_rx = rand.float32() * 100.0  // 0-100 MB/s
	state.net_tx = rand.float32() * 50.0   // 0-50 MB/s

	// Processes
	clear(&state.processes)
	process_names := []string{"systemd", "Xorg", "firefox", "bash", "vim", "python", "node", "docker"}
	for i in 0..<8 {
		process := ProcessInfo{
			pid = 1000 + i,
			name = process_names[i % len(process_names)],
			cpu = rand.float32() * 20.0,
			mem = rand.float32() * 5.0,
		}
		append(&state.processes, process)
	}
}

update_fake_data :: proc(state: ^BtopDemoState) {
	// Update CPU with some variation
	for i in 0..<8 {
		change := (rand.float32() - 0.5) * 20.0
		state.cpu_usage[i] = clamp(state.cpu_usage[i] + change, 0.0, 100.0)
	}

	// Update memory
	change := (rand.float32() - 0.5) * 2.0
	state.mem_used = clamp(state.mem_used + change, 4.0, state.mem_total)

	change = (rand.float32() - 0.5) * 1.0
	state.swap_used = clamp(state.swap_used + change, 0.0, state.swap_total)

	// Update network
	state.net_rx = rand.float32() * 100.0
	state.net_tx = rand.float32() * 50.0

	// Update histories
	append(&state.mem_history, state.mem_used / state.mem_total * 100.0)
	if len(state.mem_history) > 60 {
		ordered_remove(&state.mem_history, 0)
	}

	append(&state.net_rx_history, state.net_rx)
	if len(state.net_rx_history) > 60 {
		ordered_remove(&state.net_rx_history, 0)
	}

	append(&state.net_tx_history, state.net_tx)
	if len(state.net_tx_history) > 60 {
		ordered_remove(&state.net_tx_history, 0)
	}
}