# Handover — Sprint 2 / Proposta A (Comparação de Fornecedores)
**Data:** 2026-10-07 · **Status:** implementação concluída e validada; pendências operacionais com o usuário

## Objetivo da sprint
Implementar a Proposta A: ofertas `offers[]` aninhadas no insumo (teto 15), `activeOfferId` escolhido manualmente (app nunca auto-troca), logs de auditoria `price_audit_logs` append-only (180d), ranking por R$/un, cenário de economia no ticket, migração lazy sem regressão.

## Gate aprovado (todas "a")
Ticket usa oferta ativa manual · array no doc · sem histórico no MVP · logs 180d · escolha explícita da ativa.

## O que foi entregue
- **Camada de dados:** `lib/models/ingredient_offer.dart`, `lib/models/price_audit_log.dart`; `ingredient.dart` com `offers`/`activeOfferId` + getters (`pricePerUnit` = ativa→fallback legado); `firestore_service.dart` com batch+logs (`upsertOffer`, `setActiveOffer`, `toggleOfferActive`, `deleteOffer`, `migrateLegacyPrice`, `priceAuditLogsStream`), `updateIngredient` protegido contra apagar ofertas; `ingredient_provider.dart` wrappers; `firestore.rules` com `price_audit_logs` (read/create dono; update/delete false) **antes do catch-all**.
- **Lógica pura:** `lib/utils/offer_comparator.dart` (rank, bestOffer, syntheticLegacyOffer, hasDifferentPackageSizes, bestSupplierScenario, deltas).
- **UI:** 14 widgets novos em `lib/widgets/`; telas novas `ingredient_offers_screen`, `offer_form_screen`, `audit_logs_screen`; integração em `ingredients_screen` (badge/markers/storefront), `ingredient_form_screen` (seções Fornecedor padrão/Ofertas), `product_detail_screen` (`EconomySummaryCard` após veredito); rotas `/ingredient-offers`, `/offer-form`, `/audit-logs` no `main.dart`.
- **Verificação:** `dart analyze .` limpo · `flutter test` 24/24 (23 testes novos). Obs.: `flutter analyze` crasha no analysis server por causa do caminho `"(Cópia)"` — usar `dart analyze .`.
- **Docs:** `documentacao/CTRLCASH_SPRINT2_PROPOSTA_A_RT.docx` (23 pág., padrão BIBLIOTECA), `documentacao/logs/sprint2/docs_sprint2_proposta_a.md` + esqueleto + plano de design + `GUIA_FORMATACAO_DOCX.md`; `docs/overview.md` atualizado.
- **Metadata:** snapshot `documentacao/logs/metadata/sprint2_2026-10-07_proposta_a.md` (lib/ +3.528 linhas, rotas 21→24).

## Depende do usuário (ações pendentes)
1. **Deploy das rules ANTES de rodar/distribuir o app:** `firebase deploy --only firestore:rules` (senão logs/offertas são bloqueadas pelo catch-all).
2. **`.env`:** a cópia tem `.env` de 0 bytes (criado por agente para testes). Restaurar o `.env` real do projeto original para rodar o app.
3. **Commit:** nada foi commitado. Duas ondas sugeridas: (a) setup de agentes/infra pendente da Sprint 1; (b) Sprint 2 completa. Só com pedido explícito.
4. **Limpeza de sobras** (aguardando confirmação): versionar ou ignorar `devtools_options.yaml`; definir se `documentacao/` entra no git; `.opencode/node_modules/` (62 MB, gitignored) manter ou limpar.
5. **Aceite visual:** rodar o app e testar o fluxo (criar oferta → ativar → badge → economia no ticket → auditoria). Figuras 3–8 do .docx dependem de capturas.

## Próximo passo recomendado
1. Restaurar `.env` → `firebase deploy --only firestore:rules` → smoke test manual do fluxo de ofertas.
2. Ajustes de UI que o teste revelar (mini-sprint de polish).
3. Commit das duas ondas.
4. Depois: fila da Sprint 1 de inovações — item 3 (simulação de sensibilidade, baixa complexidade) ou 6 (duplicar ficha técnica).
