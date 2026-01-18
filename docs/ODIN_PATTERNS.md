# Important Odin Patterns

**ALWAYS use core:sys/posix first!**

```odin
import "core:sys/posix"

// termios functions return posix.result
res := posix.tcgetattr(fd, &termios)
if res != .OK { /* error */ }

// termios fields are bit_set - use += / -=
raw.c_lflag -= {.ECHO, .ICANON}
raw.c_cflag += {.CS8}
```

**Odin does NOT have:**
- Increment/decrement operators (++/--)
- Constructors or destructors
- Exceptions (use defer for cleanup)
