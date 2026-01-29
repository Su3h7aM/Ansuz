# Comparação de Implementação de TUI: Ansuz vs Ratatui vs Charm

Este documento compara como implementar uma interface simples (uma borda arredondada centralizada com texto) usando três bibliotecas diferentes: **Ansuz** (Odin), **Ratatui** (Rust) e **Charm/Bubbletea** (Go).

## 1. Ansuz (Nossa Biblioteca - Odin)

O Ansuz utiliza uma abordagem **Immediate Mode** com um sistema de layout flexível embutido. O posicionamento é feito declarativamente na chamada de desenho.

### Código
```odin
// Dentro do loop de renderização ou função update
ansuz.Layout_begin_container(ctx, {
    direction = .TopToBottom,
    sizing = {ansuz.Sizing_grow(), ansuz.Sizing_grow()}, // Ocupa toda a tela
    alignment = {horizontal = .Center, vertical = .Center}, // Centraliza os filhos
})

    // Caixa com borda arredondada
    ansuz.Layout_box(ctx, ansuz.STYLE_NORMAL, {
        sizing = {ansuz.Sizing_fixed(40), ansuz.Sizing_fixed(10)},
        alignment = {horizontal = .Center, vertical = .Center}, // Centraliza o texto dentro da caixa
    }, .Rounded)
        ansuz.Layout_text(ctx, "Olá Ansuz!", ansuz.STYLE_BOLD)
    ansuz.Layout_end_box(ctx)

ansuz.Layout_end_container(ctx)
```

### Características
- **Paradigma**: Immediate Mode.
- **Layout**: Flexbox-like integrado (`sizing`, `alignment`, `direction`).
- **Bordas**: Propriedade do container (`.Rounded`), desenhada automaticamente.
- **Centralização**: Feita via propriedade `alignment` no container pai.

---

## 2. Ratatui (Rust)

Ratatui utiliza uma separação estrita entre Layout (cálculo de áreas `Rect`) e Renderização (desenho de `Widgets` nessas áreas). Centralizar algo geralmente exige uma função auxiliar para calcular o `Rect` central.

### Código
```rust
use ratatui::{prelude::*, widgets::*};

fn draw(f: &mut Frame) {
    let area = f.size();
    
    // Função auxiliar necessária para criar o Rect centralizado
    let popup_area = centered_rect(area, 40, 10); 

    let block = Block::default()
        .borders(Borders::ALL)
        .border_type(BorderType::Rounded)
        .title("Ratatui");

    let paragraph = Paragraph::new("Olá Rust!")
        .block(block) // A borda pertence ao widget
        .alignment(Alignment::Center); // Alinhamento do texto

    f.render_widget(paragraph, popup_area);
}

// Helper comum no ecosistema Ratatui
fn centered_rect(r: Rect, w: u16, h: u16) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length((r.height - h) / 2),
            Constraint::Length(h),
            Constraint::Length((r.height - h) / 2),
        ])
        .split(r);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Length((r.width - w) / 2),
            Constraint::Length(w),
            Constraint::Length((r.width - w) / 2),
        ])
        .split(popup_layout[1])[1]
}
```

### Características
- **Paradigma**: Retained/Immediate mista (recalcula layout todo frame).
- **Layout**: Baseado em `Constraints` (Restrições) que dividem áreas.
- **Bordas**: Componente `Block` que embrulha outros widgets.
- **Centralização**: Manual ou via helpers de corte de layout.

---

## 3. Charm / Bubbletea + Lipgloss (Go)

Charm usa o paradigma **The Elm Architecture** (Model-View-Update). O layout e estilo são fortemente baseados em **Lipgloss**, que funciona de forma similar ao CSS.

### Código
```go
import "github.com/charmbracelet/lipgloss"

// Definição de estilo (CSS-like)
var style = lipgloss.NewStyle().
    BorderStyle(lipgloss.RoundedBorder()).
    BorderForeground(lipgloss.Color("63")).
    Width(40).
    Height(10).
    Align(lipgloss.Center). // Alinha texto horizontalmente
    Padding(1)

func (m Model) View() string {
    // Renderiza o conteúdo (caixa com borda)
    content := style.Render("Olá Go!")

    // Centraliza o conteúdo na tela inteira
    return lipgloss.Place(
        m.width, m.height,
        lipgloss.Center, lipgloss.Center,
        content,
    )
}
```

### Características
- **Paradigma**: Declarativo / Componentizado (String-based return).
- **Layout**: CSS-like (`Padding`, `Margin`, `Align`).
- **Bordas**: Definidas no estilo (`BorderStyle`).
- **Centralização**: Utilitário `lipgloss.Place` para posicionar strings renderizadas em um espaço maior.

---

## Resumo da Comparação

| Característica | Ansuz (Odin) | Ratatui (Rust) | Charm (Go) |
| :--- | :--- | :--- | :--- |
| **Bordas** | Argumento do container (`.Rounded`) | Widget `Block` wrapper | Estilo Lipgloss (`BorderStyle`) |
| **Layout** | Container properties (`grow`, `fixed`) | Constraints Solver (`Layout::split`) | CSS-like properties |
| **Centralização** | `alignment` no pai | Cálculo manual de `Rect` | `lipgloss.Place` |
| **Verbosidade** | Média (Lógica de layout explicita) | Alta (Layout separado da renderização) | Baixa (Estilo separado, view concisa) |

O Ansuz busca um meio-termo, oferecendo a facilidade de layout do CSS (como o Charm/Flexbox) mas mantendo a performance e estrutura imperativa do Immediate Mode, evitando a complexidade de cálculo de retângulos manuais do Ratatui.
