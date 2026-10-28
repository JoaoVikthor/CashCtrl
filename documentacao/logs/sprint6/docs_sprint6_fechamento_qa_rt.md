# Documentação Técnica de Fechamento e QA do CashCtrl — Sprint 6

**Relatório técnico no padrão BIBLIOTECA (RT 279, ICMC).**
Fonte de verdade: código real da branch `nova-versao-app`, verificado em 27/10/2026.

---

## Capa

Documentação Técnica de Fechamento e QA do CashCtrl — Sprint 6

Sprint final de fechamento: correção de bugs críticos de navegação, perfil e
salvamento, auditoria completa de persistência, compatibilidade web e QA
final em preparação às builds

Equipe CashCtrl

autoria: github.com/JoaoVikthor

RELATÓRIOS TÉCNICOS DO CASHCTRL

São Carlos

27/10/2026

---

## Indice

1. Introdução
2. Resumo Executivo
3. Sprint 1 — Correções Críticas
    3.1 Botão voltar morto na tela de auditoria
    3.2 Navegação reduzida: drawer de 9 para 7 itens
    3.3 Camaleão dourado no Dashboard
    3.4 Perfil: salvamento fiel e estado de erro com "Tentar novamente"
    3.5 `StorageService`: falha explícita com causa
4. Sprint 2 — Integridade de Salvamento
    4.1 Bug de deduplicação por nome do fornecedor (`applyOfferUpsert`)
    4.2 Preferências de notificação com rollback
    4.3 Cadastro: erro final com detalhe da causa
    4.4 Polish: toasts antes do pop nos formulários
5. Sprint 3 — Auditoria de Persistência e Compatibilidade Web
    5.1 Auditoria completa de escrita (models × regras)
    5.2 Bug ALTO: edição de transação recorrente perdia campos
    5.3 Compatibilidade web (`kIsWeb`)
    5.4 Riscos registrados
6. Resultados de QA Automatizado
7. Resultados de Build (Web/APK)
8. Checklist de Teste Manual por Tela
9. Como Rodar e Testar
10. Apêndice iOS (não construído nesta fase)
11. Estado Final e Considerações
Referências

---

## 1. Introdução

Este relatório documenta a **Sprint 6 do CashCtrl**, aplicativo móvel
desenvolvido em Flutter com backend Firebase, dedicada ao **fechamento** do
projeto: correção dos defeitos críticos remanescentes de navegação, perfil e
salvamento de dados, auditoria completa das rotas de escrita do Firestore
(`toMap`/`fromMap` × regras de segurança), adequação do código à execução na
web e o ciclo final de QA automatizado em preparação às builds de
distribuição.

Todo o conteúdo reflete o código efetivamente entregue na data de
27/10/2026: nomes de arquivos, classes, assinaturas, mensagens de erro e
microcopy foram extraídos diretamente do repositório, e cada correção
afirmada neste relatório foi **reverificada no código** antes de ser
documentada. O relatório segue o padrão dos anteriores da biblioteca
(Sprint 2 — Proposta A, Sprint 3 — RT v2 e Sprint 4 — Módulo Comparativo),
continuando a numeração de tabelas e figuras a partir do fim do RT anterior,
com Figuras 21–23 específicas das telas finais.

## 2. Resumo Executivo

A sprint de fechamento dividiu-se em **três etapas internas** (nomeadas
Sprint 1, 2 e 3 desta fase), nas quais foram corrigidos **quatro bugs de
severidade alta ou crítica**:

1. **Botão voltar morto** na tela de auditoria de preços (`/audit-logs`) —
   o usuário podia ficar preso na tela sem saída conhecida;
2. **Duplicação de oferta** em `upsertOffer` quando o fornecedor era
   renomeado (deduplicação incorreta pelo nome);
3. **Perda de campos** (`generatedFrom`, `skippedOccurrences`, `receiptUrl`,
   `budgetId`) ao editar uma transação recorrente;
4. **Salvamento do perfil** não refletia campos apagados e a falha de
   carregamento não oferecia recuperação.

Ao final da fase, o aplicativo está **livre de `dart:io`** (executa na web),
com upload de arquivos unificado via `StorageService.uploadBytes`
(`putData`), suíte de testes em **128/128** (12 arquivos de teste),
`dart analyze` com apenas **1 info pré-existente** (deprecação da API
`updateEmail` do Firebase Auth), e QA manual documentado tela a tela
(seção 8). A identidade visual do app — paleta escura verde/dourada e logo
camaleão — foi **preservada integralmente**, com o acréscimo controlado do
camaleão dourado apenas no Dashboard.

A Tabela 1 resume os defeitos corrigidos.

Tabela 1. Defeitos corrigidos na Sprint 6.

