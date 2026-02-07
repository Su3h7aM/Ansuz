package ansuz

// ============================================================================
// Scoped Layout API - 100% Callback-Based
// ============================================================================
// This API provides a cleaner, more ergonomic interface that eliminates
// explicit begin/end calls in favor of scoped callbacks.
//
// Example:
//   ansuz.layout(ctx, proc(ctx) {
//       ansuz.container(ctx, {
//           direction = .TopToBottom,
//           sizing = {.X = ansuz.grow(), .Y = ansuz.grow()},
//       }, proc(ctx) {
//           ansuz.box(ctx, {
//               style = ansuz.style(.BrightCyan, .Default, {}),
//               sizing = {.X = ansuz.fixed(40), .Y = ansuz.fixed(9)},
//           }, .Rounded, proc(ctx) {
//               ansuz.label(ctx, "Hello, World!")
//           })
//       })
//   })
//
// NOTE: Odin callbacks do NOT capture variables from the enclosing scope.
// Use global variables or explicit parameters to share state with callbacks.

// layout - Starts a complete layout definition for the screen
// This replaces begin_layout() and end_layout() with a single scoped call.
// The body callback should contain all container and element declarations.
layout :: proc(ctx: ^Context, body: proc(^Context)) {
	reset_layout_context(&ctx.layout_ctx, Rect{0, 0, ctx.width, ctx.height})
	body(ctx)
	finish_layout(&ctx.layout_ctx, ctx)
}

// container - Creates a layout container with children
// This replaces begin_element()/end_element() for container elements.
// The body callback is called to add child elements to this container.
container :: proc(ctx: ^Context, config: LayoutConfig, body: proc(^Context)) {
	node_idx := begin_container(&ctx.layout_ctx, config)
	body(ctx)
	end_container(&ctx.layout_ctx)
	_ = node_idx // Silence unused warning
}

// box - Creates a bordered box container
// Automatically adds padding for the border so content doesn't overlap it.
// The body callback is called to add child elements inside the box.
box :: proc(ctx: ^Context, config: LayoutConfig, box_style: BoxStyle, body: proc(^Context)) {
	// Automatically add padding for the border
	modified_config := config
	modified_config.padding.left += 1
	modified_config.padding.right += 1
	modified_config.padding.top += 1
	modified_config.padding.bottom += 1

	node_idx := begin_container(&ctx.layout_ctx, modified_config)
	ctx.layout_ctx.nodes[node_idx].render_cmd = RenderCommand{
		type      = .Box,
		style     = config.style,
		box_style = box_style,
	}
	body(ctx)
	end_container(&ctx.layout_ctx)
}

// vstack - Creates a vertical stack container (TopToBottom direction)
// Convenience alias for container with direction = .TopToBottom
vstack :: proc(ctx: ^Context, config: LayoutConfig, body: proc(^Context)) {
	modified := config
	modified.direction = .TopToBottom
	container(ctx, modified, body)
}

// hstack - Creates a horizontal stack container (LeftToRight direction)
// Convenience alias for container with direction = .LeftToRight
hstack :: proc(ctx: ^Context, config: LayoutConfig, body: proc(^Context)) {
	modified := config
	modified.direction = .LeftToRight
	container(ctx, modified, body)
}

// rect - Creates a filled rectangular container
// Automatically applies the fill character to the entire container area.
// The body callback is called to add child elements (they will overlay the fill).
rect :: proc(ctx: ^Context, config: LayoutConfig, char: rune, body: proc(^Context)) {
	node_idx := begin_container(&ctx.layout_ctx, config)
	ctx.layout_ctx.nodes[node_idx].render_cmd = RenderCommand{
		type  = .Rect,
		style = config.style,
		char  = char,
	}
	body(ctx)
	end_container(&ctx.layout_ctx)
}
