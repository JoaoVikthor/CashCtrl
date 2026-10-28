# Auditoria & Plano de Redesign — CashCtrl (2026-10-08)

> Fonte: design-analyst (skills ui-taste + redesign-existing-projects), salvo pelo orquestrador porque a sessão do agente não tinha ferramenta de escrita. Plano só-leitura — nenhuma mudança em `lib/`.

## 1. Resumo executivo

O CashCtrl tem identidade forte (paleta verde-escura + dourado, camaleão, microcopy PT-BR bem escrita) mas **não tem design system**: 27 arquivos redeclaram o mesmo bloco de 5 cores (`79` declarações `static const Color` + `100+` ocorrências `0xFF` inline em lib/), e o `ThemeData` do `main.dart` define apenas `scaffoldBackgroundColor` e um `ColorScheme.dark` de 2 campos — sem `textTheme`, `cardTheme`, `inputDecorationTheme`, `buttonTheme` ou `snackBarTheme`. Consequência: 15 tamanhos de fonte ad-hoc, 11 valores de `borderRadius` (3→50), `Colors.green/red/orange/blue` cruas em ~100 pontos (a assinatura visual mais "template IA" do app), e cada tela reimplementa fields, chips, empty states e banners. Os pontos fortes são reais e devem ser preservados: `AppBrandedHeader`/`AppDrawer` consistentes, widgets `EmptyState`/`ErrorState`/`OfferCard`/`FilterChipRow`/`SearchField` de boa qualidade (subutilizados), forms de oferta com validação inline e preview de preço por unidade, e o fluxo de ofertas com confirmação + undo + auditoria (excelente UX). O plano é em 4 ondas: fundação (tokens + tema Material 3 completo + tipografia com algarismos tabulares), telas núcleo (login, home, drawer), domínio de produtos (o coração do diferencial), e por fim forms/settings/states — tudo validado antes por protótipos HTML na paleta real, começando pelo **dashboard** e pelo **login**.

## 2. Diagnóstico por tela

