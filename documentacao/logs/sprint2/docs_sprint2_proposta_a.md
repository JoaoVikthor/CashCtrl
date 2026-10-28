# Documentação Técnica da Aplicação Móvel CashCtrl — Sprint 2

**Proposta A — Comparação de Fornecedores** (ofertas por insumo, ticket com oferta
ativa e logs de auditoria de preços)

Equipe CashCtrl (autoria: github.com/JoaoVikthor — lista final de autores/e-mails a
confirmar na versão institucional)

Documento interno do projeto, no formato de relatório técnico do template
`documentacao/BIBLIOTECA_113_RT_279.docx` — São Carlos — Outubro/2026

---

## Indice

- 1. Introdução
- 2. Visão Geral do CashCtrl
- 3. Requisitos do CashCtrl
  - 3.1 Requisitos não-funcionais
  - 3.2 Requisitos funcionais do Sprint 2
- 4. Projeto Lógico e Implementação do Sprint 2
  - 4.1 Separação de Interesses (SoC) — arquitetura Flutter + Firebase
  - 4.2 Estrutura de diretórios e subdiretórios
  - 4.3 Descrição da Implementação
  - 4.4 Modelo de Dados — `IngredientOffer` embutido no insumo
  - 4.5 Logs de Auditoria de Preços
  - 4.6 Diagrama Entidade-Relacionamento
  - 4.7 Esquema do Banco de Dados (Firestore)
- 5. Instalação do CashCtrl
- 6. Manual do usuário
  - 6.1 Comparativo de fornecedores
  - 6.2 Ticket do produto com oferta ativa
  - 6.3 Histórico de auditoria
- 7. Considerações Finais

---

## 1. Introdução

Este relatório apresenta a documentação técnica do **Sprint 2** do CashCtrl, aplicativo
móvel desenvolvido em Flutter com backend Firebase, referente à implementação da
**Proposta A — Comparação de Fornecedores**. Neste relatório estão os principais
documentos para o entendimento técnico da solução: o modelo de dados de ofertas por
insumo, os logs de auditoria de preços, as regras de negócio do ticket e os detalhes de
implementação das telas.

O objetivo dessa documentação é propiciar uma visão abrangente dos recursos
implementados no Sprint 2 e incentivar que a ferramenta seja rapidamente compreendida
por desenvolvedores interessados em evoluir suas características. Todo o conteúdo
reflete o código efetivamente entregue (`lib/`, `firestore.rules`, `test/`) na data de
outubro de 2026: nomes de arquivos, classes, assinaturas e microcopy foram extraídos
diretamente do repositório.

## 2. Visão Geral do CashCtrl

O CashCtrl é um aplicativo móvel (Flutter/Firebase, tema escuro com acentos verdes e
dourados) para microempreendedores, com gestão financeira (transações, orçamentos,
relatórios) e cálculo de ficha técnica de produtos ("ticket"), que aponta lucro ou
prejuízo por produto.

No Sprint 1 o insumo possuía um único preço (`purchasePrice` + `packageQuantity` →
`pricePerUnit`), lido ao vivo pelo `ProductCalculator`. O Sprint 2 (Proposta A) evolui o
parque de insumos para suportar **múltiplas ofertas de fornecedores por insumo**, com
comparação por preço/unidade, oferta ativa escolhida pelo usuário alimentando o ticket,
alerta de economia e logs de auditoria append-only.

A versão do aplicativo no `pubspec.yaml` é `1.0.0+1`, com Dart SDK `^3.11.5`. O escopo
entregue no Sprint 2 inclui: modelo `IngredientOffer` embutido em array no documento do
insumo (teto de 15), lógica pura de comparação em `lib/utils/offer_comparator.dart`,
operações de oferta e migração no `FirestoreService` com log de auditoria gravado no
mesmo batch da mutação, três rotas novas (`/ingredient-offers`, `/offer-form`,
`/audit-logs`), treze widgets reutilizáveis novos e 23 testes unitários da lógica pura
(suíte completa: 24/24 aprovados).

## 3. Requisitos do CashCtrl

### 3.1 Requisitos não-funcionais

Requisitos prioritários considerados para o Sprint 2 (mantidos do Sprint 1 e
estendidos):

- **Isolamento (RN02):** todos os dados continuam sob `users/{uid}/...`; nenhum usuário
  acessa dados de outro (Firestore e Storage).
- **Auditabilidade:** toda mutação de preço gera log append-only com retenção definida
  (`expireAt` = criação + 180 dias), gravado **no mesmo batch** da mutação.
- **Zero regressão:** o cálculo do ticket legado não pode mudar de resultado para
  insumos migrados — o `ProductCalculator` consome `Ingredient.pricePerUnit`, que cai
  para o fallback `purchasePrice / packageQuantity` quando não há oferta ativa.
- **Política manual:** o app nunca troca a oferta ativa sozinho; toda troca exige
  confirmação explícita do usuário.
- **Manutenibilidade:** SoC mantido — models, lógica pura em `lib/utils/`, services,
  providers e screens/widgets em camadas separadas; sem comentários novos no código.
- **Segurança:** regras Firestore atualizadas (coleção `price_audit_logs`, append-only)
  e **deployadas antes do app**; chaves apenas em `.env` (nunca hardcoded).

### 3.2 Requisitos funcionais do Sprint 2

Lista validada contra o código final (nenhum item do MVP foi cortado):

- suporte a múltiplas ofertas de fornecedor por insumo (teto de **15** ofertas,
  validado no formulário e no serviço com `StateError`),
- comparação de ofertas por preço/unidade (`pricePerUnit = packagePrice /
  packageQuantity`) com ranking ascendente,
- oferta ativa (`activeOfferId`) escolhida manualmente pelo usuário para alimentar o
  ticket, com flag `isActive` exclusiva entre as ofertas,
- marcadores "ATIVA" (`ActiveOfferMarker`) e "melhor" com estrela (`BestPriceChip`) no
  comparativo e na lista de insumos,
- cartão de economia no ticket (`EconomySummaryCard`) calculado por
  `OfferComparator.bestSupplierScenario` — informativo, nunca altera o veredito,
- upsert por fornecedor normalizado (`trim().toLowerCase()` — mesmo fornecedor atualiza
  em vez de duplicar),
- logs de auditoria append-only com retenção de 180 dias (`expireAt`),
- migração lazy e idempotente dos insumos legados sem `offers[]`
  (`migrateLegacyPrice`), criando a oferta "Fornecedor padrão" com `source='migration'`,
