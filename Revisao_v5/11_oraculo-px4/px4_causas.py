#!/usr/bin/env python3
"""Outras causas de failsafe no PX4 REAL (alem da bateria): composicao por severidade e "trava ou libera".

Nada disto tem correspondente nos nossos traços (a implementacao em CREM so conhece bateria e comandos): e uma medida do
que o PX4 faz, para orientar uma extensao do modelo. Tudo e medido rodando o failsafe, nao lido do codigo.

Parte 1 (trava ou libera). Para cada causa e cada valor do parametro que a configura: armado, AUTO_MISSION, a causa liga por
3 passos e desliga; registra-se a acao (a) com a causa ativa, (b) 1 s depois de a causa sumir, (c) depois de uma troca de modo,
(d) depois de desarmar e armar de novo. "Trava" = a acao continua depois que a condicao some (como a nossa EmergencyLanding
continua ate o LandedSignal).

Parte 2 (lei de severidade). O PX4 diz que, com varios failsafes ativos, vale o mais severo. Para muitas configuracoes de
parametros sorteadas (semente fixa) e TODOS os subconjuntos de 9 causas ligadas ao mesmo tempo, confere-se se a acao escolhida e o
maximo das acoes escolhidas por cada causa sozinha (ordem do enum Action do PX4).
Uso: python px4_causas.py <px4_failsafe> [saida.md] [configuracoes=300]
"""
import collections
import itertools
import random
import subprocess
import sys

exe = sys.argv[1]
out_md = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None
NCFG = int(sys.argv[3]) if len(sys.argv) > 3 else 300
ACT = {0: "None", 1: "Warn", 2: "FbPos", 3: "FbAlt", 4: "FbStab", 5: "Hold", 6: "RTL", 7: "Land", 8: "Descend", 9: "Disarm", 10: "Term"}
MISSION, LOITER = 3, 4


