# Crítica — Comparação de Preços de Fornecedores Automatizada (Sprint 3)
**Autor:** innovator-advisor · **Data:** 2026-10-08 · **Escopo:** leitura do repositório — nenhuma alteração de código
**Base:** RELATORIO_INOVACOES_SPRINT1.md · HANDOVER.md (sprint2) · plano_design_proposta_a.md §7 · metadata sprint2 · código (`offer_comparator.dart`, `firestore_service.dart`, `ingredient_offer.dart`, `ingredient.dart`, `product_calculator.dart`, `firestore.rules`)

---

## Veredito por dimensão

| Dimensão | Veredito | Motivo-síntese |
|---|---|---|
| **Risco** | Reprovado p/ auto-troca (L3/L4) no estado atual · Aprovado c/ ressalvas p/ sugestão one-tap (L2) | Promessa de produto documentada em 4 pontos diz "o app não troca sozinho"; dado de oferta não tem frescor (`validUntil`/`confirmedAt` inexistentes) |
| **UX** | Aprovado c/ ressalvas (L2) | Usuário (padaria/lanchonete) quer decisão no momento certo, não dashboard; o momento natural de decisão é o pós-cadastro da oferta — L2 o captura |
| **Migração** | Aprovado | Migração lazy da Sprint 2 é idempotente e não conflita — desde que automação nunca trate oferta `source: migration` como elegível sem reconfirmação |
| **Complexidade** | L2: baixa · L3: média-alta · L4: alta | L2 reusa `setActiveOffer` + `ConfirmActionDialog` existentes; L3 exige doc de settings + rules + engine de guardrails; L4 exige Blaze |
| **Custo** | L2: zero · L3: baixo · L4: reprovado | L4 (Functions/Scheduler/FCM) exige plano Blaze = "feature que gera boleto" para app de pequeno negócio em Spark |

**Veredito geral: Aprovado com ressalvas.** MVP = **L2 (sugestão one-tap)**. L3 (auto opt-in com guardrails) apenas v2, condicionado às ressalvas vinculantes. L4 cortado.

---

## Achados críticos

### 1. CRÍTICO — Quebra de promessa de produto documentada
A política "o app NUNCA troca sozinho" não é um comentário solto: está no plano de design (§0 regra permanente, §3.2 microcopy, §3.3 note do diálogo de ativação, §5 microcopy fixa), no HANDOVER ("app nunca auto-troca"), no gate aprovado pelo usuário em 07/10 e no veredito da Sprint 1 (ressalva 1). Auto-troca sem mudança explícita de política **viola contrato com o usuário em 4 pontos de UI simultaneamente** — e o pior momento para corromper confiança é exatamente o ticket, que é o coração do app (veredito "DÁ LUCRO/DÁ PREJUÍZO" é a âncora do produto).
**Recomendação:** MVP não altera a política. L2 mantém a promessa intacta ("você decide, o app facilita"). Se um dia houver L3, a microcopy muda para "o app só troca quando você autorizar" — e TODOS os 4 pontos + overview.md + HANDOVER precisam ser atualizados no mesmo commit.

### 2. CRÍTICO — Automação sobre dado sem frescor é pior que manual
`IngredientOffer` tem apenas `createdAt`/`updatedAt`. Não existe `validUntil` nem `confirmedAt`. O `bestOffer()` filtra `packageQuantity <= 0` mas não idade do preço. Uma automação que troca para "a mais barata" pode trocar para um preço digitado há 8 meses e esquecido — o usuário manual ao menos olha a tela na hora. Dado velho + decisão automática = ticket errado com aparência de verdade.
**Recomendação:** MVP usa `updatedAt` como proxy de frescor (oferta com updatedAt > 30d → chip laranja "confirmar preço" na ativa; oferta stale nunca é elegível a sugestão). v2 adiciona `confirmedAt`/`validUntil` de verdade com decaimento de confiança.

### 3. ALTO — Corrida multi-device amplificada por automação
`upsertOffer`, `setActiveOffer`, `toggleOfferActive` e `deleteOffer` fazem read-modify-write do **array inteiro** (`get` → batch `set` com merge). Dois devices concurrentes = last-write-wins sobre o array todo: uma oferta criada no device B pode ser apagada pelo device A. Isso já existe no fluxo manual; automação aumenta a frequência de escritas e a janela de corrida.
**Recomendação:** qualquer lógica de automação roda **somente em foreground, com stream fresco** (nunca em background/sync). v1.1: subcoleção + transação. Não "consertar" isso no MVP — apenas não amplificar.

### 4. ALTO — L4 (server-side) é "feature que gera boleto"
Functions + Scheduler + FCM exigem plano Blaze. O app opera em Spark. E há um insight estrutural que elimina a necessidade: **o preço de uma oferta só muda quando o próprio usuário digita o preço novo** — não há integração com nota fiscal nem API de fornecedor. O gatilho de mudança é sempre uma escrita do cliente. Servidor não tem informação que o app não tenha.
**Recomendação:** L4 cortado do roadmap até existir fonte de preço externa. Nada de Scheduler para "verificar preços" que ninguém atualizou.