- tela de histórico de auditoria (`AuditLogsScreen`, somente leitura),
- exclusão de oferta individual (`deleteOffer`) com limpeza de `activeOfferId` quando
  necessário — evento `offer.delete` incluído no escopo real.

Itens previstos no esqueleto e **não implementados** (registrados para rastreabilidade):
o evento `offer.defaultRecalculated` (o recálculo de default foi resolvido com a flag
exclusiva `isActive` + `activeOfferId`, sem evento próprio) e os campos sintéticos
persistidos `lowestPricePerUnit`/`bestSupplier`/`offersCount` no documento do insumo
(que no código final são **getters calculados**: `lowestActivePricePerUnit`,
`bestActiveOffer`, `offersCount`).

## 4. Projeto Lógico e Implementação do Sprint 2

### 4.1 Separação de Interesses (SoC) — arquitetura Flutter + Firebase

Para garantir manutenibilidade, foi mantida a abordagem de Separação de Interesses
(Separation of Concerns — SoC) em camadas:

- **Lógica:** classes puras em Dart, sem dependência de Widgets —
  `lib/utils/offer_comparator.dart` (ranking `rank`/`rankAll`, melhor oferta
  `bestOffer`, oferta sintética legado `syntheticLegacyOffer`, detecção de embalagens
  de tamanhos diferentes `hasDifferentPackageSizes`, cenário informativo
  `bestSupplierScenario`) e `lib/utils/product_calculator.dart` (ticket, inalterado no
  Sprint 2).
- **Dados:** models (`lib/models/ingredient_offer.dart`, `lib/models/price_audit_log.dart`,
  `lib/models/ingredient.dart`) e acesso ao Firestore (`lib/services/firestore_service.dart`),
  com dados isolados por UID sob `users/{uid}/...`, streams em tempo real e logs de
  auditoria gravados em batch junto com cada mutação.
- **Apresentação:** provider (`lib/providers/ingredient_provider.dart`), telas
  (`lib/screens/`) e widgets (`lib/widgets/`), tema escuro com a paleta existente
  (`colorBackground 0xFF0D1E16`, `colorGreenPrimary 0xFF165A41`, `colorGold 0xFFB89775`,
  `colorCard 0xFF142A20`, `colorTextSec 0xFF7A8B83`), moeda e datas sempre via
  `lib/utils/format.dart`.

### 4.2 Estrutura de diretórios e subdiretórios

Arquivos criados ou modificados pelo Sprint 2 (árvore real extraída do repositório):

**Figura 1.** Estrutura de diretórios afetada pelo Sprint 2.

```
lib/
|-- main.dart                     (modificado: rotas /ingredient-offers, /offer-form, /audit-logs)
|-- models/
|   |-- ingredient.dart           (modificado: offers[], activeOfferId + getters sintéticos)
|   |-- ingredient_offer.dart     (novo: modelo IngredientOffer)
|   |-- price_audit_log.dart      (novo: modelo PriceAuditLog)
|-- utils/
|   |-- offer_comparator.dart     (novo: ranking, delta, cenário best — lógica pura)
|-- services/
|   |-- firestore_service.dart    (modificado: CRUD ofertas + log em batch + migração lazy)
|-- providers/
|   |-- ingredient_provider.dart  (modificado: upsertOffer, setActiveOffer, toggleOfferActive,
|   |                              deleteOffer, migrateLegacyPrice, auditLogs)
|-- screens/
|   |-- ingredients_screen.dart          (modificado: OfferCountBadge, marcadores, atalho de ofertas)
|   |-- ingredient_form_screen.dart      (modificado: seções "Fornecedor padrão" e "Ofertas")
|   |-- ingredient_offers_screen.dart    (novo: comparativo/ranking)
|   |-- offer_form_screen.dart           (novo: formulário de oferta)
|   |-- product_detail_screen.dart       (modificado: EconomySummaryCard após o veredito)
|   |-- audit_logs_screen.dart           (novo: histórico de auditoria, leitura)
|-- widgets/
    |-- offer_count_badge.dart      (novo)  |-- section_header.dart       (novo)
    |-- best_price_chip.dart        (novo)  |-- search_field.dart         (novo)
    |-- active_offer_marker.dart    (novo)  |-- filter_chip_row.dart      (novo)
    |-- delta_price_text.dart       (novo)  |-- empty_state.dart          (novo)
    |-- offer_card.dart             (novo)  |-- error_state.dart          (novo)
    |-- offer_limit_banner.dart     (novo)  |-- confirm_action_dialog.dart (novo)
    |-- audit_entry_tile.dart       (novo)  |-- economy_summary_card.dart (novo)

firestore.rules                   (modificado: match /price_audit_logs antes do catch-all)
test/offer_comparator_test.dart   (novo: 23 testes da lógica pura)
```

> Sem screenshot aplicável a esta figura (árvore de diretórios); a Figura 1 acima é a
> representação textual adotada no lugar da captura. Capturas de tela das telas
> (Figuras 3 a 8) permanecem pendentes por não haver device/emulador no ambiente de
> documentação.

### 4.3 Descrição da Implementação

#### 4.3.1 Diretório `lib/models`

- `ingredient_offer.dart`: modelo da oferta embutida. Classe imutável `IngredientOffer`
  com `id` (String), `supplier` (String), `packagePrice` (double, > 0 validado no
  serviço), `packageQuantity` (double, > 0 validado no serviço), `isActive` (bool,
  padrão `false`), `source` (String, `'manual'` | `'migration'`, padrão `'manual'`),
  `notes` (String, padrão `''`), `createdAt`/`updatedAt` (DateTime). O preço por
  unidade **não é campo armazenado**: é o getter calculado `pricePerUnit =>
  packageQuantity > 0 ? packagePrice / packageQuantity : 0`. Serialização
  `fromMap`/`toMap` + `copyWith`; o `toMap` persiste datas como **ISO 8601 string** e o
  `fromMap` aceita `Timestamp` do Firestore, `DateTime` ou string ISO (tolerante).
  Não há campo `isDefault` nem `pricePerUnitCache` no código final — a oferta "padrão"
  é representada por `source == 'migration'` e o cache por unidade é calculado.
