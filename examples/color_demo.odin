// color_demo.odin - Demonstração completa das capacidades de cor do Ansuz
//
// Este exemplo mostra:
// - Paleta padrão de 16 cores ANSI
// - Modificadores de estilo (Bold, Dim, Italic, Underline, Blink, Reverse)
// - Paleta de 256 cores (Cubo de Cores 6x6x6 e Grayscale)
// - TrueColor (RGB) com gradientes suaves
// - União de tipos TerminalColor (Ansi, Color256, RGB)
// - API 100% scoped com callbacks

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
	// API 100% scoped - sem begin/end explícitos
	ansuz.layout(ctx, proc(ctx: ^ansuz.Context) {
		// Container Principal
		ansuz.container(ctx, {
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			padding = {2, 2, 1, 1},
			gap = 1,
			alignment = {.Center, .Top},
		}, proc(ctx: ^ansuz.Context) {
			// Título
			ansuz.box(ctx, {
				sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(3)},
				alignment = {.Center, .Center},
				direction = .TopToBottom,
			}, ansuz.style(.BrightCyan, .Default, {.Bold}), .Double, proc(ctx: ^ansuz.Context) {
				ansuz.label(ctx, "ANSUZ COLOR SYSTEM DEMO", ansuz.Element{style = ansuz.default_style()})
			})

			// Seção 1: Cores ANSI (16 cores)
			render_ansi_section(ctx)

			// Seção 2: Estilos e Modificadores
			render_styles_section(ctx)

			// Seção 3: TrueColor (RGB) Gradients
			render_rgb_section(ctx)

			// Seção 4: 256 Colors
			render_256_section(ctx)

			// Rodapé
			ansuz.label(ctx, "[Q/ESC] Quit", ansuz.Element{style = ansuz.style(.BrightBlack, .Default, {.Dim})})
		})
	})
}

render_ansi_section :: proc(ctx: ^ansuz.Context) {
	ansuz.label(
		ctx,
		"1. Standard ANSI Colors (16-color palette)",
		ansuz.Element{style = ansuz.style(.White, .Default, {.Bold, .Underline})},
	)

	// Normal colors
	ansuz.hstack(ctx, {
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(4)},
		gap = 1,
	}, proc(ctx: ^ansuz.Context) {
		colors := [?]ansuz.Ansi{.Black, .Red, .Green, .Yellow, .Blue, .Magenta, .Cyan, .White}
		names := [?]string{"Blk", "Red", "Grn", "Yel", "Blu", "Mag", "Cyn", "Wht"}

		for color, i in colors {
			box_style := ansuz.style(color, .Default, {})
			if color == .Black do box_style.bg = .White
			ansuz.label(ctx, names[i], ansuz.Element{
				style = box_style,
				sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			})
		}
	})

	// Bright colors
	ansuz.hstack(ctx, {
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(4)},
		gap = 1,
	}, proc(ctx: ^ansuz.Context) {
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
		names := [?]string{"Blk", "Red", "Grn", "Yel", "Blu", "Mag", "Cyn", "Wht"}

		for color, i in bright_colors {
			box_style := ansuz.style(color, .Default, {})
			ansuz.label(ctx, names[i], ansuz.Element{
				style = box_style,
				sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			})
		}
	})
}

render_styles_section :: proc(ctx: ^ansuz.Context) {
	ansuz.label(
		ctx,
		"2. Styles & Modifiers",
		ansuz.Element{style = ansuz.style(.White, .Default, {.Bold, .Underline})},
	)

	ansuz.hstack(ctx, {
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(3)},
		gap = 2,
	}, proc(ctx: ^ansuz.Context) {
		ansuz.label(ctx, "Normal", ansuz.Element{style = ansuz.default_style()})
		ansuz.label(ctx, "Bold", ansuz.Element{style = ansuz.style(.Default, .Default, {.Bold})})
		ansuz.label(ctx, "Dim", ansuz.Element{style = ansuz.style(.Default, .Default, {.Dim})})
		ansuz.label(ctx, "Italic", ansuz.Element{style = ansuz.style(.Default, .Default, {.Italic})})
		ansuz.label(ctx, "Underline", ansuz.Element{style = ansuz.style(.Default, .Default, {.Underline})})
		ansuz.label(ctx, "Blink", ansuz.Element{style = ansuz.style(.Default, .Default, {.Blink})})
		ansuz.label(ctx, "Reverse", ansuz.Element{style = ansuz.style(.Default, .Default, {.Reverse})})
	})
}

