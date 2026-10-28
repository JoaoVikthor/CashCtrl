#!/usr/bin/env python3
"""Embute as imagens linkadas no DOCX e normaliza a largura das figuras.

O import HTML->DOCX do LibreOffice (modo Writer/Web) deixa as imagens como
links externos (TargetMode="External" + <a:blip r:link>) e aplica o tamanho
natural a 96 dpi, que estoura a largura util da pagina. Este script:
  1. copia os PNGs referenciados para word/media/ e converte os
     relationships para alvos internos;
  2. troca <a:blip r:link="rIdN"> por <a:blip r:embed="rIdN">;
  3. normaliza wp:extent/a:ext para a largura informada (padrao 17 cm),
     mantendo a proporcao de cada figura;
  4. garante o Default png em [Content_Types].xml.

Uso: python3 embutir_figuras.py <caminho-do-docx> <pasta-das-imagens> [largura_cm]
"""
import re
import sys
import zipfile
from pathlib import Path
from urllib.parse import unquote, urlparse

EMU_POR_CM = 360000


def main():
    docx_path = Path(sys.argv[1])
    img_dir = Path(sys.argv[2])
    largura_cm = float(sys.argv[3]) if len(sys.argv) > 3 else 17.0
    largura_emu = round(largura_cm * EMU_POR_CM)

    with zipfile.ZipFile(docx_path) as zin:
        entries = {i.filename: zin.read(i.filename) for i in zin.infolist()}

    rels = entries["word/_rels/document.xml.rels"].decode("utf-8")
    doc = entries["word/document.xml"].decode("utf-8")

    externas = re.findall(
        r'<Relationship [^>]*Type="[^"]*relationships/image"[^>]*/>', rels)
    if not externas:
        raise SystemExit("ERRO: nenhuma imagem em relationship encontrada")

    n_embutidas = 0
    for n, rel in enumerate(externas, start=1):
        if 'TargetMode="External"' not in rel:
            continue
        m_target = re.search(r'Target="([^"]+)"', rel)
        m_id = re.search(r'Id="([^"]+)"', rel)
        rid, alvo = m_id.group(1), unquote(urlparse(m_target.group(1)).path)
        dados = (img_dir / Path(alvo).name).read_bytes()

        nome = f"media/image{n}.png"
        entries[f"word/{nome}"] = dados
        novo = (
            f'<Relationship Id="{rid}" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/'
            f'relationships/image" Target="{nome}"/>'
        )
        rels = rels.replace(rel, novo)
        doc = doc.replace(f'<a:blip r:link="{rid}"', f'<a:blip r:embed="{rid}"')
        n_embutidas += 1

    if n_embutidas == 0:
        raise SystemExit("ERRO: nenhuma imagem externa para embutir")

    def normaliza(m):
        cx, cy = int(m.group(1)), int(m.group(2))
        novo_cy = round(largura_emu * cy / cx)
        return m.group(0).replace(f'cx="{cx}"', f'cx="{largura_emu}"') \
                         .replace(f'cy="{cy}"', f'cy="{novo_cy}"')

    doc, n1 = re.subn(r'<wp:extent cx="(\d+)" cy="(\d+)"/>', normaliza, doc)
    doc, n2 = re.subn(r'<a:ext cx="(\d+)" cy="(\d+)"/>', normaliza, doc)

    ct = entries["[Content_Types].xml"].decode("utf-8")
    if 'Extension="png"' not in ct:
        ct = ct.replace(
            "</Types>",
            '<Default Extension="png" ContentType="image/png"/></Types>',
        )

    entries["word/_rels/document.xml.rels"] = rels.encode("utf-8")
    entries["word/document.xml"] = doc.encode("utf-8")
    entries["[Content_Types].xml"] = ct.encode("utf-8")

    with zipfile.ZipFile(docx_path, "w", zipfile.ZIP_DEFLATED) as zout:
        for nome, dados in entries.items():
            zout.writestr(nome, dados)

    print(f"OK: {n_embutidas} imagem(ns) embutida(s) em {docx_path} "
          f"(extents normalizados: {n1 + n2}; largura {largura_cm} cm = "
          f"{largura_emu} EMU)")


if __name__ == "__main__":
    main()
