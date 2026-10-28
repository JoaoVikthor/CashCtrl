# Redesign do Comparativo Automatizado — `ingredient_offers_screen`
**CashCtrl (Flutter, dark verde+dourado) · Direção de UI · Fonte: código real (`lib/screens/ingredient_offers_screen.dart`, 513 linhas)**

> Status: PLANO — não implementar sem protótipo HTML prévio (regra vigente em `context/decisoes-de-fluxo.md`).
> Este documento redefine a tela de comparativo para abrigar **níveis de automação** (alerta → sugestão → auto-troca opt-in) sem trair a confiança do usuário.

---

## 0. Identidade — nunca quebrar

- Paleta fixa: fundo `0xFF0D1E16`, verde `0xFF165A41`, dourado `0xFFB89775`, cards `0xFF142A20`, texto sec `0xFF7A8B83`. Sem cores novas; status reaproveita `Colors.green` / `Colors.red` / `Colors.orange` do Material (já usados em `product_detail` e banners).
- Logo camaleão intocável. Tokens/ritmo conforme `documentacao/logs/sprint2/plano_design_proposta_a.md` (seções 0–2): raio 12 (cards/campos/botões), 10 (linhas internas), 16 (veredito), 20 (top sheet); padding de lista `(20,16,20,90)`; card padding 16, margin-bottom 12; alvos ≥ 44.
- Moeda/datas sempre via `formatCurrencyAbs` / `formatDate` / `formatDateShort` (`lib/utils/format.dart`).
- Anti-template-IA: **nada de** lista de cards idênticos como única hierarquia, ícones mistos (manter o conjunto Material já em uso: `storefront_outlined`, `check_circle`, `star`, `history`, `schedule`, `autorenew`), espaçamento sem ritmo, tipografia sem pesos contrastados.
- Loading: `CircularProgressIndicator(color: colorGold)`. Sem swipe-to-delete em ofertas.

### 0.1 Princípio de produto: confiança > mágica
A automação entra em **níveis**, nunca como mágica silenciosa:

| Nível | O que faz | Transparência mínima |
|---|---|---|
| **L0 — Manual** (hoje) | usuário compara e troca | microcopy "O app não troca sozinho" |
| **L1 — Alerta** | avisa preço vencido / desatualizado | frescor visível em cada oferta + banner |
| **L2 — Sugestão** | card one-tap "trocar para X e economizar R$Y" | sugestão nunca auto-aplica; exige toque + confirmação com desfazer |
| **L3 — Auto (opt-in por insumo)** | troca sozinho sob política (Δ mínimo, cooldown) | chip "AUTO" dourado em toda troca, log de auditoria, desfazer fácil, política editável |

Regra de ouro: **default L0/L2; L3 só por opt-in explícito por insumo**, com o mesmo `ConfirmActionDialog` de hoje explicando as regras antes de ligar.

### 0.2 O que NÃO muda (todas as variantes)
- Rota `/ingredient-offers` (args `String ingredientId`) e `/offer-form` (map) — sem quebra de back-stack; push/pop idêntico.
- AppBar transparente com voltar; bottom CTA "Adicionar oferta" (verde, disabled @.5 no limite 15).
- `ConfirmActionDialog` para qualquer troca manual; SnackBar gold sucesso / red erro.
- `OfferComparator.rankAll` como fonte do ranking; inativas a opacidade .55.
- Sem swipe, sem animação de troca de layout, sem dependência nova.

---

## 1. Diagnóstico da tela atual (baseline)

| Dimensão | Hoje | Lacuna para automação |
|---|---|---|
| Hierarquia | Card resumo → banner tamanhos → frase de política → busca/filtros → contador → lista plana de `OfferCard` → CTA | Todos os cards têm o mesmo peso; decisão importante (trocar) disputa com edição/olho no rodapé de cada card |
| Frescor | **Inexistente** — `updatedAt` do offer nunca é exibido | Usuário não sabe se R$ é de hoje ou de 3 meses; automação sem frescor é arma apontada |
| Origem | `source` ('manual'/'migration') filtrada como chip "Padrão" mas invisível no card | Sem chip de origem não há como diferenciar troca manual × automática |
| Sugestão | `EconomySummaryCard` só no `product_detail`; aqui só delta inline | Comparativo por insumo não oferece "mover o dedo uma vez e economizar" |
| Política | Frase fixa "O app não troca sozinho" (linha 103) | Precisa evoluir para "você escolhe o nível" sem soar traição |
| Estados | vazio, erro, sem-filtro, 15/15 ok | Faltam: todos vencidos, sugestão pendente, auto ligado |

