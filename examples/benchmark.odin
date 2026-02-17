// benchmark.odin - Benchmark de performance do Ansuz
//
// Este exemplo demonstra:
// - Medição de tempo com time.Duration
// - get_last_frame_time() para calcular FPS
// - Renderização intensiva para stress test
// - Estatísticas em tempo real
// - Loop contínuo (não event-driven)
// - API scoped com @(deferred_in_out)

package benchmark

import ansuz "../ansuz"
import "core:fmt"
import "core:time"

// Estatísticas do benchmark
Stats :: struct {
	frame_count:    u64,
	total_time:     time.Duration,
	min_frame_time: time.Duration,
	max_frame_time: time.Duration,
	avg_frame_time: time.Duration,
	elements_count: int,
	stress_level:   int, // 1-10
}

g_stats: Stats
g_history: [60]time.Duration // Últimos 60 frames para média móvel
g_history_idx: int

main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		return
	}
	defer ansuz.shutdown(ctx)

	// Inicializa estatísticas
	g_stats.min_frame_time = time.Duration(999 * time.Millisecond)
	g_stats.stress_level = 5

	// Loop contínuo para benchmark real
	for {
		// Processa eventos de entrada (non-blocking)
		for event in ansuz.poll_events(ctx) {
			if ansuz.is_quit_key(event) do return

			// Teclas para ajustar stress level
			if key_event, ok := event.(ansuz.KeyEvent); ok {
				if key_event.key == .Up && g_stats.stress_level < 10 {
					g_stats.stress_level += 1
				} else if key_event.key == .Down && g_stats.stress_level > 1 {
					g_stats.stress_level -= 1
				}
			}
		}

		// Renderiza UI + stress test
		if ansuz.render(ctx) {
			render(ctx)
		}

		// Atualiza estatísticas após o frame
		update_stats(ctx)
	}
}

update_stats :: proc(ctx: ^ansuz.Context) {
	frame_time := ctx.last_frame_time

	g_stats.frame_count += 1
	g_stats.total_time += frame_time

	// Min/Max (ignora frame 0)
	if frame_time < g_stats.min_frame_time && frame_time > 0 && g_stats.frame_count > 1 {
		g_stats.min_frame_time = frame_time
	}
	if frame_time > g_stats.max_frame_time {
		g_stats.max_frame_time = frame_time
	}

	// Histórico para média móvel
	g_history[g_history_idx] = frame_time
	g_history_idx = (g_history_idx + 1) % len(g_history)

	// Calcula média móvel
	total: time.Duration = 0
	count := min(int(g_stats.frame_count), len(g_history))
	for i in 0 ..< count {
		total += g_history[i]
	}
	if count > 0 {
		g_stats.avg_frame_time = total / time.Duration(count)
	}
}

