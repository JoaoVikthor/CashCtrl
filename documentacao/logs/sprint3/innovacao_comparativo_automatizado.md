# Inovação Sprint 3 — Comparativo de Fornecedores AUTOMATIZADO (evolução da Proposta A)

**Autor:** innovator · **Data:** 2026-10-08 · **Status:** proposta técnica para gate do usuário — **nenhum código alterado**
**Base lida:** Sprint 1 (`RELATORIO_INOVACOES_SPRINT1.md`, `proposta_a_tecnica.md`), Sprint 2 (`HANDOVER.md`, `plano_design_proposta_a.md` §7), `context/decisoes-de-fluxo.md`, `context/erros-a-evitar.md`, código real (`ingredient_offer.dart`, `ingredient.dart`, `price_audit_log.dart`, `offer_comparator.dart`, `firestore_service.dart`, `ingredient_provider.dart`, `ingredient_offers_screen.dart`, `offer_card.dart`, `product_calculator.dart`, `firestore.rules`).

## 0. Contexto e linha de partida

O MVP da Proposta A (Sprint 2) entrega comparação **100% manual**: ofertas aninhadas (teto 15), `activeOfferId` escolhido pelo usuário, logs append-only 180d, `OfferComparator` com rank/best/deltas/cenário. O gate de 07/10 respondeu **(a)** em todas as 5 perguntas — inclusive "oferta ativa = escolha explícita, app nunca troca sozinho" — e o §7 do plano de design colocou "auto-trocar oferta" **fora do escopo**. Este relatório **não pede a revogação daquele gate**: ele desenha a escada que vai do manual (L0, atual) até a automação com consentimento (L3), mantendo o usuário no controle em todos os degraus que chegam ao ticket. Decisão permanente reafirmada: **o app só troca sozinho onde o usuário ligou a troca, com desfazer de 1 toque e registro de auditoria obrigatório.**

Estado verificado no código (relevante para o desenho):
- `IngredientOffer`: `id, supplier, packagePrice, packageQuantity, isActive, source, notes, createdAt, updatedAt` — **sem nenhuma noção de quando o preço foi observado** (updatedAt ≠ "data do preço": editar uma nota barata o frescor).
- `Ingredient.pricePerUnit` → `activeOffer?.pricePerUnit ?? legado` — o ticket **já recalcula ao vivo** por stream.
- `setActiveOffer` faz `get → mutate → batch.set` (não transação) e tem **bug-latente**: `firstWhere(orElse: () => offers.first)` — se o `offerId` não existir, ativa o primeiro do array silenciosamente. **Correção é pré-requisito de qualquer automação.**
- `price_audit_logs`: `expireAt` gravado como **string ISO** (TTL nativo do Firestore exigiria Timestamp) e o stream não filtra vencidos; nada deleta logs (rules proíbem delete inclusive para o dono) → limpeza futura depende de função server-side (Blaze).
- `firestore.rules`: `price_audit_logs` append-only ✅; `ingredients` write irrestrito do dono; **não existe caminho `settings/`** (cai no catch-all bloqueador).

---

## 1. Degraus de automação (L0 → L4)

| Nível | Nome | Mecânica | Quem toca o ticket | Risco de confiança | Esforço |
|---|---|---|---|---|---|
| **L0** | Manual (atual) | Usuário cria/edita/ativa ofertas | Só o usuário | — | entregue |
| **L1** | Preço fresco (sinal passivo) | Campos `priceCapturedAt`/`validityDays`; chips "expirando em N dias"/"preço vencido"; badge ★melhor só entre **frescas**; rank ganha coluna de frescor | Ninguém (só sinaliza) | Zero | Baixo |
| **L2** | Sugestão one-tap | Banner "💡 Trocar para {X}: economia R$Y/un (Z%)"; 1 toque → fluxo atual de `setActiveOffer` com `ConfirmActionDialog` | Usuário confirma | Baixo | Baixo-médio |
| **L3** | Auto-troca com política **opt-in por insumo** | `automation.mode='auto'` só liga após toggle explícito; troca se: candidata fresca ∧ Δ≥`minDeltaPct` ∧ (Δ≥`minDeltaAbs` se configurado) ∧ cooldown vencido ∧ sem edição manual recente; transação com guarda otimista; notifica + loga `offer.autoSwitched`; **undo 1-tap** | App, com consentimento prévio | Médio (mitigado) | Médio |
| **L4** | Auto pleno global | Política default auto para todo o parque | App | Alto | **FORA** |

