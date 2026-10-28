# Plano de Design — Proposta A: Comparação de Fornecedores
**CashCtrl (Flutter, dark verde+dourado) · MVP · Fonte única de verdade para os streams UI**

---

## 0. Regras permanentes

- Paleta fixa: fundo `0xFF0D1E16`, verde `0xFF165A41`, dourado `0xFFB89775`, cards `0xFF142A20`, texto sec `0xFF7A8B83`. Logo camaleão intocável.
- Status reusa as cores JÁ usadas no app: economia/lucro `Colors.green`, prejuízo/erro `Colors.red`, aviso `Colors.orange`. Nenhuma cor nova.
- Moeda/datas SEMPRE via `formatCurrencyAbs` / `formatCurrency` / `formatDate` / `formatDateShort` (`lib/utils/format.dart`).
- Política de produto (aparecer em 1 lugar por tela relevante): **o preço do ticket = oferta ATIVA escolhida manualmente; o app NUNCA troca sozinho**. Teto de 15 ofertas sempre comunicado.
- Raio padrão: 12 (cards/campos/botões), 10 (linhas internas), 16 (veredito), 20 (top bottom sheet). Padding lista `(20,16,20,90)`; card padding 16, margin-bottom 12; alvos de toque ≥ 44.
- Loading: `CircularProgressIndicator(color: colorGold)`. Formulários: AppBar transparente com fechar/voltar. Listas: `AppBrandedHeader`. Sem swipe-to-delete em ofertas (risco); ações explícitas.

## 1. Design token map

| Token | Valor | Uso |
|---|---|---|
| colorBackground | 0xFF0D1E16 | Scaffold de todas as telas |
| colorGreenPrimary | 0xFF165A41 | Botões primários, FAB, chip ativo, preview (alpha .12), SnackBar sucesso |
| colorGold | 0xFFB89775 | Valores monetários, ícones de seção, borda "★ melhor", SnackBar info, spinner |
| colorCard | 0xFF142A20 | Cards, campos, dialogs, sheets |
| colorTextSec | 0xFF7A8B83 | Labels, legendas, timestamps |
| Colors.green/red/orange | Material | economia / prejuízo-erros / avisos (já usados em product_detail) |
| Derivados aceitos | `withValues(alpha: .12/.15/.2/.3/.35/.4/.5)` | estados de card como nas telas atuais |

## 2. Widgets (`lib/widgets/`) — contrato de nomes

| Widget | Assinatura |
|---|---|
| `offer_count_badge.dart` | `OfferCountBadge({required int count})` — pill "N ofertas" (fundo green@.2, texto gold 11 bold); `count == 0` → "sem ofertas" textSec |
| `best_price_chip.dart` | `BestPriceChip({String label = 'melhor'})` — ★ gold, borda gold 1.2, fundo card |
| `active_offer_marker.dart` | `ActiveOfferMarker({bool active = true})` — "ATIVA" pill fundo greenPrimary / "INATIVA" outline white24 |
| `delta_price_text.dart` | `DeltaPriceText({required double delta, double fontSize = 12})` — negativo `−R$ x` verde, positivo `+R$ x` vermelho, zero `—` textSec |
| `section_header.dart` | `SectionHeader({required IconData icon, required String title, Widget? trailing})` — ícone gold 18 + título white bold 16 |
| `search_field.dart` | `AppSearchField({required String hint, required ValueChanged<String> onChanged})` — card fill, ícone gold, radius 12 |
| `filter_chip_row.dart` | `AppFilterChipRow({required List<String> options, required int selectedIndex, required ValueChanged<int> onSelected})` — selecionado greenPrimary bg + white; não = card + textSec; altura 40 |
| `empty_state.dart` | `EmptyState({required IconData icon, required String title, required String message, String? actionLabel, VoidCallback? onAction})` — ícone 56 textSec + CTA verde |
| `error_state.dart` | `ErrorState({required String message, VoidCallback? onRetry})` |
| `offer_limit_banner.dart` | `OfferLimitBanner({required int current})` — laranja: "Restam X ofertas" / "Limite de 15 ofertas atingido" |
| `confirm_action_dialog.dart` | `ConfirmActionDialog.show(context, {required String title, required String body, String? note}) → Future<bool>` — Cancelar (gold) / Confirmar (verde) |
| `offer_card.dart` | `OfferCard({required RankedOffer ranked, required int totalOffers, required VoidCallback onSet, required VoidCallback onEdit, required VoidCallback onToggle})` — card ~88–96, fornecedor + embalagem + R$/un gold bold + delta + pills ATIVA/★ + ações; inativas com opacidade .55; sem swipe |
| `audit_entry_tile.dart` | `AuditEntryTile({required PriceAuditLog log})` — ícone gold por tipo (destrutivas red) + summary white 14 + detail textSec 12 + hora data textSec 11; tap → bottom sheet detalhes |
| `economy_summary_card.dart` | `EconomySummaryCard({required TicketScenario? scenario, required TicketResult ticket, required void Function(String ingredientId) onViewOffers})` — string vazio = "Gerenciar insumos" (`/ingredients`) |

