# Defeitos na FSM em Haskell ingênua (Avionics.Naive)

Gerado por `05_c-cpp/scripts/haskell_defects.sh` em 2026-11-13, GHC 9.6.7. A: `-Wall`. W: `-Wall -Werror=incomplete-patterns`.
Harness: `runghc` imprime os 16 pares e compara com `spec/transition_table.csv`.

| Id | Defeito | A | W | Harness exaustivo | Primeira mensagem (W) |
|---|---|---|---|---|---|
| N0 | baseline (sem defeito) | silêncio | silêncio | passa | - |
| N1 | par omitido (InFlight+LandedSignal), sem curinga | aviso(1) | recusa | detecta (exceção em execução: Harness.hs: Avionics\Naive.hs:(62,1)-(76,54): Non-exhaustive) | [GHC-62161] [-Wincomplete-patterns, Werror=incomplete-patterns] |
| N2 | par omitido e cláusula final com curinga (transition s _ = s) | silêncio | silêncio | passa | - |
| N3 | transição proibida InFlight+SystemCutoff -> Shutdown | silêncio | silêncio | detecta (1 par) | - |
| N4 | aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown) | silêncio | silêncio | detecta (1 par) | - |
| N5 | compara estado com evento (s == e) | recusa | recusa | - | [GHC-83865] |
| N6 | valor fora da enumeração (42 :: AvState) | recusa | recusa | - | [GHC-39999] |
