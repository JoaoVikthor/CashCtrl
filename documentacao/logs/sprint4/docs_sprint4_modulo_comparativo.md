# Documentação Técnica do Módulo Comparativo de Fornecedores do CashCtrl — Sprint 4

**Relatório técnico no padrão BIBLIOTECA (RT 279, ICMC).**
Fonte de verdade: código real da branch `nova-versao-app` (HEAD `e3c6302`), verificado em 09/10/2026.

---

## Capa

Documentação Técnica do Módulo Comparativo de Fornecedores do CashCtrl — Sprint 4

Comparação de ofertas por insumo, painel "Comparar preços", troca manual da oferta
ativa com confirmação/desfazer, exclusão com confirmação e logs de auditoria de preços

Equipe CashCtrl

autoria: github.com/JoaoVikthor

RELATÓRIOS TÉCNICOS DO CASHCTRL

São Carlos

09/10/2026

---

## Indice

1. Introdução
2. Arquitetura do Módulo
    2.1 Modelo de dados — ofertas embutidas no insumo (`offers[]`)
    2.2 Subcoleção `price_audit_logs` (append-only)
    2.3 Camadas e separação de interesses (SoC)
    2.4 Diagrama do modelo de dados
3. Fluxos do Módulo
    3.1 Cadastro e edição de oferta (upsert por fornecedor)
    3.2 Troca da oferta ativa — confirmação, desfazer e auditoria
    3.3 Exclusão de oferta — confirmação com alerta de oferta ativa
    3.4 Comparação por produto e por fornecedor (painel "Comparar preços")
    3.5 Histórico de auditoria com retry funcional
4. Segurança
    4.1 Regras do Firestore (isolamento por UID)
    4.2 Append-only dos logs de auditoria
    4.3 Batch atômico (mutação + log)
5. Testes
6. Decisões de Produto
7. Limitações Conhecidas e Próximos Passos
8. Considerações Finais
Referências

---

## 1. Introdução

Este relatório apresenta a documentação técnica do **módulo comparativo de
fornecedores** do CashCtrl, aplicativo móvel desenvolvido em Flutter com backend
Firebase, consolidado na **Sprint 4** (branch `nova-versao-app`, commit
`e3c6302`). O módulo reúne, em um único conjunto coeso: o modelo de ofertas por
insumo (`offers[]` embutido no documento do insumo), a lógica pura de comparação
e agregação, o painel "Comparar preços" (visões por produto e por fornecedor), a
troca manual da oferta ativa com confirmação e desfazer, a exclusão de oferta
com diálogo de confirmação e os logs de auditoria de preços append-only.

O objetivo desta documentação é propiciar uma visão abrangente dos recursos
implementados e incentivar que a ferramenta seja rapidamente compreendida por
desenvolvedores interessados em evoluir suas características. Todo o conteúdo
reflete o código efetivamente entregue (`lib/`, `firestore.rules`, `test/`) na
data de outubro de 2026: nomes de arquivos, classes, assinaturas, mensagens de
erro e microcopy foram extraídos diretamente do repositório. Em relação ao
relatório da Sprint 3 (que documentava o painel como implementação futura), esta
versão registra os diferenciais implementados depois: **exclusão de oferta com
confirmação e log de auditoria**, **falha explícita e amigável ao trocar para
oferta inexistente**, **parsing defensivo de documentos malformados**, **retry
funcional na tela de auditoria** e o **corte do login social** (decisão de
escopo, seção 6.4).

## 2. Arquitetura do Módulo

### 2.1 Modelo de dados — ofertas embutidas no insumo (`offers[]`)

A decisão de modelar as ofertas como **array embutido no documento do insumo**
(evitando subcoleção e leitura adicional) foi mantida da Sprint 2 e consolidada.
Cada insumo (`users/{uid}/ingredients/{ingredientId}`) carrega até **15 ofertas**
(`offers[]`) e o identificador da oferta ativa (`activeOfferId`). O modelo
`IngredientOffer` (`lib/models/ingredient_offer.dart`) possui os campos da
Tabela 1.

Tabela 1. Campos do modelo `IngredientOffer` (lib/models/ingredient_offer.dart).

| Campo | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `id` | String | `''` | Identificador da oferta (gerado no serviço quando vazio) |
| `supplier` | String | `''` | Nome do fornecedor (normalizado `trim().toLowerCase()` para upsert) |
| `packagePrice` | double | `0` | Preço pago na embalagem (deve ser > 0 — RN01) |
| `packageQuantity` | double | `0` | Quantidade da embalagem (deve ser > 0 — RN01) |
| `isActive` | bool | `false` | Flag exclusiva: apenas uma oferta ativa por insumo |
| `source` | String | `'manual'` | Origem (`'manual'` ou `'migration'` na oferta sintética legado) |
| `notes` | String | `''` | Notas opcionais (limite visual de 200 caracteres no formulário) |
| `createdAt` | DateTime | — | Criação (preservada no update) |
| `updatedAt` | DateTime | — | Última atualização |