**Recomendação de MVP: L1+L2 universais + L3 construído, default OFF, opt-in por insumo.** Justificativa: (a) L1/L2 já entregam 80% do valor percebido ("o app trabalha por mim, eu decido") sem tocar na política aprovada no gate; (b) L3 sem consentimento violaria o espírito do gate (a) de 07/10 e a persona (microempresário que precisa **confiar** no número do ticket); (c) L4 ignora que "mais barato" nem sempre é comprável (pedido mínimo, entrega, qualidade, fiado) — dados que o app não tem.

**Regra de ouro transversal:** *manual sempre vence o automático.* Toda interação humana com ofertas reseta/prevalece sobre estado de automação (ver §4).

---

## 2. Fontes de preço "sempre fresco"

### 2.1 Revalidação manual (client-side, custo zero — base do MVP)

- Cada oferta passa a ter `priceCapturedAt` (quando este preço foi observado) e `validityDays` (default global 30, sobrescrevível por oferta/insumo; `0` = nunca vence). `expiresAt` é **derivado**, nunca gravado.
- Ação nova "Preço ainda é este ✓" (na `ingredient_offers_screen` e no card): atualiza `priceCapturedAt = agora` sem mudar valores → log `offer.revalidated`. Fricção mínima: 1 toque por oferta, ou "revalidar todas frescas do insumo".
- Estados derivados (função pura `OfferFreshness.of(offer, now)`): `fresh` (<70% da validade), `expiringSoon` (≥70%, chip laranja), `expired` (chip cinza/laranja "preço de {data} — revalide"). **Nada roda em background**: o vencimento é calculado a cada snapshot do stream com o relógio do dispositivo.

### 2.2 O que exige Blaze (sinalizado para decisão do usuário)

| Recurso | Precisa Blaze? | Nota de custo |
|---|---|---|
| L1/L2/L3 client-side (cálculo, sugestão, auto-troca em transação) | **Não** | Roda no Spark; custo = reads/writes Firestore normais (auto-troca: 1 transação ≈ 2 reads + 2 writes por evento, raro) |
| Notificações **locais** | **Não** | Nova dependência `flutter_local_notifications` (decisão consciente, ver erros-a-evitar §3.2) |
| Cloud Functions Scheduled (varredura diária, push server-side) | **Sim** | Functions exige billing ligado; free tier mensal cobre um cron diário — custo real ≈ R$0, mas **cartão no projeto** |
| Push FCM disparado por agendador server-side | **Sim** (o agendador) | FCM em si é grátis; o trigger precisa de Functions/Scheduler |
| **TTL Firestore** p/ limpar `price_audit_logs` vencidos | **Sim** | Deletes de TTL **não** estão na cota gratuita; e exige `expireAt` como **Timestamp** (hoje é string ISO → migração de tipo) |
| OCR de nota fiscal **on-device** (ML Kit) | **Não** | Processamento no aparelho, grátis; peso de APK ↑ |
| OCR server-side (Cloud Vision) / APIs de preço de terceiros | **Sim** | Chamadas externas de back-end |
| ⚠️ Cloud Storage (fotos já usadas pelo app) | Desde fev/2026, criar/manter bucket exige billing | **Verificar plano atual do projeto antes de dimensionar o resto** — se já usa Storage em produção, provavelmente já está no Blaze |

