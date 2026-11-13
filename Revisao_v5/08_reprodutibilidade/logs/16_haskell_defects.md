# Defeitos na FSM em Haskell: `Avionics.Naive` (sem CREM) e a ação do CREM

Gerado por `05_c-cpp/scripts/haskell_defects.sh` em 2026-11-13, GHC 9.6.7.

## Haskell sem CREM (`Avionics.Naive`)

A: `-Wall`. W: `-Wall -Werror=incomplete-patterns`. Harness: `runghc` imprime os 16 pares e compara com `spec/transition_table.csv`.

| Id | Defeito | A | W | Harness exaustivo | Primeira mensagem (W) |
|---|---|---|---|---|---|
| N0 | baseline (sem defeito) | silêncio | silêncio | passa | - |
| N1 | par omitido (InFlight+LandedSignal), sem curinga | aviso(1) | recusa | detecta (exceção em execução: Harness.hs: Avionics\Naive.hs:(62,1)-(76,54): Non-exhaustive) | [GHC-62161] [-Wincomplete-patterns, Werror=incomplete-patterns] Pattern match(es) are non-exhaustive  |
| N2 | par omitido e cláusula final com curinga (transition s _ = s) | silêncio | silêncio | passa | - |
| N3 | transição proibida InFlight+SystemCutoff -> Shutdown | silêncio | silêncio | detecta (1 par) | - |
| N4 | aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown) | silêncio | silêncio | detecta (1 par) | - |
| N5 | compara estado com evento (s == e) | recusa | recusa | - | [GHC-83865] * Couldn't match expected type `AvState' with actual type `AvEvent'  |
| N6 | valor fora da enumeração (42 :: AvState) | recusa | recusa | - | [GHC-39999] * No instance for `Num AvState' arising from the literal `42'  |

## Haskell + CREM (`Avionics.Crem`), classes D5 e D6

Compilado com as opções do pacote (GHC2021, `-Wall -Werror=incomplete-patterns`) e `-fno-code`. C0 (sem defeito) confere o comando.
As classes D1 a D4 do CREM estão em `06_mutation_haskell.md` (H5, H9, H4, H2).

| Id | Defeito | W | Primeira mensagem |
|---|---|---|---|
| C0 | baseline (sem defeito) | silêncio | - |
| C5 | evento usado como destino (Grounded+CriticalBattery devolve o evento CriticalBattery) | recusa | [GHC-83865] * Couldn't match expected type `SAvionicsVertex finalVertex0'  |
| C6 | valor fora da enumeração (Grounded+CriticalBattery devolve 42) | recusa | [GHC-39999] * Could not deduce `AllowedTransition  |
