# Snapshot de Metadados — Sprint 7 / "Fechamento Total" (Rastreamento FINAL da sessão 2026-10-27, Sessões 5–7)

- **generated_at:** 2026-10-27T22:45:58-03:00 (congelamento do snapshot)
- **workspace:** `/home/vikthor/dev/Projetos/ctrlcash (Cópia)`
- **baseline commit ("antes" versionado):** HEAD `e3c6302` ("Reta final: remove login social; excluir oferta na UI e seguranca de dados no comparativo", 2026-10-09) — **inalterado** (0 commits desde o snapshot sprint6)
- **estado ("depois"):** worktree da sessão 2026-10-27, **Sessões 5–7** (vocabulário/categorias/productName · unificação home/reports + export Excel · remoção do scanner + fluxo de fichas/pendências) — **não commitado**
- **snapshot JSON irmão:** `documentacao/logs/metadata/sprint7_2026-10-27_fechamento_total.json` (formato de `sprint6_2026-10-27_fechamento.json`)
- **snapshots anteriores:** `sprint5_2026-10-12_fechamento.{json,md}` (12/10) · `sprint6_2026-10-27_fechamento.{json,md}` (27/10, 20:03)
- **escopo desta passada:** Sessões **5, 6 e 7** (após o snapshot sprint6), por janela de mtime + evidência de diff/grep
- **garantias:** **nada commitado, nada apagado, nenhuma limpeza executada, nenhum deploy**; **`flutter` não executado** (métricas de teste por contagem estática + briefing da sessão); `dart analyze` reexecutado (somente leitura) → 1 info; `lib/` **intocado** (somente leitura); `.env`, keystores, `google-services.json` e `documentacao/BIBLIOTECA_113_RT_279.docx` intocados; únicos arquivos criados por este tracker: os dois deste snapshot

---

## 1. Estado git (excluindo `build/` para contagens)

| Item | S6 (20:03) | **S7 (22:45)** | Δ |
|---|---:|---:|---:|
| `git rev-parse --short HEAD` | `e3c6302` | **`e3c6302`** | 0 commits |
| `git stash list` | 0 | **0** | 0 |
| `git status` M / D / ?? (excl. `build/`) | 58 / 0 / 27 | **66 / 1 / 35** | +8 M, **+1 D**, +8 ?? |
| `git status` total (excl. `build/`) | 85 | **102** | +17 |
| `git status` com `build/` | 86 | **103** (67 M / 1 D / 35 ??) | +17 |
| `git status` ao final da escrita | — | **66 / 1 / 38** = 105 | +3 ?? (2 deste snapshot + 1 doc sprint7 paralelo) |
| `git diff --stat HEAD` (excl. `build/`) | 58 files, +5 600 / −3 291 | **67 files, +6 758 / −3 821** | +9 files, +1 158 / +530 |

**Único `D` (deleção real da sessão):** `lib/screens/product_scanner_screen.dart` (confirmado ausente do disco e marcado `D` no git).

---

## 2. Arquivos tocados por sessão (janelas de mtime + evidência de conteúdo)

**53 arquivos tocados** nas Sessões 5–7 (excl. `build/`).

### 2.1 Sessão 5 — vocabulário / categorias / productName / ticket / drawer / banner perfil — **34 arquivos** (janela 20:48–21:11)

