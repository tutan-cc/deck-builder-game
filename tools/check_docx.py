"""检查生成的 docx：段落/表格/图片数量与开头内容。"""

from pathlib import Path

from docx import Document

DOCX = Path(r"D:\deepseek工作区\deck-builder-game\docs\分集详解-P1-P19.docx")

doc = Document(str(DOCX))
paras = doc.paragraphs
tables = doc.tables
images = doc.inline_shapes

print(f"paragraphs: {len(paras)}")
print(f"tables:     {len(tables)}")
print(f"images:     {len(images)}")

headings = [p.text for p in paras if p.style.name.startswith("Heading")]
print(f"headings:   {len(headings)}")
print("前 8 个标题:")
for h in headings[:8]:
    print("  -", h)

empty = sum(1 for p in paras if not p.text.strip() and p.style.name == "Normal")
print(f"空段落:     {empty}")

# 表格里有没有图（图片单元格）
img_cells = 0
for t in tables:
    for row in t.rows:
        for cell in row.cells:
            if cell.paragraphs and cell.paragraphs[0].runs and cell.paragraphs[0].runs[0]._element.findall(
                "{http://schemas.openxmlformats.org/drawingml/2006/main}blip"
            ):
                img_cells += 1
print(f"（近似）表格内图片单元格: {img_cells}")