---

## 2. Variantes

### V0 — "Evolução incremental" (sem quebrar nada)
**Tese:** a tela de hoje fica, ganha frescor + chip de origem + faixa de sugestão condicional; menor risco, entrega L1+L2 imediatos.

#### Layout, seção a seção
- **A — Card resumo** (igual ao `_buildSummaryCard` atual): nome, "Preço por unidade de referência: R$/un", chips ATIVA/★. **+linha nova** sob os chips, quando houver automação configurada: chip outline dourado `AUTO` + "sugestões ativas" (ou "auto-troca ativa · Δ mín. 5% · intervalo 7 dias").
- **B — Banner tamanhos** (condicional, igual).
- **C — Faixa de sugestão** (NOVA, condicional, `green@.12` + `green@.35`, mesmo tratamento do `EconomySummaryCard`):
  - Título: `Sugestão: trocar para {fornecedor}` (green bold 14)
  - Valor: `−R$ X,XX por unidade` (green bold 24) + linha textSec 12: `Hoje: {ativo} · Economia estimada: R$ Y,YY por fornecimento` (se qtd do insumo conhecida).
  - Ações: botão texto gold `Usar no ticket` (abre o `ConfirmActionDialog` de hoje, já preenchido com o corpo da troca) + botão texto textSec `Dispensar` (some até próxima atualização de dados).
  - Microcopy fixa 12 textSec: `Sugestão gerada a partir dos preços cadastrados. Nada foi alterado.`
- **D — Filtros** (iguais: `AppSearchField`, `AppFilterChipRow [Todas, Ativas, Inativas, Padrão]`, toggle "só com economia").
- **E — Contador** `X de 15 ofertas` (igual).
- **F — Lista `OfferCard` enriquecida**: em `lib/widgets/offer_card.dart`, sob o nome do fornecedor, **linha de frescor** textSec 11: `coletado há 12 dias` · quando aplicável `· vence em 18`. No canto dos chips, ao lado de ATIVA/★, **chip de origem**: `AUTO` (borda gold 1.2, texto gold 10 bold, outline — espelha `BestPriceChip`) quando a ativação veio de automação; `MANUAL` omitido (ausência = manual; não poluir). Oferta vencida: delta continua, mas preço ganha selo laranja `vencido` + opacidade .55 mesmo sendo ativa (com aviso no card resumo).
- **G — Bottom CTA** (igual).

#### Estados
| Estado | Comportamento |
|---|---|
| Sem ofertas | igual hoje (`EmptyState` + card legacy se houver preço migrado) |
| Todos vencidos | banner `orange@.12` no topo (antes do card resumo): `Todos os preços deste insumo estão vencidos. Confira antes de usar no ticket.` + CTA texto gold `Revisar ofertas` (scroll até a lista) |
| Sugestão ativa | faixa C visível (só quando Δ vs. ativa < −0.005 **e** sugerida não vencida) |
| Auto ligado | chip `AUTO` dourado no card resumo + linha `Última troca automática: {data}`; toda troca L3 deixa `AuditEntryTile` |
| Limite 15/15 | banner `OfferLimitBanner` + CTA disabled (igual) |

#### Comunica
- Frescor: linha em cada card + banner global se tudo vencido (L1 completo).
- Sugestão: faixa C one-tap com confirmação + SnackBar gold com ação `Desfazer` (restaura `activeOfferId` anterior — snapshot em memória, sem backend novo).
- Política: em L0, frase de hoje permanece; em L2/L3, vira `Você escolhe qual oferta entra no ticket. O app só troca quando você permite.` Configuração da política vive em **bottom sheet** aberto pelo chip do card resumo (`Configurar automação`).

#### Acessibilidade
- Faixa C: botões ≥48 height; `Semantics(label: 'Sugestão: trocar para X, economia de Y reais por unidade')`.
- Frescor: `Semantics(label: 'preço coletado há 12 dias, vence em 18 dias')` (traduzir o texto visual, não ler "·").
- Chip AUTO: `Semantics(label: 'ativação automática')`.

#### Prós / contras
- ✅ Zero mudança de modelo mental; delta pequeno no `offer_card.dart` + bloco novo na tela; risco mínimo.
- ✅ Entrega L1+L2 rápido e testável.
- ❌ Hierarquia continua plana (risco anti-template: mais um card no meio de cards); sugestão compete com banner de tamanhos e contador; a experiência de automação nunca "vira produto".