| Tela | Pontos fortes | Problemas | Pri |
|---|---|---|---|
| **main.dart (tema)** | `ColorScheme.dark` com primary/secondary da paleta; `AuthGate` com loading próprio | Tema mínimo (2 campos); sem textTheme/cardTheme/inputTheme/buttons/snackbars/dialogs/bottomsheet; loading do AuthGate usa cores inline | **P0** |
| **login_screen** | Boa estrutura (logo → wordmark → fields → social → CTA registro); loading individual por botão; borders com focus gold; FA só nas marcas (justificado) | Wordmark 32px sem escala; `Colors.grey` cru; validação só por SnackBar; "Esqueceu a senha?" 13px com alvo pequeno; layout genérico | P1 |
| **cadastro_screen** | PageView 2 etapas com step indicator (verde/dourado); checkbox de termos | Validação sequencial só via SnackBar (nenhum errorText inline); `Colors.grey` cru; sem máscara CNPJ/telefone | P1 |
| **home_screen (dashboard)** | Boa estrutura de seções; gráfico de pizza; recentes com avatar | **4 KPI cards idênticos** (grid 2×2, valor 15px < título 16px — hierarquia invertida); greeting 26px fora de escala; radius 20 num card e 15 nos outros; "Nova Transação" botão no fim da lista vs FAB em outras telas; loading = spinner nu; empty/error inline duplicando widgets | **P0** |
| **budgets_screen** | Barra de progresso com cor da categoria; menu editar/excluir; empty state | Erro vaza exceção crua; 3ª cor de sistema (18 hexes de categoria fora da paleta); progresso minHeight 10 grosso demais | P1 |
| **expenses_screen** | Resumo receita/despesa/saldo; filtros + busca; Dismissible com confirmação | `_filterChip` reimplementa `AppFilterChipRow`; empty state inline; erro cru; hint `white38` ilegível | P1 |
| **reports_screen** | KPIs com descritivos; barras fl_chart; top 5 | KPI grid idêntico ao home (mesmo template); `Colors.green/red` cruas; tamanhos de título inconsistentes | P1 |
| **settings_screen** | Header de perfil com iniciais; tiles com chevron; logout claro | Título de seção 22px; ListTile solto sem agrupamento; "Sair" vermelho puro colado no fim | P2 |
| **settings/*** | Subtítulos explicativos; tema do showTimePicker customizado | SnackBars "em breve" como feedback de feature inexistente; `Colors.grey` cru; help_screen com microcopy boa | P2 |
| **ingredients_screen** | Card denso com hierarquia (nome → ofertas → preço/un gold); markers ativa/melhor; empty com CTA | Long-press para ofertas é gesto oculto; card com 3 colunas + botão — risco de overflow; spinner nu | P1 |
| **ingredient_form_screen** | Preview de preço/un ao vivo (excelente); 3 estados de fornecedor; policy copy | Banner laranja inline (duplicado em 3 outros arquivos); validação só SnackBar | P1 |
| **ingredient_offers_screen** | **Melhor tela do app**: summary, filtros, ranking, confirmação + undo, banner limite, empty/legacy | Densidade alta antes da 1ª oferta (≈2,5 telas de scroll); "só com economia" minúsculas inconsistente | P1 |
| **offer_form_screen** | **Referência de form**: errorText inline, helper, counter, preview, comparação com ativa | textarea de notas sem limite visual até 160 chars | P2 |
| **compare_prices_screen** | Tabs produto/fornecedor; eco-line hero 20px; chips de fornecedor com tooltip; estados | `_buildSupplierChip` duplica `AppFilterChipRow`; eco-line usa `Colors.green` cru; 2 linhas de chips empilhadas | P1 |
| **audit_logs_screen** | Timeline agrupada por dia; bottom sheet de detalhe; usa EmptyState/ErrorState | Densidade boa; sem problemas graves | P2 |
| **products_screen** | Card com bloco custo/lucro destacado; empty condicional inteligente | AppBar reimplementa `AppBrandedHeader`; lucro 18px vs venda 12px; veredito com verde/vermelho Material cru | P1 |
| **product_form_screen** | Live preview de ticket — excelente; picker bottom sheet; custo por linha | TextField de quantidade 72px com alvo apertado; sem busca no picker; validação SnackBar; delete vermelho cru | P1 |
| **product_detail_screen** | **Hero do veredito 36px** — melhor momento visual do app | "ESTE PRODUTO DÁ LUCRO" ALL CAPS; coluna custo fixa 90px; `Divider white24` cru | P1 |
| **product_scanner_screen** | Sheets reconhecido/novo com CTA; estado de upload | Falta estado de permissão de câmera negada; "Produto reconhecido!" (anti-pattern de copy) | P2 |
| **app_drawer** | Header com logo + tagline; item ativo verde + bold; versão no rodapé | Tagline genérica; item ativo sem barra indicadora; errorBuilder `Icons.ac_unit` | P1 |
| **app_branded_header** | API flexível (logo/título, back/menu); transparente | Título sempre centrado; texto branco puro sem token | P2 |
| **empty_state / error_state** | Boa hierarquia ícone→título→mensagem→CTA | Subutilizados (5 telas reimplementam inline); ErrorState mostra exceção crua | **P0** |
| **offer_card / panel_product_card / supplier_summary_card** | Boa densidade; ações 44dp; delta colorido | Números sem tabular figures; `Colors.green` como const de widget | P1 |

## 3. Diagnóstico sistêmico

1. **Não existe design system central.** `lib/` não tem `theme/` ou `core/` de tokens:
   - **100+** ocorrências de `Color(0xFF…)` (estimado ~130);
   - **79** declarações `static const Color _color…` em **27 arquivos** — mesmo bloco de 5 cores copiado ~20×;
   - **~100** usos de `Colors.green/red/orange/blue` — fora da paleta, pálidos sobre `0xFF0D1E16`;
   - **18 hexes** extras em `utils/categories.dart` (3º sistema paralelo);
   - **11 valores** de `borderRadius` (3→50) sem escala; **15 tamanhos** de fonte (10→36) sem escala.
2. **`MaterialApp` theme** (`main.dart:98-104`): só `scaffoldBackgroundColor` + `ColorScheme.dark(primary, secondary)`. ElevatedButton/TextField/SnackBar/AlertDialog/BottomSheet reescritos copy-paste em ~10-15 arquivos (SnackBar com 3 fundos diferentes).
3. **Números**: `utils/format.dart` correto em pt-BR, mas **sem `FontFeature.tabularFigures()`** — valores dançam em colunas. Maior ganho premium de baixo custo para app financeiro.
4. **Ícones**: Material `*_outlined` dominante e coeso; FontAwesome só em Google/Facebook no login (legítimo). Problema: mistura de pesos pontual (`warning_amber` vs `_rounded`, filled vs outline) e `Icons.ac_unit` como fallback no drawer.
5. **Estados**: spinner nu em ~15 telas (zero skeletons); empty states duplicados inline em 5 telas apesar do `EmptyState` existir; erros vazam exceção crua em budgets/expenses/ingredients/products.
6. **Sinais de template IA**: grid 2×2 de KPIs idênticos (home e reports); FAB verde + AppBar centralizada; `Colors.green/red` crus; login no layout mais comum; snackbars coloridos como único feedback; "ESTE PRODUTO DÁ LUCRO" ALL CAPS.

## 4. Plano de redesenho por ondas

> Regra transversal: **nenhuma cor da identidade fixa muda** (0xFF0D1E16, 0xFF165A41, 0xFFB89775, 0xFF142A20, 0xFF7A8B83), **logo camaleão intocável**. Tokens *derivados* (borda, sucesso/perigo/aviso, texto terciário) são novidades que passam por aprovação no protótipo.

### Onda 1 — Fundação (prerequisite de tudo; risco baixo, impacto sistêmico)

**Arquivos novos:** `lib/theme/app_colors.dart`, `app_spacing.dart`, `app_radius.dart`, `app_typography.dart`, `app_theme.dart` (+ `assets/fonts/` se bundlar fonte).

- **Tokens de cor**: 5 fixos + derivados propostos:
  - `colorBorder` `0xFF1E3A2C` (unificar com divider `0xFF1F3A2C` do drawer);
  - `colorTextTertiary`; semânticos `colorSuccess`/`colorDanger`/`colorWarning` harmonizados com o fundo (substituir os ~100 `Colors.green/red/orange` crus; valores calibrados no protótipo);
  - categorias de `categories.dart` mantidas (cor de dados), centralizadas.
- **Espaçamento**: base 4; ritmo 8/12/16/20/24/32 (screen padding 20, seções 24, internos 8/12). Eliminar 14/15/18/22/30.
- **Raio**: `sm=8` (inputs internos/tags), `md=12` (padrão cards/botões/fields), `lg=16` (hero/veredito), `pill=999` (chips). Eliminar 3/4/6/10/15/20/22/50.
- **Tipografia**: escala **28/20/16/14/12/11** com pesos 700/600/500/400 (28=hero, 20=título, 16=seção/card, 14=corpo, 12=secundário, 11=caption mínimo). Nada abaixo de 11.
  - `AppNumberStyle` com `FontFeature.tabularFigures()` para todo R$/%.
  - Família: bundlar **Manrope** (ou Outfit) 2 pesos (~200 KB) em `assets/fonts/`; contra `google_fonts`: dependência de rede/flash no cold start. Alternativa zero-dependência (P2): Roboto + tabularFigures.
- **ThemeData completo** (herda o visual atual): ColorScheme seeds da paleta; textTheme; AppBarTheme transparente elevation 0; CardThemeData(elevation 0, colorCard, borda `0xFF1E3A2C`, radius 12); InputDecorationTheme (filled card, radius 12, focus gold 1.5); ElevatedButtonTheme (verde, radius 12, vertical 16, elevation 0, peso 600); FAB, SnackBar (bg card + borda + ícone por tipo; parar de usar dourado como sucesso), BottomSheet (radius 16 top), Dialog, Divider (`0xFF1E3A2C`), Chip.
- **Migração mecânica**: apagar os ~20 blocos `static const Color` e importar tokens; `Colors.white38/white54/grey/white70` → tokens de texto. **Sem mudar layout nesta onda.**
- **Não mudar**: paleta, logo, microcopy, rotas.

### Onda 2 — Telas núcleo (login, home, drawer, cadastro)

- **Home**: quebrar o 2×2 idêntico → **1 card hero "Saldo Total"** (28 tabular + delta semântico) + 3 cards menores (Receitas/Despesas/Economia, valor 20 tabular); greeting 26→20 + subtítulo 12; `SectionHeader` unificado; "Nova Transação" → **FAB**; loading → **skeleton**; usar `EmptyState`/`ErrorState` existentes; extrair `TransactionListTile` compartilhado com Expenses.
- **Login**: escala (wordmark 28, tagline 14); token no lugar de `Colors.grey`; **validação inline** por campo (padrão offer_form); FA só nos sociais.
- **Drawer/Header**: item ativo com **barra indicadora gold 3px**; tagline → propor "Custos, ofertas e ticket sob controle" (**aprovação do usuário necessária**); `Icons.ac_unit` → ícone coerente; título do header alinhado à esquerda com drawer (confirmar no protótipo).
- **Cadastro**: manter step indicator; erros inline por campo.

### Onda 3 — Domínio de produtos (insumos, ofertas, comparar, ticket)

- **`AlertBanner`** único substituindo os 4 banners laranja duplicados + banner verde cru do compare_prices.
- **Tabular everywhere**: preço/un gold 16-18 em OfferCard/PanelProductCard/Ingredients; deltas tokenizados.
- **ingredients_screen**: eliminar redundância long-press (manter ícone de loja explícito, tooltip "Ver ofertas").
- **ingredient_offers**: reduzir pré-roll de filtros (toggle "só com economia" vai para a linha de chips). Tela é a melhor do app — mexer pouco.
- **compare_prices**: estender `AppFilterChipRow` (apagar `_buildSupplierChip`); eco-line 20-22 gold tabular com `colorSuccess`; labels de seção "Ordenar por"/"Fornecedor" separando as 2 linhas de chips.
- **product_detail**: veredito 36 tabular mantido; **ALL CAPS → sentence case** ("Dá lucro"/"Dá prejuízo"); dividers token.
- **products**: adicionar **margem % tabular** no card (decisão sem abrir detalhe).
- **product_form**: busca no picker de insumos; padding do campo quantidade; live preview com tokens.
- **audit_logs**: só migração para tokens.

### Onda 4 — Forms, settings, estados

- **`AppTextField`** compartilhado (decoração padrão + errorText + helper + numérico pt-BR) migrando login/cadastro/transaction/budget/ingredient/product/offer.
- **`AppToast.success/error/info`** com tema central; eliminar `Colors.red`/gold como fundo de snackbar (~20 usos).
- **`ErrorState` amigável** ("Não foi possível carregar.") + detalhe só em log; apagar `"Erro: ${bp.error}"` crus.
- **Skeletons** em ingredients/products/expenses.
- **Settings**: tiles desabilitados com badge "Em breve" no lugar de SnackBars; help ok.
- Apagar os 5 empty states inline duplicados.

## 5. Protótipos como próxima etapa (regra do fluxo)

Gerar primeiro, em `documentacao/logs/sprint4/`:

1. **`prototipo_redesign_home.html`** — prioridade 1 (valida tokens, escala, tabular, hero+apoio, skeleton, section headers, FAB, empty state). Dados realistas.
2. **`prototipo_redesign_login.html`** — prioridade 2 (tipografia de marca, erro inline, sociais harmonizados).
3. **`prototipo_redesign_produtos.html`** — prioridade 3 (insumos + ofertas + comparar num documento só).

**Critérios de aprovação (gate antes de codar):**
- Paleta idêntica (5 hex fixos) + derivados aprovados formalmente;
- Microcopy real do app (inclusive a policy "O app não troca sozinho");
- Escala tipográfica visível (hero>seção>item>caption);
- R$/% tabulares (colunas alinhadas);
- Contraste: `0xFF7A8B83` sobre `0xFF142A20` ≈4.3:1 (borderline AA) — se reprovar, aprovação explícita p/ clarear só o token secundário (ex. `0xFF8A9C94`);
- Alvos ≥48dp; estados vazio/carregando demonstrados; ≥3 níveis de card na home (hero/seção/item).

## 6. Checklist do implementador

1. Cor só via `lib/theme/app_colors.dart` — zero `Color(0xFF…)` e zero `Colors.green/red/orange/blue` crus em telas.
2. Espaçamento só no ritmo 4/8/12/16/20/24/32.
3. Radius só 8/12/16/pill.
4. Font sizes só 28/20/16/14/12/11; nada <11.
5. Todo valor monetário/percentual tabular.
6. Cards `elevation: 0` + borda `0xFF1E3A2C` (sem sombra preta neste fundo).
7. Ícones Material `*_outlined`; FontAwesome só p/ logos de marca; nunca misturar pesos.
8. Botão primário = verde, radius 12, vertical 16, elevation 0, peso 600; secundário = Outlined/Text gold.
9. Forms com `AppTextField` + validação inline; SnackBar só p/ feedback de ação.
10. Listas: skeleton + `EmptyState` com CTA + `ErrorState` sem exceção crua.
11. SnackBar com ícone e token semântico; nunca dourado como sucesso.
12. Copy sentence case; sem ALL CAPS; sem exclamação em status.
13. AppBar transparente; alinhamento à esquerda com drawer (a confirmar).

## 7. Fora do escopo

- Paleta fixa (5 cores), logo camaleão e assets de marca.
- Arquitetura Provider/Firebase, schema Firestore, regra "o app nunca troca sozinho", rotas.
- `erros-a-evitar.md`: sem segredos, sem tocar em `.env`/`google-services.json`.
- Nenhuma implementação em `lib/` nesta etapa — protótipo HTML primeiro (veto de 2026-10-07).
