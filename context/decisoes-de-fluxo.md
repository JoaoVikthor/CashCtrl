# Decisões de Fluxo (tratar como permanente)

## Fluxo de UI: protótipo antes do código
- **Aprovado pelo usuário em 2026-10-07:** para telas novas ou mudanças visuais relevantes, gerar primeiro **protótipo HTML estático** fiel à identidade (paleta/tokens/microcopy reais) em `documentacao/logs/<sprint>/prototipo_*.html`, abrir para aprovação, e **só então** implementar em Flutter.
- O protótipo deve cobrir estados principais (happy path) e, quando pedido, variantes (vazio/erro/limite).
- Veto do usuário: não "pular" direto para a tela codificada quando houver mudança de layout.

## Identidade (reafirmado)
- Paleta fixa, logo camaleão intocável.
- O app **não deve ter cara de template genérico de IA**: evitar cards idênticos em tudo, ícones mistos (um único conjunto), espaçamento sem ritmo, tipografia sem hierarquia. Ver auditoria do design-analyst em `documentacao/logs/` quando existir.

## Painel de comparação: demonstrável fora do app (Aprovado pelo usuário em 2026-10-08 — diretriz do professor)
- **NÃO implementar o painel "Comparar preços" no Flutter por enquanto.** O app atual (home como mostruário do produto real) permanece intocado; o painel é a **implementação futura** do diferencial (usuário vê os produtos com os preços de cada fornecedor e compara).
- A entrega agora é o **protótipo HTML interativo** (demo clicável com dados de exemplo fiéis ao modelo real `offers[]`/R$por unidade) em `documentacao/logs/sprint3/prototipo_painel_precos.html`.
- O relatório técnico ganha capítulo **"Implementação futura — Painel de Comparação de Preços"** (versão v2 do .docx; original preservado).
- Automação (níveis L1–L3 de `documentacao/logs/sprint3/innovacao_comparativo_automatizado.md`) segue em backlog, condicionada ao gate de política ("o app nunca troca sozinho").
- Quando for implementar de verdade: fonte de dado = agregação client-side dos insumos já existentes (sem mudança de schema); rota sugerida `/comparar-precos`; política do ticket permanece manual.
- **Evolution (2026-10-08, mesma sessão — pedido do usuário):** a demo foi aceita e vira **módulo utilizável dentro do app**: tela "Comparar preços" no drawer com todas as funções do protótipo (painel por produto, ordenação/busca/filtro, detalhe via `/ingredient-offers`, visão por fornecedor, estados vazio/1-fornecedor, troca com confirmação + undo + auditoria). Decisão "fora do app" é substituída por esta; o protótipo HTML vira a especificação aprovada. Rota no padrão do repo: `/compare-prices`. Sem mudança de schema (dados já existem).

## Quem cadastra produtos/ofertas dos fornecedores (Confirmado pelo usuário em 2026-10-08)
- **Exclusivamente o usuário (dono do negócio).** O fornecedor **nunca** escreve no sistema — não há portal/app do fornecedor nem proposta direta.
- Consequência para o **módulo separado** (a ser anexado ao projeto): qualquer dado que ele gere (cadastro em lote, importação, OCR, etc.) deve desaguar no **form de revisão do usuário** antes de virar oferta em `insumo.offers[]` — nada entra ativo sem confirmação humana do usuário (reforça "o app nunca troca sozinho").
- Escrita em `offers[]` permanece isolada por UID do usuário; regras do Firestore existentes não precisam de exceção para terceiros.
- Badge/registro de origem da oferta (`manual` | `importacao` | `ocr`) é desejável para o usuário ponderar confiabilidade, mas a **responsabilidade pelo cadastro é sempre do usuário**.
