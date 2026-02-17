# Important Odin Patterns

**Prefer native standard library bindings (`core:sys/posix`, `core:sys/linux`) and avoid foreign imports unless absolutely necessary.**

```odin
import "core:os"
import "core:sys/linux"
import "core:sys/posix"

stdin_fd := posix.FD(os.stdin)
res := posix.tcgetattr(stdin_fd, &termios)
if res != .OK { /* error */ }

result := linux.ioctl(linux.Fd(stdin_fd), linux.TIOCGWINSZ, uintptr(&ws))
if result < 0 { /* error */ }
```

**termios fields are bit sets — use `+=` and `-=` for flags:**

```odin
raw.c_lflag -= {.ECHO, .ICANON}
raw.c_cflag += {.CS8}
```

**Odin does NOT have:**
- Increment/decrement operators (++/--)
- Constructors or destructors
- Exceptions (use defer for cleanup)
- Capturing closures for callbacks
- A `byte` type (use `u8`)