| Grupo | Arquivos (destaques) | Evidência verificada |
|---|---|---|
| Vocabulário + categorias | `lib/utils/categories.dart` | **`_legacyCategories`** (linha 33) + fallback `?? _legacyCategories[name]` (linha 53); categoria legada **'Insumos'** mantida (linha 14) |
| Auditoria | `lib/utils/audit_builder.dart` | '**Produto** $name criado/atualizado/removido' (linhas 15/28/39) e '**Ficha técnica** ...' (150/165/181) |
| `productName` em ofertas | `models/ingredient_offer.dart` (campo + `hasProductName`), `offer_form_screen.dart` (controller/linha 330), `widgets/offer_card.dart:68`, `screens/ingredient_offers_screen.dart` (**busca** linha 480 + 620), `compare_prices_screen.dart`, `widgets/panel_product_card.dart` | campo `productName` persistido (`toMap`/`fromMap`) e exibido como "Produto: …" |
| BottomSheet criar | `lib/screens/ingredients_screen.dart` | `_showCreateSheet` (linha 97) — "O que você quer criar?" |
| Ticket % participação | `lib/screens/product_detail_screen.dart:317` | `'${(share * 100).toStringAsFixed(1)}% do custo total'` |
| Drawer 7 itens/nova ordem | `lib/widgets/app_drawer.dart` | Dashboard → **Produtos(`/ingredients`)** → **Fichas Técnicas(`/products`)** → Orçamentos → Transações → Relatórios → Configurações |
| Banner recriação perfil | `lib/providers/user_provider.dart` (`hasSession:34`, `email:35`, `_authUser`), `screens/settings/edit_profile_screen.dart:260` | "Não foi possível carregar o perfil salvo. Preencha e salve para recriá-lo." + `StateError('Sessão expirada…')` |
| Resto do lote (vocabulário propagado + testes tocados) | `budgets_screen`, `audit_logs_screen`, `help_screen`, `budget_form_screen`, `transaction_form_screen`, `expenses_screen`, `ingredient_provider`, `models/ingredient.dart`, `models/product.dart`, `product_calculator`, `price_panel_aggregator`, `firestore_service`, `supplier_summary_card`, `economy_summary_card`, `terms_privacy_screen`, `offer_rules`, `offer_upsert_test`, `offer_rules_test`, `audit_builder_test`, `model_roundtrip_test`, `product_calculator_test`, `price_panel_aggregator_test`, `user_provider` | vocabulário unificado ("produto" ↔ "insumo"/"ficha técnica") |

### 2.2 Sessão 6 — unificação home/reports + export Excel — **5 arquivos próprios** (janela 21:11–21:14) + 2 compartilhados

| Arquivo | Tam. | sha256 (16) | Papel |
|---|---:|---|---|
| `lib/utils/report_export.dart` | 6 490 | `b2ed76b2c2839c33` | API + geração XLSX (`package:excel`); `export '…_web.dart' if (dart.library.io) '…_native.dart'` |
| `lib/utils/report_export_native.dart` | 1 047 | `0b9ea734fbeed317` | `dart:io` + `path_provider` + `share_plus` |
| `lib/utils/report_export_web.dart` | 949 | `26b5aa70a65f3487` | `dart:js_interop` + `package:web` (download no browser) |
| `lib/widgets/export_excel_button.dart` | 2 879 | `b8dd73394db33ffa` | botão usado em `reports_screen.dart:92` |
| `lib/reports_screen.dart` | 17 236 | `16fbded433fc83c0` | tela **única** de relatórios (+370 ln de diff) |
| `lib/home_screen.dart` *(compartilhado S6+S7)* | 13 503 | `ddf2620e01ec79ba` | unificação do home operacional (+534 ln de diff) + spacer 96 (S7) |
| `pubspec.yaml` *(compartilhado S6+S7)* | 5 017 | `e8fec3da1682c460` | S6: +`excel: ^4.0.6`, +`path_provider: ^2.1.6`, +`share_plus: ^13.3.1`, +`web: ^1.1.0`; S7: −`mobile_scanner` |

### 2.3 Sessão 7 — scanner removido / FAB único / pendências de ofertas — **13 arquivos + 1 deletado** (janela 22:01–22:44)

| Arquivo | Tam. | sha256 (16) | Evidência |
|---|---:|---|---|
| `lib/screens/product_scanner_screen.dart` | — | — | **DELETADO** (`D`) — 612 linhas removidas |
| `lib/main.dart` | 7 969 | `350bdff5eb19a145` | **22 rotas** (eram 25): −`/product-scanner`, −`/product-form-with-barcode`, −`/product-form-with-photo` |
| `lib/screens/products_screen.dart` | 9 246 | `d06bfe028ae2aee1` | **FAB único** "Nova ficha" (heroTag `products-new-fab`, linha 53) |
| `lib/screens/product_form_screen.dart` | 30 509 | `2f72f95aeace1b1a` | **sem `barcode`** (grep vazio); mantém bottom sheet de seleção de insumo |
| `lib/providers/product_provider.dart` | 2 552 | `efb11162b435c85b` | **`findByBarcode` removido** (grep vazio) |
| `lib/services/storage_service.dart` | 2 410 | `562eb91d3a1c8dec` | **retry `-13040`** (`_cancelledCode`, linha 9) + rejeição de **bytes vazios** (linha 20) |
| `lib/screens/settings/edit_profile_screen.dart` | 13 115 | `aa06dd720c8a864e` | **downscale** `maxWidth: 1024` / `imageQuality: 82`; **sem `deleteFile`** (grep vazio) |
| `lib/home_screen.dart` | 13 503 | `ddf2620e01ec79ba` | **`SizedBox(height: 96)`** (linha 96) |
| `lib/screens/ingredient_form_screen.dart` | 37 532 | `06a6e110c97dca97` | ofertas **na criação** + cards clicáveis `_openOfferForm` (206/620/685/736) e `_registerSupplierHint` (645/713) |
| `lib/utils/pending_offers.dart` | 1 998 | `db430e9a307340af` | **NOVO** — `PendingOfferValidation`, `buildPendingOffer`, `canAddPendingOffer` |
| `test/pending_offers_test.dart` | 3 421 | `8220ffa6b731c3f0` | **NOVO** — **10 testes** |
| `lib/widgets/offer_count_badge.dart` | 1 137 | `fc099d446a7790da` | singular **'1 oferta'** (linha 18) |
| `pubspec.yaml` / `pubspec.lock` | 5 017 / 26 777 | `e8fec3da1682c460` / `18eb3a566ffe08ea` | **−`mobile_scanner: ^6.0.2`** (0 ocorrências no projeto) |
| `lib/models/product.dart` | — | — | campo **`barcode` mantido** (linhas 59/71/104/117) — só a busca/UI saiu |

