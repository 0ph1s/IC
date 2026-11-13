# Matriz de rejeição da topologia em C++17 tipado (16 pares), com a causa conferida

Gerado por `05_c-cpp/scripts/typed_matrix.sh` em 2026-11-13. Compilador: clang version 14.0.6, `-std=c++17 -Wall -Wextra`.
Esperado: derivado de `03_codigo/validation/spec/transition_table.csv`. Rejeitado = exatamente um erro, `static_assert` nomeando o par.

| De | Para | Esperado | Obtido | Confere |
|---|---|---|---|---|
| Grounded | Grounded | compila | compila | ok |
| Grounded | InFlight | compila | compila | ok |
| Grounded | EmergencyLanding | rejeitado | rejeitado | ok |
| Grounded | Shutdown | compila | compila | ok |
| InFlight | Grounded | rejeitado | rejeitado | ok |
| InFlight | InFlight | compila | compila | ok |
| InFlight | EmergencyLanding | compila | compila | ok |
| InFlight | Shutdown | rejeitado | rejeitado | ok |
| EmergencyLanding | Grounded | compila | compila | ok |
| EmergencyLanding | InFlight | rejeitado | rejeitado | ok |
| EmergencyLanding | EmergencyLanding | compila | compila | ok |
| EmergencyLanding | Shutdown | rejeitado | rejeitado | ok |
| Shutdown | Grounded | rejeitado | rejeitado | ok |
| Shutdown | InFlight | rejeitado | rejeitado | ok |
| Shutdown | EmergencyLanding | rejeitado | rejeitado | ok |
| Shutdown | Shutdown | compila | compila | ok |

Compilaram: 8. Rejeitados: 8. Divergências: 0.

## Mensagem nos pares rejeitados

- `Grounded → EmergencyLanding`: static_assert failed due to requirement 'Allowed<Grounded, EmergencyLanding>::value' "transicao fora da topologia"
- `InFlight → Grounded`: static_assert failed due to requirement 'Allowed<InFlight, Grounded>::value' "transicao fora da topologia"
- `InFlight → Shutdown`: static_assert failed due to requirement 'Allowed<InFlight, Shutdown>::value' "transicao fora da topologia"
- `EmergencyLanding → InFlight`: static_assert failed due to requirement 'Allowed<EmergencyLanding, InFlight>::value' "transicao fora da topologia"
- `EmergencyLanding → Shutdown`: static_assert failed due to requirement 'Allowed<EmergencyLanding, Shutdown>::value' "transicao fora da topologia"
- `Shutdown → Grounded`: static_assert failed due to requirement 'Allowed<Shutdown, Grounded>::value' "transicao fora da topologia"
- `Shutdown → InFlight`: static_assert failed due to requirement 'Allowed<Shutdown, InFlight>::value' "transicao fora da topologia"
- `Shutdown → EmergencyLanding`: static_assert failed due to requirement 'Allowed<Shutdown, EmergencyLanding>::value' "transicao fora da topologia"
