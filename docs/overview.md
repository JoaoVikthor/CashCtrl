# CtrlCash / CashCtrl — Documentação do App

Aplicativo de controle financeiro pessoal e de negócio em Flutter com Firebase, focado em calcular o ticket das fichas técnicas para mostrar se cada item dá lucro ou prejuízo.

**Versão definitiva: 1.0.0+1 (28/10/2026).** 30/10/2026 — Sprint 9: Desperdício (%) em lugar do Fator de Correção (fator = 100/(100−%), storage `correctionFactor` mantido) e campo de quantidade estilo calculadora (máscara por unidade); 213 testes verdes. 29/10/2026 — Sprint 8: regra Sebrae (Fator de Correção + Peso Médio) implementada de forma invisível; 176 testes verdes. Os módulos de foto (captura com `image_picker` e upload ao Firebase Storage) foram **removidos** do app, pois o upload não persistia; o avatar do perfil exibe as iniciais do nome. O leitor de código de barras também não faz mais parte do app. Login exclusivamente e-mail/senha.

## Visão Geral

O CashCtrl é um app mobile/web de gestão financeira que permite ao usuário:

- Autenticar-se com e-mail/senha (Firebase Auth), com redefinição de senha.
- Gerenciar transações financeiras (receitas e despesas) com categorias de negócio, métodos de pagamento e recorrência.
- Criar e acompanhar orçamentos mensais por categoria, com progresso em tempo real.
- Acompanhar um dashboard operacional com saldo do negócio, atalho para relatórios, ações rápidas e movimentações recentes.
- Analisar o desempenho em uma página única de relatórios (KPIs, receitas vs custos, custos por categoria e top 5) e exportar os dados para Excel (3 abas: Resumo, Mensal e Transações).
- Cadastrar um parque de produtos (itens comprados para fabricar as fichas técnicas), com cálculo automático de preço por unidade.
- Comparar ofertas de fornecedores por produto (preço por unidade, ranking com badges "ATIVA"/"melhor"), com nome do produto anunciado pelo fornecedor, escolhendo manualmente a oferta ativa que alimenta o ticket, com cartão informativo de economia possível.
- Cadastrar ofertas já na criação do produto (mini-form inline de fornecedor + produto + preço + quantidade, até 15 ofertas).
- Consultar o histórico de auditoria de preços (logs append-only em `price_audit_logs`; o campo `expireAt` é reservado para política TTL de 180 dias, a ativar no console).
- Criar fichas técnicas (ex.: um sanduíche), selecionando produtos, quantidades, mão de obra e embalagem.
- Visualizar o ticket da ficha técnica: custo por item com participação percentual no custo, custo total, ganho/perda e veredito final de lucro ou prejuízo.
- O cadastro de produto admite Peso Médio da unidade (g) e Desperdício (%) (regra Sebrae) opcionais; na montagem da ficha a quantidade é digitada em campo estilo calculadora com máscara por unidade (un/pct com 1 casa, g/ml inteiro, kg/L com 3 casas) e o sistema converte e aplica o fator de correção de forma invisível (storage `correctionFactor` mantido), exibindo na linha do ticket apenas o valor final em dinheiro.
- Editar perfil, configurar notificações, segurança e acessar a central de ajuda.

## Stack / Tecnologias

- **Linguagem:** Dart (SDK ^3.11.5)
- **Framework:** Flutter (Android e Web; iOS adiado)
- **Backend:** Firebase
  - `firebase_core` — inicialização
  - `firebase_auth` — autenticação (e-mail/senha)
  - `cloud_firestore` — banco de dados NoSQL (CRUD isolado por UID)
- **Estado:** `provider` (ChangeNotifierProvider, StreamProvider)
- **Gráficos:** `fl_chart` (barras e pizza)
- **Notificações locais:** `flutter_local_notifications`
- **Excel:** `excel` (geração do workbook), `path_provider` + `share_plus` (nativo) e `web` (download no navegador)
- **Config:** `flutter_dotenv` (variáveis de ambiente para chaves do Firebase)

## Design System

Paleta de cores centralizada e reutilizada em todas as telas:

- Fundo: `0xFF0D1E16` (verde escuro)
- Verde Primário: `0xFF165A41`
- Dourado: `0xFFB89775`
- Cards: `0xFF142A20`
- Texto Secundário: `0xFF7A8B83`

Logo: `assets/images/logo.png` (camaleão nas cores do app, fundo transparente). No Dashboard, a AppBar aplica o camaleão dourado com `ColorFiltered`/`BlendMode.srcIn` no dourado institucional (`goldLogo`).

## Estrutura de Pastas