- `price_audit_log.dart`: modelo do log de auditoria. `PriceAuditLog` com `action`,
  `entityType`, `entityId`, `summary`, `supplier?`, `previousPrice?`, `newPrice?`,
  `pricePerUnit?`, `source` (padrão `'manual'`) e `timestamp?` (DateTime lido). O
  `toMap(DateTime expireAt)` grava `timestamp` como **`FieldValue.serverTimestamp()`**
  (nunca o relógio do cliente) e `expireAt` como ISO 8601 string. O `fromMap` aceita
  `Timestamp`/`DateTime`/string. Não há campo `uid` no documento (a posse é garantida
  pelo caminho `users/{uid}/price_audit_logs/`), nem `entityName` nem campos de
  quantidade — contexto fica no `summary`.
- `ingredient.dart`: `Ingredient` estendido com `offers` (`List<IngredientOffer>`,
  padrão `const []`) e `activeOfferId` (`String?`). Getters sintéticos calculados:
  `activeOffer` (procura `activeOfferId` com `isActive`, senão a primeira `isActive`),
  `pricePerUnit` (oferta ativa, senão legado `purchasePrice / packageQuantity`),
  `offersCount`, `lowestActivePricePerUnit` e `bestActiveOffer`. O `toMap` persiste
  `offers` (via `IngredientOffer.toMap`), `activeOfferId` e datas como ISO 8601; o
  `fromMap` reconstrói a lista tolerando documentos legados sem `offers`.

#### 4.3.2 Diretório `lib/utils`

- `offer_comparator.dart`: lógica pura de comparação (nome real do arquivo; o plano
  inicial chamava `offer_logic.dart`). Classes de resultado: `RankedOffer`
  (`offer`, `isBest`, `isActive`, `deltaVsActive`), `TicketLineSaving`
  (`ingredientId`, `ingredientName`, `supplier`, `currentUnitPrice`, `bestUnitPrice`,
  `quantity`; getter `saving = (currentUnitPrice − bestUnitPrice) × quantity`) e
  `TicketScenario` (`totalSaving`, `simulatedProfit`, `salePrice`, `stillLoss`,
  `lines`). Métodos estáticos de `OfferComparator`: `rank` (ordena por
  `pricePerUnit` ascendente, apenas ofertas `isActive` por padrão —
  `considerInactive: true` inclui inativas; delta calculado contra a oferta ativa,
  `0.0` quando não há ativa), `rankAll`, `bestOffer` (ignora
  `packageQuantity <= 0`; `activeOnly: true` por padrão),
  `syntheticLegacyOffer(ing, {id = 'legacy'})` (oferta sintética "Fornecedor padrão"
  espelhando o preço legado, `isActive: true`, `source: 'migration'`, notas
  "Preço cadastrado migrado automaticamente"), `pricePerUnitWithFallback(ing)`
  (oferta ativa, senão legado), `hasDifferentPackageSizes` (≥ 2 ofertas com
  quantidades distintas), `bestSupplierScenario(ticket)` (cenário informativo: para
  cada linha não-`missing` com melhor oferta mais barata que o preço usado —
  tolerância `0.005` — acumula economia, arredonda para 2 centavos via `_round2`,
  retorna `null` se economia total `<= 0.01`, calcula `simulatedProfit =
  ticket.profit + totalSaving` e marca `stillLoss`) e `deltaUnit(a, b)`.
- `product_calculator.dart`: inalterado como cálculo — o ticket continua consumindo
  `Ingredient.pricePerUnit`, que agora resolve para o preço da oferta ativa e cai no
  fallback legado (`purchasePrice / packageQuantity`) quando não há oferta ativa. O
  cenário "melhor fornecedor" vive no `OfferComparator` e é sempre paralelo ao
  `TicketResult`, nunca o substitui.

#### 4.3.3 Diretório `lib/services`

- `firestore_service.dart`: `FirestoreService` estendido com o bloco de ofertas e
  auditoria, sempre sob `users/{uid}/...`:
  - `addIngredient`: batch com `set` do insumo + log `ingredient.create`
    ("Insumo {name} criado").
  - `updateIngredient`: batch com `merge` do insumo + log `ingredient.update`
    ("Insumo {name} atualizado"). Antes do merge, o mapa é limpo com
    `data.remove('offers')` e `data.remove('activeOfferId')` — **proteção contra
    overwrite**: editar o insumo (nome/unidade/preço base) nunca apaga nem sobrescreve
    as ofertas persistidas.
  - `deleteIngredient`: batch com `delete` + log `ingredient.delete` ("Insumo removido").
  - `upsertOffer(uid, ingredientId, offer)`: valida `packagePrice > 0` e
    `packageQuantity > 0` (senão `StateError`); normaliza o fornecedor
    (`trim().toLowerCase()`) e atualiza a oferta existente do mesmo fornecedor
    preservando `id` e `createdAt` (log `offer.update`) ou cria uma nova — se
    `current.length >= 15`, lança `StateError('Limite de 15 ofertas por insumo
    atingido.')` (log `offer.create`). Grava `offers` + `activeOfferId` preservado e o
    log **no mesmo batch**.
  - `setActiveOffer(uid, ingredientId, offerId)`: escolhe a oferta (`orElse` primeira;
    no-op quando `offers` vazio e `offerId == 'legacy'`), grava a flag `isActive`
    **exclusiva** (`o.id == chosen.id`) e `activeOfferId = chosen.id`, com log
    `offer.setActive` ("Oferta de {supplier} definida como ativa — X.XX/un").
  - `toggleOfferActive(uid, ingredientId, offerId, isActive)`: liga/desliga a oferta;
    ao **desativar a ativa**, limpa `activeOfferId` (o ticket volta ao preço base) e o
    summary do log `offer.toggleActive` registra "Oferta de {supplier} desativada;
    ticket volta ao preço base"; caso contrário "Oferta de {supplier}
    ativada/desativada".
  - `deleteOffer(uid, ingredientId, offerId)`: remove a oferta; se ela era a ativa,
    limpa `activeOfferId`; log `offer.delete` ("Oferta de {supplier} removida").
  - `migrateLegacyPrice(uid, ing)`: **idempotente** — retorna cedo se o documento já
    tiver `offers` não vazio; cria a oferta "Fornecedor padrão" com o preço legado,
    `isActive: true`, `source: 'migration'`, notas "Preço cadastrado migrado
    automaticamente", define `activeOfferId` e grava o log
    `migration.legacyToOffer` ("Preço legado de {name} migrado para oferta").
  - `writeAuditLog`: gravação avulsa de log (usada por mutações fora dos métodos
    acima). Todos os logs recebem `expireAt = agora + 180 dias` e são gravados no
    **mesmo batch** da mutação do insumo — não existe preço alterado sem log.
  - `priceAuditLogsStream(uid, {limit = 100})`: stream ordenado por `timestamp`
    descendente para a tela de auditoria.

