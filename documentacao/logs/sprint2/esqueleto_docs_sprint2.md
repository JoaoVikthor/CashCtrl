# Documentação Técnica do CashCtrl — Sprint 2 (Proposta A — Comparação de Fornecedores)

> **Status: ESQUELETO (fase pré-implementação).** Este documento espelha a estrutura e a
> terminologia do relatório técnico ICMC `documentacao/BIBLIOTECA_113_RT_279.docx`
> (relatório "Documentação Técnica da Aplicação Web Homework"). As seções marcadas com
> `[PENDENTE IMPLEMENTAÇÃO]` só poderão ser preenchidas após a codificação do Sprint 2.
> Pipeline de geração do `.docx` final: `cashctrl_tecnica.md` → `cashctrl_tecnica.html`
> (estilos do template) → `soffice --headless --convert-to docx` →
> `documentacao/CASHCTRL_DOCUMENTACAO_TECNICA.docx`.

---

## Capa (página 1 — sem numeração de seção)

*(padrão BIBLIOTECA: título centralizado, autores, instituição, local e data)*

- **Título:** Documentação Técnica da Aplicação Móvel CashCtrl — Sprint 2
- **Subtítulo/escopo:** Proposta A — Comparação de Fornecedores (ofertas por insumo,
  ticket com oferta ativa e logs de auditoria de preços)
- **Autores:** [PENDENTE IMPLEMENTAÇÃO — confirmar nomes/e-mails da equipe]
- **Instituição:** estilo "RELATÓRIOS TÉCNICOS DO ICMC" do template
  *(no CashCtrl: documento interno do projeto — ajustar selo/linha institucional)*
- **Local/data:** São Carlos — Outubro/2026

<!-- estilo: título capa Verdana/Times 20–16pt centralizado; corpo Times; sem numeração -->

---

## Índice

*(padrão BIBLIOTECA: título "Indice" em Ttulo1 sem numeração, entradas Sumrio1/Sumrio2
com número de página à direita; no HTML gerar TOC estático)*

- 1. Introdução
- 2. Visão Geral do CashCtrl
- 3. Requisitos do CashCtrl
  - 3.1 Requisitos não-funcionais
  - 3.2 Requisitos funcionais do Sprint 2
- 4. Projeto Lógico e Implementação do Sprint 2
  - 4.1 Separação de Interesses (SoC) — arquitetura Flutter + Firebase
  - 4.2 Estrutura de diretórios e subdiretórios
  - 4.3 Descrição da Implementação
    - 4.3.1 Diretório `lib/models`
    - 4.3.2 Diretório `lib/utils`
    - 4.3.3 Diretório `lib/services`
    - 4.3.4 Diretório `lib/providers`
    - 4.3.5 Diretório `lib/screens`
    - 4.3.6 Diretório `lib/widgets`
    - 4.3.7 Regras de segurança (`firestore.rules`)
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

*(padrão BIBLIOTECA: 2 parágrafos curtos — o que o relatório apresenta e qual o objetivo)*

Este relatório apresenta a documentação técnica do **Sprint 2** do CashCtrl, aplicativo
móvel desenvolvido em Flutter com backend Firebase, referente à implementação da
**Proposta A — Comparação de Fornecedores**. Neste relatório estão os principais
documentos para o entendimento técnico da solução: o modelo de dados de ofertas por
insumo, os logs de auditoria de preços, as regras de negócio do ticket e os detalhes de
implementação das telas.

O objetivo dessa documentação é propiciar uma visão abrangente dos recursos
implementados no Sprint 2 e incentivar que a ferramenta seja rapidamente compreendida
por desenvolvedores interessados em evoluir suas características.

> `[PENDENTE IMPLEMENTAÇÃO]` — revisar o texto após o código refletir o que foi
> efetivamente entregue.

---

## 2. Visão Geral do CashCtrl

*(padrão BIBLIOTECA: parágrafo descritivo do software + contexto do sprint)*

O CashCtrl é um aplicativo móvel (Flutter/Firebase, tema escuro com acentos verdes e
dourados) para microempreendedores, com gestão financeira (transações, orçamentos,
relatórios) e cálculo de ficha técnica de produtos ("ticket"), que aponta lucro ou
prejuízo por produto.

