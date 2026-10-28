# Relatório de Inovações — CashCtrl (Sprint 1)

**Gerado em:** conselheiro de inovações (análise paralela)  
**Escopo:** leitura do repositório — nenhuma alteração de código  
**Pendência:** aprovação humana antes do Sprint 2 (implementação)

---

## Diagnóstico rápido

- Insumo hoje: **1 preço** (`purchasePrice` + `packageQuantity` → `pricePerUnit`)
- Ticket lê preço ao vivo via `ProductCalculator` + `IngredientProvider.asMap`
- Firestore: `users/{uid}/{transactions,budgets,ingredients,products}` com catch-all bloqueador
- **Não existe** fornecedor, histórico de preço nem logs de auditoria

---

## 1) Ideias priorizadas

| # | Ideia | Valor | Complexidade |
|---|-------|-------|--------------|
| 1 | **Proposta A — Comparação por fornecedor** | Decisão de compra + margem real | Média |
| 2 | Histórico de preços + alerta de variação | Antecipa quebra de margem | Média |
| 3 | Simulação de sensibilidade de lucro | Ticket vira ferramenta de decisão | Baixa |
| 4 | Lista de compras por fornecedor | Ação diária de compra | Média-alta |
| 5 | Simulador de novo preço de venda (break-even) | Evita vender no prejuízo | Baixa |
| 6 | Duplicar produto / copiar ficha | Menos fricção no cadastro | Baixa |
| 7 | Alertas de margem baixa no dashboard | Retenção do usuário | Média |
| 8 | Backup/export CSV | Portabilidade + suporte | Baixa-média |

**Ordem sugerida:** 1 → 3 → 6 → 2 → 4 → 5 → 7 → 8

---

## 2) Proposta A — Comparação de fornecedores (detalhe)

### Modelo recomendado (consenso dos 2 conselheiros com ressalvas)

**Preferência do innovator:** subcoleção  
`users/{uid}/ingredients/{ingredientId}/offers/{offerId}`  
+ `users/{uid}/auditLogs/{logId}` (ou `price_audit_logs`)

**Ressalva do advisor:** MVP pode usar **array `offers[]` no doc do insumo** se forem poucos fornecedores (típico 3–10), com:
- `activeOfferId` (oferta que alimenta o ticket)
- `lowestPricePerUnit` / `bestSupplier` (cache)
- teto duro (ex.: 15 ofertas) com erro claro

| Abordagem | Prós | Contras |
|-----------|------|---------|
| Array no doc | 1 leitura, ticket sem join, menos complexidade MVP | Limite ~1MB; concorrência last-write-wins; payload em stream |
| Subcoleção | Escala, concorrência segura, histórico futuro | Rules novas, mais leituras, mais código |

**Recomendação executiva para MVP:** array + campos sintéticos + teto 15 + upsert por fornecedor  
**v1.1+:** migrar p/ subcoleção se histórico/multi-device exigir

### Campos da oferta (essência)

- `id`, `supplier`, `packagePrice`, `packageQuantity`
- `unit` (herda do insumo)
- `pricePerUnitCache` = packagePrice / packageQuantity
- `isActive`, `isDefault` / `activeOfferId` no insumo
- `source` (`manual`|`migration`)
- `notes`, `createdAt`, `updatedAt`
- soft delete opcional

### Cálculo

```
pricePerUnit = packagePrice / packageQuantity
ranking = ofertas ativas ordenadas por pricePerUnit ASC
deltaLinha = (preçoUsadoNoTicket - melhorPreço) * qty
economiaTicket = Σ deltaLinha
```

- Ticket usa **oferta ativa** (explícita), **nunca** troca sozinho p/ a mais barata
- Exibe alerta: “Poderia economizar R$ X usando {fornecedor}”
- Se ainda assim dá prejuízo, avisa (não vende economia como solução mágica)

### Telas

| Tela | Ação |
|------|------|
| `ingredients_screen` | badge “N ofertas”, preço ativo, chip “★ melhor” |
| `ingredient_form` | seção fornecedor padrão + gerenciar ofertas |
| **`ingredient_offers_screen` (nova)** | ranking, Δ, filtros, CTA adicionar |
| **`offer_form_screen` (nova)** | fornecedor, preço embalagem, qtd, preview R$/un |
| `product_detail_screen` | cenário melhor fornecedor + economia |
| **`audit_logs_screen` (nova)** | histórico de auditoria (leitura) |

