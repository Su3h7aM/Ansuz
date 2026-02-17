// hello_world.odin - Exemplo mínimo demonstrando a API do Ansuz
//
// Este exemplo mostra:
// - Inicialização e shutdown do contexto
// - Loop de eventos com render() + wait_for_event()
// - Sistema de layout com API scoped (@deferred_in_out)
// - Texto estilizado com cores
// - Centralização de elementos
// - Tratamento de eventos (Ctrl+C para sair)

package hello_world

import ansuz "../ansuz"
import "core:fmt"

frame_count: i32

main :: proc() {
	// Inicializa o contexto Ansuz
	ctx, err := ansuz.init()
	if err != .None {
		return
	}
	defer ansuz.shutdown(ctx)

	// Loop principal
	for {
		// Processa eventos de entrada
		for event in ansuz.poll_events(ctx) {
			if ansuz.is_quit_key(event) do return
		}

		// Renderiza a UI
		if ansuz.render(ctx) {
			frame_count += 1
			render(ctx)
		}

		// Aguarda próximo evento
		ansuz.wait_for_event(ctx)
	}
}

render :: proc(ctx: ^ansuz.Context) {
	// Container principal que preenche toda a tela
	if ansuz.container(ctx, {
		direction = .TopToBottom,
		sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
		alignment = {.Center, .Center}, // Centraliza o conteúdo
	}) {
		// Box com bordas arredondadas
		if ansuz.box(ctx, {
			sizing = {.X = ansuz.fixed(40), .Y = ansuz.fixed(10)},
			padding = ansuz.padding_all(1),
			alignment = {.Center, .Center},
			direction = .TopToBottom,
			gap = 1,
		}, ansuz.style(.BrightCyan, .Default, {}), .Rounded) {
			// Título com estilo
			ansuz.label(ctx, "Hello, Ansuz!", ansuz.Element{
				style = ansuz.style(.BrightYellow, .Default, {.Bold}),
			})

			// Subtítulo
			ansuz.label(ctx, "Uma biblioteca TUI para Odin", ansuz.Element{
				style = ansuz.style(.White, .Default, {}),
			})

			// Contador de frames
			frame_str := fmt.tprintf("Frame: %d", frame_count)
			ansuz.label(ctx, frame_str, ansuz.Element{
				style = ansuz.style(.BrightGreen, .Default, {}),
			})

			// Instruções
			ansuz.label(ctx, "[Q/ESC] sair", ansuz.Element{
				style = ansuz.style(.BrightBlack, .Default, {.Dim}),
			})
		}
	}
}
