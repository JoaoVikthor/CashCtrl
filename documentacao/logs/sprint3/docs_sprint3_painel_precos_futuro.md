# Capítulo — Implementação futura — Painel de Comparação de Preços

**Destino:** relatório técnico do CashCtrl **v2** (inserido como capítulo 7, antes das
Considerações Finais, que passam a 8) · **Autor:** docs-writer · **Data:** 2026-10-08 ·
**Status:** documentação de implementação futura — **nenhum código alterado** (o app
permanece intocado).

**Fontes:** `context/decisoes-de-fluxo.md` (decisão de 2026-10-08, diretriz do
professor) · `documentacao/logs/sprint3/innovacao_comparativo_automatizado.md` ·
`documentacao/logs/sprint3/critica_comparativo_automatizado.md` ·
`documentacao/logs/sprint3/redesign_comparativo_automatico.md` ·
`documentacao/logs/sprint3/prototipo_painel_precos.html` · código da Sprint 2
(`lib/models/ingredient_offer.dart`, `lib/utils/offer_comparator.dart`) ·
`docs/overview.md` · `documentacao/logs/sprint2/docs_sprint2_proposta_a.md`.

A numeração de figuras deste capítulo (Figuras 9 a 13) dá continuidade à numeração do
relatório da Sprint 2 (Figuras 1 a 8). Não há capturas de tela: o artefato existente é
o protótipo HTML interativo, citado em cada legenda; capturas podem ser extraídas dele
quando houver ambiente gráfico.

---

## 7. Implementação futura — Painel de Comparação de Preços

Este capítulo documenta o **Painel de Comparação de Preços** ("Comparar preços"), o
diferencial essencial do CashCtrl, na condição de **implementação futura**. A decisão,
registrada em `context/decisoes-de-fluxo.md` em 08/10/2026 (diretriz do professor), é
de que o painel **não entra no aplicativo Flutter neste momento**: o app atual — cuja
tela inicial funciona como mostruário do produto real — permanece intocado, e a entrega
desta sprint é um **protótipo HTML interativo** em
`documentacao/logs/sprint3/prototipo_painel_precos.html`, fiel à identidade visual
(paleta e tokens reais) e ao modelo de dados implementado. O relatório técnico passa à
versão v2 com este capítulo; o DOCX da Sprint 2 é preservado sem alteração
(versionamento seguro).

### 7.1 Motivação e diferencial

O diferencial do CashCtrl é permitir que o usuário veja os **produtos com os preços de
cada fornecedor e compare** — um "mercado" construído com os dados do próprio usuário,
sem catálogo externo, sem scraping e sem integração com terceiros. Cada preço existe
porque o microempreendedor o digitou; o painel apenas organiza essa informação para a
decisão de compra.

No Sprint 2 o comparativo já existe, porém **por insumo** (`ingredient_offers_screen`):
para decidir onde comprar a semana inteira, o usuário precisaria abrir insumo a
insumo. O painel futuro agrega todos os insumos em uma única leitura, com:

- faixa de **economia possível** consolidada (no protótipo, R$ 14,32/semana trocando 3
  produtos de fornecedor, a partir do cenário de consumo cadastrado);
- busca por produto ou fornecedor, ordenação (maior economia, menor preço, nome) e
  filtro por fornecedor;
- um card por insumo respondendo, de cima para baixo: qual é o **melhor preço por
  unidade** (dourado), o que está **no ticket hoje** (oferta ativa) e quanto se
  economiza ao trocar.

A leitura de decisão permanece a mesma do comparativo por insumo — melhor preço por
unidade, oferta ativa e delta —, agora com visão de cesta.

### 7.2 O protótipo HTML e as três visões do painel

O artefato `documentacao/logs/sprint3/prototipo_painel_precos.html` é uma demo
clicável com três visões e dois estados de poucos dados. Ele usa a paleta real do app
(fundo `#0D1E16`, card `#142A20`, verde `#165A41`, dourado `#B89775`, texto secundário
`#7A8B83`; status verde/vermelho/laranja do Material) e dados de exemplo fiéis ao
modelo real `offers[]` com preço por unidade derivado: seis fornecedores de exemplo
(SJ Atacão São Jorge, DC Distribuidora Central, BF Mercado Bom Farto, EC Empório do
Café, MC Maciel & Filhos, HB Hortifruti Boa Colheita) e um cenário semanal de exemplo
(queijo 2 kg · café 2 × 500 g · copos 80 un → R$ 14,32). A demo permite busca,
ordenação, filtros, troca da oferta ativa com confirmação e desfazer, e alternância
entre os estados Normal, Vazio e 1 fornecedor.

#### 7.2.1 Visão 1 — Painel principal "Comparar preços" (por produto)

