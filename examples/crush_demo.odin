package main

import ansuz "../ansuz"
import "core:fmt"
import "core:strings"
import "core:time"

// CrushState holds the application state
CrushState :: struct {
	running:      bool,
	input_buffer: strings.Builder,
	blink_state:  bool,
	last_blink:   time.Time,
}

// Styles
// Attempting to match the Synthwave/Cyberpunk aesthetic of Charm tools
STYLE_HEADER_BG :: ansuz.Style{.Magenta, .Default, {}} // Background for header
STYLE_HEADER_TEXT :: ansuz.Style{.BrightWhite, .Default, {.Bold}}
STYLE_LOGO :: ansuz.Style{.BrightMagenta, .Default, {.Bold, .Reverse}} // Inverted box for logo
STYLE_LOGO_TEXT :: ansuz.Style{.BrightMagenta, .Default, {.Bold}}
STYLE_STRIPE :: ansuz.Style{.Blue, .Default, {}}
STYLE_META_LABEL :: ansuz.Style{.BrightBlack, .Default, {}}
STYLE_META_VALUE :: ansuz.Style{.White, .Default, {}}
STYLE_PROMPT :: ansuz.Style{.BrightMagenta, .Default, {}}
STYLE_INPUT_PLACE :: ansuz.Style{.BrightBlack, .Default, {}}
STYLE_FOOTER_KEY :: ansuz.Style{.White, .Default, {}}
STYLE_FOOTER_DESC :: ansuz.Style{.BrightBlack, .Default, {}}

g_state: CrushState

main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to initialize Ansuz:", err)
		return
	}
	defer ansuz.shutdown(ctx)

	// Initialize state
	g_state = CrushState {
		running    = true,
		last_blink = time.now(),
	}
	strings.builder_init(&g_state.input_buffer)
	defer strings.builder_destroy(&g_state.input_buffer)

	ansuz.run(ctx, update_app)
}

update_app :: proc(ctx: ^ansuz.Context) -> bool {
	// Handle input
	events := ansuz.poll_events(ctx)
	for ev in events {
		handle_input(&g_state, ev)
	}

	if !g_state.running {
		return false
	}

	// Blink cursor
	now := time.now()
	if time.diff(g_state.last_blink, now) > 500 * time.Millisecond {
		g_state.blink_state = !g_state.blink_state
		g_state.last_blink = now
	}

	render_crush(ctx, &g_state)
	return true
}

handle_input :: proc(state: ^CrushState, event: ansuz.Event) {
	#partial switch e in event {
	case ansuz.KeyEvent:
		#partial switch e.key {
		case .Ctrl_C:
			state.running = false
		case .Char:
			// Simple input handling
			if e.rune >= 32 && e.rune <= 126 {
				strings.write_rune(&state.input_buffer, e.rune)
			}
		case .Backspace:
			if strings.builder_len(state.input_buffer) > 0 {
				strings.pop_byte(&state.input_buffer)
			}
		}
	}
}

render_crush :: proc(ctx: ^ansuz.Context, state: ^CrushState) {
	ansuz.begin_layout(ctx)

	// Main Container
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			padding   = {0, 0, 0, 0}, // No padding on outer container to touch edges
			sizing    = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
		},
	)

	// 1. Header Section
	render_header(ctx)

	// 2. Metadata Section (Context info)
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			padding   = {1, 2, 0, 2}, // Left/Right padding to align with content
			gap       = 1,
		},
	)
	// Row 1: Current Directory (simulated)
	ansuz.Layout_text(ctx, "~/Projects/Ansuz", STYLE_META_LABEL)

	// Row 2: Model Info
	ansuz.Layout_begin_container(ctx, {direction = .LeftToRight, gap = 1})
	ansuz.Layout_text(ctx, "◇", STYLE_META_LABEL)
	ansuz.Layout_text(ctx, "GLM-4.7", STYLE_META_VALUE)
	ansuz.Layout_end_container(ctx)

	// Row 3: LSP/MCP Columns
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .LeftToRight,
			gap       = 20, // Space between columns
			padding   = {1, 0, 0, 0},
		},
	)
	// Column 1
	ansuz.Layout_begin_container(ctx, {direction = .TopToBottom})
	ansuz.Layout_text(ctx, "LSPs", STYLE_META_LABEL)
	ansuz.Layout_text(ctx, "None", STYLE_META_VALUE)
	ansuz.Layout_end_container(ctx)

	// Column 2
	ansuz.Layout_begin_container(ctx, {direction = .TopToBottom})
	ansuz.Layout_text(ctx, "MCPs", STYLE_META_LABEL)
	ansuz.Layout_text(ctx, "None", STYLE_META_VALUE)
	ansuz.Layout_end_container(ctx)

	ansuz.Layout_end_container(ctx)

	ansuz.Layout_end_container(ctx)

	// 3. Main Content Spacer
	// Grow to push footer down, empty area
	ansuz.Layout_begin_container(
		ctx,
		{direction = .TopToBottom, sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()}},
	)
	ansuz.Layout_end_container(ctx)

	// 4. Prompt Area
	render_prompt(ctx, state)

	// 5. Footer
	render_footer(ctx)

	ansuz.Layout_end_container(ctx) // End Main
	ansuz.end_layout(ctx)
}