| # | Severidade | Síntoma | Correção |
|---|-----------|---------|----------|
| 1 | Crítica | Botão voltar da `/audit-logs` não fazia nada | Fallback `pushNamedAndRemoveUntil('/dashboard')` em `AppBrandedHeader` |
| 2 | ALTA | Renomear o fornecedor duplicava a oferta | `applyOfferUpsert` (match por `id` prioritário) |
| 3 | ALTA | Edição de recorrente perdia 4 campos | `_save` repassa os campos de `widget.editing` |
| 4 | ALTA | Perfil não refletia campos apagados; erro sem recuperação | `AppUser` montado dos controllers + `ErrorState` com "Tentar novamente" |

## 3. Sprint 1 — Correções Críticas

### 3.1 Botão voltar morto na tela de auditoria

**Sintoma:** na tela de Auditoria (`/audit-logs`, `audit_logs_screen.dart`,
AppBar criada com `AppBrandedHeader(title: 'Auditoria', showBack: true)`), o
botão voltar podia não ter efeito: chegando à tela por navegação sem pilha
(ex.: fluxo histórico que usava `pushReplacementNamed`), o `pop` não tinha
para onde ir.

**Causa raiz:** composição de dois fatores.

- O acesso antigo "Histórico de preços" do drawer navegava com
  `pushReplacementNamed`, que **remove da pilha** a tela anterior — não era
  possível voltar;
- o cabeçalho `AppBrandedHeader` não tinha plano de saída quando a pilha de
  navegação está vazia (nada a fazer `pop`).

**Correção:** o `leading` de `AppBrandedHeader` em modo `showBack`
(`app_branded_header.dart`, linhas 38–45) passou a testar a pilha:

```dart
if (Navigator.of(context).canPop()) {
  Navigator.of(context).pop();
} else {
  Navigator.of(context).pushNamedAndRemoveUntil(
    '/dashboard',
    (route) => false,
  );
}
```

Com o fallback, qualquer sub-tela aberta por `pushReplacementNamed` (sem
histórico) ou diretamente (sem pilha) sempre oferece uma **saída
determinística para o Dashboard**.

Tabela 2. Comportamento final do botão voltar em `AppBrandedHeader`.

| Estado da pilha | Ação |
|-----------------|------|
| `canPop()` verdadeiro | `pop()` — volta à tela de origem |
| histórico vazio | `pushNamedAndRemoveUntil('/dashboard', …)` — Dashboard vira a única rota |

### 3.2 Navegação reduzida: drawer de 9 para 7 itens

O drawer (`app_drawer.dart`) foi simplificado de **9 para 7 itens**,
ajustando o menu à pirâmide de uso do app:

- **Removidos:** "Comparar preços" e "Histórico de preços";
- **Preservados:** Dashboard, Produtos, Insumos, Orçamentos, Transações,
  Relatórios e Configurações.

Os acessos removidos do menu não desapareceram do sistema — continuam
disponíveis pelos pontos naturais de uso:

- **"Comparar preços":** ícone de comparação na AppBar da tela de
  **Insumos** (linha 48 de `ingredients_screen.dart`), com
  `Navigator.pushNamed(context, '/compare-prices')`;
- **"Histórico de preços" (auditoria):** ícone `history_outlined` na AppBar
  da tela de **Ofertas do insumo** (linhas 67–69 de
  `ingredient_offers_screen.dart`), com
  `Navigator.pushNamed(context, '/audit-logs')`.

As rotas `/compare-prices` e `/audit-logs` **continuam definidas** em
`main.dart` (linhas 156–157) — nada foi removido da tabela de rotas, apenas
do menu. A lista final do drawer está na Tabela 3.

Tabela 3. Itens do drawer após a redução (7 itens, em ordem).

| # | Label | Rota | Ícone |
|---|-------|------|-------|
| 1 | Dashboard | `/dashboard` | `dashboard_outlined` |
| 2 | Produtos | `/products` | `lunch_dining_outlined` |
| 3 | Insumos | `/ingredients` | `inventory_2_outlined` |
| 4 | Orçamentos | `/budgets` | `account_balance_outlined` |
| 5 | Transações | `/expenses` | `receipt_long_outlined` |
| 6 | Relatórios | `/reports` | `bar_chart_outlined` |
| 7 | Configurações | `/settings` | `settings_outlined` |

### 3.3 Camaleão dourado no Dashboard

O Dashboard (`home_screen.dart`, linha 66) passou a exibir a **logo camaleão
em dourado** na AppBar (`AppBrandedHeader(goldLogo: true)`). Para tanto,
`AppBrandedHeader` recebeu o parâmetro opcional `goldLogo` (padrão `false`,
efeito nulo nas demais telas):

```dart
goldLogo
    ? ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.gold,   // Color(0xFFB89775)
          BlendMode.srcIn,
        ),
        child: Image.asset('assets/images/logo.png', …),
      )
    : Image.asset('assets/images/logo.png', …)
```

