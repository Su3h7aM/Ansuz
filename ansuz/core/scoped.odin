package ansuz

import ac "../color"
import al "../layout"
import ab "../buffer"

@(deferred_in_out = _scoped_end_container)
container :: proc(ctx: ^Context, config: al.LayoutConfig = al.DEFAULT_LAYOUT_CONFIG) -> bool {
	al.begin_container(&ctx.layout_ctx, config)
	return true
}

_scoped_end_container :: proc(ctx: ^Context, _: al.LayoutConfig, ok: bool) {
	if ok {
		al.end_container(&ctx.layout_ctx)
	}
}

@(deferred_in_out = _scoped_end_box)
box :: proc(
	ctx: ^Context,
	config: al.LayoutConfig = al.DEFAULT_LAYOUT_CONFIG,
	s: ac.Style = {},
	bs: ab.BoxStyle = .Sharp,
) -> bool {
	modified_config := config
	modified_config.padding.left += 1
	modified_config.padding.right += 1
	modified_config.padding.top += 1
	modified_config.padding.bottom += 1

	node_idx := al.begin_container(&ctx.layout_ctx, modified_config)
	ctx.layout_ctx.nodes[node_idx].render_cmd = al.RenderCommand {
		type      = .Box,
		style     = s,
		box_style = bs,
	}
	return true
}

_scoped_end_box :: proc(ctx: ^Context, _: al.LayoutConfig, _: ac.Style, _: ab.BoxStyle, ok: bool) {
	if ok {
		al.end_container(&ctx.layout_ctx)
	}
}

@(deferred_in_out = _scoped_end_vstack)
vstack :: proc(ctx: ^Context, config: al.LayoutConfig = al.DEFAULT_LAYOUT_CONFIG) -> bool {
	modified := config
	modified.direction = .TopToBottom
	al.begin_container(&ctx.layout_ctx, modified)
	return true
}

_scoped_end_vstack :: proc(ctx: ^Context, _: al.LayoutConfig, ok: bool) {
	if ok {
		al.end_container(&ctx.layout_ctx)
	}
}

@(deferred_in_out = _scoped_end_hstack)
hstack :: proc(ctx: ^Context, config: al.LayoutConfig = al.DEFAULT_LAYOUT_CONFIG) -> bool {
	modified := config
	modified.direction = .LeftToRight
	al.begin_container(&ctx.layout_ctx, modified)
	return true
}

_scoped_end_hstack :: proc(ctx: ^Context, _: al.LayoutConfig, ok: bool) {
	if ok {
		al.end_container(&ctx.layout_ctx)
	}
}

@(deferred_in_out = _scoped_end_rect)
rect :: proc(
	ctx: ^Context,
	config: al.LayoutConfig = al.DEFAULT_LAYOUT_CONFIG,
	s: ac.Style = {},
	char: rune = ' ',
) -> bool {
	node_idx := al.begin_container(&ctx.layout_ctx, config)
	ctx.layout_ctx.nodes[node_idx].render_cmd = al.RenderCommand {
		type  = .Rect,
		style = s,
		char  = char,
	}
	return true
}

_scoped_end_rect :: proc(ctx: ^Context, _: al.LayoutConfig, _: ac.Style, _: rune, ok: bool) {
	if ok {
		al.end_container(&ctx.layout_ctx)
	}
}

@(deferred_in_out = _scoped_end_zstack)
zstack :: proc(ctx: ^Context, config: al.LayoutConfig = al.DEFAULT_LAYOUT_CONFIG) -> bool {
	modified := config
	modified.direction = .ZStack
	al.begin_container(&ctx.layout_ctx, modified)
	return true
}

_scoped_end_zstack :: proc(ctx: ^Context, _: al.LayoutConfig, ok: bool) {
	if ok {
		al.end_container(&ctx.layout_ctx)
	}
}

spacer :: proc(ctx: ^Context, config: al.LayoutConfig = al.DEFAULT_LAYOUT_CONFIG) {
	cfg := config
	if cfg.sizing[.X].type == .FitContent {
		cfg.sizing[.X] = al.grow(1)
	}
	if cfg.sizing[.Y].type == .FitContent {
		cfg.sizing[.Y] = al.grow(1)
	}
	al.begin_container(&ctx.layout_ctx, cfg)
	al.end_container(&ctx.layout_ctx)
}