## 3. Telas

### 3.1 `ingredients_screen` (modificada)
- Card atual preservado. NOVO sob o nome: `OfferCountBadge(count: ing.offersCount)`.
- Coluna direita, sob o valor R$/un (que agora representa a oferta ativa via getter): quando `offers.length >= 2`, empilhar micro-markers `ActiveOfferMarker` e `BestPriceChip` (se a ativa NÃO for a melhor; se for a melhor, só ATIVA).
- Novo ícone trailing `Icons.storefront_outlined` (gold 22) → `Navigator.pushNamed('/ingredient-offers', arguments: ing.id)`; `onLongPress` idem.
- Dismiss/FAB/estados inalterados.

### 3.2 `ingredient_form_screen` (modificada)
- Campos base e preview inalterados (preço legado = fallback quando não há oferta ativa).
- NOVA seção "Fornecedor padrão" (`SectionHeader(icon: Icons.storefront_outlined, ...)`) após `_buildPreview`:
  - com oferta ativa: "Ativa agora" + fornecedor white bold + pill ATIVA + `R$ x · qtd un · R$/un gold` + links "Editar oferta" / "Ver todas (N)";
  - com ofertas sem ativa: aviso laranja "Nenhuma oferta ativa. O ticket usa o preço base deste insumo.";
  - 0 ofertas: empty inline storefront 28 textSec + botão outline verde "Adicionar primeira oferta" → `/offer-form` (edição de insumo já persistido; no create puro, navegar só após salvar).
- NOVA seção "Ofertas": header + contador "X/15" textSec + até 3 cards compactos + "Ver todas as N ofertas →" + CTA outline "Gerenciar ofertas".
- Salvar o insumo NUNCA cria oferta. Microcopy 1x: "Você escolhe qual oferta entra no ticket. O app não troca sozinho."
- Com oferta ativa, sub-linha no preview: "Com oferta ativa, o ticket usa R$ x,xx/un (fornecedor Y)."