`BlendMode.srcIn` aplica **tint colorido preservando a silhueta**: todo o
traço do camaleão é pintado com o dourado institucional `0xFFB89775`
(`lib/theme/app_colors.dart`, `AppColors.gold`) — o mesmo dourado já usado
nos acentos do app, sem introduzir cor nova na paleta.

A decisão foi intencionalmente **local**: somente `home_screen.dart` passa
`goldLogo: true`. Todas as demais AppBars mantêm a logo original
(`goldLogo: false`) e o drawer preserva o `logo_drawer.png` original.
Paleta e identidade camaleão ficaram **inalteradas**.

### 3.4 Perfil: salvamento fiel e estado de erro com "Tentar novamente"

O método `_save` da tela de edição de perfil
(`edit_profile_screen.dart`) agora monta o objeto `AppUser` **direto dos
controllers**, em vez de herdar campos parciais da sessão:

```dart
final updated = AppUser(
  uid: current.uid,
  nome: _nomeController.text.trim(),
  email: current.email,
  empresa: _empresaController.text.trim(),
  cnpj: _cnpjController.text.trim(),
  segmento: _segmentoController.text.trim(),
  telefone: _telefoneController.text.trim(),
  endereco: _enderecoController.text.trim(),
  photoUrl: _photoUrl,
  notifOrcamento: current.notifOrcamento,
  notifRecorrentes: current.notifRecorrentes,
  notifMargem: current.notifMargem,
);
```

Consequências:

1. **campos apagados persistem como string vazia (`''`)** — nunca mais um
   valor antigo "vazando" pela fusão do documento (`SetOptions(merge:
   true)` em `FirestoreService.saveUser`) quando o usuário apagou o campo;
2. **flags de notificação preservadas** (`notifOrcamento`,
   `notifRecorrentes` e `notifMargem` copiadas do perfil atual);
3. **toast antes do pop:** `AppToast.success(context, 'Perfil atualizado!')`
   só então `Navigator.pop(context)` — o aviso de sucesso não depende de um
   contexto já desfocado;
4. **estado de erro funcional:** quando `prov.user == null` (falha de
   carregamento do Firestore), a tela mostra o `ErrorState`
   (`lib/widgets/error_state.dart`) com `message: prov.profileError ?? 'Perfil
   não carregado.'` e botão **"Tentar novamente"** chamando
   `await prov.reloadProfile()` (`UserProvider`, que reexecuta
   `loadProfile(uid)`).

### 3.5 `StorageService`: falha explícita com causa

Os métodos do `StorageService` (`lib/services/storage_service.dart`) passaram
a **re-throw com causa legível**:

```dart
catch (e) {
  throw Exception('Falha no upload: $e');
}
```

`deleteFile` lança `'Falha ao excluir arquivo: $e'`. Em vez de falhas
silenciosas ou exceções de rede/Storage enterradas, as telas (cadastro,
perfil, produto, scanner) mostram ao usuário **cadeias de erro legíveis**
com a causa real no final (por exemplo, "Erro ao enviar foto: $e" no fluxo
de cadastro).

## 4. Sprint 2 — Integridade de Salvamento

### 4.1 Bug de deduplicação por nome do fornecedor (`applyOfferUpsert`)

**Bug de severidade ALTA.** O `upsertOffer` (`firestore_service.dart`)
deduplicava pelo **nome do fornecedor** normalizado
(`trim().toLowerCase()`); ao editar uma oferta trocando o nome do
fornecedor, a rotina não encontrava equivalente e **criava uma segunda
oferta em vez de atualizar**, duplicando o item no array.

**Correção (lógica pura):** o upsert foi extraído para uma **função pura e
testável** `applyOfferUpsert(current, offer, {required newOfferId, now?})`
em `lib/utils/offer_rules.dart`, retornando
`OfferUpsertResult(offers, offerId, isCreate, previous)`:

1. **match por `id` prioritário** (`indexWhere((o) => o.id == offer.id)`) —
   edição idempotente: renomear o fornecedor **atualiza** a oferta no lugar,
   preservando `createdAt` e a posição;
2. fallback de upsert por fornecedor normalizado (mantido para novos
   cadastros de mesma parceria);
3. **teto de 15 ofertas** preservado (`ensureOfferLimit` com
   `StateError('Limite de 15 ofertas por insumo atingido.')`);
4. **ordem do array preservada** (substituição in-place, sem reordenação);
5. a **primeira** oferta do insumo nasce ativa
   (`isFirst → isActive: true`), com `activeOfferId` correspondente no
   serviço;
6. o **batch de auditoria fica intacto**: `upsertOffer`
   (`firestore_service.dart`, a partir da linha 267) consome o
   `OfferUpsertResult` e grava o documento do insumo **e** o log
   `offer.create`/`offer.update` no mesmo `WriteBatch`, sem mudança de
   comportamento nas `price_audit_logs`.

