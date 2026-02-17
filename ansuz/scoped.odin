package ansuz

// ============================================================================
// Scoped Layout API - @(deferred_in_out) Pattern
// ============================================================================
// This API uses Odin's @(deferred_in_out) attribute to automatically close
// containers when the scope exits. This follows the same pattern used by
// Odin's vendor/microui library.
//
// Example:
//   if ansuz.layout(ctx) {
//       if ansuz.container(ctx, {
//           direction = .TopToBottom,
//           sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
//       }) {
//           if ansuz.box(ctx, {
//               sizing = {.X = ansuz.fixed(40), .Y = ansuz.fixed(9)},
//           }, ansuz.style(.BrightCyan, .Default, {}), .Rounded) {
//               ansuz.label(ctx, "Hello, World!")
//           }
//       }
//   }
//
// Benefits over callback API:
// - Local variables are accessible inside blocks (no closures needed)
// - No global state workarounds
// - More natural control flow (break, continue, return work normally)
// - Cleanup is guaranteed even on early return

// --- Layout (top-level) ---

// layout starts a complete layout pass for the screen.
// Must be the outermost scope for all container/element calls.
// Usage: if ansuz.layout(ctx) { ... }
@(deferred_in_out = _scoped_end_layout)
layout :: proc(ctx: ^Context) -> bool {
	reset_layout_context(&ctx.layout_ctx, Rect{0, 0, ctx.width, ctx.height})
	return true
}

_scoped_end_layout :: proc(ctx: ^Context, ok: bool) {
	if ok {
		finish_layout(&ctx.layout_ctx, ctx)
	}
}

// --- Container ---

// container creates a layout container with children.
// Usage: if ansuz.container(ctx, config) { ... }
@(deferred_in_out = _scoped_end_container)
container :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) -> bool {
	begin_container(&ctx.layout_ctx, config)
	return true
}

_scoped_end_container :: proc(ctx: ^Context, _: LayoutConfig, ok: bool) {
	if ok {
		end_container(&ctx.layout_ctx)
	}
}

// --- Box (bordered container) ---

// box creates a bordered box container.
// Automatically adds padding for the border so content doesn't overlap it.
// Usage: if ansuz.box(ctx, config, style, box_style) { ... }
@(deferred_in_out = _scoped_end_box)
box :: proc(
	ctx: ^Context,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
	s: Style = {},
	bs: BoxStyle = .Sharp,
) -> bool {
	// Automatically add padding for the border
	modified_config := config
	modified_config.padding.left += 1
	modified_config.padding.right += 1
	modified_config.padding.top += 1
	modified_config.padding.bottom += 1

	node_idx := begin_container(&ctx.layout_ctx, modified_config)
	ctx.layout_ctx.nodes[node_idx].render_cmd = RenderCommand {
		type      = .Box,
		style     = s,
		box_style = bs,
	}
	return true
}

_scoped_end_box :: proc(ctx: ^Context, _: LayoutConfig, _: Style, _: BoxStyle, ok: bool) {
	if ok {
		end_container(&ctx.layout_ctx)
	}
}

// --- VStack (vertical stack) ---

// vstack creates a vertical stack container (TopToBottom direction).
// Usage: if ansuz.vstack(ctx, config) { ... }
@(deferred_in_out = _scoped_end_vstack)
vstack :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) -> bool {
	modified := config
	modified.direction = .TopToBottom
	begin_container(&ctx.layout_ctx, modified)
	return true
}

_scoped_end_vstack :: proc(ctx: ^Context, _: LayoutConfig, ok: bool) {
	if ok {
		end_container(&ctx.layout_ctx)
	}
}

// --- HStack (horizontal stack) ---

// hstack creates a horizontal stack container (LeftToRight direction).
// Usage: if ansuz.hstack(ctx, config) { ... }
@(deferred_in_out = _scoped_end_hstack)
hstack :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) -> bool {
	modified := config
	modified.direction = .LeftToRight
	begin_container(&ctx.layout_ctx, modified)
	return true
}

_scoped_end_hstack :: proc(ctx: ^Context, _: LayoutConfig, ok: bool) {
	if ok {
		end_container(&ctx.layout_ctx)
	}
}

// --- Rect (filled rectangle container) ---

// rect creates a filled rectangular container.
// Usage: if ansuz.rect(ctx, config, style, char) { ... }
@(deferred_in_out = _scoped_end_rect)
rect :: proc(
	ctx: ^Context,
	config: LayoutConfig = DEFAULT_LAYOUT_CONFIG,
	s: Style = {},
	char: rune = ' ',
) -> bool {
	node_idx := begin_container(&ctx.layout_ctx, config)
	ctx.layout_ctx.nodes[node_idx].render_cmd = RenderCommand {
		type  = .Rect,
		style = s,
		char  = char,
	}
	return true
}

_scoped_end_rect :: proc(ctx: ^Context, _: LayoutConfig, _: Style, _: rune, ok: bool) {
	if ok {
		end_container(&ctx.layout_ctx)
	}
}

// --- ZStack (overlay stacking container) ---

// zstack creates a container where all children stack on top of each other.
// All children take the full size of the parent and are positioned at (0, 0).
// Last child is rendered on top (like CSS absolute positioning).
// Usage: if ansuz.zstack(ctx, config) { ... }
@(deferred_in_out = _scoped_end_zstack)
zstack :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) -> bool {
	modified := config
	modified.direction = .ZStack
	begin_container(&ctx.layout_ctx, modified)
	return true
}

_scoped_end_zstack :: proc(ctx: ^Context, _: LayoutConfig, ok: bool) {
	if ok {
		end_container(&ctx.layout_ctx)
	}
}

// --- Spacer (flexible space filler) ---

// spacer adds flexible space that grows to fill available space in flex containers.
// It doesn't render anything (invisible element).
// Usage: ansuz.spacer(ctx, config)
spacer :: proc(ctx: ^Context, config: LayoutConfig = DEFAULT_LAYOUT_CONFIG) {
	cfg := config
	if cfg.sizing[.X].type == .FitContent {
		cfg.sizing[.X] = grow(1)
	}
	if cfg.sizing[.Y].type == .FitContent {
		cfg.sizing[.Y] = grow(1)
	}
	begin_container(&ctx.layout_ctx, cfg)
	end_container(&ctx.layout_ctx)
}