### 3.3 `ingredient_offers_screen` (NOVA) — `IngredientOffersScreen({required String ingredientId})`
```
AppBar transparente: [← ] "Ofertas de {insumo}" (center bold white)
A. Card resumo: nome insumo (white bold 18), "Preço por unidade de referência: R$/un ATIVO" textSec 12,
   Row chips [ATIVA: Fornecedor Z] · [★ melhor: Fornecedor M] (se mesma: "★ também é a melhor")
B. Banner orange condicional: hasDifferentPackageSizes → "Atenção: embalagens de tamanhos diferentes. Compare o preço por unidade."
C. Filtros sticky: AppSearchField("Buscar fornecedor…") + AppFilterChipRow [Todas, Ativas, Inativas, Padrão] + toggle gold-border "★ só com economia"
D. Contador "12 de 15 ofertas" (orange "Limite de 15 atingido")
E. Lista ranking via OfferComparator.rank(ing.offers, activeOfferId: ing.activeOfferId) — R$/un asc, inativas com opacidade; item = OfferCard
F. Bottom CTA SafeArea full-width verde "Adicionar oferta" (desabilitada @.5 com 15/15)
```
- Delta vs ativa: `OfferComparator.rank` já entrega; sem ativa → "sem referência" textSec 10.
- Ação "Usar no ticket" → `ConfirmActionDialog.show` (título "Usar esta oferta no ticket?", body "Fornecedor M · R$ x/un" + economia ou "ficará R$ x mais caro", note "Você pode trocar de volta quando quiser. O app não altera automaticamente.") → `provider.setActiveOffer(ingredientId, offerId)` → SnackBar gold "Oferta de {supplier} agora é a ativa."; erro → SnackBar red "Não foi possível trocar a oferta."
- Com 0 ofertas persistidas mas preço legado existente: exibir `OfferComparator.syntheticLegacyOffer(ing)` como card de referência não-acionável ("Preço base do insumo — cadastre ofertas para comparar").
- Estados: loading spinner gold; erro `ErrorState`; vazio `EmptyState(storefront, 'Nenhuma oferta cadastrada', 'Cadastre fornecedores para comparar preços e escolher quem entra no ticket.', 'Adicionar oferta')`; filtro sem resultado: "Nenhuma oferta corresponde aos filtros." + "Limpar filtros".
- Sem auto-troca, sem animação de troca; flash verde @.2→transparente 400ms opcional após ativar (AnimatedContainer).

### 3.4 `offer_form_screen` (NOVA) — `OfferFormScreen({required String ingredientId, IngredientOffer? offer})`
```
A. AppBar transparente [←/X] "Nova oferta"/"Editar oferta"
B. Legenda grey 13: "Informe o que você paga e quanto vem na embalagem. O app calcula o preço por unidade."
C. AppSearchField-style _field "Nome do fornecedor" (Icons.storefront_outlined gold prefix; helper "Ex.: Distribuiora Central, Atacado do Zé")
D. Row flex 2+1 gap 12: "Preço da embalagem (R$)" | "Qtd. da embalagem"; chip read-only gold "unidade: {unit.label}"
E. PREVIEW AO VIVO (padrão ingredient_form: green@.12, borda green@.3, radius 12): lightbulb gold + "Preço por unidade" + "R$ 12,90 / kg" white bold 22; qty 0 → "Informe a quantidade"
F. "Notas (opcional)" multiline 2–4, contador n/200 quando >160
G. Edição: card "Comparado com a oferta ativa" com DeltaPriceText
H. Bottom "Salvar oferta"/"Salvar alterações" verde full-width (disabled @.5, spinner branco)
```
- Validação dura: fornecedor trim ≠ vazio; `packagePrice > 0`; `packageQuantity > 0`; criação com 15 ofertas → não salvar + banner/toast laranja "Limite de 15 ofertas por insumo." Erro: SnackBar vermelha + errorText no campo. Parsing aceita vírgula (`replaceAll(',', '.')`).
- Salvar → `provider.upsertOffer(ingredientId, offer)` (id `''` no create); sucesso → pop + SnackBar; oferta ativa editada manter ativação (service cuida).

