# CashCtrl — Respostas aos Pendentes da v0.2 (Versão Definitiva 1.0.0+1)

**Escopo:** documento de respostas técnicas consolidadas aos 42 marcadores
pendentes do relatório v0.2, verificados contra a versão definitiva do CashCtrl
(commit único `master`, 28/10/2026, `version: 1.0.0+1`, APK release 59 MB;
módulos de foto removidos).

**Pipeline:** este Markdown → `ctrlcash_respostas_v02.html` (estilos do
template `documentacao/BIBLIOTECA_113_RT_279.docx`) →
`soffice --headless --convert-to "docx:MS Word 2007 XML"` →
`documentacao/CTRLCASH_RESPOSTAS_V02.docx` (+ pós-processamento do rodapé com
PAGE, conforme `documentacao/GUIA_FORMATACAO_DOCX.md`).

**Sinalização textual:** `[Verificado no código]` substitui ✅;
`[DECISÃO DA EQUIPE]` substitui 🔧; `[A CONFIRMAR PELA EQUIPE]` substitui ❓.
`[Verificado no código + figura]` marca os itens 6 e 7, cujos diagramas
(Figuras 1 e 2) foram elaborados a partir do código e estão embutidos neste
documento. Itens marcados com DECISÃO/A CONFIRMAR permanecem explicitamente em
aberto — nenhuma resposta foi inventada para eles.

---

## 1. Introdução

Este documento consolida as respostas aos 42 marcadores pendentes levantados
pelo revisor na v0.2 do relatório técnico do CashCtrl. Todas as respostas foram
verificadas contra a versão definitiva do aplicativo: commit único na branch
`master`, de 28/10/2026, versão `1.0.0+1` (`pubspec.yaml`), APK de release com
59 MB. Os módulos de foto (`image_picker` + Firebase Storage) foram removidos
dessa versão e nenhuma resposta os considera.

A sinalização é textual: itens marcados com **[Verificado no código]** foram
conferidos diretamente na base definitiva; itens marcados com
**[DECISÃO DA EQUIPE]** exigem deliberação do time (com sugestão registrada no
corpo da resposta, quando existe); itens marcados com
**[A CONFIRMAR PELA EQUIPE]** dependem de dado que só a equipe possui e
permanecem explicitamente em aberto. Os itens 6 e 7 foram conferidos no código
e vêm acompanhados das **Figuras 1 e 2**, elaboradas a partir da base
definitiva (sinalização **[Verificado no código + figura]**). O consolidado do
que falta está na seção 8.

---

## 2. Decisões da equipe (itens 1–5)

### 2.1 Item 1 — Situação real dos módulos citados (RF13–RF17)

**[Verificado no código]**

Tabela 1. Situação real dos conceitos citados pelo revisor na versão definitiva.

| Conceito | Status na versão definitiva | Onde |
|---|---|---|
| Rendimento | **NÃO implementado** — não existe no código | — |
| Custos fixos × variáveis (classificação) | **NÃO implementado** como classificação; existem custos diretos por ficha | — |
| Mão de obra | **Implementado** — campo `laborCost` entra no custo total | `product.dart`, `product_calculator.dart:94` |
| Markup | **Implementado** — `markup = venda ÷ custo total`, exibido no detalhe ("Markup X.XXx") | `product_calculator.dart:34`, `product_detail_screen.dart:221` |
| Contribuição / margem | **Implementado** — `lucro = venda − custo`, `margem% = lucro ÷ venda`, veredito Dá lucro/Prejuízo | `product_calculator.dart:95-98` |
| Ponto de equilíbrio | **NÃO implementado** | — |

**DECISÃO DA EQUIPE:** o que não existe (rendimento, ponto de equilíbrio,
classificação fixo/variável) deve constar na documentação como **evolução
futura**, não como entrega. Implementar agora atrasaria a entrega.

### 2.2 Item 2 — Controle financeiro (RF01, RF05–RF10)

**[Verificado no código]**

Já está **implementado e dentro da entrega**: transações (receita/despesa,
categorias de negócio, método de pagamento, recorrência), orçamentos mensais
com progresso em tempo real, dashboard operacional, relatórios unificados com
gráficos (fl_chart) e exportação Excel (3 abas). Telas: `expenses_screen.dart`,
`budgets_screen.dart`, `reports_screen.dart`, `home_screen.dart`.
**DECISÃO DA EQUIPE:** restante — apenas manter no escopo (recomendado — já
funciona).

