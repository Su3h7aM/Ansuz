package main

import ansuz "../ansuz"
import "core:fmt"
import "core:strings"
import "core:time"

// OpenCodeState holds the application state
OpenCodeState :: struct {
	running:      bool,
	input_buffer: strings.Builder,
	blink_state:  bool,
	last_blink:   time.Time,
}

// Styles
STYLE_BG :: ansuz.Style{.Default, .Default, {}}
STYLE_HEADER_PATH :: ansuz.Style{.BrightBlack, .Default, {}}
STYLE_TAB_ACTIVE :: ansuz.Style{.White, .BrightBlack, {}}
STYLE_TAB_TEXT :: ansuz.Style{.White, .Default, {}}
STYLE_LOGO :: ansuz.Style{.White, .Default, {.Bold}}
STYLE_INPUT_BOX :: ansuz.Style{.White, .BrightBlack, {}}
STYLE_INPUT_PLACE :: ansuz.Style{.BrightBlack, .BrightBlack, {}} // Gray on Gray for placeholder logic if needed, or just dim
STYLE_PROMPT_TEXT :: ansuz.Style{.White, .Default, {}}
STYLE_TIP :: ansuz.Style{.Yellow, .Default, {}}
STYLE_TIP_TEXT :: ansuz.Style{.BrightBlack, .Default, {}}
STYLE_FOOTER_INFO :: ansuz.Style{.BrightBlack, .Default, {}}
STYLE_FOOTER_VER :: ansuz.Style{.BrightBlack, .Default, {}}

g_state: OpenCodeState

main :: proc() {
	ctx, err := ansuz.init()
	if err != .None {
		fmt.eprintln("Failed to initialize Ansuz:", err)
		return
	}
	defer ansuz.shutdown(ctx)

	// Initialize state
	g_state = OpenCodeState {
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

	render_opencode(ctx, &g_state)
	return true
}

handle_input :: proc(state: ^OpenCodeState, event: ansuz.Event) {
	#partial switch e in event {
	case ansuz.KeyEvent:
		#partial switch e.key {
		case .Ctrl_C:
			state.running = false
		case .Char:
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

render_opencode :: proc(ctx: ^ansuz.Context, state: ^OpenCodeState) {
	ansuz.begin_layout(ctx)

	// Main Container
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			padding = {0, 0, 0, 0},
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
		},
	)

	// 1. Top Header Bar
	render_header(ctx)

	// 2. Middle Content (Grow)
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .TopToBottom,
			sizing    = {ansuz.Sizing_grow(), ansuz.Sizing_grow()},
			alignment = {.Center, .Center}, // Center content vertically provided alignment is supported or manual pad
			padding   = {0, 0, 0, 0},
		},
	)
	// Manually pad top to center visually approx 30% down
	// Since we don't have percentage padding, we rely on a spacer or just putting it in the middle if alignment works.
	// Assuming alignment .Center might not be fully implemented in all containers, using Spacer idea.

	// Spacer Top
	ansuz.Layout_begin_container(ctx, {sizing = {ansuz.Sizing_grow(), ansuz.Sizing_percent(0.3)}})
	ansuz.Layout_end_container(ctx)

	// Logo Area
	render_logo(ctx)

	// Input Area
	render_input(ctx, state)

	// Spacer Bottom
	ansuz.Layout_begin_container(ctx, {sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()}})
	// Tip in the bottom half
	ansuz.Layout_begin_container(
		ctx,
		{direction = .LeftToRight, alignment = {.Center, .Center}, padding = {1, 0, 0, 0}},
	)
	ansuz.Layout_text(ctx, "● Tip", STYLE_TIP)
	ansuz.Layout_text(
		ctx,
		" Use opencode run --attach to connect to a running server",
		STYLE_TIP_TEXT,
	)
	ansuz.Layout_end_container(ctx)
	ansuz.Layout_end_container(ctx)

	ansuz.Layout_end_container(ctx)

	// 3. Footer
	render_footer(ctx)

	ansuz.Layout_end_container(ctx)
	ansuz.end_layout(ctx)
}

render_header :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .LeftToRight,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
			padding = {0, 1, 0, 1},
			gap = 1,
		},
	)

	// Left: Path
	ansuz.Layout_text(ctx, "~/Apps/Antigravity...", STYLE_HEADER_PATH)

	// Spacer
	ansuz.Layout_begin_container(ctx, {sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)}})
	ansuz.Layout_end_container(ctx)

	// Right: Tab "OpenCode x"
	// Using a box for the tab look
	ansuz.Layout_box(
		ctx,
		STYLE_TAB_ACTIVE,
		{direction = .LeftToRight, padding = {0, 1, 0, 1}},
		.Rounded,
	)
	ansuz.Layout_text(ctx, "OpenCode", STYLE_TAB_TEXT)
	ansuz.Layout_text(ctx, "×", STYLE_TAB_TEXT)
	ansuz.Layout_end_box(ctx)

	ansuz.Layout_end_container(ctx)
}

