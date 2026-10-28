# Snapshot de Metadados — Sprint 6 / "Fechamento" (Rastreamento FINAL da sessão 2026-10-27)

- **generated_at:** 2026-10-27T20:03:06-03:00 (congelamento do snapshot)
- **workspace:** `/home/vikthor/dev/Projetos/ctrlcash (Cópia)`
- **baseline commit ("antes" versionado):** HEAD `e3c6302` ("Reta final: remove login social; excluir oferta na UI e seguranca de dados no comparativo", 2026-10-09) — **inalterado desde a S5** (0 commits novos)
- **estado ("depois"):** worktree da sessão 2026-10-27 — Sprints 1–3 de fechamento (nav/voltar/perfil/camaleão dourado · dedupe upsertOffer + notificações + toasts · compat web + fix recorrência) — **não commitado**
- **snapshot JSON irmão:** `documentacao/logs/metadata/sprint6_2026-10-27_fechamento.json` (formato de `sprint5_2026-10-12_fechamento.json`)
- **snapshot anterior:** `sprint5_2026-10-12_fechamento.{json,md}` (12/10) — comparações "S5 → S6" abaixo
- **garantias desta passada:** **nada commitado, nada deletado, nenhum deploy, nenhuma limpeza executada**; `flutter` **não executado** (contagem de 128 testes obtida por contagem estática de declarações `test(`/`testWidgets(`); `dart analyze` reexecutado (somente leitura); nenhum arquivo fora de `documentacao/logs/metadata/` foi criado ou alterado por este relatório; `.env`, keystores, `google-services.json` e `documentacao/BIBLIOTECA_113_RT_279.docx` intocados; `lib/` intocado (somente leitura)

---

## 1. Estado git (excluindo `build/` para contagens)

| Item | S5 (12/10) | **S6 (27/10)** | Δ |
|---|---:|---:|---:|
| `git rev-parse --short HEAD` | `e3c6302` | **`e3c6302`** | 0 commits novos |
| `git stash list` | 0 | **0** | 0 |
| `git status` M / D / ?? (excl. `build/`) | 56 / 0 / 21 | **58 / 0 / 27** | +2 M, +6 ?? |
| `git status` total (excl. `build/`) | 77 | **85** | +8 |
| `git status` com `build/` | — | 59 M / 0 D / 27 ?? = 86 | +1 M = APK trackeado |
| `git diff --stat HEAD` (excl. `build/`) | 56 files, +5 219 / −3 127 | **58 files, +5 600 / −3 291** | +2 files, +381 / +164 |

*(`build/app/outputs/flutter-apk/app-release.apk` é **rastreado** no git e aparece como `M` — artefato de build versionado, ver §8.)*

### 1.1 Modificados (M) — 58 (excl. `build/`)

Mesmos 56 da S5 **+ 2 desta sessão**:

| Arquivo | Motivo | mtime |
|---|---|---|
| `lib/services/storage_service.dart` | novo `uploadBytes` (compat web) — S3 | 27/10 18:20 |
| `documentacao/GUIA_FORMATACAO_DOCX.md` | **+22 linhas, agente paralelo (docs-writer) durante esta coleta** — não é das sprints de código | 27/10 18:48 |

### 1.2 Deletados (D) — **0**

### 1.3 Não rastreados (??) — 27 (eram 21 na S5; +6)

| Entrada nova desde a S5 | Origem |
|---|---|
| `test/offer_upsert_test.dart` | S2/S3 desta sessão (8 testes) |
| `documentacao/logs/metadata/sprint5_2026-10-12_fechamento.{json,md}` (2) | snapshot anterior (S5) |
| `Lembretes para a versao web` (raiz, 3 900 B, mtime 21/10) | nota solta, entre sprints |
| `documentacao/CTRLCASH_SPRINT6_FECHAMENTO_QA_RT.docx` | **agente paralelo (docs-writer), 27/10 18:48** |
| `documentacao/logs/sprint6/` (3: `.md` 31 219 B · `.html` 43 277 B · `.docx` 25 673 B) | **agente paralelo (docs-writer), 27/10 18:44–18:47** |

*Resto inalterado desde a S5: 11 entradas `lib/` (theme/, notification_service, terms_privacy, 4 utils, 4 widgets), 7 suítes `test/` antigas, docx S4 + 2 logs S4.*

