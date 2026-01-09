# Solução Final: Terminal Resize - Implemetação Corrigida

## Problema
O layout quebrava quando o terminal era redimensionado em modo immediate.

## Solução Implementada

### 1. Arquivo: `ansuz/terminal.odin`

**Imports adicionados:**
```odin
import "core:sys/linux"  // Fornece TIOCGWINSZ constant

// Foreign import mínimo para ioctl (não disponível no core:sys/linux)
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

**O que mudou:**
- Usa `linux.TIOCGWINSZ` do `core:sys/linux` (constante do Odin!)
- Foreign import apenas para `ioctl()` (não disponível no core:sys/linux)
- Struct `winsize` definida manualmente (não disponível no core:sys/linux)
- Removedo `import "core:time"` (não necessário mais)

### 2. Arquivo: `ansuz/api.odin`

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

    // Clear the screen to prevent artifacts from old content
    clear_screen()

    resize_buffer(&ctx.buffer, new_width, new_height)
}
```

## Como Funciona

```
A cada frame:
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

## Compilação e Teste

```bash
# Compile os exemplos
odin build examples/hello_world.odin -file -out:examples/hello_world
odin build examples/layout_demo.odin -file -out:examples/layout_demo

# Execute o layout_demo
./examples/layout_demo

# Redimensione o terminal - o layout deve se adaptar imediatamente
```

## Principais Pontos da Solução

1. **Usa a biblioteca padrão do Odin**:
   - `linux.TIOCGWINSZ` vem de `core:sys/linux` (não definido manualmente)
   - Maximiza o uso do que o Odin já fornece

2. **Foreign imports mínimos**:
   - Apenas `ioctl()` precisa de foreign import
   - TIOCGWINSZ já está disponível no Odin
   - Struct winsize precisa ser definido manualmente

3. **Correto para immediate mode**:
   - Verifica o tamanho a cada frame
   - UI sempre reflete o estado atual

4. **Eficiente**:
   - ioctl é não-bloqueante e rápido (microsegundos)
   - Pode ser chamado a cada frame sem impacto perceptível

5. **Sem interferência**:
   - Não interfere com input do teclado
   - Não bloqueia o loop de renderização

## Resumo Técnico

| Componente | Fonte |
|------------|---------|
| TIOCGWINSZ constant | `core:sys/linux` (Odin stdlib) ✅ |
| ioctl() function | foreign import libc (necessário) |
| winsize struct | definido manualmente (necessário) |
| termios, tcgetattr, tcsetattr | `core:sys/posix` (Odin stdlib) ✅ |

**Princípio**: Use sempre as bibliotecas padrão do Odin (`core:sys/*`) quando possível. Use foreign imports apenas para o que não está disponível.

## Conclusão

✅ Solução implementada corretamente
✅ Usa biblioteca padrão do Odin quando possível
✅ Foreign imports mínimos apenas para ioctl
✅ Funciona corretamente em immediate mode
✅ Layout se adapta automaticamente ao redimensionamento
✅ Não requer mudanças nas aplicações existentes
