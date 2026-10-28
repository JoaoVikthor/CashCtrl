# Documentação Técnica de Fechamento Final do CashCtrl — Sprints 5, 6 e 7

**Relatório técnico no padrão BIBLIOTECA (RT 279, ICMC).**
Fonte de verdade: código real da branch `nova-versao-app`, verificado em 27/10/2026.

---

## Capa

Documentação Técnica de Fechamento Final do CashCtrl — Sprints 5, 6 e 7

Virada de vocabulário (Produtos e Fichas Técnicas), categorias de negócio,
dashboard operacional, relatórios unificados com exportação Excel, remoção do
scanner de código de barras, ofertas na criação do produto e correção da foto
de perfil

Equipe CashCtrl

autoria: github.com/JoaoVikthor

RELATÓRIOS TÉCNICOS DO CASHCTRL

São Carlos

27/10/2026

---

## Indice

1. Introdução
2. Resumo Executivo
3. Sprint 5 — Virada de Vocabulário e Features
    3.1 Vocabulário de produto e drawer
    3.2 Categorias de negócio (e mapa legado)
    3.3 Auditoria no novo vocabulário
    3.4 Bottom sheet "O que você quer criar?"
    3.5 Participação percentual no custo do ticket
    3.6 Nome do produto do fornecedor (`productName`)
4. Sprint 6 — Unificação e Exportação Excel
    4.1 Dashboard operacional
    4.2 Relatórios em página única
    4.3 Exportação Excel (3 abas)
    4.4 Dependências adicionadas
    4.5 Validação no emulador
5. Sprint 7 — Fechamento de UX
    5.1 Remoção do código de barras
    5.2 Correção da foto de perfil
    5.3 Banner de recriação de perfil
    5.4 FAB do Dashboard e spacer
    5.5 Ofertas na criação do produto
    5.6 Cards clicáveis e plural de ofertas
6. QA Final e Builds
7. Como Rodar e Testar
    7.1 Fluxos manuais (checklist)
8. Pendências de Produção
9. Glossário
10. Estado Final e Considerações
Referências

---

## 1. Introdução

Este relatório documenta as **Sprints 5, 6 e 7 do CashCtrl**, aplicativo
Flutter com backend Firebase, que encerram o ciclo de produto iniciado nos
relatórios anteriores. A Sprint 5 virou o vocabulário do app para a linguagem
do negócio (Produtos e Fichas Técnicas), substituiu as categorias genéricas
por categorias de restaurante, adicionou o bottom sheet de criação, a
participação percentual no custo do ticket e o nome do produto anunciado pelo
fornecedor. A Sprint 6 unificou o Dashboard em uma visão operacional e os
Relatórios em uma página única com **exportação Excel**. A Sprint 7 fechou a
experiência: removeu todo o código de barras, corrigiu o upload da foto de
perfil, criou o banner de recriação de perfil e permitiu cadastrar ofertas de
fornecedores **já na criação do produto**, com cards clicáveis.

O conteúdo reflete o código efetivamente entregue em 27/10/2026 (verificado
arquivo a arquivo antes da redação). A numeração de figuras continua a do
relatório da Sprint 6: Figuras 24–29. Nada em `lib/`, nas regras ou nos assets
foi alterado por esta documentação.

## 2. Resumo Executivo

Em três etapas, o CashCtrl passou de "app de insumos e produtos" para um app
de **gestão de restaurante**, com o vocabulário e o fluxo de trabalho do dono
do negócio:

- **Sprint 5 — vocabulário e features:** Insumos→**Produtos**, Produtos→
  **Fichas Técnicas**; drawer com 7 itens; 11 categorias de despesa e 3 de
  receita (com mapa legado); auditoria reescrita ("Produto X criado" /
  "Ficha técnica X criada", sem mudar `action`/`entityType`); bottom sheet
  "O que você quer criar?"; participação % de cada item no custo do ticket;
  `productName` na oferta (nome do produto como o fornecedor anuncia).
- **Sprint 6 — unificação e Excel:** Dashboard operacional (saldo com borda
  dourada, atalho para Relatórios, ações rápidas e movimentações recentes;
  pizza e KPIs removidos do Dashboard); Relatórios em página única; export
  Excel com 3 abas (`Resumo`, `Mensal`, `Transações`), condicional nativo/web,
  validado no emulador Android.
