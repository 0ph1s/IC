## T16 — probabilidade EXATA de um teste aleatório de L ticks achar a lacuna

Estados presos sob ticks ociosos: ["(InFlight, Critical, Standby)","(InFlight, Critical, CutoffHeld)"]; cegos no fim do tick: ["(InFlight, Critical, Standby)","(InFlight, Critical, CriticalHeld)","(InFlight, Critical, CutoffHeld)"]
Pares do produto implementação x Queue: 282; implementação x Level: 337

| L | cegueira (uniforme) | cegueira (genTick) | testes esperados (genTick) | cego no fim (genTick) | divergência OneSlot x Queue (uniforme) | idem (genTick) | divergência impl. x Level (genTick) |
|---|---|---|---|---|---|---|---|
| 1 | 0.000000 | 0.000000 | --- | 0.000000 | 0.000000 | 0.000000 | 0.000000 |
| 2 | 0.000000 | 0.000000 | --- | 0.003022 | 0.000000 | 0.000000 | 0.000000 |
| 3 | 0.001875 | 0.000713 | 1402 | 0.007038 | 0.002500 | 0.000178 | 0.000000 |
| 4 | 0.003350 | 0.001761 | 568 | 0.010746 | 0.017000 | 0.001611 | 0.000683 |
| 6 | 0.003533 | 0.003428 | 292 | 0.015295 | 0.061337 | 0.009111 | 0.003642 |
| 8 | 0.002605 | 0.003900 | 256 | 0.016115 | 0.100045 | 0.020521 | 0.007277 |
| 12 | 0.001142 | 0.002892 | 346 | 0.012498 | 0.143521 | 0.044655 | 0.013102 |
| 16 | 0.000479 | 0.001646 | 608 | 0.008055 | 0.160286 | 0.063242 | 0.016382 |
| 24 | 0.000084 | 0.000456 | 2191 | 0.002896 | 0.168711 | 0.082855 | 0.018889 |
| 32 | 0.000015 | 0.000132 | 7579 | 0.001003 | 0.169825 | 0.089863 | 0.019541 |
| 60 | 0.000000 | 0.000003 | 377890 | 0.000024 | 0.169993 | 0.093297 | 0.019807 |

## T17 — enumeração exaustiva até a profundidade d (todas as 20^d sequências de d ticks)

| d | sequências de d ticks | terminam em estado preso | fração | sequências com divergência impl. x Level até d | fração |
|---|---|---|---|---|---|
| 1 | 20 | 0 | 0.000000 | 0 | 0.000000 |
| 2 | 400 | 0 | 0.000000 | 0 | 0.000000 |
| 3 | 8000 | 15 | 0.001875 | 0 | 0.000000 |
| 4 | 160000 | 536 | 0.003350 | 180 | 0.001125 |
| 5 | 3200000 | 11979 | 0.003743 | 7860 | 0.002456 |
| 6 | 64000000 | 226128 | 0.003533 | 240160 | 0.003752 |
| 7 | 1280000000 | 3959823 | 0.003094 | 6215740 | 0.004856 |
| 8 | 25600000000 | 66681464 | 0.002605 | 147113660 | 0.005747 |

## Conferência por sorteio (200 000 cenários, genTick, gerador congruencial, semente 20261118 + 7919k)

| L | exato | sorteado |
|---|---|---|
| 4 | 0.001761 | 0.001715 |
| 8 | 0.003900 | 0.003705 |
| 16 | 0.001646 | 0.001660 |
| 32 | 0.000132 | 0.000120 |
