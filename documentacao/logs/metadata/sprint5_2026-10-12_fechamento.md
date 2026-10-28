# Snapshot de Metadados — Sprint 5 / "Fechamento" (Rastreamento FINAL da sprint)

- **generated_at:** 2026-10-12T16:01:27-03:00 (fim de sprint)
- **workspace:** `/home/vikthor/dev/Projetos/ctrlcash (Cópia)`
- **baseline commit ("antes" versionado):** HEAD `e3c6302` ("Reta final: remove login social; excluir oferta na UI e seguranca de dados no comparativo", 2026-10-09 08:48) — **inalterado**
- **estado ("depois"):** worktree da sessão 2026-10-12 (tema centralizado, notificações locais, termos/privacidade, utilitários de negócio + 120 testes) — **não commitado**
- **snapshot JSON irmão:** `documentacao/logs/metadata/sprint5_2026-10-12_fechamento.json` (formato de `sprint0_baseline.json`)
- **escopo rastreado:** estado git, contagens Dart (`lib/`, `test/`), higiene de cores/tema, dependências, rotas/Firestore, artefatos de docs, sobras
- **garantias desta passada:** **nada commitado, nada deletado, nenhum deploy, nenhuma limpeza executada**; nenhum arquivo fora de `documentacao/logs/metadata/` foi alterado por este relatório; `.env`, keystores, `google-services.json` e `documentacao/BIBLIOTECA_113_RT_279.docx` intocados

---

## 1. Estado git

| Item | Valor |
|---|---|
| `git rev-parse --short HEAD` | `e3c6302` (4 commits desde `caed584`: `3fe247a` setup agents · `7511b06` comparativo · `557f1d8` docs · `e3c6302` reta final) |
| Commits desde o último snapshot (S3, HEAD `caed584`) | **4** |
| `git stash list` | **0** (nenhum stash) |
| `git status --short` | **56 M · 0 D · 21 ??** (77 entradas) |

### 1.1 Modificados (M) — 56

| Grupo | Qtd | Arquivos |
|---|---:|---|
| Raiz | 4 | `.env.example`, `firestore.rules`, `pubspec.yaml`, `pubspec.lock` |
| `android/app` | 2 | `build.gradle.kts`, `AndroidManifest.xml` |
| `docs` | 1 | `overview.md` |
| `lib/` (raiz) | 6 | `main.dart`, `home_screen.dart`, `budgets_screen.dart`, `expenses_screen.dart`, `reports_screen.dart`, `settings_screen.dart` |
| `lib/models` | 2 | `app_user.dart`, `transaction.dart` |
| `lib/providers` | 2 | `transaction_provider.dart`, `user_provider.dart` |
| `lib/services` | 2 | `auth_service.dart`, `firestore_service.dart` |
| `lib/screens` | 18 | 14 telas + 4 de `settings/` (todas as telas do app) |
| `lib/widgets` | 19 | todos os widgets da S2/S3 |

`git diff --stat HEAD` acumulado: **56 files changed, 5 219 insertions(+), 3 127 deletions(-)**.

### 1.2 Deletados (D) — **0**

A remoção da suíte antiga de agents (`agent.json/*.json` + `.opencode/agents/{backend,frontend,logic,qa}.md`, 8 entradas `D` desde a Sprint 2) **foi commitada** no bloco `3fe247a` — não há mais sobras `D` no status.

### 1.3 Não rastreados (??) — 21

| Grupo | Entradas | Arquivos | Conteúdo |
|---|---:|---:|---|
| `lib/` | 11 | **15** | `theme/` (5), `services/notification_service.dart`, `screens/settings/terms_privacy_screen.dart`, `utils/{app_info,audit_builder,offer_rules,recurrence}.dart` (4), `widgets/{alert_banner,app_text_field,app_toast,list_skeleton}.dart` (4) |
| `test/` | 7 | 7 | `audit_builder`, `ingredient_active_offer`, `model_roundtrip`, `offer_rules`, `product_calculator`, `recurrence`, `transaction_rules` (todos `_test.dart`) |
| `documentacao/` | 3 | 3 | `CTRLCASH_SPRINT4_MODULO_COMPARATIVO_RT.docx` + `logs/sprint4/{docs_sprint4_modulo_comparativo.md, ctrlcash_sprint4_modulo_comparativo_rt.html}` |

*(21 = 11 + 7 + 3 ✓)*

---

## 2. Antes → Depois por área (linhas Dart)

