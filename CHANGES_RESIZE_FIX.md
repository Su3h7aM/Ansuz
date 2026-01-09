# Changes Summary: Terminal Resize Fix

## Problem
Layout breaks when terminal is resized because:
- Terminal size was queried only once during initialization
- Context dimensions were never updated
- Buffer was never resized
- Layout used stale dimensions

## Solution

### 1. Modified: `ansuz/terminal.odin`

**Added ioctl support via core:sys/linux (pure Odin):**

```odin
// Added import for Linux system calls
import "core:sys/linux"
```

**Replaced get_terminal_size() with pure Odin implementation:**

```odin
// OLD: Used ANSI escape sequences, blocked for 50ms, interfered with stdin
// NEW: Uses ioctl via core:sys/linux, non-blocking, fast, safe, 100% Odin

get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
    stdin_fd := int(posix.FD(os.stdin))

    ws: linux.winsize
    result := linux.ioctl(stdin_fd, linux.TIOCGWINSZ, &ws)

    if result < 0 {
        // ioctl failed, return error
        return 0, 0, .FailedToGetAttributes
    }

    return int(ws.ws_col), int(ws.ws_row), .None
}
```

**Key changes:**
- Uses `core:sys/linux` package (standard Odin library)
- `linux.winsize` struct (provided by Odin)
- `linux.TIOCGWINSZ` constant (provided by Odin)
- `linux.ioctl()` function (provided by Odin)
- **100% pure Odin - no C dependencies or foreign imports**

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