No Sprint 1 o insumo possuía um único preço (`purchasePrice` + `packageQuantity` →
`pricePerUnit`), lido ao vivo pelo `ProductCalculator`. O Sprint 2 (Proposta A) evolui o
parque de insumos para suportar **múltiplas ofertas de fornecedores por insumo**, com
comparação por preço/unidade, oferta ativa escolhida pelo usuário alimentando o ticket,
alerta de economia e logs de auditoria append-only.

> `[PENDENTE IMPLEMENTAÇÃO]` — confirmar números de versão (`pubspec.yaml`) e escopo
> final entregue.

---

## 3. Requisitos do CashCtrl

*(padrão BIBLIOTECA: seção "Requisitos" com requisitos não-funcionais orientando a
arquitetura e lista de requisitos funcionais em PargrafodaLista)*

### 3.1 Requisitos não-funcionais

Requisitos prioritários considerados para o Sprint 2 (mantidos do Sprint 1 e
estendidos):

- **Isolamento (RN02):** todos os dados continuam sob `users/{uid}/...`; nenhum usuário
  acessa dados de outro (Firestore e Storage).
- **Auditabilidade:** toda mutação de preço gera log append-only com retenção definida.
- **Zero regressão:** o cálculo do ticket legado não pode mudar de resultado para
  insumos migrados (fallback no `ProductCalculator`).
- **Manutenibilidade:** SoC mantido — models, lógica pura em `utils/`, services,
  providers e screens em camadas separadas.
- **Segurança:** regras Firestore atualizadas e **deployadas antes do app**; chaves
  apenas em `.env` (nunca hardcoded).

### 3.2 Requisitos funcionais do Sprint 2

- suporte a múltiplas ofertas de fornecedor por insumo (teto de 15 ofertas),
- comparação de ofertas por preço/unidade (`pricePerUnit`) com ranking ascendente,
- oferta ativa (`activeOfferId`) escolhida manualmente pelo usuário para alimentar o
  ticket,
- badges "MAIS BARATO" e "OFERTA ATIVA" no comparativo,
- alerta de economia no ticket ("Poderia economizar R$ X usando {fornecedor}"),
- upsert por fornecedor normalizado (mesmo fornecedor não duplica),
- logs de auditoria append-only com retenção de 180 dias,
- migração lazy e idempotente dos insumos legados (sem `offers[]`),
- tela de histórico de auditoria (somente leitura).

> `[PENDENTE IMPLEMENTAÇÃO]` — validar a lista contra o código final (itens cortados do
> MVP, se houver).

---

## 4. Projeto Lógico e Implementação do Sprint 2

*(padrão BIBLIOTECA: seção "Projeto Lógico e Implementação" com SoC, estrutura de
diretórios, descrição por arquivo, DER e esquema)*

### 4.1 Separação de Interesses (SoC) — arquitetura Flutter + Firebase

Para garantir manutenibilidade, foi mantida a abordagem de Separação de Interesses
(Separation of Concerns — SoC) em camadas:

- **Lógica:** classes puras em Dart (`lib/utils/`) — ranking de ofertas, cálculo de
  delta/economia e cenário "melhor fornecedor" do ticket, sem dependência de Widgets.
- **Dados:** models (`lib/models/`) e acesso ao Firestore (`lib/services/`), com dados
  isolados por UID sob `users/{uid}/...` e streams em tempo real.
- **Apresentação:** providers (`lib/providers/`) e telas (`lib/screens/`,
  `lib/widgets/`), tema escuro com paleta existente (`colorBackground`,
  `colorGreenPrimary`, `colorGold`, `colorCard`).

> `[PENDENTE IMPLEMENTAÇÃO]` — descrever os módulos novos exatamente como ficarem no
> código (nomes de arquivos/classes finais).

### 4.2 Estrutura de diretórios e subdiretórios

*(padrão BIBLIOTECA: árvore de diretórios como "Figura 1" + descrição por arquivo em
PargrafodaLista no formato `arquivo: descrição`)*