> **Figura 9.** Protótipo: painel principal "Comparar preços" — visão por produto
> (captura pendente; artefato:
> `documentacao/logs/sprint3/prototipo_painel_precos.html`, Tela 1).

A tela abre com a AppBar "Comparar preços" e a faixa verde "Economia possível — R$
14,32 · trocando 3 produtos de fornecedor". Seguem a busca ("Buscar produto ou
fornecedor…"), a ordenação [Maior economia, Menor preço, Nome] e os chips de
fornecedor [Todos, SJ, DC, BF, EC, MC, HB] com legenda de siglas. A lista exibe **um
card por insumo** com hierarquia fixa: nome do produto e unidade ("Café torrado · por
kg · pacotes de 500 g"); **melhor preço por unidade em dourado** com fornecedor e
embalagem ("R$ 79,80/kg — Atacão São Jorge · R$ 39,90 · 500 g"); linha "No ticket:
{fornecedor} · Δ vs. a melhor" (vermelho para aumento relevante, laranja para delta
pequeno); mini-chips com os demais preços por unidade ("EC 88,00 · MC 83,00"); e chip
verde de economia ("−R$ 8,20/semana") apenas nos produtos do cenário atual. Pills
"★ melhor" e "ATIVA" marcam a melhor oferta e a que alimenta o ticket; quando a ativa
já é a melhor, o card exibe "★ também é a melhor — sem delta". A nota de rodapé do
protótipo fixa a regra: o dourado lidera cada card, a linha "No ticket" mostra a
oferta ativa e **o app não troca sozinho**.

#### 7.2.2 Visão 2 — Detalhe do produto e ranking de ofertas

> **Figura 10.** Protótipo: detalhe do produto com ranking de ofertas (captura
> pendente; artefato: `documentacao/logs/sprint3/prototipo_painel_precos.html`,
> Tela 2).