---

## 2. Arquivos alterados POR SPRINT desta sessão (agrupamento por mtime + evidência de diff)

**19 arquivos tocados pela sessão** (17 `M` + 2 `??`), nas 3 sprints de fechamento. Exclui `build/`.

### Sprint 1 — fixes nav/voltar/perfil/camaleão dourado (janela 18:04–18:05) — **5 arquivos**

| Arquivo | Tam. | sha256 (16) | Evidência |
|---|---:|---|---|
| `lib/widgets/app_branded_header.dart` | 2 626 | `513a35883912c54e` | novo campo `goldLogo`; ícone voltar → `AppColors.textPrimary` |
| `lib/home_screen.dart` | 14 239 | `fea4c381dedadacb` | `AppBrandedHeader(goldLogo: true)` (linha 66) |
| `lib/widgets/app_drawer.dart` | 5 863 | `7f6f927e788a6964` | **−2 `_DrawerEntry`** (ver §4); 9 → 7 entradas |
| `lib/screens/ingredients_screen.dart` | 9 948 | `c921d12b7f082bc8` | cores cruas removidas → tema |
| `lib/settings_screen.dart` | 6 072 | `dda988dcd433ceec` | "Editar Perfil" reencaminhado; `Colors.red` → `AppColors.danger` |

### Sprint 2 — dedupe upsertOffer + notificações + toasts (janela 18:11–18:12; teste em 18:33) — **8 arquivos**

| Arquivo | Tam. | sha256 (16) | Evidência |
|---|---:|---|---|
| `lib/utils/offer_rules.dart` (`??`) | 2 867 | `e05edb4ff1c0f9cc` | **`OfferUpsertResult` + `applyOfferUpsert`** (linha 25) |
| `lib/services/firestore_service.dart` | 19 653 | `7d98db7eceb2bcfc` | chama `applyOfferUpsert` (linha 267) |
| `lib/providers/user_provider.dart` | 2 317 | `65d8eb561db827be` | `updateNotificationPrefs` + getters `notif*` |
| `lib/screens/settings/notifications_screen.dart` | 5 643 | `d477dab3a1899819` | persistência das prefs via provider |
| `lib/screens/budget_form_screen.dart` | 9 203 | `28966b057ee845f6` | imports de tema + `app_toast` |
| `lib/screens/ingredient_form_screen.dart` | 21 418 | `9a7def198af74525` | imports de tema + `offer_rules` + `app_toast`/`alert_banner` |
| `lib/screens/offer_form_screen.dart` | 13 406 | `cb01c4b3c44fd5f4` | imports de tema + `offer_rules` + `app_toast` |
| `test/offer_upsert_test.dart` (`??`, novo) | 6 564 | `deb23325b8824c46` | 8 testes de `applyOfferUpsert` — **mtime 18:33:59, na janela da S3; conteúdo pertence ao tema S2** |

### Sprint 3 — compat web + fix recorrência transação (janela 18:20–18:34) — **6 arquivos**

| Arquivo | Tam. | sha256 (16) | Evidência |
|---|---:|---|---|
| `lib/screens/transaction_form_screen.dart` | 18 112 | `ecc1fdb401a6cf1e` | `utils/recurrence.dart` + UI `_recurrence` (fix recorrência) |
| `lib/services/storage_service.dart` | 1 303 | `600e102aa45e6181` | **`uploadBytes(Uint8List)`**; `dart:io` removido |
| `lib/screens/product_scanner_screen.dart` | 22 736 | `c27f840fc744bead` | `dart:io` → `package:flutter/foundation.dart` (`kIsWeb`) |
| `lib/screens/product_form_screen.dart` | 31 146 | `982b451341f6515e` | `kIsWeb` + `uploadBytes` (linha 451) |
| `lib/screens/settings/edit_profile_screen.dart` | 11 091 | `3213de578fd9f84a` | `kIsWeb` + `uploadBytes` (linha 69) |
| `lib/screens/cadastro_screen.dart` | 20 672 | `1b845b6bce1a82a8` | `kIsWeb ? gallery : camera` + `uploadBytes` (linha 187) |

*(5 + 8 + 6 = 19 ✓; sem sobreposição. O `test/offer_upsert_test.dart` está contado só na S2.)*