def run(script):
    r = subprocess.run([exe], input="\n".join(script) + "\n", capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("px4_failsafe falhou: " + r.stderr)
    return [l.split() for l in r.stdout.split("\n")[:-1]]


# causa -> (flag, parametro que a configura (ou None), valores do parametro, valor da flag)
CAUSES = [
    ("perda de manual/RC", "mc", "NAV_RCL_ACT", [0, 1, 2, 3, 5, 6, 7], 1),
    ("perda do GCS", "gcs", "NAV_DLL_ACT", [0, 1, 2, 3, 5, 6, 7], 1),
    ("perda de GNSS", "gnss", "COM_GNSSLOSS_ACT", [0, 1, 2, 3, 4], 1),
    ("geofence", "gf", "GF_ACTION", [0, 1, 2, 3, 4, 5], 1),
    ("vento acima do limite", "wind", "COM_WIND_MAX_ACT", [0, 1, 2, 3, 4, 5], 1),
    ("tempo de voo excedido", "ftl", None, [None], 1),
    ("falha de missao", "mf", None, [None], 1),
    ("falha do navegador", "nav", None, [None], 1),
    ("bateria Critical", "bat", "COM_LOW_BAT_ACT", [0, 1, 2, 3, 4, 5, 6], 2),
    ("bateria Emergency", "bat", "COM_LOW_BAT_ACT", [0, 1, 2, 3, 4, 5, 6], 3),
]
DEFAULTS = {"NAV_RCL_ACT": 2, "NAV_DLL_ACT": 0, "COM_GNSSLOSS_ACT": 0, "GF_ACTION": 1, "COM_WIND_MAX_ACT": 1, "COM_LOW_BAT_ACT": 3}
md = ["# Outras causas de failsafe no PX4 real\n"]

# ------------------------------------------------------------------ parte 1
md.append("## 1. A acao trava ou libera quando a condicao some?\n")
md.append("`COM_FAIL_ACT_T = 0`, armado, AUTO_MISSION, um passo por segundo. Colunas: acao com a causa ativa; 1 s depois de a causa sumir; "
          "depois de uma troca de modo para Loiter; depois de desarmar e armar de novo (causa ja desligada).\n")
md.append("| Causa | Parametro = valor | ativa | causa some | troca de modo | desarma e arma | Leitura |")
md.append("|---|---|---|---|---|---|---|")
latch = collections.Counter()
for (name, flag, param, values, fv) in CAUSES:
    for v in values:
        s = ["PARAM COM_FAIL_ACT_T 0"] + ["PARAM %s %d" % (k, d) for k, d in DEFAULTS.items()]
        if param:
            s.append("PARAM %s %d" % (param, v))
        s.append("NEW")
        t = 5000
        def step(extra, armed=1, mode=MISSION):
            global t
            s.append("STEP %d armed=%d mode=%d %s" % (t, armed, mode, extra)); t += 1000
        off = "%s=0" % flag                        # a causa DESLIGADA explicitamente (o harness mantem as flags entre passos)
        step(off)                                   # 0: limpo
        for _ in range(3):
            step("%s=%d" % (flag, fv))             # 1..3: causa ativa
        step(off)                                   # 4: causa some
        step(off)                                   # 5
        step(off, mode=LOITER)                      # 6: troca de modo
        step(off, mode=LOITER)                      # 7
        step(off, armed=0, mode=LOITER)             # 8: desarma
        step(off, armed=1, mode=MISSION)            # 9: arma de novo
        r = run(s)
        a = [int(x[1]) for x in r]
        on, off, mode, rearm = a[3], a[4], a[7], a[9]
        if on <= 1:
            reading = "so avisa ou nada" if on == 1 else "sem acao"
            kind = "sem acao"
        elif off <= 1:
            reading = "libera"
            kind = "libera"
        elif mode <= 1 or rearm <= 1:
            reading = "trava ate troca de modo ou desarmar"
            kind = "trava ate modo/desarmar"
        else:
            reading = "nunca libera"
            kind = "nunca libera"
        latch[(name, kind)] += 1
        md.append("| %s | %s | %s | %s | %s | %s | %s |" % (name, ("%s = %d" % (param, v)) if param else "(fixo)", ACT[on], ACT[off], ACT[mode], ACT[rearm], reading))
md.append("")
summ = collections.defaultdict(list)
for (name, kind), n in sorted(latch.items()):
    summ[name].append("%s: %d" % (kind, n))
md.append("Resumo por causa (quantos valores do parametro caem em cada comportamento):\n")
for name, items in summ.items():
    md.append("* %s: %s" % (name, "; ".join(items)))
md.append("")

# ------------------------------------------------------------------ parte 2
md.append("## 2. Com varias causas ao mesmo tempo, vale a mais severa?\n")
FLAGS = [(c[1], c[4], c[0]) for c in CAUSES if c[0] != "bateria Emergency"]   # 9 causas; bateria no nivel Critical
rng = random.Random(20261119)
PRM = {c[2]: c[3] for c in CAUSES if c[2]}
subsets = [sub for k in range(1, len(FLAGS) + 1) for sub in itertools.combinations(range(len(FLAGS)), k)]


def run_cfg(cfg, hold_steps):
    s = ["PARAM COM_FAIL_ACT_T %d" % (0 if hold_steps == 1 else 5)] + ["PARAM %s %d" % kv for kv in cfg.items()]
    for sub in subsets:
        s.append("NEW")
        s.append("STEP 5000 armed=1 mode=%d" % MISSION)
        flags = " ".join("%s=%d" % (FLAGS[i][0], FLAGS[i][1]) for i in sub)
        for k in range(hold_steps):
            s.append("STEP %d armed=1 mode=%d %s" % (6000 + 1000 * k, MISSION, flags))
    res = run(s)
    out = {}
    per = hold_steps + 1
    for n, sub in enumerate(subsets):
        out[sub] = int(res[n * per + hold_steps][1])
    return out


stats = {}
for T, hold in ((0, 1), (5, 8)):
    viol = collections.Counter()
    examples = {}
    total = 0
    for _ in range(NCFG):
        cfg = {p: rng.choice(v) for p, v in PRM.items()}
        res = run_cfg(cfg, hold)
        for sub, got in res.items():
            if len(sub) < 2:
                continue
            total += 1
            exp = max(res[(i,)] for i in sub)
            if got != exp:
                key = (ACT[got], ACT[exp])
                viol[key] += 1
                examples.setdefault(key, (cfg, [FLAGS[i][2] for i in sub]))
    stats[T] = (total, viol, examples)
    print("T=%d: %d casos, %d violacoes" % (T, total, sum(viol.values())), flush=True)
md.append("%d configuracoes sorteadas de parametros (semente 20261119), todos os %d subconjuntos de 2 ou mais das 9 causas "
          "(%s) ligados ao mesmo tempo no passo 1. Lei: acao escolhida = maximo das acoes de cada causa sozinha (mesma configuracao).\n"
          % (NCFG, len(subsets) - len(FLAGS), ", ".join(f[2] for f in FLAGS)))
md.append("| `COM_FAIL_ACT_T` | casos | violacoes | escolhida / esperada (o maximo) |")
md.append("|---|---|---|---|")
for T, (total, viol, examples) in stats.items():
    if not viol:
        md.append("| %d | %d | 0 | - |" % (T, total))
    else:
        md.append("| %d | %d | %d | %s |" % (T, total, sum(viol.values()), "; ".join("%s / %s: %d" % (k[0], k[1], n) for k, n in viol.most_common())))
md.append("")
for T, (total, viol, examples) in stats.items():
    for key, (cfg, sub) in list(examples.items())[:6]:
        md.append("Exemplo (T=%d), escolhida %s, esperada %s: parametros %s; causas %s." % (T, key[0], key[1], cfg, ", ".join(sub)))
# ------------------------------------------------------------------ parte 3
md.append("\n## 3. O resultado depende da ordem em que as causas aparecem?\n")
md.append("Mesmas configuracoes. Para cada subconjunto de 2 ou 3 causas, todas as ordens de chegada, uma causa nova por passo (1 s) e as "
          "anteriores continuam ligadas; depois, passos de espera ate o fim. Conferem-se (a) acao final igual para todas as ordens e (b) igual "
          "ao maximo das acoes de cada causa sozinha.\n")
md.append("| `COM_FAIL_ACT_T` | casos (subconjunto, configuracao) | ordens distintas dao acao final diferente | acao final diferente do maximo |")
md.append("|---|---|---|---|")
rng3 = random.Random(20261120)
sizes23 = [sub for sub in subsets if len(sub) in (2, 3)]
for T, wait in ((0, 2), (5, 8)):
    ncase = ndiff = nmax = 0
    ex3 = None
    for _ in range(NCFG):
        cfg = {p: rng3.choice(v) for p, v in PRM.items()}
        script = ["PARAM COM_FAIL_ACT_T %d" % T] + ["PARAM %s %d" % kv for kv in cfg.items()]
        runs = []
        for sub in subsets:                           # acao de cada causa sozinha, mesma configuracao
            if len(sub) == 1:
                script.append("NEW"); script.append("STEP 5000 armed=1 mode=%d" % MISSION)
                for k in range(wait + 1):
                    script.append("STEP %d armed=1 mode=%d %s=%d" % (6000 + 1000 * k, MISSION, FLAGS[sub[0]][0], FLAGS[sub[0]][1]))
                runs.append(("single", sub, None, 2 + wait))
        for sub in sizes23:
            for perm in itertools.permutations(sub):
                script.append("NEW"); script.append("STEP 5000 armed=1 mode=%d" % MISSION)
                on = []
                for j, ci in enumerate(perm):
                    on.append("%s=%d" % (FLAGS[ci][0], FLAGS[ci][1]))
                    script.append("STEP %d armed=1 mode=%d %s" % (6000 + 1000 * j, MISSION, " ".join(on)))
                for k in range(wait):
                    script.append("STEP %d armed=1 mode=%d %s" % (6000 + 1000 * (len(perm) + k), MISSION, " ".join(on)))
                runs.append(("perm", sub, perm, 1 + len(perm) + wait))
        res = run(script)
        pos = 0
        single, final = {}, collections.defaultdict(set)
        for kind, sub, perm, n in runs:
            single_val = int(res[pos + n - 1][1])
            pos += n
            if kind == "single":
                single[sub[0]] = single_val
            else:
                final[sub].add(single_val)
        for sub, vals in final.items():
            ncase += 1
            if len(vals) > 1:
                ndiff += 1
                ex3 = ex3 or (cfg, [FLAGS[i][2] for i in sub], sorted(ACT[v] for v in vals))
            elif next(iter(vals)) != max(single[i] for i in sub):
                nmax += 1
                ex3 = ex3 or (cfg, [FLAGS[i][2] for i in sub], ["maximo " + ACT[max(single[i] for i in sub)], ACT[next(iter(vals))]])
    md.append("| %d | %d | %d | %d |" % (T, ncase, ndiff, nmax))
    print("ordem T=%d: %d casos, %d dependem da ordem, %d diferem do maximo" % (T, ncase, ndiff, nmax), flush=True)
    if ex3:
        md.append("\nExemplo (T=%d): parametros %s; causas %s; resultados %s.\n" % ((T,) + ex3))
text = "\n".join(md)
print(text)
if out_md:
    open(out_md, "w", encoding="utf8", newline="\n").write(text + "\n")