A partir de qualquer card do painel, o detalhe do produto (no protótipo, "Queijo
mussarela") apresenta um cartão-herói com o nome, "3 ofertas cadastradas · por kg", o
melhor preço agora ("R$ 37,80/kg — Distribuidora Central · R$ 37,80 · 1 kg") e as
pills "ATIVA · Atacão São Jorge" e "★ melhor · Distribuidora Central". Um banner
informativo registra a situação sem decidir por usuário: "A oferta ativa custa R$
2,10/kg a mais que a melhor. Trocar é opcional — você confirma." Abaixo, o **ranking
vertical numerado** por preço por unidade mostra, em cada linha, fornecedor,
embalagem ("R$ 39,90 · 1 kg"), R$/un em dourado, delta vs. a ativa ("−R$ 2,10/kg vs.
a ativa" / "— oferta ativa no ticket" / "+R$ 2,60/kg vs. a ativa") e as ações "Usar
no ticket" (na melhor) e "Editar oferta". O rodapé reforça o frescor e a política:
"Preços coletados em 02/10 · confirme antes de comprar." e "Usar no ticket pede
confirmação e troca só quando você manda. O app não altera automaticamente." Esta
visão corresponde à `ingredient_offers_screen` da Proposta A, reenquadrada pelo
painel.

#### 7.2.3 Visão 3 — Visão por fornecedor

> **Figura 11.** Protótipo: visão por fornecedor com cesta consolidada (captura
> pendente; artefato: `documentacao/logs/sprint3/prototipo_painel_precos.html`,
> Tela 3).

Leitura alternativa do mesmo dado, orientada à pergunta "comprei bem deste
fornecedor?". Chips de fornecedor no topo trocam o foco; o cabeçalho resume a
participação ("Atacão São Jorge — Fornece 7 de 8 insumos · ★ melhor em 2 · 3º preço
em 3", com pills "★ presunto", "★ café torrado" e "não fornece tomate"). A lista
"Produtos que ele fornece" mostra, por insumo, a posição no ranking ("★ melhor preço
· 1º de 2", "2º melhor preço · de 3", "3º de 3") e o delta vs. a média dos preços
cadastrados (verde/laranja/vermelho). O rodapé consolida a cesta com honestidade:
"Se a cesta inteira fosse deste fornecedor — Cesta SJ (7 insumos): R$ 379,17/semana;
Cesta mais barata (★ de cada insumo): R$ 352,67/semana; Diferença: +R$ 26,50 a mais"
— e conclui com a leitura útil: "SJ é ★melhor em presunto e café — vale comprar só
esses dele." O painel não recomenda exclusividade: mostra onde cada fornecedor ganha
e onde perde.

#### 7.2.4 Estados de poucos dados: vazio e fornecedor único

> **Figura 12.** Protótipo: estado vazio do painel (captura pendente; artefato:
> `documentacao/logs/sprint3/prototipo_painel_precos.html`, seção de estados).

> **Figura 13.** Protótipo: estado com um único fornecedor (captura pendente;
> artefato: `documentacao/logs/sprint3/prototipo_painel_precos.html`, seção de
> estados).

Sem ofertas, o painel exibe o estado vazio com ícone de loja, título "Nenhuma oferta
cadastrada ainda", mensagem "Cadastre preços de fornecedores para comparar e escolher
quem entra no ticket." e CTA verde "Adicionar primeira oferta" — enquanto isso o
ticket continua usando o preço base cadastrado no insumo, sem quebra de fluxo. Com
um único fornecedor, o painel mostra os preços **sem ranking, delta ou economia**
(não há "melhor" nem "pior" sem concorrência): banner laranja "Cadastre mais
fornecedores para ver o comparativo.", card único "Distribuidora Central — único
fornecedor com ofertas · 8 insumos" com pill "sem comparação" e CTA outline
"Cadastrar outro fornecedor". Nenhum ranking é inventado.

### 7.3 Viabilidade de dados — derivação do schema da Sprint 2

Todo o painel é derivável, no cliente, do schema já implementado no Sprint 2 — **sem
mudança de schema, sem coleção nova e sem alteração de regras**:

| Dado exibido no painel | Origem no schema atual |
|------------------------|------------------------|
| Lista de produtos com ofertas | `users/{uid}/ingredients/{ingredientId}` — array `offers[]` (teto 15) |
| Preço por unidade (R$/un) | getter derivado `pricePerUnit = packagePrice / packageQuantity` (`IngredientOffer`) — nunca armazenado |
| Melhor oferta / ranking / delta | `OfferComparator.rank`/`rankAll`/`bestOffer`/`deltaVsActive` (`lib/utils/offer_comparator.dart`) |
| Oferta que alimenta o ticket | `activeOfferId` + flag exclusiva `isActive` (escolha manual) |
| Economia por produto / cesta | `OfferComparator.bestSupplierScenario` (já usado pelo `EconomySummaryCard`) |
| Auditoria das trocas | `users/{uid}/price_audit_logs/{logId}` (append-only, 180 dias) |

Consequências práticas: a agregação é client-side sobre os streams existentes
(`IngredientProvider.asMap`); a rota sugerida é `/comparar-precos`, com entrada nova
no menu lateral; os widgets da Proposta A são reutilizados (`BestPriceChip`,
`ActiveOfferMarker`, `DeltaPriceText`); e o delta segue a semântica do protótipo
(vermelho ≥ R$ 1,00; laranja < R$ 1,00; "—" quando a ativa é a melhor), exibindo
sempre R$/un — nunca apenas o preço da embalagem. Nenhum dado novo precisa ser
coletado para a versão informativa do painel.

### 7.4 Política preservada — o preço do ticket permanece escolha manual

A política aprovada no gate do Sprint 2 e reafirmada em 08/10/2026 é **intocada**: o
preço que alimenta o ticket é a oferta ativa (`activeOfferId`), escolhida
manualmente pelo usuário; **o app nunca troca sozinho**. O painel é um instrumento
informativo: informa o melhor preço por unidade, mostra o delta da oferta ativa e,
quando houver cenário de consumo, estima a economia — mas qualquer troca passa pelo
fluxo existente ("Usar no ticket" → `ConfirmActionDialog` → `setActiveOffer` → log
`offer.setActive`), com desfazer. A microcopy do protótipo fixa o contrato: "Trocar é
opcional — você confirma.", "O app não altera automaticamente." e "o app não troca
sozinho". Nenhum nível de automação altera o veredito do ticket sem ação explícita do
usuário.

### 7.5 Evolução prevista em backlog — escada de automação L0–L4

A automação sobre preços segue em **backlog**, condicionada ao gate de política ("o
app nunca troca sozinho"), conforme a escada desenhada na Sprint 3
(`innovacao_comparativo_automatizado.md`) e criticada pelo advisor
(`critica_comparativo_automatizado.md`):

| Nível | Nome | Mecânica | Quem toca o ticket | Status |
|-------|------|----------|--------------------|--------|
| **L0** | Manual (atual) | Usuário cria/edita/ativa ofertas | Só o usuário | entregue (Sprint 2) |
| **L1** | Preço fresco (sinal passivo) | Campos `priceCapturedAt`/`validityDays`; chips "expirando em N dias"/"preço vencido"; badge ★melhor só entre ofertas frescas | Ninguém (só sinaliza) | backlog |
| **L2** | Sugestão one-tap | Banner "Trocar para {X}: economia R$ Y/un (Z%)"; 1 toque → fluxo atual de `setActiveOffer` com `ConfirmActionDialog` | Usuário confirma | backlog — **MVP seguro recomendado pela crítica** |
| **L3** | Auto-troca com política opt-in por insumo | `automation.mode='auto'` só liga após toggle explícito; troca se: candidata fresca ∧ Δ ≥ `minDeltaPct` ∧ cooldown vencido ∧ sem edição manual recente; transação com guarda otimista; log `offer.autoSwitched`; undo de 1 toque | App, com consentimento prévio | backlog — v2, condicionado às ressalvas (§7.6) |
| **L4** | Auto pleno global, server-side | Política default auto para todo o parque; Functions/Scheduler/FCM | App | **FORA** até haver fonte externa de preço |

Dois condicionantes estruturais registados na Sprint 3:

- **L4/server-side fica fora** até existir fonte externa de preço: o preço de uma
  oferta só muda quando o próprio usuário digita o preço novo, logo o servidor não
  tem informação que o app não tenha; e recursos server-side (Cloud Functions
  agendada, push disparado por Scheduler, TTL nativo para limpar
  `price_audit_logs`, OCR server-side) exigem o plano **Blaze** — decisão de custo
  sinalizada, não assumida.
- **Pré-requisitos técnicos** identificados para qualquer automação: correção do
  fallback silencioso em `setActiveOffer` (`orElse: () => offers.first`), frescor
  real do preço (`updatedAt` como proxy no MVP; `priceCapturedAt`/`validityDays`
  depois), deploy das rules vigentes antes do app e lógica de elegibilidade 100%
  pura (em `offer_comparator.dart` ou util novo) com testes.

O MVP recomendado pela crítica é **L1+L2** (frescor + sugestão one-tap), que entrega
a maior parte do valor percebido — "o app trabalha por mim, eu decido" — sem tocar na
política; L3 (auto opt-in com guardrails) é v2, e L4 está cortado.

### 7.6 Ressalvas vinculantes resumidas

Condições para aprovar **qualquer** auto-troca (hoje ou na v2), resumidas das dez
ressalvas vinculantes da crítica; as dez originais permanecem em vigor no documento
de origem:

1. **Opt-in explícito, default OFF, em tela própria** — nunca bundling em outro
   fluxo; a política é por insumo.
2. **Elegibilidade com frescor:** oferta-alvo ativa com frescor ≤ 30 dias; oferta
   `source: migration` só elegível após reconfirmação; oferta desatualizada nunca é
   elegível a sugestão.
3. **Δ mínimo e ritmo:** economia por linha ≥ max(R$ 0,05; 1% do custo da linha);
   cooldown de 7 dias por insumo e cap de 10 trocas/mês, persistidos em documento
   com rules próprias deployadas antes do app.
4. **Auditoria e reversão:** log append-only com `source: automation` (action
   `offer.autoSwitch`) e badge "AUTO" na UI de auditoria; undo em 1 toque, disponível
   no mínimo durante a sessão; oferta ativa expirada **nunca** é rebaixada
   automaticamente (só alerta — degradar avisando, não decidindo).
5. **Execução e código:** automação somente em foreground com stream fresco (nunca em
   background/sync); lógica de elegibilidade 100% pura e testada (zero decisão dentro
   de widget/service); qualquer mudança de política atualiza a microcopy nos pontos
   documentados do plano de design, o `overview.md` e o HANDOVER **no mesmo commit**.

### 7.7 Critérios de aceite quando for implementado

Quando o painel entrar no app (rota sugerida `/comparar-precos`), a implementação só
estará completa se:

- o painel agregar, client-side, os insumos e ofertas existentes — **sem mudança de
  schema** e sem novas permissões (rules inalteradas);
- o painel seja somente leitura em relação ao ticket: nenhuma troca de oferta sem
  toque do usuário; recusar uma sugestão deixa o ticket idêntico antes e depois
  (testável);
- "Usar no ticket" reutilize `setActiveOffer` + `ConfirmActionDialog` e gere log
  `offer.setActive`; o desfazer restaure a oferta anterior e gere **log novo**
  (nenhum update/delete em `price_audit_logs`);
- os estados vazio e "1 fornecedor" não exibam ranking, delta ou economia inventados;
  a economia só apareça quando a quantidade do cenário for conhecida — nunca inventar
  número;
- o ranking seja sempre por preço por unidade (nunca só pelo preço da embalagem), com
  a semântica de delta do protótipo (verde/vermelho/laranja/"—") e os marcadores
  "ATIVA" e "★ melhor" reutilizados;
- a microcopy "o app não troca sozinho" permaneça em todos os pontos documentados;
- o protótipo HTML tenha sido aprovado antes do código (regra de fluxo de 07/10);
- `dart analyze .` limpo, `flutter test` verde, zero dependências novas e paleta/logo
  intocados.

---

*Capítulo gerado a partir das fontes listadas no cabeçalho; nenhuma alteração em
`lib/`, `firestore.rules`, `storage.rules`, `.env` ou `android/`. O protótipo
`documentacao/logs/sprint3/prototipo_painel_precos.html` é o artefato de referência
das Figuras 9 a 13.*
