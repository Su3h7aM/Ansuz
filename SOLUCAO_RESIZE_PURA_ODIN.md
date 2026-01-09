# Solução Correta: Terminal Resize - Odin Puro

## Problema Original

O layout quebrava quando o terminal era redimensionado porque:
1. O tamanho do terminal era consultado apenas uma vez na inicialização
2. As dimensões do contexto nunca eram atualizadas
3. O buffer de framebuffer nunca era redimensionado
4. O layout usava dimensões obsoletas

## Solução: Odin Puro (100%)

### Arquivo: `ansuz/terminal.odin`

**Adicionado import:**
```odin
import "core:sys/linux"
```

**Função get_terminal_size() reimplementada:**
```odin
get_terminal_size :: proc() -> (width, height: int, err: TerminalError) {
    stdin_fd := int(posix.FD(os.stdin))

    ws: linux.winsize
    result := linux.ioctl(stdin_fd, linux.TIOCGWINSZ, &ws)

    if result < 0 {
        return 0, 0, .FailedToGetAttributes
    }

    return int(ws.ws_col), int(ws.ws_row), .None
}
```

**Componentes usados do Odin:**
- `linux.winsize` - struct fornecida por `core:sys/linux`
- `linux.TIOCGWINSZ` - constante fornecida por `core:sys/linux`
- `linux.ioctl()` - função fornecida por `core:sys/linux`

**Removidos:**
- `foreign import libc "system:c"` - não necessário
- Definições manuais de structs e constantes - já existem no Odin
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

### 1. **100% Odin Puro**
- Usa apenas bibliotecas padrão do Odin (`core:sys/linux`)
- Sem dependências em C
- Sem foreign imports desnecessários

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

| Aspecto | Anterior (ANSI) | Nova (ioctl via core:sys/linux) |
|---------|----------------|--------------------------------|
| Velocidade | 50ms timeout | ~1μs |
| Bloqueio | Sim (50ms) | Não |
| Interfere stdin | Sim | Não |
| Código Odin | Sim (mas com C) | 100% Odin |
| Manutenção | Complexo | Simples |
| Confiança | Manual | Verificado (biblioteca padrão) |

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
- ✅ É 100% pura em Odin
- ✅ Usa apenas bibliotecas padrão (`core:sys/linux`)
- ✅ É simples e idiomática
- ✅ É eficiente e rápida
- ✅ Funciona corretamente em immediate mode
- ✅ Não requer mudanças nas aplicações existentes
- ✅ É fácil de manter e estender

**Princípio chave:** Sempre que possível, use as bibliotecas padrão do Odin (`core:sys/*`) em vez de foreign imports em C. Isso resulta em código mais limpo, mais seguro e mais fácil de manter.
