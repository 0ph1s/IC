# -*- coding: utf-8 -*-
"""Confere o TLC com a exploração em Haskell: o conjunto de ternos (aviônica, energia, ambiente) com a
fila vazia, no dump do TLC (política OneSlot), deve ser IGUAL ao conjunto de ternos alcançáveis que
`cabal test validation-reach-tests` imprime (08_reprodutibilidade/logs/04_reach.txt, seção [lista]).
Sai com 0 se forem iguais."""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
LOGS = os.path.join(HERE, "..", "08_reprodutibilidade", "logs")
AV = ("Grounded", "InFlight", "EmergencyLanding", "Shutdown")


def haskell_states():
    txt = open(os.path.join(LOGS, "04_reach.txt"), encoding="utf-8", errors="replace").read()
    sec = txt.split("[lista]")[1].split("=== 1.")[0]
    return {t for t in re.findall(r"\((\w+), (\w+), (\w+)\)", sec) if t[0] in AV}


def tlc_states(policy):
    path = os.path.join(HERE, "states", "dump_%s.txt.dump" % policy)
    txt = open(path, encoding="utf-8", errors="replace").read().strip()
    out = set()
    for st in re.split(r"\n\s*\n", txt):
        if "av =" in st and re.search(r"queue = <<\s*>>", st):
            out.add(tuple(re.search(r'%s = "(\w+)"' % k, st).group(1) for k in ("av", "pw", "slot")))
    return out


def main():
    hs, tl = haskell_states(), tlc_states("OneSlot")
    print("ternos com fila vazia: TLC = %d, Haskell = %d" % (len(tl), len(hs)))
    print("conjuntos iguais:", hs == tl)
    if hs != tl:
        print("só no Haskell:", sorted(hs - tl))
        print("só no TLC:", sorted(tl - hs))
    return 0 if hs == tl else 1


if __name__ == "__main__":
    sys.exit(main())
