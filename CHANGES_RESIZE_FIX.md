# Changes Summary: Terminal Resize Fix

## Problem
Layout breaks when terminal is resized because:
- Terminal size was queried only once during initialization
- Context dimensions were never updated
- Buffer was never resized
- Layout used stale dimensions

## Solution

### 1. Modified: `ansuz/terminal.odin`

**Added ioctl support for terminal size queries:**

```odin
// Foreign imports for ioctl and TIOCGWINSZ which aren't exposed by core:sys/posix
foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
    ioctl :: proc(fd: int, request: u64, ...) -> int ---
}

// winsize struct for TIOCGWINSZ ioctl
winsize :: struct {
    ws_row:    u16,  // rows, in characters
    ws_col:    u16,  // columns, in characters
    ws_xpixel: u16,  // horizontal size, pixels (unused)
    ws_ypixel: u16,  // vertical size, pixels (unused)
}

TIOCGWINSZ :: 0x5413 // Terminal IO Control Get WINdow SiZe
```

**Replaced get_terminal_size():**

```odin
// OLD: Used ANSI escape sequences, blocked for 50ms, interfered with stdin
// NEW: Uses ioctl, non-blocking, fast, safe

get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
    stdin_fd := posix.FD(os.stdin)
    ws: winsize
    result := ioctl(stdin_fd, TIOCGWINSZ, &ws)
    if result < 0 {
        return 0, 0, .FailedToGetAttributes
    }
    return int(ws.ws_col), int(ws.ws_row), .None
}
```

**Removed:** Unused `import "core:time"` (no longer needed)

### 2. Modified: `ansuz/api.odin`

**Modified begin_frame() to check for resize:**

```odin
begin_frame :: proc(ctx: ^Context) {
    // Check for terminal size changes (every frame)
    // Since we now use ioctl() which is non-blocking, this is safe and efficient
    current_width, current_height, size_err := get_terminal_size()
    if size_err == .None && (current_width != ctx.width || current_height != ctx.height) {
        // Terminal was resized - update context
        handle_resize(ctx, current_width, current_height)
    }

    // Clear buffer for new frame
    clear_buffer(&ctx.buffer)
}
```

**Enhanced handle_resize() to clear screen:**

```odin
handle_resize :: proc(ctx: ^Context, new_width, new_height: int) {
    ctx.width = new_width
    ctx.height = new_height

    // Clear the screen to prevent artifacts from old content
    clear_screen()

    resize_buffer(&ctx.buffer, new_width, new_height)
}
```

## How It Works

### Before Fix:
```
init() → gets terminal size once
begin_frame() → uses stale size
layout → calculated with wrong dimensions
render → buffer doesn't match terminal
```

### After Fix:
```
begin_frame() → checks terminal size every frame via ioctl
  → if size changed:
    → handle_resize() updates context dimensions
    → handle_resize() clears screen
    → resize_buffer() reallocates buffer
layout → calculated with current dimensions
render → buffer matches terminal
```

## Benefits

1. **Automatic**: Applications don't need code changes
2. **Efficient**: ioctl is non-blocking and fast (microseconds)
3. **Safe**: Doesn't interfere with keyboard input
4. **Immediate mode compliant**: Every frame uses current state
5. **Clean**: Screen cleared on resize to prevent artifacts

## Testing

Run the layout demo and resize terminal:
```bash
odin build examples/layout_demo.odin -file -out:examples/layout_demo
./examples/layout_demo
# Resize terminal window - layout should adapt immediately
```

## Files Changed

- `ansuz/terminal.odin` - Added ioctl support, simplified get_terminal_size()
- `ansuz/api.odin` - Added automatic resize detection in begin_frame()

## Backward Compatibility

✅ Fully backward compatible - no API changes
✅ Existing applications work without modification
✅ All existing tests should pass