Arquivos previstos/afetados pelo Sprint 2 (conforme plano técnico da Proposta A):

```
lib/
|-- models/
|   |-- ingredient.dart          (modificado: offers[], activeOfferId, campos sintéticos)
|   |-- ingredient_offer.dart    (novo: modelo IngredientOffer)
|   |-- price_audit_log.dart     (novo: modelo PriceAuditLog)
|-- utils/
|   |-- offer_logic.dart         (novo: ranking, delta, cenário best — lógica pura)
|   |-- product_calculator.dart  (modificado: fallback legado + cenário melhor fornecedor)
|-- services/
|   |-- firestore_service.dart   (modificado: CRUD ofertas + log em batch + migração lazy)
|-- providers/
|   |-- ingredient_provider.dart (modificado: ofertas, sincronização de default)
|-- screens/
|   |-- ingredients_screen.dart          (modificado: badge "N ofertas", chip "★ melhor")
|   |-- ingredient_form_screen.dart      (modificado: seção fornecedor + gerenciar ofertas)
|   |-- ingredient_offers_screen.dart    (novo: comparativo/ranking)
|   |-- offer_form_screen.dart           (novo: formulário de oferta)
|   |-- product_detail_screen.dart       (modificado: cenário melhor fornecedor + economia)
|   |-- audit_logs_screen.dart           (novo: histórico de auditoria, leitura)
|-- widgets/
    (ajustes pontuais se necessário)
firestore.rules                  (modificado: match de price_audit_logs antes do catch-all)
test/                            (novos testes da lógica pura)
```

> `[PENDENTE IMPLEMENTAÇÃO]` — substituir por árvore real extraída do repositório após o
> sprint e inserir como **Figura 1** (captura/árvore gerada). Sem screenshot, usar
> `[Figura 1 — captura de tela pendente]`.

### 4.3 Descrição da Implementação

*(padrão BIBLIOTECA: subtítulos por diretório e listas `arquivo: descrição`)*

#### 4.3.1 Diretório `lib/models`

- `ingredient_offer.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — modelo da oferta embutida:
  `id`, `supplier`, `packagePrice`, `packageQuantity`, `pricePerUnitCache`,
  `isActive`, `isDefault`, `source` (`manual` | `migration`), `notes`, `createdAt`,
  `updatedAt`; serialização `fromMap`/`toMap` e normalização de fornecedor para upsert.
- `price_audit_log.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — modelo do log de auditoria com
  campos mínimos (ver 4.5) e `expireAt`.
- `ingredient.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — ajustes: `offers[]` (máx. 15),
  `activeOfferId`, `lowestPricePerUnit`, `bestSupplier`, `offersCount`; `toMap`/merge
  nunca apagando ofertas existentes.

#### 4.3.2 Diretório `lib/utils`

- `offer_logic.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — funções puras: `pricePerUnit =
  packagePrice / packageQuantity`; ranking de ofertas ativas por preço/unidade
  ascendente; `deltaLinha = (preçoUsadoNoTicket − melhorPreço) × qty`;
  `economiaTicket = Σ deltaLinha`; ordenação estável com centavos.
- `product_calculator.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — ticket continua usando a
  oferta ativa do insumo; fallback legado (`purchasePrice/packageQuantity`) quando não
  houver ofertas; cenário "melhor fornecedor" + economia para o alerta do ticket.

#### 4.3.3 Diretório `lib/services`

- `firestore_service.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — CRUD de ofertas com teto de 15
  e upsert por fornecedor; gravação do log de auditoria **em batch** com a mutação do
  documento (evita preço alterado sem log); migração lazy idempotente; leitura dos logs
  para a tela de auditoria.

#### 4.3.4 Diretório `lib/providers`

- `ingredient_provider.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — exposição das ofertas por
  insumo, mapa id→ingrediente para a calculadora e sincronização da oferta
  default/ativa.

#### 4.3.5 Diretório `lib/screens`

- `ingredients_screen.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — badge "N ofertas", preço da
  oferta ativa, chip "★ melhor".