### 2.3 Futuro (F3): ingestion

- **OCR de nota fiscal:** foto → ML Kit Document Text Recognition on-device → parser heurístico (fornecedor, data, item, preço, qtd) → **form de revisão pré-aprovado** (o usuário confirma cada campo; nada entra no ticket sem revisão) → oferta com `source='ocr'`, `priceCapturedAt=data_da_nota`.
- **Importação CSV** de atacado — trivial, sem Blaze.
- **APIs de preço externas / scraping:** fora (custo, jurídico, irrelevante para o perfil de compra local do público).

---

## 3. Modelo de dados (proposto)

### 3.1 `IngredientOffer` — campos novos (pseudocódigo Dart)

```
class IngredientOffer {
  // ... campos existentes (id, supplier, packagePrice, packageQuantity,
  //     isActive, source, notes, createdAt, updatedAt)
  DateTime  priceCapturedAt;   // obrigatório; migração := updatedAt
  int       validityDays;      // default 30; 0 = nunca vence
  DateTime? lastCheckedAt;     // última revalidação "preço ainda é este"
  bool      excludeFromAuto;   // pinar oferta fora da automação (default false)

  DateTime get expiresAt => priceCapturedAt.add(Duration(days: validityDays));
  OfferFreshness freshnessAt(DateTime now);  // derivado — NUNCA gravar status
}
```

**Decisão: `status` derivado, não armazenado.** Um campo `status` gravado exigiria cron para virar flag (Blaze) e criaria divergência multi-device; derivar de `priceCapturedAt+validityDays` dá o mesmo resultado em qualquer aparelho, offline, com custo zero.

### 3.2 `Ingredient` — política + estado de automação por insumo

```
class IngredientAutomationPolicy {   // map 'automation' no doc do insumo
  String mode;            // 'manual' (default) | 'suggest' | 'auto'
  double minDeltaPct;     // default 5.0   (% mais barato que a ativa p/ agir)
  double minDeltaAbs;     // default 0.00  (R$/un; 0 = desconsiderar)
  int    cooldownDays;    // default 7     (mín. entre auto-trocas do insumo)
  DateTime? lastAutoSwitchAt;
  String?  lastAutoOfferId;
  String?  lastManualChangeAt;   // carimbada em toda ação humana
  // dedupe de UI/logs:
  String?  suggestionShownKey;   // "<offerId>@<priceCapturedAt ISO>"
  String?  expiredLoggedKey;
}
```

Array `offers[]` aninhado (teto 15) **permanece** — decisão do gate Sprint 2; automação não muda o storage. Se um dia passar de ~15 ofertas ou precisar de histórico, migra-se para subcoleção (decisão independente, já adiada na Sprint 1).

### 3.3 Defaults globais — doc novo `users/{uid}/settings/automation`

```
{ defaultMode:'manual', defaultValidityDays:30, defaultMinDeltaPct:5.0,
  defaultMinDeltaAbs:0.0, defaultCooldownDays:7, notifyExpiringSoon:true,
  updatedAt }
```

Precedência: **oferta > insumo > settings globais > constantes do app.** Escrita apenas pelo dono (rules §5). Uma tela de "Automação de preços" dentro de `/settings` edita os defaults.

### 3.4 Novas actions de auditoria (append-only, mesmas rules atuais)

| Action | Quando | Campos extras (`trigger`, `previousOfferId`, `newOfferId`, `deltaPct`, `deltaAbs`, `reason`, `ruleSnapshot`) |
|---|---|---|
| `offer.revalidated` | toque em "preço ainda é este" | trigger='manual' |
| `price.expired` | 1ª vez que uma oferta **ativa ou melhor** vira vencida no aparelho (dedupe por `expiredLoggedKey`) | reason PT-BR |
| `offer.suggestionShown` | sugestão L2 exibida **1× por (offerId, priceCapturedAt)** — dedupe obrigatório p/ não spammar cota de escrita | deltaPct/deltaAbs |
| `offer.autoSwitched` | L3: transação de troca com sucesso | previousOfferId/newOfferId, ruleSnapshot, trigger='auto' |
| `offer.autoReverted` | undo do autoSwitched | trigger='manual' |
| `automation.policyChanged` | liga/desliga/ajusta modo (insumo ou settings globais) | anterior→novo |