### 2.1 Artefatos paralelos detectados DURANTE a coleta (docs-writer, não das sprints de código)

| Arquivo | Tam. | sha256 (16) | mtime |
|---|---:|---|---|
| `documentacao/logs/sprint6/docs_sprint6_fechamento_qa_rt.md` | 31 219 | `b5066b199fa1f468` | 18:44:04 |
| `documentacao/logs/sprint6/ctrlcash_sprint6_fechamento_qa_rt.html` | 43 277 | `a4515c3e1f2cfafc` | 18:45:55 |
| `documentacao/logs/sprint6/ctrlcash_sprint6_fechamento_qa_rt.docx` | 25 673 | `bb527b811b408bb9` | 18:47:19 |
| `documentacao/CTRLCASH_SPRINT6_FECHAMENTO_QA_RT.docx` | 25 916 | `7c60238befd67f15` | 18:48:12 |
| `documentacao/GUIA_FORMATACAO_DOCX.md` (M, +22 ln) | 9 278 | `1f10285dfc51d913` | 18:48:32 |

---

## 3. Contagens antes → depois (S5 → S6)

| Área | S5 arq | **S6 arq** | S5 linhas | **S6 linhas** | Δ sessão |
|---|---:|---:|---:|---:|---:|
| `lib/` (total) | 80 | **80** | 16 273 | **16 567** | 0 arq / **+294 ln** |
| `test/` | 11 | **12** | 2 223 | **2 455** | **+1 arq / +232 ln** |
| total lib+test | 91 | **92** | 18 496 | **19 022** | +1 arq / +526 ln |
| vs HEAD `e3c6302` | 65 arq / 13 117 ln (lib) | **80 / 16 567** | — | — | +15 arq / +3 450 ln (lib) |
| Blocos `lib/theme/` | 5 | **5** | 269 | 269 | 0 |
| Widgets `lib/widgets/` | 23 | **23** | 2 426 | 2 426 | 0 |

---

## 4. Rotas — drawer × `main.dart`

| Item | HEAD / S5 | **S6** |
|---|---:|---:|
| Entradas do drawer (`app_drawer.dart`) | 9 | **7** |
| Rotas nomeadas (`main.dart`) | 25 | **25** (nenhuma removida) |
| Coleções Firestore | 6 | **6** (`firestore.rules` inalterado desde 12/10) |

### 4.1 As 2 rotas removidas do drawer (preservadas no `main.dart`)

| Rota | Label removido do drawer | Preservada em `main.dart` |
|---|---|---|
| `/compare-prices` | "Comparar preços" (`Icons.compare_arrows_outlined`) | linha 157 ✅ |
| `/audit-logs` | "Histórico de preços" (`Icons.history_outlined`) | linha 156 ✅ |

**7 entradas restantes:** `/dashboard`, `/products`, `/ingredients`, `/budgets`, `/expenses`, `/reports`, `/settings`.

**25 rotas nomeadas preservadas:** `/login`, `/cadastro`, `/dashboard`, `/budgets`, `/budget-form`, `/expenses`, `/transaction-form`, `/reports`, `/ingredients`, `/ingredient-form`, `/products`, `/product-form`, `/product-detail`, `/product-scanner`, `/product-form-with-barcode`, `/product-form-with-photo`, `/settings`, `/settings/profile`, `/settings/notifications`, `/settings/security`, `/settings/help`, `/ingredient-offers`, `/offer-form`, `/audit-logs`, `/compare-prices`.

*As 2 rotas perdidas do drawer continuam acessíveis por navegação direta (ex.: do comparativo/auditoria); apenas saíram da lista lateral.*

---

## 5. Novos símbolos públicos desta sessão

| Símbolo | Local | Definição | Consumidores |
|---|---|---|---|
| `AppBrandedHeader.goldLogo` | `lib/widgets/app_branded_header.dart:15,23` | `final bool goldLogo` (default `false`); alterna logo dourado (linha 62) | `home_screen.dart:66` (`goldLogo: true`) |
| `StorageService.uploadBytes` | `lib/services/storage_service.dart:11` | `Future<String?> uploadBytes({uid, path, Uint8List bytes, contentType})` via `putData` | `cadastro_screen:187`, `product_form:451`, `product_scanner:311`, `edit_profile:69` |
| `applyOfferUpsert` (+ `OfferUpsertResult`) | `lib/utils/offer_rules.dart:25` | upsert idempotente de oferta com normalização de fornecedor e limite (15) | `firestore_service:267`; testado em `offer_upsert_test.dart` (8 testes) |