*(`13` arquivos modificados/novos + `1` deletado = 14; `home_screen` e `pubspec.yaml` já contabilizados na §2.2 como compartilhados.)*

---

## 3. Métricas finais (S6 → S7)

| Métrica | S6 | **S7** | Δ |
|---|---:|---:|---:|
| Arquivos `lib/*.dart` | 80 | **84** | +4 |
| Linhas `lib/` | 16 567 | **17 392** | +825 |
| Arquivos `test/*_test.dart` | 12 | **13** | +1 |
| Linhas `test/` | 2 455 | **2 741** | +286 |
| **Testes** | 128 | **144** | **+16** |
| `dart analyze` | 1 info | **1 info (o mesmo)** | 0 |
| Rotas nomeadas | 25 | **22** | **−3** |
| Entradas do drawer | 7 | **7** | 0 (mudou a ordem/roteamento) |
| Coleções Firestore | 6 | **6** | 0 |
| Dependências de export | — | **excel, path_provider, share_plus, web** | +4 |
| `mobile_scanner` | presente | **removido** | −1 |
| APK release | — | **61 258 206 B (61,3 MB)** | — |
| Web | — | **ok (reportado pela sessão)** | — |

**Composição dos 144 testes:** `offer_comparator` 23 + `price_panel_aggregator` 16 + `unit_converter` 15 + `ingredient_active_offer` 15 + `audit_builder` 15 + `recurrence` 10 + `product_calculator` 10 + **`pending_offers` 10 (novo)** + `offer_upsert` 10 + `transaction_rules` 9 + `model_roundtrip` 6 + `offer_rules` 4 + `widget_test` 1 = **144** ✅

**`dart analyze` (reexecutado, somente leitura):** `exit 0` — exatamente **1 info pré-existente**: `deprecated_member_use` `updateEmail` em `lib/services/auth_service.dart:107:18` (a mesma das S5/S6).

---

## 4. Rotas e drawer (S7)

| Item | S6 | **S7** |
|---|---:|---:|
| Rotas em `main.dart` | 25 | **22** |
| Entradas do drawer | 7 | **7** (nova ordem/vocabulário) |

**3 rotas removidas:** `/product-scanner`, `/product-form-with-barcode`, `/product-form-with-photo` (coerente com a deleção do `product_scanner_screen.dart` e o fim do fluxo de barcode).

**22 rotas restantes:** `/login`, `/cadastro`, `/dashboard`, `/budgets`, `/budget-form`, `/expenses`, `/transaction-form`, `/reports`, `/ingredients`, `/ingredient-form`, `/products`, `/product-form`, `/product-detail`, `/settings`, `/settings/profile`, `/settings/notifications`, `/settings/security`, `/settings/help`, `/ingredient-offers`, `/offer-form`, `/audit-logs`, `/compare-prices`.

**Drawer (7, nova ordem):** Dashboard · **Produtos → `/ingredients`** · **Fichas Técnicas → `/products`** · Orçamentos · Transações · Relatórios · Configurações.
*(Atenção ao roteamento deliberado: o item "Produtos" aponta para `/ingredients` e "Fichas Técnicas" para `/products` — vocabulário novo do app.)*

---

## 5. Entregas por sessão (resumo do que foi verificado)

