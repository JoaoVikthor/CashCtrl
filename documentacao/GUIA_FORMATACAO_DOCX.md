# Guia de Formatação — DOCX do CashCtrl no padrão BIBLIOTECA

Guia do pipeline de geração dos relatórios técnicos do CashCtrl, espelhando o
template `documentacao/BIBLIOTECA_113_RT_279.docx` (relatório técnico ICMC
"Documentação Técnica da Aplicação Web Homework").

---

## 1. Pipeline de geração

```
Markdown (autoria)  →  HTML (estilos do template)  →  soffice --headless  →  .docx
```

Arquivos do Sprint 2 (Proposta A):

| Etapa | Arquivo |
|-------|---------|
| Autoria (Markdown) | `documentacao/logs/sprint2/docs_sprint2_proposta_a.md` |
| HTML com estilos | `documentacao/logs/sprint2/ctrlcash_sprint2_proposta_a_rt.html` |
| DOCX final | `documentacao/CTRLCASH_SPRINT2_PROPOSTA_A_RT.docx` |

Arquivos do Sprint 3 (RT v2 — capítulo de implementação futura; o DOCX da Sprint 2
permanece preservado, sem sobrescrita):

| Etapa | Arquivo |
|-------|---------|
| Autoria do capítulo (Markdown) | `documentacao/logs/sprint3/docs_sprint3_painel_precos_futuro.md` |
| RT v2 fundido (Markdown) | `documentacao/logs/sprint3/docs_rt_v2_com_capitulo_futuro.md` |
| HTML com estilos | `documentacao/logs/sprint3/ctrlcash_sprint3_rt_v2.html` |
| DOCX final (novo, v2) | `documentacao/CTRLCASH_SPRINT3_PAINEL_COMPARACAO_FUTURO_RT.docx` |

Comando de conversão (o filtro precisa ser explícito para HTML→DOCX):

```bash
soffice --headless --convert-to "docx:MS Word 2007 XML" \
  --outdir documentacao documentacao/logs/sprint3/ctrlcash_sprint3_rt_v2.html
mv documentacao/ctrlcash_sprint3_rt_v2.docx \
   documentacao/CTRLCASH_SPRINT3_PAINEL_COMPARACAO_FUTURO_RT.docx
```

Arquivos do Sprint 6 (Fechamento/QA — o DOCX das Sprints 2–4 permanecem
preservados, sem sobrescrita):

| Etapa | Arquivo |
|-------|---------|
| Autoria (Markdown) | `documentacao/logs/sprint6/docs_sprint6_fechamento_qa_rt.md` |
| HTML com estilos | `documentacao/logs/sprint6/ctrlcash_sprint6_fechamento_qa_rt.html` |
| DOCX final | `documentacao/CTRLCASH_SPRINT6_FECHAMENTO_QA_RT.docx` |

Arquivos do Sprint 7 (Fechamento Final — cobre Sprints 5, 6 e 7; 19 páginas):

| Etapa | Arquivo |
|-------|---------|
| Autoria (Markdown) | `documentacao/logs/sprint7/docs_sprint7_fechamento_final_rt.md` |
| HTML com estilos | `documentacao/logs/sprint7/ctrlcash_sprint7_fechamento_final_rt.html` |
| DOCX final | `documentacao/CTRLCASH_SPRINT7_FECHAMENTO_FINAL_RT.docx` |

Observações do Sprint 7:

- Figuras 24–29 (capturas pendentes), continuando a numeração do Sprint 6;
- Tabelas 1–6;
- `docs/overview.md` foi atualizado na mesma entrega (vocabulário, categorias,
  Excel, Relatórios unificados, scanner/barcode removido e dependências).

Observações do Sprint 6:

- Numeração de figuras continua a do Sprint 4: Figuras 21–23 (capturas pendentes).
- Tabelas 1–6 (a Tabela 6 consolida QA + builds).
- Rodapé com PAGE replicado do DOCX da Sprint 4 (extração de `word/footer1.xml`
  e re-injeção via zipfile) — pgMar fica **inalterado** (o footer="567" do item
  abaixo NÃO é necessário; a Sprint 4 validada usa `w:footer="0"`); inserir
  apenas `<w:footerReference w:type="default" r:id="rIdFtr1"/>` logo após
  `<w:sectPr>` e a `Relationship rIdFtr1` + `Override footer+xml`.
- Seção 7 do RT ("Resultados de Build (Web/APK)") foi **fechada com os números
  reais** (web 27,3 s → `build/web/`; APK 36,0 s → `app-release.apk` 75,1 MB,
  assinatura de debug registrada como pendência de produção).

Arquivos do documento de Respostas aos Pendentes da v0.2 (respostas aos 42
marcadores do revisor, contra a versão definitiva v1.0.0+1):

| Etapa | Arquivo |
|-------|---------|
| Autoria (Markdown) | `documentacao/logs/respostas_v02/docs_respostas_marcadores_v02.md` |
| Espelho na raiz (Markdown) | `documentacao/respostas-marcadores-v0.2.md` |
| HTML com estilos | `documentacao/logs/respostas_v02/ctrlcash_respostas_v02.html` |
| Script de embutir figuras | `documentacao/logs/respostas_v02/embutir_figuras.py` |
| Script de rodapé | `documentacao/logs/respostas_v02/injetar_rodape.py` |
| DOCX final | `documentacao/CTRLCASH_RESPOSTAS_V02.docx` |

Observações das Respostas v0.2 (validado em 28/10/2026, LibreOffice 25.2.3.2):

- Sinalização textual dos marcadores (emojis não sobrevivem ao DOCX):
  ✅ → tag/palavra **VERIFICADO NO CÓDIGO**; 🔧 → **DECISÃO DA EQUIPE**;
  ❓ → **A CONFIRMAR PELA EQUIPE** (classe `p.tag`, Arial 10,5pt bold);
  itens da equipe permanecem explicitamente em aberto, sem resposta inventada.
- Estrutura: capa + Indice + 9 seções numeradas (H1) e 26 subseções (H2);
  Tabelas 1–3 (7×3, 12×2, 6×2); Figuras 1 e 2 embutidas
  (fig1_casos_de_uso.png 1001×1011 — casos de uso; fig2_modelo_dados.png
  1001×761 — modelo de dados no Firestore), centralizadas com largura de 17 cm
  e legenda em `p.cap` abaixo da imagem (sinalização dos itens 6 e 7:
  VERIFICADO NO CÓDIGO + FIGURA).
- Blocos `pre` reformatados para ≤ 66 colunas (10pt Courier estoura a margem
  útil acima disso).
- Rodapé injetado com o script `injetar_rodape.py` (argumentos: docx e texto;
  formata "N — <texto>" centrado, Georgia 10pt, campo PAGE sem `separate`).
- **Imagens embutidas com `embutir_figuras.py`** (argumentos: docx, pasta das
  imagens, largura em cm — padrão 17): o import HTML→DOCX do LibreOffice
  (Writer/Web) deixa as imagens como **links externos**
  (`TargetMode="External"` + `<a:blip r:link>`) e aplica o tamanho natural a
  96 dpi (1001 px → 26,5 cm, estourando a largura útil de ~18 cm; o CSS
  `width: 17cm` no `<img>` é ignorado). O script copia os PNGs para
  `word/media/`, troca `r:link` por `r:embed` e normaliza `wp:extent`/`a:ext`
  para a largura informada, mantendo proporção.
- **Imagem + legenda juntos:** quando a imagem fecha a página, a legenda
  (`p.cap`, parágrafo seguinte) abre a página seguinte — usar quebra de página
  inline (`style="page-break-before: always"`) no parágrafo da imagem (caso da
  Figura 1). Validar no PDF (`pdfimages -list`: ppi ≈ pixels ÷ (largura em
  polegadas) confirma a largura aplicada; 1001 px a 150 ppi ≈ 17 cm).