### 2.3 Item 3 — Mão de obra e custos diretos no custo do lote

**[Verificado no código]**

**Sim, entram.** Fórmula no código:
`custoTotal = Σ(qtd × preço/un do insumo) + mão de obra + embalagem`
(`product_calculator.dart:93-94`). A participação percentual de cada item no
custo é exibida no ticket (`product_detail_screen.dart`).

### 2.4 Item 4 — Markup e mix de vendas

**[Verificado no código]**

- **Markup atual é informativo (saída), não base de cálculo (entrada):** o app
  calcula e mostra o markup do preço que o usuário definiu; não sugere preço a
  partir de um markup-alvo.
- **Mix de vendas:** cada ficha técnica tem preço de venda próprio. Não existe
  markup único aplicado a vários produtos. Os relatórios têm "Top 5 categorias"
  e receita × custos dos últimos 6 meses.
- **DECISÃO DA EQUIPE:** documentar o markup como indicador calculado
  (venda ÷ custo) e tratar "precificação por markup-alvo com mix" como evolução
  futura.

### 2.5 Item 5 — Perfis (proprietário × produção/precificação)

**[Verificado no código]**

**Não existem.** O app é monousuário: cada conta acessa somente seus próprios
dados (isolamento por UID no Firestore). Para duas pessoas no mesmo negócio,
hoje compartilhariam a mesma conta. **DECISÃO DA EQUIPE:** registrar como
evolução futura (perfis/roles).

---

## 3. Conteúdo técnico (itens 6–14)

### 3.1 Item 6 — Diagrama de casos de uso

**[Verificado no código + figura]**

Atores: **Proprietário do negócio** (único). Os casos de uso identificados nas
telas foram consolidados em 9 casos no diagrama da Figura 1:

- Efetuar login/cadastro;
- Gerenciar transações;
- Gerenciar orçamentos;
- Ver dashboard e relatórios;
- Exportar Excel;
- Cadastrar produtos e ofertas;
- Comparar preços/oferta ativa/auditoria de preços;
- Criar ficha técnica e ver ticket;
- Configurar conta e notificações.

Figura 1 – Diagrama de casos de uso do CashCtrl (fonte: código da versão
definitiva v1.0.0+1).

![Figura 1 — diagrama de casos de uso UML do CashCtrl](fig1_casos_de_uso.png)

(Arquivo: `documentacao/logs/respostas_v02/fig1_casos_de_uso.png`, 1001×1011 px
— ator "Proprietário do negócio" ligado aos 9 casos de uso dentro da fronteira
do sistema CashCtrl.)

### 3.2 Item 7 — Modelo de dados: escolha do banco

**[Verificado no código + figura]**

**Cloud Firestore** (não Realtime Database). Justificativa: documentos NoSQL,
streams em tempo real nativos ao Flutter (`StreamProvider`), regras de
segurança por subcoleção e isolamento por UID. Estrutura:

```
users/{uid}                     perfil + dados do negócio
users/{uid}/transactions/{id}   tipo, categoria, valor, data,
                                método, recorrência
users/{uid}/budgets/{id}        categoria + limite mensal
users/{uid}/ingredients/{id}    produto comprado: nome, unidade,
                                preço de compra, qtd da embalagem,
                                offers[] (≤15), activeOfferId
users/{uid}/products/{id}       ficha técnica: receita[], laborCost,
                                packagingCost, salePrice
users/{uid}/price_audit_logs/{id}
                                auditoria de preços (append-only)
```

Figura 2 – Modelo de dados no Firestore, com isolamento por UID.

![Figura 2 — modelo de dados no Firestore do CashCtrl](fig2_modelo_dados.png)

(Arquivo: `documentacao/logs/respostas_v02/fig2_modelo_dados.png`, 1001×761 px —
raiz `users/{uid}` com as subcoleções `transactions`, `budgets`, `products`,
`price_audit_logs` (append-only) e `ingredients` com `offers[]` (até 15)
embutidas e relação `recipe[].ingredientId`.)