### 3.5 `product_detail_screen` (modificada)
- Inserir `EconomySummaryCard` imediatamente após `_buildVerdictCard` (antes do aviso de insumos removidos / "Receita por ingrediente"). Cálculo: `OfferComparator.bestSupplierScenario(ticket)` — **paralelo, não altera TicketResult**.
- Caso A economia > 0: fundo green@.12 borda green@.35, ícone trending_down green, "Melhor fornecedor possível" green bold 14, "−R$ X,XX no custo dos ingredientes" green bold 28, texto "…Nada foi alterado no ticket." + CTA outline "Ver ofertas de {insumo maior delta}" → `/ingredient-offers`.
- Caso B scenario == null e existem ofertas: card branco "Fornecedores já estáveis" check_circle green + "As ofertas ativas deste produto já são as melhores entre as cadastradas." (1 oferta: acrescentar "poucas ofertas cadastradas — cadastre mais para comparar.")
- Caso C `scenario.stillLoss`: fundo red@.12, warning_amber, "Ainda dá prejuízo com o melhor preço" red bold, "−R$ X,XX ainda de prejuízo" red bold 24, texto honesto sugerindo ajustar preço/custos, CTA "Ver ofertas".
- Caso D nenhum insumo com ofertas: card "Sem dados de fornecedores" + CTA "Gerenciar insumos" (`/ingredients`).
- Omitir linhas `missing`; nunca verde para prejuízo ou vermelho para economia.

### 3.6 `audit_logs_screen` (NOVA) — `AuditLogsScreen()`
```
A. AppBar transparente [←] "Auditoria" (sub-tela, sem drawer novo no MVP)
B. Subcabeçalho: "Registro de ações" white bold 16 + "Tudo que altera custos, ofertas e produtos aparece aqui." textSec 12
C. Sticky: AppSearchField("Buscar por ação, produto ou fornecedor…") + AppFilterChipRow [Tudo, Insumos, Ofertas, Produtos, Sistema]
D. Timeline ListView agrupada por dia: "Hoje"/"Ontem"/formatDate; AuditEntryTile (ícone gold por ação, summary white, detail textSec, hora textSec 11, divider white24)
E. Tap tile → showModalBottomSheet (card, radius top 20): summary, timestamp completo, detalhe anterior→novo
```
- Stream: `IngredientProvider.auditLogs` (limit 100, orderBy timestamp desc). Sem paginação no MVP (plano futuro: cursor + "Carregar mais", export CSV, filtros por período).
- Vazio: EmptyState(receipt_long, 'Nenhuma ação registrada', 'Alterações em insumos, ofertas e produtos aparecerão aqui.')
- Nunca mostrar uid/IDs brutos.

## 4. Rotas (main.dart)
- `/ingredient-offers` → `IngredientOffersScreen(ingredientId: arguments as String)`
- `/offer-form` → `OfferFormScreen(ingredientId: map['ingredientId'] as String, offer: map['offer'] as IngredientOffer?)` (arguments = `Map<String, dynamic>`)
- `/audit-logs` → `AuditLogsScreen()`
Convenção kebab-case; padrões `ModalRoute.settings.arguments`.

## 5. Microcopy PT-BR fixo
"usar no ticket" · "oferta ativa" · "preço por unidade" · "limite de 15 ofertas" · "o app não troca sozinho" · "Nada foi alterado no ticket." · "Fornecedor padrão" · "Preço cadastrado migrado automaticamente".

## 6. Checklist do implementer
- [ ] Scaffold bg `0xFF0D1E16` em todas; cards `0xFF142A20` radius 12
- [ ] Moeda/data sempre via `lib/utils/format.dart`
- [ ] Ranking exibe R$/un (nunca só preço de embalagem)
- [ ] Política manual visível; confirmação explícita antes de ativar; SnackBar gold sucesso / red erro
- [ ] Teto 15 comunicado (contador + banner + CTA disabled)
- [ ] Empty/error states extraídos; targets ≥ 44; Tooltip em ícones; Semantics nos deltas
- [ ] Zero comentários novos no código, zero print, zero dependência nova
- [ ] `dart analyze .` limpo (obs.: `flutter analyze` crasha com o caminho "(Cópia)" — usar `dart analyze .`)

## 7. Fora do escopo
Auto-trocar oferta; histórico de preços; paginação auditoria; novo item no drawer; mudanças de paleta/logo/gradientes; remover campos legados do Ingredient; alterar ProductCalculator; Cloud Functions/multi-moeda.