- `ingredient_form_screen.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — seção de fornecedor
  padrão + acesso ao gerenciamento de ofertas.
- `ingredient_offers_screen.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — comparativo: ranking
  por preço/unidade, delta (Δ), filtros (ativas/inativas/padrão, busca por fornecedor,
  ordenação padrão mais barata, toggle "só Δ econômico"), aviso de embalagens de
  tamanhos diferentes, CTA adicionar oferta.
- `offer_form_screen.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — fornecedor, preço da
  embalagem, quantidade, preview R$/un; validação dura `packagePrice > 0` e
  `packageQuantity > 0`; bloqueio da 16ª oferta.
- `product_detail_screen.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — cenário "melhor
  fornecedor" por linha + economia total; alerta quando existir oferta mais barata que
  a ativa.
- `audit_logs_screen.dart`: `[PENDENTE IMPLEMENTAÇÃO]` — histórico de auditoria
  (somente leitura), resumo em PT-BR por evento.

#### 4.3.6 Diretório `lib/widgets`

- `[PENDENTE IMPLEMENTAÇÃO]` — listar widgets novos/ajustados (ex.: badge de oferta,
  linha de ranking), se houver.

#### 4.3.7 Regras de segurança (`firestore.rules`)

- `[PENDENTE IMPLEMENTAÇÃO]` — novo `match /users/{uid}/price_audit_logs/{logId}`
  inserido **antes** do catch-all `match /{document=**}`; `allow create` apenas do dono
  com campos mínimos; `allow update, delete: if false` (append-only); leitura restrita
  ao dono. O `match /ingredients/{ingredientId}` existente permanece (escrita do dono),
  com validação extra de `packagePrice`/`packageQuantity` no formulário (reforço nas
  rules é evolução futura).

### 4.4 Modelo de Dados — `IngredientOffer` embutido no insumo

*(decisão do gate: array `offers[]` no documento do insumo — MVP; subcoleção é
caminho de evolução v1.1+)*

Caminho: `users/{uid}/ingredients/{ingredientId}` (documento existente, estendido).

Campos novos no documento do insumo:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `activeOfferId` | String? | Oferta que alimenta o ticket (escolha manual do usuário) |
| `lowestPricePerUnit` | double? | Cache do menor preço/unidade entre as ofertas |
| `bestSupplier` | String? | Cache do fornecedor da oferta mais barata |
| `offersCount` | int? | Cache da quantidade de ofertas |
| `offers` | Array | Lista de ofertas (teto duro: **15**) |

Estrutura de cada item de `offers[]` (`IngredientOffer`):

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | String | Identificador da oferta |
| `supplier` | String | Nome do fornecedor (normalizado para upsert) |
| `packagePrice` | double | Preço pago pela embalagem (**> 0**, validação dura) |
| `packageQuantity` | double | Quantidade da embalagem (**> 0**, validação dura) |
| `pricePerUnitCache` | double | `packagePrice / packageQuantity` |
| `isActive` | bool | Oferta habilitada para comparação |
| `isDefault` | bool | Oferta padrão (recalculada) |
| `source` | String | `manual` (criada pelo usuário) ou `migration` (gerada na migração) |
| `notes` | String? | Observações |
| `createdAt` | String/Timestamp | Criação |
| `updatedAt` | String/Timestamp | Última atualização |

Justificativa do MVP em array (do relatório de inovações): 1 leitura, ticket sem join,
menor complexidade; limites conhecidos (~1 MB por documento, concorrência
last-write-wins) são aceitáveis para 3–10 fornecedores típicos, com teto de 15.

> `[PENDENTE IMPLEMENTAÇÃO]` — confirmar tipos finais (Timestamp vs ISO 8601 string,
> padrão do projeto) e se `isDefault` entra no MVP ou só `activeOfferId`.

### 4.5 Logs de Auditoria de Preços

Caminho: `users/{uid}/price_audit_logs/{logId}` — coleção **append-only** (só criação;
update/delete negados nas rules).

Tabela de eventos auditados:

