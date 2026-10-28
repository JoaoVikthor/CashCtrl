# Proposta A — Detalhamento técnico (base p/ implementer)

Consolidado a partir das análises paralelas (innovator + advisor).  
Aguarda aprovação das 5 perguntas do gate antes do Sprint 2.

## Decisão técnica preliminar (sujeita ao gate)

| Item | Recomendação MVP |
|------|------------------|
| Onde guardam as ofertas | **Array `offers[]` no doc do insumo** + campos sintéticos |
| Teto de ofertas | **15** por insumo |
| Preço do ticket | **`activeOfferId` explícito** do usuário |
| Comparar por | `pricePerUnit` (nunca só preço da embalagem) |
| Duplicatas | **Upsert** por fornecedor normalizado |
| Logs | `users/{uid}/price_audit_logs/{id}` append-only + `expireAt` |
| Migração | Lazy, idempotente, fallback legado no calculator |
| Rules | Novos matches **antes** do catch-all; deploy antes do app |

## Schema sugerido (array MVP)

```
users/{uid}/ingredients/{ingredientId}
  name, unit, purchasePrice, packageQuantity, createdAt
  activeOfferId: String?
  lowestPricePerUnit: double?
  bestSupplier: String?
  offersCount: int?
  offers: [
    {
      id, supplier,
      packagePrice, packageQuantity,
      pricePerUnitCache,
      isActive, isDefault,
      source, notes?,
      createdAt, updatedAt
    }
  ]
```

## Schema de log

```
users/{uid}/price_audit_logs/{logId}
  uid, timestamp (serverTimestamp),
  action, entityType, entityId, entityName?,
  supplier?, previousPrice?, newPrice?,
  previousPackageQuantity?, newPackageQuantity?,
  pricePerUnit?, source, summary,
  expireAt
```

## Rules (resumo)

```
match /ingredients/{ingredientId} {
  allow read, write: if auth.uid == uid;
  // validação extra de packagePrice/Quantity no form + reforço futuro
}
match /price_audit_logs/{logId} {
  allow read: if auth.uid == uid;
  allow create: if auth.uid == uid && campos mínimos ok;
  allow update, delete: if false;
}
```

## Ordem de implementação (Sprint 2)

1. `firestore.rules` (+ deploy manual pelo usuário no Console)
2. Models: `IngredientOffer`, `PriceAuditLog` + ajuste `Ingredient`
3. Lógica pura: ranking, delta, cenário best (`lib/utils/`)
4. `FirestoreService`: CRUD ofertas + log em batch
5. Providers
6. Telas: offer_form, ingredient_offers, ajustes list/form insumo
7. Ticket: cenário best + alerta
8. audit_logs_screen (leitura)
9. Migração lazy
10. `flutter analyze` + testes puros da lógica

## Critérios de aceite (do advisor)

1. Comparativo ordena por preço/unidade ascendente  
2. Badge “MAIS BARATO” + “OFERTA ATIVA”  
3. `packageQuantity<=0` ou preço ≤ 0 rejeitado  
4. Ticket usa oferta ativa; alerta se existe mais barata  
5. Upsert: mesmo fornecedor não duplica  
6. Editar 1 oferta não apaga as outras  
7. Doc legado sem offers → 1 oferta sintética; custo do ticket inalterado  
8. Log append-only; update/delete de log negado nas rules  
9. Rules: outro UID não lê logs/ofertas  
10. Ordenação estável com centavos  
11. Form bloqueia 16ª oferta  
12. `flutter analyze` limpo; sem comentários novos no Dart  

## Perguntas do gate (responder p/ liberar Sprint 2)

1. Preço do ticket: (a) oferta ativa explícita / (b) mais barato / (c) última compra  
2. Modelo: (a) array no doc / (b) subcoleção  
3. Histórico no MVP: (a) não / (b) sim  
4. Retenção logs: (a) 180d / (b) sem expirar / (c) outro  
5. Oferta ativa: (a) escolha do usuário / (b) automática mais barata  