**Testes:** 8 testes novos em `test/offer_upsert_test.dart` — entre eles
"applyOfferUpsert nao duplica ao editar oferta trocando nome do
fornecedor", "preserva ordem das ofertas ao atualizar pelo meio", "lanca
StateError ao tentar criar alem do limite de 15" e "atualizar fornecedor
sem mudar preco mantem previousPrice igual".

### 4.2 Preferências de notificação com rollback

A gravação das preferências (`notifications_screen.dart`, rota
`'/settings/notifications'`) gravava os `Switch`es **otimistamente**, sem
esperar o resultado do Firestore — uma falha de rede deixava o exibido
incoerente com o salvo.

Correção em dois pontos:

- **Provider (`user_provider.dart`, `updateNotificationPrefs`):** guarda o
  snapshot `previous`, aplica o estado otimista, faz
  `await _firestore.saveUser(updated)`; em falha **restaura
  `_user = previous`** (rollback) e `rethrow` — o estado exibido nunca fica
  inconsistente com o persistido;
- **Tela:** `await provider.updateNotificationPrefs(orcamento/recorrentes/
  margem: …)` por switch, indicador **"Salvando..."** durante a gravação
  (linha 152) e, no `catch`,
  `AppToast.error(context, 'Erro ao salvar preferência: $e')` com a causa
  legível.

### 4.3 Cadastro: erro final com detalhe da causa

O `catch` final do fluxo de cadastro (`cadastro_screen.dart`) mostra agora a
causa real, além das mensagens amigáveis dos tipos específicos:

```dart
catch (e) {
  _mostrarErro('Não foi possível concluir o cadastro: $e');
}
```

Os blocos `on AuthException` e `on FirebaseAuthException` mantêm as mensagens
amigáveis existentes; o catch genérico vira último recurso legível (ex.:
falha no upload da foto de perfil, indisponibilidade de rede), cobrindo
inclusive o `AppToast.error(context, 'Erro ao enviar foto: $e')` do envio
da foto.

### 4.4 Polish: toasts antes do pop nos formulários

Padronizado o padrão **toast-antes-do-pop**: `AppToast.*` é emitido **antes**
de `Navigator.pop(context)`, garantindo que o feedback fique visível na tela
de destino, não perdido no stack em desfoco. Os cinco formulários principais
adotam o padrão:

1. `transaction_form_screen.dart` — "Transação registrada!" /
   "Transação atualizada!";
2. `budget_form_screen.dart`;
3. `ingredient_form_screen.dart`;
4. `offer_form_screen.dart`;
5. `product_form_screen.dart`.

Complemento: `edit_profile_screen.dart` ("Perfil atualizado!") segue o
mesmo padrão e `cadastro_screen.dart` emite
`AppToast.success(context, 'Cadastro realizado com sucesso!')` antes de
`pushNamedAndRemoveUntil('/dashboard', …)` — o Dashboard abre já com o aviso
de confirmação.

## 5. Sprint 3 — Auditoria de Persistência e Compatibilidade Web

### 5.1 Auditoria completa de escrita (models × regras)

Foi realizada auditoria completa cruzando **rotas de escrita do Firestore ×
modelos (`toMap`/`fromMap`) × regras de segurança**:

- `firestore.rules` — as 6 coleções (`users`, `transactions`, `budgets`,
  `ingredients`, `products`, `price_audit_logs`) permanecem isoladas por
  UID com `users/{uid}/...`; `transactions` mantém a validação de domínio
  nas regras (`amount is number && amount > 0` — RN01); a subcoleção
  `price_audit_logs` é **append-only** (leitura e criação para o dono;
  `update`/`delete: if false`);
- `storage.rules` — isolamento por UID em `users/{uid}/{allPaths=**}` e
  bloqueio genérico `allow read, write: if false`;
- **`toMap`/`fromMap` — SEM mismatch:** nenhum modelo escrito tem campo
  persistido fora do respectivo `fromMap`; o roundtrip foi coberto por
  `test/model_roundtrip_test.dart`.

### 5.2 Bug ALTO: edição de transação recorrente perdia campos

**Bug de severidade ALTA.** O `_save` da tela de transações
(`transaction_form_screen.dart`) montava o `AppTransaction` sem copiar os
**campos de recorrência e anexos** da transação em edição. Salvar a edição
perdia:

- `generatedFrom` (vínculo da instância gerada com a recorrente original);
- `skippedOccurrences` (ocorrências puladas);
- `receiptUrl` (foto do comprovante);
- `budgetId` (vínculo com o orçamento).

**Correção** (linhas 112–125): os quatro campos são repassados de
`widget.editing`:

