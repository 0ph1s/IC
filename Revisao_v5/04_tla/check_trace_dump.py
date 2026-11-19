#!/usr/bin/env python3
"""Lê o -dump do TLC (TraceCheck.tla) e diz, para cada traço, se foi ACEITO: o estado final do traço
(t = número de ticks, k = número de passos do último tick, fila vazia) foi alcançado.

Uso: python check_trace_dump.py <dump> <TraceData.tla> <tracos.csv>
Código de saída 0 se: todos os traços de aresta e aleatórios foram aceitos e todos os corrompidos recusados.
"""
import collections
import csv
import re
import sys

dump, data, csvp = sys.argv[1:4]

# --- comprimento de cada traço (ticks e passos do último tick), lido do próprio TraceData.tla
txt = open(data, encoding="utf8").read()
body = txt[txt.index("Traces == <<") + len("Traces == <<"):txt.rindex(">>\n====")]
tick_re = re.compile(r"<<(\d+),(\d+), <<([\d,]*)>>>>")
traces = [m.group(1) for m in re.finditer(r"<< (<<\d+,\d+, <<[\d,]*>>>>(?:,\s*<<\d+,\d+, <<[\d,]*>>>>)*) >>", body)]
rows = list(csv.DictReader(open(csvp, encoding="utf8")))
assert len(traces) == len(rows), (len(traces), len(rows))
info = []
for tr in traces:
    ticks = tick_re.findall(tr)
    nsteps = [len([x for x in t[2].split(",") if x != ""]) for t in ticks]
    info.append((len(ticks), nsteps[-1]))

# --- estados do dump (campos de uma linha; a fila pode ocupar várias linhas, por isso só se testa "vazia")
final_ok = set()
cur = {}


def close(c):
    if c and "id" in c:
        i = int(c["id"]) - 1
        nt, nlast = info[i]
        if int(c["t"]) == nt and int(c["k"]) == nlast and c["queue"].replace(" ", "") == "<<>>":
            final_ok.add(i + 1)


field = re.compile(r"^/\\ (\w+) = (.*)$")
for line in open(dump, encoding="utf8"):
    line = line.rstrip("\r\n")
    if line.startswith("State "):
        close(cur)
        cur = {}
        continue
    m = field.match(line)
    if m:
        cur[m.group(1)] = m.group(2)
close(cur)

if len(sys.argv) > 4:   # lista opcional dos traços aceitos (um nome por linha), para comparar oráculos
    with open(sys.argv[4], "w", encoding="utf8") as f:
        f.write(chr(10).join(r["nome"] for r in rows if int(r["indice"]) in final_ok) + chr(10))

by = collections.defaultdict(lambda: [0, 0])
for r in rows:
    k = int(r["indice"])
    by[r["tipo"]][0] += 1
    by[r["tipo"]][1] += k in final_ok
for tipo, (n, a) in by.items():
    print(f"{tipo:12s} traços: {n:4d}  aceitos: {a:4d}  recusados: {n - a:4d}")
ok = (by["aresta"][0] == by["aresta"][1] and by["aleatorio30"][0] == by["aleatorio30"][1]
      and by["corrompido"][1] == 0)
print("ESPERADO (todos os traços da implementação aceitos; todos os corrompidos recusados):",
      "CONFERE" if ok else "NAO CONFERE")
if not ok:
    div = [r["nome"] for r in rows if (r["tipo"] != "corrompido") != (int(r["indice"]) in final_ok)]
    print("traços divergentes (primeiros 20):", div[:20])
sys.exit(0 if ok else 1)
