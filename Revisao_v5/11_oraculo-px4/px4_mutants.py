#!/usr/bin/env python3
"""O4 (PX4) contra os mutantes de DESTINO que o compilador aceita (aresta dentro da topologia): 16 dos 48.
Para cada mutante, numa COPIA de 03_codigo (os arquivos do projeto nunca sao tocados): compila a implementacao
mutada, exporta os tracos dela (validation-export), passa os tracos pelo failsafe real do PX4 (px4_diff.py) e compara
com o resultado da implementacao SEM mutacao, na mesma copia.

Um mutante e "morto pelo PX4" se o resultado muda de uma destas formas:
  (a) aparece uma classe de divergencia que a implementacao original nao tem (px4_diff.py sai com codigo 1:
      classe inexplicada, "PX4 pousa; nossa (..) nao" etc.);  ou
  (b) as contagens das classes diferem das da implementacao original NOS TRACOS ALEATORIOS (500 de 30 ticks), que sao os
      mesmos cenarios de entrada para toda implementacao: a diferenca vem so da mutacao;
  (c) so os tracos de aresta mudam (evidencia mais fraca: eles seguem o grafo da implementacao mutada).
Uso: python px4_mutants.py <px4_failsafe> [id ...]     (ids D01..D48; sem ids: os 16 que o compilador aceita)
Variaveis: TMPDIR (pasta de trabalho; em Windows, caminho curto como C:/mv), COM_LOW_BAT_ACT (padrao 2).
Escreve logs/px4_contra_mutantes.md. Demora: a primeira compilacao refaz tudo (minutos), depois ~1 a 2 min por mutante.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

SCRIPT = os.path.abspath(__file__)
HERE = os.path.dirname(SCRIPT)
ROOT = os.path.dirname(HERE)                       # Revisao_v5/
EXE = os.path.abspath(sys.argv[1])
WANT = sys.argv[2:]
TMP = os.environ.get("TMPDIR") or os.environ.get("TEMP") or tempfile.gettempdir()
WORK = os.path.join(TMP, "px4mut")
OUT_MD = os.path.join(HERE, "logs", "px4_contra_mutantes.md")
ACT = os.environ.get("COM_LOW_BAT_ACT", "2")
VERTS = ["Grounded", "InFlight", "EmergencyLanding", "Shutdown"]
ALLOWED = {("Grounded", "Grounded"), ("Grounded", "InFlight"), ("Grounded", "Shutdown"),
           ("InFlight", "InFlight"), ("InFlight", "EmergencyLanding"),
           ("EmergencyLanding", "EmergencyLanding"), ("EmergencyLanding", "Grounded"),
           ("Shutdown", "Shutdown")}

if os.path.isdir(WORK):
    shutil.rmtree(WORK)
os.makedirs(WORK)
CODE = os.path.join(WORK, "03_codigo")
shutil.copytree(os.path.join(ROOT, "03_codigo"), CODE,
                ignore=lambda d, n: [x for x in n if x in ("dist-newstyle", "states", "saida_traces")])
CREM = os.path.join(CODE, "base", "avionics-crem", "src", "Avionics", "Crem.hs")
BUILD = os.path.join(WORK, "d")
original = open(CREM, encoding="utf8", newline="").read()
eq = re.compile(r"^avionicsAction S(\w+) (\w+)\s*= pureResult \w+ S(\w+)\s*$")
mutants, n = [], 0
for line in original.splitlines():
    m = eq.match(line.rstrip("\r"))
    if not m:
        continue
    st, ev, dest = m.groups()
    for v in VERTS:
        if v == dest:
            continue
        n += 1
        mutants.append(("D%02d" % n, st, ev, dest, v, (st, v) in ALLOWED))
if n != 48:
    sys.exit("ERRO: esperados 48 mutantes de destino, gerados %d (o formato de Crem.hs mudou?)" % n)
env = dict(os.environ, LANG="C.UTF-8")


def parse(stdout):
    tally = {}
    for mm in re.finditer(r"^\| (.+?) \| (\d+) \| \(.*\) \|$", stdout, re.M):
        tally[mm.group(1)] = int(mm.group(2))
    return tally


def export_and_diff(tag):
    out = os.path.join(WORK, "out_" + tag)
    r = subprocess.run(["cabal", "run", "--builddir=" + BUILD, "-v0", "avionics-validation:exe:validation-export", "--", out],
                       cwd=CODE, env=env, capture_output=True, text=True, encoding="utf8", errors="replace")
    if r.returncode != 0:
        return None, None, "falha na compilacao/exportacao: " + " ".join((r.stdout + r.stderr).split())[-200:]
    d = subprocess.run([sys.executable, os.path.join(HERE, "px4_diff.py"), EXE, os.path.join(out, "TraceData.tla"),
                        os.path.join(out, "tracos.csv"), ACT],
                       env=env, capture_output=True, text=True, encoding="utf8", errors="replace")
    tally = parse(d.stdout)
    if not tally:
        return None, None, "px4_diff sem resultado: " + " ".join((d.stdout + d.stderr).split())[-200:]
    d2 = subprocess.run([sys.executable, os.path.join(HERE, "px4_diff.py"), EXE, os.path.join(out, "TraceData.tla"),
                         os.path.join(out, "tracos.csv"), ACT, "", "1", "0", "100", "aleatorio30"],
                        env=env, capture_output=True, text=True, encoding="utf8", errors="replace")
    return (tally, parse(d2.stdout)), max(d.returncode, d2.returncode), ""


def short(cls):
    if cls.startswith("PX4 pousa; nossa ("):
        return cls
    for key in ("concordam", "cegueira", "trava", "so avisa", "INEXPLICADO"):
        if key in cls:
            return key
    return cls[:40]


def agg(t):
    out = {}
    for k, v in t.items():
        out[short(k)] = out.get(short(k), 0) + v
    return out


base2, bcode, err = export_and_diff("base")
if base2 is None:
    sys.exit("ERRO na linha de base: " + err)
base, baserand = agg(base2[0]), agg(base2[1])
print("linha de base:", base, "; so aleatorios:", baserand, flush=True)
rows = []
for (mid, st, ev, dest, v, inside) in mutants:
    if not inside or (WANT and mid not in WANT):
        continue
    new_lines = []
    for line in original.splitlines(keepends=True):
        if line.startswith("avionicsAction S%s %s " % (st, ev)) and line.rstrip("\r\n").endswith("S" + dest):
            body = line.rstrip("\r\n")
            line = body[: -len(dest)] + v + line[len(body):]
        new_lines.append(line)
    mutated = "".join(new_lines)
    assert mutated != original
    open(CREM, "w", encoding="utf8", newline="").write(mutated)
    tally, code, err = export_and_diff(mid)
    open(CREM, "w", encoding="utf8", newline="").write(original)
    if tally is None:
        rows.append((mid, "%s + %s: %s -> %s" % (st, ev, dest, v), None, err))
        print(mid, err, flush=True)
        continue
    allc, randc = agg(tally[0]), agg(tally[1])
    new_classes = sorted(k for k in set(allc) | set(randc) if k not in base)
    dr = {k: (baserand.get(k, 0), randc.get(k, 0)) for k in set(baserand) | set(randc) if baserand.get(k, 0) != randc.get(k, 0)}
    da = {k: (base.get(k, 0), allc.get(k, 0)) for k in set(base) | set(allc) if base.get(k, 0) != allc.get(k, 0)}
    if code != 0 or new_classes:
        verdict = "morto (classe nova)"
    elif dr:
        verdict = "morto (aleatorios diferem)"
    elif da:
        verdict = "morto so pelos tracos de aresta"
    else:
        verdict = "VIVO"
    rows.append((mid, "%s + %s: %s -> %s" % (st, ev, dest, v), (verdict, new_classes, dr), ""))
    print(mid, st, ev, dest, "->", v, verdict, new_classes, dr, flush=True)

os.makedirs(os.path.dirname(OUT_MD), exist_ok=True)
with open(OUT_MD, "w", encoding="utf8", newline="\n") as f:
    f.write("# O4 (PX4) contra os mutantes de destino aceitos pelo compilador\n\n")
    f.write("COM_LOW_BAT_ACT = %s. Linha de base (implementacao sem mutacao), todos os tracos: %s.\nSo os 500 aleatorios (mesmos cenarios para toda implementacao): %s.\n\n"
            % (ACT, ", ".join("%s %d" % (k, v) for k, v in base.items()), ", ".join("%s %d" % (k, v) for k, v in baserand.items())))
    f.write("| Id | Defeito | Resultado | Classes novas | Contagens que mudam nos aleatorios (base -> mutante) |\n|---|---|---|---|---|\n")
    for mid, d, res, err in rows:
        if res is None:
            f.write("| %s | %s | sem resultado: %s | | |\n" % (mid, d, err))
        else:
            verdict, newc, diffs = res
            f.write("| %s | %s | **%s** | %s | %s |\n" % (mid, d, verdict, ", ".join(newc) or "-",
                    "; ".join("%s %d -> %d" % (k, a, b) for k, (a, b) in sorted(diffs.items())) or "-"))
    ok = [r for r in rows if r[2] is not None]
    f.write("\nMutantes avaliados: %d; mortos por classe nova: %d; mortos por contagens nos aleatorios: %d; mortos so pelos tracos de aresta: %d; vivos: %d; sem resultado: %d.\n"
            % (len(rows), sum(1 for r in ok if r[2][0] == "morto (classe nova)"), sum(1 for r in ok if r[2][0] == "morto (aleatorios diferem)"),
               sum(1 for r in ok if r[2][0] == "morto so pelos tracos de aresta"), sum(1 for r in ok if r[2][0] == "VIVO"), len(rows) - len(ok)))
    f.write("\nOs tracos de aresta de um mutante sao os da exploracao da propria implementacao mutada; por isso as contagens variam de um mutante para outro.\n")
sys.exit(0 if rows and all(r[2] is not None and r[2][0] != "VIVO" for r in rows) else 1)
