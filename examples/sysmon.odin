// sysmon.odin - Monitor de recursos simulado estilo btop
//
// Este exemplo demonstra:
// - Layouts complexos com containers aninhados
// - Sizing_grow() com pesos para proporções
// - Sizing_fixed() para alturas específicas
// - Múltiplos BoxStyle (Sharp, Rounded)
// - Sistema completo de cores (16 cores ANSI)
// - StyleFlags (.Bold, .Dim)
// - Padding e Gap
// - Barras de progresso visuais
// - Dados simulados dinâmicos
// - Sample rate configurável

package sysmon

import ansuz "../ansuz"
import "core:fmt"
import "core:math/rand"
import "core:time"

// Dados simulados do sistema
SystemData :: struct {
	cpu_total:    f32,
	cpu_cores:    [4]f32,
	memory_used:  f32,
	memory_total: f32,
	processes:    [5]Process,
}

Process :: struct {
	pid:       int,
	name:      string,
	cpu:       f32,
	memory_mb: int,
}

// Estado global para simulação
g_data: SystemData
g_frame: int
g_sample_rate_ms: int = 500 // Sample rate em ms (100-1000, passo 100)
g_last_update: time.Time

main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		return
	}
	defer ansuz.shutdown(ctx)

	// Inicializa dados simulados
	init_data()
	g_last_update = time.now()

	// Loop contínuo para atualizar dados em tempo real
	for {
		ansuz.begin_frame(ctx)

		// Processa eventos (non-blocking)
		for event in ansuz.poll_events(ctx) {
			if ansuz.is_quit_key(event) {
				ansuz.end_frame(ctx)
				return
			}

			// Ajusta sample rate com Up/Down
			if key_event, ok := event.(ansuz.KeyEvent); ok {
				if key_event.key == .Up && g_sample_rate_ms > 100 {
					g_sample_rate_ms -= 100
				} else if key_event.key == .Down && g_sample_rate_ms < 1000 {
					g_sample_rate_ms += 100
				}
			}
		}

		// Atualiza dados apenas quando passar o sample rate
		elapsed := time.duration_milliseconds(time.diff(g_last_update, time.now()))
		if i64(elapsed) >= i64(g_sample_rate_ms) {
			update_data()
			g_last_update = time.now()
		}

		render(ctx)

		ansuz.end_frame(ctx)
	}
}

init_data :: proc() {
	g_data.memory_total = 16.0
	g_data.memory_used = 6.4

	g_data.processes = {
		{1234, "firefox", 12.3, 1200},
		{5678, "code", 8.7, 890},
		{9012, "ghostty", 2.1, 120},
		{3456, "spotify", 4.5, 340},
		{7890, "slack", 3.2, 560},
	}
}

update_data :: proc() {
	g_frame += 1

	// Simula variação de CPU
	for i in 0 ..< 4 {
		g_data.cpu_cores[i] = 20.0 + rand.float32() * 60.0
	}

	// Média dos cores
	total: f32 = 0
	for core in g_data.cpu_cores {
		total += core
	}
	g_data.cpu_total = total / 4.0

	// Variação de memória
	g_data.memory_used = 5.0 + rand.float32() * 8.0
}

render :: proc(ctx: ^ansuz.Context) {
	ansuz.begin_layout(ctx)

	// Container principal
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
			padding = {1, 1, 0, 0},
			gap = 1,
		},
	)

	// Linha superior: CPU + Memory (lado a lado)
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .LeftToRight,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(10)},
			gap = 1,
		},
	)
	render_cpu_panel(ctx)
	render_memory_panel(ctx)
	ansuz.Layout_end_container(ctx)

	// Processos (preenche o resto)
	render_processes_panel(ctx)

	// Barra de status
	render_status_bar(ctx)

	ansuz.Layout_end_container(ctx)

	ansuz.end_layout(ctx)
}

render_cpu_panel :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_box(
		ctx,
		ansuz.Style{.Cyan, .Default, {}},
		{
			sizing = {ansuz.Sizing_grow(1), ansuz.Sizing_grow()},
			padding = {1, 1, 1, 1},
			direction = .TopToBottom,
			gap = 0,
		},
		.Rounded,
	)
	// Título
	ansuz.Layout_text(ctx, "󰻠 CPU", ansuz.Style{.BrightCyan, .Default, {.Bold}})

	// Barra total
	render_progress_bar(ctx, "Total", g_data.cpu_total, .BrightGreen)

	// Cores individuais
	for i in 0 ..< 4 {
		label := fmt.tprintf("Core %d", i + 1)
		color := get_cpu_color(g_data.cpu_cores[i])
		render_progress_bar(ctx, label, g_data.cpu_cores[i], color)
	}

	ansuz.Layout_end_box(ctx)
}