---

## 6. Testes e verificações

| Verificação | Resultado |
|---|---|
| Total de testes | **128** (contagem estática de `test(`/`testWidgets(` em `test/*_test.dart`; `flutter test` **não executado** por instrução) |
| Composição dos 128 | `offer_comparator` 23 + `unit_converter` 15 + `price_panel_aggregator` 15 + `ingredient_active_offer` 15 + `audit_builder` 15 + `recurrence` 10 + `product_calculator` 10 + `transaction_rules` 9 + **`offer_upsert` 8 (novo)** + `offer_rules` 4 + `model_roundtrip` 3 + `widget_test` 1 = **128** ✅ |
| Δ vs S5 | 120 → **128** (+8 = `offer_upsert_test.dart`) |
| Arquivos de teste | 11 → **12** |
| `dart analyze` (reexecutado, somente leitura) | **exit 0 — exatamente 1 info pré-existente** ⚠️ `deprecated_member_use`: `updateEmail` em `lib/services/auth_service.dart:107:18` (mesma ocorrência registrada na S5; sugestão: `verifyBeforeUpdateEmail()`) |
| `flutter` / `flutter test` / builds | **não executados** nesta passada (mandato) |

---

## 7. Pendências conhecidas (reportadas — **nenhuma executada**)

1. **`set()` sem `merge` no Firestore** — `firestore_service.dart`: `updateTransaction` (**linha 144**), `updateBudget` (**181**), `updateProduct` (**569**) gravam `set(map)` **sem** `SetOptions(merge: true)` → risco de sobrescrever campos fora do mapa. *Já com merge:* `users` (linha 47) e `updateIngredient` (linha 217).
2. **iOS não construído** — não existe nem o diretório `ios/` no projeto (targets Android + `web/`); build/validação iOS nunca feitos.
3. **`uploadFile` legado sem uso** — `storage_service.dart:29` delega para `uploadBytes`, **zero chamadores** em `lib/` (candidato a remoção, ver §8.1).
4. **Commit da sessão** — todo o trabalho (S5 + Sprints 1–3 de 27/10, 58 `M` + 27 `??`) segue no worktree; HEAD `e3c6302`; **0 commits desde o snapshot S5**.
5. **Deploy de `firestore.rules`** — segue modificado desde 12/10; `firebase deploy --only firestore:rules` **não executado**.
6. **Versionamento de artefatos** — docx/HTML/MD das Sprints 4, 5 e 6 + `Lembretes para a versao web` seguem untracked.
7. **`deprecated_member_use`** (`updateEmail`, §6) — info pré-existente, pendente de migração.
8. **APK trackeado no git** — `build/app/outputs/flutter-apk/app-release.apk` é versionado e está `M` (§8.4).

---

## 8. Sobras identificadas — **LISTADAS, NÃO LIMPAS** (limpeza só com confirmação explícita)

- **Nenhuma limpeza executada nesta sessão** (mandato: sem confirmação → apenas reportar).
- Varredura de temporários (`*.tmp`, `*.bak`, `~$*`, `.~lock.*`, `*.swp`, `*.orig`, `*.rej`, `.DS_Store`, `*~`, excluindo `build/`, `.dart_tool/`, `.git/`, `android/.gradle/`, `.opencode/node_modules/`): **nenhum arquivo encontrado** ✅
- **Aguardando confirmação do usuário:**

