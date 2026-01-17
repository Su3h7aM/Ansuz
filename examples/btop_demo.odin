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
		case .Tab:
			state.selected_tab = (state.selected_tab + 1) % 4
		case .Right:
			state.selected_tab = (state.selected_tab + 1) % 4
		case .Left:
			state.selected_tab = (state.selected_tab - 1 + 4) % 4
	}
	}
}

render_btop :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.begin_layout(ctx)

	// Header
	render_header(ctx, state)

	// Main content based on tab
	switch state.selected_tab {
	case 0: {
		ansuz.Layout_text(ctx, "CPU VIEW - Press Tab to switch", ansuz.STYLE_BOLD)
		ansuz.Layout_text(ctx, fmt.tprintf("Core 0: %.1f%%", state.cpu_usage[0]), ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, fmt.tprintf("Core 1: %.1f%%", state.cpu_usage[1]), ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, fmt.tprintf("Core 2: %.1f%%", state.cpu_usage[2]), ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, fmt.tprintf("Core 3: %.1f%%", state.cpu_usage[3]), ansuz.STYLE_NORMAL)
	}
	case 1: {
		ansuz.Layout_text(ctx, "MEMORY VIEW", ansuz.STYLE_BOLD)
		ansuz.Layout_text(ctx, fmt.tprintf("RAM: %.1f/%.1f GB", state.mem_used, state.mem_total), ansuz.STYLE_NORMAL)
		render_progress_bar(ctx, state.mem_used / state.mem_total * 100.0)
	}
	case 2: {
		ansuz.Layout_text(ctx, "NETWORK VIEW", ansuz.STYLE_BOLD)
		ansuz.Layout_text(ctx, fmt.tprintf("RX: %.1f MB/s", state.net_rx), ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, fmt.tprintf("TX: %.1f MB/s", state.net_tx), ansuz.STYLE_NORMAL)
	}
	case 3: {
		ansuz.Layout_text(ctx, "PROCESS VIEW", ansuz.STYLE_BOLD)
		for i in 0..<min(5, len(state.processes)) {
			p := state.processes[i]
			ansuz.Layout_text(ctx, fmt.tprintf("%d %s %.1f%% %.1f%%", p.pid, p.name, p.cpu, p.mem), ansuz.STYLE_NORMAL)
		}
	}
	}

	// Footer with controls
	render_footer(ctx, state)

	ansuz.end_layout(ctx)
}

render_header :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, ansuz.STYLE_BOLD, {
		direction = .LeftToRight,
		padding = {1, 1, 1, 1},
	})

	ansuz.Layout_text(ctx, "BTOP SIMULATOR", ansuz.STYLE_BOLD)

	// FPS display
	fps_text := fmt.tprintf("FPS: %.1f", ansuz.get_fps(ctx))
	ansuz.Layout_text(ctx, fps_text, ansuz.STYLE_DIM)

	ansuz.Layout_end_box(ctx)
}

render_footer :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .LeftToRight,
		padding = {0, 1, 0, 1},
	})

	tabs := []string{"CPU", "MEM", "NET", "PROC"}
	for tab, i in tabs {
		style := ansuz.STYLE_NORMAL
		if i == state.selected_tab {
			style = ansuz.STYLE_BOLD
		}
		ansuz.Layout_text(ctx, fmt.tprintf("[%s]", tab), style)
		if i < len(tabs) - 1 {
			ansuz.Layout_text(ctx, " ", ansuz.STYLE_NORMAL)
		}
	}

	ansuz.Layout_text(ctx, " | [Tab] Switch | [Esc] Quit", ansuz.STYLE_DIM)

	ansuz.Layout_end_box(ctx)
}

// Placeholder functions for each view
render_cpu_view :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
	})

	// Title
	ansuz.Layout_text(ctx, "CPU USAGE", ansuz.STYLE_BOLD)

	// CPU bars
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
	})

	for i in 0..<8 {
		usage := state.cpu_usage[i]

		// CPU label and percentage
		label := fmt.tprintf("CPU%d: %.1f%%", i, usage)
		ansuz.Layout_text(ctx, label, ansuz.STYLE_NORMAL)

		// Progress bar
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .LeftToRight,
		padding = {0, 0, 0, 0},
	})

	// Filled portion
	if usage > 0 {
		fill_width := int(usage / 100.0 * 20.0)  // 20 chars wide
		if fill_width > 0 {
			ansuz.Layout_rect(ctx, '█', ansuz.STYLE_NORMAL, {
				sizing = {ansuz.Sizing_fixed(fill_width), ansuz.Sizing_fixed(1)},
			})
			ansuz.Layout_end_rect(ctx)
		}
	}

	// Empty portion
	empty_width := 20 - int(usage / 100.0 * 20.0)
	if empty_width > 0 {
		ansuz.Layout_rect(ctx, '░', ansuz.STYLE_DIM, {
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
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
	})

	// Title
	ansuz.Layout_text(ctx, "MEMORY USAGE", ansuz.STYLE_BOLD)

	// Memory info
	mem_percent := state.mem_used / state.mem_total * 100.0
	mem_text := fmt.tprintf("RAM: %.1f/%.1f GB (%.1f%%)", state.mem_used, state.mem_total, mem_percent)
	ansuz.Layout_text(ctx, mem_text, ansuz.STYLE_NORMAL)

	// Memory bar
	render_progress_bar(ctx, mem_percent)

	// Swap info
	if state.swap_total > 0 {
		swap_percent := state.swap_used / state.swap_total * 100.0
		swap_text := fmt.tprintf("SWAP: %.1f/%.1f GB (%.1f%%)", state.swap_used, state.swap_total, swap_percent)
		ansuz.Layout_text(ctx, swap_text, ansuz.STYLE_NORMAL)

		// Swap bar
		render_progress_bar(ctx, swap_percent)
	}

	ansuz.Layout_end_box(ctx)
}