```dart
final t = AppTransaction.create(
  id: widget.editing?.id ?? '',
  type: _type,
  category: _category,
  description: _descriptionController.text.trim(),
  amount: value,
  date: _date,
  paymentMethod: _paymentMethod,
  recurring: _recurring,
  recurrence: _recurrence,
  generatedFrom: widget.editing?.generatedFrom,
  skippedOccurrences: widget.editing?.skippedOccurrences ?? const [],
  receiptUrl: widget.editing?.receiptUrl,
  budgetId: widget.editing?.budgetId,
  notes: …,
);
```

Com isso, **editar não apaga** o vínculo da recorrência, o comprovante nem o
vínculo com o orçamento.

### 5.3 Compatibilidade web (`kIsWeb`)

Adequação para build web, com diretriz central `kIsWeb`:

- **`dart:io` erradicado de `lib/`** — uma varredura por `grep dart:io
  lib/` retorna **vazio**;
- **`StorageService.uploadBytes`** (`ref.putData(bytes, metadata)`) criado
  como caminho único de upload — funciona em Android/iOS **e** web, sem
  depender de arquivos do sistema;
- os **pickers** (`image_picker`) usam `ImageSource.gallery` quando
  `kIsWeb` (`kIsWeb ? ImageSource.gallery : ImageSource.camera` no scanner
  e nos demais pontos de foto), sempre lendo `XFile.readAsBytes()` antes do
  `uploadBytes` (um único pipeline de bytes);
- **`product_scanner_screen.dart`** ganhou guarda `kIsWeb` com **corpo web
  dedicado** (`_buildWebBody`, linha 391): digitar/colar o código do produto
  manualmente e ação "Escolher foto" pela galeria; as ações **câmera e
  lanterna** ficam **explicitamente indisponíveis na web**;
- o **upload do scanner** segue o mesmo caminho unificado do
  `StorageService` adotado nas demais telas.

Resultado: o aplicativo não tem mais bloqueio tecnológico de `dart:io` para
compilar em web, e as diferenças de plataforma ficam explícitas na
interface.

### 5.4 Riscos registrados

Risco futuro baixo e registrado: `updateTransaction`, `updateBudget` e
`updateProduct` persistem com `doc.set(t.toMap())` **sem merge**. Hoje é
coerente, pois os formulários gravam o payload completo do modelo. Mas, caso
um modelo **ganhe um campo novo** no futuro, o `set()` sem merge
sobrescreveria o documento e **descartaria qualquer campo extra
preexistente**. Recomendação para a v-next: trocar para
`SetOptions(merge: true)` (ou `update()`) nesses setters, com teste de
integração que valide o payload completo.

## 6. Resultados de QA Automatizado

Comandos executados em 27/10/2026, no fechamento da sprint:

**`dart analyze .`** ⇒ **1 issue** (a variante `flutter analyze` não roda
neste workspace pelo caminho contendo "(Cópia)" — verificação do guia de
formatação):

```
info - lib/services/auth_service.dart:107:18 - 'updateEmail' is deprecated
 … Please use verifyBeforeUpdateEmail() instead - deprecated_member_use
```

O único aviso é **pré-existente** (idêntico no snapshot da Sprint 5) e
refere-se à API de `FirebaseAuth` deprecada (sugestão do SDK é
`verifyBeforeUpdateEmail()`). Nenhum `warning` ou `error` novo foi
introduzido nesta sprint.

**`flutter test`** ⇒ **exit 0 — "+128: All tests passed!"**, em **12
arquivos** de teste. A base de 120 testes da Sprint 5 foi mantida e os **8
testes** de `offer_upsert_test.dart` (seção 4.1) adicionados.

Tabela 4. Distribuição dos 128 testes da suíte final (12 arquivos).

| Arquivo | Testes | Escopo |
|---------|-------:|--------|
| `offer_comparator_test.dart` | 23 | Lógica pura de comparação de ofertas |
| `price_panel_aggregator_test.dart` | 15 | Lógica pura do painel (produto/fornecedor) |
| `unit_converter_test.dart` | 15 | Conversão de unidades (g/kg, L/ml) |
| `audit_builder_test.dart` | 15 | Geração de resumos de auditoria |
| `ingredient_active_offer_test.dart` | 15 | Getters de oferta ativa do insumo |
| `offer_upsert_test.dart` (NOVO) | **8** | `applyOfferUpsert` — deduplicação, ordem, teto, `previousPrice` |
| `product_calculator_test.dart` | 10 | Cálculo do ticket (insumos e margem) |
| `recurrence_test.dart` | 10 | Geração/pulação de recorrências |
| `transaction_rules_test.dart` | 9 | Regras de transação (recorrente/estornos) |
| `offer_rules_test.dart` | 4 | Limite de 15 ofertas e validações |
| `model_roundtrip_test.dart` | 3 | `toMap`/`fromMap` sem perda de dados |
| `widget_test.dart` | 1 | Renderização da tela de cadastro |
| **Total** | **128** | |