#### 4.3.4 Diretório `lib/providers`

- `ingredient_provider.dart`: `IngredientProvider` (ChangeNotifier) expõe `list`,
  `loading`, `error`, `asMap` (mapa id → `Ingredient` consumido pelo `ProductProvider`
  e pelas calculadoras) e os métodos assíncronos `addIngredient`, `updateIngredient`,
  `deleteIngredient`, `upsertOffer`, `setActiveOffer`, `toggleOfferActive`,
  `deleteOffer`, `migrateLegacyPrice` e o stream `auditLogs` (delega para o
  `FirestoreService` com `limit = 100`). Todos lançam `StateError('Usuário não
  autenticado.')` quando não há UID; o stream reconecta quando o usuário logado muda
  (`attach` + listener no `UserProvider`).

#### 4.3.5 Diretório `lib/screens`

- `ingredients_screen.dart` (modificada): card do insumo preservado; abaixo do nome,
  `OfferCountBadge(count: ing.offersCount)` ("N ofertas" ou "sem ofertas"); na coluna
  direita, sob o preço por unidade (que agora representa a oferta ativa via getter),
  quando `offers.length >= 2` aparecem `ActiveOfferMarker` e, se a ativa não for a
  melhor, `BestPriceChip`; novo ícone `Icons.storefront_outlined` (dourado, tooltip
  "Ver ofertas") e `onLongPress` navegam para `/ingredient-offers` com `ing.id`.
  Exclusão continua com diálogo "Excluir insumo?" e SnackBar "Insumo excluído.".