---

### V1 — "Ranking + faixa de automação"
**Tese:** o ranking manual é rei e fica intacto; a automação vive numa faixa vertical própria acima, como "painel de controle" — o usuário lê de cima para baixo: estado → decisão → detalhe.

#### Layout, seção a seção
- **A — AppBar** (igual).
- **B — Card resumo compacto** (menor que hoje): nome insumo white bold 16 + preço ativo gold bold 20 + uma linha única de status: `Ativa: {supplier} · ★melhor` (chips existentes em wrap).
- **C — Faixa de automação** (NOVA, ocupa ~40% do primeiro scroll; cartão `colorCard` com **borda esquerda gold 3dp** — não é mais um card igual, é um painel):
  - Linha 1: ícone `autorenew` gold 18 + `Automação` white bold 15 + **segmented control compacto** `Desligada | Sugerir | Automática` (selected = greenPrimary bg; alvo 44 por segmento; Semantics de rádio).
  - Linha 2 (estado atual, textSec 12):
    - Desligada: `O app não troca sozinho. Você compara e escolhe.`
    - Sugerir: `Quando acharmos economia, mostramos um card. Nada muda sem você tocar.`
    - Automática: `Troca quando a economia ≥ {5}% e passaram {7} dias da última troca.`
  - Linha 3 (regras, só visível em Automática; chips editáveis via bottom sheet): `Δ mín. 5%` · `intervalo 7 dias` · link gold texto `Editar regras`.
  - Linha 4 (sugestão pendente, condicional — substitui a faixa C da V0): mesmo conteúdo green@.12 da V0, com botões `Usar no ticket` / `Dispensar`.
- **D — Filtros sticky** (busca + chips + toggle economia — iguais).
- **E — Contador + seção** `Ofertas (12)` via `SectionHeader(icon: storefront_outlined, title: 'Ofertas', trailing: contador)`.
- **F — Lista `OfferCard`** com frescor + chip AUTO (como V0-F) — **o card da sugerida ganha borda green@.3** para achar rápido sem depender da faixa.
- **G — Histórico** (NOVO, colapsado no fim): `SectionHeader(icon: schedule, title: 'Últimas trocas', trailing: textVer)`. Quando auto/sugerir ativo, mostra até 3 `AuditEntryTile` (`Oferta trocada de A para B` / `fonte: automática`). Link `Ver auditoria completa` → `/audit-logs` (rota já existe).
- **H — Bottom CTA** (igual).

#### Estados
Iguais à V0, com adições: segmento `Automática` selecionado sem regras salvas → linha 3 mostra `Defina as regras para ativar` + CTA gold `Configurar`; troca automática recente → chip AUTO na oferta ativa + primeira entrada do histórico com `há 2 dias`.

#### Comunica
- Frescor: card + banner (V0).
- Sugestão: linha C4 (one-tap com confirmação + desfazer).
- Política: **segmented control na própria tela** (não escondida em settings) — transparência é o produto; bottom sheet `Configurar automação` com steppers/sliders (Δ mín. 3–20%, intervalo 1/3/7/14/30 dias) e nota fixa `A auto-troca é por insumo. Outros insumos não são afetados.`

#### Acessibilidade
- Segmentos 44+; Semantics de grupo `Nível de automação do insumo X`. Faixa com borda gold usa contraste gold-on-card (já aprovado em BestPriceChip). Link `Editar regras` com hitSlop 8.

#### Prós / contras
- ✅ Hierarquia forte (painel ≠ cards) e escaneável; política honesta e visível; escala bem para L1–L3.
- ✅ Reaproveita quase 100% dos widgets; diff concentrado em 1 faixa + 1 sheet.
- ❌ Primeiro scroll mais "operacional" que "comparativo"; usuário que só quer comparar precisa rolar até a lista (mitigável: faixa colapsável com chevron quando em Desligada).

---

### V2 — "Mercado" (frescor como eixo de organização)
**Tese:** a tela vira um mercado honesto — o que está fresco e barato sobe, o que vencido desce com selo; o usuário decide lendo "quando cada preço vale".

