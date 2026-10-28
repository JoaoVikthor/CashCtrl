# Snapshot de Metadados — Sprint 2 / Proposta A (Rastreamento)

- **generated_at:** 2026-10-07
- **workspace:** `/home/vikthor/dev/Projetos/ctrlcash (Cópia)`
- **baseline ("antes"):** HEAD `caed584` ("Icone do app: fundo branco + APK release", 2026-08-08) + setup de agents não commitada
- **estado ("depois"):** worktree da Sprint 2 (não commitado)
- **escopo rastreado:** models, services, providers, utils, screens, widgets, test, main.dart (rotas), firestore.rules, paths Firestore, eventos de auditoria, pubspec, docs
- **garantias desta passada:** nenhum arquivo alterado em `lib/`, `test/`, `firestore.rules`, `.env` ou segredos; **nada commitado, nada deletado, nenhum deploy**

---

## 1. Estado git (`git status --short`)

| Tipo | Arquivos |
|---|---|
| Modificados (M) | `.gitignore`, `analysis_options.yaml`, `firestore.rules`, `lib/main.dart`, `lib/models/ingredient.dart`, `lib/providers/ingredient_provider.dart`, `lib/screens/ingredient_form_screen.dart`, `lib/screens/ingredients_screen.dart`, `lib/screens/product_detail_screen.dart`, `lib/services/firestore_service.dart`, `pubspec.lock` |
| Deletados (D) — setup antiga | `.opencode/agents/{backend,frontend,logic,qa}.md`, `agent.json/{backend,frontend,logic,qa}.json` |
| Novos (??) — Sprint 2 código | `lib/models/ingredient_offer.dart`, `lib/models/price_audit_log.dart`, `lib/screens/{audit_logs,ingredient_offers,offer_form}_screen.dart`, `lib/utils/offer_comparator.dart`, 14 × `lib/widgets/*`, `test/offer_comparator_test.dart` |
| Novos (??) — setup de agents | `opencode.json`, 8 × `.opencode/agents/*.md` |
| Novos (??) — outros | `documentacao/` (inteiro), `devtools_options.yaml` |

Total: 11 modificados, 8 deletados, 27 não rastreados (grupos).

---

## 2. Antes → Depois por área (linhas Dart)

| Área | Arquivos antes | Arquivos depois | Linhas antes | Linhas depois | Δ linhas |
|---|---:|---:|---:|---:|---:|
| `lib/models/` | 5 | 7 | 544 | 775 | **+231** |
| `lib/services/` | 3 | 3 | 310 | 646 | **+336** |
| `lib/providers/` | 5 | 5 | 471 | 505 | **+34** |
| `lib/utils/` | 3 | 4 | 197 | 398 | **+201** |
| `lib/screens/` | 14 | 17 | 4 548 | 6 203 | **+1 655** |
| `lib/widgets/` | 3 | 17 | 342 | 1 398 | **+1 056** |
| `lib/main.dart` | 1 | 1 | 208 | 223 | **+15** |
| **`lib/` total** | **40** | **60** | **8 125** | **11 653** | **+3 528** |
| `test/` | 1 | 2 | 13 | 421 | **+408** |

*(raiz de `lib/` fora das subpastas: 6 telas/legacy + `firebase_options.dart` = 1 505 linhas, inalteradas nesta sprint.)*

### 2.1 Arquivos novos (Sprint 2)

| Arquivo | Linhas | sha256 (16) |
|---|---:|---|
| `lib/models/ingredient_offer.dart` | 100 | `e2e4bfd7800c6432` |
| `lib/models/price_audit_log.dart` | 65 | `e5015ce6c4cee6cc` |
| `lib/utils/offer_comparator.dart` | 201 | `5b225789d6cfe28b` |
| `test/offer_comparator_test.dart` | 408 | `64e13f588580d51e` |
| `lib/screens/ingredient_offers_screen.dart` | 513 | — |
| `lib/screens/offer_form_screen.dart` | 448 | — |
| `lib/screens/audit_logs_screen.dart` | 351 | — |
| `lib/widgets/` (14 novos) | 1 056 | — |