- **Sprint 7 — fechamento de UX:** remoção completa do código de barras
  (tela, 3 rotas, campo do formulário e `mobile_scanner`); correção do upload
  da foto de perfil (StorageException −13040, retry, downscale); banner de
  recriação de perfil; ofertas na criação do produto com `pending_offers`;
  cards clicáveis de fornecedor/ofertas e plural "1 oferta" corrigido.

O QA final ficou em **144/144 testes (13 arquivos)**, `dart analyze` com **1
info pré-existente** e APK de release com **61,3 MB** (ante 77,6 MB antes da
remoção do scanner). O detalhamento está na seção 6.

## 3. Sprint 5 — Virada de Vocabulário e Features

### 3.1 Vocabulário de produto e drawer

O vocabulário visível ao usuário foi alinhado ao domínio do negócio, **sem
renomear nada no Firestore** (compatibilidade total com dados existentes):

Tabela 1. Mapeamento do vocabulário de UI para o modelo persistido.

| Conceito na UI | Classe/modelo | Coleção Firestore | Rota |
|----------------|---------------|-------------------|------|
| **Produto** | `Ingredient` | `users/{uid}/ingredients` | `/ingredients`, `/ingredient-form` |
| **Ficha Técnica** (receita) | `Product` | `users/{uid}/products` | `/products`, `/product-form` |
| **Oferta** | `IngredientOffer` | `offers[]` embutido no produto | `/offer-form` |

O drawer (`app_drawer.dart`) mantém **7 itens**, agora com os rótulos:
Dashboard, **Produtos** (rota `/ingredients`), **Fichas Técnicas** (rota
`/products`), Orçamentos, Transações, Relatórios e Configurações. As telas
receberam os títulos correspondentes (`IngredientsScreen` → "Produtos",
`ProductsScreen` → "Fichas Técnicas") e os textos auxiliares acompanham:
"Itens que entram nas fichas técnicas", "Produtos são os itens comprados.
Fichas técnicas são os pratos vendidos." e os empty states ("Nenhum produto
cadastrado", "Nenhuma ficha técnica cadastrada").

### 3.2 Categorias de negócio (e mapa legado)

As categorias genéricas (Moradia, Alimentação, Lazer etc.) foram substituídas
por categorias de operação de restaurante em `lib/utils/categories.dart`:

Tabela 2. Categorias de despesa e receita (`kExpenseCategories`, `kIncomeCategories`).

| Tipo | Categorias |
|------|------------|
| **Despesa (11)** | Insumos · Mão de Obra · Aluguel/Ocupação · Energia/Água · Embalagens · Taxas/Plataformas · Manutenção · Marketing · Impostos · Transporte/Delivery · Outros |
| **Receita (3)** | Vendas · Delivery/Encomendas · Outros |

`findCategory(name, isIncome:)` resolve a categoria de exibição e, para
documentos antigos, consulta o mapa privado `_legacyCategories` — que
preserva **Moradia**, **Alimentação**, **Transporte**, **Lazer**, **Saúde**,
**Educação**, **Tecnologia**, **Salários**, **Salário**, **Investimentos**,
**Freelance** e **Reembolso** — antes de cair no fallback "Outros". Nenhuma
transação existente perde ícone/cor ao ser aberta.

### 3.3 Auditoria no novo vocabulário