| # | Sobra | Tam. | Situação | Recomendação do tracker |
|---|---|---:|---|---|
| 1 | `uploadFile` em `lib/services/storage_service.dart:29` | ~450 B de código | legado **sem nenhum chamador** (substituído por `uploadBytes`) | remoção **segura após confirmação** — mexe em `lib/`, exige pedido explícito + `flutter analyze` |
| 2 | `imagens/` (raiz: `camaleao-removebg.png`, `camaleao_sem_fundo_e_dourado.png`) | 188 KB | **fora do bundle** — `pubspec.yaml` só publica `assets/images/`; nenhum referencial em `lib/` | confirmar se são fontes a manter no repo ou sobra de asset; **não é o bundle do app** |
| 3 | `build/google_sign_in_android/`, `build/flutter_facebook_auth/` | parte dos 3,6 GB de `build/` | resíduos de **dependências já removidas** (S5: google_sign_in/facebook) | remoção segura **se confirmada** (cache regenerável) ou `flutter clean` |
| 4 | `build/app/outputs/flutter-apk/app-release.apk` | trackeado no git, `M` | artefato de build **versionado** (commit `caed584`) e alterado a cada build | decisão do usuário: `git rm --cached` + `.gitignore` **ou** manter; não mexer sem confirmação |
| 5 | `build/` (total) | **3,6 GB** | cache de builds locais, gitignored | `flutter clean` **se confirmado** |
| 6 | `.opencode/node_modules/` | **62 MB** | gitignored, cache de ferramentas (pendência herdada da S5) | remoção segura **se confirmada** (regenerável) |
| 7 | `Lembretes para a versao web` (raiz) | 3 900 B, untracked | nota solta (mtime 21/10) | mover para `documentacao/` **ou** remover — decisão do usuário |
| 8 | `documentacao/logs/sprint4/*.html/.md` (S5) | 43 566 + 33 200 B, untracked | HTML intermediário + fonte MD do RT S4 | mesmo veredito da S5: remoção **se** o `.docx` for definitivo; aguarda confirmação |
| 9 | Artefatos **Sprints 5/6** untracked (docx/MD/HTML) | ~167 KB | entregas de documentação, **não é lixo** | candidatos a **commit**, não a remoção |

---

## 9. Conclusão — resumo da sessão (métricas antes / depois)

| Métrica | **Antes** (S5, 12/10) | **Depois** (S6, 27/10) | Δ sessão |
|---|---:|---:|---:|
| Arquivos em `lib/` | 80 | **80** | 0 |
| Linhas em `lib/` | 16 273 | **16 567** | +294 |
| Arquivos em `test/` | 11 | **12** | +1 |
| Testes (total) | 120 | **128** | +8 |
| `dart analyze` | 1 info (deprecado) | **1 info (o mesmo)** ⚠️ | 0 |
| Entradas do drawer | 9 (no HEAD) | **7** | **−2** |
| Rotas nomeadas | 25 | **25** | 0 |
| Coleções Firestore | 6 | **6** | 0 |
| Blocos `lib/theme/` / widgets | 5 / 23 | **5 / 23** | 0 |
| Símbolos públicos novos | — | **3** (`goldLogo`, `uploadBytes`, `applyOfferUpsert`) | +3 |
| `git status` M / ?? (excl. build) | 56 / 21 | **58 / 27** | +2 M, +6 ?? |
| `git diff` vs HEAD (excl. build) | 56 files, +5 219 / −3 127 | **58 files, +5 600 / −3 291** | +2 files |
| Commits | 5 (`e3c6302`) | **5 (`e3c6302`)** | **0** |
| Arquivos alterados nesta sessão | — | **19** (S1=5 · S2=8 · S3=6) | — |
| Limpeza executada | não | **não** | 0 arquivos removidos |

**Veredito da passada:** a sessão de fechamento (Sprints 1–3) tocou **19 arquivos** em `lib/`+`test/` — camaleão dourado no header/drawer (−2 rotas do drawer, 9→7, todas as 25 rotas preservadas no `main.dart`), upsert idempotente de ofertas com **8 testes novos (128 no total)**, notificações persistidas via provider, toasts padronizados e **compat web** (`kIsWeb` + `uploadBytes`, `dart:io` eliminado de 4 telas + service) além do fix de recorrência na transação. `dart analyze` segue com **apenas 1 info pré-existente**. **Nada foi commitado, deletado, deployado ou limpo**; as pendências §7 (sprints `set()` sem merge, iOS não construído, `uploadFile` legado, commit, deploy das rules) e as sobras §8 (9 itens) seguem **aguardando decisão explícita do usuário**. Registro extra: artefatos do QA da Sprint 6 e edição do `GUIA_FORMATACAO_DOCX.md` foram gravados **em paralelo** durante esta coleta (docs-writer) e estão catalogados na §2.1.