Widgets novos: `active_offer_marker`, `audit_entry_tile`, `best_price_chip`, `confirm_action_dialog`, `delta_price_text`, `economy_summary_card`, `empty_state`, `error_state`, `filter_chip_row`, `offer_card`, `offer_count_badge`, `offer_limit_banner`, `search_field`, `section_header`.
*(pré-existentes: `app_branded_header`, `app_drawer`, `category_pie_chart`.)*

### 2.2 Arquivos modificados (delta de linhas, HEAD → worktree)

| Arquivo | Antes | Depois | Δ | sha256 (16, depois) |
|---|---:|---:|---:|---|
| `lib/services/firestore_service.dart` | 137 | 473 | **+336** | `026501f8cf5a3d2f` |
| `lib/screens/ingredient_form_screen.dart` | 290 | 588 | **+298** | `9a7ff8b463fd821c` |
| `lib/models/ingredient.dart` | 90 | 156 | **+66** | `0c65cdf28954c40d` |
| `lib/providers/ingredient_provider.dart` | 98 | 132 | **+34** | `a245b240d83a02e0` |
| `lib/screens/ingredients_screen.dart` | 188 | 215 | **+27** | `6435a38ecebef0f5` |
| `lib/main.dart` | 208 | 223 | **+15** | `815deba3aaa1df8e` |
| `lib/screens/product_detail_screen.dart` | 339 | 357 | **+18** | `76f053307cd164f9` |
| `firestore.rules` | 43 | 49 | **+6** | `7f6a5b815e1ac010` |

---

## 3. Rotas (`lib/main.dart`)

| Métrica | Antes | Depois |
|---|---:|---:|
| Rotas nomeadas | 21 | **24** |

Novas rotas: `'/ingredient-offers'`, `'/offer-form'`, `'/audit-logs'`.

---

## 4. Caminhos Firestore usados pelo app

| Path | Status | Observação |
|---|---|---|
| `users/{uid}` | present | perfil (`saveUser`/`getUser`) |
| `users/{uid}/transactions` | present | inalterado |
| `users/{uid}/budgets` | present | inalterado |
| `users/{uid}/products` | present | inalterado |
| `users/{uid}/ingredients` | **modified** | doc agora embute array `offers` (até 15) + campo `activeOfferId`; preço legado continua no doc |
| `users/{uid}/price_audit_logs` | **created** | coleção nova, append-only |

Helper no serviço: `_auditLogCol(uid)` / `collection('price_audit_logs')`.

### 4.1 `firestore.rules` (+6 linhas)

```rules
match /price_audit_logs/{logId} {
  allow read, create: if request.auth != null && request.auth.uid == uid;
  allow update, delete: if false;
}
```
*(regra "Bloqueia qualquer outra colecao" existente passa a cobrir implicitamente as demais.)*
**Status:** apenas local — **`firebase deploy` NÃO executado** (pendência operacional, ver §7).

---

## 5. Eventos de auditoria documentados (9)

| Evento | Origem (`firestore_service.dart`) |
|---|---|
| `ingredient.create` | `addIngredient` |
| `ingredient.update` | `updateIngredient` |
| `ingredient.delete` | `deleteIngredient` |
| `offer.create` | `upsertOffer` (criação) |
| `offer.update` | `upsertOffer` (edição) |
| `offer.delete` | `deleteOffer` |
| `offer.setActive` | `setActiveOffer` |
| `offer.toggleActive` | `toggleOfferActive` |
| `migration.legacyToOffer` | `migrateLegacyPrice` |

Métodos novos no serviço: `upsertOffer`, `setActiveOffer`, `toggleOfferActive`, `deleteOffer`, `migrateLegacyPrice`, `writeAuditLog`, `priceAuditLogsStream`.

---

## 6. Dependências e verificação

| Item | Antes | Depois | Status |
|---|---|---|---|
| `pubspec.yaml` | — | idêntico ao HEAD | **sem dependências novas** (diff vazio) |
| `pubspec.lock` | — | modified | apenas bumps de transitivas de teste (`matcher` 0.12.19→0.12.20, `meta` 1.17.0→1.19.0, `test_api` 0.7.10→0.7.12, `typed_data`, `vector_math`) — **sem pacote novo** |

### Status de verificação (reexecutado nesta passada)