| Área | Arq. HEAD | Arq. agora | Linhas HEAD | Linhas agora | Δ sessão |
|---|---:|---:|---:|---:|---:|
| `lib/models/` | 7 | 7 | 776 | 840 | +64 |
| `lib/services/` | 3 | 4 | 581 | 1 036 | **+455** |
| `lib/providers/` | 5 | 5 | 512 | 544 | +32 |
| `lib/utils/` | 6 | 10 | 855 | 1 172 | **+317** |
| `lib/screens/` | 18 | 19 | 6 641 | 7 730 | **+1 089** |
| `lib/widgets/` | 19 | 23 | 1 975 | 2 426 | **+451** |
| `lib/theme/` | 0 | **5** | 0 | 269 | **+269** |
| `lib/` raiz | 7 | 7 | 1 777 | 2 256 | +479 |
| **`lib/` total** | **65** | **80** | **13 117** | **16 273** | **+3 156** |
| `test/` | 4 | **11** | 939 | 2 223 | **+1 284** |
| **total lib+test** | **69** | **91** | **14 056** | **18 496** | **+4 440** |

### 2.1 Código NOVO desta sprint (untracked, mtime 2026-10-12)

| Arquivo | Linhas | Bytes | sha256 (16) |
|---|---:|---:|---|
| `lib/theme/app_theme.dart` | 204 | 7 083 | `52efb9ba3c926ade` |
| `lib/theme/app_colors.dart` | 16 | 621 | `e7600de999b60767` |
| `lib/theme/app_typography.dart` | 34 | 1 032 | `17f6455ee0041fc8` |
| `lib/theme/app_spacing.dart` | 9 | 236 | `158a4da11878b0fd` |
| `lib/theme/app_radius.dart` | 6 | 146 | `5d62d09314ef3c46` |
| `lib/services/notification_service.dart` | 185 | 5 398 | `0fb4e4a5cf0c1cbc` |
| `lib/screens/settings/terms_privacy_screen.dart` | 87 | 3 548 | `081574ed3372e297` |
| `lib/utils/audit_builder.dart` | 200 | 5 719 | `c35a3ada885dce79` |
| `lib/utils/recurrence.dart` | 106 | 2 981 | `2933822d4ea660cc` |
| `lib/utils/offer_rules.dart` | 7 | 224 | `67805a2c2e7b5c3f` |
| `lib/utils/app_info.dart` | 4 | 104 | `0a6fc0332a97bd42` |
| `lib/widgets/alert_banner.dart` | 52 | 1 338 | `d196ea336ee2c758` |
| `lib/widgets/app_text_field.dart` | 71 | 1 798 | `e1479ddc0d14d0ce` |
| `lib/widgets/app_toast.dart` | 58 | 1 776 | `cc1c0923326ef48c` |
| `lib/widgets/list_skeleton.dart` | 69 | 1 796 | `f540700790fa0f1a` |
| **subtotal `lib/` (15 arq.)** | **1 389** | — | — |
| **subtotal `test/` (7 arq.)** | **1 284** | — | — |

---

## 3. Higiene de código — cores e tema (pós-refatoração)

| Verificação | Esperado | Encontrado | Status |
|---|---|---|---|
| `Color(0xFF` fora de `lib/theme/` | ~0 | **0** (as 11 ocorrências estão todas em `lib/theme/app_colors.dart`) | ✅ |
| `0xFF` cru fora do theme | 0 + categories | **19**, todas em `lib/utils/categories.dart` (`CategoryDef(..., 0xFF....)` — paleta de categorias, exceção esperada) | ✅ |
| `Colors.green/red/orange/blue` crus fora do tema | 0 | **0** (os 47 "matches" aparentes são `AppColors.greenPrimary` — alias do tema) | ✅ |
| Qualquer `Colors.*` crus fora de `lib/theme/` | 0 | **0** (`Colors.white`/`transparent` só dentro de `app_theme.dart`, 9 usos) | ✅ |
| `static const Color` | 0 fora do theme | **11**, todas em `lib/theme/app_colors.dart` (0 fora do theme) | ✅ |
| Blocos `lib/theme/` | 5 arquivos | **5** (`app_colors`, `app_radius`, `app_spacing`, `app_theme`, `app_typography`) = 269 linhas | ✅ |
| Widgets em `lib/widgets/` | — | **23** arquivos (19 do HEAD + 4 novos) = 2 426 linhas | ✅ |

---

## 4. Rotas (`lib/main.dart`) e Firestore

### 4.1 Rotas nomeadas — **25** (mesma contagem do HEAD; sem rota nova)

