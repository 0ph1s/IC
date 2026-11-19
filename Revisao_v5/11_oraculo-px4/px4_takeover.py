#!/usr/bin/env python3
"""Takeover do piloto no failsafe REAL do PX4 (bateria Critical -> Land/RTL), e o que ele significa para a nossa maquina.

No PX4, quando um failsafe de bateria esta ativo, o piloto pode retomar o controle:
  * por MANCHE (rc_sticks_takeover_request): so se allow_user_takeover for Always, o que o PX4 decide assim:
    COM_FAIL_ACT_T > 0.1 s -> Always (manche vale); COM_FAIL_ACT_T = 0 -> AlwaysModeSwitchOnly (manche NAO vale);
  * por TROCA DE MODO (user_intended_mode muda): vale nos dois casos.
Na nossa maquina nao existe entrada do piloto: EmergencyLanding so sai com LandedSignal.

Parte 1: cenarios roteirizados (tabela de acoes por passo).
Parte 2: sonda. De cada fim de tick dos nossos tracos em que a nossa aviônica esta em EmergencyLanding, repete-se o traco no
PX4 e acrescenta-se um passo com manche (ou troca de modo); registra-se o que o PX4 faria.
Uso: python px4_takeover.py <px4_failsafe> <TraceData.tla> <tracos.csv> [saida.md]
"""
import collections
import csv
import subprocess
import sys

exe, tla, csvp = sys.argv[1], sys.argv[2], sys.argv[3]
out_md = sys.argv[4] if len(sys.argv) > 4 and sys.argv[4] else None
ACT = {0: "None", 1: "Warn", 2: "FbPos", 3: "FbAlt", 4: "FbStab", 5: "Hold", 6: "RTL", 7: "Land", 8: "Descend", 9: "Disarm", 10: "Term"}
MODE_MISSION, MODE_LOITER = 3, 4


