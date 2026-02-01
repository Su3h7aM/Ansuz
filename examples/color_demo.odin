// color_demo.odin - Demonstração completa das capacidades de cor do Ansuz
//
// Este exemplo mostra:
// - Paleta padrão de 16 cores ANSI
// - Modificadores de estilo (Bold, Dim, Italic, Underline, Blink, Reverse)
// - Paleta de 256 cores (Cubo de Cores 6x6x6 e Grayscale)
// - TrueColor (RGB) com gradientes suaves
// - União de tipos TerminalColor (Ansi, Color256, RGB)

package color_demo

import ansuz "../ansuz"
import "core:fmt"
import "core:math"

main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		return
	}
	defer ansuz.shutdown(ctx)

	ansuz.run(ctx, proc(ctx: ^ansuz.Context) -> bool {
		for event in ansuz.poll_events(ctx) {
			if ansuz.is_quit_key(event) {
				return false
			}
		}

		render(ctx)
		return true
	})
}

render :: proc(ctx: ^ansuz.Context) {
	ansuz.begin_layout(ctx)

	// Container Principal
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
			padding = {2, 2, 1, 1},
			gap = 1,
			alignment = {.Center, .Top},
		},
	)

	// Título
	ansuz.Layout_box(
		ctx,
		ansuz.style(ansuz.Ansi.BrightCyan, ansuz.Ansi.Default, {.Bold}),
		{
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(3)},
			alignment = {.Center, .Center},
			direction = .TopToBottom,
		},
		.Double,
	)
	ansuz.Layout_text(ctx, "ANSUZ COLOR SYSTEM DEMO", ansuz.style_normal())
	ansuz.Layout_end_box(ctx)

	// Seção 1: Cores ANSI (16 cores)
	render_ansi_section(ctx)

	// Seção 2: Estilos e Modificadores
	render_styles_section(ctx)

	// Seção 3: TrueColor (RGB) Gradients
	render_rgb_section(ctx)

	// Seção 4: 256 Colors
	render_256_section(ctx)

	// Rodapé
	ansuz.Layout_text(
		ctx,
		"[Q/ESC] Quit",
		ansuz.style(ansuz.Ansi.BrightBlack, ansuz.Ansi.Default, {.Dim}),
	)

	ansuz.Layout_end_container(ctx)
	ansuz.end_layout(ctx)
}

render_ansi_section :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_text(
		ctx,
		"1. Standard ANSI Colors (16-color palette)",
		ansuz.style(ansuz.Ansi.White, ansuz.Ansi.Default, {.Bold, .Underline}),
	)

	ansuz.Layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(4)}, gap = 1},
	)

	// Normal params
	colors := [?]ansuz.Ansi{.Black, .Red, .Green, .Yellow, .Blue, .Magenta, .Cyan, .White}
	names := [?]string{"Blk", "Red", "Grn", "Yel", "Blu", "Mag", "Cyn", "Wht"}

	for color, i in colors {
		style := ansuz.style_fg(color)
		if color == .Black do style.bg = ansuz.Ansi.White // Hack para ler preto no fundo preto

		ansuz.Layout_box(
			ctx,
			style,
			{sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()}, alignment = {.Center, .Center}},
			.Rounded,
		)
		ansuz.Layout_text(ctx, names[i], style)
		ansuz.Layout_end_box(ctx)
	}
	ansuz.Layout_end_container(ctx)

	// Bright params
	ansuz.Layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(4)}, gap = 1},
	)
	bright_colors := [?]ansuz.Ansi {
		.BrightBlack,
		.BrightRed,
		.BrightGreen,
		.BrightYellow,
		.BrightBlue,
		.BrightMagenta,
		.BrightCyan,
		.BrightWhite,
	}

	for color, i in bright_colors {
		style := ansuz.style_fg(color)
		ansuz.Layout_box(
			ctx,
			style,
			{sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()}, alignment = {.Center, .Center}},
			.Rounded,
		)
		ansuz.Layout_text(ctx, names[i], style) // Reutiliza nomes
		ansuz.Layout_end_box(ctx)
	}
	ansuz.Layout_end_container(ctx)
}