```
lib/
  main.dart                      # Inicializa .env, Firebase, providers e rotas
  firebase_options.dart          # Lê config do Firebase de .env (sem hardcoded keys)
  home_screen.dart               # Dashboard operacional (saldo, ações rápidas, recentes)
  budgets_screen.dart            # Orçamentos com progresso calculado em tempo real
  expenses_screen.dart           # Transações com filtros, busca e exclusão
  reports_screen.dart            # Página única de relatórios + exportação Excel
  settings_screen.dart           # Configurações com perfil do usuário
  models/                        # Models de dados (puros, com fromMap/toMap)
    app_user.dart                # Perfil do usuário + dados do negócio
    transaction.dart             # Transação (receita/despesa, método de pagamento)
    budget.dart                  # Orçamento mensal por categoria
    ingredient.dart              # Produto (preço de compra → preço por unidade; ofertas[]; peso médio e Desperdício (%); storage `correctionFactor`)
    ingredient_offer.dart        # Oferta de fornecedor (supplier, productName, preço/qtd)
    price_audit_log.dart         # Log de auditoria de preços (append-only)
    product.dart                 # Ficha técnica (receita + custos + venda; barcode legado)
  providers/                     # Estado global (ChangeNotifier + streams)
    user_provider.dart           # Perfil + negócio (Firestore)
    transaction_provider.dart    # Stream de transações
    budget_provider.dart         # Stream de orçamentos
    ingredient_provider.dart     # Stream de produtos (mapa id→Ingredient) + ofertas e auditLogs
    product_provider.dart        # Stream de fichas técnicas
  services/                      # Camada de acesso ao Firebase
    auth_service.dart            # FirebaseAuth (login, cadastro, logout)
    firestore_service.dart       # CRUD no Firestore (isolado por UID) + ofertas com log em batch
    notification_service.dart    # Notificações locais (orçamento, recorrência, margem)
  screens/                       # Telas
    login_screen.dart            # Login (e-mail/senha)
    cadastro_screen.dart         # Cadastro multi-etapa (pessoal + negócio, sem foto)
    transaction_form_screen.dart # Nova/editar transação
    budget_form_screen.dart      # Novo/editar orçamento
    ingredients_screen.dart      # Lista de produtos + atalho de comparação de preços
    ingredient_form_screen.dart  # Cadastrar/editar produto (ofertas inline na criação)
    ingredient_offers_screen.dart # Comparativo de fornecedores do produto
    offer_form_screen.dart       # Nova/editar oferta de fornecedor
    audit_logs_screen.dart       # Histórico de auditoria de preços, somente leitura
    products_screen.dart         # Lista de fichas técnicas com veredito de lucro/prejuízo
    product_form_screen.dart     # Ficha técnica (receita + custos + venda; sem foto)
    product_detail_screen.dart   # Ticket da ficha técnica (participação % por item)
    compare_prices_screen.dart   # Painel "Comparar preços" (produto/fornecedor)
    settings/
      edit_profile_screen.dart   # Editar perfil (avatar com iniciais, sem upload)
      notifications_screen.dart  # Preferências de notificações
      security_screen.dart       # Segurança e privacidade
      help_screen.dart           # Central de ajuda
      terms_privacy_screen.dart  # Termos e privacidade
  theme/                         # Design tokens (cores, tipografia, espaçamento)
  utils/                         # Utilitários e lógica pura
    categories.dart              # Categorias de negócio (despesa/receita) + legadas
    format.dart                  # Formatação de moeda (R$) e datas (pt-BR)
    product_calculator.dart      # Calculadora do ticket (lucro/prejuízo, margem, markup)
    offer_comparator.dart        # Comparação de ofertas: ranking, delta e cenário
    offer_rules.dart             # Upsert de ofertas (match por id) e limite de 15
    pending_offers.dart          # Ofertas em memória na criação do produto
    price_panel_aggregator.dart  # Agregação do painel de preços
    report_export.dart           # Workbook Excel (Resumo, Mensal, Transações)
    report_export_native.dart    # Salva e compartilha o .xlsx (Android)
    report_export_web.dart       # Download do .xlsx via Blob no navegador
    audit_builder.dart           # Resumos de auditoria no vocabulário da UI
    sebrae_rules.dart          # Regra Sebrae (Peso Médio + Desperdício (%), lógica pura; helpers `factorFromWastePercent` e `wastePercentFromFactor`)
    quantity_mask.dart           # Máscara de quantidade estilo calculadora por unidade (un/pct, g/ml, kg/L)
    recurrence.dart, unit_converter.dart, app_info.dart
  widgets/                       # Widgets reutilizáveis
    app_drawer.dart              # Menu lateral com navegação
    app_branded_header.dart      # AppBar padrão com logo (opção dourada)
    category_pie_chart.dart      # Gráfico de pizza de despesas (fl_chart)
    export_excel_button.dart     # Botão "Exportar Excel"
    offer_count_badge.dart, best_price_chip.dart, active_offer_marker.dart,
    delta_price_text.dart, section_header.dart, search_field.dart,
    filter_chip_row.dart, empty_state.dart, error_state.dart,
    offer_limit_banner.dart, confirm_action_dialog.dart, offer_card.dart,
    audit_entry_tile.dart, economy_summary_card.dart
                                 # Widgets do comparativo de fornecedores/auditoria
android/                          # Configuração Android (google-services.json local)
web/                             # Configuração web
context/                          # Regras do assistente (erros a evitar)
docs/                            # Esta documentação
firestore.rules                  # Regras de segurança do Firestore (isolamento por UID)
```

