# Refatoração para Immediate Mode Puro

## Resumo

A biblioteca Ansuz foi refatorada para usar um modelo de **immediate mode puro**, onde toda a tela é re-renderizada completamente a cada frame. Isso torna a biblioteca muito mais simples de entender, manter e usar.

## Mudanças Principais

### 1. Remoção do Double Buffering

**Antes:**
```odin
Context :: struct {
    front_buffer: FrameBuffer,
    back_buffer:  FrameBuffer,
    // ...
}
```

**Depois:**
```odin
Context :: struct {
    buffer: FrameBuffer,  // Apenas um buffer
    // ...
}
```

### 2. Remoção da Flag "Dirty"

**Antes:**
```odin
Cell :: struct {
    rune:     rune,
    fg_color: Color,
    bg_color: Color,
    style:    StyleFlags,
    dirty:    bool,  // Removido!
}
```

**Depois:**
```odin
Cell :: struct {
    rune:     rune,
    fg_color: Color,
    bg_color: Color,
    style:    StyleFlags,
}
```

### 3. Simplificação do set_cell

**Antes:**
```odin
set_cell :: proc(buffer: ^FrameBuffer, x, y: int, r: rune, fg, bg: Color, style: StyleFlags) -> BufferError {
    cell := get_cell(buffer, x, y)
    if cell == nil {
        return .OutOfBounds
    }

    // Verificar se mudou para marcar dirty
    changed := cell.rune != r || 
               cell.fg_color != fg || 
               cell.bg_color != bg || 
               cell.style != style

    if changed {
        cell.rune = r
        cell.fg_color = fg
        cell.bg_color = bg
        cell.style = style
        cell.dirty = true
    }

    return .None
}
```

**Depois:**
```odin
set_cell :: proc(buffer: ^FrameBuffer, x, y: int, r: rune, fg, bg: Color, style: StyleFlags) -> BufferError {
    cell := get_cell(buffer, x, y)
    if cell == nil {
        return .OutOfBounds
    }

    cell.rune = r
    cell.fg_color = fg
    cell.bg_color = bg
    cell.style = style

    return .None
}
```

### 4. Remoção do render_diff

**Removidas:**
- `render_diff()` - Não é mais necessário
- `clear_dirty_flags()` - Não existem mais flags dirty
- `cells_equal()` - Não comparamos mais células

**Mantida:**
- `render_to_string()` - Agora sempre renderiza o buffer completo

### 5. Simplificação do Frame Cycle

**Antes:**
```odin
begin_frame :: proc(ctx: ^Context) {
    clear_buffer(&ctx.back_buffer)
    clear_dirty_flags(&ctx.back_buffer)
}

end_frame :: proc(ctx: ^Context) {
    output := render_diff(&ctx.back_buffer, &ctx.front_buffer, context.temp_allocator)
    write_ansi(output)
    flush_output()
    copy(ctx.front_buffer.cells, ctx.back_buffer.cells)
    ctx.frame_count += 1
}
```

**Depois:**
```odin
begin_frame :: proc(ctx: ^Context) {
    clear_buffer(&ctx.buffer)
}

end_frame :: proc(ctx: ^Context) {
    output := render_to_string(&ctx.buffer, context.temp_allocator)
    write_ansi(output)
    flush_output()
    ctx.frame_count += 1
}
```

### 6. Atualização das Funções de API

Todas as funções da API (`text`, `box`, `rect`) agora usam `ctx.buffer` em vez de `ctx.back_buffer`.

## Benefícios

### Simplicidade
- **Menos código**: Removido todo o código de dirty tracking e diffing
- **Mais fácil de entender**: O fluxo é linear e direto
- **Menos bugs**: Menos estados para rastrear significa menos chance de bugs

### Alinhamento com Immediate Mode
- **True immediate mode**: Cada frame é uma declaração completa do estado visual
- **Sem estado oculto**: Não há buffers escondidos ou flags de dirty
- **Previsível**: O que você desenha é o que aparece, sempre

### Performance Adequada
Para aplicações TUI típicas:
- Terminais modernos lidam bem com re-renderização completa
- A maioria das TUIs não precisa de 60 FPS
- O gargalo é geralmente o I/O do terminal, não a geração do buffer

## Arquivos Modificados

1. **ansuz/buffer.odin**
   - Removido campo `dirty` da struct `Cell`
   - Simplificado `clear_buffer()`
   - Simplificado `set_cell()`
   - Removido `clear_dirty_flags()`
   - Removido `cells_equal()`
   - Removido `render_diff()`
   - Atualizado comentários de `render_to_string()`
   - Simplificado `resize_buffer()`

2. **ansuz/api.odin**
   - Alterado `Context` para ter apenas um `buffer`
   - Atualizado `init()` para criar apenas um buffer
   - Atualizado `shutdown()` para limpar apenas um buffer
   - Simplificado `begin_frame()`
   - Simplificado `end_frame()` (usa `render_to_string()`)
   - Atualizado `text()`, `box()`, `rect()` para usar `ctx.buffer`
   - Atualizado `handle_resize()` para redimensionar apenas um buffer

## Uso

Não há mudanças necessárias no código do usuário! A API permanece a mesma:

```odin
ansuz.begin_frame(ctx)

// Desenhe sua UI
ansuz.text(ctx, 10, 5, "Hello, World!", style)
ansuz.box(ctx, 5, 3, 30, 10, style)

ansuz.end_frame(ctx)
```

## Compatibilidade

Esta é uma mudança interna que não afeta a API pública. Todos os exemplos existentes continuam funcionando sem modificações.

## Próximos Passos

Com essa simplificação, a biblioteca agora está muito mais fácil de:
- Manter e depurar
- Estender com novos widgets
- Documentar e ensinar
- Otimizar se necessário (perfil primeiro!)

Se no futuro for necessário otimização, podemos adicionar:
- Renderização incremental opcional
- Caching de strings ANSI
- Dirty regions (mas apenas se o profiling mostrar necessidade)
