#!/usr/bin/env python3
"""T27(b): o que acontece com (SD) quando a decisao depende de um parametro e de um temporizador?

(SD), no nosso trabalho, diz que a saida de um passo e funcao do estado abstrato (o terno de vertices) e da entrada.
Aqui o "sistema" e o failsafe REAL do PX4, com COM_FAIL_ACT_T = T s. Entradas: o nivel de bateria (0, 1 ou 2) a cada
segundo, armado, modo AUTO_MISSION, COM_LOW_BAT_ACT = 3. Enumera TODAS as palavras de comprimento N sobre {0,1,2}
e mede, para varias abstracoes do estado:

  alfa     = (acao selecionada, takeover)                          o que um observador externo ve
  alfa'    = alfa + o ultimo nivel de bateria recebido             analogo ao terno de vertices (estado + nivel de energia)
  beta     = alfa + atrasos + lista de acoes ativas + resto do estado privado   o estado interno que o harness consegue ler
  (verifica-se se beta basta: se a saida e o proximo beta sao funcao de (beta, entrada))

"Conflito" = o mesmo par (abstracao, entrada) levou a mais de um resultado. Conflito zero = (SD) vale para a abstracao.
Tambem conta as classes de comportamento futuro (equivalencia de Nerode limitada): duas historias de comprimento L estao
na mesma classe se todas as continuacoes de comprimento M dao a mesma sequencia de acoes.

Uso: python px4_sd.py <px4_failsafe> [saida.md] [N=10] [L=5] [Ts=0,1,2,3,5] [alfabeto=0,1,2]   (N = L + M)
"""
import os
import itertools
import subprocess
import sys

exe = sys.argv[1]
out_md = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None
N = int(sys.argv[3]) if len(sys.argv) > 3 else 10
L = int(sys.argv[4]) if len(sys.argv) > 4 else 5
M = N - L
TS = [float(x) for x in (sys.argv[5] if len(sys.argv) > 5 else "0,1,2,3,5").split(",")]
# simbolo = bateria, ou bateria:manche, ou bateria:manche:modo (modo pretendido; 3 = AUTO_MISSION, 4 = AUTO_LOITER),
# ou flags nomeadas ligadas por '+', por exemplo bat2+gnss1+mc1 (chaves do harness: bat stick mode gnss mc gcs gf wind ftl mf nav).
# Internamente, um simbolo e uma tupla de pares (chave, valor); toda chave nao citada fica desligada (0; modo 3).
def sym(tok):
    if tok[0].isalpha():
        kv = dict((p.rstrip("0123456789"), int(p[len(p.rstrip("0123456789")):])) for p in tok.split("+"))
        return tuple(sorted(kv.items()))
    f = [int(x) for x in tok.split(":")]
    f = f + [0, 3][len(f) - 1:]
    return (("bat", f[0]), ("mode", f[2]), ("stick", f[1]))


def sym_line(s):
    d = dict(s)
    d.setdefault("bat", 0); d.setdefault("stick", 0); d.setdefault("mode", 3)
    keys = ["bat", "stick", "mode", "gnss", "mc", "gcs", "gf", "wind", "ftl", "mf", "nav"]
    return " ".join("%s=%d" % (k, d.get(k, 0)) for k in keys)


def sym_name(s):
    d = dict(s)
    if set(d) <= {"bat", "stick", "mode"}:
        return "%d:%d:%d" % (d.get("bat", 0), d.get("stick", 0), d.get("mode", 3))
    return "+".join("%s%d" % kv for kv in s if kv[1])


ALPHA = tuple(sym(x) for x in (sys.argv[6] if len(sys.argv) > 6 else "0,1,2").split(","))
words = list(itertools.product(ALPHA, repeat=N))
conts = list(itertools.product(ALPHA, repeat=M))


def run(T):
    script = ["VERBOSE 1", "PARAM COM_LOW_BAT_ACT 3", "PARAM COM_FAIL_ACT_T %g" % T]
    script += ["PARAM %s %s" % tuple(p.split("=")) for p in os.environ.get("PX4_PARAMS", "").split(",") if p]   # parametros extras, ex.: NAV_RCL_ACT=2,COM_GNSSLOSS_ACT=2
    for w in words:
        script.append("NEW")
        t = 5000
        for s in w:
            script.append("STEP %d armed=1 %s" % (t, sym_line(s)))
            t += 1000
    res = subprocess.run([exe], input="\n".join(script) + "\n", capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit("px4_failsafe falhou: " + res.stderr)
    lines = res.stdout.split("\n")[:-1]
    assert len(lines) == len(words) * N, (len(lines), len(words) * N)
    return lines


rows = []
for T in TS:
    lines = run(T)
    alpha_t, alphap_t, beta_t = {}, {}, {}
    alphas, alphaps, betas = set(), set(), set()
    sig = {}
    for wi, w in enumerate(words):
        prev_a = prev_ap = prev_b = "INIT"
        seq = []
        for i, s in enumerate(w):
            f = lines[wi * N + i].split(" ")
            a = (f[1], f[2])
            ap = (a, s)
            b = (f[1], f[2], f[4], f[5], f[6], f[7])
            alphas.add(a); alphaps.add(ap); betas.add(b)
            alpha_t.setdefault((prev_a, s), set()).add(a)
            alphap_t.setdefault((prev_ap, s), set()).add(ap)
            beta_t.setdefault((prev_b, s), set()).add((a, b))
            prev_a, prev_ap, prev_b = a, ap, b
            seq.append(f[1])
        h, c = w[:L], w[L:]
        sig.setdefault(h, {})[c] = tuple(seq[L:])
    conflicts = lambda d: sum(1 for v in d.values() if len(v) > 1)
    classes = len({tuple(sig[h][c] for c in conts) for h in sig})
    rows.append((T, len(alphas), conflicts(alpha_t), len(alphaps), conflicts(alphap_t), len(betas), conflicts(beta_t), classes))
    print("T=%g s: alfa=%d (conflitos %d), alfa'=%d (conflitos %d), beta=%d (conflitos %d), classes futuras=%d"
          % rows[-1], flush=True)

md = ["PX4 (failsafe real), COM_LOW_BAT_ACT = 3%s, armado, entrada (bateria:manche:modo, ou flags nomeadas) em {%s} a cada segundo."
      % ((", " + os.environ["PX4_PARAMS"].replace(",", ", ")) if os.environ.get("PX4_PARAMS") else "", ",".join(sym_name(a) for a in ALPHA)),
      "Todas as %d palavras de comprimento %d; classes futuras: historias de comprimento %d, continuacoes de comprimento %d." % (len(words), N, L, M), "",
      "| COM_FAIL_ACT_T (s) | estados alfa | conflitos alfa | estados alfa' | conflitos alfa' | estados beta | conflitos beta | classes futuras |",
      "|---|---|---|---|---|---|---|---|"]
for r in rows:
    md.append("| %g | %d | %d | %d | %d | %d | %d | %d |" % r)
text = "\n".join(md)
print("\n" + text)
if out_md:
    open(out_md, "w", encoding="utf8", newline="\n").write(text + "\n")
# codigo de saida: 0 se beta nunca tem conflito (o estado interno lido basta); 1 se faltar estado
sys.exit(0 if all(r[6] == 0 for r in rows) else 1)
