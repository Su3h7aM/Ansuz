// benchmark.odin - Benchmark de performance do Ansuz
//
// Este exemplo demonstra:
// - Medição de tempo com time.Duration
// - get_last_frame_time() para calcular FPS
// - Renderização intensiva para stress test
// - Estatísticas em tempo real
// - Loop contínuo (não event-driven)
// - API 100% scoped com callbacks

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

	// Loop contínuo para benchmark real (não usa ansuz.run que é event-driven)
	for {
		ansuz.begin_frame(ctx)

		// Processa eventos de entrada (non-blocking)
		for event in ansuz.poll_events(ctx) {
			if ansuz.is_quit_key(event) {
				ansuz.end_frame(ctx)
				return
			}

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
		render(ctx)

		ansuz.end_frame(ctx)

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
	width, height := ctx.width, ctx.height

	// API 100% scoped - sem begin/end explícitos
	ansuz.layout(ctx, proc(ctx: ^ansuz.Context) {
		// Container principal
		ansuz.container(ctx, {
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			padding = {1, 1, 0, 0},
			gap = 0,
		}, proc(ctx: ^ansuz.Context) {
			// Header
			render_header(ctx)

			// Estatísticas principais
			render_main_stats(ctx)

			// Stress test area
			render_stress_test(ctx, width, height)

			// Controles
			render_controls(ctx)
		})
	})
}

render_header :: proc(ctx: ^ansuz.Context) {
	ansuz.box(ctx, {
		style = ansuz.style(.BrightBlue, .Default, {}),
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(3)},
		alignment = {.Center, .Center},
	}, .Double, proc(ctx: ^ansuz.Context) {
		ansuz.label(
			ctx,
			"ANSUZ PERFORMANCE BENCHMARK",
			{style = ansuz.style(.BrightYellow, .Default, {.Bold})},
		)
	})
}

render_main_stats :: proc(ctx: ^ansuz.Context) {
	ansuz.hstack(ctx, {
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(8)},
		gap = 1,
		padding = {0, 0, 1, 0},
	}, proc(ctx: ^ansuz.Context) {
		// FPS Box
		ansuz.box(ctx, {
			style = ansuz.style(.Green, .Default, {}),
			sizing = {.X = ansuz.grow(1), .Y = ansuz.grow()},
			padding = {1, 1, 1, 1},
			direction = .TopToBottom,
		}, .Rounded, proc(ctx: ^ansuz.Context) {
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
		})

		// Frame Time Box
		ansuz.box(ctx, {
			style = ansuz.style(.Cyan, .Default, {}),
			sizing = {.X = ansuz.grow(1), .Y = ansuz.grow()},
			padding = {1, 1, 1, 1},
			direction = .TopToBottom,
		}, .Rounded, proc(ctx: ^ansuz.Context) {
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
		})

		// Stress Level Box
		ansuz.box(ctx, {
			style = ansuz.style(.Magenta, .Default, {}),
			sizing = {.X = ansuz.grow(1), .Y = ansuz.grow()},
			padding = {1, 1, 1, 1},
			direction = .TopToBottom,
		}, .Rounded, proc(ctx: ^ansuz.Context) {
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
		})
	})
}

render_stress_test :: proc(ctx: ^ansuz.Context, width, height: int) {
	ansuz.box(ctx, {
		style = ansuz.style(.Yellow, .Default, {}),
		sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
		padding = {1, 1, 1, 1},
		direction = .TopToBottom,
		overflow = .Hidden,
	}, .Sharp, proc(ctx: ^ansuz.Context) {
		// Título com info do stress level
		title := fmt.tprintf(
			"Stress Test [Level %d: %d elements]",
			g_stats.stress_level,
			g_stats.stress_level * 20,
		)
		ansuz.label(ctx, title, {style = ansuz.style(.BrightYellow, .Default, {.Bold})})

		// Container principal para stress test
		ansuz.vstack(ctx, {
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			overflow = .Hidden,
			gap = 0,
		}, proc(ctx: ^ansuz.Context) {
			// O stress level controla quantos CONTAINERS aninhados criamos
			// Cada nível adiciona mais complexidade de layout
			elements := 0
			rows := g_stats.stress_level * 4 // 4-40 linhas baseado no level (mais pesado)

			for row in 0 ..< rows {
				// Cada linha é um container horizontal
				ansuz.hstack(ctx, {
					sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)},
					overflow = .Hidden,
				}, proc(ctx: ^ansuz.Context) {
					// Número de elementos por linha também depende do stress level (2x)
					cols := g_stats.stress_level * 2
					for col in 0 ..< cols {
						pattern := generate_stress_pattern(row, col, g_stats.frame_count)
						color := get_rainbow_color(row + col)
						ansuz.label(ctx, pattern, {style = ansuz.style(color, .Default, {})})
						elements += 1
					}
				})
			}

			g_stats.elements_count = elements
		})
	})
}

