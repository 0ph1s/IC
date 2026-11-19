#!/usr/bin/env python3
"""Oraculo PX4: roda os tracos da implementacao (TraceData.tla + tracos.csv, exportados por validation-export)
no failsafe REAL do PX4 (px4_failsafe.exe) e compara, ao fim de cada tick, a decisao do PX4 com a da nossa
implementacao.

Traducao (declarada, nao e propriedade do PX4): por passo (aviônica, bateria, ambiente) ->
  armed = aviônica in {InFlight, EmergencyLanding};  battery_warning = {Charged:0, Low:1, Critical:2}, e o comando
  CriticalBattery (codigo 2) AFIRMA bateria Critical durante os passos do seu tick (assert=1; assert=0 desliga isso);
  modo pretendido = AUTO_MISSION; COM_LOW_BAT_ACT e COM_FAIL_ACT_T dados por argumento; 100 ms por passo.
"Pouso" na PX4 = acao selecionada Land (7) ou RTL (6) (conforme o parametro); na nossa = EmergencyLanding.
Uso: python px4_diff.py <px4_failsafe> <TraceData.tla> <tracos.csv> <COM_LOW_BAT_ACT> [saida.md] [assert_cb 0|1]
Saida 0 se toda divergencia cair numa das tres classes explicadas abaixo; 1 se houver classe INEXPLICADA
(ou outra nao prevista).
"""
import collections
import csv
import subprocess
import sys

exe, tla, csvp, act = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
out_md = sys.argv[5] if len(sys.argv) > 5 else None
assert_cb = int(sys.argv[6]) if len(sys.argv) > 6 else 1
fail_t = float(sys.argv[7]) if len(sys.argv) > 7 else 0.0     # COM_FAIL_ACT_T em segundos
step_ms = int(sys.argv[8]) if len(sys.argv) > 8 else 100      # tempo por passo
AV = ["Grounded", "InFlight", "EmergencyLanding", "Shutdown"]
PW = ["Charged", "Low", "Critical"]
ACT = {0: "None", 1: "Warn", 2: "FallbackPos", 3: "FallbackAlt", 4: "FallbackStab", 5: "Hold", 6: "RTL", 7: "Land",
       8: "Descend", 9: "Disarm", 10: "Terminate"}
text = open(tla, encoding="utf8").read()
body = text.split("Traces ==", 1)[1].split("====", 1)[0]
traces = eval(body.replace("<<", "[").replace(">>", "]"))
kinds = {int(r["indice"]) - 1: r["tipo"] for r in csv.DictReader(open(csvp, encoding="utf8"))}
assert len(kinds) == len(traces), (len(kinds), len(traces))
use = [i for i in range(len(traces)) if kinds[i] != "corrompido"]


def dec(code):
    return code // 100, (code // 10) % 10


script = ["PARAM COM_LOW_BAT_ACT %d" % act, "PARAM COM_FAIL_ACT_T %g" % fail_t]
index = []   # (trace, tick, k, ours_av, ours_pw, is_tick_end)
for i in use:
    script.append("NEW")
    t = 0
    first = True
    prev_armed = 0
    arm_pw = 0
    for ti, (cmd, pwe, steps) in enumerate(traces[i]):
        for k, code in enumerate(steps):
            if k == 0 and not first:
                continue   # o primeiro passo de um tick repete o ultimo do tick anterior
            av, pw = dec(code)
            armed = 1 if av in (1, 2) else 0
            bat = 2 if (assert_cb and cmd == 2 and k >= 1) else pw
            if armed and not prev_armed:
                arm_pw = bat
            prev_armed = armed
            script.append("STEP %d armed=%d mode=3 bat=%d" % (t, armed, bat))
            index.append((i, ti, k, av, pw, k == len(steps) - 1, arm_pw, bat))
            t += step_ms
        first = False
res = subprocess.run([exe], input="\n".join(script) + "\n", capture_output=True, text=True)
if res.returncode != 0:
    sys.exit("px4_failsafe falhou: " + res.stderr)
lines = res.stdout.split("\n")[:-1]
assert len(lines) == len(index), (len(lines), len(index))

LAND = {6, 7}
tally = collections.Counter()
examples = {}
for (i, ti, k, av, pw, end, arm_pw, bat), line in zip(index, lines):
    if not end:
        continue
    action = int(line.split()[1])
    ours_land = av == 2
    px_land = action in LAND
    if action == 5 and fail_t > 0 and bat == 2:
        cls = "ATRASO: o PX4 esta em Hold esperando COM_FAIL_ACT_T; a nossa esta em %s" % AV[av]
    elif ours_land == px_land:
        cls = "concordam"
    elif px_land and av == 1 and pw == 2:
        cls = "PX4 pousa; nossa fica InFlight com bateria Critical (cegueira)"
    elif px_land and not ours_land:
        cls = "PX4 pousa; nossa (%s, %s) nao" % (AV[av], PW[pw])
    elif bat == 2 and arm_pw == 2:
        cls = "PX4 so avisa: a bateria ja estava Critical ao armar (framework.cpp/failsafe.cpp, COM_LOW_BAT_ACT)"
    elif bat == 2:
        cls = "INEXPLICADO: nossa em EmergencyLanding, bateria Critical, PX4 acao %s" % ACT[action]
    else:
        cls = "trava: nossa segue em EmergencyLanding com bateria %s; PX4 liberou (acao %s)" % (PW[bat], ACT[action])
    tally[cls] += 1
    examples.setdefault(cls, (kinds[i], i + 1, ti + 1))
total = sum(tally.values())
rows = ["Parametro COM_LOW_BAT_ACT = %d, COM_FAIL_ACT_T = %g s, %d ms por passo; tracos usados: %d (aresta e aleatorios); finais de tick comparados: %d." % (act, fail_t, step_ms, len(use), total), ""]
rows.append("| Classe | Finais de tick | Exemplo (tipo, traco, tick) |")
rows.append("|---|---|---|")
for cls, n in sorted(tally.items(), key=lambda x: -x[1]):
    rows.append("| %s | %d | %s |" % (cls, n, examples[cls]))
msg = "\n".join(rows)
print(msg)
if out_md:
    open(out_md, "w", encoding="utf8", newline="\n").write(msg + "\n")
EXPLAINED = ("concordam", "ATRASO:", "PX4 pousa; nossa fica InFlight", "PX4 so avisa", "trava:")
unexpected = [c for c in tally if not c.startswith(EXPLAINED)]
if unexpected:
    print("\nCLASSES NAO PREVISTAS:", *unexpected, sep="\n  ")
sys.exit(1 if unexpected else 0)
