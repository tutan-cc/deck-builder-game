"""把 docs/分集详解-P1-P19.md 转成带图片的 Word 文档。

支持的 Markdown 子集：H1/H2/H3、代码块、表格（含表格里的图片）、
行内图片、引用、列表、行内 `代码` / **加粗** / 链接。
"""

import re
import sys
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

MD = Path(r"D:\deepseek工作区\deck-builder-game\docs\分集详解-P1-P19.md")
OUT = Path(r"D:\deepseek工作区\deck-builder-game\docs\分集详解-P1-P19.docx")
BASE = MD.parent

CJK_FONT = "Microsoft YaHei"
MONO_FONT = "Consolas"
BODY_SIZE = Pt(10.5)
CODE_SIZE = Pt(8.5)


def set_run_font(run, name=CJK_FONT, size=BODY_SIZE, bold=None, color=None):
    run.font.name = name
    run.font.size = size
    if bold is not None:
        run.font.bold = bold
    if color is not None:
        run.font.color.rgb = color
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:eastAsia"), name)
    rfonts.set(qn("w:ascii"), name)
    rfonts.set(qn("w:hAnsi"), name)


def shade(paragraph, fill="F2F2F2"):
    ppr = paragraph._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    ppr.append(shd)


INLINE = re.compile(r"(\*\*.+?\*\*|`[^`]+`|\[[^\]]+\]\([^)]+\))")


def add_inline(paragraph, text, size=BODY_SIZE, color=None):
    for piece in INLINE.split(text):
        if not piece:
            continue
        if piece.startswith("**") and piece.endswith("**") and len(piece) > 4:
            run = paragraph.add_run(piece[2:-2])
            set_run_font(run, size=size, bold=True, color=color)
        elif piece.startswith("`") and piece.endswith("`") and len(piece) > 2:
            run = paragraph.add_run(piece[1:-1])
            set_run_font(run, name=MONO_FONT, size=Pt(size.pt - 1), color=RGBColor(0xA8, 0x2A, 0x2A))
        elif piece.startswith("[") and "](" in piece:
            label = piece[1:piece.index("](")]
            run = paragraph.add_run(label)
            set_run_font(run, size=size, color=RGBColor(0x1F, 0x4E, 0x9A))
        else:
            run = paragraph.add_run(piece)
            set_run_font(run, size=size, color=color)


IMG_LINE = re.compile(r"^!\[([^\]]*)\]\(([^)]+)\)$")


def add_image(paragraph, rel_path, width_in):
    path = (BASE / rel_path).resolve()
    if not path.exists():
        run = paragraph.add_run(f"[缺图 {rel_path}]")
        set_run_font(run, size=BODY_SIZE, color=RGBColor(0xCC, 0x00, 0x00))
        return
    run = paragraph.add_run()
    run.add_picture(str(path), width=Inches(width_in))


def convert():
    lines = MD.read_text(encoding="utf-8").splitlines()
    doc = Document()

    section = doc.sections[0]
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    section.left_margin = Inches(0.9)
    section.right_margin = Inches(0.9)
    section.top_margin = Inches(0.8)
    section.bottom_margin = Inches(0.8)

    usable = 8.27 - 1.8

    style = doc.styles["Normal"]
    style.font.name = CJK_FONT
    style.font.size = BODY_SIZE
    style.element.rPr.rFonts.set(qn("w:eastAsia"), CJK_FONT)

    i = 0
    while i < len(lines):
        line = lines[i].rstrip()

        # 代码块
        if line.startswith("```"):
            i += 1
            block = []
            while i < len(lines) and not lines[i].startswith("```"):
                block.append(lines[i])
                i += 1
            i += 1
            for code_line in block:
                p = doc.add_paragraph()
                p.paragraph_format.space_after = Pt(0)
                p.paragraph_format.space_before = Pt(0)
                p.paragraph_format.left_indent = Inches(0.15)
                shade(p)
                run = p.add_run(code_line if code_line else " ")
                set_run_font(run, name=MONO_FONT, size=CODE_SIZE)
            doc.add_paragraph().paragraph_format.space_after = Pt(4)
            continue

        # 表格
        if line.startswith("|") and i + 1 < len(lines) and set(lines[i + 1].replace("|", "").strip()) <= set("-: "):
            header = [c.strip() for c in line.strip().strip("|").split("|")]
            i += 2
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append([c.strip() for c in lines[i].strip().strip("|").split("|")])
                i += 1
            cols = len(header)
            has_header_text = any(c and c not in ("---", "") for c in header)
            first_row = [header] + rows if has_header_text else rows
            table = doc.add_table(rows=len(first_row), cols=cols)
            table.style = "Table Grid"
            table.alignment = WD_TABLE_ALIGNMENT.CENTER
            for r, row in enumerate(first_row):
                for c in range(cols):
                    cell = table.cell(r, c)
                    cell.text = ""
                    para = cell.paragraphs[0]
                    value = row[c] if c < len(row) else ""
                    m = IMG_LINE.match(value)
                    if m:
                        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
                        add_image(para, m.group(2), min(usable / cols - 0.15, 3.0))
                    else:
                        add_inline(para, value, size=Pt(9))
                        if has_header_text and r == 0:
                            for run in para.runs:
                                run.font.bold = True
            doc.add_paragraph().paragraph_format.space_after = Pt(2)
            continue

        # 标题
        if line.startswith("# "):
            p = doc.add_heading(level=1)
            set_run_font(p.add_run(line[2:].strip()), size=Pt(20), bold=True, color=RGBColor(0x1A, 0x1A, 0x1A))
            i += 1
            continue
        if line.startswith("## "):
            p = doc.add_heading(level=2)
            set_run_font(p.add_run(line[3:].strip()), size=Pt(14), bold=True, color=RGBColor(0x22, 0x22, 0x22))
            i += 1
            continue
        if line.startswith("### "):
            p = doc.add_heading(level=3)
            set_run_font(p.add_run(line[4:].strip()), size=Pt(12), bold=True, color=RGBColor(0x33, 0x33, 0x33))
            i += 1
            continue

        # 分隔线
        if line.strip() == "---":
            i += 1
            continue

        # 独立图片
        m = IMG_LINE.match(line.strip())
        if m:
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            add_image(p, m.group(2), usable)
            i += 1
            continue

        # 引用
        if line.startswith(">"):
            text = line.lstrip("> ").strip()
            if text:
                p = doc.add_paragraph()
                p.paragraph_format.left_indent = Inches(0.25)
                add_inline(p, text, size=Pt(9.5), color=RGBColor(0x44, 0x44, 0x44))
                for run in p.runs:
                    run.font.italic = True
            i += 1
            continue

        # 列表
        if re.match(r"^[-*] ", line):
            p = doc.add_paragraph(style="List Bullet")
            add_inline(p, line[2:].strip())
            i += 1
            continue
        if re.match(r"^\d+\. ", line):
            p = doc.add_paragraph(style="List Number")
            add_inline(p, re.sub(r"^\d+\. ", "", line).strip())
            i += 1
            continue

        # 空行
        if not line.strip():
            i += 1
            continue

        # 普通段落
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(4)
        add_inline(p, line.strip())
        i += 1

    doc.save(OUT)
    print(f"saved: {OUT}")


if __name__ == "__main__":
    convert()