render_logo :: proc(ctx: ^ansuz.Context) {
	// Large "opencode" text.
	// We can simulate big text with a block font or just use Uppercase spaced out for now.
	// The image shows a pixel-font-ish look. I'll use simple text for simplicity or block chars if ambitious.
	// Let's use simple UPPERCASE text with Letter spacing.

	ansuz.Layout_begin_container(
		ctx,
		{direction = .TopToBottom, alignment = {.Center, .Center}, padding = {0, 0, 1, 0}},
	)
	// Approximate the "opencode" logo
	ansuz.Layout_text(ctx, "o p e n c o d e", ansuz.Style{.White, .Default, {.Bold}})
	ansuz.Layout_end_container(ctx)
}

render_input :: proc(ctx: ^ansuz.Context, state: ^OpenCodeState) {
	// Input Box
	ansuz.Layout_begin_container(
		ctx,
		{direction = .TopToBottom, alignment = {.Center, .Center}, padding = {0, 0, 1, 0}},
	)

	// The Box itself
	ansuz.Layout_box(
		ctx,
		STYLE_INPUT_BOX,
		{
			direction = .TopToBottom,
			padding   = {1, 2, 1, 2},
			sizing    = {ansuz.Sizing_percent(0.6), ansuz.Sizing_fit()}, // 60% width
		},
		.Rounded,
	)

	// Prompt line
	ansuz.Layout_begin_container(ctx, {direction = .LeftToRight, gap = 1})
	// Icon/Cursor placeholder in image looks like a specific prompt char
	ansuz.Layout_text(
		ctx,
		"Ask anything... \"Fix a TODO in the codebase\"",
		ansuz.Style{.BrightBlack, .BrightBlack, {}},
	) // Placeholder style

	// Actual input overlay?
	// For simplicity in this demo, let's just show the input if present, or placeholder if empty.

	// Actually the image shows "Ask anything..." as gray text, and "Plan GLM..." below.
	// Let's implement the top line as input.
	ansuz.Layout_end_container(ctx)

	// Current Input (Overlaying for demo purposes or separate line)
	ansuz.Layout_begin_container(ctx, {direction = .LeftToRight, gap = 0})
	if strings.builder_len(state.input_buffer) > 0 {
		ansuz.Layout_text(ctx, strings.to_string(state.input_buffer), STYLE_PROMPT_TEXT)
	}
	if state.blink_state {
		ansuz.Layout_rect(
			ctx,
			'█',
			STYLE_PROMPT_TEXT,
			{sizing = {ansuz.Sizing_fixed(1), ansuz.Sizing_fixed(1)}},
		)
		ansuz.Layout_end_rect(ctx)
	}
	ansuz.Layout_end_container(ctx)

	// Plan info line below input
	ansuz.Layout_begin_container(ctx, {direction = .LeftToRight, gap = 1, padding = {1, 0, 0, 0}})
	ansuz.Layout_text(ctx, "Plan", ansuz.Style{.Magenta, .BrightBlack, {}})
	ansuz.Layout_text(ctx, "GLM-4.7 Z.AI Coding Plan", ansuz.Style{.BrightBlack, .BrightBlack, {}})
	ansuz.Layout_end_container(ctx)

	ansuz.Layout_end_box(ctx)

	// Hints below box
	ansuz.Layout_begin_container(ctx, {direction = .LeftToRight, padding = {0, 0, 1, 0}, gap = 2})
	ansuz.Layout_text(ctx, "tab agents", STYLE_FOOTER_INFO)
	ansuz.Layout_text(ctx, "ctrl+p commands", STYLE_FOOTER_INFO)
	ansuz.Layout_end_container(ctx)

	ansuz.Layout_end_container(ctx)
}

render_footer :: proc(ctx: ^ansuz.Context) {
	ansuz.Layout_begin_container(
		ctx,
		{
			direction = .LeftToRight,
			sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fixed(1)},
			padding = {0, 1, 0, 1},
		},
	)

	// Left Status
	ansuz.Layout_text(ctx, "~/Projects/Ansuz:HEAD", STYLE_FOOTER_INFO)
	ansuz.Layout_text(ctx, "  ", STYLE_FOOTER_INFO)
	ansuz.Layout_text(ctx, "4 MCP", STYLE_FOOTER_INFO)
	ansuz.Layout_text(ctx, " ", STYLE_FOOTER_INFO)
	ansuz.Layout_text(ctx, "/status", STYLE_FOOTER_INFO)

	// Spacer
	ansuz.Layout_begin_container(ctx, {sizing = {ansuz.Sizing_grow(), ansuz.Sizing_fit()}})
	ansuz.Layout_end_container(ctx)

	// Right Version
	ansuz.Layout_text(ctx, "1.1.40", STYLE_FOOTER_VER)

	ansuz.Layout_end_container(ctx)
}
