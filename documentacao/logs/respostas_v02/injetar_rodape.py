#!/usr/bin/env python3
"""Injeta rodapé com campo PAGE no DOCX gerado pelo LibreOffice.

Conforme documentacao/GUIA_FORMATACAO_DOCX.md (seção 1, pós-processamento
obrigatório): o import HTML->DOCX do LibreOffice nao cria rodape.

Uso: python3 injetar_rodape.py <caminho-do-docx> "<texto-do-rodape>"
"""
import re
import sys
import zipfile


def main():
    path = sys.argv[1]
    footer_text = sys.argv[2]

    with zipfile.ZipFile(path) as zin:
        entries = {i.filename: zin.read(i.filename) for i in zin.infolist()}

    # 1. document.xml: inserir footerReference logo apos a abertura do sectPr
    doc = entries["word/document.xml"].decode("utf-8")
    n_sect = len(re.findall(r"<w:sectPr[ >]", doc))
    doc, n = re.subn(
        r"(<w:sectPr[^>]*>)",
        r'\1<w:footerReference w:type="default" r:id="rIdFtr1"/>',
        doc,
        count=1,
    )
    if n != 1:
        raise SystemExit("ERRO: sectPr nao encontrado em word/document.xml")

    # 2. rels: registrar rIdFtr1 -> footer1.xml
    rels = entries["word/_rels/document.xml.rels"].decode("utf-8")
    if "rIdFtr1" in rels:
        raise SystemExit("ERRO: rIdFtr1 ja existe em document.xml.rels")
    rels = rels.replace(
        "</Relationships>",
        '<Relationship Id="rIdFtr1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/'
        'relationships/footer" Target="footer1.xml"/></Relationships>',
    )

    # 3. [Content_Types].xml: registrar o override footer+xml
    ct = entries["[Content_Types].xml"].decode("utf-8")
    if "footer+xml" in ct:
        raise SystemExit("ERRO: footer+xml ja declarado em [Content_Types].xml")
    ct = ct.replace(
        "</Types>",
        '<Override PartName="/word/footer1.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.'
        'wordprocessingml.footer+xml"/></Types>',
    )

    # 4. word/footer1.xml: centrado, campo PAGE + texto (sem "separate" nem
    #    espacos no instrText — o LibreOffice renderiza "X" residual)
    rpr = (
        '<w:rPr><w:rFonts w:ascii="Georgia" w:hAnsi="Georgia"/>'
        '<w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr>'
    )
    footer = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:p><w:pPr><w:jc w:val="center"/></w:pPr>'
        f"<w:r>{rpr}<w:fldChar w:fldCharType=\"begin\"/></w:r>"
        f'<w:r>{rpr}<w:instrText xml:space="preserve">PAGE</w:instrText></w:r>'
        f"<w:r>{rpr}<w:fldChar w:fldCharType=\"end\"/></w:r>"
        f'<w:r>{rpr}<w:t xml:space="preserve">{footer_text}</w:t></w:r>'
        "</w:p></w:ftr>"
    )

    entries["word/document.xml"] = doc.encode("utf-8")
    entries["word/_rels/document.xml.rels"] = rels.encode("utf-8")
    entries["[Content_Types].xml"] = ct.encode("utf-8")
    entries["word/footer1.xml"] = footer.encode("utf-8")

    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as zout:
        for name, data in entries.items():
            zout.writestr(name, data)

    print(f"OK: rodape injetado em {path} (sectPr encontrados: {n_sect})")


if __name__ == "__main__":
    main()