| Verificação | Resultado |
|---|---|
| `dart analyze lib test` | **exit 0 — "No issues found!"** ✅ |
| `flutter test` | **24/24 — All tests passed!** ✅ (exit 0) |
| `flutter analyze` | ⚠️ analysis server crasou com `FormatException` no canal LSP (ambiente, caminho com espaços/acentos) — **não é issue de código**; usar `dart analyze` como verificador |

---

## 7. Pendências operacionais (sem execução — só reporte)

1. **Commit da Sprint 2** — todo o código novo/modificado está no worktree; nenhum commit foi feito.
2. **Commit ou descarte da setup de agents** — `opencode.json` + 8 agentes `.md` novos, remoção de `agent.json/` e dos 4 agentes antigos (ver §8b).
3. **`firebase deploy --only firestore:rules`** — regra de `price_audit_logs` só vale após deploy (requer confirmação).
4. **`.env` real** — ver §8a.
5. **Aprovação das sobras** — §8; nada foi removido.

---

## 8. Sobras identificadas — **LISTADAS, NÃO LIMPADAS** (limpeza só com confirmação)

### (a) `.env` de 0 bytes ⚠️
- `.env` — 0 bytes, mtime 2026-10-07 09:42, criado por agente para rodar testes; gitignored (`.gitignore:49`).
- **Ação necessária do usuário:** copiar o `.env` real de volta para esta cópia do workspace, senão o app não roda (Firebase/`flutter_dotenv`).
- Não deletar nem editar automaticamente.

### (b) Setup de agents antiga, não commitada
| Item | Status git | Observação |
|---|---|---|
| `.gitignore` | M (+2) | adiciona `.widget_preview/` — setup, não Sprint 2 |
| `analysis_options.yaml` | M (+5) | adiciona `analyzer.exclude: build/**, android/**, web/**` — setup |
| `pubspec.lock` | M | bumps de transitivas de teste (§6) — pode entrar no commit da Sprint 2 ou separado |
| `.opencode/agents/{backend,frontend,logic,qa}.md` | D (4) | renomeados/substituídos |
| `.opencode/agents/*.md` novos (8) | ?? | `orchestrator`, `project-analyst`, `implementer`, `docs-writer`, `innovator`, `innovator-advisor`, `metadata-tracker`, `design-analyst` |
| `agent.json/{backend,frontend,logic,qa}.json` | D (4) | diretório `agent.json/` não existe mais |
| `opencode.json` | ?? | config nova da suíte (sha256 `93e73ab19390439b`) |
- **Decisão do usuário:** commitar setup separado da Sprint 2, ou descartar parte dela.

### (c) Temporários / lixo de conversão
- Varredura por `*.tmp`, `*.bak`, `~$*`, `.~lock.*`, `*.swp`, `*.orig`, `*.rej`, `.DS_Store` → **nenhum arquivo encontrado**.
- Único `.docx` do repo: `documentacao/BIBLIOTECA_113_RT_279.docx` (modelo protegido, **não é lixo**).
- `.opencode/node_modules/` — 62 MB, gitignored via `.opencode/.gitignore` (resíduo de setup, não é lixo de conversão; manter ou limpar a critério do usuário).
- `build/`, `.dart_tool/`, `android/.gradle/` — caches normais, gitignored.

### (d) `devtools_options.yaml`
- Novo, não versionado (184 bytes, mtime 2026-09-05 21:30) — gerado pelo DevTools.
- **Decisão do usuário:** versionar, adicionar ao `.gitignore` ou remover.

### Observação de contexto
- `documentacao/` aparece inteiro como `?? documentacao/` (nunca versionado): inclui os logs das sprints, os docs de apoio e o `.docx` modelo. Definir se passa a ser versionado.

---

## 9. Conclusão

A Sprint 2 (Proposta A) cresceu o `lib/` de **8 125 → 11 653 linhas (+43%)**, adicionou **20 arquivos Dart** (2 models, 3 telas, 14 widgets, 1 utilitário, 1 teste), **3 rotas**, a coleção **`users/{uid}/price_audit_logs`** com regra append-only em `firestore.rules` e **9 eventos de auditoria**. `pubspec.yaml` permaneceu **inalterado** (zero dependências novas). Verificações limpas: `dart analyze` sem issues e `flutter test` **24/24**. Nenhuma sobra foi removida; itens (a)–(d) aguardam decisão do usuário. Nada foi commitado, deletado ou implantado.
