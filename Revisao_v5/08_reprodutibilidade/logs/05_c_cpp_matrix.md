# Auditoria da comparação com C e C++ (matriz reproduzível)

Gerado por `05_c-cpp/scripts/audit.sh` em 2026-11-13. Sistema: MINGW64_NT-10.0-26300 (x86_64).
Compilador C: clang version 14.0.6. Compilador C++: clang version 14.0.6.
Esperado: os 16 triplos de `03_codigo/validation/spec/transition_table.csv` (coluna `origem` não usada aqui).

Legenda: **recusa** = a compilação falha; **aviso(N)** = compila com N avisos; **silêncio** = compila sem aviso.
O harness imprime os 16 pares e os compara com a tabela: **passa** = igual; **detecta** = diferente.

## Pilha 1 — C (`enum` + `switch`)

Fonte: `05_c-cpp/src/fsm.c`. Compilador: clang version 14.0.6. Padrão: `padrão do compilador`.
A: `-Wall -Wextra`. B: `-Wall -Wextra -Wswitch-enum -Wenum-compare -Wassign-enum`. W: B com `-Werror`. S: `--analyze`.

| Id | Defeito injetado | A | B | W (erro) | S (análise) | Harness exaustivo | Primeira mensagem (W) |
|---|---|---|---|---|---|---|---|
| M0 | baseline (sem defeito) | silêncio | silêncio | silêncio | silêncio | passa | - |
| M1 | omite o caso InFlight+LandedSignal (sem default) | aviso(1) | aviso(1) | recusa | silêncio | passa | enumeration value 'LANDED_SIGNAL' not handled in switch [-Werror,-Wswitch] |
| M2 | omite o mesmo caso e acrescenta default (curinga) | silêncio | aviso(1) | recusa | silêncio | passa | enumeration value 'LANDED_SIGNAL' not explicitly handled in switch [-Werror,-Wswitch-enum] |
| M3 | transição proibida InFlight+SystemCutoff -> Shutdown | silêncio | silêncio | silêncio | silêncio | detecta (1 par) | - |
| M4 | aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown) | silêncio | silêncio | silêncio | silêncio | detecta (1 par) | - |
| M5 | compara estado com constante de evento | silêncio | silêncio | silêncio | silêncio | detecta (3 par) | - |
| M6 | retorna valor fora da enumeração (42) | silêncio | silêncio | silêncio | silêncio | detecta (1 par) | - |

## Pilha 2 — C++17 (`enum class` + `switch`)

Fonte: `05_c-cpp/src/fsm.cpp`. Compilador: clang version 14.0.6. Padrão: `-std=c++17`.
A: `-Wall -Wextra`. B: `-Wall -Wextra -Wswitch-enum -Wenum-compare -Wassign-enum`. W: B com `-Werror`. S: `--analyze`.

| Id | Defeito injetado | A | B | W (erro) | S (análise) | Harness exaustivo | Primeira mensagem (W) |
|---|---|---|---|---|---|---|---|
| M0 | baseline (sem defeito) | silêncio | silêncio | silêncio | silêncio | passa | - |
| M1 | omite o caso InFlight+LandedSignal (sem default) | aviso(1) | aviso(1) | recusa | silêncio | passa | enumeration value 'LANDED_SIGNAL' not handled in switch [-Werror,-Wswitch] |
| M2 | omite o mesmo caso e acrescenta default (curinga) | silêncio | aviso(1) | recusa | silêncio | passa | enumeration value 'LANDED_SIGNAL' not explicitly handled in switch [-Werror,-Wswitch-enum] |
| M3 | transição proibida InFlight+SystemCutoff -> Shutdown | silêncio | silêncio | silêncio | silêncio | detecta (1 par) | - |
| M4 | aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown) | silêncio | silêncio | silêncio | silêncio | detecta (1 par) | - |
| M5 | compara estado com constante de evento | recusa | recusa | recusa | recusa | - | invalid operands to binary expression ('state_t' and 'event_t') |
| M6 | retorna valor fora da enumeração (42, via static_cast) | silêncio | silêncio | silêncio | silêncio | detecta (1 par) | - |

## Pilha 3 — C++17 moderno (`std::variant` + topologia em `static_assert`)

Fonte: `05_c-cpp/src/fsm_typed.cpp`. Compilador: clang version 14.0.6. Padrão: `-std=c++17`.
A: `-Wall -Wextra`. B: `-Wall -Wextra -Wswitch-enum -Wenum-compare -Wassign-enum`. W: B com `-Werror`. S: `--analyze`.

| Id | Defeito injetado | A | B | W (erro) | S (análise) | Harness exaustivo | Primeira mensagem (W) |
|---|---|---|---|---|---|---|---|
| T0 | baseline (sem defeito) | silêncio | silêncio | silêncio | silêncio | passa | - |
| T1 | omite o par InFlight+LandedSignal (sem curinga) | recusa | recusa | recusa | recusa | - | no matching function for call to 'step' |
| T2 | omite o mesmo par e acrescenta um gabarito genérico (curinga) | silêncio | silêncio | silêncio | silêncio | passa | - |
| T3 | transição proibida InFlight+SystemCutoff -> Shutdown | recusa | recusa | recusa | recusa | - | static_assert failed due to requirement 'Allowed<InFlight, Shutdown>::value' "transicao fora da topologia" |
| T4 | aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown) | silêncio | silêncio | silêncio | silêncio | detecta (1 par) | - |
| T5 | usa um evento como destino (estado x evento) | recusa | recusa | recusa | recusa | - | static_assert failed due to requirement 'Allowed<Grounded, TakeoffSignal>::value' "transicao fora da topologia" |

T6 (valor fora da enumeração) não se aplica: com `std::variant` de tipos distintos não existe valor 42 do tipo de estado.

Pares que a tabela deixa como convenção do projeto (`CONV`) valem igualmente para as três pilhas: o estado não muda.
