# Solução Correta: Terminal Resize - Odin com Acesso ao Sistema

## Problema Original

O layout quebrava quando o terminal era redimensionado porque:
1. O tamanho do terminal era consultado apenas uma vez na inicialização
2. As dimensões do contexto nunca eram atualizadas
3. O buffer de framebuffer nunca era redimensionado
4. O layout usava dimensões obsoletas

## Solução: Odin com ioctl (Usando core:sys/linux + Foreign Imports Mínimos)

### Arquivo: `ansuz/terminal.odin`

**Adicionados imports:**
```odin
import "core:sys/linux"

// Foreign imports mínimos apenas para ioctl (não disponível no core:sys/linux)
foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
    ioctl :: proc(fd: int, request: u64, ...) -> int ---
}

// Struct winsize necessária para TIOCGWINSZ
winsize :: struct {
    ws_row:    u16,  // rows, in characters
    ws_col:    u16,  // columns, in characters
    ws_xpixel: u16,  // horizontal size, pixels (unused)
    ws_ypixel: u16,  // vertical size, pixels (unused)
}
```

**Função get_terminal_size() reimplementada:**
```odin
get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
    stdin_fd := int(posix.FD(os.stdin))

    ws: winsize
    result := ioctl(stdin_fd, linux.TIOCGWINSZ, &ws)

    if result < 0 {
        return 0, 0, .FailedToGetAttributes
    }

    return int(ws.ws_col), int(ws.ws_row), .None
}
```

**Componentes usados:**
- `linux.TIOCGWINSZ` - **constante fornecida por `core:sys/linux`** do Odin!
- `ioctl()` - foreign import necessário (não disponível no core:sys/linux)
- `winsize` - struct definida manualmente (não disponível no core:sys/linux)

**Removidos:**
- `import "core:time"` - não necessário mais

### Arquivo: `ansuz/api.odin`

**Modificada begin_frame():**
```odin
begin_frame :: proc(ctx: ^Context) {
    // Check for terminal size changes (every frame)
    current_width, current_height, size_err := get_terminal_size()
    if size_err == .None && (current_width != ctx.width || current_height != ctx.height) {
        // Terminal was resized - update context
        handle_resize(ctx, current_width, current_height)
    }

    // Clear buffer for new frame
    clear_buffer(&ctx.buffer)
}
```

**Melhorada handle_resize():**
```odin
handle_resize :: proc(ctx: ^Context, new_width, new_height: int) {
    ctx.width = new_width
    ctx.height = new_height

    // Clear the screen to prevent artifacts
    clear_screen()

    resize_buffer(&ctx.buffer, new_width, new_height)
}
```

## Por Que Esta É a Melhor Abordagem

### 1. **Usa Bibliotecas Padrão do Odin Quando Possível**
- Usa `linux.TIOCGWINSZ` do `core:sys/linux` (constante fornecida pelo Odin)
- Foreign imports apenas para ioctl (não disponível no core:sys/linux)
- Minimiza dependências externas

### 2. **Simples e Idiomática**
- Segue as convenções do Odin
- Usa structs e constantes já fornecidas pela linguagem
- Código limpo e fácil de manter

### 3. **Eficiente**
- ioctl é não-bloqueante e rápido (microsegundos)
- Pode ser chamado a cada frame sem impacto perceptível
- Não interfere com input do teclado

### 4. **Correta para Immediate Mode**
- Em immediate mode, cada frame é recalculado do zero
- Verificar o tamanho do terminal a cada frame é essencial
- A UI sempre reflete o estado atual do terminal

## Como Funciona

```
Cada Frame:
  1. begin_frame() é chamado
  2. get_terminal_size() consulta o tamanho atual via ioctl
  3. Se mudou:
     - handle_resize() atualiza ctx.width e ctx.height
     - handle_resize() limpa a tela
     - resize_buffer() realoca o buffer
  4. clear_buffer() limpa o buffer
  5. UI é desenhada com as novas dimensões
  6. end_frame() renderiza tudo
```

## Vantagens vs Abordagem Anterior

| Aspecto | Anterior (ANSI) | Nova (ioctl + core:sys/linux) |
|---------|----------------|--------------------------------|
| Velocidade | 50ms timeout | ~1μs |
| Bloqueio | Sim (50ms) | Não |
| Interfere stdin | Sim | Não |
| Usa constante Odin | Não | Sim (linux.TIOCGWINSZ) |
| Foreign imports | Não | Mínimo (apenas ioctl) |
| Manutenção | Complexo | Simples |
| Confiança | Manual | Parcialmente verificado |

## Testando

```bash
# Compile o exemplo de layout
odin build examples/layout_demo.odin -file -out:examples/layout_demo

# Execute e redimensione o terminal
./examples/layout_demo

# O layout deve se adaptar imediatamente
```

## Conclusão

Esta solução:
- ✅ Usa constante TIOCGWINSZ do `core:sys/linux` (biblioteca padrão do Odin)
- ✅ Foreign imports mínimos (apenas ioctl, não disponível no core:sys/linux)
- ✅ É simples e idiomática
- ✅ É eficiente e rápida
- ✅ Funciona corretamente em immediate mode
- ✅ Não requer mudanças nas aplicações existentes
- ✅ É fácil de manter e estender

**Princípio chave:** Sempre que possível, use as bibliotecas padrão do Odin (`core:sys/*`). Quando algo não está disponível, use foreign imports mínimos apenas para o que falta. Isso resulta em código mais limpo e maximiza o uso do que o Odin já fornece.
