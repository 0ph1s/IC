#!/usr/bin/env python3
"""O3 contra mutantes: aplica, um de cada vez, os mutantes de DESTINO que o compilador aceita (aresta dentro
da topologia) à ação da aviônica em Crem.hs, exporta os traços da implementação mutada e pede ao TLC que os
valide contra AvionicsLoop.tla (04_tla/run_trace_validation.sh). Um mutante é 'morto pelo O3' se algum traço da
implementação (de aresta ou aleatório) for RECUSADO. Opcionalmente (SCXML_DIR definido), o SCION valida os mesmos
traços e a lista de traços aceitos é comparada com a do TLC.

TRABALHA NUMA CÓPIA de 03_codigo e 04_tla (como mutation_dest48.sh): os arquivos do projeto nunca são tocados.
Uso (de qualquer pasta):   python 03_codigo/validation/scripts/o3_mutants.py [id ...]
Variáveis: TMPDIR (pasta de trabalho; em Windows, uma de caminho curto, por exemplo C:/mv), SCXML_DIR (opcional).
Requisitos: GHC/cabal, Java, 04_tla/tools/tla2tools.jar, Python 3 (e Node com scxml 4.3.1, se SCXML_DIR).
Escreve 08_reprodutibilidade/logs/18_o3_contra_mutantes.md.
Demora: a primeira compilação da cópia refaz tudo (minutos); depois cerca de 2 a 3 minutos por mutante.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

SCRIPT = os.path.abspath(__file__)
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(SCRIPT))))   # Revisao_v5/
TMP = os.environ.get("TMPDIR") or os.environ.get("TEMP") or tempfile.gettempdir()
WORK = os.path.join(TMP, "o3mut")
OUT_MD = os.path.join(ROOT, "08_reprodutibilidade", "logs", "18_o3_contra_mutantes.md")


def ignore(_dir, names):
    return [n for n in names if n in ("dist-newstyle", "states", "states_trace", "states_f", "states_cmp", "saida_traces", "logs_fairness")]


if os.path.isdir(WORK):
    shutil.rmtree(WORK)
os.makedirs(WORK)
CODE = os.path.join(WORK, "03_codigo")
TLA = os.path.join(WORK, "04_tla")
shutil.copytree(os.path.join(ROOT, "03_codigo"), CODE, ignore=ignore)
shutil.copytree(os.path.join(ROOT, "04_tla"), TLA, ignore=lambda d, n: [x for x in n if x.startswith("states") or x in ("saida_traces", "logs_fairness")])
CREM = os.path.join(CODE, "base", "avionics-crem", "src", "Avionics", "Crem.hs")
BUILD = os.path.join(WORK, "d")
VERTS = ["Grounded", "InFlight", "EmergencyLanding", "Shutdown"]
ALLOWED = {("Grounded", "Grounded"), ("Grounded", "InFlight"), ("Grounded", "Shutdown"),
           ("InFlight", "InFlight"), ("InFlight", "EmergencyLanding"),
           ("EmergencyLanding", "EmergencyLanding"), ("EmergencyLanding", "Grounded"),
           ("Shutdown", "Shutdown")}

original = open(CREM, encoding="utf8", newline="").read()
eq = re.compile(r"^avionicsAction S(\w+) (\w+)\s*= pureResult \w+ S(\w+)\s*$")
mutants = []
n = 0
for line in original.splitlines():
    m = eq.match(line.rstrip("\r"))
    if not m:
        continue
    st, ev, dest = m.groups()
    for v in VERTS:
        if v == dest:
            continue
        n += 1
        mutants.append((f"D{n:02d}", st, ev, dest, v, (st, v) in ALLOWED))
if n != 48:
    sys.exit(f"ERRO: esperados 48 mutantes de destino, gerados {n} (o formato de Crem.hs mudou?)")
want = sys.argv[1:]
env = dict(os.environ, LANG="C.UTF-8", BUILDDIR=BUILD)
use_scion = bool(os.environ.get("SCXML_DIR")) and os.path.isdir(os.path.join(os.environ.get("SCXML_DIR", ""), "node_modules", "scxml"))
rows = []
for (mid, st, ev, dest, v, inside) in mutants:
    if not inside or (want and mid not in want):
        continue
    new_lines = []
    for line in original.splitlines(keepends=True):
        if line.startswith(f"avionicsAction S{st} {ev} ") and line.rstrip("\r\n").endswith(f"S{dest}"):
            body = line.rstrip("\r\n")
            eol = line[len(body):]
            line = body[: -len(dest)] + v + eol
        new_lines.append(line)
    mutated = "".join(new_lines)
    assert mutated != original
    open(CREM, "w", encoding="utf8", newline="").write(mutated)
    out = os.path.join(WORK, "out_" + mid)
    r = subprocess.run(["bash", "run_trace_validation.sh", out.replace("\\", "/"), CODE.replace("\\", "/")],
                       cwd=TLA, env=env, capture_output=True, text=True, encoding="utf8", errors="replace")
    text = r.stdout + r.stderr
    acc = {}
    for mm in re.finditer(r"^(aresta|aleatorio30|corrompido)\s+traços:\s+(\d+)\s+aceitos:\s+(\d+)", text, re.M):
        acc[mm.group(1)] = (int(mm.group(2)), int(mm.group(3)))
    scion = ""
    sc_acc, sc_killed = {}, None
    if acc and use_scion:
        e2 = dict(env, ACCEPT_LIST=os.path.join(out, "aceitos_scion.txt"))
        r2 = subprocess.run(["node", "--no-deprecation", os.path.join(ROOT, "04_tla", "scion", "scion_oracle.js"),
                             os.path.join(TLA, "TraceData.tla"), os.path.join(out, "tracos.csv")],
                            env=e2, capture_output=True, text=True, encoding="utf8", errors="replace")
        a = open(os.path.join(out, "aceitos_tlc.txt"), encoding="utf8").read().replace("\r", "")
        b = open(os.path.join(out, "aceitos_scion.txt"), encoding="utf8").read().replace("\r", "")
        scion = "sim" if a == b else "**NÃO**"
        # o SCION tambem tem veredito proprio: recusar algum traco de aresta ou aleatorio da implementacao mutada mata o mutante
        for mm in re.finditer(r"^(aresta|aleatorio30|corrompido)\s+traços:\s+(\d+)\s+aceitos:\s+(\d+)", r2.stdout, re.M):
            sc_acc[mm.group(1)] = (int(mm.group(2)), int(mm.group(3)))
        if "aresta" in sc_acc and "aleatorio30" in sc_acc:
            sc_killed = sc_acc["aresta"][1] < sc_acc["aresta"][0] or sc_acc["aleatorio30"][1] < sc_acc["aleatorio30"][0]
        else:
            scion = scion + " (SCION sem resultado: " + " ".join((r2.stdout + r2.stderr).split())[:120] + ")"
    if not acc:
        status, killed = "sem resultado: " + " ".join(text.split())[:160], None
    else:
        killed = acc["aresta"][1] < acc["aresta"][0] or acc["aleatorio30"][1] < acc["aleatorio30"][0]
        status = ""
    rows.append((mid, f"{st} + {ev}: {dest} -> {v}", acc, killed, status, scion, sc_acc, sc_killed))
    print(mid, st, ev, dest, "->", v, acc, "morto pelo O3" if killed else ("VIVO" if killed is False else status), scion, sc_acc,
          "morto pelo SCION" if sc_killed else ("VIVO no SCION" if sc_killed is False else "SCION n/a"), flush=True)
    open(CREM, "w", encoding="utf8", newline="").write(original)

os.makedirs(os.path.dirname(OUT_MD), exist_ok=True)
with open(OUT_MD, "w", encoding="utf8") as f:
    f.write("# O3 (validação de traços no TLC) contra os mutantes de destino aceitos pelo compilador\n\n")
    f.write("| Id | Defeito | TLC: aresta aceitos | TLC: aleatórios aceitos | TLC: corrompidos aceitos | Resultado O3 | SCION: aresta aceitos | SCION: aleatórios aceitos | Resultado O2 (SCION) | SCION aceita o mesmo conjunto que o TLC |\n|---|---|---|---|---|---|---|---|---|---|\n")
    for mid, d, acc, killed, status, scion, sc_acc, sc_killed in rows:
        a = acc.get("aresta", (0, 0)); b = acc.get("aleatorio30", (0, 0)); c = acc.get("corrompido", (0, 0))
        sa = sc_acc.get("aresta"); sb = sc_acc.get("aleatorio30")
        res = "**morto pelo O3**" if killed else ("**VIVO**" if killed is False else status)
        res2 = "**morto pelo SCION**" if sc_killed else ("**VIVO**" if sc_killed is False else "n/a")
        f.write(f"| {mid} | {d} | {a[1]}/{a[0]} | {b[1]}/{b[0]} | {c[1]}/{c[0]} | {res} | {f'{sa[1]}/{sa[0]}' if sa else 'n/a'} | {f'{sb[1]}/{sb[0]}' if sb else 'n/a'} | {res2} | {scion or 'n/a'} |\n")
    f.write(f"\nMutantes avaliados: {len(rows)}; mortos pelo O3: {sum(1 for r in rows if r[3])}; vivos no O3: {sum(1 for r in rows if r[3] is False)}.\n")
    if use_scion:
        f.write(f"SCION: mortos {sum(1 for r in rows if r[7])}; vivos {sum(1 for r in rows if r[7] is False)}; conjuntos de traços aceitos idênticos aos do TLC em {sum(1 for r in rows if r[5].startswith('sim'))} de {len(rows)}.\n")
    f.write("\nOs traços de aresta de um mutante são os da exploração da própria implementação mutada, por isso o total varia de um mutante para outro.\n")
shutil.rmtree(WORK, ignore_errors=True) if os.environ.get("KEEP") != "1" else None
sys.exit(0 if rows and all(r[3] for r in rows) and (not use_scion or all(r[7] for r in rows)) else 1)