def run(script):
    r = subprocess.run([exe], input="\n".join(script) + "\n", capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit("px4_failsafe falhou: " + r.stderr)
    return [l.split() for l in r.stdout.split("\n")[:-1]]


out = []
# ---------------------------------------------------------------- parte 1
def scenario(T, act, events, n=14):
    """events: {passo: dict de chaves extras}; bateria Critical a partir do passo 1; um passo por segundo."""
    s = ["PARAM COM_LOW_BAT_ACT %d" % act, "PARAM COM_FAIL_ACT_T %g" % T, "NEW"]
    mode = MODE_MISSION
    for k in range(n):
        ev = events.get(k, {})
        mode = ev.get("mode", mode)
        s.append("STEP %d armed=1 mode=%d bat=%d stick=%d" % (5000 + 1000 * k, mode, ev.get("bat", 2 if k >= 1 else 0), ev.get("stick", 0)))
    res = run(s)
    return " ".join("%s%s" % (ACT[int(r[1])], "*" if r[2] == "1" else "") for r in res)


out.append("# Takeover do piloto (PX4 real): cenarios e sonda nos estados de EmergencyLanding\n")
out.append("Sequencias de acoes, um passo por segundo, armado, modo AUTO_MISSION; bateria Critical a partir do passo 1; `*` = userTakeoverActive.\n")
out.append("```")
for T in (0, 5):
    for act in (2, 3):
        out.append("COM_FAIL_ACT_T=%g COM_LOW_BAT_ACT=%d" % (T, act))
        out.append("  sem takeover        : " + scenario(T, act, {}))
        out.append("  manche no passo 8   : " + scenario(T, act, {8: {"stick": 1}}))
        out.append("  troca de modo, 8    : " + scenario(T, act, {8: {"mode": MODE_LOITER}}))
        out.append("  manche no passo 8, bateria Emergency no 11: " + scenario(T, act, {8: {"stick": 1}, 11: {"bat": 3}}))
        out.append("  manche no passo 8, bateria recupera no 10 e cai de novo no 12: " + scenario(T, act, {8: {"stick": 1}, 10: {"bat": 0}, 12: {"bat": 2}}))
out.append("```\n")

# ---------------------------------------------------------------- parte 2
text = open(tla, encoding="utf8").read()
body = text.split("Traces ==", 1)[1].split("====", 1)[0]
traces = eval(body.replace("<<", "[").replace(">>", "]"))
kinds = {int(r["indice"]) - 1: r["tipo"] for r in csv.DictReader(open(csvp, encoding="utf8"))}


def steps_of(trace, cmd_assert=True):
    """Passos (av, bat) de um traco, como em px4_diff.py (CriticalBattery afirma bateria Critical durante o tick)."""
    res = []
    for ti, (cmd, pwe, steps) in enumerate(trace):
        for k, code in enumerate(steps):
            av, pw = code // 100, (code // 10) % 10
            bat = 2 if (cmd_assert and cmd == 2 and k >= 1) else pw
            res.append((av, bat, k == len(steps) - 1, ti))
    return res


def probe(T, act, dt):
    script = ["PARAM COM_LOW_BAT_ACT %d" % act, "PARAM COM_FAIL_ACT_T %g" % T]
    meta = []
    for i, tr in enumerate(traces):
        if kinds[i] == "corrompido":
            continue
        st = steps_of(tr)
        for j, (av, bat, end, ti) in enumerate(st):
            if not (end and av == 2):
                continue
            for kind in ("manche", "modo"):
                script.append("NEW")
                t = 5000
                for (a2, b2, _, _) in st[: j + 1]:
                    script.append("STEP %d armed=%d mode=%d bat=%d" % (t, 1 if a2 in (1, 2) else 0, MODE_MISSION, b2)); t += dt
                if kind == "manche":
                    script.append("STEP %d armed=1 mode=%d bat=%d stick=1" % (t, MODE_MISSION, bat)); t += dt
                    script.append("STEP %d armed=1 mode=%d bat=%d" % (t, MODE_MISSION, bat))
                else:
                    script.append("STEP %d armed=1 mode=%d bat=%d" % (t, MODE_LOITER, bat)); t += dt
                    script.append("STEP %d armed=1 mode=%d bat=%d" % (t, MODE_LOITER, bat))
                meta.append((i, kind, j + 1))
                meta[-1] = (i, kind, j + 1, bat)
    res = run(script)
    # cada sonda produz (j+1) + 2 linhas
    pos = 0
    tally = collections.Counter()
    for (i, kind, n, bat) in meta:
        lines = res[pos: pos + n + 2]
        pos += n + 2
        before = int(lines[n - 1][1])
        after = int(lines[n][1])
        later = int(lines[n + 1][1])
        tally[(kind, ACT[before], ACT[after], ACT[later])] += 1
    assert pos == len(res), (pos, len(res))
    return tally


out.append("## Sonda nos estados de EmergencyLanding dos nossos tracos\n")
out.append("Cada linha: de um fim de tick em que a NOSSA aviônica esta em EmergencyLanding, o que o PX4 faz com um manche (ou uma troca de "
           "modo para Loiter) no passo seguinte (`depois`), e o que faz no passo seguinte a esse sem novo gesto (`mantem`). `antes` = a acao do PX4 "
           "naquele fim de tick.\n")
for T, dt in ((0, 100), (5, 100), (5, 1000)):
    for act in (2,):
        tally = probe(T, act, dt)
        total = collections.Counter()
        for (kind, b, a, l), n in tally.items():
            total[kind] += n
        out.append("### COM_FAIL_ACT_T = %g s, COM_LOW_BAT_ACT = %d, %d ms por passo\n" % (T, act, dt))
        out.append("| gesto | antes | depois | mantem | fins de tick |")
        out.append("|---|---|---|---|---|")
        for (kind, b, a, l), n in sorted(tally.items(), key=lambda x: (x[0][0], -x[1])):
            out.append("| %s | %s | %s | %s | %d |" % (kind, b, a, l, n))
        out.append("")
        print("T=%g: %s" % (T, {k: v for k, v in total.items()}), flush=True)
msg = "\n".join(out)
print(msg)
if out_md:
    open(out_md, "w", encoding="utf8", newline="\n").write(msg + "\n")
