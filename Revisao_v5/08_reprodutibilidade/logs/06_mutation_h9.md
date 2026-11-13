# Testes de mutação da implementação em CREM

Gerado por `validation/scripts/mutation.sh` em 2026-11-13, GHC 9.6.7. Cada mutante é aplicado a uma cópia temporária de `03_codigo`.
Suítes: spec-tests e sim-tests (N=3) do pacote base; conformance, reach e model (Hedgehog) do pacote de validação.

| Id | Defeito injetado | Resultado | Suítes que reprovaram / causa |
|---|---|---|---|
| H9 | CURINGA: Grounded+TakeoffSignal omitida e cláusula final avionicsAction s _ = pureResult MsgIgnored s (identidade) | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) |

Mutantes avaliados: 1. Vivos: 0.

Notas: um mutante recusado na compilação não precisa de teste (é o que se quer da tipagem e de `-Werror=incomplete-patterns`).
Um mutante que compila e é morto só por teste mostra a fronteira da garantia dos tipos (H2, H3, H6, H7, H8: o compilador os aceita).