- **S5:** `_legacyCategories` com fallback (compatibilidade de categorias antigas) e categoria legada 'Insumos' preservada; auditoria separando **Produto** × **Ficha técnica**; `productName` em `IngredientOffer` + formulário + card + **busca** do comparativo; BottomSheet "O que você quer criar?"; ticket com **% de participação** no custo; drawer 7 itens reordenado; banner de **recriação de perfil** (`hasSession`/`email` + mensagem).
- **S6:** home operacional unificado e **reports única**; camada `report_export` com **split condicional** `web`/`native` (`dart.library.io`), botão `ExportExcelButton`; `pubspec` ganhou `excel`, `path_provider`, `share_plus`, `web`.
- **S7:** **scanner deletado** (−3 rotas); `products_screen` com **FAB único**; `product_form` sem barcode (busca `findByBarcode` removida, **model `barcode` mantido**); `storage_service` com **retry −13040** + guarda de bytes vazios; `edit_profile` com **downscale** e **sem `deleteFile`**; spacer 96 no home; ofertas **na criação de insumo** com cards clicáveis + hint de fornecedor; **`pending_offers.dart`** + **10 testes**; badge **'1 oferta'**.

---

## 6. Pendências conhecidas (reportadas — **nenhuma executada**)

1. **Commit da sessão** — 66 `M` + 1 `D` + 35 `??` (excl. `build/`) no worktree; HEAD `e3c6302`; **0 commits desde o snapshot sprint6**.
2. **Release signing** — `android/app/build.gradle.kts:41` usa `signingConfigs.getByName("debug")`; sem `key.properties` de release.
3. **Bundle id** — `applicationId = "com.example.ctrlcash"` (`namespace` idem), ainda provisório.
4. **Rules deploy/TTL** — `firestore.rules` modificado desde 12/10, sem deploy; **sem TTL** (`grep TTL/expire/180` vazio).
5. **iOS adiado** — não existe `ios/` no projeto.
6. **Categoria legada 'Insumos'** — mantida em `categories.dart:14` (compatibilidade com dados antigos), pendente de decisão de migração.
7. **Docs da Sprint 7** — **em produção pelo docs-writer**: no congelamento existia apenas `documentacao/logs/sprint7/docs_sprint7_fechamento_final_rt.md` (30 374 B, 22:48); **sem `.html`/`.docx` e sem `CTRLCASH_SPRINT7_FECHAMENTO_FINAL_RT.docx`** até o fim desta coleta.
8. **`deprecated_member_use`** — `updateEmail` (`auth_service.dart:107`).
9. **APK trackeado** — `build/app/outputs/flutter-apk/app-release.apk` segue versionado no git e `M` (61,3 MB).
10. **`uploadFile` legado** — `storage_service.dart:45`, **zero chamadores** (confirmado por grep).

---

## 7. Sobras — **LISTADAS, NÃO LIMPAS** (repetição não-destrutiva das 9 do sprint6 + novas)

- **Nenhuma limpeza executada.**
- Varredura de temporários (`*.tmp`, `*.bak`, `~$*`, `.~lock.*`, `*.swp`, `*.orig`, `*.rej`, `.DS_Store`, `*~`; excl. `build/`, `.dart_tool/`, `.git/`, `android/.gradle/`, `.opencode/node_modules/`): **nenhum arquivo encontrado** ✅
- **Aguardando confirmação do usuário:**

| # | Sobra | Tam. | Situação | Recomendação |
|---|---|---:|---|---|
| 1 | `uploadFile` em `lib/services/storage_service.dart:45` | ~450 B | legado **sem chamadores** (confirmado) | remoção segura **após confirmação** (mexe em `lib/`) |
| 2 | `imagens/` (raiz: `camaleao-removebg.png`, `camaleao_sem_fundo_e_dourado.png`) | 188 KB (2 arq.) | **fora do bundle** (`pubspec` só publica `assets/images/`); sem referência em `lib/` | confirmar se são fontes a manter ou sobra |
| 3 | `build/google_sign_in_android/`, `build/flutter_facebook_auth/` | parte dos 3,6 GB | resíduos de dependências removidas (S5) | remoção segura se confirmada / `flutter clean` |
| 4 | `build/app/outputs/flutter-apk/app-release.apk` | 61,3 MB, trackeado, `M` | artefato de build **versionado** | `git rm --cached` + `.gitignore` **ou** manter — decisão do usuário |
| 5 | `build/` (total) | 3,6 GB | cache local, gitignored | `flutter clean` se confirmado |
| 6 | `.opencode/node_modules/` | 62 MB | gitignored, regenerável | remoção segura se confirmada |
| 7 | `Lembretes para a versao web` (raiz) | 3 900 B, untracked | nota solta (21/10) | mover para `documentacao/` ou remover |
| 8 | `documentacao/logs/sprint4/*.html/.md` | 43 566 + 33 200 B | HTML intermediário + fonte MD do RT S4 | remoção se o `.docx` for definitivo |
| 9 | Artefatos docx/MD/HTML Sprints 4–6 untracked | ~198 KB | entregas de documentação (não é lixo) | candidatos a **commit** |