#### Layout, seção a seção
- **A — Card resumo** (V1-B) **+ barra de saúde**: `3 de 5 ofertas atualizadas` com mini-barra (green@.2 preenchida conforme razão) — "health" do insumo em 1 olhar.
- **B — Seção `Melhor agora`** (NOVA): card "hero" (`green@.12` + `green@.35`, radius 16 — único card radius 16 da tela, quebra a monotonia): fornecedor white bold 16, R$/un gold bold 28, `Δ −R$ X,XX vs. ativa`, frescor `coletado há 3 dias · vence em 25`, chips ★melhor + ATIVA se couber, ações `Usar no ticket` (verde) / `Ver detalhes` (scroll até o card na lista). Se a ativa já é a melhor: `Você já usa o melhor preço` + check_circle green.
- **C — Filtros** (iguais; chip extra `Vencidas` opcional na AppFilterChipRow → `[Todas, Ativas, Inativas, Padrão, Vencidas]`).
- **D — Subseção `Em dia`** (`SectionHeader(icon: check_circle_outline, title: 'Em dia')`): `OfferCard` com frescor; ordenação: Δ vs ativa, depois R$/un.
- **E — Subseção `Vencidas ou antigas`** (`SectionHeader(icon: schedule, title: 'Vencidas ou antigas', trailing: count)`): mesmo `OfferCard`, mas com selo laranja `vencido` no lugar do delta quando vencida, e micro-linha `Confira o preço com o fornecedor.`; opacidade .55 só aqui.
- **F — Faixa de automação** (mesma da V1-C, mas enxuta — 2 linhas: nível + resumo das regras; expande ao toque).
- **G — Histórico** (V1-G).
- **H — Bottom CTA** (igual).

#### Estados
Sem ofertas (EmptyState); **todos vencidos**: seção D vazia com EmptyState inline `Nenhuma oferta em dia` + seção E populada + banner laranja no topo; sugestão ativa = card hero mostra a sugerida (não a atual) com botão `Usar no ticket`; auto ligado = chip AUTO + hero ganha linha textSec `troca automática em vigor`; 15/15 igual.

#### Comunica
- Frescor é **estrutura**, não detalhe: determina em qual subseção o card cai; barra de saúde no topo.
- Sugestão: card hero dual-mode (atual vs sugerida) — a "sugestão" não é um card extra competindo, é o próprio hero mostrando o futuro.
- Política: faixa F enxuta (mesmo sheet da V1).

#### Acessibilidade
- Subseções dão landmarks de ScreenReader (`Semantics(header: true)`). Barra de saúde com label `3 de 5 ofertas com preço atualizado`.

#### Prós / contras
- ✅ Frescor vira o coração do comparativo — prepara perfeitamente L3 (auto precisa de dados frescos).
- ✅ Quebra o anti-template com hero + subseções (não é lista plana).
- ❌ Reorganização grande: mudanças no `offer_card.dart` (modo "compact/vencida") + lógica de agrupamento; filtros clássicos (Ativas/Inativas) colidem com agrupamento por fresco/vencido — risco de UX confusa se os dois eixos brigar.
- ❌ Usuário que quer "só o ranking de preço" (o uso atual) perde a listagem única.

---

### V3 — "Assistente" (decisão guiada)
**Tese:** a tela responde 1 pergunta — "troco ou não troco?" — com 1 recomendação grande, lista colapsada e política num toggle com regras; mais productizado, mais longe da tela atual.

#### Layout, seção a seção
- **A — Card decisão** (NOVO, ocupa meia tela; radius 16; variantes por estado — é o único "hero" da tela):
  - **Estado trocar**: ícone `trending_down` green + `Trocar para {supplier}` green bold 18; `−R$ X,XX por unidade` green bold 32; linhas: `Hoje no ticket: {ativo} · R$/un`, `Frescor do sugerido: coletado há 2 dias`, `Economia por fornecimento: R$ Y,YY`; botão verde full `Trocar agora` (→ ConfirmActionDialog + desfazer) + texto gold `Manter {ativo}`.
  - **Estado estável**: check_circle green + `Preço ativo já é o melhor` + `Última verificação: hoje` + textSec `Você pode revisar as ofertas quando quiser.`
  - **Estado vencido**: warning_amber orange + `Preço ativo venceu` + `Confira com {supplier} antes de fechar o ticket` + botão outline gold `Ver ofertas`.
- **B — Toggle automação** (NOVA linha sob o card): `Switch` (trilha greenPrimary quando on) + label `Automática neste insumo` + sub-linha textSec com regras correntes ou `sugestões apenas`; toque abre o mesmo bottom sheet da V1 com steppers e `Ativar automática` exige ConfirmActionDialog listando regras.
- **C — Seção colapsável** `Outras ofertas (12)` — `ExpansionTile` customizado (card bg, header: contador + mini resumo `melhor: R$ X · ativa: R$ Y`); aberto mostra `AppSearchField` + `AppFilterChipRow` + `OfferCard` (com frescor/AUTO).
- **D — Histórico** (V1-G, sempre visível se L3 on).
- **E — Bottom CTA** (igual).