## Modelo de Dados (Firestore)

Todos os dados ficam sob `users/{uid}/...`, garantindo isolamento total por usuário (RN02):

- `users/{uid}` — perfil do usuário (nome, e-mail, empresa, CNPJ, segmento, telefone, endereço)
- `users/{uid}/transactions/{txId}` — transações (tipo, categoria, valor, data, método de pagamento, recorrência)
- `users/{uid}/budgets/{budgetId}` — orçamentos (categoria, limite mensal)
- `users/{uid}/ingredients/{ingredientId}` — produtos (nome, unidade, preço de compra, quantidade da embalagem, `offers[]` com até 15 ofertas de fornecedores, `activeOfferId`, `averageUnitWeightGrams` (opcional) e `correctionFactor` (padrão 1.0; interface como Desperdício (%)))
- `users/{uid}/products/{productId}` — fichas técnicas (nome, receita[] — cujas linhas guardam `inputUnit`, a unidade digitada, quando informada —, mão de obra, embalagem, preço de venda; `barcode` mantido apenas para legado)
- `users/{uid}/price_audit_logs/{logId}` — logs de auditoria de preços (append-only: `action`, `entityType`, `entityId`, `summary`, preços antes/depois, `timestamp` serverTimestamp, `expireAt` +180 dias)

## O Ticket da Ficha Técnica (recurso central)

O coração do app é mostrar ao usuário o ticket de cada ficha técnica. O fluxo:

1. Usuário cadastra produtos no parque (ex.: pão R$ 10,00/20un → R$ 0,50/un), opcionalmente já com ofertas de fornecedores.
2. Cria uma ficha técnica (ex.: "Sanduíche X") selecionando produtos e quantidades (2 fatias de pão, 100g de queijo, etc.), mão de obra e embalagem.
3. O app calcula: custo por item (qtd × preço por unidade), participação percentual de cada item no custo total, subtotal, custo total, preço de venda, lucro/prejuízo e margem. Quando o produto tem Peso Médio/Desperdício (%), a quantidade é convertida para a unidade-base e multiplicada pelo fator de correção (bruto = líquido × fator) antes de precificar — sem nada disso aparecer na tela; exemplo canônico: tomate R$ 10,00/kg, 3% de desperdício (fator ≈ 1,0309), 60 g líquidos → ~61,86 g brutos → ~R$ 0,62.
4. O ticket mostra o veredito: "Dá lucro" ou "Dá prejuízo", com margem e markup.

A fórmula exata: `custoTotal = Σ(qtd × preço/un) + mão de obra + embalagem`. Por isso o custo de uma ficha pode ser maior que a soma dos preços de compra dos insumos — mão de obra e embalagem entram no cálculo.

## Relatórios e Exportação

A aba Relatórios reúne, em página única: KPIs (lucro líquido, margem, total de receitas e total de custos), gráfico "Receitas vs Custos" dos últimos 6 meses, "Custos por categoria" e "Top 5 Categorias". O botão "Exportar Excel" gera `relatorio_cashctrl_ultimos_6_meses.xlsx` com as abas Resumo, Mensal e Transações; no Android o arquivo é salvo em diretório temporário e compartilhado pela share sheet, e na web o download é feito via Blob + âncora.

## Segurança

- As credenciais do Firebase NÃO estão no código. São lidas de `.env` via `flutter_dotenv`.
- `.env` e `google-services.json` estão no `.gitignore` (não versionados).
- `firestore.rules` garantem isolamento por UID (cada usuário só acessa seus próprios dados); transações exigem `amount > 0`; logs de auditoria são imutáveis (`update, delete: if false`).
- Keystores e `local.properties` também estão no `.gitignore`.
- No build web, as variáveis do `.env` são embutidas no bundle JS; a segurança efetiva vem das regras do Firebase.

## Como rodar localmente

1. Copie `.env.example` para `.env` e preencha os valores do Firebase.
2. Coloque `google-services.json` em `android/app/` (baixe do Firebase Console).
3. Publique as regras ANTES de rodar o app atualizado: `firebase deploy --only firestore:rules` (o app grava em `price_audit_logs` desde a primeira mutação).
4. `flutter pub get`
5. `flutter run` (dispositivo) ou `flutter run -d chrome` (web)
6. Testes: `flutter test` • Verificação estática: `dart analyze .`
7. Builds: `flutter build apk --release` e `flutter build web`

## Repositório

- Origin: `https://github.com/JoaoVikthor/ctrlcash.git`
- Nome de exibição: **CashCtrl** (marca/app); `ctrlcash` é o nome do repositório/pacote Flutter.
