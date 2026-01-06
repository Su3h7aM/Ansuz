# Solução Odin Puro - Usando core:sys/posix

## Objetivo

Manter o projeto **100% em Odin** (sem `foreign import`/C), usando a API oficial do Odin conforme a documentação:

- https://pkg.odin-lang.org/core/sys/posix/
- https://pkg.odin-lang.org/core/sys/posix/#termios

## O que mudou

### Antes (com foreign imports)

O código usava bindings manuais para `tcgetattr/tcsetattr/ioctl/fsync`, além de structs/constantes definidas à mão.

### Depois (100% Odin puro)

#### Termios

No `core:sys/posix`, o tipo é `posix.termios` (lowercase) e as funções retornam `posix.result` (`.OK` / `.FAIL`).

```odin
import "core:os"
import "core:sys/posix"

TerminalState :: struct {
    original_termios: posix.termios,
    ...
}

stdin_fd := posix.FD(os.stdin)

res := posix.tcgetattr(stdin_fd, &termios)
if res != .OK {
    // erro
}

_ = posix.tcsetattr(stdin_fd, .TCSAFLUSH, &termios)
```

#### Flags do raw mode (bit_set)

Os campos `c_iflag/c_oflag/c_cflag/c_lflag` em `posix.termios` são `bit_set[...]`, então o jeito correto é **usar operações de conjunto** (ex.: `-=` para remover flags, `+=` para adicionar flags), e não `&= ~mask`.

```odin
raw.c_iflag -= {.BRKINT, .ICRNL, .INPCK, .ISTRIP, .IXON}
raw.c_oflag -= {.OPOST}
raw.c_cflag += {.CS8}
raw.c_lflag -= {.ECHO, .ICANON, .IEXTEN, .ISIG}

raw.c_cc[.VMIN]  = posix.cc_t(0)
raw.c_cc[.VTIME] = posix.cc_t(0)
```

#### Tamanho do terminal

`core:sys/posix` não expõe `ioctl/TIOCGWINSZ`, então o tamanho do terminal é obtido de forma portátil via ANSI DSR (`ESC [ 6 n`).

## Arquivos Modificados

- `ansuz/terminal.odin` (removidos `foreign import`, usando apenas APIs oficiais do Odin)

## Referências

- [Odin core:sys/posix](https://pkg.odin-lang.org/core/sys/posix/)
- [Termios](https://pkg.odin-lang.org/core/sys/posix/#termios)
