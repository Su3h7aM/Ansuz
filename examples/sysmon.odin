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
// - API 100% scoped com callbacks

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
	// API 100% scoped - sem begin/end explícitos
	ansuz.layout(ctx, proc(ctx: ^ansuz.Context) {
		// Container principal
		ansuz.container(ctx, {
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			padding = {1, 1, 0, 0},
			gap = 1,
		}, proc(ctx: ^ansuz.Context) {
			// Linha superior: CPU + Memory (lado a lado)
			ansuz.hstack(ctx, {
				sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(10)},
				gap = 1,
			}, proc(ctx: ^ansuz.Context) {
				render_cpu_panel(ctx)
				render_memory_panel(ctx)
			})

			// Processos (preenche o resto)
			render_processes_panel(ctx)

			// Barra de status
			render_status_bar(ctx)
		})
	})
}

render_cpu_panel :: proc(ctx: ^ansuz.Context) {
	ansuz.box(ctx, {
		sizing = {.X = ansuz.grow(1), .Y = ansuz.grow()},
		padding = {1, 1, 1, 1},
		direction = .TopToBottom,
		gap = 0,
	}, ansuz.style(.Cyan, .Default, {}), .Rounded, proc(ctx: ^ansuz.Context) {
		// Título
		ansuz.label(ctx, "󰻠 CPU", {style = ansuz.style(.BrightCyan, .Default, {.Bold})})

		// Barra total
		render_progress_bar(ctx, "Total", g_data.cpu_total, .BrightGreen)

		// Cores individuais
		for i in 0 ..< 4 {
			name := fmt.tprintf("Core %d", i + 1)
			color := get_cpu_color(g_data.cpu_cores[i])
			render_progress_bar(ctx, name, g_data.cpu_cores[i], color)
		}
	})
}

render_memory_panel :: proc(ctx: ^ansuz.Context) {
	ansuz.box(ctx, {
		sizing = {.X = ansuz.grow(1), .Y = ansuz.grow()},
		padding = {1, 1, 1, 1},
		direction = .TopToBottom,
		gap = 0,
	}, ansuz.style(.Magenta, .Default, {}), .Rounded, proc(ctx: ^ansuz.Context) {
		// Título
		ansuz.label(ctx, "󰍛 Memory", {style = ansuz.style(.BrightMagenta, .Default, {.Bold})})

		// Barra de uso
		pct := (g_data.memory_used / g_data.memory_total) * 100.0
		render_progress_bar(ctx, "Used", pct, .BrightBlue)

		// Detalhes
		ansuz.label(
			ctx,
			fmt.tprintf("Used:  %.1f GB", g_data.memory_used),
			{style = ansuz.style(.White, .Default, {})},
		)
		ansuz.label(
			ctx,
			fmt.tprintf("Free:  %.1f GB", g_data.memory_total - g_data.memory_used),
			{style = ansuz.style(.BrightBlack, .Default, {})},
		)
		ansuz.label(
			ctx,
			fmt.tprintf("Total: %.1f GB", g_data.memory_total),
			{style = ansuz.style(.BrightBlack, .Default, {.Dim})},
		)
	})
}

render_processes_panel :: proc(ctx: ^ansuz.Context) {
	ansuz.box(ctx, {
		sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
		padding = {1, 1, 1, 1},
		direction = .TopToBottom,
		gap = 0,
	}, ansuz.style(.Yellow, .Default, {}), .Sharp, proc(ctx: ^ansuz.Context) {
		// Título
		ansuz.label(ctx, "󰓹 Processes", {style = ansuz.style(.BrightYellow, .Default, {.Bold})})

		// Cabeçalho
		ansuz.label(
			ctx,
			"  PID   │ Name              │ CPU    │ Memory",
			{style = ansuz.style(.White, .Default, {.Bold})},
		)
		ansuz.label(
			ctx,
			"────────┼───────────────────┼────────┼─────────",
			{style = ansuz.style(.BrightBlack, .Default, {})},
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

			color: ansuz.TerminalColor = .White
			if proc_info.cpu > 10.0 {
				color = .BrightRed
			} else if proc_info.cpu > 5.0 {
				color = .BrightYellow
			}

			ansuz.label(ctx, line, {style = ansuz.style(color, .Default, {})})
		}
	})
}

render_status_bar :: proc(ctx: ^ansuz.Context) {
	ansuz.container(ctx, {
		direction = .LeftToRight,
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)},
		alignment = {.Center, .Center},
	}, proc(ctx: ^ansuz.Context) {
		status := fmt.tprintf(" [Up/Down] Rate: %dms | [Q/ESC] Sair", g_sample_rate_ms)
		ansuz.label(ctx, status, {style = ansuz.style(.BrightBlack, .Default, {.Dim})})
	})
}

render_progress_bar :: proc(
	ctx: ^ansuz.Context,
	label: string,
	value: f32,
	color: ansuz.TerminalColor,
) {
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
	ansuz.label(ctx, line, {style = ansuz.style(color, .Default, {})})
}

get_cpu_color :: proc(value: f32) -> ansuz.TerminalColor {
	if value > 80.0 {
		return ansuz.Ansi.BrightRed
	} else if value > 60.0 {
		return ansuz.Ansi.BrightYellow
	} else if value > 40.0 {
		return ansuz.Ansi.BrightGreen
	}
	return ansuz.Ansi.Green
}