// Helper for progress bars
render_progress_bar :: proc(ctx: ^ansuz.Context, percent: f32) {
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .LeftToRight,
		padding = {0, 0, 0, 0},
	})

	bar_width := 40
	fill_width := int(percent / 100.0 * f32(bar_width))
	empty_width := bar_width - fill_width

	if fill_width > 0 {
		ansuz.Layout_rect(ctx, '█', ansuz.STYLE_NORMAL, {
			sizing = {ansuz.Sizing_fixed(fill_width), ansuz.Sizing_fixed(1)},
		})
		ansuz.Layout_end_rect(ctx)
	}
	if empty_width > 0 {
		ansuz.Layout_rect(ctx, '░', ansuz.STYLE_DIM, {
			sizing = {ansuz.Sizing_fixed(empty_width), ansuz.Sizing_fixed(1)},
		})
		ansuz.Layout_end_rect(ctx)
	}

	ansuz.Layout_end_box(ctx)
}

render_net_view :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
	})

	// Title
	ansuz.Layout_text(ctx, "NETWORK TRAFFIC", ansuz.STYLE_BOLD)

	// Current rates
	rx_text := fmt.tprintf("RX: %.1f MB/s", state.net_rx)
	tx_text := fmt.tprintf("TX: %.1f MB/s", state.net_tx)

	ansuz.Layout_text(ctx, rx_text, ansuz.STYLE_NORMAL)
	ansuz.Layout_text(ctx, tx_text, ansuz.STYLE_NORMAL)

	// Simple sparkline graphs
	if len(state.net_rx_history) > 0 {
		ansuz.Layout_text(ctx, "RX History:", ansuz.STYLE_NORMAL)
		render_sparkline(ctx, state.net_rx_history[:])

		ansuz.Layout_text(ctx, "TX History:", ansuz.STYLE_NORMAL)
		render_sparkline(ctx, state.net_tx_history[:])
	}

	ansuz.Layout_end_box(ctx)
}

// Simple sparkline renderer
render_sparkline :: proc(ctx: ^ansuz.Context, values: []f32) {
	if len(values) == 0 {
		return
	}

	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
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

		ansuz.Layout_text(ctx, fmt.tprintf("%c", char), ansuz.STYLE_NORMAL)
	}

	ansuz.Layout_end_box(ctx)
}

render_proc_view :: proc(ctx: ^ansuz.Context, state: ^BtopDemoState) {
	ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
		direction = .TopToBottom,
		padding = {1, 1, 1, 1},
	})

	// Title
	ansuz.Layout_text(ctx, "PROCESS LIST", ansuz.STYLE_BOLD)

// Header
	ansuz.Layout_box(ctx, ansuz.STYLE_BOLD, {
		direction = .LeftToRight,
		padding = {1, 1, 1, 1},
	})
	ansuz.Layout_text(ctx, "PID", ansuz.STYLE_BOLD)
	ansuz.Layout_text(ctx, "     NAME", ansuz.STYLE_BOLD)
	ansuz.Layout_text(ctx, "   CPU%", ansuz.STYLE_BOLD)
	ansuz.Layout_text(ctx, "   MEM%", ansuz.STYLE_BOLD)
	ansuz.Layout_end_box(ctx)

	// Process list (show first 10)
	display_count := math.min(10, len(state.processes))
	for i in 0..<display_count {
		process := state.processes[i]

		ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
			direction = .LeftToRight,
			padding = {0, 0, 0, 0},
		})

		pid_text := fmt.tprintf("%d", process.pid)
		name_text := fmt.tprintf("%10s", process.name)
		cpu_text := fmt.tprintf("%6.1f", process.cpu)
		mem_text := fmt.tprintf("%6.1f", process.mem)

		ansuz.Layout_text(ctx, pid_text, ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, name_text, ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, cpu_text, ansuz.STYLE_NORMAL)
		ansuz.Layout_text(ctx, mem_text, ansuz.STYLE_NORMAL)

		ansuz.Layout_end_box(ctx)
	}

	if len(state.processes) > 10 {
		more_text := fmt.tprintf("... and %d more processes", len(state.processes) - 10)
		ansuz.Layout_text(ctx, more_text, ansuz.STYLE_DIM)
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