### 5. ALTO — Rules pendentes de deploy + catch-all
A regra de `price_audit_logs` existe só localmente (metadata §4.1: "firebase deploy NÃO executado"). Qualquer doc novo de settings de automação (`users/{uid}/settings/automation`) precisa de match **antes do catch-all** — senão a feature nasce bloqueada, ou pior, alguém "testa" afrouxando o catch-all.
**Recomendação:** deploy das rules da Sprint 2 é pré-requisito de qualquer Sprint 3. Doc de settings só entra com match próprio + deploy antes do app.

### 6. MÉDIO — Volatilidade silenciosa do ticket (o que a auto-troca realmente muda)
`ProductCalculator.calculate` lê `ing.pricePerUnit` → `activeOffer`. O `EconomySummaryCard` é paralelo (não altera `TicketResult`) — design correto da Sprint 2. Auto-troca altera o `TicketResult` real: lucro, margem, markup e veredito. Nota técnica: trocar para mais barato **só aumenta lucro** no modelo atual (salePrice é fixo), então o perigo não é prejuízo silencioso — é (a) ticket que não bate com a nota fiscal real, (b) margem que vira número móvel entre aberturas de app, (c) erro de digitação propagado silenciosamente para todos os produtos que usam o insumo.
**Recomendação (guardrails para L3, se um dia):** Δ mínimo por linha (≥ max(R$ 0,05; 1% do custo da linha)), cooldown de 7 dias por insumo, cap de 10 trocas/mês, log `source: automation`, badge "AUTO" na auditoria, undo em 1 toque.

### 7. MÉDIO — Oferta de migração envenenaria o decaimento de confiança
`migrateLegacyPrice` cria a oferta sintética com `createdAt = now` (ok), mas `syntheticLegacyOffer` em `offer_comparator.dart` usa `ing.createdAt` — que pode ser de meses atrás. Se automação usar idade como critério, a própria oferta ativa migrada nasceria "stale" no dia 1.
**Recomendação:** critério de frescor sempre por `updatedAt` real do doc, nunca por `ing.createdAt`; migração marca a data de confirmação como a data da migração.

### 8. MÉDIO — Fallback silencioso em `setActiveOffer`
`offers.firstWhere((o) => o.id == offerId, orElse: () => offers.first)` — se o `offerId` não existir, troca para a primeira oferta **sem erro e sem avisar**. Para fluxo manual é tolerável; para qualquer lógica futura de automação é uma troca errada silenciosa.
**Recomendação:** automação (L2/L3) nunca depende desse fallback; validar existência antes e tratar. Corrigir o fallback é v1.1 (mudança de comportamento testado).

### 9. BAIXO — Logs: PII e forjabilidade
Logs append-only já cobertos por rules (`update, delete: if false`). Corpo do log não deve repetir uid (o path já o contém) nem dados sensíveis — summaries PT-BR atuais estão ok. Log escrito pelo cliente é forjável pelo próprio dono — aceitável no MVP (dado é dele), documentar como limitação conhecida.

---

## Formas recomendadas — crítica de todas as variantes

| Nível | O que é | Crítica | Veredito |
|---|---|---|---|
| **L0 (atual)** | Manual puro + EconomySummaryCard no ticket | Seguro, mas a economia só aparece quando o usuário abre o ticket — o momento de decisão (cadastro da oferta) é desperdiçado | Insuficiente sozinho |
| **L1** | Alerta passivo (badge/chip) quando há economia disponível | Barato, mas ainda exige navegação até `/ingredient-offers` para agir | Base do L2 |
| **L2 — RECOMENDADO MVP** | **Sugestão one-tap contextual**: ao salvar/editar oferta que passa a ser a melhor, dialog "Esta agora é a melhor oferta. Usar no ticket? (−R$ X/un)" → `setActiveOffer` existente → SnackBar com **Desfazer** | Captura ~90% do valor da auto-troca com ~10% do risco: zero infra nova, zero política nova, decisão continua sendo do usuário. Reusa `ConfirmActionDialog`, `setActiveOffer`, logs `offer.setActive` — tudo já testado | **Aprovado** |
| **L3** | Auto opt-in com guardrails (Δ mínimo, cooldown, cap mensal, badge AUTO, undo) | Exige doc de settings + rules novas + engine de elegibilidade + mudança de microcopy em 4 pontos. Valor marginal sobre L2 é pequeno (o usuário já está digitando o preço — um toque a mais é fricção mínima) | **v2**, condicionado às ressalvas vinculantes |
| **L4** | Server-side (Functions + Scheduler + FCM) | Blaze; gatilho de dados é sempre ação do próprio usuário; custo variável imprevisível | **Reprovado/cortado** |

**Narrativa de venda honesta (recomendada):** "Você cadastra o preço, o app mostra na hora se ele é o melhor e troca com um toque — e nunca mexe no seu ticket sem você saber." NÃO vender "economia garantida sem esforço": preço cadastrado ≠ preço real da próxima compra, e o app não tem como saber disponibilidade do fornecedor.

---

## Entra no MVP seguro / Corta / v2