| Ação do usuário | `action` do log |
|-----------------|-----------------|
| Criar insumo | `ingredient.create` |
| Editar insumo | `ingredient.update` |
| Excluir insumo | `ingredient.delete` |
| Criar oferta | `offer.create` |
| Editar oferta | `offer.update` |
| Ativar/desativar oferta | `offer.toggleActive` |
| Definir oferta ativa do ticket | `offer.setActive` |
| Recálculo automático de default | `offer.defaultRecalculated` |
| Migração legado → oferta | `migration.legacyToOffer` |

Campos mínimos do documento de log:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `uid` | String | Dono do log |
| `timestamp` | Timestamp | `serverTimestamp()` (nunca relógio do cliente) |
| `action` | String | Um dos eventos da tabela acima |
| `entityType` | String | `ingredient` ou `offer` |
| `entityId` | String | ID do insumo/oferta afetado |
| `entityName` | String? | Nome do insumo (contexto) |
| `supplier` | String? | Fornecedor da oferta, quando aplicável |
| `previousPrice` / `newPrice` | double? | Preço da embalagem antes/depois |
| `previousPackageQuantity` / `newPackageQuantity` | double? | Quantidade antes/depois |
| `pricePerUnit` | double? | Preço/unidade resultante |
| `source` | String | `manual` ou `migration` |
| `summary` | String | Resumo legível em PT-BR |
| `expireAt` | Timestamp | Retenção: **180 dias** após a criação |

Regras de acesso (a incluir em `firestore.rules`, antes do catch-all):

```
match /price_audit_logs/{logId} {
  allow read: if request.auth != null && request.auth.uid == uid;
  allow create: if request.auth != null && request.auth.uid == uid
                && campos mínimos presentes;
  allow update, delete: if false;
}
```

Política de gravação: o log é gravado **no mesmo batch** da mutação do documento
(update do insumo + add do log), garantindo que não exista mudança de preço sem log.

> `[PENDENTE IMPLEMENTAÇÃO]` — confirmar validação exata dos "campos mínimos" nas rules
> e o mecanismo de expiração (limpeza sob demanda pela leitura vs. política manual).

### 4.6 Diagrama Entidade-Relacionamento

*(padrão BIBLIOTECA: DER como "Figura 2" + parágrafo de modelagem)*

A modelagem do banco de dados do CashCtrl após o Sprint 2 mantém a hierarquia com
isolamento por usuário e acrescenta as ofertas embutidas e a coleção de auditoria:

```
users (coleção principal)
  |
  |-- {uid} (documento do usuário)
        |
        |-- transactions (subcoleção)      {txId}
        |-- budgets (subcoleção)           {budgetId}
        |-- ingredients (subcoleção)       {ingredientId}
        |     |-- offers[] (array embutido no documento)
        |-- products (subcoleção)          {productId}
        |-- price_audit_logs (subcoleção)  {logId}   [NOVO — append-only]
```

Relações:

- `products.recipe[].ingredientId` → `ingredients.id` (referência ao insumo),
- `ingredients.activeOfferId` → `offers[].id` (oferta que alimenta o ticket),
- `price_audit_logs.entityId` → insumo/oferta auditada (referência lógica, sem join),
- `transactions.budgetId` → `budgets.id` (referência opcional, pré-existente).

> `[PENDENTE IMPLEMENTAÇÃO]` — gerar a **Figura 2** (diagrama desenhado) após o sprint;
> sem imagem, usar `[Figura 2 — diagrama pendente]`.

### 4.7 Esquema do Banco de Dados (Firestore)

*(padrão BIBLIOTECA: esquema no formato `Coleção = {campos}`)*

```
users = {nome, email, empresa?, cnpj?, segmento?, telefone?, endereco?, photoUrl?}

users/{uid}/transactions/{txId} = {type, category, description, amount, date,
  paymentMethod, recurring, notes?, receiptUrl?, budgetId?}

users/{uid}/budgets/{budgetId} = {category, limit, monthly, createdAt}

users/{uid}/ingredients/{ingredientId} = {name, unit, purchasePrice, packageQuantity,
  createdAt,
  activeOfferId?, lowestPricePerUnit?, bestSupplier?, offersCount?,
  offers: [ {id, supplier, packagePrice, packageQuantity, pricePerUnitCache,
             isActive, isDefault, source, notes?, createdAt, updatedAt} ]}

users/{uid}/products/{productId} = {name, description, recipe[], laborCost,
  packagingCost, salePrice, photoUrl?, barcode?, createdAt}

users/{uid}/price_audit_logs/{logId} = {uid, timestamp, action, entityType, entityId,
  entityName?, supplier?, previousPrice?, newPrice?, previousPackageQuantity?,
  newPackageQuantity?, pricePerUnit?, source, summary, expireAt}   [NOVO]
```

