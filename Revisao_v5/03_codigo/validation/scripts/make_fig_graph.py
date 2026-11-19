#!/usr/bin/env python3
"""T21 (plano v2): gera a figura dos 48 ternos possíveis, a partir de grafo_ternos.csv (exportado por
validation-export), com os 26 alcançáveis marcados pela profundidade (BFS) e os cegos destacados.

Uso: python make_fig_graph.py grafo_ternos.csv figures/fig_graph26.tex
Linhas: (aviônica, bateria), 12 combinações; colunas: vértice do ambiente (4).
Célula alcançável: profundidade da busca em largura. Cego no fim do tick (aviônica InFlight e bateria
Critical): sombreado; preso sob ticks ociosos: sombreado forte e em negrito. Não alcançável: vazio.
"""
import csv
import sys

src, dst = sys.argv[1:3]
rows = list(csv.DictReader(open(src, encoding="utf8")))
AV = ["Grounded", "InFlight", "EmergencyLanding", "Shutdown"]
PW = ["Charged", "Low", "Critical"]
MS = ["Standby", "CriticalHeld", "TouchdownHeld", "CutoffHeld"]
cell = {}
for r in rows:
    cell[(r["aviônica"], r["bateria"], r["ambiente"])] = r

W, H = 1.75, 0.46      # largura e altura de cada célula (cm)
X0 = 3.3               # largura da coluna de rótulos
out = []
out.append("% Gerado por make_fig_graph.py a partir de grafo_ternos.csv. Não editar à mão.")
out.append("\\begin{tikzpicture}[x=1cm,y=1cm,font=\\scriptsize]")
for j, m in enumerate(MS):
    out.append(f"\\node[anchor=south] at ({X0 + W * (j + 0.5):.2f},0.05) {{\\code{{{m}}}}};")
y = 0.0
for ia, a in enumerate(AV):
    for ip, p in enumerate(PW):
        y -= H
        label = f"\\code{{{a}}}, \\code{{{p}}}"
        out.append(f"\\node[anchor=east] at ({X0 - 0.1:.2f},{y + H / 2:.2f}) {{{label}}};")
        for j, m in enumerate(MS):
            r = cell.get((a, p, m))
            x = X0 + W * j
            if r is None:
                style = "draw=black!35, fill=black!4"
                text = ""
            else:
                trapped = r["preso_sob_ticks_ociosos"] == "sim"
                blind = r["cego_no_fim_do_tick"] == "sim"
                style = "draw=black!70, fill=black!40" if trapped else ("draw=black!70, fill=black!18" if blind else "draw=black!70")
                text = ("\\textbf{" + r["profundidade"] + "}") if trapped else r["profundidade"]
            out.append(f"\\draw[{style}] ({x:.2f},{y:.2f}) rectangle ({x + W:.2f},{y + H:.2f});")
            if text:
                out.append(f"\\node at ({x + W / 2:.2f},{y + H / 2:.2f}) {{{text}}};")
    out.append(f"\\draw[black!60] (0,{y:.2f}) -- ({X0 + 4 * W:.2f},{y:.2f});")
out.append("\\end{tikzpicture}")
open(dst, "w", encoding="utf8").write("\n".join(out) + "\n")
n_reach = sum(1 for r in rows)
print(f"{n_reach} ternos alcançáveis desenhados em {dst}")