#### Estados
Sem ofertas → card A vira EmptyState embutido + CTA; todos vencidos → estado vencido do card A; sugestão = estado trocar; auto ligado → chip `AUTO` dourado no canto do card A + `Última troca: {data}` + desfazer rápido (`Desfazer última troca` enquanto <24h); 15/15 → contador no header de C + CTA disabled.

#### Comunica
Frescor dentro do card decisão (sempre); sugestão **é** o card A (sem competidor); política no toggle B (1 grau de liberdade na tela, regras no sheet).

#### Prós / contras
- ✅ Melhor conversão para L2/L3; zero ambiguidade sobre "o que fazer agora".
- ❌ **Esconde informação**: para insumo com 8 fornecedores e nuances (tamanho de embalagem, vencidas), a lista colapsada atrasa a comparação; quebra o hábito atual (ranking é o produto).
- ❌ Maior divergência do código atual; mais estados de card A a testar; risco de "app de recomendação" demais para um app de **controle** (CashCtrl).

---

## 3. Recomendação

**Implementar V1 como alvo de design; V0 como caminho de rollout incremental dentro da V1.**

Justificativa (confiança > mágica):
1. **Preserva o comparativo como herói.** O usuário do CashCtrl veio para *comparar*; V3 esconde a lista, V2 troca o eixo de leitura. V1 mantém ranking intacto e coloca automação como **camada**, não como substituta.
2. **Política visível sem ser impositiva.** O segmented control da V1-C torna o nível de automação um estado declarado da tela — não um switch escondido em settings — e evolui a microcopy de hoje ("não troca sozinho") sem contradizê-la ("só troca quando você permite").
3. **Risco de implementação menor.** V0 (frescor + chip AUTO + faixa de sugestão + desfazer) já entrega L1+L2 com diff pequeno em `offer_card.dart` e um bloco novo na tela; V1 soma o painel de política + histórico reaproveitando `AuditEntryTile` e `/audit-logs` que já existem.
4. **Escalona para L3 sem redesenho.** Auto-troca liga como mais um estado do segmented control; desfazer (snapshot de `activeOfferId` + SnackBar com ação) e auditoria já são desenhados.

Evolução sugerida: **fase 1** = V0 (frescor + chip AUTO + faixa de sugestão + desfazer) → **fase 2** = V1 completo (faixa de política + histórico). Protótipo HTML obrigatório antes do Flutter (regra de fluxo).

---

## 4. Widgets — novos vs reutilizados

### Reutilizados (sem mudança ou micro-mudança)
| Widget | Uso |
|---|---|
| `offer_card.dart` | base de todas; **micro-mudança**: slot opcional para linha de frescor + chip `AUTO` + modo "vencida" |
| `best_price_chip.dart` | ★melhor (inalterado) |
| `active_offer_marker.dart` | ATIVA/INATIVA (inalterado) |
| `delta_price_text.dart` | deltas (inalterado; Semantics já ok) |
| `filter_chip_row.dart` / `search_field.dart` | filtros (inalterados) |
| `section_header.dart` | seções "Ofertas"/"Últimas trocas" |
| `offer_limit_banner.dart`, `empty_state.dart`, `error_state.dart` | estados (inalterados) |
| `confirm_action_dialog.dart` | toda troca manual, ativação de auto, confirmação L3 |
| `audit_entry_tile.dart` | histórico de trocas |
| `economy_summary_card.dart` | **referência de tratamento** green@.12/red@.12 para faixa de sugestão e card hero |