render_header :: proc(ctx: ^ansuz.Context) {
	// Determine the width of the terminal to draw the full stripe bar
	// Since we don't have direct access to width in pixels/cols easily here without passing it,
	// we rely on Sizing_grow() in a horizontal container.

	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .LeftToRight,
			sizing    = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(3)}, // Height 3 lines
			padding   = {0, 0, 0, 0},
		},
	)

	// We construct a "Logo" looking thing.
	// In the image it's: `/// Charm CRUSH /// ...`
	// We can simulate the stripes with text.

	// Left Stripes
	ansuz.Layout_text(ctx, "///// ", STYLE_STRIPE)

	// Logo "Charm" small above "CRUSH"
	// Since we can't do complex ASCII art easily in one text block without multiline string or container complexity,
	// let's try a vertical container for the logo part.

	ansuz.Layout_begin_container(
		ctx,
		{direction = .TopToBottom, sizing = {ansuz.Sizing_fit(), ansuz.Sizing_fit()}},
	)
	ansuz.Layout_text(ctx, " Charm™      v0.36.0 ", STYLE_LOGO_TEXT)
	// Big Text simulation using full-width chars or bold
	ansuz.Layout_text(ctx, " CRUSH ", ansuz.Style{.Black, .BrightMagenta, {.Bold}})
	ansuz.Layout_end_container(ctx)

	// Right Stripes (Filling the rest)
	// We use a pattern repitition.
	// Since we can't easily "repeat until end", we'll just put a long string and clip output implicitly
	// or rely on a custom renderer. For now, a long string is the easiest hack.
	long_stripes := "////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////"
	ansuz.Layout_text(ctx, long_stripes, STYLE_STRIPE)

	ansuz.Layout_end_container(ctx)
}

render_prompt :: proc(ctx: ^ansuz.Context, state: ^CrushState) {
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			padding   = {0, 2, 1, 2}, // Bottom padding for footer separation
		},
	)

	// Prompt Line
	ansuz.Layout_begin_container(ctx, {direction = .LeftToRight, gap = 1})
	ansuz.Layout_text(ctx, ">", STYLE_PROMPT)

	input_len := strings.builder_len(state.input_buffer)
	if input_len == 0 {
		ansuz.Layout_text(
			ctx,
			"Ready for instructions",
			ansuz.Style{.BrightBlack, .Default, {.Dim}},
		) // Placeholder
		// Cursor at start
		if state.blink_state {
			ansuz.Layout_rect(
				ctx,
				'█',
				STYLE_PROMPT,
				{sizing = {ansuz.Sizing_fixed(1), ansuz.Sizing_fixed(1)}},
			)
			ansuz.Layout_end_rect(ctx)
		}
	} else {
		ansuz.Layout_text(
			ctx,
			strings.to_string(state.input_buffer),
			ansuz.Style{.White, .Default, {}},
		)
		if state.blink_state {
			ansuz.Layout_rect(
				ctx,
				'█',
				STYLE_PROMPT,
				{sizing = {ansuz.Sizing_fixed(1), ansuz.Sizing_fixed(1)}},
			)
			ansuz.Layout_end_rect(ctx)
		}
	}
	ansuz.Layout_end_container(ctx)

	// Decorative dots below prompt (::: :::)
	ansuz.Layout_text(ctx, ":::", ansuz.Style{.BrightBlack, .Default, {.Dim}})
	ansuz.Layout_text(ctx, ":::", ansuz.Style{.BrightBlack, .Default, {.Dim}})

	ansuz.Layout_end_container(ctx)
}

render_footer :: proc(ctx: ^ansuz.Context) {
	// Footer Key hints
	// / or ctrl+p commands   ctrl+m models   shift+enter newline   ctrl+c quit   ctrl+g more

	ansuz.Layout_begin_container(ctx, {direction = .LeftToRight, padding = {0, 2, 0, 1}, gap = 1})

	draw_key_hint(ctx, "/", "or", "ctrl+p", "commands")
	ansuz.Layout_text(ctx, "•", STYLE_FOOTER_DESC)

	draw_key_hint(ctx, "ctrl+m", "", "", "models")
	ansuz.Layout_text(ctx, "•", STYLE_FOOTER_DESC)

	draw_key_hint(ctx, "shift+enter", "", "", "newline")
	ansuz.Layout_text(ctx, "•", STYLE_FOOTER_DESC)

	draw_key_hint(ctx, "ctrl+c", "", "", "quit")
	ansuz.Layout_text(ctx, "•", STYLE_FOOTER_DESC)

	draw_key_hint(ctx, "ctrl+g", "", "", "more")

	ansuz.Layout_end_container(ctx)
}

draw_key_hint :: proc(ctx: ^ansuz.Context, k1: string, sep: string, k2: string, desc: string) {
	if k1 != "" {
		ansuz.Layout_text(ctx, k1, STYLE_FOOTER_KEY)
	}
	if sep != "" {
		ansuz.Layout_text(ctx, sep, STYLE_FOOTER_DESC)
	}
	if k2 != "" {
		ansuz.Layout_text(ctx, k2, STYLE_FOOTER_KEY)
	}
	ansuz.Layout_text(ctx, desc, STYLE_FOOTER_DESC)
}