## 7. Resultados de Build (Web/APK)

As duas builds de distribuição foram executadas no **ambiente final de
desenvolvimento**: Flutter **3.47.2 stable**, Dart **3.13.2**, host **Linux**
(sem Xcode — iOS permanece apêndice, seção 10).

### 7.1 Web — `flutter build web --release`

- **✓ concluída** (compilação de `main.dart` em **27,3 s**), saída em
  `build/web/` (artefato pronto para hospedagem, ex.: Firebase Hosting);
- **aviso não-bloqueante único:** referência à fonte `cupertino_icons`
  ausente, tratada pelo **tree-shaking normal de `MaterialIcons`** (sem
  impacto no build);
- **limitações de runtime já documentadas (seção 5.3) permanecem:** câmera
  do scanner indisponível na web (corpo web = digitar/colar código +
  galeria), pickers via `ImageSource.gallery` quando `kIsWeb`, e `.env`
  **embutido no bundle JS** — decisão aceita, com a segurança real
  delegada às Regras (`firestore.rules`, `storage.rules`), conforme §1.3
  de `context/erros-a-evitar.md`.

### 7.2 Android — `flutter build apk --release`

- **✓ concluída** (Gradle `assembleRelease` em **36,0 s**), saída em
  `build/app/outputs/flutter-apk/app-release.apk` com **75,1 MB**
  (fat APK multi-ABI; reduzir com `--split-per-abi`, seção 9.3);
- **ATENÇÃO — assinatura de debug:** o release está assinado com **chaves
  de debug** (`android/app/build.gradle.kts:41`, marcado com `TODO` — não
  editado nesta sprint). O APK é **apto para teste em dispositivo**
  (instalação e QA manual da seção 8), porém **NÃO publicável na Play
  Store** até configurar `key.properties` + keystore de assinatura, que
  corretamente **não existem no repositório** (§1.1 de
  `context/erros-a-evitar.md` — segredos nunca versionados);
- **bundle identifier:** `com.example.ctrlcash` (placeholder histórico em
  `android/app/build.gradle.kts`) — registrado como **pendência de
  produção** (renomear em par com a assinatura), sem promessa de mudança
  neste fechamento.

### 7.3 Consolidação QA + build

Tabela 6. Consolidação final de QA e builds (27/10/2026).

| Verificação | Resultado |
|-------------|-----------|
| `dart analyze .` | 1 info pré-existente (`updateEmail` deprecated, `auth_service.dart:107`) |
| `flutter test` | **128/128** passando (12 arquivos) |
| `flutter build web --release` | ✓ (27,3 s) — `build/web/` |
| `flutter build apk --release` | ✓ (36,0 s) — `app-release.apk` (75,1 MB) |
| iOS | **não construído** nesta fase (decisão do usuário — apêndice 10) |
| Assinatura do APK | chaves de debug — teste ok, Play Store bloqueada até produção |

## 8. Checklist de Teste Manual por Tela

Roteiro de QA funcional a executar (web e Android), com os pontos
resultantes desta sprint. Execução combinada com o QA automatizado (seção
6) completa o fechamento.

Tabela 5. Checklist de teste manual por tela.

| # | Tela | Ação de teste | Resultado esperado |
|---|------|---------------|--------------------|
| 1 | Dashboard | Verificar logo camaleão **dourada** na AppBar | Silhueta preservada, traço `0xFFB89775`, sem cor nova |
| 2 | Drawer | Contar os itens | **7 entradas**, na ordem da Tabela 3 |
| 3 | Insumos | Tocar ícone de comparação | Abre `/compare-prices` (push), voltar retorna |
| 4 | Ofertas do insumo | Tocar ícone de histórico | Abre `/audit-logs` (push) |
| 5 | Auditoria | Voltar pela AppBar | Sai da tela (pop) ou cai no fallback `/dashboard` |
| 6 | Perfil | Apagar campo e salvar | Valor persiste como `''` (sem "vazamento" do valor antigo) |
| 7 | Perfil | Simular falha de rede e tapar "Tentar novamente" | `reloadProfile()` reexecuta sem travar |
| 8 | Oferta — editar | Renomear fornecedor e salvar | **1 oferta** (id preservado), sem duplicata |
| 9 | Oferta — teto | Criar a 16ª oferta | `StateError('Limite de 15 ofertas por insumo atingido.')` |
| 10 | Notificações | Desligar switch com rede fora | Rollback no provider + toast com causa |
| 11 | Notificações | Salvar com rede ok | "Salvando..." → "Preferência salva" → valor persistido |
| 12 | Transação recorrente | Editar e salvar | `generatedFrom`, `skippedOccurrences`, `receiptUrl` e `budgetId` preservados |
| 13 | Cadastro | Falhar no meio do fluxo | Erro legível com causa (`'Não foi possível concluir o cadastro: $e'`) |
| 14 | Uploads (web e Android) | Foto de perfil, do produto e do scanner | todos por `StorageService.uploadBytes` com URL no doc |
| 15 | Scanner (web) | Entrar em `/product-scanner` no Chrome | corpo web ativo: digitar/colar código + "Escolher foto"; sem câmera/lanterna |
| 16 | Scanner (Android) | Usar câmera nativa | pipeline de foto via `ImageSource.camera`, upload via `uploadBytes` |
| 17 | Transações | Salvar transação | toast dourado **antes** do `pop`, visível na tela de destino |
| 18 | Orçamento / Insumo / Oferta / Produto | Salvar | idem, toast antes do pop nos cinco formulários |
| 19 | Notificações offline | Firestore offline → salvar preferência | erro visível, switch retorna ao estado anterior |
| 20 | Auditoria visual | Conferir paleta e padrões | aparência idêntica à pré-sprint — zero cor nova |