`PriceAuditLog` ganha os campos opcionais acima + `trigger` default `'manual'` (legado continua lendo). **`expireAt` passa a ser gravado como `Timestamp`** (habilita TTL futuro; `fromMap` já tolera os dois formatos). Ações humanas existentes (`offer.setActive` etc.) ganham `trigger='suggestion'` quando vierem do fluxo L2.

---

## 4. Triggers no cliente (custo zero) e multi-device

### 4.1 Pontos de avaliação (nunca há background job no MVP)

| Gatilho | O que roda | Custo |
|---|---|---|
| Snapshot do `ingredientsStream` (já vivo) | recomputa frescor + rank em memória; chips L1 | read já pago |
| `AppLifecycleState.resumed` | reavalia sugestões L2 e política L3 dos insumos `mode='auto'` | 0 |
| Abertura de `ingredient_offers_screen` / `product_detail_screen` | banner L2; chip de proveniência | 0 |
| Após create/edit/revalidate de oferta | reavalia imediatamente aquele insumo | 0 |

Debounce: máx. 1 avaliação/insumo a cada 60s; L3 dispara no máximo 1 transação por insumo por avaliação.

### 4.2 Auto-troca segura (L3) — algoritmo

```
evaluateAutoSwitch(ing, settings, now):
  se ing.automation.mode != 'auto' → aborta
  se agora - ing.automation.lastManualChangeAt < 12h → aborta   // manual vence
  se agora - lastAutoSwitchAt < cooldownDays → aborta
  candidatas = ativas ∧ frescas ∧ !excludeFromAuto ∧ packageQuantity>0
  best = menor pricePerUnit entre candidatas
  ativa = ing.activeOffer
  se best==null ∥ ativa==null ∥ best.id==ativa.id → aborta
  deltaPct = (ativa.ppu - best.ppu)/ativa.ppu*100
  deltaAbs = ativa.ppu - best.ppu
  se !(deltaPct >= minDeltaPct ∥ (minDeltaAbs>0 ∧ deltaAbs >= minDeltaAbs)) → aborta
  runTransaction:                            // NÃO batch: transação
    re-lê doc; se activeOfferId != id esperado OU updatedAt mudou desde a
      avaliação → ABORTA (dispositivo/humano ganhou a corrida)
    escreve: offers[], activeOfferId=best.id,
             automation.{lastAutoSwitchAt, lastAutoOfferId}
    + log offer.autoSwitched (mesma transação)
  → notificação local + banner "Troquei {ing}: {A}→{B}, economia R$X. [Desfazer]"
```

Undo = `setActiveOffer(previousOfferId)` com `trigger='manual'` + log `offer.autoReverted` + carimbo `lastManualChangeAt` (o que também reativa o cooldown).

### 4.3 Multi-device: como mitigar a corrida

- **Problema real:** array aninhado + `merge:true` = last-write-wins no array inteiro; duas telas abertas podem apagar a edição uma da outra (risco já documentado na Sprint 1, tolerado no MVP).
- **Mitigações:** (1) toda mutação estrutural passa de `batch` para **`runTransaction` com leitura condicional** (guarda `expectedActiveOfferId` + hash leve do array); (2) cooldown + carimbo `lastManualChangeAt` suprimem ping-pong entre aparelhos; (3) auto-troca só roda **online** (offline apenas sinaliza L1, nunca age); (4) máx. 1 auto-troca por insumo por dia por aparelho.
- **Aceito (risco documentado):** LWW residual em edições manuais simultâneas de ofertas — mesmo comportamento do MVP atual; mitigação plena exigiria subcoleção (adiada no gate).