### Filtros (MVP)

- Status: ativas/inativas/padrão
- Busca por fornecedor
- Ordenação: mais barata (preço/un) — padrão
- Toggle: só Δ econômico
- Aviso quando embalagens têm tamanhos diferentes

### LOGS DE AUDITORIA (obrigatório — pedido do usuário)

**Path:** `users/{uid}/price_audit_logs/{logId}` (append-only)

| Evento | action |
|--------|--------|
| Criar/editar/excluir insumo | `ingredient.create/update/delete` |
| Criar/editar oferta | `offer.create/update` |
| Ativar/desativar | `offer.toggleActive` |
| Trocar oferta do ticket | `offer.setDefault` / `offer.setActive` |
| Recálculo automático de default | `offer.defaultRecalculated` |
| Migração legado | `migration.legacyToOffer` |

**Campos mínimos:** uid, timestamp (**serverTimestamp**), action, entityType/entityId, supplier, previousPrice/newPrice, previousPackageQuantity/newPackageQuantity, pricePerUnit, source, summary PT-BR, expireAt (ex.: +180d)

**Rules:** `allow create` do dono; `allow update, delete: if false`  
**Batch:** update do doc + add do log juntos (evita preço mudado sem log)

### Rules Firestore

Adicionar matches novos **antes** do catch-all; **deploy das rules antes do app**.

### Migração legado

1. Insumo sem `offers` → 1 oferta sintética “Fornecedor padrão” / “Preço cadastrado”
2. Idempotente (`source=migration` + flag)
3. `ProductCalculator` mantém fallback legado → **zero regressão**
4. `updateIngredient` com `merge: true` para não apagar offers por overwrite

### Esforço MVP

| Fase | Escopo | Esforço |
|------|--------|---------|
| F1 | Models + lógica pura + testes | 1,5–2 d |
| F2 | Service + rules + deploy | 1,5 d |
| F3 | Providers + sync default | 1–1,5 d |
| F4 | Telas ofertas | 2–2,5 d |
| F5 | Ticket cenário best | 1,5–2 d |
| F6 | Auditoria UI + migração lazy | 1–1,5 d |
| F7 | Filtros + polish + analyze | 1 d |
| **Total** | | **~9,5–12 dias** |

---

## 3) Veredito do advisor

**Aprovado com ressalvas** — implementar apenas se:

1. **Política explícita de preço ativo no ticket** (nunca auto-trocar p/ mais barato)
2. **Rules novas deployadas antes do app**
3. **Validação dura** `packagePrice > 0` e `packageQuantity > 0`
4. **`updateIngredient`/`toMap` nunca apaguem offers** (merge)
5. **Logs append-only** com `expireAt`

### MVP: entra / corta

**Entra:** CRUD ofertas (teto 15), upsert por fornecedor, ranking preço/un, badge mais barato + oferta ativa, alerta de economia no ticket, logs, migração lazy, rules, UI comparativa  

**Corta:** histórico completo, fotos de nota, notificações, gráficos, cesta multi-insumo, Cloud Functions, multi-moeda

---

## 4) Perguntas para você (gate do Sprint 2)

1. **Ticket usa qual preço por padrão?**  
   a) Oferta ativa escolhida por você (recomendado)  
   b) Sempre o mais barato  
   c) Última compra  

2. **MVP com array no doc (até ~15 fornecedores) ou já subcoleção?**  
   a) Array no doc (mais rápido) — recomendado  
   b) Subcoleção desde já  

3. **Histórico de preços antigos é necessário no MVP?**  
   a) Não (só preço vigente + data) — recomendado  
   b) Sim  

4. **Retenção dos logs?**  
   a) 180 dias com `expireAt` — recomendado  
   b) Sem expirar  
   c) Outro prazo  

5. **Oferta ativa:**  
   a) Escolha explícita do usuário — recomendado  
   b) App marca automaticamente a mais barata  

---

## 5) Próximo passo

Após suas respostas ao gate, o orquestrador dispara o **Sprint 2** em paralelo:

- Stream A: models + service + rules + logs  
- Stream B: lógica de comparação  
- Stream C: plano de telas (design-analyst)  
- Stream D: esqueleto da documentação BIBLIOTECA  

**Importante:** reinicie o opencode para carregar a suíte (`orchestrator`, `innovator`, etc.).