| Entra no MVP seguro | Corta | v2 |
|---|---|---|
| L2: sugestão one-tap pós-save/edição de oferta melhor | L4 inteiro (Functions, Scheduler, FCM, Blaze) | L3 opt-in com guardrails completos |
| Undo via SnackBar (reversão = `setActiveOffer` de volta + log novo) | Auto-troca em background/sync | Doc `settings/automation` + rules próprias |
| Chip laranja "confirmar preço" quando ativa com `updatedAt` > 30d | `validUntil`/`confirmedAt` como campo obrigatório agora | Campos de frescor reais + decaimento de confiança |
| Oferta stale nunca elegível a sugestão | Notificação push de economia | Subcoleção `offers` v1.1 + transação |
| Log `offer.setActive` existente (sem action novo) | Action de log novo no MVP | Action `offer.autoSwitch` + badge "AUTO" |
| Migração lazy inalterada | Integração com nota fiscal/API | Histórico de preços por oferta |

---

## Ressalvas vinculantes (condições para aprovar QUALQUER auto-troca, hoje ou na v2)

1. **Opt-in explícito**, default OFF, em tela própria — nunca bundling em outro fluxo.
2. **Elegibilidade:** oferta-alvo ativa com frescor ≤ 30d; oferta `source: migration` só elegível após reconfirmação.
3. **Δ mínimo:** economia por linha ≥ max(R$ 0,05; 1% do custo da linha) — sem churn de trocas por centavos.
4. **Cooldown 7 dias por insumo + cap 10 trocas/mês**, persistidos em doc com rules próprias deployadas antes do app.
5. **Log append-only** com `source: automation`, `action: offer.autoSwitch`, oldPrice/newPrice/pricePerUnit + badge "AUTO" na UI de auditoria.
6. **Undo em 1 toque**, disponível no mínimo durante a sessão.
7. **Oferta ativa expirada NUNCA é rebaixada automaticamente** — só alerta (degradar avisando, não decidindo).
8. **Microcopy atualizada nos 4 pontos** do plano de design + overview.md + HANDOVER no mesmo commit da mudança de política.
9. **Automação foreground-only** com stream fresco; nunca em background.
10. **Lógica de elegibilidade 100% pura** (em `offer_comparator.dart` ou novo util) com testes — zero lógica de decisão dentro de widget/service.

---

## Simplificações para o MVP

- L2 puro: reusa `ConfirmActionDialog`, `setActiveOffer`, `DeltaPriceText`, logs existentes — nenhuma dependência nova, nenhuma rota nova, nenhuma rule nova.
- Frescor por `updatedAt` (proxy) em vez de campo novo no model — evita migração de schema.
- Undo = chamada reversa a `setActiveOffer` (gera log novo, append-only preservado) em vez de mecanismo de transação.
- Sugestão disparada só em dois momentos: pós-criação e pós-edição de oferta (não em stream listener genérico — evita re-disparo em rebuild).

## Perigos de implementação (fluxos que costumam quebrar neste projeto)

- `updateIngredient` remove `offers`/`activeOfferId` do map antes do merge — qualquer fluxo novo NÃO pode passar por ele para tocar ofertas.
- Fallback silencioso `orElse: () => offers.first` em `setActiveOffer` (achado 8).
- `syntheticLegacyOffer` usa `ing.createdAt` como timestamp (achado 7).
- `flutter analyze` crasha com o caminho "(Cópia)" — usar `dart analyze .`.
- Deploy das rules antes de rodar/distribuir o app (pendência em aberto da Sprint 2).
- Zero dependências novas; paleta/logo intocáveis; zero comentários novos.

## Perguntas que o usuário deve responder

1. Aceita **L2 (sugestão one-tap pós-cadastro)** como teto do MVP, mantendo a promessa "o app não troca sozinho"?
2. Frescor: **30 dias** desde `updatedAt` é o prazo razoável para o chip "confirmar preço"?
3. O **deploy das rules da Sprint 2** foi executado? (bloqueador operacional de qualquer Sprint 3)
4. Se L3 vier na v2: opt-in **global** ou **por insumo**?
5. Undo via SnackBar in-app é suficiente, ou espera reversão pelo histórico de auditoria?

## Check-list de aceite para o implementer

- [ ] Salvar/editar oferta que se torna a melhor exibe sugestão one-tap; recusar deixa ticket inalterado (testável: ticket idêntico antes/depois de recusar).
- [ ] Aceitar sugestão chama `setActiveOffer` e gera log `offer.setActive` com summary, supplier, pricePerUnit e timestamp.
- [ ] Undo restaura a oferta anterior e gera **log novo** (nenhum update/delete em `price_audit_logs`).
- [ ] Oferta com `updatedAt` > 30d nunca recebe sugestão; ativa stale exibe chip "confirmar preço".
- [ ] Oferta `source: migration` sem reconfirmação nunca recebe sugestão.
- [ ] Nenhuma troca ocorre sem toque do usuário (nenhum listener de stream dispara troca).
- [ ] `dart analyze .` limpo · `flutter test` verde (testes novos para elegibilidade) · zero dependências novas · paleta intacta.
- [ ] Microcopy "o app não troca sozinho" preservada em todos os pontos do plano de design.