- Validação final (28/10/2026): DOCX 274 KB com `word/media/image1-2.png`
  internos, 0 links externos, PDF de teste com 16 páginas, figuras nas páginas
  7 e 8 com legendas na mesma página, 0 marcadores "Figura N — pendente".

Verificar antes: `soffice --version` (validado com LibreOffice 25.2.3.2).

### Pós-processamento obrigatório: rodapé com página

O import HTML→DOCX do LibreOffice não cria rodapé. Após a conversão, injetar
`word/footer1.xml` (texto + campo `PAGE`), registrar em
`word/_rels/document.xml.rels` (`rIdFtr1`), em `[Content_Types].xml`
(`footer+xml`) e inserir `<w:footerReference w:type="default" r:id="rIdFtr1"/>`
no `<w:sectPr>` (com `w:footer="567"` no `pgMar`). O script usado está no
histórico da sessão de documentação; estrutura validada do campo:

```xml
<w:r><w:fldChar w:fldCharType="begin"/></w:r>
<w:r><w:instrText xml:space="preserve">PAGE</w:instrText></w:r>
<w:r><w:fldChar w:fldCharType="end"/></w:r>
```

**Não** usar a forma com `separate` + valor em cache + espaços em `instrText`
(`" PAGE "`): o LibreOffice renderiza um "X" residual após o número.

## 2. Mapeamento template → HTML/Markdown

| Elemento BIBLIOTECA | Estilo no template | HTML/Markdown |
|---------------------|--------------------|---------------|
| Título da capa | Verdana/Times 20–16pt centralizado | `p.cover-title` (Verdana 20pt bold) + `cover-sub`, `cover-authors`, `cover-seal`, `cover-place` |
| `Ttulo1` (heading 1) | Arial bold 16pt, numerado `%1.` | `<h1>` — numeração explícita no texto (`1.`, `2.`…) |
| `Ttulo2` (heading 2) | Arial bold 14pt, numerado `%1.%2` | `<h2>` — numeração explícita (`3.1`, `4.2`…) |
| `Ttulo3` (heading 3) | Arial bold 14pt | `<h3>` (`4.3.1`…) |
| `Ttulo4` (heading 4) | Palatino Linotype bold 12pt, sem numeração | `<h4>` ("Requisitos:", "Passo a passo:") |
| `Ttulo5` (heading 5) | Courier New bold | `<h5>` (passos `(1.)`, comandos) |
| `Corpodetexto` (Body Text) | corpo do template | `<p>` — Georgia 12pt justificado |
| `PargrafodaLista` (List Paragraph) | recuo de lista | `<ul><li>` — Georgia 12pt |
| `Sumrio1/2` (toc 1/2) | 12pt | `p.toc1` / `p.toc2` (recuo 24pt) |
| Tabelas | o BIBLIOTECA original não usa tabela | `<table>` sóbria: bordas finas 0,75pt `#666`, cabeçalho negrito com fundo `#EFEFEF`, larguras explícitas em `%` nos `<th>` |
| Figuras | legenda "Figura N. descrição" centralizada | `p.cap` (centralizado, itálico 11pt) + bloco `<pre>` (árvore/DER) ou captura |
| Rodapé | "N — Documentação Técnica …" com PAGE | injetado no DOCX (ver seção 1) |

Comentários de estilo no HTML (rastreabilidade), ex.:
`<!-- estilo: Ttulo1 | fonte: Arial 16pt bold -->`.

## 3. Fontes e tamanhos (resumo)

- Capa: Verdana 20pt bold (título), 14pt (subtítulo), Georgia 12pt (autores/selo/local/data).
- H1: Arial 16pt bold · H2/H3: Arial 14pt bold · H4: Palatino Linotype 12pt bold · H5: Courier New 11pt bold.
- Corpo e listas: Georgia 12pt · Código/`pre`: Courier New 10pt · Tabelas: Georgia 10,5pt · Legendas: Georgia 11pt itálico · Rodapé: 10pt.

## 4. Quebras de página e numeração