O getter `pricePerUnit` calcula `packagePrice / packageQuantity` (retorna `0`
quando a quantidade é não positiva). O `fromMap` é **defensivo**: aceita
`Timestamp`, `DateTime` ou String ISO 8601 para as datas, com fallback
`DateTime.now()`, e valores numéricos nulos caem para `0`.

O modelo `Ingredient` (`lib/models/ingredient.dart`) expõe os getters sintéticos
calculados (não persistidos): `activeOffer` (procura `activeOfferId` com
`isActive`, depois a primeira `isActive`, senão `null`), `pricePerUnit` (da
oferta ativa, com fallback `purchasePrice / packageQuantity`), `offersCount`,
`lowestActivePricePerUnit` (mínimo entre as ativas) e `bestActiveOffer` (ativa
mais barata). O `fromMap` do insumo usa **parsing defensivo** com
`whereType<Map>()`: elementos malformados dentro de `offers[]` são simplesmente
ignorados, sem derrubar o stream de dados (diferencial 2.5, seção 3.2).

### 2.2 Subcoleção `price_audit_logs` (append-only)

Cada mutação de preço grava um log em `users/{uid}/price_audit_logs/{logId}`
(modelo `PriceAuditLog`, `lib/models/price_audit_log.dart`), no **mesmo batch**
da mutação (seção 4.3). Os campos estão na Tabela 2.

Tabela 2. Campos do modelo `PriceAuditLog` (lib/models/price_audit_log.dart).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `action` | String | Ação (Tabela 3) |
| `entityType` | String | `'ingredient'`, `'offer'` ou `'product'` |
| `entityId` | String | Identificador da entidade afetada |
| `summary` | String | Resumo legível em português (microcopy real do app) |
| `supplier` | String? | Fornecedor envolvido (quando aplicável) |
| `previousPrice` | double? | Preço anterior (quando aplicável) |
| `newPrice` | double? | Novo preço (quando aplicável) |
| `pricePerUnit` | double? | Preço por unidade resultante |
| `source` | String | Origem (padrão `'manual'`) |
| `timestamp` | DateTime? | `FieldValue.serverTimestamp()` no momento da gravação |
| `expireAt` | Timestamp | Criação + 180 dias (campo reservado para política TTL — seção 7.1) |

As ações registradas pelo módulo estão na Tabela 3.

Tabela 3. Ações registradas nos logs de auditoria (campo `action`).

| Ação | Origem no código | Conteúdo típico do `summary` |
|------|------------------|------------------------------|
| `offer.create` | `FirestoreService.upsertOffer` | "Oferta de {fornecedor} criada" |
| `offer.update` | `FirestoreService.upsertOffer` | "Oferta de {fornecedor} atualizada" |
| `offer.setActive` | `FirestoreService.setActiveOffer` | "Oferta de {fornecedor} definida como ativa — {ppu}/un" |
| `offer.toggleActive` | `FirestoreService.toggleOfferActive` | "Oferta de {fornecedor} ativada/desativada" (ou "…desativada; ticket volta ao preço base") |
| `offer.delete` | `FirestoreService.deleteOffer` | "Oferta de {fornecedor} removida" |
| `ingredient.create` / `ingredient.update` / `ingredient.delete` | CRUD de insumos | "Insumo {nome} criado/atualizado/removido" |

### 2.3 Camadas e separação de interesses (SoC)

O módulo mantém a arquitetura em camadas do app:

- **Lógica pura (sem Widgets):** `lib/utils/offer_comparator.dart` —
  `RankedOffer` (oferta ranqueada com `isBest`, `isActive` e `deltaVsActive`),
  `TicketLineSaving`/`TicketScenario` (cenário informativo de economia no
  ticket), `rank`/`rankAll` (ranking ascendente por preço/unidade),
  `bestOffer`, `syntheticLegacyOffer` (oferta sintética do preço legado),
  `pricePerUnitWithFallback`, `hasDifferentPackageSizes`,
  `bestSupplierScenario` (tolerância de 0,005 e arredondamento em 2 casas) e
  `deltaUnit`. `lib/utils/price_panel_aggregator.dart` — `ProductPanelEntry`,
  `SupplierPanelRow`, `SupplierPanelEntry`, `PanelSummary` e o agregador
  `PricePanelAggregator` (`buildPanel`, `sortPanel`, `filterPanel`,
  `summarize`, `rowsForSupplier`, `buildSupplierReport`), com normalização de
  fornecedores (`trim().toLowerCase()`), remoção de acentos na ordenação/busca
  (`_unaccent`/`_sortKey`), tolerância de 0,005 no delta e sentinela `-1`
  quando não há comparação válida.
