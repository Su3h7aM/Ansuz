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
	ansuz.layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			padding = {2, 2, 1, 1},
			gap = 1,
			alignment = {.Center, .Top},
		},
	)

	// Título
	ansuz.layout_box(
		ctx,
		ansuz.style(.BrightCyan, .Default, {.Bold}),
		{
			sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(3)},
			alignment = {.Center, .Center},
			direction = .TopToBottom,
		},
		.Double,
	)
	ansuz.layout_text(ctx, "ANSUZ COLOR SYSTEM DEMO", ansuz.default_style())
	ansuz.layout_end_container(ctx)

	// Seção 1: Cores ANSI (16 cores)
	render_ansi_section(ctx)

	// Seção 2: Estilos e Modificadores
	render_styles_section(ctx)

	// Seção 3: TrueColor (RGB) Gradients
	render_rgb_section(ctx)

	// Seção 4: 256 Colors
	render_256_section(ctx)

	// Rodapé
	ansuz.layout_text(ctx, "[Q/ESC] Quit", ansuz.style(.BrightBlack, .Default, {.Dim}))

	ansuz.layout_end_container(ctx)
	ansuz.end_layout(ctx)
}

render_ansi_section :: proc(ctx: ^ansuz.Context) {
	ansuz.layout_text(
		ctx,
		"1. Standard ANSI Colors (16-color palette)",
		ansuz.style(.White, .Default, {.Bold, .Underline}),
	)

	ansuz.layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(4)}, gap = 1},
	)

	// Normal params
	colors := [?]ansuz.Ansi{.Black, .Red, .Green, .Yellow, .Blue, .Magenta, .Cyan, .White}
	names := [?]string{"Blk", "Red", "Grn", "Yel", "Blu", "Mag", "Cyn", "Wht"}

	for color, i in colors {
		style := ansuz.style(color, .Default, {})
		if color == .Black do style.bg = .White // Hack para ler preto no fundo preto

		ansuz.layout_box(
			ctx,
			style,
			{sizing = {.X = ansuz.grow(), .Y = ansuz.grow()}, alignment = {.Center, .Center}},
			.Rounded,
		)
		ansuz.layout_text(ctx, names[i], style)
		ansuz.layout_end_container(ctx)
	}
	ansuz.layout_end_container(ctx)

	// Bright params
	ansuz.layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(4)}, gap = 1},
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
		style := ansuz.style(color, .Default, {})
		ansuz.layout_box(
			ctx,
			style,
			{sizing = {.X = ansuz.grow(), .Y = ansuz.grow()}, alignment = {.Center, .Center}},
			.Rounded,
		)
		ansuz.layout_text(ctx, names[i], style) // Reutiliza nomes
		ansuz.layout_end_container(ctx)
	}
	ansuz.layout_end_container(ctx)
}

render_styles_section :: proc(ctx: ^ansuz.Context) {
	ansuz.layout_text(
		ctx,
		"2. Styles & Modifiers",
		ansuz.style(.White, .Default, {.Bold, .Underline}),
	)

	ansuz.layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(3)}, gap = 2},
	)

	ansuz.layout_text(ctx, "Normal", ansuz.default_style())
	ansuz.layout_text(ctx, "Bold", ansuz.style(.Default, .Default, {.Bold}))
	ansuz.layout_text(ctx, "Dim", ansuz.style(.Default, .Default, {.Dim}))
	ansuz.layout_text(ctx, "Italic", ansuz.style(.Default, .Default, {.Italic}))
	ansuz.layout_text(ctx, "Underline", ansuz.style(.Default, .Default, {.Underline}))
	ansuz.layout_text(ctx, "Blink", ansuz.style(.Default, .Default, {.Blink}))
	ansuz.layout_text(ctx, "Reverse", ansuz.style(.Default, .Default, {.Reverse}))

	ansuz.layout_end_container(ctx)
}

render_rgb_section :: proc(ctx: ^ansuz.Context) {
	ansuz.layout_text(
		ctx,
		"3. TrueColor (RGB) Gradients",
		ansuz.style(.White, .Default, {.Bold, .Underline}),
	)

	ansuz.layout_begin_container(
		ctx,
		{direction = .TopToBottom, sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(6)}, gap = 0},
	)

	// Gradiente 1: Vermelho -> Amarelo -> Verde
	ansuz.layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)}},
	)
	steps := 60
	for i in 0 ..< steps {
		t := f32(i) / f32(steps)
		r := u8(255 * (1.0 - t))
		g := u8(255 * t)
		b := u8(0)
		ansuz.layout_text(ctx, "█", ansuz.style(ansuz.rgb(r, g, b), .Default, {}))
	}
	ansuz.layout_end_container(ctx)

	// Gradiente 2: Azul -> Cyan -> Magenta
	ansuz.layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)}},
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
		ansuz.layout_text(ctx, "█", ansuz.style(ansuz.rgb(r2, g2, b2), .Default, {}))
	}
	ansuz.layout_end_container(ctx)

	// Complex gradient text
	ansuz.layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)}},
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
		ansuz.layout_text(ctx, string(str_buf[:]), ansuz.style(ansuz.rgb(r, g, b), .Default, {}))
	}
	ansuz.layout_end_container(ctx)

	ansuz.layout_end_container(ctx)
}

render_256_section :: proc(ctx: ^ansuz.Context) {
	ansuz.layout_text(
		ctx,
		"4. 256-Color Palette (Color Cube & Grayscale)",
		ansuz.style(.White, .Default, {.Bold, .Underline}),
	)

	// Color Cube Slice
	ansuz.layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(2)}, gap = 0},
	)
	for i in 0 ..< 36 {
		// Primeiras 36 cores do cubo (indices 16-51)
		ansuz.layout_text(ctx, "■ ", ansuz.style(ansuz.color256(u8(16 + i)), .Default, {}))
	}
	ansuz.layout_end_container(ctx)

	// Grayscale ramp
	ansuz.layout_begin_container(
		ctx,
		{direction = .LeftToRight, sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(2)}, gap = 0},
	)
	for i in 0 ..< 24 {
		// Grayscale indices 232-255
		ansuz.layout_text(ctx, "█ ", ansuz.style(ansuz.color256(u8(232 + i)), .Default, {}))
	}
	ansuz.layout_end_container(ctx)
}
