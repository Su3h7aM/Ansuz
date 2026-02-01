// hello_world.odin - Exemplo mínimo demonstrando a API básica do Ansuz
//
// Este exemplo mostra:
// - Inicialização e shutdown do contexto
// - Loop de eventos com ansuz.run()
// - Sistema de layout com containers e boxes
// - Texto estilizado com cores
// - Centralização de elementos
// - Tratamento de eventos (Ctrl+C para sair)

package hello_world

import ansuz "../ansuz"

main :: proc() {
	// Inicializa o contexto Ansuz
	ctx, err := ansuz.init()
	if err != .None {
		return
	}
	defer ansuz.shutdown(ctx)

	// Executa o loop de eventos
	ansuz.run(
		ctx,
		proc(ctx: ^ansuz.Context) -> bool {
			// Processa eventos de entrada
			for event in ansuz.poll_events(ctx) {
				if ansuz.is_quit_key(event) {
					return false // Sair do loop
				}
			}

			// Renderiza a UI
			render(ctx)
			return true
		},
	)
}

render :: proc(ctx: ^ansuz.Context) {
	ansuz.begin_layout(ctx)

	// Container principal que preenche toda a tela
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			sizing    = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
			alignment = {.Center, .Center}, // Centraliza o conteúdo
		},
	)

	// Box com bordas arredondadas
	ansuz.Layout_box(
		ctx,
		ansuz.Style{.BrightCyan, .Default, {}},
		{
			sizing = {ansuz.Sizing_fixed(40), ansuz.Sizing_fixed(9)},
			padding = ansuz.Padding_all(1),
			alignment = {.Center, .Center},
			direction = .TopToBottom,
			gap = 1,
		},
		.Rounded,
	)
	// Título com estilo
	ansuz.Layout_text(ctx, "Hello, Ansuz!", ansuz.Style{.BrightYellow, .Default, {.Bold}})

	// Subtítulo
	ansuz.Layout_text(ctx, "Uma biblioteca TUI para Odin", ansuz.Style{.White, .Default, {}})

	// Instruções
	ansuz.Layout_text(ctx, "[Q/ESC] sair", ansuz.Style{.BrightBlack, .Default, {.Dim}})

	ansuz.Layout_end_box(ctx)

	ansuz.Layout_end_container(ctx)

	ansuz.end_layout(ctx)
}