render_controls :: proc(ctx: ^ansuz.Context) {
	ansuz.container(ctx, {
		direction = .LeftToRight,
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)},
		alignment = {.Center, .Center},
	}, proc(ctx: ^ansuz.Context) {
		ansuz.label(
			ctx,
			" [Up/Down] Stress | [Q/ESC] Sair",
			{style = ansuz.style(.BrightBlack, .Default, {.Dim})},
		)
	})
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
		"%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c",
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

make_frame_graph :: proc() -> string {
	// Encontra min e max para normalização
	min_val: time.Duration = time.Duration(999 * time.Millisecond)
	max_val: time.Duration = 0
	valid_count := 0

	for ft in g_history {
		if ft > 0 {
			valid_count += 1
			if ft > max_val do max_val = ft
			if ft < min_val do min_val = ft
		}
	}

	// Caracteres ASCII para o gráfico (altura crescente)
	bars := [8]rune{'.', '-', '=', '+', '*', '#', '@', '@'}

	// Gera 60 caracteres de gráfico, lendo na ordem correta do buffer circular
	graph_chars: [60]rune

	// Se não temos dados suficientes, mostra slots vazios preenchidos conforme os dados entram
	if valid_count < 2 {
		for i in 0 ..< 60 {
			idx := (g_history_idx + i) % 60
			if g_history[idx] > 0 {
				graph_chars[i] = '#'
			} else {
				graph_chars[i] = ' '
			}
		}
	} else {
		// Usa escala absoluta: 0-16ms (para ~60fps: 16.67ms/frame)
		// Valores acima de 16ms ficam no topo
		scale_max := time.Duration(16 * time.Millisecond)

		for i in 0 ..< 60 {
			idx := (g_history_idx + i) % 60
			ft := g_history[idx]
			if ft <= 0 {
				graph_chars[i] = ' '
			} else {
				// Normaliza usando escala absoluta
				normalized := int(f64(ft) / f64(scale_max) * 7)
				if normalized > 7 do normalized = 7
				if normalized < 0 do normalized = 0
				graph_chars[i] = bars[normalized]
			}
		}
	}

	return fmt.tprintf(
		"%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c",
		graph_chars[0],
		graph_chars[1],
		graph_chars[2],
		graph_chars[3],
		graph_chars[4],
		graph_chars[5],
		graph_chars[6],
		graph_chars[7],
		graph_chars[8],
		graph_chars[9],
		graph_chars[10],
		graph_chars[11],
		graph_chars[12],
		graph_chars[13],
		graph_chars[14],
		graph_chars[15],
		graph_chars[16],
		graph_chars[17],
		graph_chars[18],
		graph_chars[19],
		graph_chars[20],
		graph_chars[21],
		graph_chars[22],
		graph_chars[23],
		graph_chars[24],
		graph_chars[25],
		graph_chars[26],
		graph_chars[27],
		graph_chars[28],
		graph_chars[29],
		graph_chars[30],
		graph_chars[31],
		graph_chars[32],
		graph_chars[33],
		graph_chars[34],
		graph_chars[35],
		graph_chars[36],
		graph_chars[37],
		graph_chars[38],
		graph_chars[39],
		graph_chars[40],
		graph_chars[41],
		graph_chars[42],
		graph_chars[43],
		graph_chars[44],
		graph_chars[45],
		graph_chars[46],
		graph_chars[47],
		graph_chars[48],
		graph_chars[49],
		graph_chars[50],
		graph_chars[51],
		graph_chars[52],
		graph_chars[53],
		graph_chars[54],
		graph_chars[55],
		graph_chars[56],
		graph_chars[57],
		graph_chars[58],
		graph_chars[59],
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
