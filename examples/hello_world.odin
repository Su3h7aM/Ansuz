// hello_world.odin - Exemplo mínimo demonstrando a API scoped do Ansuz
//
// Este exemplo mostra:
// - Inicialização e shutdown do contexto
// - Loop de eventos com ansuz.run()
// - Sistema de layout com API scoped (@deferred_in_out)
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
	// API scoped com @(deferred_in_out) - sem callbacks, sem begin/end explícitos
	if ansuz.layout(ctx) {
		// Container principal que preenche toda a tela
		if ansuz.container(ctx, {
			direction = .TopToBottom,
			sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
			alignment = {.Center, .Center}, // Centraliza o conteúdo
		}) {
			// Box com bordas arredondadas
			if ansuz.box(ctx, {
				sizing = {.X = ansuz.fixed(40), .Y = ansuz.fixed(9)},
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

				// Instruções
				ansuz.label(ctx, "[Q/ESC] sair", ansuz.Element{
					style = ansuz.style(.BrightBlack, .Default, {.Dim}),
				})
			}
		}
	}
}