`lib/utils/audit_builder.dart` foi reescrito para falar a língua da UI:
`ingredientCreate` gera o resumo **"Produto {nome} criado"**, `productCreate`
gera **"Ficha técnica {nome} criada · {preço}"**, e as variantes de
update/delete seguem o mesmo padrão ("Produto X atualizado", "Ficha técnica X
removida"). Importante: **`action` e `entityType` permanecem inalterados**
(`ingredient.create`, `ingredient.update`, `product.create`, `product.update`
etc.) — os logs antigos e os filtros da tela de auditoria continuam
funcionando, e nenhuma migração de dados foi necessária.

### 3.4 Bottom sheet "O que você quer criar?"

O FAB da tela **Produtos** passou a abrir um `showModalBottomSheet` com o
título **"O que você quer criar?"** e a explicação "Produtos são os itens
comprados. Fichas técnicas são os pratos vendidos.", oferecendo duas opções:

- **Produto** — "Item que entra na receita (ex.: queijo, farinha)." →
  `Navigator.pushNamed('/ingredient-form')`;
- **Receita / Ficha Técnica** — "Prato vendido, com custo e ticket
  calculados." → `Navigator.pushNamed('/product-form')`.

O sheet fecha antes de navegar (`Navigator.pop` + `pushNamed`) e mantém o
padrão visual do app (card escuro, ícone dourado, seta de avanço).

### 3.5 Participação percentual no custo do ticket

Na tela de detalhe da ficha técnica (`product_detail_screen.dart`), cada item
da receita ganhou a linha **"Participação no custo"**, com barra dourada
(`LinearProgressIndicator` com `AppColors.gold`) e o texto
**"{X,X}% do custo total"**. O valor é **derivado na UI**:

```dart
final showShare = !line.missing && totalCost > 0;
final share = showShare
    ? (line.lineCost / totalCost).clamp(0.0, 1.0).toDouble()
    : 0.0;
```

Isso preserva `ProductCalculator` e `LineCost` intactos (sem novo campo no
modelo nem no cálculo): a fração é uma apresentação do mesmo `lineCost` já
calculado, com `clamp` para nunca estourar 100% em dados inconsistentes.

### 3.6 Nome do produto do fornecedor (`productName`)

`IngredientOffer` (`lib/models/ingredient_offer.dart`) ganhou o campo
opcional **`productName`** (default `''`, getter `hasProductName`), com
`fromMap` **tolerante**: valores não-string viram string vazia, e documentos
antigos sem o campo continuam carregando normalmente. O campo é coletado no
formulário de oferta e no mini-form de criação, com o rótulo exato
**"Nome do produto (como o fornecedor anuncia)"** (helper "Ex.: Farinha de
trigo tipo 1 — 5kg", limite visual de 80 caracteres).

No painel **"Comparar preços"**, a busca (`filterPanel`) passa a casar também
com `productName` das ofertas ativas válidas (`_productNames`), mantendo o
hint **"Buscar produto ou fornecedor…"** — ou seja, buscar "farinha tipo 1"
encontra o produto mesmo que o nome interno seja "Farinha".

## 4. Sprint 6 — Unificação e Exportação Excel

### 4.1 Dashboard operacional

O Dashboard (`home_screen.dart`) deixou de ser uma tela de BI e virou uma
**visão operacional**: saudação ("Olá, {primeiro nome}!" e "Visão operacional
do negócio"), card de **Saldo do negócio** com **borda dourada**
(`AppColors.gold` a 40% de opacidade) e atalho de texto **"Relatórios"**;
**Ações rápidas** em três cards ("Ver produtos" → `/ingredients`, "Fichas
técnicas" → `/products`, "Novo orçamento" → `/budget-form`); e a lista
**Movimentações recentes** (últimas 5 transações, com "Ver todas" →
`/expenses`). O gráfico de pizza e os KPIs foram **removidos do Dashboard** —
a análise agora vive em Relatórios. O FAB continua abrindo
`/transaction-form`.

### 4.2 Relatórios em página única

`reports_screen.dart` reúne toda a análise em uma página, com o selo
**"Desempenho e análise do negócio"** e o período fixo **"Últimos 6 meses"**:

1. **KPIs** em grade 2×2: Lucro Líquido, Margem de Lucro, **Total Receitas**
   e **Total de Custos** (os rótulos usam "Custos", não "Despesas");
2. **Receitas vs Custos** (barras, `fl_chart`, verdes × vermelhas, últimos 6
   meses);
3. **Custos por categoria** (pizza, `CategoryPieChart`);
4. **Top 5 Categorias** (barras horizontais com a cor da categoria).

No cabeçalho da página fica o `ExportExcelButton`, com o arquivo
`relatorio_cashctrl_ultimos_6_meses.xlsx`. O botão fica desabilitado quando
não há transações e mostra "Exportando..." durante a geração.

### 4.3 Exportação Excel (3 abas)

`lib/utils/report_export.dart` expõe **`buildReportWorkbook({transactions,
periodLabel})`**, que cria o workbook com o package `excel` e três abas:

Tabela 3. Estrutura do arquivo Excel exportado.

| Aba | Conteúdo |
|-----|----------|
| **Resumo** | Título "Relatório de Desempenho - CashCtrl", período, Lucro Líquido, Margem (%), Total Receitas, **Total Custos**, quantidade de transações e data/hora de geração |
| **Mensal** | Meses (Jan–Dez/ano) com Receitas, Custos e Resultado, mais a linha de total |
| **Transações** | Data, Tipo, Categoria, Descrição, Forma de Pagamento e Valor (despesas negativas), ordenadas da mais recente para a mais antiga |

O estilo do arquivo usa o verde institucional (`#165A41`) no cabeçalho e o
dourado (`#B89775`) no título, mantendo a identidade visual. O download é
**condicional por plataforma**, com `export 'report_export_web.dart' if
(dart.library.io) 'report_export_native.dart'`:

- **Nativo (Android/iOS):** `report_export_native.dart` grava o `.xlsx` em
  diretório temporário (`path_provider`) e abre a share sheet com
  `SharePlus.instance.share(ShareParams(files: [...], subject: 'Relatório
  CashCtrl', ...))` — único arquivo que importa `dart:io`;
- **Web:** `report_export_web.dart` cria um `Blob` (`package:web`), gera
  `URL.createObjectURL`, injeta um `HTMLAnchorElement` com `download` e
  dispara o clique; a URL é revogada após 10 segundos.

### 4.4 Dependências adicionadas

O `pubspec.yaml` passou a declarar:

```
excel: ^4.0.6
path_provider: ^2.1.6
share_plus: ^13.3.1
web: ^1.1.0
```

`mobile_scanner` ainda estava presente nesta etapa e foi **removido na Sprint
7** junto com o scanner (seção 5.1).

### 4.5 Validação no emulador

O fluxo de exportação foi validado no emulador Android: o botão gera o
workbook e a share sheet abre com o arquivo
**`relatorio_cashctrl_ultimos_6_meses.xlsx`** — comprovando o caminho nativo
(`path_provider` + `share_plus`) de ponta a ponta.

## 5. Sprint 7 — Fechamento de UX

### 5.1 Remoção do código de barras

Todo o fluxo de código de barras/scanner foi **removido**:

- a tela `product_scanner_screen.dart` foi **apagada**;
- as rotas `/product-scanner`, `/product-form-with-barcode` e
  `/product-form-with-photo` **deixaram de existir** em `main.dart` — a
  tabela ficou com **22 rotas nomeadas** (eram 25);
- o campo de código de barras saiu do **formulário** de ficha técnica;
- o **modelo** `Product` mantém `barcode` (nullable) e o `fromMap`/`toMap`
  continuam lendo/gravando o campo, para **compatibilidade com dados
  legados**;
- `ProductProvider.findByBarcode` foi removido;
- a dependência **`mobile_scanner`** saiu do `pubspec.yaml`;
- a tela **Fichas Técnicas** ficou com um **FAB único** (`Nova ficha`) que
  abre `/product-form` quando já existem produtos cadastrados e
  `/ingredient-form` quando o parque está vazio.

### 5.2 Correção da foto de perfil

**Sintoma:** o upload da foto de perfil falhava em dispositivo com
`StorageException: -13040` (task cancelada), e havia um fluxo que apagava o
`profile.jpg` antes de enviar o novo (deixando o perfil sem foto quando o
upload falhava).

**Correção em `StorageService`** (`lib/services/storage_service.dart`):

- constantes explícitas `_cancelledCode = -13040` e
  `_retryDelay = 600 ms`;
- `uploadBytes` valida **bytes vazios** antes de enviar
  (`'Falha no upload: Arquivo de imagem vazio.'`);
- o envio é feito por `_putAndGetUrl`, que **retém a `UploadTask` e aguarda**
  (`final task = ref.putData(...); final snapshot = await task;`), evitando o
  cancelamento por perda de referência;
- em erro, `_isCancelled` detecta o código −13040 (ou mensagens com
  "cancel") e faz **uma nova tentativa após 600 ms**; se falhar de novo, lança
  o erro com o detalhe ("Falha no upload após nova tentativa (...)");
- no perfil (`edit_profile_screen.dart`), o `image_picker` faz **downscale
  `maxWidth: 1024`** e **`imageQuality: 82`** antes do upload; **não há mais
  `deleteFile` do `profile.jpg`** no fluxo de perfil (o `StorageService.deleteFile`
  permanece apenas para limpar a foto ao excluir uma ficha técnica em
  `FirestoreService`).

### 5.3 Banner de recriação de perfil

Se a sessão existe mas o documento `users/{uid}` não carrega (perfil
inconsistente), a tela de edição **não bloqueia** o usuário: `UserProvider`
expõe `hasSession` (`uid != null`) e `email` (do perfil ou do `Auth`), e a
tela mostra o `AlertBanner`:

> "Não foi possível carregar o perfil salvo. Preencha e salve para recriá-lo."

com a ação **"Tentar carregar"**, que chama `reloadProfile()` e exibe toast com
o erro quando a leitura falha de novo. Como o `_save` monta o `AppUser`
inteiro a partir dos controllers e do `uid`/`email` (do `Auth`), salvar
**recria o documento**. A saudação do Dashboard ("Olá, vikthor!") foi validada
com esse fluxo no emulador.

### 5.4 FAB do Dashboard e spacer

O Dashboard ganhou um **espaçador fixo de 96 px** no fim do
`SingleChildScrollView` (`const SizedBox(height: 96)`), garantindo que a
última movimentação não fique escondida atrás do FAB/elevação ao rolar até o
fim. O FAB continua levando a `/transaction-form`.

### 5.5 Ofertas na criação do produto

A criação de produto (`ingredient_form_screen.dart`) passou a permitir
**cadastrar ofertas de fornecedores antes de salvar o produto**, sem ida e
volta ao Firestore. A lógica de validação é pura, em
`lib/utils/pending_offers.dart`:

- `buildPendingOffer({supplier, productName, priceInput, quantityInput})`
  valida fornecedor obrigatório, preço > 0 e quantidade > 0, devolvendo
  `PendingOfferValidation` (com `firstError`) ou um `IngredientOffer` pronto;
- `parseOfferNumber` aceita vírgula decimal;
- `pendingOffersHasSupplier` faz o **dedupe** por fornecedor normalizado;
- `canAddPendingOffer` respeita o **limite de 15** (`maxOffersPerIngredient`).

Na tela, o mini-form inline (fornecedor + nome do produto + preço + qtd)
adiciona ofertas a `_pendingOffers`, mostra "Oferta adicionada. Ela será salva
junto com o produto." e a **troca de unidade converte as quantidades
pendentes** (`UnitConverter.convertToIngredientUnit`), bloqueando a troca
quando a conversão não é possível ("Remova as ofertas pendentes antes de
trocar para {unidade}.").

Ao salvar, o produto é criado primeiro (`addIngredient`, que retorna o novo
id) e cada oferta pendente é gravada por `upsertOffer` — **com a auditoria
por batch já existente**. O feedback é:

- sucesso total: **"Produto cadastrado com {N} oferta(s)!"**;
- falha parcial: "Produto cadastrado, mas {X} de {N} oferta(s) falharam:
  {causa}";
- sem ofertas: "Produto cadastrado!".

**Testes:** 10 testes em `test/pending_offers_test.dart` cobrem validação,
parsing com vírgula, dedupe por fornecedor e o limite de 15.

### 5.6 Cards clicáveis e plural de ofertas

Ainda na criação/edição do produto, os cards vazios de **"Fornecedor
padrão"** e **"Ofertas"** agora são **clicáveis**: um `InkWell` abre o
mini-form diretamente (`_openOfferForm`) e o card exibe a dica dourada
**"⊕ Cadastrar fornecedor"** (ícone `add_circle_outline` + texto em
`AppColors.gold`). **Não existe botão externo** de adicionar fornecedor até a
primeira oferta existir; a partir daí, o botão `Adicionar fornecedor` aparece
abaixo da lista (e o texto "A primeira oferta adicionada fica como ativa; as
demais entram na comparação de preços.").

O `OfferCountBadge` teve o plural corrigido: `0` → "sem ofertas", `1` →
**"1 oferta"**, `n` → "{n} ofertas".

## 6. QA Final e Builds

Verificações executadas em 27/10/2026, no estado final do repositório:

- **`dart analyze .`** → **1 issue**, a mesma informação pré-existente:
  `lib/services/auth_service.dart:107:18 - 'updateEmail' is deprecated …
  verifyBeforeUpdateEmail() - deprecated_member_use`;
- **`flutter test`** → **144/144 testes passando, em 13 arquivos**;
- **APK de release** → **61,3 MB** (`61.258.206 bytes`), gerado em
  `build/app/outputs/flutter-apk/app-release.apk`; a redução ante os **77,6 MB**
  anteriores vem da remoção do `mobile_scanner`. O APK continua **assinado com
  chave de debug** (`TODO` de produção em `android/app/build.gradle.kts`) —
  instalável para teste, **não publicável** na Play Store;
- **build web** → concluído, com `build/web/` presente (~43 MB);
- **emulador Android:** roteiro completo validado por screenshots — drawer de
  7 itens, participação % no ticket, sheet "O que você quer criar?", cards
  clicáveis de oferta, exportação Excel com share sheet e a notificação
  automática **"Margem negativa"** (via `runStartupChecks`, quando há ficha
  técnica no vermelho).

Tabela 4. Distribuição dos 144 testes da suíte final (13 arquivos).

| Arquivo | Testes | Escopo |
|---------|-------:|--------|
| `offer_comparator_test.dart` | 23 | Comparação e ranking de ofertas |
| `price_panel_aggregator_test.dart` | 15 | Painel "Comparar preços" |
| `unit_converter_test.dart` | 15 | Conversão de unidades |
| `audit_builder_test.dart` | 15 | Resumos de auditoria no novo vocabulário |
| `ingredient_active_offer_test.dart` | 15 | Oferta ativa do produto |
| `product_calculator_test.dart` | 10 | Cálculo do ticket |
| `recurrence_test.dart` | 10 | Recorrências |
| **`pending_offers_test.dart` (NOVO)** | **10** | Ofertas na criação do produto |
| `transaction_rules_test.dart` | 9 | Regras de transação |
| `offer_upsert_test.dart` | 8 | Upsert de ofertas (dedupe/ordem/teto) |
| `offer_rules_test.dart` | 4 | Limite de 15 e validações |
| `model_roundtrip_test.dart` | 3 | `toMap`/`fromMap` sem perda |
| `widget_test.dart` | 1 | Renderização da tela de cadastro |
| **Total** | **144** | |

## 7. Como Rodar e Testar

### 7.1 Requisitos e comandos

```
$ flutter pub get      # dependências (excel, path_provider, share_plus, web, ...)
$ dart analyze .       # 1 info pré-existente (updateEmail)
$ flutter test         # 144/144 (13 arquivos)
```

**Android (dispositivo físico):**

```
$ flutter run
$ flutter build apk --release
# saída: build/app/outputs/flutter-apk/app-release.apk (61,3 MB, chave debug)
$ adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**Web (local):**

```
$ flutter run -d chrome
$ flutter build web        # build/web/ (~43 MB)
# servir build/web com um servidor estático e abrir no navegador
```

O `.env` é a fonte das chaves do Firebase (via `flutter_dotenv`). No build
web as variáveis ficam **embutidas no bundle** — decisão aceita, com a
segurança real nas regras (`firestore.rules`, `storage.rules`). As regras
devem ser publicadas antes de distribuir
(`firebase deploy --only firestore:rules,storage`).

### 7.2 Fluxos manuais (checklist)

Tabela 5. Checklist de teste manual dos fluxos das Sprints 5–7.

| # | Fluxo | Passos | Resultado esperado |
|---|-------|--------|--------------------|
| 1 | Produto com fornecedor na criação | Produtos → FAB → "Produto" → tocar card "Fornecedor padrão" ou "Ofertas" → preencher fornecedor/produto/preço/qtd → "Adicionar oferta" → Salvar | Toast "Produto cadastrado com 1 oferta(s)!"; produto nasce com oferta ativa e log `offer.create` |
| 2 | Limite e dedupe de ofertas | Adicionar 15 ofertas; tentar a 16ª; repetir fornecedor | Bloqueio no 15º/16º e "Você já adicionou esse fornecedor." |
| 3 | Ticket com participação | Abrir Ficha Técnica → detalhe | Barra dourada e "X,X% do custo total" por item; custo total inalterado |
| 4 | Bottom sheet de criação | Produtos → FAB | Sheet "O que você quer criar?" com Produto e Receita/Ficha Técnica |
| 5 | Foto de perfil | Editar perfil → tocar avatar → tirar/escolher foto | Upload conclui, foto aparece e persiste após salvar; sem `-13040` |
| 6 | Perfil sem documento | Sessão válida sem doc `users/{uid}` | Banner "Não foi possível carregar o perfil salvo…" + "Tentar carregar"; salvar recria o perfil |
| 7 | Export Excel (Android) | Relatórios → Exportar Excel | Share sheet com `relatorio_cashctrl_ultimos_6_meses.xlsx` (abas Resumo/Mensal/Transações) |
| 8 | Export Excel (web) | Relatórios → Exportar Excel no Chrome | Download do `.xlsx` via Blob, sem erro |
| 9 | Dashboard operacional | Abrir Dashboard | Saldo com borda dourada, atalho Relatórios, ações rápidas, 5 recentes; sem pizza/KPIs |
| 10 | Scanner removido | Buscar rotas antigas | `/product-scanner`, `/product-form-with-barcode` e `/product-form-with-photo` não existem; FAB único em Fichas Técnicas |
| 11 | Categorias de negócio | Criar transação | 11 categorias de despesa e 3 de receita; transação antiga (ex.: "Moradia") abre com ícone preservado |
| 12 | Notificação de margem | Abrir o app com ficha técnica no vermelho | Notificação local "Margem negativa" (quando `notifMargem` ativo) |
| 13 | Auditoria no vocabulário | Editar produto/ficha → Auditoria | "Produto X atualizado" / "Ficha técnica X criada"; filtros continuam funcionando |
| 14 | Busca por nome do fornecedor | Comparar preços → buscar nome do produto anunciado | Produto encontrado via `productName` |

## 8. Pendências de Produção

O fechamento funcional está concluído; as pendências restantes são
operacionais/de produção:

1. **Commit das sessões** — as alterações das Sprints 5–7 seguem no worktree;
   o commit será feito **quando o usuário pedir** (nenhum commit foi criado
   por esta documentação).
2. **Assinatura de release** — o APK usa chave de debug
   (`android/app/build.gradle.kts`, `TODO`); é preciso criar
   `key.properties` + keystore fora do repositório para publicar.
3. **Bundle identifier** — `com.example.ctrlcash` é placeholder histórico;
   renomear junto com a assinatura, antes da loja.
4. **Deploy das regras** — `firebase deploy --only firestore:rules,storage`
   segue pendente; a **política TTL de 180 dias** no campo `expireAt` de
   `price_audit_logs` precisa ser ativada no console/GCP.
5. **iOS adiado** — sem macOS/Xcode; o apêndice iOS do relatório da Sprint 6
   continua válido (`flutter create --platforms=ios`, Firebase iOS,
   `GoogleService-Info.plist`, `pod install`, build no Mac).
6. **"Insumos" como nome de categoria persistido** — a categoria de despesa
   "Insumos" é gravada como string no Firestore; renomeá-la na UI exigiria
   migração de dados (mantida por compatibilidade).

## 9. Glossário

Tabela 6. Glossário do domínio do CashCtrl.

| Termo (UI) | Equivalente técnico | Definição |
|------------|---------------------|-----------|
| **Produto** | `Ingredient` (`ingredients`) | Item comprado que entra na receita (queijo, farinha), com unidade, preço de compra e ofertas de fornecedores |
| **Ficha Técnica** | `Product` (`products`) | Prato/receita vendida, com itens, quantidades, mão de obra, embalagem e preço de venda |
| **Oferta** | `IngredientOffer` (`offers[]`) | Preço de um fornecedor para um produto (embalagem, quantidade, preço por unidade, nome anunciado) |
| **Fornecedor** | campo `supplier` (texto) | Parceiro que vende o produto; não tem login nem portal — é digitado pelo dono |
| **Ticket** | `TicketResult` | Resultado do cálculo da ficha técnica: custo por item, custo total, lucro/prejuízo, margem e markup |
| **Auditoria** | `PriceAuditLog` (`price_audit_logs`) | Histórico append-only das mutações de preço, com resumo legível e TTL reservado de 180 dias |

## 10. Estado Final e Considerações

O CashCtrl encerra o ciclo em estado de **fechamento funcional**:

- **identidade preservada** — paleta (`0xFF0D1E16`, `0xFF165A41`,
  `0xFFB89775`, `0xFF142A20`, `0xFF7A8B83`) e camaleão intactos; o dourado no
  Dashboard continua via `goldLogo`/`ColorFiltered` (`BlendMode.srcIn`);
- **22 rotas nomeadas** em `main.dart` (3 removidas na Sprint 7 com o
  scanner), sem outras quebras de navegação;
- **`firestore.rules` e `storage.rules` intactos** — isolamento por UID,
  append-only em `price_audit_logs`, `amount > 0` em transações;
- **features consolidadas** — vocabulário de negócio, categorias de
  restaurante, dashboard operacional, relatórios em página única com Excel,
  ofertas na criação do produto, foto de perfil estável e perfil recriável;
- **QA limpo** — 144/144 testes em 13 arquivos, analyze com 1 info
  pré-existente, APK de 61,3 MB e build web funcional;
- **sem segredos no documento** — nenhum valor de `.env`, keystore ou
  `google-services.json` foi lido ou citado.

As pendências (seção 8) são de produção e de operação, não de código: commit
sob demanda, assinatura/keystore, bundle id, deploy das regras + TTL, iOS
adiado e a categoria legada "Insumos".

## Referências

- Código-fonte: `lib/main.dart`, `lib/home_screen.dart`,
  `lib/reports_screen.dart`, `lib/widgets/app_drawer.dart`,
  `lib/widgets/offer_count_badge.dart`, `lib/widgets/export_excel_button.dart`,
  `lib/utils/categories.dart`, `lib/utils/audit_builder.dart`,
  `lib/utils/pending_offers.dart`, `lib/utils/report_export.dart`,
  `lib/utils/report_export_native.dart`, `lib/utils/report_export_web.dart`,
  `lib/services/storage_service.dart`, `lib/providers/user_provider.dart`,
  `lib/screens/ingredients_screen.dart`,
  `lib/screens/ingredient_form_screen.dart`,
  `lib/screens/ingredient_offers_screen.dart`,
  `lib/screens/products_screen.dart`,
  `lib/screens/product_form_screen.dart`,
  `lib/screens/product_detail_screen.dart`,
  `lib/screens/settings/edit_profile_screen.dart`.
- Regras de segurança: `firestore.rules`, `storage.rules`.
- Testes: os 13 arquivos de `test/` (Tabela 4), incluindo
  `pending_offers_test.dart`.
- Documentação de apoio: `docs/overview.md` (atualizado nesta entrega);
  `context/erros-a-evitar.md` (§1.1 segredos, §1.3 web);
  `documentacao/CTRLCASH_SPRINT6_FECHAMENTO_QA_RT.docx`.
- Relatórios anteriores do padrão BIBLIOTECA:
  `documentacao/BIBLIOTECA_113_RT_279.docx` (template),
  `documentacao/CTRLCASH_SPRINT2_PROPOSTA_A_RT.docx`,
  `documentacao/CTRLCASH_SPRINT3_PAINEL_COMPARACAO_FUTURO_RT.docx`,
  `documentacao/CTRLCASH_SPRINT4_MODULO_COMPARATIVO_RT.docx`.

---

## Figuras pendentes (capturas de tela)

- Figura 24 — Dashboard operacional (saldo com borda dourada, atalho
  Relatórios, ações rápidas e movimentações recentes).
  `[captura de tela pendente]`
- Figura 25 — Relatórios em página única com o botão "Exportar Excel".
  `[captura de tela pendente]`
- Figura 26 — Bottom sheet "O que você quer criar?" na tela Produtos.
  `[captura de tela pendente]`
- Figura 27 — Ofertas na criação do produto (mini-form inline e card vazio
  clicável com "⊕ Cadastrar fornecedor").
  `[captura de tela pendente]`
- Figura 28 — Ticket com participação percentual por item (barra dourada).
  `[captura de tela pendente]`
- Figura 29 — Foto de perfil e banner de recriação de perfil.
  `[captura de tela pendente]`

*(Numeração contínua após as Figuras 21–23 do relatório da Sprint 6; capturas
a inserir quando houver dispositivo/emulador.)*