> `[PENDENTE IMPLEMENTAÇÃO]` — conferir o esquema contra o código final.

---

## 5. Instalação do CashCtrl

*(padrão BIBLIOTECA: "Requisitos:" e "Passo a passo:" em Ttulo4/Ttulo5, comandos em
Courier New)*

### Requisitos:

- Flutter (Dart SDK ^3.11.5) e Android SDK (plataforma principal; web opcional),
- Projeto Firebase com Authentication (Email/Senha, Google, Facebook), Firestore e
  Storage ativados,
- Arquivo `.env` com as chaves (a partir de `.env.example`; **nunca versionado**),
- CLI Firebase (para aplicar as regras) ou Firebase Console.

### Passo a passo:

**[PENDENTE IMPLEMENTAÇÃO]** — passos numerados no padrão BIBLIOTECA
(`(1.)`, `(2.)`... em Ttulo5, comandos em Courier New), incluindo:

1. Clonar o repositório e entrar na pasta.
2. Copiar `.env.example` → `.env` e preencher as chaves Firebase.
3. **Aplicar as regras do Firestore ANTES de executar o app novo** (policy de deploy do
   Sprint 2): publicar `firestore.rules` atualizado (com `price_audit_logs`) pelo
   Console ou `firebase deploy --only firestore:rules`. As regras novas precisam estar
   ativas antes da primeira execução do app atualizado, pois o app já grava logs e o
   catch-all antigo bloquearia a coleção.
4. `flutter pub get`.
5. `flutter run` (ou `flutter run -d chrome` para web).

> `[PENDENTE IMPLEMENTAÇÃO]` — confirmar se há passo adicional de migração de dados
> (a migração é lazy, executada pelo próprio app ao abrir insumos legados; não deve
> exigir passo manual).

---

## 6. Manual do usuário

