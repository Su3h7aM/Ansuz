// explorer.odin - File Explorer TUI
//
// Este exemplo demonstra:
// - Navegação interativa com teclado (Up/Down/Enter/Backspace)
// - Leitura real do filesystem
// - Scroll automático para listas longas
// - Diferentes estilos para arquivos vs diretórios
// - Status bar dinâmica com info do item selecionado
// - Layout responsivo

package explorer

import ansuz "../ansuz"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

// Estado do explorer
ExplorerState :: struct {
	current_path:  string,
	entries:       [dynamic]Entry,
	selected:      int,
	scroll_offset: int,
	error_msg:     string,
}

Entry :: struct {
	name:     string,
	is_dir:   bool,
	size:     i64,
	readable: bool,
}

g_state: ExplorerState

main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		return
	}
	defer ansuz.shutdown(ctx)

	// Inicializa no diretório atual
	init_explorer()
	defer cleanup_explorer()

	// Loop principal - usa ansuz.run() para resposta imediata a eventos
	ansuz.run(ctx, proc(ctx: ^ansuz.Context) -> bool {
		for event in ansuz.poll_events(ctx) {
			if ansuz.is_quit_key(event) {
				return false
			}
			handle_input(event)
		}

		render(ctx)
		return true
	})
}

init_explorer :: proc() {
	g_state.current_path = os.get_current_directory()
	g_state.entries = make([dynamic]Entry)
	load_directory()
}

cleanup_explorer :: proc() {
	delete(g_state.entries)
}

load_directory :: proc() {
	clear(&g_state.entries)
	g_state.selected = 0
	g_state.scroll_offset = 0
	g_state.error_msg = ""

	// Abre o diretório
	handle, err := os.open(g_state.current_path)
	if err != os.ERROR_NONE {
		g_state.error_msg = "Erro ao abrir diretorio"
		return
	}
	defer os.close(handle)

	// Lê as entradas
	file_infos, read_err := os.read_dir(handle, -1)
	if read_err != os.ERROR_NONE {
		g_state.error_msg = "Erro ao ler diretorio"
		return
	}

	// Adiciona ".." para voltar (exceto na raiz)
	if g_state.current_path != "/" {
		append(&g_state.entries, Entry{name = "..", is_dir = true, size = 0, readable = true})
	}

	// Separa dirs e arquivos para ordenar
	dirs: [dynamic]Entry
	files: [dynamic]Entry
	defer delete(dirs)
	defer delete(files)

	for fi in file_infos {
		entry := Entry {
			name     = strings.clone(fi.name),
			is_dir   = os.is_dir(fi.fullpath),
			size     = fi.size,
			readable = true,
		}

		if entry.is_dir {
			append(&dirs, entry)
		} else {
			append(&files, entry)
		}
	}

	// Adiciona dirs primeiro, depois arquivos
	for d in dirs {
		append(&g_state.entries, d)
	}
	for f in files {
		append(&g_state.entries, f)
	}
}

handle_input :: proc(event: ansuz.Event) {
	if key_event, ok := event.(ansuz.KeyEvent); ok {
		#partial switch key_event.key {
		case .Up:
			if g_state.selected > 0 {
				g_state.selected -= 1
			}
		case .Down:
			if g_state.selected < len(g_state.entries) - 1 {
				g_state.selected += 1
			}
		case .Enter:
			if len(g_state.entries) > 0 {
				enter_selected()
			}
		case .Backspace:
			go_up()
		case .Home:
			g_state.selected = 0
		case .End:
			g_state.selected = max(0, len(g_state.entries) - 1)
		case .PageUp:
			g_state.selected = max(0, g_state.selected - 10)
		case .PageDown:
			g_state.selected = min(len(g_state.entries) - 1, g_state.selected + 10)
		case:
		}
	}
}

enter_selected :: proc() {
	if g_state.selected >= len(g_state.entries) {
		return
	}

	entry := g_state.entries[g_state.selected]

	if !entry.is_dir {
		return // Não entra em arquivos
	}

	if entry.name == ".." {
		go_up()
		return
	}

	// Entra no diretório
	new_path := filepath.join({g_state.current_path, entry.name})
	g_state.current_path = new_path
	load_directory()
}

go_up :: proc() {
	parent := filepath.dir(g_state.current_path)
	if parent != g_state.current_path {
		g_state.current_path = parent
		load_directory()
	}
}

render :: proc(ctx: ^ansuz.Context) {
	_, height := ansuz.get_size(ctx)

	ansuz.begin_layout(ctx)

	// Container principal
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
			padding = {1, 1, 0, 0},
			gap = 0,
		},
	)

	render_header(ctx)
	render_file_list(ctx, height)
	render_status_bar(ctx)

	ansuz.Layout_end_container(ctx)

	ansuz.end_layout(ctx)
}