### 3.3 Item 8 — Estrutura de pastas da versão definitiva

**[Verificado no código]**

```
lib/
  main.dart, firebase_options.dart, home_screen.dart,
  budgets_screen.dart, expenses_screen.dart, reports_screen.dart,
  settings_screen.dart
  models/     app_user, transaction, budget, ingredient,
              ingredient_offer, price_audit_log, product
  providers/  user, transaction, budget, ingredient, product
  services/   auth_service.dart, firestore_service.dart,
              notification_service.dart
              (storage_service.dart REMOVIDO — sem upload de fotos)
  screens/    login, cadastro, transaction_form, budget_form,
              ingredients (Produtos), ingredient_form, ingredient_offers,
              offer_form, audit_logs, products (Fichas Técnicas),
              product_form, product_detail, compare_prices,
              settings/ (edit_profile, notifications, security,
              help, terms_privacy)
  theme/  utils/  widgets/
android/  web/  firestore.rules  storage.rules
```

### 3.4 Item 9 — Regras de segurança do banco (`firestore.rules`)

**[Verificado no código]**

- Isolamento total por UID: `allow read, write: if request.auth.uid == uid` em
  `users/{uid}/...`; não há coleções globais.
- Transações: `create/update` exige `amount` numérico > 0.
- Produtos (ingredients): exige `purchasePrice ≥ 0`.
- Logs de auditoria: **append-only** — `allow read, create`;
  `update, delete: if false`.

### 3.5 Item 10 — Ferramentas de design e UML

**[DECISÃO DA EQUIPE]**

O design foi definido **em código** (design system próprio:
`theme/app_colors.dart` — fundo `0xFF0D1E16`, verde `0xFF165A41`, dourado
`0xFFB89775`) e validado com **protótipos HTML** (em
`documentacao/logs/sprint2–4/prototipo_*.html`). Não houve uso de Figma. Para o
relatório: desenhar diagramas em draw.io/PlantUML. **DECISÃO DA EQUIPE:**
confirmar qual ferramenta declarar.

### 3.6 Item 11 — Controle de versão e nome do repositório

**[Verificado no código]**

Git + GitHub, repositório `https://github.com/JoaoVikthor/ctrlcash`.
Nomenclatura real: **CashCtrl** = nome do app (marca, logo camaleão);
**ctrlcash** = nome do repositório e do pacote Flutter (`pubspec: name:
ctrlcash`). Sugestão para o texto: "CashCtrl (repositório: ctrlcash)". A
branch única passa a ser `master` com histórico refeito (um commit).

### 3.7 Item 12 — Plataforma, requisitos, web e instalação

**[Verificado no código]**

- **Android** (plataforma principal; `minSdk` = padrão do Flutter) e **Web**
  (`flutter build web`). iOS adiado.
- Requisitos: Android com Firebase Auth disponível, ~50 MB de armazenamento,
  tela sensível ao toque; app funciona em smartphone intermediário.
- Instalação: APK `app-release.apk` (transferir ao aparelho e instalar com
  "fontes desconhecidas"), ou rodar a versão web no navegador.
- Backend: projeto Firebase `crtlcash-71ac3` (Auth, Firestore).

### 3.8 Item 13 — Versão demonstrada

**[Verificado no código]**

**v1.0.0+1** (`pubspec.yaml`), build definitiva de 28/10/2026 **sem módulos de
foto** (decisão da última sprint: a funcionalidade de fotos não salvava
corretamente no Firebase Storage e foi removida — perfil exibe apenas
iniciais).

### 3.9 Item 14 — Nível real de cada módulo

**[Verificado no código]**

Tabela 2. Nível real de cada módulo na versão definitiva (pós-demonstração).

| Módulo | Nível |
|---|---|
| Autenticação (e-mail/senha + redefinir senha) | Completo |
| Cadastro (pessoal + negócio, multi-etapa) | Completo (sem foto) |
| Transações / receitas e despesas | Completo |
| Orçamentos | Completo |
| Dashboard | Completo |
| Relatórios + Excel | Completo |
| Produtos (parque) + ofertas + comparativo + auditoria | Completo |
| Fichas técnicas + ticket (mão de obra, embalagem, markup, margem) | Completo |
| Notificações locais | Completo (orçamento, recorrência, margem) |
| Perfil/segurança/ajuda/termos | Completo (sem upload de foto) |
| Rendimento, ponto de equilíbrio, perfis de usuário | Não implementado (evolução futura) |

