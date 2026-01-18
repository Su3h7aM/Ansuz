# API Reference

```odin
// Context management
init() -> (^Context, Error)
shutdown(^Context)

// Frame lifecycle
begin_frame(^Context)
end_frame(^Context)

// Drawing
write_text(^Context, x, y, text, Style)
fill_rect(^Context, x, y, width, height, rune, Style)
draw_box(^Context, x, y, width, height, Style)

// Input
poll_events(^Context) -> []Event
get_size(^Context) -> (width, height: int)
```