render_styles_section :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_text(
		ctx,
		"2. Styles & Modifiers",
		ansuz.style(ansuz.Ansi.White, ansuz.Ansi.Default, {.Bold, .Underline}),
	)

	ansuz.Layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(3)}, gap = 2},
	)

	ansuz.Layout_text(ctx, "Normal", ansuz.style_normal())
	ansuz.Layout_text(ctx, "Bold", ansuz.style(ansuz.Ansi.Default, ansuz.Ansi.Default, {.Bold}))
	ansuz.Layout_text(ctx, "Dim", ansuz.style(ansuz.Ansi.Default, ansuz.Ansi.Default, {.Dim}))
	ansuz.Layout_text(
		ctx,
		"Italic",
		ansuz.style(ansuz.Ansi.Default, ansuz.Ansi.Default, {.Italic}),
	)
	ansuz.Layout_text(
		ctx,
		"Underline",
		ansuz.style(ansuz.Ansi.Default, ansuz.Ansi.Default, {.Underline}),
	)
	ansuz.Layout_text(ctx, "Blink", ansuz.style(ansuz.Ansi.Default, ansuz.Ansi.Default, {.Blink}))
	ansuz.Layout_text(
		ctx,
		"Reverse",
		ansuz.style(ansuz.Ansi.Default, ansuz.Ansi.Default, {.Reverse}),
	)

	ansuz.Layout_end_container(ctx)
}

render_rgb_section :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_text(
		ctx,
		"3. TrueColor (RGB) Gradients",
		ansuz.style(ansuz.Ansi.White, ansuz.Ansi.Default, {.Bold, .Underline}),
	)

	ansuz.Layout_begin_container(
		ctx,
		{direction = .TopToBottom, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(6)}, gap = 0},
	)

	// Gradiente 1: Vermelho -> Amarelo -> Verde
	ansuz.Layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)}},
	)
	steps := 60
	for i in 0 ..< steps {
		t := f32(i) / f32(steps)
		r := u8(255 * (1.0 - t))
		g := u8(255 * t)
		b := u8(0)
		ansuz.Layout_text(ctx, "█", ansuz.style_fg(ansuz.rgb(r, g, b)))
	}
	ansuz.Layout_end_container(ctx)

	// Gradiente 2: Azul -> Cyan -> Magenta
	ansuz.Layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)}},
	)
	for i in 0 ..< steps {
		t := f32(i) / f32(steps)
		r := u8(255 * t) // 0 -> 255
		g := u8(255 * t) // 0 -> 255
		b := u8(255) // Fixo 255
		// Azul(0,0,255) -> Branco(255,255,255) ?? Não, vamos fazer algo mais bonito
		// Azul(0,0,255) -> Magenta(255,0,255)

		r2 := u8(255 * t)
		g2 := u8(0)
		b2 := u8(255)
		ansuz.Layout_text(ctx, "█", ansuz.style_fg(ansuz.rgb(r2, g2, b2)))
	}
	ansuz.Layout_end_container(ctx)

	// Complex gradient text
	ansuz.Layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)}},
	)
	text := "The Ansuz TUI Library supports 16 million colors with RGB!"
	for i in 0 ..< len(text) {
		t := f32(i) / f32(len(text))
		// Rainbow wave
		r := u8(127 + 127 * math.sin(6.28 * t + 0.0))
		g := u8(127 + 127 * math.sin(6.28 * t + 2.0))
		b := u8(127 + 127 * math.sin(6.28 * t + 4.0))

		str_buf: [1]u8
		str_buf[0] = text[i]
		ansuz.Layout_text(ctx, string(str_buf[:]), ansuz.style_fg(ansuz.rgb(r, g, b)))
	}
	ansuz.Layout_end_container(ctx)

	ansuz.Layout_end_container(ctx)
}

render_256_section :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_text(
		ctx,
		"4. 256-Color Palette (Color Cube & Grayscale)",
		ansuz.style(ansuz.Ansi.White, ansuz.Ansi.Default, {.Bold, .Underline}),
	)

	// Color Cube Slice
	ansuz.Layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(2)}, gap = 0},
	)
	for i in 0 ..< 36 {
		// Primeiras 36 cores do cubo (indices 16-51)
		ansuz.Layout_text(ctx, "■ ", ansuz.style_fg(ansuz.color256(u8(16 + i))))
	}
	ansuz.Layout_end_container(ctx)

	// Grayscale ramp
	ansuz.Layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(2)}, gap = 0},
	)
	for i in 0 ..< 24 {
		// Grayscale indices 232-255
		ansuz.Layout_text(ctx, "█ ", ansuz.style_fg(ansuz.color256(u8(232 + i))))
	}
	ansuz.Layout_end_container(ctx)
}