---

## 4. Evidências e validação (itens 15–19)

### 4.1 Item 15 — Comportamento esperado nos cinco testes

**[Verificado no código]**

Tabela 3. Comportamento da versão definitiva nos cinco testes.

| Teste | O que a versão definitiva faz |
|---|---|
| Caso didático | Fluxo completo: produto (preço/un calculado) → ficha → ticket com veredito |
| Rendimento zero | **N/A** — rendimento não existe na versão definitiva (a divisão de embalagem usa `packageQuantity > 0`; se 0, preço/un = 0, sem crash: `ingredient.dart:76-78`) |
| Insumo ausente | Linha marcada como ausente, custo 0 e aviso `hasMissingIngredients` (`product_calculator.dart:70-78`) |
| Contribuição não positiva | Veredito "Prejuízo" em vermelho, margem negativa (`products_screen.dart:214-230`) |
| Acesso entre contas | Bloqueado pelas regras: só o dono do UID lê `users/{uid}/...` |

**A CONFIRMAR PELA EQUIPE:** os resultados **executados** (data, quem testou,
prints) a equipe registra.

### 4.2 Itens 16–19 — Pesquisa, Canvas/UML/PDCA/pitch, atribuições e considerações finais

**[A CONFIRMAR PELA EQUIPE]**

Somente a equipe fornece. Sugestão de quem faz adequações de código: registrar
Vikthor (GitHub `JoaoVikthor`) como responsável pelo código do app.

---

## 5. Manual do usuário (itens 20–25)

### 5.1 Item 20 — Status geral dos prints da v0.2

**Todos os prints da v0.2 são de versão ANTIGA do app e precisam ser
recapturados na APK definitiva** (tela "Produtos" agora lista produtos de
compra com badge "N ofertas", preço "R$ x / embalagem", preço por unidade em
dourado e botão "Comparar preços"; as fichas técnicas mudaram de nome no menu
para "Fichas Técnicas"; não há mais fotos nem leitor de código de barras).

### 5.2 Item 21 — Login e cadastro (versão definitiva)

**[Verificado no código]**

- **Login:** apenas **e-mail e senha** + "Esqueci minha senha". (Login social
  Google/Facebook **não existe** na versão atual — não colocar prints sociais.)
- **Cadastro:** multi-etapa — dados pessoais (nome, e-mail, telefone) → dados
  do negócio (empresa, segmento, endereço, CNPJ opcional) → senha. Sem foto.

### 5.3 Item 22 — Formulários (conferir ao capturar)

**[Verificado no código]**

- **Produto (tela Produtos → "+"):** nome, unidade (kg/g/L/un…), preço de
  compra, quantidade da embalagem → app calcula preço por unidade; ofertas de
  fornecedores inline (até 15: fornecedor, produto, preço, quantidade).
- **Ficha técnica (tela Fichas Técnicas → "+"):** nome, descrição, itens da
  receita (produto + quantidade, com participação % no custo), mão de obra
  (R$), embalagem (R$), preço de venda → resumo ao vivo com lucro/prejuízo e
  margem.

### 5.4 Item 23 — Telas de configurações

**[Verificado no código]**

Editar Perfil (nome, empresa, CNPJ, segmento, telefone, endereço; avatar com
**iniciais**, sem upload), Notificações (3 chaves: orçamento, recorrências,
margem), Segurança e Privacidade (redefinir senha, sessão), Ajuda e Suporte
(FAQ) e Termos.

### 5.5 Item 24 — Ícone ao lado do "+" coberto pelo botão azul

**[Verificado no código]**

Era o **leitor de código de barras** (ícone dourado de QR,
`Icons.qr_code_scanner`, no topo da tela Produtos da versão antiga, encoberto
pelo FAB). **O módulo foi removido** da versão definitiva — o manual novo não
deve citá-lo. (No card de cada produto existe hoje um ícone dourado de
**loja** = "Ver ofertas".)