`/login`, `/cadastro`, `/dashboard`, `/budgets`, `/budget-form`, `/expenses`, `/transaction-form`, `/reports`, `/ingredients`, `/ingredient-form`, `/products`, `/product-form`, `/product-detail`, `/product-scanner`, `/product-form-with-barcode`, `/product-form-with-photo`, `/settings`, `/settings/profile`, `/settings/notifications`, `/settings/security`, `/settings/help`, `/ingredient-offers`, `/offer-form`, `/audit-logs`, `/compare-prices`.

*(`TermsPrivacyScreen` não é rota: é navegada via `Navigator.push(MaterialPageRoute)` a partir de `cadastro_screen.dart` e `security_screen.dart`.)*

### 4.2 Coleções Firestore — **6** (estável desde a Sprint 2)

`users`, `transactions`, `budgets`, `ingredients`, `products`, `price_audit_logs` — idênticas aos blocos `match /` de `firestore.rules` (6 + catch-all `/{document=**}`).

---

## 5. Dependências (`pubspec.yaml`)

| Item | Estado |
|---|---|
| `flutter_local_notifications` | **`^19.0.0`** no yaml → **19.5.0** no `pubspec.lock` (novo nesta sprint) ✅ |
| `font_awesome_flutter` | **REMOVIDO** (diff: `-  font_awesome_flutter: ^11.0.0`) ✅ |
| `google_sign_in` / `flutter_facebook_auth` / facebook | **AUSENTES** (grep no yaml: 0 ocorrências) ✅ |
| Demais | `firebase_core ^3`, `firebase_auth ^5`, `cloud_firestore ^5`, `firebase_storage ^12`, `provider ^6.1.2`, `fl_chart ^0.69`, `image_picker ^1.1.2`, `mobile_scanner ^6.0.2`, `flutter_dotenv ^5.2` — inalterados |

---

## 6. Testes e verificações (reexecutadas agora)

| Verificação | Resultado |
|---|---|
| `flutter test` | **exit 0 — "+120: All tests passed!"** ✅ |
| Composição dos 120 testes | `widget_test` 1 + `offer_comparator` 23 + `price_panel_aggregator` 15 + `unit_converter` 15 + `audit_builder` 15 + `ingredient_active_offer` 15 + `product_calculator` 10 + `recurrence` 10 + `transaction_rules` 9 + `offer_rules` 4 + `model_roundtrip` 3 = **120** ✅ |
| Arquivos de teste | **11** (4 do HEAD + **7 novos**; briefing esperava 8 — a contagem real é 11, total de testes confere em 120) |
| `dart analyze .` | **exit 0 — 1 info** ⚠️ (`deprecated_member_use`: `updateEmail` em `lib/services/auth_service.dart:107`; sugestão: `verifyBeforeUpdateEmail()`) |

---

## 7. Artefatos de documentação da Sprint 4 (untracked)

| Arquivo | Linhas | Bytes | sha256 (16) | mtime |
|---|---:|---:|---|---|
| `documentacao/logs/sprint4/docs_sprint4_modulo_comparativo.md` | 639 | 33 200 | `d7c203b3df80e418` | 2026-10-09 08:57 |
| `documentacao/logs/sprint4/ctrlcash_sprint4_modulo_comparativo_rt.html` | 631 | 43 566 | `7c224612999e4361` | 2026-10-09 09:01 |
| `documentacao/CTRLCASH_SPRINT4_MODULO_COMPARATIVO_RT.docx` | — | 24 415 | `0dc94823ae024807` | 2026-10-09 09:02 |

*(Os `.docx` das Sprints 2 e 3 já foram commitados em `557f1d8`; o da Sprint 4 permanece fora do versionamento.)*

---

## 8. Pendências operacionais (reportadas — **nenhuma executada**)

1. **Commit da Sprint 5** — todo o trabalho de fechamento (tema, notificações, termos/privacidade, 7 testes, 15 arquivos `lib/` novos + refatoração em 56 arquivos) segue no worktree; HEAD `e3c6302`; 0 commits desde o snapshot S3.
2. **Versionamento dos artefatos da Sprint 4** — `.docx` + `.md` + `.html` (3 entradas `??` em `documentacao/`) ainda não commitados.
3. **`firestore.rules`** — segue modificado localmente (bloco `price_audit_logs`); deploy (`firebase deploy --only firestore:rules`) **não executado** nesta passada.
4. **`deprecated_member_use`** — `updateEmail` em `auth_service.dart:107` (info do analyzer; migração sugerida acima).

**Resolvidas desde a S3:** `.env` agora tem **734 bytes** (não vazio ✅); remoção da suíte antiga de agents já commitada (0 entradas `D` ✅).