render :: proc(ctx: ^ansuz.Context) {
		// Container principal
		if ansuz.container(ctx, {
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			padding = {1, 1, 0, 0},
			gap = 0,
		}) {
			// Header
			if ansuz.box(ctx, {
				sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(3)},
				alignment = {.Center, .Center},
			}, ansuz.style(.BrightBlue, .Default, {}), .Double) {
				ansuz.label(
					ctx,
					"ANSUZ PERFORMANCE BENCHMARK",
					{style = ansuz.style(.BrightYellow, .Default, {.Bold})},
				)
			}

			// Estatísticas principais
			if ansuz.hstack(ctx, {
				sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(8)},
				gap = 1,
				padding = {0, 0, 1, 0},
			}) {
				// FPS Box
				if ansuz.box(ctx, {
					sizing = {.X = ansuz.grow(1), .Y = ansuz.grow()},
					padding = {1, 1, 1, 1},
					direction = .TopToBottom,
				}, ansuz.style(.Green, .Default, {}), .Rounded) {
					ansuz.label(ctx, "FPS", {style = ansuz.style(.BrightGreen, .Default, {.Bold})})

					fps := calculate_fps()
					fps_str := fmt.tprintf("%.1f", fps)
					ansuz.label(ctx, fps_str, {style = ansuz.style(get_fps_color(fps), .Default, {.Bold})})

					ansuz.label(ctx, "", {style = ansuz.default_style()})
					ansuz.label(
						ctx,
						fmt.tprintf("Frames: %d", g_stats.frame_count),
						{style = ansuz.style(.BrightBlack, .Default, {.Dim})},
					)
				}

				// Frame Time Box
				if ansuz.box(ctx, {
					sizing = {.X = ansuz.grow(1), .Y = ansuz.grow()},
					padding = {1, 1, 1, 1},
					direction = .TopToBottom,
				}, ansuz.style(.Cyan, .Default, {}), .Rounded) {
					ansuz.label(ctx, "Frame Time", {style = ansuz.style(.BrightCyan, .Default, {.Bold})})

					avg_ms := f64(g_stats.avg_frame_time) / f64(time.Millisecond)
					ansuz.label(
						ctx,
						fmt.tprintf("%.2f ms", avg_ms),
						{style = ansuz.style(.White, .Default, {.Bold})},
					)

					min_ms := f64(g_stats.min_frame_time) / f64(time.Millisecond)
					max_ms := f64(g_stats.max_frame_time) / f64(time.Millisecond)
					ansuz.label(
						ctx,
						fmt.tprintf("Min: %.2f ms", min_ms),
						{style = ansuz.style(.BrightBlack, .Default, {})},
					)
					ansuz.label(
						ctx,
						fmt.tprintf("Max: %.2f ms", max_ms),
						{style = ansuz.style(.BrightBlack, .Default, {})},
					)
				}

				// Stress Level Box
				if ansuz.box(ctx, {
					sizing = {.X = ansuz.grow(1), .Y = ansuz.grow()},
					padding = {1, 1, 1, 1},
					direction = .TopToBottom,
				}, ansuz.style(.Magenta, .Default, {}), .Rounded) {
					ansuz.label(ctx, "Stress Level", {style = ansuz.style(.BrightMagenta, .Default, {.Bold})})

					ansuz.label(
						ctx,
						fmt.tprintf("%d / 10", g_stats.stress_level),
						{style = ansuz.style(get_stress_color(g_stats.stress_level), .Default, {.Bold})},
					)

					ansuz.label(ctx, "", {style = ansuz.default_style()})
					ansuz.label(
						ctx,
						fmt.tprintf("Elements: %d", g_stats.elements_count),
						{style = ansuz.style(.BrightBlack, .Default, {.Dim})},
					)
				}
			}

			// Stress test area - NO GLOBALS NEEDED with @(deferred_in_out)!
			stress_rows := g_stats.stress_level * 4
			stress_cols := g_stats.stress_level * 2
			stress_frame := g_stats.frame_count

			if ansuz.box(ctx, {
				sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
				padding = {1, 1, 1, 1},
				direction = .TopToBottom,
				overflow = .Hidden,
			}, ansuz.style(.Yellow, .Default, {}), .Sharp) {
				// Título com info do stress level
				title := fmt.tprintf(
					"Stress Test [Level %d: %d elements]",
					g_stats.stress_level,
					g_stats.stress_level * 20,
				)
				ansuz.label(ctx, title, {style = ansuz.style(.BrightYellow, .Default, {.Bold})})

				// Renderiza cada linha - local vars accessible inside if block!
				for r in 0 ..< stress_rows {
					if ansuz.container(ctx, {
						sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)},
						direction = .LeftToRight,
						overflow = .Hidden,
					}) {
						// Renderiza células - NO GLOBAL NEEDED!
						for c in 0 ..< stress_cols {
							pattern := generate_stress_pattern(r, c, stress_frame)
							color := get_rainbow_color(r + c)
							ansuz.label(ctx, pattern, {style = ansuz.style(color, .Default, {})})
						}
					}
				}

				// Calcula elementos totais
				g_stats.elements_count = stress_rows * stress_cols
			}

			// Controles
			if ansuz.container(ctx, {
				direction = .LeftToRight,
				sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)},
				alignment = {.Center, .Center},
			}) {
				ansuz.label(
					ctx,
					" [Up/Down] Stress | [Q/ESC] Sair",
				{style = ansuz.style(.BrightBlack, .Default, {.Dim})},
			)
			}
		}
}

