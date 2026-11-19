# Mutação exaustiva de destinos (48 mutantes) da ação da aviônica em CREM

Gerado por `validation/scripts/mutation_dest48.sh` em 2026-11-19, GHC 9.6.7. Cada mutante é aplicado a uma cópia temporária de `03_codigo`.
Suítes: spec-tests e sim-tests (N=3) do pacote base; conformance, reach e model (Hedgehog) do pacote de validação.

| Id | Defeito injetado | Previsto | Resultado | Suítes que reprovaram / causa | Concorda |
|---|---|---|---|---|---|
| D01 | destino trocado: Grounded+TakeoffSignal -> Grounded (original InFlight) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D02 | destino trocado: Grounded+TakeoffSignal -> EmergencyLanding (original InFlight) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:86:50: error: [GHC-39999] | sim |
| D03 | destino trocado: Grounded+TakeoffSignal -> Shutdown (original InFlight) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D04 | destino trocado: Grounded+CriticalBattery -> InFlight (original Grounded) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D05 | destino trocado: Grounded+CriticalBattery -> EmergencyLanding (original Grounded) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:87:50: error: [GHC-39999] | sim |
| D06 | destino trocado: Grounded+CriticalBattery -> Shutdown (original Grounded) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D07 | destino trocado: Grounded+LandedSignal -> InFlight (original Grounded) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D08 | destino trocado: Grounded+LandedSignal -> EmergencyLanding (original Grounded) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:88:50: error: [GHC-39999] | sim |
| D09 | destino trocado: Grounded+LandedSignal -> Shutdown (original Grounded) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D10 | destino trocado: Grounded+SystemCutoff -> Grounded (original Shutdown) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D11 | destino trocado: Grounded+SystemCutoff -> InFlight (original Shutdown) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D12 | destino trocado: Grounded+SystemCutoff -> EmergencyLanding (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:89:50: error: [GHC-39999] | sim |
| D13 | destino trocado: InFlight+TakeoffSignal -> Grounded (original InFlight) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:90:50: error: [GHC-39999] | sim |
| D14 | destino trocado: InFlight+TakeoffSignal -> EmergencyLanding (original InFlight) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D15 | destino trocado: InFlight+TakeoffSignal -> Shutdown (original InFlight) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:90:50: error: [GHC-39999] | sim |
| D16 | destino trocado: InFlight+CriticalBattery -> Grounded (original EmergencyLanding) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:91:50: error: [GHC-39999] | sim |
| D17 | destino trocado: InFlight+CriticalBattery -> InFlight (original EmergencyLanding) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D18 | destino trocado: InFlight+CriticalBattery -> Shutdown (original EmergencyLanding) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:91:50: error: [GHC-39999] | sim |
| D19 | destino trocado: InFlight+LandedSignal -> Grounded (original InFlight) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:92:50: error: [GHC-39999] | sim |
| D20 | destino trocado: InFlight+LandedSignal -> EmergencyLanding (original InFlight) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D21 | destino trocado: InFlight+LandedSignal -> Shutdown (original InFlight) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:92:50: error: [GHC-39999] | sim |
| D22 | destino trocado: InFlight+SystemCutoff -> Grounded (original InFlight) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:93:50: error: [GHC-39999] | sim |
| D23 | destino trocado: InFlight+SystemCutoff -> EmergencyLanding (original InFlight) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D24 | destino trocado: InFlight+SystemCutoff -> Shutdown (original InFlight) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:93:50: error: [GHC-39999] | sim |
| D25 | destino trocado: EmergencyLanding+TakeoffSignal -> Grounded (original EmergencyLanding) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D26 | destino trocado: EmergencyLanding+TakeoffSignal -> InFlight (original EmergencyLanding) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:94:52: error: [GHC-39999] | sim |
| D27 | destino trocado: EmergencyLanding+TakeoffSignal -> Shutdown (original EmergencyLanding) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:94:52: error: [GHC-39999] | sim |
| D28 | destino trocado: EmergencyLanding+CriticalBattery -> Grounded (original EmergencyLanding) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D29 | destino trocado: EmergencyLanding+CriticalBattery -> InFlight (original EmergencyLanding) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:95:52: error: [GHC-39999] | sim |
| D30 | destino trocado: EmergencyLanding+CriticalBattery -> Shutdown (original EmergencyLanding) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:95:52: error: [GHC-39999] | sim |
| D31 | destino trocado: EmergencyLanding+LandedSignal -> InFlight (original Grounded) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:96:52: error: [GHC-39999] | sim |
| D32 | destino trocado: EmergencyLanding+LandedSignal -> EmergencyLanding (original Grounded) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D33 | destino trocado: EmergencyLanding+LandedSignal -> Shutdown (original Grounded) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:96:52: error: [GHC-39999] | sim |
| D34 | destino trocado: EmergencyLanding+SystemCutoff -> Grounded (original EmergencyLanding) | aceito | compila; **morto** | spec-tests, sim-tests (N=3), conformance, reach, model (Hedgehog) | sim |
| D35 | destino trocado: EmergencyLanding+SystemCutoff -> InFlight (original EmergencyLanding) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:97:52: error: [GHC-39999] | sim |
| D36 | destino trocado: EmergencyLanding+SystemCutoff -> Shutdown (original EmergencyLanding) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:97:52: error: [GHC-39999] | sim |
| D37 | destino trocado: Shutdown+TakeoffSignal -> Grounded (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:98:50: error: [GHC-39999] | sim |
| D38 | destino trocado: Shutdown+TakeoffSignal -> InFlight (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:98:50: error: [GHC-39999] | sim |
| D39 | destino trocado: Shutdown+TakeoffSignal -> EmergencyLanding (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:98:50: error: [GHC-39999] | sim |
| D40 | destino trocado: Shutdown+CriticalBattery -> Grounded (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:99:50: error: [GHC-39999] | sim |
| D41 | destino trocado: Shutdown+CriticalBattery -> InFlight (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:99:50: error: [GHC-39999] | sim |
| D42 | destino trocado: Shutdown+CriticalBattery -> EmergencyLanding (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:99:50: error: [GHC-39999] | sim |
| D43 | destino trocado: Shutdown+LandedSignal -> Grounded (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:100:50: error: [GHC-39999] | sim |
| D44 | destino trocado: Shutdown+LandedSignal -> InFlight (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:100:50: error: [GHC-39999] | sim |
| D45 | destino trocado: Shutdown+LandedSignal -> EmergencyLanding (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:100:50: error: [GHC-39999] | sim |
| D46 | destino trocado: Shutdown+SystemCutoff -> Grounded (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:101:50: error: [GHC-39999] | sim |
| D47 | destino trocado: Shutdown+SystemCutoff -> InFlight (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:101:50: error: [GHC-39999] | sim |
| D48 | destino trocado: Shutdown+SystemCutoff -> EmergencyLanding (original Shutdown) | recusado | **recusado na compilação** | src\Avionics\Crem.hs:101:50: error: [GHC-39999] | sim |

Mutantes avaliados: 48. Recusados na compilação: 32. Aceitos: 16. Vivos: 0. Previsão confirmada em 48 de 48.

Notas: a previsão (32 recusados, 16 aceitos) é combinatória e decorre da topologia declarada; este relatório é a medida.
Um mutante previsto como recusado só conta como confirmado se o erro do GHC citar AllowedTransition.