---

## 5. Regras Firestore necessárias

```
// dentro de match /users/{uid} — SEMPRE antes do catch-all, deploy antes do app

match /settings/{settingsId} {
  allow read: if auth.uid == uid;
  allow write: if auth.uid == uid
    && settingsId == 'automation'
    && request.resource.data.defaultMode in ['manual','suggest','auto'];
}

match /ingredients/{ingredientId} {
  allow read: if auth.uid == uid;
  allow write: if auth.uid == uid
    && (!('offers' in request.resource.data)
        || request.resource.data.offers.size() <= 15)
    // ofertas com packagePrice>0 && packageQuantity>0 (helper list filter)
    // && não existe mais de 1 isActive=true
    && (!('automation' in request.resource.data)
        || request.resource.data.automation.mode in ['manual','suggest','auto']);
}

match /price_audit_logs/{logId} {   // INALTERADO no essencial
  allow read, create: if auth.uid == uid;
  allow update, delete: if false;    // append-only (limpeza server-side exige Admin SDK / Blaze)
}
```

Notas: (a) validação de `ingredients` é **reforço**, não quebra-compatibilidade; (b) se preferir MVP mais magro, a versão de `ingredients` pode entrar só em F1.5; (c) deploy `firebase deploy --only firestore:rules` continua sendo pré-release obrigatório.

---

## 6. Integração com o ticket (`ProductCalculator`)

**Princípio: `ProductCalculator` não muda** — a automação age **sobre os dados**, o getter `Ingredient.pricePerUnit` já resolve o resto. Consequência honesta: auto-troca **recalcula o ticket imediatamente** — e isso precisa ser **visível, nunca silencioso**:

1. **Chip de proveniência** no veredito: quando a oferta ativa de algum insumo da ficha veio de automação, exibe sob o veredito: `⚙ custo de {insumo} via oferta automática de {fornecedor} ({data})` + link `/audit-logs`. Manual: nenhum chip (status quo).
2. **Banner de recálculo (≤7 dias):** se há `offer.autoSwitched` recente em insumo da receita: "O custo deste produto mudou por automação: {A}→{B}, {−R$X} no custo. [Ver] [Desfazer]". Nunca reescreve `TicketResult`; só explica o número ao vivo.
3. **Honestidade preservada:** prejuízo continua vermelho; auto-troca **só desce custo** (nunca sobe — guardada no algoritmo §4.2); se mesmo com melhor preço der prejuízo, mantém-se o "Caso C" do `EconomySummaryCard`.
4. **`EconomySummaryCard` vira L2:** hoje informativo; passa a ter botão "Aplicar economia (1 toque)" por linha do cenário (confirmação + log com `trigger='suggestion'`).
5. **Frescor no ticket:** linha cujo preço ativo está `expired` ganha aviso laranja "⚠ preço desatualizado ({data}) — revalide"; microcopy: "pode estar otimista/pessimista".

---

## 7. Telas alteradas (resumo — protótipo HTML antes, regra de 07/10)

| Tela | Mudança |
|---|---|
| `offer_form_screen` | + "Data do preço" (default hoje), + "Vale por N dias" (default do settings), + toggle "excluir da automação" |
| `ingredient_offers_screen` | + chips de frescor no `OfferCard`; + banner L2 "💡 Trocar para X · economia R$Y (Z%)" com one-tap; + "revalidar todas"; + card de undo pós-auto |
| `ingredient_form_screen` | + seção "Automação deste insumo": [Manual \| Sugerir \| Auto] com defaults e explicação honesta |
| `settings/` (nova sub-tela) | "Automação de preços" — defaults globais + atalho "ligar auto em insumos com sugestões aceitas" |
| `product_detail_screen` | chip de proveniência + banner de recálculo (§6) |
| `audit_logs_screen` | filtros novos; ícones por tipo; sheet mostra `ruleSnapshot` |
| `ingredients_screen` | badge de oferta vencida no card do insumo (ponto laranja) |