## 9. Como Rodar e Testar

### 9.1 Requisitos

```
$ flutter --version      # canal estável compatível com SDK Dart ^3.11.5
$ dart --version
```

Dependências do app no fechamento (`pubspec.yaml`): `firebase_core ^3.0.0`,
`firebase_auth ^5.0.0`, `flutter_dotenv ^5.2.0`, `provider ^6.1.2`,
`cloud_firestore ^5.0.0`, `fl_chart ^0.69.0`, `image_picker ^1.1.2`,
`firebase_storage ^12.0.0`, `mobile_scanner ^6.0.2`,
`flutter_local_notifications ^19.0.0` (e `flutter_lints ^6.0.0` em dev).
**O login social (Google/Facebook) não existe no `pubspec.yaml` atual** —
o `AuthService` expõe somente e-mail/senha.

### 9.2 `.env` e Firebase

Como registrado nos RTs anteriores (e em `context/erros-a-evitar.md`,
§1.3), as credenciais do Firebase **vivem apenas no `.env`** e são lidas
com `flutter_dotenv` em `lib/firebase_options.dart`; a segurança real vem
das Regras (`firestore.rules`, `storage.rules`) — a API key é restrita ao
projeto, não substitui as regras. **No build web**, as variáveis do `.env`
são **embutidas no bundle JS**; essa decisão está documentada e aceita
(§1.3 do "Erros a Evitar").

O `.env` é criado a partir de `.env.example` (valores vazios), com as
mesmas chaves — **não expostas neste documento**.

### 9.3 Rodando e testando

**Passo a passo (base de desenvolvimento):**

```
$ flutter pub get      # restaura as dependências
$ dart analyze .       # verificação estática (workspace com "(Cópia)")
$ flutter test         # 128 testes / 12 arquivos
```

**Android (dispositivo físico) — duas formas:**

```
$ flutter run                          # dev direto no dispositivo conectado (USB/ADB)
$ flutter build apk --release          # gera build/app/outputs/flutter-apk/app-release.apk
$ adb install -r build/app/outputs/flutter-apk/app-release.apk   # instala o APK
```

O APK de release (seção 7.2) é assinado com chaves de debug — instalável
para teste em dispositivo, não publicável na Play Store. A opção
`--split-per-abi` gera variantes por arquitetura (`v7a`, `v8a`, `x86_64`),
reduzindo o tamanho por APK.

**Web (local) — duas formas:**

```
$ flutter run -d chrome    # dev com hot reload no Chrome
$ flutter build web        # gera build/web/ (servir o diretório hospedando-o)
```

Para conferir o build pronto, servir o conteúdo de `build/web/` por um
servidor estático local e abrir no navegador (testar seções 5.3 e 8 nos
pontos marcados como web).

**Testes automatizados:**

```
$ flutter test             # suíte completa: 128/128 (seção 6)
```

### 9.4 Deploy das regras (operação)

Antes de distribuir, implantar as regras vigentes (operação de
console/CLI, não de código):

```
$ firebase deploy --only firestore:rules,storage
```

## 10. Apêndice iOS (não construído nesta fase)

O build iOS **não foi realizado nesta fase** por decisão do usuário: a
máquina de desenvolvimento é **Linux, sem Xcode**, e a pasta `ios/` não
existe no repositório (apenas `android/` e `web/` presentes). Nenhum
problema de código bloqueia o iOS — é **dependência de ambiente**.
Checklist futuro resumido:

1. `flutter create --platforms=ios .` para gerar o Runner iOS;
2. criar o app **iOS** no console do Firebase (bundle identifier exposto
   em `android/app/build.gradle.kts` como `com.example.ctrlcash`) e baixar
   o `GoogleService-Info.plist` para `ios/Runner/`;
3. ** `.env`** — chaves no `.env` já válidas; o `flutter_dotenv` lê as
   mesmas credenciais (atenção ao **reCAPTCHA**/condições de login
   e-mail/senha no iOS);
