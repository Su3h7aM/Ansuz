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
	ansuz.layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			sizing    = {ansuz.sizing_grow(), ansuz.sizing_grow()},
			alignment = {.Center, .Center}, // Centraliza o conteúdo
		},
	)

	// Box com bordas arredondadas
	ansuz.layout_box(
		ctx,
		ansuz.style(.BrightCyan, .Default, {}),
		{
			sizing = {ansuz.sizing_fixed(40), ansuz.sizing_fixed(9)},
			padding = ansuz.padding_all(1),
			alignment = {.Center, .Center},
			direction = .TopToBottom,
			gap = 1,
		},
		.Rounded,
	)
	// Título com estilo
	ansuz.layout_text(
		ctx,
		"Hello, Ansuz!",
		ansuz.style(.BrightYellow, .Default, {.Bold}),
	)

	// Subtítulo
	ansuz.layout_text(ctx, "Uma biblioteca TUI para Odin", ansuz.style(.White, .Default, {}))

	// Instruções
	ansuz.layout_text(
		ctx,
		"[Q/ESC] sair",
		ansuz.style(.BrightBlack, .Default, {.Dim}),
	)

	ansuz.layout_end_container(ctx)

	ansuz.layout_end_container(ctx)

	ansuz.end_layout(ctx)
}