*(padrão BIBLIOTECA: seção "Manual do usuário" com subtítulos por tela e "Figura N.
Página de ... que apresenta ..." para cada captura)*

**[PENDENTE IMPLEMENTAÇÃO]** — texto definitivo após as telas existirem. Estrutura
prevista (cada item com captura de tela como Figura N; sem screenshot, usar
`[Figura N — captura de tela pendente]`):

### 6.1 Comparativo de fornecedores

- Acesso: menu lateral > Insumos > selecionar insumo > "Ofertas" (ou badge "N ofertas").
- Ranking por preço/unidade ascendente; badges "MAIS BARATO" e "OFERTA ATIVA".
- Adicionar oferta: fornecedor, preço da embalagem, quantidade; preview R$/un;
  mesmo fornecedor atualiza (upsert) em vez de duplicar; 16ª oferta é bloqueada.
- Editar uma oferta não apaga as demais; ativar/desativar e definir a oferta ativa
  (a que alimenta o ticket) são ações manuais — o app **nunca** troca a ativa
  automaticamente.

### 6.2 Ticket do produto com oferta ativa

- O ticket continua calculando com a oferta ativa de cada insumo (fallback legado
  quando não houver ofertas — custo inalterado).
- Se existir oferta mais barata que a ativa, o ticket exibe o alerta de economia:
  "Poderia economizar R$ X usando {fornecedor}".
- O veredicto de lucro/prejuízo, margem e markup permanecem os mesmos do Sprint 1.

### 6.3 Histórico de auditoria

- Acesso: menu lateral > Insumos > Auditoria (ou Configurações, conforme
  implementação).
- Lista somente leitura dos eventos (`ingredient.*`, `offer.*`,
  `migration.legacyToOffer`) com resumo em PT-BR, preço anterior/novo e data.
- Registros expiram após 180 dias.

> `[PENDENTE IMPLEMENTAÇÃO]` — descrever navegação real, textos de botões e mensagens
> exatamente como implementados; inserir Figuras 3..N (capturas).

---

## 7. Considerações Finais

*(padrão BIBLIOTECA: parágrafo de fechamento + próximos passos)*

**[PENDENTE IMPLEMENTAÇÃO]** — redigir após o sprint. Pontos a cobrir:

- Resumo do que foi entregue (comparativo de fornecedores, oferta ativa no ticket,
  auditoria, migração lazy) e a política de deploy (rules antes do app).
- Critérios de aceite verificados (do advisor): comparativo ordena por preço/unidade
  ascendente; badges "MAIS BARATO"/"OFERTA ATIVA"; `packageQuantity <= 0` ou preço
  `<= 0` rejeitado; ticket usa oferta ativa com alerta de economia; upsert por
  fornecedor; editar 1 oferta não apaga as outras; doc legado sem `offers` → 1 oferta
  sintética com custo do ticket inalterado; log append-only (update/delete negado);
  outro UID não lê logs/ofertas; ordenação estável com centavos; form bloqueia a 16ª
  oferta; `flutter analyze` limpo e sem comentários novos no Dart.
- Testes: `[PENDENTE IMPLEMENTAÇÃO]` — lista de testes da lógica pura (ranking, delta,
  cenário best, migração idempotente, teto de 15, upsert) e resultados de
  `flutter analyze`/`flutter test`.
- Próximos passos (v1.1+): migração de `offers[]` para subcoleção, histórico completo
  de preços, lista de compras por fornecedor, export CSV.

---

## Apêndice do esqueleto — mapeamento de formatação (para o .docx final)

*(não entra no relatório final; guia o pipeline Markdown → HTML → LibreOffice)*

| Elemento BIBLIOTECA | Estilo no template | Uso neste documento |
|---------------------|--------------------|---------------------|
| Título da capa | Verdana/Times 20–16pt centralizado | Capa |
| `Ttulo1` (heading 1) | Arial bold 16pt, numerado `%1.` | Seções 1–7 e "Indice" (sem número) |
| `Ttulo2` (heading 2) | Arial bold 14pt, numerado `%1.%2` | Subseções (4.1, 4.2, ...) |
| `Ttulo3` (heading 3) | Arial bold 14pt, numerado | Sub-subseções (4.3.x) |
| `Ttulo4` (heading 4) | Palatino Linotype bold 12pt, sem numeração | "Requisitos:", "Passo a passo:" |
| `Ttulo5` (heading 5) | Courier New bold, sem numeração | Comandos, passos `(1.)`, código |
| `Corpodetexto` (Body Text) | padrão do template (Times) | Parágrafos |
| `PargrafodaLista` (List Paragraph) | recuo 1430/360 | Listas `arquivo: descrição` e requisitos |
| `Sumrio1/2` (toc 1/2) | 12pt | Entradas do Índice |
| Tabelas | sem tabela no BIBLIOTECA original | Usar grade simples discreta (bordas finas) |
| Figuras | legenda "Figura N. descrição" centralizada | Figuras 1 (árvore), 2 (DER), 3..N (telas) |
| Rodapé | "N — Documentação Técnica ..." com PAGE | Todas as páginas numeradas |

Observações de conversão:

- Numeração de títulos no BIBLIOTECA é automática (multilevel); no HTML/Markdown usar
  numeração explícita nos textos dos títulos.
- O BIBLIOTECA não usa tabelas; as tabelas deste esqueleto (campos, eventos) devem ser
  renderizadas com estilo sóbrio (bordas finas, cabeçalho em negrito) para manter o tom
  do relatório.
- Comando de regeneração do `.docx` (apenas na fase final, não agora):
  `soffice --headless --convert-to docx --outdir documentacao documentacao/cashctrl_tecnica.html`
  e renomear para `documentacao/CASHCTRL_DOCUMENTACAO_TECNICA.docx`.