render_memory_panel :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_box(
		ctx,
		ansuz.Style{.Magenta, .Default, {}},
		{
			sizing = {ansuz.Sizing_grow(1), ansuz.Sizing_grow()},
			padding = {1, 1, 1, 1},
			direction = .TopToBottom,
			gap = 0,
		},
		.Rounded,
	)
	// Título
	ansuz.Layout_text(ctx, "󰍛 Memory", ansuz.Style{.BrightMagenta, .Default, {.Bold}})

	// Barra de uso
	pct := (g_data.memory_used / g_data.memory_total) * 100.0
	render_progress_bar(ctx, "Used", pct, .BrightBlue)

	// Detalhes
	ansuz.Layout_text(
		ctx,
		fmt.tprintf("Used:  %.1f GB", g_data.memory_used),
		ansuz.Style{.White, .Default, {}},
	)
	ansuz.Layout_text(
		ctx,
		fmt.tprintf("Free:  %.1f GB", g_data.memory_total - g_data.memory_used),
		ansuz.Style{.BrightBlack, .Default, {}},
	)
	ansuz.Layout_text(
		ctx,
		fmt.tprintf("Total: %.1f GB", g_data.memory_total),
		ansuz.Style{.BrightBlack, .Default, {.Dim}},
	)

	ansuz.Layout_end_box(ctx)
}

render_processes_panel :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_box(
		ctx,
		ansuz.Style{.Yellow, .Default, {}},
		{
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
			padding = {1, 1, 1, 1},
			direction = .TopToBottom,
			gap = 0,
		},
		.Sharp,
	)
	// Título
	ansuz.Layout_text(ctx, "󰓹 Processes", ansuz.Style{.BrightYellow, .Default, {.Bold}})

	// Cabeçalho
	ansuz.Layout_text(
		ctx,
		"  PID   │ Name              │ CPU    │ Memory",
		ansuz.Style{.White, .Default, {.Bold}},
	)
	ansuz.Layout_text(
		ctx,
		"────────┼───────────────────┼────────┼─────────",
		ansuz.Style{.BrightBlack, .Default, {}},
	)

	// Lista de processos
	for proc_info in g_data.processes {
		line := fmt.tprintf(
			"  %-5d │ %-17s │ %5.1f%% │ %4d MB",
			proc_info.pid,
			proc_info.name,
			proc_info.cpu,
			proc_info.memory_mb,
		)

		color: ansuz.Color = .White
		if proc_info.cpu > 10.0 {
			color = .BrightRed
		} else if proc_info.cpu > 5.0 {
			color = .BrightYellow
		}

		ansuz.Layout_text(ctx, line, ansuz.Style{color, .Default, {}})
	}

	ansuz.Layout_end_box(ctx)
}

render_status_bar :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .LeftToRight,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
			alignment = {.Center, .Center},
		},
	)
	status := fmt.tprintf(" [Up/Down] Rate: %dms | [Q/ESC] Sair", g_sample_rate_ms)
	ansuz.Layout_text(ctx, status, ansuz.Style{.BrightBlack, .Default, {.Dim}})
	ansuz.Layout_end_container(ctx)
}

render_progress_bar :: proc(ctx: ^ansuz.Context, label: string, value: f32, color: ansuz.Color) {
	// Formato: "Label  [████████░░░░] 62%"
	bar_width := 20
	filled := int(value / 100.0 * f32(bar_width))
	if filled > bar_width do filled = bar_width
	if filled < 0 do filled = 0

	bar: [32]u8
	for i in 0 ..< bar_width {
		if i < filled {
			bar[i] = '#' // Simula bloco cheio
		} else {
			bar[i] = '-' // Simula bloco vazio
		}
	}

	line := fmt.tprintf("%-6s [%s] %3.0f%%", label, string(bar[:bar_width]), value)
	ansuz.Layout_text(ctx, line, ansuz.Style{color, .Default, {}})
}

get_cpu_color :: proc(value: f32) -> ansuz.Color {
	if value > 80.0 {
		return .BrightRed
	} else if value > 60.0 {
		return .BrightYellow
	} else if value > 40.0 {
		return .BrightGreen
	}
	return .Green
}
