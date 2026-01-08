# Testing Guide for Immediate Mode Refactor

## Automated Tests

### Unit Tests
```bash
export ODIN_ROOT=/tmp/Odin  # or your Odin installation path
cd /home/engine/project
odin test ansuz
```

Expected result: All tests should pass (3 layout tests)

### Compilation Tests
```bash
export ODIN_ROOT=/tmp/Odin
cd /home/engine/project

# Build hello_world example
odin build examples/hello_world.odin -file -out:examples/hello_world

# Build layout_demo example
odin build examples/layout_demo.odin -file -out:examples/layout_demo
```

Expected result: Both should compile without errors

## Manual Testing

### Hello World Example

```bash
./examples/hello_world
```

**What to test:**
1. ✅ A blue box appears centered on screen
2. ✅ Title "Hello, Ansuz!" is displayed in bright yellow
3. ✅ Frame counter increments every frame
4. ✅ Status bar at bottom shows terminal dimensions
5. ✅ Ctrl+C exits the program
6. ✅ Terminal is properly restored after exit
7. ✅ Resize terminal - UI should adapt (may need to restart)

**Expected behavior:**
- Smooth rendering without flicker
- No visual artifacts
- Clean exit restoring terminal

### Layout Demo Example

```bash
./examples/layout_demo
```

**What to test:**
1. ✅ Header with "ANSUZ LAYOUT SYSTEM" is displayed
2. ✅ Sidebar and content areas are visible
3. ✅ Centered text appears in the middle
4. ✅ Three colored boxes at bottom
5. ✅ Footer with "Status: OK"
6. ✅ 'q' or Escape exits the program
7. ✅ Terminal is properly restored after exit

**Expected behavior:**
- Layout adapts to terminal size
- All elements properly aligned
- Clean rendering

## Performance Testing

### Frame Rate
The immediate mode architecture should still provide smooth rendering for typical TUI applications.

**What to observe:**
- No noticeable lag when updating
- Text input feels responsive
- Frame counter increments smoothly in hello_world

**Note:** TUIs don't need 60 FPS. Even 10-20 FPS is perfectly acceptable for most use cases.

### Terminal Size
Test with different terminal sizes:
```bash
# Small terminal (try to make it 40x12 or smaller)
./examples/hello_world

# Large terminal (try 200x50 or larger)
./examples/hello_world
```

**Expected behavior:**
- Works correctly at any size
- No crashes or artifacts
- UI elements adapt appropriately

## Regression Testing

### Changes Verification

Verify that the simplified immediate mode works identically to the old diff-based system:

**Before (old system):**
- Used double buffering
- Tracked dirty cells
- Diffed buffers before rendering
- Only output changed cells

**After (new system):**
- Uses single buffer
- No dirty tracking
- Renders entire buffer every frame
- Simpler code, same visual result

**Visual Test:**
The output should look EXACTLY the same. Users should not be able to tell the difference.

## Code Quality Tests

### No Dead Code
```bash
# Search for any remaining references to removed functions
cd /home/engine/project
grep -r "dirty" ansuz/*.odin examples/*.odin
grep -r "render_diff" ansuz/*.odin examples/*.odin
grep -r "cells_equal" ansuz/*.odin examples/*.odin
grep -r "front_buffer" ansuz/*.odin examples/*.odin
grep -r "back_buffer" ansuz/*.odin examples/*.odin
```

Expected result: No matches found (already verified)

### Memory Leaks
The test runner already checks for memory leaks:
```bash
odin test ansuz
```

Look for: "All tests were successful" with no memory warnings

## Edge Cases

### Rapid Resizing
1. Start hello_world
2. Rapidly resize terminal window
3. Check for:
   - No crashes
   - UI recovers properly
   - No memory leaks

### Minimal Terminal
1. Make terminal very small (e.g., 10x5)
2. Start hello_world
3. Check for:
   - No crashes
   - Graceful handling of small size
   - No buffer overflows

### Exit Handling
Test different exit methods:
- Ctrl+C in hello_world
- Ctrl+D in hello_world
- 'q' in layout_demo
- Escape in layout_demo

All should cleanly restore the terminal.

## Performance Profiling (Optional)

If you want to measure the performance difference:

```bash
# Time a fixed number of frames
time timeout 5s ./examples/hello_world
```

Compare before/after refactor. The new immediate mode should be:
- Similar or slightly slower (more work per frame)
- But still more than fast enough for TUI use
- Simpler code is worth minor perf tradeoff

## Success Criteria

✅ All unit tests pass
✅ Both examples compile without warnings
✅ Both examples run correctly
✅ Visual output is identical to before refactor
✅ No memory leaks detected
✅ Terminal properly restores on exit
✅ Performance is acceptable for TUI use
✅ Code is simpler and easier to understand

## Known Limitations

1. **Performance**: Full redraw is slower than diff-based rendering, but adequate for TUI
2. **Bandwidth**: Uses more terminal bandwidth, but negligible on modern connections
3. **No optimizations**: Deliberately chose simplicity over optimization

These are acceptable tradeoffs for the benefit of much simpler code.

## Troubleshooting

### "odin: command not found"
Make sure Odin is installed and ODIN_ROOT is set:
```bash
export ODIN_ROOT=/path/to/Odin
export PATH=$PATH:/path/to/Odin
```

### Terminal corruption after exit
This shouldn't happen, but if it does:
```bash
reset
```

### Compilation errors
Make sure you're using a recent version of Odin (2024+)

## Conclusion

The immediate mode refactor maintains 100% functional compatibility while significantly simplifying the codebase. All tests should pass and examples should work identically to before.
