# Implementação Final: Correção de Redimensionamento de Terminal

## Problema Resolvido

O layout quebrava quando o terminal era redimensionado em modo immediate.

## Solução Implementada

### Arquivo: `ansuz/terminal.odin`

**Adicionado import:**
```odin
import "core:sys/linux"  // Fornece ioctl() e TIOCGWINSZ nativos do Odin
```

**Struct winsize:**
```odin
// winsize struct para TIOCGWINSZ ioctl
winsize :: struct {
    ws_row:    u16,  // rows, in characters
    ws_col:    u16,  // columns, in characters
    ws_xpixel: u16,  // horizontal size, pixels (unused)
    ws_ypixel: u16,  // vertical size, pixels (unused)
}
```

**Função get_terminal_size() usando ioctl nativo do Odin:**
```odin
get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
    stdin_fd := posix.FD(os.stdin)

    ws: winsize
    result := linux.ioctl(stdin_fd, linux.TIOCGWINSZ, uintptr(&ws))

    if result < 0 {
        // ioctl failed, return error
        return 0, 0, .FailedToGetAttributes
    }

    return int(ws.ws_col), int(ws.ws_row), .None
}
```

**Componentes usados:**
- `linux.TIOCGWINSZ` - **CONSTANTE NATIVA DO ODIN** (via core:sys/linux)!
- `linux.ioctl()` - **FUNÇÃO NATIVA DO ODIN** (via core:sys/linux)!
- `winsize` struct - definido manualmente (não disponível no core:sys/linux)
- **100% ODIN NATIVO** - sem foreign imports, sem dependências em C!

**Removedo:**
- `import "core:time"` (não necessário)

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

    // Clear the screen to prevent artifacts from old content
    clear_screen()

    resize_buffer(&ctx.buffer, new_width, new_height)
}
```

## Como Funciona

### Frame Cycle (Solução Atual)
```
begin_frame():
  ├─ get_terminal_size() via linux.ioctl() (função nativa do Odin!)
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

## Detalhes Técnicos Importantes

### 100% Odin Nativo

| Componente | Fonte | Status |
|------------|---------|---------|
| ioctl() | `linux.ioctl()` | ✅ NATIVO DO ODIN (core:sys/linux) |
| TIOCGWINSZ | `linux.TIOCGWINSZ` | ✅ NATIVO DO ODIN (core:sys/linux) |
| winsize struct | Definido manualmente | ⚠️ Necessário (não disponível no Odin) |
| Foreign imports | NENHUM | ✅ 100% ODIN NATIVO! |

### Por Que Odin Nativo?

1. **Simplicidade**: Código mais limpo e fácil de entender
2. **Performance**: Funções nativas são otimizadas
3. **Segurança**: Menos dependências externas
4. **Idiomático**: Segue as convenções do Odin
5. **Manutenção**: Código Odin é mais fácil de manter

## Compilação

```bash
# Compile os exemplos
odin build examples/hello_world.odin -file -out:examples/hello_world
odin build examples/layout_demo.odin -file -out:examples/layout_demo

# Execute
./examples/layout_demo

# Redimensione o terminal - layout deve se adaptar imediatamente
```

## Benefícios

1. **Automático**: Aplicações não precisam de mudanças de código
2. **Eficiente**: ioctl é não-bloqueante e rápido (microsegundos)
3. **Seguro**: Não interfere com input do teclado
4. **Odin Nativo**: Usa `linux.ioctl()` e `linux.TIOCGWINSZ` - funções nativas!
5. **Sem Foreign Imports**: 100% Odin puro!
6. **Immediate Mode Compatível**: Cada frame usa estado atual
7. **Limpo**: Tela limpa no resize para evitar artefatos

## Conclusão

✅ Solução implementada 100% em Odin nativo!
✅ Usa `linux.ioctl()` - FUNÇÃO NATIVA DO ODIN!
✅ Usa `linux.TIOCGWINSZ` - CONSTANTE NATIVA DO ODIN!
✅ Sem foreign imports!
✅ Sem dependências em C!
✅ Funciona corretamente em immediate mode
✅ Layout se adapta automaticamente ao redimensionamento
✅ Não requer mudanças nas aplicações existentes

**Princípio Chave**: **SEMPRE use funções e constantes nativas do Odin primeiro!**
- O Odin fornece `linux.ioctl()` através do pacote `core:sys/linux`
- O Odin fornece `linux.TIOCGWINSZ` através do pacote `core:sys/linux`
- Só defina structs manualmente quando o Odin não as fornece
- Resultado: Código mais limpo, seguro e fácil de manter!