- **Dados:** models (`lib/models/ingredient_offer.dart`,
  `price_audit_log.dart`, `ingredient.dart`) e acesso ao Firestore
  (`lib/services/firestore_service.dart`) com streams em tempo real e logs
  gravados em batch; provider (`lib/providers/ingredient_provider.dart`) com
  mapa `id → Ingredient` e cache do stream de auditoria.
- **Apresentação:** telas (`lib/screens/ingredient_offers_screen.dart`,
  `offer_form_screen.dart`, `compare_prices_screen.dart`,
  `audit_logs_screen.dart`) e widgets (`lib/widgets/offer_card.dart`,
  `panel_product_card.dart`, `supplier_summary_card.dart`,
  `audit_entry_tile.dart`, `economy_summary_card.dart`,
  `confirm_action_dialog.dart` e auxiliares), sobre a paleta existente
  (`0xFF0D1E16`, `0xFF165A41`, `0xFFB89775`, `0xFF142A20`, `0xFF7A8B83`).

A Figura 14 mostra a estrutura de diretórios do módulo (árvore real do
repositório).

Figura 14. Estrutura de diretórios do módulo comparativo de fornecedores.

```
lib/
|-- main.dart                       (rotas /ingredient-offers, /offer-form,
|                                    /audit-logs, /compare-prices)
|-- models/
|   |-- ingredient.dart             (offers[], activeOfferId + getters sintéticos)
|   |-- ingredient_offer.dart       (modelo IngredientOffer)
|   |-- price_audit_log.dart        (modelo PriceAuditLog)
|-- utils/
|   |-- offer_comparator.dart       (ranking, delta, cenário best — lógica pura)
|   |-- price_panel_aggregator.dart (painel por produto/fornecedor — lógica pura)
|-- services/
|   |-- firestore_service.dart      (upsertOffer, setActiveOffer, toggleOfferActive,
|                                    deleteOffer + logs em batch)
|-- providers/
|   |-- ingredient_provider.dart    (wrappers + auditLogs cacheado + reconnectAuditLogs)
|-- screens/
|   |-- ingredient_offers_screen.dart (comparativo do insumo + ações)
|   |-- offer_form_screen.dart        (nova/editar oferta)
|   |-- compare_prices_screen.dart    (painel "Comparar preços")
|   |-- audit_logs_screen.dart        (histórico de auditoria)
|-- widgets/
    |-- offer_card.dart              (card da oferta com onDelete)
    |-- panel_product_card.dart      (card do painel por produto)
    |-- supplier_summary_card.dart   (card do painel por fornecedor)
    |-- audit_entry_tile.dart        (linha da timeline de auditoria)
    |-- economy_summary_card.dart    (cenário de economia no ticket)
    |-- confirm_action_dialog.dart   (diálogo de confirmação reutilizável)
    |-- active_offer_marker.dart, best_price_chip.dart, delta_price_text.dart,
    |-- offer_count_badge.dart, offer_limit_banner.dart, empty_state.dart,
    |-- error_state.dart, filter_chip_row.dart, search_field.dart,
    |-- section_header.dart          (auxiliares do módulo)
test/
|-- offer_comparator_test.dart      (23 testes)
|-- price_panel_aggregator_test.dart(15 testes)
|-- unit_converter_test.dart        (15 testes)
|-- widget_test.dart                (1 teste de widget)
```

### 2.4 Diagrama do modelo de dados

A Figura 15 apresenta o modelo de dados do módulo sob o namespace do usuário
(`users/{uid}/...`), com as ofertas embutidas no insumo e a subcoleção de
auditoria.

Figura 15. Modelo de dados do módulo (Firestore, isolado por UID).

```
users/{uid}                          (perfil do usuário — Firebase Auth e-mail/senha)
  |
  |-- ingredients/{ingredientId}     (insumo do parque)
  |     |-- name, unit, purchasePrice, packageQuantity, createdAt
  |     |-- activeOfferId : String?  (referência lógica a offers[].id)
  |     |-- offers[] : Array<IngredientOffer>   (teto de 15)
  |            |-- id, supplier, packagePrice, packageQuantity,
  |            |   isActive, source, notes, createdAt, updatedAt
  |
  |-- price_audit_logs/{logId}       (subcoleção append-only)
        |-- action, entityType, entityId, summary
        |-- supplier?, previousPrice?, newPrice?, pricePerUnit?, source
        |-- timestamp (serverTimestamp), expireAt (+180 dias)

Relações (lógicas, sem referências do Firestore):
  - ingredients.activeOfferId  -> ingredients.offers[].id
  - price_audit_logs.entityId  -> ingredients.id | ingredients.offers[].id | products.id
  - products.recipe[].ingredientId -> ingredients.id (ticket consome Ingredient.pricePerUnit)
```

