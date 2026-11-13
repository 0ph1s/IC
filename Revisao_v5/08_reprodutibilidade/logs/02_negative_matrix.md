# Matriz de rejeição em compilação (16 pares de vértices), com a causa conferida

Gerado por `validation/scripts/negative_matrix.sh` em 2026-11-13, com GHC 9.6.7.
Esperado: derivado de `validation/spec/transition_table.csv`. Cada linha foi compilada com `ghc -fno-code`.
Rejeitado = exatamente um erro, e é `Could not deduce AllowedTransition ... <origem> <destino>`.

| De | Para | Natureza | Esperado | Obtido | Confere |
|---|---|---|---|---|---|
| Grounded | Grounded | identidade | compila | compila | ok |
| Grounded | InFlight | aresta | compila | compila | ok |
| Grounded | EmergencyLanding | proibido | rejeitado | rejeitado | ok |
| Grounded | Shutdown | aresta | compila | compila | ok |
| InFlight | Grounded | proibido | rejeitado | rejeitado | ok |
| InFlight | InFlight | identidade | compila | compila | ok |
| InFlight | EmergencyLanding | aresta | compila | compila | ok |
| InFlight | Shutdown | proibido | rejeitado | rejeitado | ok |
| EmergencyLanding | Grounded | aresta | compila | compila | ok |
| EmergencyLanding | InFlight | proibido | rejeitado | rejeitado | ok |
| EmergencyLanding | EmergencyLanding | identidade | compila | compila | ok |
| EmergencyLanding | Shutdown | proibido | rejeitado | rejeitado | ok |
| Shutdown | Grounded | proibido | rejeitado | rejeitado | ok |
| Shutdown | InFlight | proibido | rejeitado | rejeitado | ok |
| Shutdown | EmergencyLanding | proibido | rejeitado | rejeitado | ok |
| Shutdown | Shutdown | identidade | compila | compila | ok |

Compilaram: 8. Rejeitados: 8. Divergências: 0.

## Erro do GHC nos pares rejeitados (trecho)

Entre parênteses, o tamanho da saída do GHC (`wc -l` / `wc -c`); os bytes incluem o caminho do módulo gerado.

- `Grounded → EmergencyLanding` (25 linhas, 1709 bytes): Could not deduce `Crem.Topology.AllowedTransition (Crem.Topology.Topology '[]) Grounded EmergencyLanding'
- `InFlight → Grounded` (25 linhas, 1637 bytes): Could not deduce `Crem.Topology.AllowedTransition (Crem.Topology.Topology '[]) InFlight Grounded'
- `InFlight → Shutdown` (25 linhas, 1636 bytes): Could not deduce `Crem.Topology.AllowedTransition (Crem.Topology.Topology '[]) InFlight Shutdown'
- `EmergencyLanding → InFlight` (26 linhas, 1773 bytes): Could not deduce `Crem.Topology.AllowedTransition (Crem.Topology.Topology '[]) EmergencyLanding InFlight'
- `EmergencyLanding → Shutdown` (26 linhas, 1773 bytes): Could not deduce `Crem.Topology.AllowedTransition (Crem.Topology.Topology '[]) EmergencyLanding Shutdown'
- `Shutdown → Grounded` (25 linhas, 1637 bytes): Could not deduce `Crem.Topology.AllowedTransition (Crem.Topology.Topology '[]) Shutdown Grounded'
- `Shutdown → InFlight` (25 linhas, 1637 bytes): Could not deduce `Crem.Topology.AllowedTransition (Crem.Topology.Topology '[]) Shutdown InFlight'
- `Shutdown → EmergencyLanding` (25 linhas, 1709 bytes): Could not deduce `Crem.Topology.AllowedTransition (Crem.Topology.Topology '[]) Shutdown EmergencyLanding'