### 5.6 Item 25 — Seção "rendimento e simulação"

**Remover/reescrever:** rendimento não existe. O que existe: **simulação de
preço por unidade** (preço da embalagem ÷ quantidade) e **simulação de troca
de fornecedor** (tela Comparar preços / ofertas, com ranking, melhor preço e
cartão de economia possível; mudança de oferta ativa gera log de auditoria).
Descrever isso no lugar.

---

## 6. Conferências (itens 26–29)

### 6.1 Item 26 — Nome do orientador

**[A CONFIRMAR PELA EQUIPE]** Confirmar com a equipe: "Luiz Davi **Araújo**"
ou "AraÚjos"? (Grafia final deve bater com o cadastro da instituição.)

### 6.2 Item 27 — Nome do evento

**[A CONFIRMAR PELA EQUIPE]** Inova SENAI ou INTEGRA SENAI? Só a coordenação
confirma; usar o nome oficial da edição.

### 6.3 Item 28 — Custo R$ 1.532,00 × insumo R$ 1.500,00

**[Verificado no código]**

Não é erro: o valor exibido como custo da ficha técnica é
`custoTotal = insumos + mão de obra + embalagem`. A diferença de R$ 32,00
corresponde a mão de obra/embalagem digitados naquela ficha de teste. (Custo do
produto/insumo isolado é outro número: preço da embalagem.)

### 6.4 Item 29 — Dados de teste dos prints

**[Verificado no código]**

Concordo com a crítica: recapturar tudo com dados reais da Casa do Salgado
(ex.: empada de frango, salgado assado, insumos com preços por kg realistas).
O "Olá, !" sem nome ocorre quando o campo nome do perfil está vazio — resolver
cadastrando nome completo antes do print. Batata a "R$ 11,00/g" é erro de
digitação de teste (preço da embalagem lançado como preço por grama) — no
print novo, usar embalagens coerentes (ex.: batata 10 kg por R$ 150,00 →
R$ 15,00/kg). "Venda de celular" deve sair do histórico de transações dos
prints.

---

## 7. Acabamento (itens 30–32)

- **Item 30** — **[Verificado no código]** Aplicável: remover na v0.3 o
  parágrafo sobre marcadores, o aviso de resultados e o "Versão 0.2" da capa
  (trocar por versão final e data da entrega).
- **Item 31** — Sumário automático e legendas ("Figura N – ...") a inserir na
  geração do .docx final.
- **Item 32** — **[A CONFIRMAR PELA EQUIPE]** E-mails na capa — decidir com a
  equipe.

---

## 8. Resumo do que falta (só a equipe)

1. Grafia do orientador (Araújo/Araújos) — item 26;
2. Nome oficial do evento — item 27;
3. Confirmar decisões A1–A5 (sugestões dadas acima são todas "manter como
   evolução futura");
4. Conteúdo de Canvas/PDCA/pitch, feedback da Casa do Salgado, atribuições e
   considerações finais — itens 16–19;
5. Capturar os prints novos na APK definitiva (itens 20–25);
6. E-mails na capa — item 32.

Com isso, gerar a **v0.3 final** sem marcadores.

---

## 9. Considerações finais

Este documento responde aos 32 blocos de marcadores da v0.2 (42 marcadores no
total), organizados nas seções A–F do revisor: decisões da equipe (1–5),
conteúdo técnico (6–14), evidências e validação (15–19), manual do usuário
(20–25), conferências (26–29) e acabamento (30–32). As respostas verificadas no
código refletem a versão definitiva v1.0.0+1 de 28/10/2026, sem módulos de
foto.

Permanecem explicitamente em aberto — sem resposta inventada — somente os itens
sinalizados com **[DECISÃO DA EQUIPE]** (item 10, além das decisões registradas
nos itens 1, 2, 4, 5 e 15) e com **[A CONFIRMAR PELA EQUIPE]** (itens 15, 16–19,
26, 27 e 32), consolidados na seção 8. As Figuras 1 (diagrama de casos de uso)
e 2 (modelo de dados no Firestore) foram elaboradas a partir do código e estão
embutidas neste documento. Com esses encaminhamentos, o próximo passo é gerar a
**v0.3 final** do relatório, sem marcadores.