## 3. Fluxos do Módulo

### 3.1 Cadastro e edição de oferta (upsert por fornecedor)

O formulário (`lib/screens/offer_form_screen.dart`, rota `/offer-form`) coleta
fornecedor, preço da embalagem, quantidade da embalagem e notas, com **preview
ao vivo** do preço por unidade e, em edição, o card "Comparado com a oferta
ativa" (`DeltaPriceText`). A validação é inline (`errorText`) e por SnackBar:
fornecedor obrigatório, preço > 0, quantidade > 0 e teto de 15 ofertas.

No serviço, `upsertOffer` (`lib/services/firestore_service.dart`) executa:

1. **Validação de domínio (RN01):** `packagePrice <= 0 || packageQuantity <= 0`
   lança `StateError('O preço e a quantidade da embalagem devem ser maiores que
   zero (RN01).')`.
2. **Leitura defensiva do documento:** `offers[]` é parseado com
   `whereType<Map>()` — elementos malformados são ignorados.
3. **Upsert por fornecedor normalizado** (`trim().toLowerCase()`): o mesmo
   fornecedor **atualiza** a oferta existente (preservando `createdAt`) em vez
   de duplicar; log `offer.update` com `previousPrice`/`newPrice`.
4. **Criação:** respeita o teto (`StateError('Limite de 15 ofertas por insumo
   atingido.')`); a **primeira** oferta do insumo nasce ativa
   (`isActive = true` e `activeOfferId` apontando para ela); log `offer.create`.
5. **Batch atômico:** grava `{offers, activeOfferId}` no documento do insumo
   (`SetOptions(merge: true)`) **e** o log de auditoria
   (`expireAt = agora + 180 dias`) no mesmo `WriteBatch`.

### 3.2 Troca da oferta ativa — confirmação, desfazer e auditoria