Widgets novos mínimos: `freshness_chip`, `suggestion_banner`, `automation_mode_selector`, `undo_auto_switch_card`. Paleta/tokens intocados.

---

## 8. Rollout, esforço e o que fica FORA

| Fase | Escopo | Blaze? | Esforço |
|---|---|---|---|
| **F0 — pré-requisitos** | fix `setActiveOffer` (orElse silencioso); `expireAt`→Timestamp; protótipos HTML | não | 0,5–1 d |
| **F1 — L1+L2 client-side** | campos de frescor + comparator estendido (`rankFrescas`, `bestFresh`, `suggestionFor`), chips, banner one-tap, `offer.revalidated`, settings doc + rules, logs dedup | **não** | 4–6 d |
| **F1.5 — L3 opt-in** | política por insumo, `evaluateAutoSwitch` em transação, undo, `offer.autoSwitched/Reverted/policyChanged`, seção no form, chips de proveniência no ticket | **não** | 3–4 d |
| **F2 — notificação** | (a) local (`flutter_local_notifications`): Spark; (b) push server-side agendado | (a) não / (b) sim | (a) 2–3 d / (b) +3–5 d |
| **F3 — fontes** | OCR on-device ML Kit com revisão pré-cadastro; import CSV; TTL de logs (função agendada, **Blaze**) | OCR local não; TTL/Vision sim | 4–6 d |
| **MVP recomendado** | **F0+F1+F1.5** | **zero** | **≈ 7–10 d** |

**FORA (explícito):** L4 auto pleno; catálogo de fornecedores compartilhado entre usuários (quebra RN02 como feature social); scraping/APIs externas; negociação/pedido direto ao fornecedor; migração para subcoleção `offers/` (só se/quando o teto 15 apertar); mudança de paleta/logo.

---

## 9. Riscos abertos (para o advisor criticar)

1. **Confiança vs. mágica:** L3 ainda toca o número central do app (o veredito). O desenho aposta em opt-in + undo + proveniência; é suficiente? Alternativa: L3 só rebaixa a ativa vencida para o preço legado (nunca escolhe fornecedor novo) — mais conservador, menos útil.
2. **Corrida LWW no array:** transação client-side resolve auto-vs-manual, mas **não** resolve duas edições manuais simultâneas em aparelhos diferentes. Aceitar ou puxar migração p/ subcoleção para F2?
3. **Cota de escrita Spark:** `price.expired`/`suggestionShown` dedupados por chave no doc do insumo — dedupe no doc (1 write extra) ou em memória (pode repetir 1×/dia)? Recomendo doc.
4. **`expireAt` Timestamp:** logs já gravados como string nunca serão TTL-ados. Convive-se ou função de backfill (Blaze)?
5. **Relógio do cliente:** vencimento usa `DateTime.now()` do aparelho; margem de 2 dias no L3 cobre drift comum — aceitável?
6. **"Mais barato ≠ melhor":** sem dados de confiabilidade de fornecedor, L3 pode trocar para quem não entrega. `excludeFromAuto` é o paliativo; vale um rating manual ★ do fornecedor?
7. **Plano do projeto:** se ainda é Spark, F2b/F3(TTL) ficam bloqueados; se já é Blaze (Storage fev/2026 sugere), o custo marginal é ~0 — **confirmar antes de prometer push**.
8. **Gate de 07/10 ("a"):** L1/L2 não o violam; L3 o estende por consentimento. Recomendo aprovar F0+F1 agora e decidir L3 com dados de aceite de L2 na prática.

*Nenhuma alteração em `lib/`, `android/`, `firestore.rules` ou `.env`. Verificações de código citadas refletem o worktree da Sprint 2 (`dart analyze` limpo, 24/24 testes, rules ainda não deployadas).*
