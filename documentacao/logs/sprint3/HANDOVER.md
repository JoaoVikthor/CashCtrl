# Handover — Sprint 3 / Módulo "Comparar preços"
**Data:** 2026-10-08 · **Status:** implementação concluída e validada (analyze + testes); smoke test real e commit PENDENTES do usuário

## Objetivo da sprint
Transformar a demo HTML aprovada em **módulo utilizável dentro do app** (pedido do usuário, evoluindo a diretriz do professor — registrado em `context/decisoes-de-fluxo.md`): tela "Comparar preços" no drawer com todas as funções do protótipo, sobre os dados reais da Sprint 2 (`offers[]`), sem mudança de schema.

## Gate aprovado (decisões do usuário)
- Protótipo HTML demonstrável primeiro → ACEITO → vira módulo real do app.
- Painel apenas informa/navega: política intocada "o app nunca troca sozinho"; troca continua manual na tela de ofertas.
- Docs: registrar decisão + capítulo no RT (.docx v2 novo, original Sprint 2 preservado).

## O que foi entregue
- **Relatórios de planejamento (3):** `documentacao/logs/sprint3/innovacao_comparativo_automatizado.md` (escada L0–L4), `critica_comparativo_automatizado.md` (ressalvas vinculantes), `redesign_comparativo_automatico.md` (V0–V3).
- **Protótipo interativo:** `documentacao/logs/sprint3/prototipo_painel_precos.html` (70 KB, JS puro, demo navegável com troca + desfazer + 3 estados) — especificação aprovada da UI.
- **Lógica pura:** `lib/utils/price_panel_aggregator.dart` (ProductPanelEntry/SupplierPanelEntry/PanelSummary; buildPanel/sortPanel/filterPanel/summarize/buildSupplierReport/rowsForSupplier) + `test/price_panel_aggregator_test.dart` (15 testes).
- **UI:** `lib/screens/compare_prices_screen.dart` (tabs Por produto|Por fornecedor; eco-line com soma honesta de deltas/un; busca + ordenação + **chips de fornecedor**; EmptyState vazio; banner 1-fornecedor; "sem comparação" p/ legado; sentinela "—"); `lib/widgets/panel_product_card.dart`; `lib/widgets/supplier_summary_card.dart`.
- **Integração:** drawer "Comparar preços" (`Icons.compare_arrows_outlined`, após Insumos), rota `/compare-prices` (25 rotas), tap no card → `/ingredient-offers` existente; `ingredient_offers_screen.dart` ganhou **"Desfazer"** no SnackBar de troca de oferta ativa.
- **Verificação (executada e confirmada pelo orquestrador):** `dart analyze .` limpo · `flutter test` **39/39** (24 Sprint 2 + 15 novos) · pubspec intacto (zero deps novas) · 100% read-only (única escrita: troca manual já existente).
- **Docs:** `documentacao/CTRLCASH_SPRINT3_PAINEL_COMPARACAO_FUTURO_RT.docx` (28 pág., cap. 7 "Implementação futura" — re-rotular quando aceite visual) + fontes em `documentacao/logs/sprint3/docs_*`.
- **Metadata:** snapshot `documentacao/logs/metadata/sprint3_2026-10-08_comparar_precos.md` (lib +4 arquivos/+1.319 linhas; rotas 24→25; testes 24→39).

## Pendências do usuário (nesta ordem)
1. **`.env` real** (cópia tem arquivo de 0 bytes) → sem isso não roda.
2. **Deploy das rules da Sprint 2** (ainda não executado): `firebase deploy --only firestore:rules` — bloqueia logs/offertas no mundo real.
3. **Smoke test visual** do módulo: abrir app → drawer → Comparar preços → (a) eco-line bate com os deltas; (b) filtros combinam; (c) card → ofertas → "usar no ticket" → **Desfazer**; (d) estados vazio/1-fornecedor com dados reais.
4. **Commit:** NADA commitado desde `caed584`. Ondas sugeridas: (a) setup agentes/infra Sprint 1; (b) Sprint 2; (c) Sprint 3 (módulo + protótipo + docs + metadata). Só com pedido explícito.
5. **RT v2:** trocar rótulo "implementação futura" → "implementado (módulo)" após aceite visual; capa com placeholders de autores.
6. **Polish backlog:** chips individuais de fornecedor já existem no tab produto; "maior economia" por unidade (não semanal) — se quiser economia semanal de verdade, precisa campo de consumo no modelo (decisão nova de produto).

## Próximo passo recomendado
1. Restaurar `.env` → deploy rules → rodar o app e fazer o smoke test acima (10 min).
2. Ajustes que o teste revelar (mini-sprint de polish).
3. Commit das 3 ondas + re-rotular cap. 7 do RT.

## Roteiro de demonstração (professor)
Drawer → Comparar preços → mostrar eco-line e deltas por unidade → filtrar por fornecedor → abrir Queijo mussarela → trocar oferta → Desfazer → tab "Por fornecedor" → posições e ★. Alternar dados para os estados vazio/1-fornecedor se quiser.