4. `pod install` no Mac (Xcode compatível) para os pods nativos
   (`firebase_core`, `firebase_storage`, notificações, `mobile_scanner`);
5. `flutter build ios --release` (ou `flutter build ipa --release`) no Mac,
   gerando o artefato assinado.

## 11. Estado Final e Considerações

Na conclusão da Sprint 6, o CashCtrl encontra-se em **estado de
fechamento**:

- **identidade camaleão e paleta preservadas** (`0xFF0D1E16`, `0xFF165A41`,
  `0xFFB89775`, `0xFF142A20`, `0xFF7A8B83`) — nenhuma cor nova foi
  adicionada; o único acréscimo visual (camaleão dourado no Dashboard)
  reutiliza o dourado institucional via `BlendMode.srcIn`;
- **rotas legadas mantidas** — as 25 rotas nomeadas de `main.dart`
  permanecem (incluídas `/compare-prices` e `/audit-logs`, fora do drawer),
  sem quebra de deep links anteriores;
- **`firestore.rules` e `storage.rules` intactos** — 6 coleções, isolamento
  por UID, append-only nas `price_audit_logs` e `amount > 0` (RN01) nas
  transações;
- **4 bugs corrigidos** (voltar morto; duplicação de oferta ao renomear
  fornecedor; campos perdidos ao editar recorrente; salvamento de perfil
  sem "vazamento");
- **QA automatizado limpo:** 128/128 testes (12 arquivos) e `dart analyze`
  sem introdução de erro/warning (1 info pré-existente no `updateEmail`
  deprecado);
- **web compilável sem `dart:io`**, scanner com corpo web dedicado e
  upload unificado em `StorageService`.

Pendências para pós-fechamento: (i) **assinatura de release** do APK
(chaves de debug hoje — ver seção 7.2) e eventual **renomeação** do bundle
identifier `com.example.ctrlcash`, ambos pendências de produção;
(ii) ativação do TTL de 180 dias nas `price_audit_logs` no console/GCP
(operacional); (iii) deploy das regras (operação de console); (iv) projeto
iOS quando houver ambiente Mac (apêndice 10); (v) migração eventual dos
setters sem merge para `merge: true`/`update()` na v-next (risco
registrado na seção 5.4).

## Referências

- Código-fonte: `lib/main.dart`, `lib/home_screen.dart`,
  `lib/theme/app_colors.dart`, `lib/widgets/app_branded_header.dart`,
  `lib/widgets/app_drawer.dart`, `lib/widgets/error_state.dart`,
  `lib/services/storage_service.dart`,
  `lib/services/firestore_service.dart`,
  `lib/providers/user_provider.dart`, `lib/utils/offer_rules.dart`,
  `lib/screens/settings/edit_profile_screen.dart`,
  `lib/screens/settings/notifications_screen.dart`,
  `lib/screens/ingredients_screen.dart`,
  `lib/screens/ingredient_offers_screen.dart`,
  `lib/screens/cadastro_screen.dart`,
  `lib/screens/transaction_form_screen.dart`,
  `lib/screens/product_scanner_screen.dart`,
  `lib/screens/product_form_screen.dart`,
  `lib/screens/budget_form_screen.dart`,
  `lib/screens/ingredient_form_screen.dart`,
  `lib/screens/offer_form_screen.dart`.
- Regras de segurança: `firestore.rules`, `storage.rules`.
- Testes: os 12 arquivos de `test/` (Tabela 4, incluindo o novo
  `offer_upsert_test.dart`).
- Documentação de apoio: `docs/overview.md`;
  `documentacao/ctrlcash_documentacao.txt`;
  `documentacao/logs/metadata/sprint5_2026-10-12_fechamento.md`;
  `context/erros-a-evitar.md` (§1.3 — segredos e web).
- Relatórios anteriores do padrão BIBLIOTECA:
  `documentacao/BIBLIOTECA_113_RT_279.docx` (template),
  `documentacao/CTRLCASH_SPRINT2_PROPOSTA_A_RT.docx`,
  `documentacao/CTRLCASH_SPRINT3_PAINEL_COMPARACAO_FUTURO_RT.docx`,
  `documentacao/CTRLCASH_SPRINT4_MODULO_COMPARATIVO_RT.docx`.

---

## Figuras pendentes (capturas de tela)

- Figura 21 — Dashboard com camaleão dourado na AppBar.
  `[captura de tela pendente]`
- Figura 22 — Drawer final com 7 itens. `[captura de tela pendente]`
- Figura 23 — Corpo web do scanner (`kIsWeb`): digitar/colar código e
  "Escolher foto". `[captura de tela pendente]`

*(Numeração contínua após as Figuras 14–20 do RT da Sprint 4; capturas a
inserir quando houver dispositivo/emulador.)*
