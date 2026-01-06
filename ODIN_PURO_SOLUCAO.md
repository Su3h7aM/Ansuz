# Solução Odin Puro - Usando core:sys/posix

## Boa Notícia! 🎉

Encontramos a solução correta usando a biblioteca **oficial** do Odin: `core:sys/posix`

## O que mudou

### Antes (com foreign imports):
```odin
foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
    tcgetattr :: proc(fd: int, termios_p: ^Termios) -> int ---
    tcsetattr :: proc(fd: int, optional_actions: int, termios_p: ^Termios) -> int ---
    ioctl     :: proc(fd: int, request: u64, ...) -> int ---
    fsync     :: proc(fd: int) -> int ---
}

// Definir manualmente:
Termios :: struct { ... }
WinSize :: struct { ... }
BRKINT :: u32(1 << 0)
// ... dezenas de constantes
```

### Depois (100% Odin puro):
```odin
import "core:sys/posix"

// Usar tipos e funções nativas:
TerminalState :: struct {
    original_termios: posix.Termios,  // Tipo nativo do Odin!
    ...
}

// Funções nativas do Odin:
posix.tcgetattr(os.stdin, &termios)
posix.tcsetattr(os.stdin, posix.TCSAFLUSH, &termios)
posix.ioctl(os.stdout, posix.TIOCGWINSZ, &ws)
posix.fsync(os.stdout)

// Constantes nativas do Odin:
raw.c_iflag &= ~(posix.BRKINT | posix.ICRNL | posix.INPCK | ...)
raw.c_lflag &= ~(posix.ECHO | posix.ICANON | posix.IEXTEN | posix.ISIG)
raw.c_cc[posix.VMIN] = 0
```

## Arquivos Modificados

### ansuz/terminal.odin
- ✅ Removidos todos os foreign imports
- ✅ Removidas todas as definições manuais de structs e constantes
- ✅ Usando `core:sys/posix` oficial do Odin
- ✅ **100% código Odin puro**

## Referências

- [Odin core:sys/posix Documentação Oficial](https://pkg.odin-lang.org/core/sys/posix/)
- [POSIX Termios](https://pkg.odin-lang.org/core/sys/posix/#termios)
- [POSIX Ioctl](https://pkg.odin-lang.org/core/sys/posix/#ioctl)

## Conclusão

**O código agora é 100% Odin puro** usando a biblioteca oficial `core:sys/posix`!
