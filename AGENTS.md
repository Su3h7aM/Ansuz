# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with jj
```

## Agent Workflow Requirements

All agents acting on this project MUST adhere to the following:

- **Use jj exclusively**: Always use **jj** (Jujutsu) for version control operations instead of git
- **Maintain TODO with beads**: Always use **beads** to maintain a TODO list of tasks to do and current work
- **Prefer inline commands**: Use versions of commands that avoid opening editors where possible, for example `jj desc -m "message"` instead of `jj desc`

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `jj git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   jj git fetch
   bd sync
   jj git push
   jj status  # MUST show clean working copy
   ```
5. **Clean up** - Abandon any abandoned commits if needed
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `jj git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

**JJ QUICK REFERENCE:**
```bash
jj status           # View working copy status
jj log              # View commit history
jj diff             # View changes
jj describe         # Edit commit message
jj new              # Create new commit
jj squash           # Amend current commit
jj git push         # Push to git remote
jj git fetch        # Fetch from git remote
jj undo             # Undo last operation
```

---

## Project Overview

**Ansuz** is an immediate-mode TUI library for the Odin programming language.

### Key Architecture Patterns

- **Immediate Mode**: UI declared each frame as pure function of state (no widget tree)
- **Single Buffer**: Full frame rendering (no double buffering or dirty tracking)
- **Raw Terminal Mode**: Direct control via Unix termios API (core:sys/posix)
- **Zero External Dependencies**: Pure Odin + standard library

### Building

```bash
export ODIN_ROOT=/path/to/Odin
odin build examples/hello_world.odin -file -out:examples/hello_world
./examples/hello_world
```

### Testing

```bash
export ODIN_ROOT=/path/to/Odin
odin test ansuz
```

### Project Structure

```
ansuz/
├── ansuz/              # Core library
│   ├── api.odin       # Public API
│   ├── terminal.odin  # Terminal I/O (raw mode, ANSI)
│   ├── buffer.odin    # Frame buffer
│   ├── colors.odin    # Color/style system
│   └── event.odin     # Input events
├── examples/          # Example programs
├── research/          # Technical documentation
└── build.sh          # Build script
```

### Important Odin Patterns

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

### API Reference

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

