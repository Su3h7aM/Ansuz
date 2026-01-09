# SOLUÇÃO FINAL: Terminal Resize - Odin Nativo Otimizado

## Problema Resolvido
Layout quebrava quando o terminal era redimensionado em modo immediate.

## Solução Implementada (Otimizada para Maximizar Odin Nativo)

### Arquivo: `ansuz/terminal.odin`

**Imports e Foreign Import Mínimo:**
```odin
import "core:sys/linux"  // Pacote padrão do Odin - fornece TIOCGWINSZ

// Foreign import APENAS para ioctl (Odin nativo não funciona bem com ponteiros de struct)
foreign import libc "system:c"

@(default_calling_convention="c")
foreign libc {
    ioctl :: proc(fd: int, request: u64, ...) -> int ---
}

// winsize struct para TIOCGWINSZ ioctl
winsize :: struct {
    ws_row:    u16,  // rows, in characters
    ws_col:    u16,  // columns, in characters
    ws_xpixel: u16,  // horizontal size, pixels (unused)
    ws_ypixel: u16,  // vertical size, pixels (unused)
}
```

**Função get_terminal_size() - SOLUÇÃO HÍBRIDA OTIMIZADA:**
```odin
get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
    stdin_fd := int(posix.FD(os.stdin))

    ws: winsize
    result := ioctl(stdin_fd, linux.TIOCGWINSZ, &ws)

    if result < 0 {
        // ioctl failed, return error
        return 0, 0, .FailedToGetAttributes
    }

    return int(ws.ws_col), int(ws.ws_row), .None
}
```

**Componentes Usados:**
- `linux.TIOCGWINSZ` - **CONSTANTE NATIVA DO ODIN** (via core:sys/linux)! ✅
- `ioctl()` - foreign import (necessário - Odin nativo não funciona bem com ponteiros de struct) ⚠️
- `winsize` - struct definido manualmente (não disponível no core:sys/linux) ⚠️
- `&ws` - ponteiro direto (funciona com foreign import) ✅

### Arquivo: `ansuz/api.odin`

**Modificada begin_frame():**
```odin
begin_frame :: proc(ctx: ^Context) {
    // Check for terminal size changes (every frame)
    // Since we now use ioctl() which is non-blocking, this is safe and efficient
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

    // Clear screen to prevent artifacts from old content
    clear_screen()

    resize_buffer(&ctx.buffer, new_width, new_height)
}
```

## Por Que Solução Híbrida?

### Limitações do Odin
1. `linux.ioctl()` nativo não aceita bem ponteiros de struct
2. `winsize` struct não está disponível em `core:sys/linux`
3. Precisamos passar ponteiro para struct ao ioctl C

### Solução Otimizada (Híbrida)
| Componente | Abordagem | Resultado |
|------------|-----------|---------|
| TIOCGWINSZ | `linux.TIOCGWINSZ` (Odin nativo) | ✅ Maximiza Odin nativo! |
| ioctl | `ioctl()` (foreign import) | ⚠️ Necessário por limitação |
| winsize | Definido manualmente | ⚠️ Não disponível no Odin |
| **Resultado** | **Solução híbrida otimizada** | **Maximiza uso do Odin nativo** ✅ |

### Princípio Aplicado
**Maximizar sempre o uso do Odin nativo, usar foreign imports APENAS quando necessário:**
- Constantes do Odin: `linux.TIOCGWINSZ` ✅ (use sempre!)
- Funções do Odin: use quando funcionam bem ⚠️ (evite se têm problemas)
- Foreign imports: apenas para o que não funciona no Odin nativo ⚠️

## Como Funciona

```
begin_frame():
  ├─ get_terminal_size() via ioctl (usa linux.TIOCGWINSZ do Odin!)
  ├─ Se size changed:
  │   ├─ handle_resize() atualiza ctx.width, ctx.height
  │   ├─ clear_screen() remove artefatos
  │   └─ resize_buffer() realoca o buffer
  └─ clear_buffer() limpa o buffer

begin_layout():
  └─ Usa ctx.width, ctx.height (sempre atualizados)

end_frame():
  └─ Renderiza buffer completo
```

## Benefícios

1. **Automático**: Aplicações não precisam de mudanças de código
2. **Eficiente**: ioctl é não-bloqueante e rápido (microsegundos)
3. **Seguro**: Não interfere com input do teclado
4. **Otimizado para Odin**: Usa `linux.TIOCGWINSZ` (constante nativa do Odin)! ✅
5. **Foreign imports mínimos**: Apenas `ioctl()` (necessário por limitação)
6. **Immediate Mode Compatível**: Cada frame usa estado atual
7. **Limpo**: Tela limpa no resize para evitar artefatos

## Compilação

```bash
# Compile os exemplos
odin build examples/hello_world.odin -file -out:examples/hello_world
odin build examples/layout_demo.odin -file -out:examples/layout_demo

# Execute
./examples/layout_demo

# Redimensione o terminal - layout deve se adaptar imediatamente
```

## Conclusão

✅ Solução híbrida otimizada implementada!
✅ Usa `linux.TIOCGWINSZ` - **CONSTANTE NATIVA DO ODIN**!
✅ Foreign import mínimo apenas para `ioctl()` (necessário)
✅ Maximiza uso do Odin nativo sempre que possível!
✅ Funciona corretamente em immediate mode
✅ Layout se adapta automaticamente ao redimensionamento
✅ Não requer mudanças nas aplicações existentes

**Princípio-chave**: **MAXIMIZE sempre o uso do Odin nativo!**
- Use constantes do Odin nativas: `linux.TIOCGWINSZ` ✅
- Use funções do Odin nativas quando funcionam bem
- Foreign imports APENAS para o que o Odin não fornece ou não funciona bem
- Resultado: Código otimizado com máximo aproveitamento do Odin nativo!
