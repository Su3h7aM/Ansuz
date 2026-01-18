# Agent Instructions

**Ansuz** is an immediate-mode TUI library for the Odin programming language.

## Documentation

- [Project Architecture](docs/ARCHITECTURE.md)
- [Layout System](docs/LAYOUT.md)
- [Testing Guide](docs/TESTING.md)
- [API Reference](docs/API.md)
- [Odin Patterns](docs/ODIN_PATTERNS.md)

## Development Workflow

We use [mise](https://mise.jdx.dev/) for task management.

```bash
mise run build  # Build all examples
mise run test   # Run all tests
```

## Tools & Workflow

This project uses specialized tools. If you are unfamiliar with them, consult their help commands (e.g., `jj -h`, `bd -h`).

### Version Control: Jujutsu (`jj`)
We use **`jj`** exclusively instead of `git`.
- **Do not use git commands directly** (except when instructed by specific workflows below).
- Use `jj` to manage commits, branches (bookmarks), and syncing.

### Issue Tracking: Beads (`bd`)
We use **`beads`** to manage issues and TODOs.
- **Rule:** Any work must be registered as an issue.
- **Rule:** Issues must have **priority** and **dependencies** defined.
- **Workflow:**
    1.  Create issue(s) for the task.
    2.  Work on the task.
    3.  Update/Close issues as you progress.


## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `jj git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - `mise run test`
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

**JJ EXCLUSIVE:**
- Always use **jj** (Jujutsu) for version control operations instead of git.
