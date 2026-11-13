# Testes de mutação da implementação em CREM

Gerado por `validation/scripts/mutation.sh` em 2026-11-13, GHC 9.6.7. Cada mutante é aplicado a uma cópia temporária de `03_codigo`.
Suítes: spec-tests e sim-tests (N=3) do pacote base; conformance, reach e model (Hedgehog) do pacote de validação.

| Id | Defeito injetado | Resultado | Suítes que reprovaram / causa |
|---|---|---|---|
| H1 | aresta ILEGAL na topologia E na ação (InFlight -> Shutdown permitida) | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) |
| H2 | DESTINO errado em aresta permitida (Grounded+TakeoffSignal -> Shutdown) | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) |
| H3 | EVENTOS trocados em Grounded (TakeoffSignal <-> SystemCutoff) | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) |
| H4 | ação ilegal SEM tocar na topologia (InFlight+SystemCutoff -> Shutdown) | **recusado na compilação** | src\Avionics\Crem.hs:93:50: error: [GHC-39999] |
| H5 | par (estado, evento) OMITIDO (Shutdown+SystemCutoff) | **recusado na compilação** | src\Avionics\Crem.hs:86:1: error: [GHC-62161] [-Wincomplete-patterns, Werror=incomplete-patterns] |
| H6 | SAÍDA errada (EmergencyLanding+LandedSignal emite MsgIgnored) | compila; **morto** | sim-tests (N=3), conformance, reach, model (Hedgehog) |
| H7 | AMBIENTE: CriticalHeld libera LandedSignal em vez de CriticalBattery | compila; **morto** | sim-tests (N=3), reach, model (Hedgehog) |
| H8 | ENERGIA: Low+Drain fica em Low (não desce a Critical) | compila; **morto** | sim-tests (N=3), conformance, reach, model (Hedgehog) |
| H9 | CURINGA: Grounded+TakeoffSignal omitida e cláusula final avionicsAction s _ = pureResult MsgIgnored s (identidade) | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) |

Mutantes avaliados: 9. Vivos: 0.

Notas: um mutante recusado na compilação não precisa de teste (é o que se quer da tipagem e de `-Werror=incomplete-patterns`).
Um mutante que compila e é morto só por teste mostra a fronteira da garantia dos tipos (H1, H2, H3, H6, H7, H8 e H9: o compilador os aceita).
Cada expressão sed de um mutante é aplicada e conferida em separado: nenhum mutante roda meio aplicado.