render_header :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_box(
		ctx,
		ansuz.style_fg(ansuz.Ansi.BrightBlue),
		{
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(3)},
			padding = {1, 1, 1, 1},
			direction = .TopToBottom,
		},
		.Rounded,
	)
	ansuz.Layout_text(
		ctx,
		"File Explorer",
		ansuz.style(ansuz.Ansi.BrightCyan, ansuz.Ansi.Default, {.Bold}),
	)

	// Caminho atual (truncado se muito longo)
	path_display := g_state.current_path
	if len(path_display) > 60 {
		path_display = fmt.tprintf("...%s", path_display[len(path_display) - 57:])
	}
	ansuz.Layout_text(ctx, path_display, ansuz.style_fg(ansuz.Ansi.White))
	ansuz.Layout_end_box(ctx)
}

render_file_list :: proc(ctx: ^ansuz.Context, screen_height: int) {
	ansuz.Layout_box(
		ctx,
		ansuz.style_fg(ansuz.Ansi.Yellow),
		{
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
			padding = {1, 1, 1, 1},
			direction = .TopToBottom,
			overflow = .Hidden,
		},
		.Sharp,
	)

	if g_state.error_msg != "" {
		ansuz.Layout_text(
			ctx,
			g_state.error_msg,
			ansuz.style(ansuz.Ansi.BrightRed, ansuz.Ansi.Default, {.Bold}),
		)
		ansuz.Layout_end_box(ctx)
		return
	}

	if len(g_state.entries) == 0 {
		ansuz.Layout_text(
			ctx,
			"(diretorio vazio)",
			ansuz.style(ansuz.Ansi.BrightBlack, ansuz.Ansi.Default, {.Dim}),
		)
		ansuz.Layout_end_box(ctx)
		return
	}

	// Calcula janela visível (considerando header + status = ~6 linhas)
	visible_lines := screen_height - 8
	if visible_lines < 3 do visible_lines = 3

	// Ajusta scroll para manter seleção visível
	if g_state.selected < g_state.scroll_offset {
		g_state.scroll_offset = g_state.selected
	}
	if g_state.selected >= g_state.scroll_offset + visible_lines {
		g_state.scroll_offset = g_state.selected - visible_lines + 1
	}

	// Renderiza entradas visíveis
	for i := g_state.scroll_offset;
	    i < min(len(g_state.entries), g_state.scroll_offset + visible_lines);
	    i += 1 {
		entry := g_state.entries[i]
		is_selected := i == g_state.selected

		// Ícone e cor baseado no tipo
		icon: string
		color: ansuz.Ansi
		if entry.is_dir {
			icon = "[D]"
			color = .BrightBlue
		} else {
			icon = "   "
			color = .White
		}

		// Indicador de seleção
		selector := "  "
		if is_selected {
			selector = "> "
			color = .BrightYellow
		}

		// Tamanho formatado
		size_str: string
		if entry.is_dir {
			size_str = "     "
		} else {
			size_str = format_size(entry.size)
		}

		line := fmt.tprintf("%s%s %-40s %s", selector, icon, entry.name, size_str)

		style: ansuz.StyleFlags = {}
		if is_selected {
			style = {.Bold}
		}

		ansuz.Layout_text(ctx, line, ansuz.style(color, ansuz.Ansi.Default, style))
	}

	ansuz.Layout_end_box(ctx)
}

render_status_bar :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .LeftToRight,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
			alignment = {.Center, .Center},
		},
	)

	// Info do item selecionado
	info: string
	if len(g_state.entries) > 0 && g_state.selected < len(g_state.entries) {
		entry := g_state.entries[g_state.selected]
		if entry.is_dir {
			info = fmt.tprintf(
				" %d/%d | [Enter] Abrir | [Backspace] Voltar | [Q/ESC] Sair",
				g_state.selected + 1,
				len(g_state.entries),
			)
		} else {
			info = fmt.tprintf(
				" %d/%d | %s | [Backspace] Voltar | [Q/ESC] Sair",
				g_state.selected + 1,
				len(g_state.entries),
				format_size(entry.size),
			)
		}
	} else {
		info = " [Q/ESC] Sair"
	}

	ansuz.Layout_text(ctx, info, ansuz.style(ansuz.Ansi.BrightBlack, ansuz.Ansi.Default, {.Dim}))
	ansuz.Layout_end_container(ctx)
}

format_size :: proc(bytes: i64) -> string {
	if bytes < 1024 {
		return fmt.tprintf("%4dB", bytes)
	} else if bytes < 1024 * 1024 {
		return fmt.tprintf("%4dK", bytes / 1024)
	} else if bytes < 1024 * 1024 * 1024 {
		return fmt.tprintf("%4dM", bytes / (1024 * 1024))
	} else {
		return fmt.tprintf("%4dG", bytes / (1024 * 1024 * 1024))
	}
}
