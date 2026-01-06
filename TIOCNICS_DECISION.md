# Por que usamos Foreign Imports em Ansuz TUI

## Contexto

O Ansuz TUI é uma biblioteca para criar interfaces de usuário no terminal. Para funcionar corretamente, ela precisa controlar o terminal em "raw mode", o que permite:
- Captura imediata de teclas (sem buffering de linha)
- Desabilitar eco de caracteres
- Capturar teclas especiais (Ctrl+C, setas, etc.)

## O Problema

Essas funcionalidades dependem de **system calls do POSIX** que são específicas do sistema operacional:
- `tcgetattr()` - Obter configurações do terminal
- `tcsetattr()` - Alterar configurações do terminal
- `ioctl()` - Comandos de I/O do terminal
- `fsync()` - Sincronizar output

## Por que Foreign Imports?

### 1. Odin não expõe essas APIs nativamente
A biblioteca padrão do Odin (`core:os`, `core:sys/unix`, `core:sys/posix`) não expõe diretamente essas funções de baixo nível. Isso é proposital porque:

- São APIs específicas do sistema operacional
- Variam entre Unix, Linux, macOS, BSD, etc.
- São consideradas "unsafe" e de baixo nível

### 2. Não há alternativa pura
Para implementar TUI funcional, é MANDATÓRIO usar essas syscalls. Não existe maneira de:
- Criar raw mode sem `tcgetattr/tcsetattr`
- Obter tamanho do terminal sem `ioctl(TIOCGWINSZ)`
- Controlar terminal ANSI sem essas funções

### 3. É prática padrão em linguagens de sistemas
Outras linguagens fazem exatamente a mesma coisa:
- **Rust**: Usa `libc` crate ou `nix`
- **Go**: Usa `syscall` package
- **C++**: Usa `<termios.h>` e `<sys/ioctl.h>`
- **Zig**: Usa `std.os.linux` ou bindings C diretos

## O que é "Odin Puro"?

Em Ansuz TUI:

### ✅ 100% Odin Puro:
- Tipos e estruturas de dados
- Lógica de negócio
- Rendering de ANSI
- Manipulação de eventos
- Buffer system
- Color system

### ⚠️ Foreign Imports (necessários):
- System calls POSIX para controle de terminal

## Arquitetura

A separação é clara:

```
Camada Odin Puro (95% do código)
├── ansuz/api.odin      - API de alto nível
├── ansuz/buffer.odin   - Sistema de renderização
├── ansuz/colors.odin   - Sistema de cores
└── ansuz/event.odin    - Manipulação de eventos

Camada de System Call (5% do código)
└── ansuz/terminal.odin  - Apenas para acesso a termios
```

## Conclusão

Os foreign imports são **necessários e corretos** para:
1. Acessar funcionalidades do sistema operacional
2. Implementar raw mode para TUI
3. Seguir padrões de desenvolvimento em linguagens de sistemas

O restante do código é 100% Odin idiomático e não depende de C.