### Novos (arquivos em `lib/widgets/`)
| Widget | Contrato visual |
|---|---|
| `price_freshness_line.dart` | `PriceFreshnessLine({required DateTime collectedAt, DateTime? validUntil, bool compact})` — textSec 11: `coletado há {N} dias`; ≥15 dias → orange `confira o preço`; vencido → red `vencido há {N} dias`. `Semantics` traduzido |
| `automation_badge.dart` | `AutomationBadge({String label = 'AUTO'})` — outline gold 1.2, texto gold 10 bold, fundo transparente (espelho do `BestPriceChip`) |
| `suggestion_banner.dart` | `SuggestionBanner({required String supplier, required double deltaPerUnit, double? estimatedSaving, required VoidCallback onApply, required VoidCallback onDismiss})` — green@.12 + green@.35, radius 12 |
| `automation_panel.dart` | `AutomationPanel({required int level, required ValueChanged<int> onLevelChanged, String? rulesSummary, VoidCallback? onEditRules})` — painel card com borda esquerda gold 3 + segmented [Desligada, Sugerir, Automática] + resumo de regras |
| `automation_rules_sheet.dart` | bottom sheet (top radius 20, bg card): Δ mín. (stepper 3–20%), intervalo (chips 1/3/7/14/30 dias), nota `A auto-troca é por insumo…`, CTA verde `Salvar regras` |

---

## 5. Contratos de dado novos (contrato visual; backend fora do escopo)

Sem estes dados, frescor e automação são teatro. Campos mínimos para o UI:

1. **`IngredientOffer.collectedAt: DateTime`** (obrigatório novo; fallback: `updatedAt`) — base do frescor.
2. **`IngredientOffer.validUntil: DateTime?`** (opcional) — quando ausente, o UI calcula faixa etária por dias desde `collectedAt` (sugestão: ≤7 ok, 8–14 "confira", ≥15 ou `now > validUntil` → vencido).
3. **`IngredientOffer.activationSource: 'manual' | 'auto'`** — origem da última ativação; alimenta chip `AUTO` (diferente do `source` atual, que é 'manual'/'migration' de criação).
4. **`Ingredient.automation: { mode: 'off' | 'suggest' | 'auto', minDeltaPercent: double (ex 5), cooldownDays: int (ex 7), lastAutoAt: DateTime? }`** (opcional; `mode == 'off'` = L0/L2 puro).
5. **`activeOfferId` anterior** para desfazer L2/L3 (snapshot local na tela + log).
6. **Sugestão** = derivada de `OfferComparator.rankAll`: melhor oferta **ativa e não vencida** com `deltaVsActive < −0.005`; se `ingredient.offers` tiver quantidade de fornecimento para estimar economia, exibir; senão omitir linha de economia (nunca inventar número).

---

## 6. Checklist visual do CashCtrl (implementador)

- [ ] Scaffold bg `0xFF0D1E16`; cards `0xFF142A20` radius 12 (hero/sugestão: radius 16; sheets: top 20).
- [ ] Moeda/data sempre via `lib/utils/format.dart`; R$/un com `formatCurrencyAbs`.
- [ ] Ranking por R$/un (nunca só embalagem); banner tamanhos mantido.
- [ ] Frescor em toda oferta (linha compacta) + estado "todos vencidos" com banner orange@.12.
- [ ] Chip `AUTO` = outline gold; nunca preencher com cor nova; ausência = manual.
- [ ] Sugestão nunca aplica sozinha: toque → `ConfirmActionDialog` → SnackBar gold com ação `Desfazer`.
- [ ] Nível de automação visível na tela (não escondido em settings); default `Desligada`.
- [ ] Política L3 exige confirmação listando regras; é **por insumo**.
- [ ] Toda troca automática gera `AuditEntryTile` (histórico até 3 + link `/audit-logs`).
- [ ] Alvos ≥44 (segmentos, botões do hero, links com hitSlop); Semantics em frescor, sugestão, chips AUTO, switch.
- [ ] Contraste só com paleta existente: green/red/orange para status, gold para valores/accent, textSec só para apoio.
- [ ] Estados: loading spinner gold, `ErrorState`, `EmptyState`, sem-filtro, 15/15 disabled.
- [ ] Microcopy sentence case, sem "!", voz ativa, PT-BR.
- [ ] Zero dependências novas; `dart analyze .` limpo (usar `dart analyze`, não `flutter analyze`, pelo caminho "(Cópia)").

---

## 7. Fora do escopo

- Qualquer mudança de paleta, logo, gradiente ou identidade.
- Backend/Firestore, Cloud Functions, multi-moeda, notificações push.
- Auto-troca global (só por insumo, opt-in).
- Remoção de campos legados (`purchasePrice`, `packageQuantity`) do `Ingredient`.
- Alterações em `ProductCalculator`, rotas existentes ou back-stack.
- Swipe-to-delete em ofertas; paginação do histórico (futuro: cursor + "Carregar mais").
- Notificação de vencimento fora desta tela (futuro: banner no dashboard/insumos reutilizando `PriceFreshnessLine`).