---

## 9. Sobras identificadas — **LISTADAS, NÃO LIMPAS** (limpeza só com confirmação)

- **Nenhuma limpeza executada nesta sessão** (mandato: sem confirmação explícita → só reportar).
- Varredura de temporários (`*.tmp`, `*.bak`, `~$*`, `.~lock.*`, `*.swp`, `*.orig`, `*.rej`, `.DS_Store`, `*~`) com exclusão de `build/`, `.dart_tool/`, `.git/`, `android/.gradle/`, `.opencode/node_modules/`: **nenhum arquivo encontrado** ✅
- **Aguardando confirmação do usuário:**

| # | Sobra | Tam. | Situação | Recomendação do tracker |
|---|---|---:|---|---|
| 1 | `documentacao/logs/sprint4/ctrlcash_sprint4_modulo_comparativo_rt.html` | 43 566 B | HTML **intermediário** (fonte de renderização do `.docx` da Sprint 4), untracked | candidato a remoção **se** o `.docx` for considerado definitivo — aguarda confirmação |
| 2 | `documentacao/logs/sprint4/docs_sprint4_modulo_comparativo.md` | 33 200 B | Markdown-fonte do RT da Sprint 4, untracked | candidato a versionamento **ou** remoção junto do HTML — decisão do usuário |
| 3 | `documentacao/CTRLCASH_SPRINT4_MODULO_COMPARATIVO_RT.docx` | 24 415 B | Documento de entrega (não é lixo), untracked | candidato a **commit**, não a remoção |
| 4 | `.opencode/node_modules/` | **62 MB** | gitignored, cache de ferramentas | remoção segura **se** confirmada (regenerável) |
| 5 | `devtools_options.yaml` | 184 B | já versionado (rastreado) | nenhum — não é sobra |

---

## 10. Conclusão — resumo da sprint (métricas antes / depois)

| Métrica | **Antes** (HEAD `e3c6302`, 09/10) | **Depois** (fim Sprint 5, 12/10) | Δ |
|---|---:|---:|---:|
| Arquivos em `lib/` | 65 | **80** | +15 |
| Linhas em `lib/` | 13 117 | **16 273** | +3 156 |
| Arquivos em `test/` | 4 | **11** | +7 |
| Linhas em `test/` | 939 | **2 223** | +1 284 |
| Total linhas (lib+test) | 14 056 | **18 496** | +4 440 |
| Testes (total / passando) | — | **120 / 120** | +81 vs S3 (39) |
| Blocos `lib/theme/` | 0 | **5** (269 ln) | +5 |
| Widgets em `lib/widgets/` | 19 | **23** | +4 |
| `Color(0xFF` fora do theme | — | **0** | meta atingida |
| `Colors.*` crus fora do theme | — | **0** | meta atingida |
| Rotas nomeadas | 25 | **25** | 0 |
| Coleções Firestore | 6 | **6** | 0 |
| `flutter_local_notifications` | ausente | **^19.0.0 (lock 19.5.0)** | +1 dep |
| `font_awesome_flutter` | presente | **removido** | −1 dep |
| `dart analyze .` | 0 issues | **1 info** (deprecado) ⚠️ | +1 info |
| `flutter test` | 39/39 (S3) | **120/120** ✅ | +81 |
| Commits no repo | 1 (=`caed584`) | **5 (=`e3c6302`)** | +4 commits |
| `git status` (M/D/??) | 13 / 8 / 38 | **56 / 0 / 21** | +43 M, −8 D, −17 ?? |
| Limpeza executada | — | **não** | 0 arquivos removidos |

**Veredito da passada:** a sprint de fechamento entregou **centralização de tema** (5 blocos em `lib/theme/` + zero `Color(0xFF`/`Colors.*` crus fora do theme), **notificações locais** (`notification_service.dart`, 185 ln, `flutter_local_notifications` 19.5.0), tela de **Termos & Privacidade**, utilitários de negócio (`audit_builder`, `recurrence`, `offer_rules`, `app_info`) e **7 suítes de teste novas** — `flutter test` **120/120** e `dart analyze` com apenas 1 info (API deprecada). `pubspec.yaml` perdeu `font_awesome_flutter` e ganhou notificações; rotas (25) e coleções Firestore (6) estáveis. **Nada foi commitado, deletado, deployado ou limpo**; as pendências §8–§9 (commit da sprint, versionamento dos artefatos da Sprint 4, deploy das rules, sobras listadas) seguem aguardando decisão do usuário.