**Novas/atualizadas nesta passada:** #1 passa de "legado sem uso" a **"zero chamadores confirmado"**; #2 permanece (pasta `imagens/` fora do bundle); nenhuma sobra nova de código detectada (o `product_scanner_screen.dart` foi **deletado de propósito** pela S7, não é sobra).

### 7.1 Artefatos paralelos (docs-writer) catalogados

| Arquivo | Tam. | sha256 (16) | mtime |
|---|---:|---|---|
| `documentacao/logs/sprint6/docs_sprint6_fechamento_qa_rt.md` | 34 052 | `c167f4621352f0e4` | 20:09:05 |
| `documentacao/logs/sprint6/ctrlcash_sprint6_fechamento_qa_rt.html` | 46 876 | `2faca898f3b0810c` | 20:09:29 |
| `documentacao/logs/sprint6/ctrlcash_sprint6_fechamento_qa_rt.docx` | 27 286 | `6e4e6f5ff184f075` | 20:09:42 |
| `documentacao/CTRLCASH_SPRINT6_FECHAMENTO_QA_RT.docx` | 27 528 | `c5a272954277072b` | 20:09:48 |
| `documentacao/GUIA_FORMATACAO_DOCX.md` (M) | 9 259 | `872a5b0502779d89` | 20:09:40 |
| `documentacao/logs/sprint7/docs_sprint7_fechamento_final_rt.md` | 30 374 | `ea58b688e0e0c056` | 22:48:57 |

*(Docs da **Sprint 7** em produção: apenas o `.md` acima existia ao final da coleta; sem `.html`, sem `.docx` e sem `CTRLCASH_SPRINT7_FECHAMENTO_FINAL_RT.docx`.)*

---

## 8. Conclusão — resumo numérico

| Métrica | S5 (12/10) | S6 (27/10 20:03) | **S7 (27/10 22:45)** |
|---|---:|---:|---:|
| Arquivos `lib/` | 80 | 80 | **84** |
| Linhas `lib/` | 16 273 | 16 567 | **17 392** |
| Arquivos `test/` | 11 | 12 | **13** |
| Testes | 120 | 128 | **144** |
| `dart analyze` (info) | 1 | 1 | **1** |
| Rotas | 25 | 25 | **22** (−3) |
| Drawer | 9 (HEAD) | 7 | **7** (nova ordem) |
| Arquivos `M` excl. build | 56 | 58 | **66** |
| Arquivos `??` | 21 | 27 | **35** |
| Arquivos `D` | 0 | 0 | **1** |
| `git diff` vs HEAD | 56 files | 58 files | **67 files, +6 758 / −3 821** |
| Commits | 5 | 5 | **5 (0 novos)** |
| Limpeza executada | não | não | **não** |

**Veredito:** as Sessões 5–7 fecharam o produto: **vocabulário e categorias compatibilizados** (`_legacyCategories`), `productName` nas ofertas com busca, ticket com **% de participação**, drawer enxuto com roteamento novo, **home/reports unificados** e **exportação Excel web+native**, e a **Sprint 7 removeu o scanner** (−3 rotas, `findByBarcode` fora, `barcode` do model preservado), com **FAB único**, **retry −13040**, **downscale** de foto e o novo fluxo de **ofertas pendentes na criação** (+10 testes → **144**). `dart analyze` segue com **1 info pré-existente**; APK release de **61,3 MB** e web ok segundo a sessão. **Nada foi commitado, apagado, deployado ou limpo**; as 10 pendências (§6) e as 9 sobras (§7) seguem aguardando decisão explícita do usuário. Registro de paralelismo: os docs da Sprint 6 foram regenerados (20:09) e o docs-writer **iniciou** os docs da Sprint 7 (`.md` às 22:48) durante esta coleta, elevando `??` de 35 → 38 ao final da escrita.