- `ingredient_form_screen.dart` (modificada): campos base e preview inalterados
  (preço legado = fallback). Nova seção "Fornecedor padrão" (`SectionHeader` com
  `Icons.storefront_outlined`): com oferta ativa, card "Ativa agora" com fornecedor,
  pill ATIVA, linha de preço ("R$ X · qtd un · R$/un") e os links "Editar oferta" e
  "Ver todas (N)"; com ofertas sem nenhuma ativa, aviso laranja "Nenhuma oferta ativa.
  O ticket usa o preço base deste insumo."; sem ofertas, ícone inline + texto "Salve o
  insumo antes de adicionar ofertas." (insumo novo, botão desabilitado) ou "Nenhuma
  oferta cadastrada." + botão "Adicionar primeira oferta". Nova seção "Ofertas" com
  contador "X/15", até 3 cards compactos (fornecedor + R$/un + marcadores ATIVA e
  ★ melhor) e link "Ver todas as N ofertas →" quando houver mais de 3 ("Nenhuma
  oferta ainda." quando vazia). Salvar o insumo nunca cria oferta; o preview exibe a
  sub-linha "Com oferta ativa, o ticket usa R$ X/un (fornecedor Y).".
- `ingredient_offers_screen.dart` (nova): `IngredientOffersScreen({required String
  ingredientId})`. AppBar "Ofertas de {insumo}"; card resumo com nome do insumo,
  "Preço por unidade de referência: R$ X/un", chips da oferta ativa (ou o aviso
  laranja "Nenhuma oferta ativa") e "também é a melhor" / "melhor: {fornecedor}";
  banner condicional laranja "Atenção: embalagens de tamanhos diferentes. Compare o
  preço por unidade."; linha de política "Você escolhe qual oferta entra no ticket. O
  app não troca sozinho."; filtros `AppSearchField` ("Buscar fornecedor…") +
  `AppFilterChipRow` [Todas, Ativas, Inativas, Padrão] (o filtro "Padrão" mapeia
  `source == 'migration'`) + toggle dourado "só com economia" (somente inativas com
  delta < −0,005); contador "{n} de 15 ofertas" com "Limite de 15 atingido" em
  laranja; ranking via `OfferComparator.rankAll` (preço/unidade ascendente, inativas
  com opacidade 0,55) renderizado por `OfferCard`; estado vazio `EmptyState`
  ("Nenhuma oferta cadastrada" / "Cadastre fornecedores para comparar preços e
  escolher quem entra no ticket." / CTA "Adicionar oferta"), card de referência do
  preço legado ("Preço base do insumo" / "Cadastre ofertas para comparar.") quando
  não há ofertas mas há preço base, e "Nenhuma oferta corresponde aos filtros." +
  "Limpar filtros" quando o filtro zera a lista; `OfferLimitBanner` quando 15/15; CTA
  inferior "Adicionar oferta" desabilitado no limite. A ação "Usar no ticket" abre
  `ConfirmActionDialog` — título **"Usar esta oferta no ticket?"**, corpo com
  "{fornecedor} · R$ X/un" + "Economia de R$ X por unidade em relação à ativa." ou
  "Ficará R$ X mais caro por unidade." — e nota "Você pode trocar de volta quando
  quiser. O app não altera automaticamente."; confirmado, chama
  `provider.setActiveOffer` com SnackBar dourada "Oferta de {fornecedor} agora é a
  ativa." ou vermelha "Não foi possível trocar a oferta.". Estados de loading (spinner
  dourado) e erro (`ErrorState` / "Insumo não encontrado.") cobertos.
- `offer_form_screen.dart` (nova): `OfferFormScreen({required String ingredientId,
  IngredientOffer? offer})`, títulos "Nova oferta"/"Editar oferta". Legenda "Informe o
  que você paga e quanto vem na embalagem. O app calcula o preço por unidade."
  Campos: "Nome do fornecedor" (helper "Ex.: Distribuidora Central, Atacado do Zé"),
  "Preço da embalagem (R$)", "Qtd. da embalagem" e chip read-only
  "unidade: {unidade do insumo}". Preview ao vivo no padrão do formulário de insumo:
  "Preço por unidade" → "R$ X / un" (ou "Informe a quantidade" quando qtd = 0).
  "Notas (opcional)" multiline com contador "n/200" acima de 160 caracteres. Em
  edição, card "Comparado com a oferta ativa" com `DeltaPriceText` e sub-linha
  "Ativa: {fornecedor} · R$ X/un". Validação dura: "Informe o nome do fornecedor.",
  "Informe um preço maior que zero.", "Informe uma quantidade maior que zero."
  (errorText no campo + SnackBar vermelha); 16ª oferta bloqueada com o toast "Limite
  de 15 ofertas por insumo." e `OfferLimitBanner`; parsing aceita vírgula
  (`replaceAll(',', '.')`). Salvar chama `provider.upsertOffer` (id `''` no create) e
  fecha com SnackBar dourada "Oferta salva."/"Oferta atualizada."; nova oferta nasce
  `isActive: true`, `source: 'manual'`.
- `product_detail_screen.dart` (modificada): insere `EconomySummaryCard` imediatamente
  após o card de veredito, com `scenario: OfferComparator.bestSupplierScenario(t)` —
  cálculo **informativo e paralelo**: o `TicketResult` (custo, lucro, margem, markup)
  nunca muda por causa do cartão. O callback `onViewOffers` navega para
  `/ingredient-offers` do insumo de maior economia ou, com id vazio, para
  `/ingredients`.
- `audit_logs_screen.dart` (nova): `AuditLogsScreen()`, somente leitura. Cabeçalho
  "Auditoria" (`AppBrandedHeader`); subcabeçalho "Registro de ações" +
  "Tudo que altera custos, ofertas e produtos aparece aqui."; busca "Buscar por ação,
  produto ou fornecedor…" e filtros [Tudo, Insumos, Ofertas, Produtos, Sistema]
  ("Sistema" agrupa `entityType == 'migration'`, `source == 'system'` e tipos fora de
  ingredient/offer/product); linha do tempo agrupada por dia ("Hoje"/"Ontem"/data via
  `formatDate`), itens `AuditEntryTile` e toque abre bottom sheet de detalhes com
  timestamp completo ("{data} às HH:MM"), "Anterior: R$ X → Novo: R$ Y" ou "Novo
  valor: R$ X" e "Fornecedor: {fornecedor}". Estado vazio "Nenhuma ação registrada" /
  "Alterações em insumos, ofertas e produtos aparecerão aqui."; erro
  `ErrorState("Erro ao carregar auditoria: ...")`. Ícones por evento: criação
  `add_circle_outline`, edição `edit_outlined`, exclusão `delete_outline` (vermelho),
  ativação `check_circle_outline`, migração `sync`. Nunca exibe uid/IDs brutos.

#### 4.3.6 Diretório `lib/widgets`

Widgets novos (todos reutilizáveis, sem dependência de screens):

- `offer_count_badge.dart`: `OfferCountBadge({required int count})` — pill "N ofertas"
  (fundo verde @0,2, texto dourado 11 bold); `count == 0` → "sem ofertas" em cinza.
- `best_price_chip.dart`: `BestPriceChip({String label = 'melhor'})` — estrela
  dourada, borda dourada 1,2, fundo card.
- `active_offer_marker.dart`: `ActiveOfferMarker({bool active = true})` — pill "ATIVA"
  (fundo verde primário) ou "INATIVA" (contorno `white24`).
- `delta_price_text.dart`: `DeltaPriceText({required double delta, double fontSize =
  12})` — negativo "−R$ X" em verde, positivo "+R$ X" em vermelho, zero "—" em cinza;
  com `Semantics` ("economia de R$ X" / "aumento de R$ X" / "sem diferença").
- `section_header.dart`: `SectionHeader({required IconData icon, required String
  title, Widget? trailing})` — ícone dourado 18 + título branco bold 16.
- `search_field.dart`: `AppSearchField({required String hint, required
  ValueChanged<String> onChanged})` — campo card, ícone de busca dourado, raio 12.
- `filter_chip_row.dart`: `AppFilterChipRow({required List<String> options, required
  int selectedIndex, required ValueChanged<int> onSelected})` — chips horizontais
  altura 40; selecionado fundo verde + branco.
- `empty_state.dart`: `EmptyState({required IconData icon, required String title,
  required String message, String? actionLabel, VoidCallback? onAction})` — ícone 56 +
  CTA verde opcional.
- `error_state.dart`: `ErrorState({required String message, VoidCallback? onRetry})` —
  ícone de erro vermelho + botão "Tentar novamente".
- `offer_limit_banner.dart`: `OfferLimitBanner({required int current})` — banner
  laranja "Restam X ofertas" / "Limite de 15 ofertas atingido".
- `confirm_action_dialog.dart`: `ConfirmActionDialog.show(context, {required String
  title, required String body, String? note}) → Future<bool>` — AlertDialog escuro com
  "Cancelar" (dourado) / "Confirmar" (verde) e nota destacada.
- `offer_card.dart`: `OfferCard({required RankedOffer ranked, required int
  totalOffers, required VoidCallback onSet, required VoidCallback onEdit, required
  VoidCallback onToggle})` — card da oferta: fornecedor + "R$ X · qtd", R$/un
  dourado bold + delta (`DeltaPriceText` ou "sem referência"), pills ATIVA/★ melhor,
  ações com tooltip e alvos 44×44 ("Usar no ticket", "Editar", "Ativar/Desativar");
  inativa com opacidade 0,55; sem swipe-to-delete.
- `audit_entry_tile.dart`: `AuditEntryTile({required PriceAuditLog log})` — ícone
  dourado por tipo (vermelho nas destrutivas `.delete`), `summary` branco 14,
  detalhe "de R$ X para R$ Y" / "novo valor: R$ X" / fornecedor em cinza 12 e hora
  "dd/MM/yyyy · HH:MM" em cinza 11.
- `economy_summary_card.dart`: `EconomySummaryCard({required TicketScenario? scenario,
  required TicketResult ticket, required void Function(String ingredientId)
  onViewOffers})` — quatro estados: economia ("Melhor fornecedor possível" +
  "−R$ X no custo dos ingredientes" + "Nada foi alterado no ticket." + CTA
  "Ver ofertas de {insumo}"), estável ("Fornecedores já estáveis" + "As ofertas
  ativas deste produto já são as melhores entre as cadastradas." + variante para
  poucas ofertas), ainda-prejuízo ("Ainda dá prejuízo com o melhor preço" +
  "−R$ X ainda de prejuízo" + orientação para revisar preço de venda/custos + CTA
  "Ver ofertas") e sem dados ("Sem dados de fornecedores" + CTA "Gerenciar insumos").

#### 4.3.7 Regras de segurança (`firestore.rules`)

- Novo `match /users/{uid}/price_audit_logs/{logId}` inserido **antes** do catch-all
  `match /{document=**}`:

```
match /price_audit_logs/{logId} {
  allow read, create: if request.auth != null && request.auth.uid == uid;
  allow update, delete: if false;
}
```

- `allow read, create` restrito ao dono (a posse é garantida pelo caminho
  `users/{uid}/...`); `allow update, delete: if false` garante o **append-only**.
  A validação dos "campos mínimos" no `create` ficou a cargo do app (o
  `PriceAuditLog.toMap` sempre grava o conjunto completo) — endurecimento por campo
  nas rules é evolução futura. O `match /ingredients/{ingredientId}` existente
  permanece `allow read, write` do dono; a validação dura de `packagePrice > 0` e
  `packageQuantity > 0` é feita no serviço (`upsertOffer`) e no formulário.

### 4.4 Modelo de Dados — `IngredientOffer` embutido no insumo

Decisão do gate mantida no MVP: array `offers[]` no documento do insumo; migração
para subcoleção é caminho de evolução (v1.1+).

Caminho: `users/{uid}/ingredients/{ingredientId}` (documento existente, estendido).

Campos novos persistidos no documento do insumo:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `activeOfferId` | String? | Oferta que alimenta o ticket (escolha manual do usuário); `null` quando a ativa é desativada/removida |
| `offers` | Array | Lista de ofertas (teto duro: **15**) |

Getters sintéticos calculados (não persistidos): `activeOffer`, `pricePerUnit`,
`offersCount`, `lowestActivePricePerUnit`, `bestActiveOffer`.

Estrutura de cada item de `offers[]` (`IngredientOffer` — código final):

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | String | Identificador da oferta (id de documento do Firestore no create) |
| `supplier` | String | Nome do fornecedor (normalizado para upsert) |
| `packagePrice` | double | Preço pago pela embalagem (**> 0**, validação dura no serviço) |
| `packageQuantity` | double | Quantidade da embalagem (**> 0**, validação dura no serviço) |
| `isActive` | bool | Oferta habilitada para comparação; exclusiva da oferta ativa do ticket |
| `source` | String | `manual` (criada pelo usuário) ou `migration` (gerada na migração) |
| `notes` | String | Observações ("Preço cadastrado migrado automaticamente" na migração) |
| `createdAt` | DateTime | Criação — persistida como ISO 8601 string |
| `updatedAt` | DateTime | Última atualização — persistida como ISO 8601 string |

Tipos de data (padrão real do projeto): as datas de insumo e oferta são gravadas como
**ISO 8601 string** no `toMap` e o `fromMap` tolera `Timestamp` do Firestore,
`DateTime` e string ISO. Exceção: `timestamp` do log de auditoria é gravado como
**`FieldValue.serverTimestamp()`** (Firestore Timestamp) para nunca depender do
relógio do cliente. `pricePerUnit` não é armazenado — é getter calculado
(`packagePrice / packageQuantity`), eliminando risco de cache dessincronizado.

Justificativa do MVP em array: 1 leitura, ticket sem join, menor complexidade;
limites conhecidos (~1 MB por documento, concorrência last-write-wins) são
aceitáveis para 3–10 fornecedores típicos, com teto de 15.

### 4.5 Logs de Auditoria de Preços

Caminho: `users/{uid}/price_audit_logs/{logId}` — coleção **append-only** (regras
negam update/delete; só o app cria).

Tabela de eventos auditados (conforme o código final — não existe
`offer.defaultRecalculated`; o evento `offer.delete` foi acrescentado):

| Ação do usuário | `action` do log | `summary` gravado |
|-----------------|-----------------|-------------------|
| Criar insumo | `ingredient.create` | "Insumo {name} criado" |
| Editar insumo | `ingredient.update` | "Insumo {name} atualizado" |
| Excluir insumo | `ingredient.delete` | "Insumo removido" |
| Criar oferta | `offer.create` | "Oferta de {supplier} criada" |
| Editar oferta (upsert) | `offer.update` | "Oferta de {supplier} atualizada" |
| Excluir oferta | `offer.delete` | "Oferta de {supplier} removida" |
| Ativar/desativar oferta | `offer.toggleActive` | "Oferta de {supplier} ativada" / "Oferta de {supplier} desativada" / "Oferta de {supplier} desativada; ticket volta ao preço base" |
| Definir oferta ativa do ticket | `offer.setActive` | "Oferta de {supplier} definida como ativa — X.XX/un" |
| Migração legado → oferta | `migration.legacyToOffer` | "Preço legado de {name} migrado para oferta" |

Campos do documento de log (conforme `PriceAuditLog.toMap(expireAt)`):

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `timestamp` | Timestamp | `FieldValue.serverTimestamp()` (nunca relógio do cliente) |
| `action` | String | Um dos eventos da tabela acima |
| `entityType` | String | `ingredient`, `offer` ou `migration` |
| `entityId` | String | ID do insumo/oferta afetada |
| `supplier` | String? | Fornecedor da oferta, quando aplicável |
| `previousPrice` / `newPrice` | double? | Preço da embalagem antes/depois |
| `pricePerUnit` | double? | Preço/unidade resultante |
| `source` | String | `manual` ou `migration` |
| `summary` | String | Resumo legível em PT-BR (coluna própria na tabela de eventos) |
| `expireAt` | String (ISO 8601) | Retenção: **180 dias** após a criação |

Observações: o campo `uid` do plano inicial não é gravado — a posse é garantida pelo
caminho `users/{uid}/price_audit_logs/` e pelas regras; `entityName` e as quantidades
de embalagem antes/depois não entraram no MVP (o contexto fica no `summary`).

Política de gravação: o log é gravado **no mesmo batch** da mutação do documento
(update do insumo + add do log), garantindo que não exista mudança de preço sem log.
Expiração: o `expireAt` (+180 dias) é gravado em todos os logs para uma futura
política de TTL/limpeza; no MVP o app não exclui nem oculta registros expirados na
leitura (limpeza sob demanda é evolução).

### 4.6 Diagrama Entidade-Relacionamento

A modelagem do banco de dados do CashCtrl após o Sprint 2 mantém a hierarquia com
isolamento por usuário e acrescenta as ofertas embutidas e a coleção de auditoria:

**Figura 2.** Diagrama Entidade-Relacionamento (representação textual) do Firestore
do CashCtrl após o Sprint 2.

```
users (coleção principal)
  |
  |-- {uid} (documento do usuário)
        |
        |-- transactions (subcoleção)      {txId}
        |-- budgets (subcoleção)           {budgetId}
        |-- ingredients (subcoleção)       {ingredientId}
        |     |-- offers[] (array embutido no documento do insumo)
        |-- products (subcoleção)          {productId}
        |-- price_audit_logs (subcoleção)  {logId}   [NOVO — append-only]
```

Relações:

- `products.recipe[].ingredientId` → `ingredients.id` (referência ao insumo),
- `ingredients.activeOfferId` → `ingredients.offers[].id` (oferta que alimenta o
  ticket; a oferta vive embutida no próprio documento, sem join),
- `price_audit_logs.entityId` → insumo/oferta auditada (referência lógica, sem join),
- `transactions.budgetId` → `budgets.id` (referência opcional, pré-existente).

> A versão desenhada da Figura 2 fica pendente de ferramenta gráfica; a representação
> textual acima é a entregue nesta versão.

### 4.7 Esquema do Banco de Dados (Firestore)

Esquema conferido contra o código final (`fromMap`/`toMap` dos models):

```
users = {nome, email, empresa?, cnpj?, segmento?, telefone?, endereco?, photoUrl?}

users/{uid}/transactions/{txId} = {type, category, description, amount, date,
  paymentMethod, recurring, notes?, receiptUrl?, budgetId?}

users/{uid}/budgets/{budgetId} = {category, limit, monthly, createdAt}

users/{uid}/ingredients/{ingredientId} = {name, unit, purchasePrice, packageQuantity,
  createdAt (ISO 8601 string),
  offers: [ {id, supplier, packagePrice, packageQuantity, isActive, source,
             notes, createdAt (ISO), updatedAt (ISO)} ],
  activeOfferId?}                                          [estendido no Sprint 2]

users/{uid}/products/{productId} = {name, description, recipe[], laborCost,
  packagingCost, salePrice, photoUrl?, barcode?, createdAt}

users/{uid}/price_audit_logs/{logId} = {timestamp (serverTimestamp), action,
  entityType, entityId, supplier?, previousPrice?, newPrice?, pricePerUnit?,
  source, summary, expireAt (ISO 8601, +180 dias)}         [NOVO — append-only]
```

## 5. Instalação do CashCtrl

### Requisitos:

- Flutter (Dart SDK ^3.11.5) e Android SDK (plataforma principal; web opcional),
- Projeto Firebase com Authentication (Email/Senha, Google, Facebook), Firestore e
  Storage ativados,
- Arquivo `.env` com as chaves (a partir de `.env.example`; **nunca versionado**),
- CLI Firebase (para aplicar as regras) ou Firebase Console.

### Passo a passo:

**(1.)** Clonar o repositório e entrar na pasta:

```
git clone https://github.com/JoaoVikthor/ctrlcash.git
cd ctrlcash
```

**(2.)** Copiar `.env.example` → `.env` e preencher as chaves do Firebase (o `.env`
está no `.gitignore` e não deve ser versionado):

```
cp .env.example .env
```

**(3.)** **Aplicar as regras do Firestore ANTES de distribuir/executar o app novo**
(política de deploy do Sprint 2). O app atualizado já grava logs em
`price_audit_logs` na primeira mutação; com o catch-all antigo (`allow ... if false`)
a coleção permaneceria bloqueada e todas as mutações de insumo falhariam em batch.
Publicar o `firestore.rules` atualizado (com o match `price_audit_logs`):

```
firebase deploy --only firestore:rules
```

Alternativa manual: colar o conteúdo de `firestore.rules` no Console do Firebase →
Firestore Database → Rules → Publish. **Ordem obrigatória: rules primeiro, app
depois.**

**(4.)** Instalar as dependências:

```
flutter pub get
```

**(5.)** Executar o app:

```
flutter run            (Android/emulador)
flutter run -d chrome  (web, opcional)
```

Observações do ambiente de desenvolvimento:

- A migração dos insumos legados é **lazy e automática** (`migrateLegacyPrice`
  executada pelo próprio app quando um insumo sem `offers` é manipulado) — não exige
  passo manual de dados.
- Verificação estática: neste workspace o `flutter analyze` encerra com crash porque
  o caminho da pasta contém "(Cópia)". Usar **`dart analyze .`** (saída limpa:
  "No issues found!").
- Testes: `flutter test` — suíte 24/24 aprovada (23 testes de lógica em
  `test/offer_comparator_test.dart` + testes de widget).

## 6. Manual do usuário

> As capturas de tela (Figuras 3 a 8) permanecem pendentes por não haver
> device/emulador no ambiente de documentação; cada ponto de captura está marcado.
> Textos entre aspas são a microcopy exata exibida pelo app.

### 6.1 Comparativo de fornecedores

- Acesso: menu lateral > Insumos > ícone de loja no card do insumo (tooltip "Ver
  ofertas" ou toque longo), ou dentro do formulário do insumo nos links "Editar
  oferta" / "Ver todas (N)" / "Ver todas as N ofertas" / botão "Adicionar primeira
  oferta".

> [Figura 3 — captura de tela pendente: lista de insumos com badge "N ofertas" e
> ícone de loja]

- A tela "Ofertas de {insumo}" abre com o card resumo (nome, "Preço por unidade de
  referência: R$ X/un", chips da oferta ativa e da melhor) e a linha de política:
  "Você escolhe qual oferta entra no ticket. O app não troca sozinho."

> [Figura 4 — captura de tela pendente: tela Ofertas de {insumo} com ranking]

- Ranking por preço/unidade ascendente; cada card mostra fornecedor, embalagem,
  R$/un em dourado, delta vs. ativa (verde para economia, vermelho para aumento,
  "sem referência" sem ativa) e os marcadores "ATIVA" e "★ melhor" ("também é a
  melhor" quando coincidem). Ofertas inativas aparecem esmaecidas.
- Adicionar oferta: botão "Adicionar oferta" (CTA inferior) abre o formulário —
  fornecedor, preço da embalagem, quantidade e preview ao vivo de R$/un; mesmo
  fornecedor (nome normalizado) atualiza a oferta existente em vez de duplicar; a
  16ª oferta é bloqueada ("Limite de 15 ofertas por insumo.") e o CTA fica
  desabilitado com o banner "Limite de 15 ofertas atingido" / "Restam X ofertas".
- Ações por card: "Usar no ticket" abre a confirmação "Usar esta oferta no ticket?"
  (com economia/custo por unidade e a nota "Você pode trocar de volta quando quiser.
  O app não altera automaticamente."); "Editar" abre o formulário preenchido (com o
  card "Comparado com a oferta ativa"); "Ativar/Desativar" liga ou desliga a oferta
  para comparação. Ao desativar a oferta ativa, o ticket volta ao preço base do
  insumo. Editar uma oferta nunca apaga as demais.
- Filtros: busca por fornecedor ("Buscar fornecedor…"), chips [Todas, Ativas,
  Inativas, Padrão] ("Padrão" = oferta migrada do preço legado) e o toggle "só com
  economia" (só ofertas inativas mais baratas que a ativa). Sem resultado: "Nenhuma
  oferta corresponde aos filtros." + "Limpar filtros". Embalagens de tamanhos
  diferentes disparam o aviso "Atenção: embalagens de tamanhos diferentes. Compare o
  preço por unidade."
- Insumo legado sem ofertas: card de referência "Preço base do insumo" /
  "Cadastre ofertas para comparar."; sem preço legado: estado vazio "Nenhuma oferta
  cadastrada" com CTA "Adicionar oferta".

### 6.2 Ticket do produto com oferta ativa

- O ticket continua calculando com a oferta ativa de cada insumo (fallback legado
  quando não houver oferta ativa — custo inalterado); o formulário do insumo mostra
  a seção "Fornecedor padrão" com a oferta "Ativa agora" ou o aviso "Nenhuma oferta
  ativa. O ticket usa o preço base deste insumo."

> [Figura 5 — captura de tela pendente: formulário do insumo com seções "Fornecedor
> padrão" e "Ofertas"]

- Após o veredito de lucro/prejuízo, o `EconomySummaryCard` exibe um dos quatro
  estados: economia possível ("Melhor fornecedor possível", "−R$ X no custo dos
  ingredientes", "Nada foi alterado no ticket.", CTA "Ver ofertas de {insumo}"),
  fornecedores estáveis ("Fornecedores já estáveis" / "As ofertas ativas deste
  produto já são as melhores entre as cadastradas."), ainda-prejuízo ("Ainda dá
  prejuízo com o melhor preço" + orientação para revisar preço de venda ou custos) e
  sem dados ("Sem dados de fornecedores", CTA "Gerenciar insumos"). O cartão é
  informativo: **o veredicto, margem e markup do ticket nunca mudam sozinhos.**

> [Figura 6 — captura de tela pendente: ticket com EconomySummaryCard]

### 6.3 Histórico de auditoria

- Acesso: rota nomeada `/audit-logs` (tela "Auditoria", registrada no `main.dart`;
  no MVP não há entrada nova no menu lateral — evolução prevista).

> [Figura 7 — captura de tela pendente: tela Auditoria com timeline]

- Lista somente leitura dos eventos (`ingredient.create/update/delete`,
  `offer.create/update/delete/toggleActive/setActive`, `migration.legacyToOffer`)
  agrupada por dia ("Hoje"/"Ontem"/data), com ícone dourado por tipo (vermelho nas
  exclusões), resumo em PT-BR, detalhe "de R$ X para R$ Y" e hora; toque abre o
  detalhe completo (timestamp, valores anterior → novo, fornecedor).
- Filtros: busca "Buscar por ação, produto ou fornecedor…" e chips [Tudo, Insumos,
  Ofertas, Produtos, Sistema]. Estado vazio: "Nenhuma ação registrada". Registros
  recebem `expireAt` de 180 dias (retenção definida; limpeza automática é evolução).

> [Figura 8 — captura de tela pendente: bottom sheet de detalhe de um log]

## 7. Considerações Finais

O Sprint 2 entregou a Proposta A completa: comparativo de fornecedores por
preço/unidade com ranking, oferta ativa escolhida manualmente alimentando o ticket,
cartão de economia informativo, auditoria append-only de todas as mutações de preço
e migração lazy/idempotente dos insumos legados. A política de deploy ficou definida
e deve ser seguida a cada atualização: **publicar `firestore.rules` antes de
distribuir o app**, porque o app novo grava em `price_audit_logs` desde a primeira
mutação e o batch falharia com as regras antigas.

Critérios de aceite verificados: o comparativo ordena por preço/unidade ascendente;
os marcadores "ATIVA" e "★ melhor" aparecem no comparativo e na lista de insumos;
`packagePrice <= 0` ou `packageQuantity <= 0` são rejeitados (validação no formulário
e `StateError` no serviço); o ticket usa a oferta ativa com o cartão de economia
informativo ("Nada foi alterado no ticket."); upsert por fornecedor normalizado não
duplica; editar/excluir uma oferta não afeta as demais; documento legado sem `offers`
recebe 1 oferta sintética com custo do ticket inalterado; os logs são append-only
(update/delete negados nas regras) e outro UID não lê logs nem ofertas; a ordenação é
estável com empate por centavos (tolerância de 0,005); o formulário bloqueia a 16ª
oferta; `dart analyze .` limpo (o `flutter analyze` crasha apenas por o caminho do
workspace conter "(Cópia)") e sem comentários novos no Dart.

Testes: 23 testes unitários da lógica pura em `test/offer_comparator_test.dart`
cubrindo `rank` (5), `bestOffer` (5), `syntheticLegacyOffer` (1),
`hasDifferentPackageSizes` (4), `bestSupplierScenario` (7) e `deltaUnit` (1) — casos
de ordenação ascendente, delta vs. ativa, `rankAll` com inativas, tolerância de
0,005, arredondamento sem falsa economia, `stillLoss` e linhas `missing`. Suíte
completa do projeto: **24/24 aprovados** (`flutter test`), com `dart analyze .`
reportando "No issues found!".

Próximos passos (v1.1+): migração de `offers[]` para subcoleção quando o volume de
ofertas justificar, endurecimento das rules com validação de campos do log, política
de TTL/limpeza dos registros com `expireAt`, entrada da Auditoria no menu, histórico
completo de preços por insumo, lista de compras por fornecedor, exportação CSV da
auditoria e paginação ("Carregar mais") da tela de auditoria.

---

*Documento gerado a partir do código real do repositório (Sprint 2 — Proposta A).
Pipeline de conversão: Markdown → HTML (estilos BIBLIOTECA) → LibreOffice `soffice
--headless --convert-to docx` → `documentacao/CTRLCASH_SPRINT2_PROPOSTA_A_RT.docx`.*