- Quebra de página: **estilo inline** `style="page-break-before: always"` no
  `<h1>`/`<h2>` que abre a página. **Não usar classe CSS** (`.pb`): o import do
  LibreOffice mescla o nome da classe ao estilo (`Ttulo1pb`) e o título perde a
  formatação, além de a quebra não ser aplicada.
- Numeração multilevel do BIBLIOTECA é automática no Word; no HTML usar
  numeração explícita nos textos dos títulos (`1.`, `3.1`, `4.3.2`).
- "Indice" é `Ttulo1` **sem** número.

## 5. Como inserir figuras

- Legenda no padrão: `Figura N. descrição` (centralizada, itálico) — `p.cap`.
- Árvores de diretórios e DER: bloco `<pre>` (Courier New) após a legenda
  (Figuras 1 e 2 do Sprint 2).
- Capturas de tela: inserir imagem de `imagens/` ou `assets/images/` quando
  disponível; sem device/emulador, usar o marcador
  `[Figura N — captura de tela pendente: descrição]` como legenda
  (Figuras 3–8 do Sprint 2, pendentes).
- Validar no PDF de teste (`soffice --convert-to pdf`) se a figura/legenda não
  quebrou entre páginas.
- **Numeração contínua entre versões do RT:** capítulos novos continuam a numeração
  da versão anterior (ex.: RT v2 da Sprint 3 usa Figuras 9–13, continuando as
  Figuras 1–8 da Sprint 2). Sem screenshot, a legenda cita o artefato de referência
  (ex.: o protótipo HTML) e marca "captura pendente".

## 6. O que NÃO mudar

- **Paleta do app** (`0xFF0D1E16`, `0xFF165A41`, `0xFFB89775`, `0xFF142A20`,
  `0xFF7A8B83`) — citada na documentação, nunca alterada no código.
- **Logo camaleão** (`assets/images/logo.png`) — intocável.
- **Segredos**: `.env`, `google-services.json`, keystores — nunca citar valores
  no documento; apenas referenciar os arquivos.
- **Estilos do template BIBLIOTECA** (fontes/tamanhos da seção 3) — não trocar
  fontes nem tamanhos dos títulos.
- **Microcopy real do app** — citar exatamente como no código (ex.: "Usar esta
  oferta no ticket?", "Nada foi alterado no ticket.", "Limite de 15 ofertas por
  insumo."); não parafrasear textos de tela.

## 7. Estrutura das seções (padrão do relatório)

1. Capa (título, subtítulo/escopo, autores, selo "RELATÓRIOS TÉCNICOS DO
   CASHCTRL", local/data) — sem numeração.
2. "Indice" (Ttulo1 sem número) + entradas `toc1`/`toc2`.
3. `1. Introdução` — 2 parágrafos curtos (o que o relatório apresenta; objetivo).
4. `2. Visão Geral` — descrição do software + contexto do sprint/versão.
5. `3. Requisitos` — 3.1 não-funcionais, 3.2 funcionais (lista).
6. `4. Projeto Lógico e Implementação` — SoC, estrutura de diretórios (Figura 1),
   descrição por pasta/arquivo (`arquivo: descrição`), modelo de dados, logs,
   DER (Figura 2), esquema do banco.
7. `5. Instalação` — "Requisitos:" e "Passo a passo:" em Ttulo4/Ttulo5, comandos
   em Courier New; destacar deploy de `firestore.rules` ANTES do app.
8. `6. Manual do usuário` — subtítulos por tela com Figuras (capturas).
9. `7. Considerações Finais` — resumo, critérios de aceite, testes, próximos passos.

## 8. Regras de escrita

- PT-BR, tom técnico de relatório.
- Não inventar funcionalidade: todo nome de arquivo/classe/texto deve existir no
  código (conferir antes de escrever).
- Desvios entre plano e código final devem ser registrados explicitamente
  (ex.: `offer_logic.dart` → `offer_comparator.dart`; evento
  `offer.defaultRecalculated` não implementado).
- Ambiente: `flutter analyze` crasha com caminho "(Cópia)" — usar
  `dart analyze .` e registrar a observação na seção de instalação.