Na tela de ofertas (`lib/screens/ingredient_offers_screen.dart`), a ação
"Usar no ticket" do `OfferCard` abre o diálogo `ConfirmActionDialog` ("Usar
esta oferta no ticket?") cujo corpo calcula o impacto contra a oferta ativa
atual: economia por unidade, aumento por unidade ou preço sem referência, com a
nota "Você pode trocar de volta quando quiser. O app não altera
automaticamente." — materialização da política "o app nunca troca sozinho"
(seção 6.2).

Confirmada a troca, `setActiveOffer` reescreve o array com a flag `isActive`
exclusiva e grava o log `offer.setActive` no mesmo batch. O SnackBar de sucesso
(dourado) oferece a ação **"Desfazer"**, que reativa a oferta anterior
(`previousActiveOfferId`) — desfazer também é uma troca manual auditada.

**Diferencial pós-Sprint 3 (falha explícita):** se o identificador informado
não corresponde a nenhuma oferta do documento, `setActiveOffer` lança
`Exception('Oferta não encontrada.')` (`firstWhere` com `orElse` que lança) em
vez de ativar a oferta errada ou falhar silenciosamente; a tela captura a
exceção e exibe o SnackBar vermelho "Não foi possível trocar a oferta: Oferta
não encontrada.". Casos de documento inexistente, `offers` não-lista ou o
convite legado `offerId == 'legacy'` com array vazio continuam sendo ignorados
com `return` (sem mutação).

A Figura 16 resume o fluxo.

Figura 16. Fluxo de troca da oferta ativa (confirmação → batch → auditoria → desfazer).

```
Usuário toca "Usar no ticket" (OfferCard)
  |
  v
ConfirmActionDialog "Usar esta oferta no ticket?"
  |-- corpo: economia/aumento por unidade vs. oferta ativa
  |-- nota: "Você pode trocar de volta quando quiser.
  |          O app não altera automaticamente."
  |
  +-- Cancelar -> nada acontece
  |
  v Confirmar
IngredientProvider.setActiveOffer(ingredientId, offerId)
  |
  v
FirestoreService.setActiveOffer
  |-- doc inexistente / offers não-lista / ('legacy' com array vazio) -> return
  |-- offerId desconhecido -> Exception('Oferta não encontrada.')
  |      -> SnackBar vermelho "Não foi possível trocar a oferta: …"
  |
  v
WriteBatch (atômico):
  |-- set ingredients/{id} { offers[] com isActive exclusivo, activeOfferId }
  |-- set price_audit_logs/{id} action=offer.setActive, expireAt=+180d
  |
  v
SnackBar dourado "Oferta de {fornecedor} agora é a ativa."
  +-- ação "Desfazer" -> setActiveOffer(ingredientId, previousActiveOfferId)
```

### 3.3 Exclusão de oferta — confirmação com alerta de oferta ativa

**Diferencial pós-Sprint 3:** a exclusão de oferta individual passou a ter
**diálogo de confirmação próprio** na tela de ofertas (`_deleteOffer`), com
comportamento distinto quando a oferta é a ativa:

- Corpo do diálogo: "{fornecedor} · {preço}/un"; quando a oferta é a ativa,
  acrescenta "Esta é a oferta ATIVA. Ao excluir, o ticket volta ao preço base
  até você escolher outra oferta."
- Nota: "A oferta ativa será removida." (ativa) ou "A exclusão não pode ser
  desfeita." (comum).
- O `OfferCard` expõe a ação "Excluir" pelo callback opcional `onDelete`
  (ícone `delete_outline`, cor secundária).

No serviço, `deleteOffer` remove a oferta do array, limpa `activeOfferId`
quando ele apontava para a oferta excluída (o ticket volta ao preço base
`purchasePrice / packageQuantity`) e grava o log `offer.delete` (com
`previousPrice` e `pricePerUnit`) no mesmo batch. O SnackBar de sucesso é
dourado ("Oferta de {fornecedor} excluída."); falhas exibem SnackBar vermelho
"Erro ao excluir oferta: …".

O toggle de visibilidade (`toggleOfferActive`) permanece: desativar a oferta
ativa limpa `activeOfferId` e registra o summary "Oferta de {fornecedor}
desativada; ticket volta ao preço base" (ação `offer.toggleActive`).

### 3.4 Comparação por produto e por fornecedor (painel "Comparar preços")

A tela `compare_prices_screen.dart` (rota `/compare-prices`, item "Comparar
preços" no drawer com `Icons.compare_arrows_outlined`) agrega o parque de
insumos via `PricePanelAggregator` (client-side, sem mudança de schema) em duas
visões selecionadas por `AppFilterChipRow`:

- **Por produto:** linha de economia ("Economia possível — {soma} combinados
  por unidade em {N} insumos" ou "Você já usa o melhor preço entre as ofertas
  cadastradas."), busca ("Buscar produto ou fornecedor…", sem acentos e
  case-insensitive), ordenação (Maior economia / Menor preço / Nome), chips de
  fornecedor (com tooltip acima de 18 caracteres), banner quando há apenas um
  fornecedor ("Cadastre mais fornecedores para ver o comparativo.") e cards
  `PanelProductCard` (melhor preço em destaque, linha "No ticket: {fornecedor}
  · {delta}" com `Semantics`, mini-chips de até 3 outros fornecedores e
  eco-chip "−{delta}/un"); insumos sem ofertas recebem a pill "sem comparação"
  (`legacyOnly`). O toque no card navega para `/ingredient-offers`.
- **Por fornecedor:** `SupplierSummaryCard` expansível por fornecedor
  ("Fornece {N} insumos · ★ melhor em {M}"), com pills das melhores ofertas
  (até 3 + "+{N}") e linhas por insumo com posição ("{i}º de {total}" ou
  "★ melhor preço · {i}º de {total}") e delta colorido (verde ≤ 0, laranja
  < 1, vermelho ≥ 1). Múltiplas ofertas do mesmo fornecedor são agrupadas
  usando a melhor (`rowsForSupplier`).

O resumo (`summarize`) conta `productsWithOffers`, `suppliersCount`,
`productsPayMore` e `economySumPerUnit` (soma honesta de deltas por unidade,
ignorando `legacyOnly` e deltas abaixo da tolerância de 0,005).

### 3.5 Histórico de auditoria com retry funcional

A tela `audit_logs_screen.dart` (rota `/audit-logs`, ícone de histórico na
AppBar da tela de ofertas) consome o stream `priceAuditLogsStream` (últimos 100
logs, `orderBy('timestamp', descending: true)`) via `StreamBuilder`. O provider
**cacheia** o stream (`_auditLogsStream ??= …`) para não reabrir a assinatura a
cada rebuild.

**Diferencial pós-Sprint 3 (retry funcional):** em caso de erro do stream, a
tela exibe `ErrorState("Não foi possível carregar o histórico.")` cujo botão
"Tentar novamente" chama `provider.reconnectAuditLogs()` (que zera o cache e
notifica os ouvintes) seguido de `setState` — o `StreamBuilder` **reassina** um
stream novo em vez de ficar preso no erro. A troca de usuário também zera o
cache (`_onUserChanged`).

A timeline agrupa os logs por dia ("Hoje", "Ontem" ou data formatada), com
`AuditEntryTile` (ícone por ação, vermelho para ações `.delete`; detalhe "de X
para Y" / "novo valor: X" / fornecedor; hora) e bottom sheet de detalhe ao
toque (resumo, timestamp completo, preços anterior → novo, fornecedor). Filtros:
Tudo / Insumos / Ofertas / Produtos / Sistema (por `entityType` e `source`),
além de busca textual.

A Tabela 4 resume as telas e rotas do módulo.

Tabela 4. Telas e rotas do módulo comparativo de fornecedores.

| Rota | Tela (arquivo) | Função |
|------|----------------|--------|
| `/ingredient-offers` | `ingredient_offers_screen.dart` | Comparativo do insumo: ranking, filtros, troca/exclusão/toggle de ofertas |
| `/offer-form` | `offer_form_screen.dart` | Nova/editar oferta (upsert por fornecedor) |
| `/compare-prices` | `compare_prices_screen.dart` | Painel "Comparar preços" (por produto / por fornecedor) |
| `/audit-logs` | `audit_logs_screen.dart` | Histórico de auditoria (somente leitura, com retry) |

## 4. Segurança

### 4.1 Regras do Firestore (isolamento por UID)

`firestore.rules` (`rules_version = '2'`) mantém o princípio do isolamento
completo por UID (RN02): cada usuário só lê/escreve dentro do próprio
`users/{uid}/...`. As subcoleções `transactions`, `budgets`, `ingredients` e
`products` permitem `read, write` apenas ao dono
(`request.auth.uid == uid`); a subcoleção `price_audit_logs` tem regra
própria (seção 4.2); o catch-all final (`match /{document=**}`) nega qualquer
outra coleção (`allow read, write: if false`). Não há coleções globais
acessíveis aos clientes.

### 4.2 Append-only dos logs de auditoria

O bloco de `price_audit_logs` é **append-only**:

```
match /price_audit_logs/{logId} {
  allow read, create: if request.auth != null && request.auth.uid == uid;
  allow update, delete: if false;
}
```

O dono pode ler e criar logs, mas **nenhum cliente** pode alterar ou apagar um
log existente — o histórico é imutável no nível das regras. A retenção
automática (TTL) é responsabilidade do console/GCP, não das regras (seção 7.1).

### 4.3 Batch atômico (mutação + log)

Toda mutação do módulo grava a mudança e o log de auditoria **no mesmo
`WriteBatch`**: ou os dois documentos são gravados, ou nenhum é. Isso vale para
`upsertOffer`, `setActiveOffer`, `toggleOfferActive`, `deleteOffer` e também
para o CRUD de insumos (`ingredient.create`/`update`/`delete`). O
`updateIngredient` protege as ofertas removendo `offers` e `activeOfferId` do
mapa antes do `merge` — a edição comum do insumo nunca apaga ofertas por
acidente. As credenciais do Firebase permanecem em `.env` (via
`flutter_dotenv`), nunca hardcoded.

## 5. Testes

A suíte do repositório possui **54 testes unitários e de widget, todos
aprovados** (`flutter test` → `+54: All tests passed!`, verificado em
09/10/2026). Os três arquivos de teste do módulo são:

- **`test/offer_comparator_test.dart` (23 testes):** `rank` (ordenação
  ascendente, marcação da melhor, `deltaVsActive` positivo/negativo/zero,
  lista vazia), `rankAll` (inclui inativas), `bestOffer` (ativa mais barata,
  `activeOnly=false`, ignora `packageQuantity <= 0`, empate estável, lista
  vazia), `syntheticLegacyOffer` (espelha o preço legado com
  `source='migration'`), `hasDifferentPackageSizes` e `bestSupplierScenario`
  (economia agregada, `null` sem economia, linhas `missing` ignoradas,
  `stillLoss`, sem falsa economia por arredondamento e tolerância de 0,005) e
  `deltaUnit`.
- **`test/price_panel_aggregator_test.dart` (15 testes):** cenário "padaria"
  com 8 insumos e 6 fornecedores — `buildPanel` (deltas corretos,
  `legacyOnly` sem economia, sentinela `-1` sem ofertas ativas válidas),
  `sortPanel` (economy/lowest/name), `filterPanel` (query sem acento,
  fornecedor exato, combinação), `rowsForSupplier` (posições e agrupamento de
  múltiplas ofertas do mesmo fornecedor), `buildSupplierReport` (ordenado por
  `bestCount`, exclui fornecedores sem ofertas ativas) e `summarize`
  (contagens e soma de economia, ignorando `legacyOnly`).
- **`test/unit_converter_test.dart` (15 testes):** conversões g↔kg e L↔ml,
  unidades iguais, famílias incompatíveis, zero/negativo sem conversão,
  comparação case-insensitive e `compatibleUnits`.

O teste de widget `test/widget_test.dart` (1 teste) cobre a renderização da
tela de cadastro. A Tabela 5 resume a distribuição.

Tabela 5. Distribuição dos 54 testes da suíte.

| Arquivo | Testes | Escopo |
|---------|-------:|--------|
| `offer_comparator_test.dart` | 23 | Lógica pura de comparação de ofertas |
| `price_panel_aggregator_test.dart` | 15 | Lógica pura do painel (produto/fornecedor) |
| `unit_converter_test.dart` | 15 | Conversão de unidades (g/kg, L/ml) |
| `widget_test.dart` | 1 | Widget da tela de cadastro |
| **Total** | **54** | |

Observação de ambiente: `flutter analyze` não é executável neste workspace
(o analysis server encerra com o caminho contendo "(Cópia)"); o verificador
oficial é `dart analyze .` (limpo) e `flutter test` (54/54).

## 6. Decisões de Produto

### 6.1 Do protótipo ao módulo real

O painel "Comparar preços" nasceu como protótipo HTML interativo aprovado
(Sprint 3, `documentacao/logs/sprint3/prototipo_painel_precos.html`) e foi
depois implementado como **módulo utilizável dentro do app** (decisão
registrada em `context/decisoes-de-fluxo.md`), sobre os dados reais de
`offers[]`, sem mudança de schema. O protótipo permanece como especificação
aprovada da UI.

### 6.2 "O app nunca troca sozinho"

A política central do módulo é que **a escolha do preço que entra no ticket é
sempre manual**: toda troca de oferta ativa exige confirmação explícita
(`ConfirmActionDialog`), o SnackBar de sucesso oferece "Desfazer", e o painel
apenas informa e navega — nunca altera dados. A microcopy do app é explícita:
"Você escolhe qual oferta entra no ticket. O app não troca sozinho." (tela de
ofertas) e "Nada foi alterado no ticket." (`EconomySummaryCard`, que apresenta
o cenário "Melhor fornecedor possível" apenas como simulação informativa).

### 6.3 O fornecedor nunca escreve no sistema

Não há login, convite ou portal para fornecedores: as ofertas são digitadas
pelo dono do negócio a partir dos preços que recebe. Todo dado vive sob
`users/{uid}/...` e as regras do Firestore não concedem acesso a terceiros —
o "fornecedor" é apenas um campo de texto (`supplier`) normalizado para
agrupamento.

### 6.4 Corte do login social (decisão de escopo)

**Diferencial pós-Sprint 3:** o login com Google e Facebook foi **removido**
por instabilidade, e o app passou a usar **apenas autenticação e-mail/senha**
(Firebase Auth). A decisão está materializada no código: `pubspec.yaml` sem
`google_sign_in` e `flutter_facebook_auth`; `AuthService` (`lib/services/
auth_service.dart`) expõe somente `signInWithEmail`/`registerWithEmail`/
`signOut`, com mensagens de erro amigáveis em português
(`friendlyAuthError`); `LoginScreen` sem botões sociais; e o cadastro
multi-etapa persiste o perfil em `users/{uid}`. Registrada no commit
`e3c6302` ("Reta final: remove login social; excluir oferta na UI e seguranca
de dados no comparativo"). Reintroduzir provedores sociais é decisão futura
que exigiria reavaliação de estabilidade e configuração nativa.

## 7. Limitações Conhecidas e Próximos Passos

### 7.1 TTL de 180 dias ainda não ativado no console/GCP

O campo `expireAt` (criação + 180 dias) **já é gravado** em todos os logs de
auditoria (`PriceAuditLog.toMap(expireAt)`), mas a **política de expiração
automática (TTL) ainda não foi ativada** no console do Firebase/GCP
(Firestore → política TTL no campo `expireAt`). Enquanto a política não for
criada, os logs antigos permanecem armazenados indefinidamente; a ativação é
operação de console, não de código.

### 7.2 Migração de preço legado é apresentada, mas não persistida

Insumos criados antes do módulo (sem `offers[]`) são tratados **em runtime**:
`OfferComparator.syntheticLegacyOffer` constrói uma oferta sintética em
memória (id `legacy`, fornecedor "Fornecedor padrão", `source='migration'`,
nota "Preço cadastrado migrado automaticamente") para exibição na tela de
ofertas, e o ticket continua lendo o preço base pelo fallback
`purchasePrice / packageQuantity` (`pricePerUnitWithFallback`). **Nada é
escrito** no documento do insumo — não há migração persistida em lote. A tela
de ofertas mostra o card "Preço base do insumo" convidando ao cadastro de
ofertas, e o filtro "Padrão" isola ofertas com `source == 'migration'`.
`setActiveOffer('legacy')` é ignorado (return silencioso) quando o array está
vazio.

### 7.3 Próximos passos (v-next)

- **Reconhecimento por foto** de produtos e **recorrência** de ofertas ficam
  para a próxima versão (não implementados no código atual).
- **Economia semanal de verdade** no painel exigiria campo de consumo no
  modelo (hoje a economia é por unidade — decisão de produto pendente).
- **Deploy das regras** (`firebase deploy --only firestore:rules`) segue como
  pendência operacional do usuário antes de rodar/distribuir o app atualizado.
- **Capturas de tela** do módulo para as Figuras 17–20 (pendentes de
  dispositivo/emulador).

## 8. Considerações Finais

O módulo comparativo de fornecedores do CashCtrl está consolidado como parte
estável do aplicativo: modelo de dados enxuto (ofertas embutidas com teto de
15 e oferta ativa exclusiva), lógica pura testável (38 testes de comparação e
painel), operações Firestore atômicas com auditoria append-only, painel
informativo em duas visões e UX de troca manual com confirmação, desfazer e
falhas amigáveis. Os diferenciais pós-Sprint 3 — exclusão com confirmação e
log, erro explícito "Oferta não encontrada.", parsing defensivo de documentos
malformados, retry funcional na auditoria e o corte do login social — foram
verificados diretamente no código da branch `nova-versao-app` (commit
`e3c6302`) e estão documentados nas seções 3.2, 3.3, 3.5 e 6.4.

As limitações remanescentes (TTL a ativar no console, migração legado apenas
em runtime, reconhecimento por foto e recorrência para v-next) estão
registradas na seção 7 com os responsáveis claros: console/GCP, runtime e
próxima versão, respectivamente.

## Referências

- Código-fonte: `lib/models/ingredient_offer.dart`, `lib/models/price_audit_log.dart`,
  `lib/models/ingredient.dart`, `lib/utils/offer_comparator.dart`,
  `lib/utils/price_panel_aggregator.dart`, `lib/services/firestore_service.dart`,
  `lib/providers/ingredient_provider.dart`, `lib/screens/ingredient_offers_screen.dart`,
  `lib/screens/offer_form_screen.dart`, `lib/screens/compare_prices_screen.dart`,
  `lib/screens/audit_logs_screen.dart`, `lib/widgets/offer_card.dart` (e demais
  widgets listados na Figura 14), `lib/main.dart`, `lib/services/auth_service.dart`.
- Regras de segurança: `firestore.rules`, `storage.rules`.
- Testes: `test/offer_comparator_test.dart`, `test/price_panel_aggregator_test.dart`,
  `test/unit_converter_test.dart`, `test/widget_test.dart`.
- Documentação de apoio: `docs/overview.md`;
  `documentacao/ctrlcash_documentacao.txt`;
  `documentacao/logs/sprint3/HANDOVER.md`;
  `documentacao/logs/metadata/sprint3_2026-10-08_comparar_precos.md`;
  `context/decisoes-de-fluxo.md`; `context/erros-a-evitar.md`.
- Relatórios anteriores do padrão BIBLIOTECA:
  `documentacao/BIBLIOTECA_113_RT_279.docx` (template),
  `documentacao/CTRLCASH_SPRINT2_PROPOSTA_A_RT.docx`,
  `documentacao/CTRLCASH_SPRINT3_PAINEL_COMPARACAO_FUTURO_RT.docx`.

---

## Figuras pendentes (capturas de tela)

- Figura 17 — Tela de ofertas do insumo (ranking com badges "ATIVA"/"melhor",
  filtros e ações do OfferCard). `[captura de tela pendente]`
- Figura 18 — Diálogo "Usar esta oferta no ticket?" com economia/aumento e
  SnackBar com "Desfazer". `[captura de tela pendente]`
- Figura 19 — Painel "Comparar preços": visão por produto (eco-line e cards) e
  visão por fornecedor. `[captura de tela pendente]`
- Figura 20 — Histórico de auditoria (timeline por dia e bottom sheet de
  detalhe). `[captura de tela pendente]`
