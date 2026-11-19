#!/usr/bin/env python3
"""Autoteste do harness: reproduz as 14 expectativas do teste BatteryFailsafeUsesLowBatActParam do PX4
(src/modules/commander/failsafe/failsafe_test.cpp, linhas 1202 a 1219 no commit fixado). Se o harness nao
reproduzir o que o PX4 afirma sobre o proprio codigo, nada do que sai dele vale.
Uso: python selftest.py <px4_failsafe>
"""
import subprocess
import sys

exe = sys.argv[1]
NONE, LOW, CRIT, EMERG = 0, 1, 2, 3
WARN, RTL, LAND, TERM = 1, 6, 7, 10
# (COM_LOW_BAT_ACT, battery_warning, battery_low_remaining_time, acao esperada) — transcritas do teste do PX4
CASES = [
    (0, NONE, 1, WARN), (2, NONE, 1, WARN), (3, NONE, 1, RTL), (4, NONE, 1, RTL), (5, NONE, 1, WARN), (6, NONE, 1, WARN),
    (3, CRIT, 0, RTL), (5, CRIT, 0, RTL), (4, CRIT, 0, RTL), (6, CRIT, 0, RTL),
    (3, EMERG, 0, LAND), (5, EMERG, 0, LAND), (4, EMERG, 0, TERM), (6, EMERG, 0, TERM),
]
script = []
for act, bat, rft, _ in CASES:
    # como no teste do PX4: arma sem aviso de bateria; 10 ms depois, aplica o aviso; COM_FAIL_ACT_T = 0
    script += ["PARAM COM_LOW_BAT_ACT %d" % act, "PARAM COM_FAIL_ACT_T 0", "NEW", "STEP 5000 armed=1",
               "STEP 5010 armed=1 bat=%d rft=%d" % (bat, rft)]
res = subprocess.run([exe], input="\n".join(script) + "\n", capture_output=True, text=True)
if res.returncode != 0:
    sys.exit("falha ao executar o harness: " + res.stderr)
got = [int(l.split()[1]) for l in res.stdout.strip().split("\n")][1::2]
bad = [(c, g) for c, g in zip(CASES, got) if c[3] != g]
print("expectativas do PX4 reproduzidas: %d de %d" % (len(CASES) - len(bad), len(CASES)))
for c, g in bad:
    print("DIVERGE: COM_LOW_BAT_ACT=%d bat=%d rft=%d esperado %d obtido %d" % (c[0], c[1], c[2], c[3], g))
sys.exit(1 if bad else 0)