// Funções auxiliares

calculate_fps :: proc() -> f64 {
	if g_stats.avg_frame_time <= 0 {
		return 0
	}
	return f64(time.Second) / f64(g_stats.avg_frame_time)
}

get_fps_color :: proc(fps: f64) -> ansuz.TerminalColor {
	if fps >= 60 {
		return ansuz.Ansi.BrightGreen
	} else if fps >= 30 {
		return ansuz.Ansi.BrightYellow
	} else if fps >= 15 {
		return ansuz.Ansi.Yellow
	}
	return ansuz.Ansi.BrightRed
}

get_stress_color :: proc(level: int) -> ansuz.TerminalColor {
	if level <= 3 {
		return ansuz.Ansi.BrightGreen
	} else if level <= 6 {
		return ansuz.Ansi.BrightYellow
	} else if level <= 8 {
		return ansuz.Ansi.Yellow
	}
	return ansuz.Ansi.BrightRed
}

get_rainbow_color :: proc(idx: int) -> ansuz.TerminalColor {
	colors := [?]ansuz.TerminalColor {
		ansuz.Ansi.BrightRed,
		ansuz.Ansi.BrightYellow,
		ansuz.Ansi.BrightGreen,
		ansuz.Ansi.BrightCyan,
		ansuz.Ansi.BrightBlue,
		ansuz.Ansi.BrightMagenta,
	}
	return colors[idx % len(colors)]
}

generate_pattern :: proc(row: int, frame: u64) -> string {
	// Gera um padrão ASCII que muda a cada frame para forçar re-renderização
	offset := int(frame) % 26

	// Padrão de letras A-Z que "rotaciona" com o frame
	base := u8('A') + u8((offset + row * 3) % 26)

	// Usa fmt.tprintf para criar string que persiste durante o frame
	return fmt.tprintf(
		"%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c",
		rune(base),
		rune(base + 1),
		rune(base + 2),
		rune(base + 3),
		rune(base + 4),
		rune(base + 5),
		rune(base + 6),
		rune(base + 7),
		rune(base + 8),
		rune(base + 9),
		rune(base + 10),
		rune(base + 11),
		rune(base + 12),
		rune(base + 13),
		rune(base + 14),
		rune(base + 15),
		rune(base + 16),
		rune(base + 17),
		rune(base + 18),
		rune(base + 19),
		rune(base + 20),
		rune(base + 21),
		rune(base + 22),
		rune(base + 23),
		rune(base + 24),
		rune(base + 25),
		rune(base),
		rune(base + 1),
		rune(base + 2),
		rune(base + 3),
		rune(base + 4),
		rune(base + 5),
		rune(base + 6),
		rune(base + 7),
		rune(base + 8),
		rune(base + 9),
		rune(base + 10),
		rune(base + 11),
		rune(base + 12),
		rune(base + 13),
		rune(base + 14),
		rune(base + 15),
		rune(base + 16),
		rune(base + 17),
		rune(base + 18),
		rune(base + 19),
		rune(base + 20),
		rune(base + 21),
		rune(base + 22),
		rune(base + 23),
		rune(base + 24),
		rune(base + 25),
		rune(base),
		rune(base + 1),
		rune(base + 2),
		rune(base + 3),
		rune(base + 4),
		rune(base + 5),
		rune(base + 6),
		rune(base + 7),
	)
}

// Gera um padrão curto para o stress test (usado em cada célula)
generate_stress_pattern :: proc(row, col: int, frame: u64) -> string {
	offset := int(frame) % 26
	base := u8('A') + u8((offset + row + col * 3) % 26)
	// Padrão curto de 8 caracteres por célula
	return fmt.tprintf(
		"%c%c%c%c%c%c%c%c",
		rune(base),
		rune(base + 1),
		rune(base + 2),
		rune(base + 3),
		rune(base + 4),
		rune(base + 5),
		rune(base + 6),
		rune(base + 7),
	)
}