render_rgb_section :: proc(ctx: ^ansuz.Context) {
	ansuz.label(
		ctx,
		"3. TrueColor (RGB) Gradients",
		ansuz.Element{style = ansuz.style(.White, .Default, {.Bold, .Underline})},
	)

	ansuz.vstack(ctx, {
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(6)},
		gap = 0,
	}, proc(ctx: ^ansuz.Context) {
		// Gradiente 1: Vermelho -> Amarelo -> Verde
		ansuz.hstack(ctx, {sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)}}, proc(ctx: ^ansuz.Context) {
			steps := 60
			for i in 0 ..< steps {
				t := f32(i) / f32(steps)
				r := u8(255 * (1.0 - t))
				g := u8(255 * t)
				b := u8(0)
				ansuz.label(ctx, "█", ansuz.Element{style = ansuz.style(ansuz.rgb(r, g, b), .Default, {})})
			}
		})

		// Gradiente 2: Azul -> Cyan -> Magenta
		ansuz.hstack(ctx, {sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)}}, proc(ctx: ^ansuz.Context) {
			for i in 0 ..< 60 {
				t := f32(i) / 60.0
				r := u8(255 * t)
				g := u8(0)
				b := u8(255)
				ansuz.label(ctx, "█", ansuz.Element{style = ansuz.style(ansuz.rgb(r, g, b), .Default, {})})
			}
		})

		// Complex gradient text
		ansuz.hstack(ctx, {sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(1)}}, proc(ctx: ^ansuz.Context) {
			text := "The Ansuz TUI Library supports 16 million colors with RGB!"
			for i in 0 ..< len(text) {
				t := f32(i) / f32(len(text))
				// Rainbow wave
				r := u8(127 + 127 * math.sin(6.28 * t + 0.0))
				g := u8(127 + 127 * math.sin(6.28 * t + 2.0))
				b := u8(127 + 127 * math.sin(6.28 * t + 4.0))

				str_buf: [1]u8
				str_buf[0] = text[i]
				ansuz.label(
					ctx,
					string(str_buf[:]),
					ansuz.Element{style = ansuz.style(ansuz.rgb(r, g, b), .Default, {})},
				)
			}
		})
	})
}

render_256_section :: proc(ctx: ^ansuz.Context) {
	ansuz.label(
		ctx,
		"4. 256-Color Palette (Color Cube & Grayscale)",
		ansuz.Element{style = ansuz.style(.White, .Default, {.Bold, .Underline})},
	)

	// Color Cube Slice
	ansuz.hstack(ctx, {
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(2)},
		gap = 0,
	}, proc(ctx: ^ansuz.Context) {
		for i in 0 ..< 36 {
			// Primeiras 36 cores do cubo (indices 16-51)
			ansuz.label(ctx, "■ ", ansuz.Element{style = ansuz.style(ansuz.color256(u8(16 + i)), .Default, {})})
		}
	})

	// Grayscale ramp
	ansuz.hstack(ctx, {
		sizing = {.X = ansuz.grow(), .Y = ansuz.fixed(2)},
		gap = 0,
	}, proc(ctx: ^ansuz.Context) {
		for i in 0 ..< 24 {
			// Grayscale indices 232-255
			ansuz.label(ctx, "█ ", ansuz.Element{style = ansuz.style(ansuz.color256(u8(232 + i)), .Default, {})})
		}
	})
}
