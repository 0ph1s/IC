# Sumário da execução de `run_all.sh`

Data: 2026-11-19 11:24:16. Cada linha é um passo; o log completo está no arquivo indicado.

| Passo | Resultado | Log |
|---|---|---|
| versões registradas | ok | `00_versions.txt` |
| compilação de todos os alvos (-Wall -Werror=incomplete-patterns) | ok | `01_build_all.txt` |
| compilação limpa de todos os alvos: 37 módulos, 0 avisos do GHC | ok | `01_build_clean.txt` |
| invalid-inflight-shutdown: não compila, com 'Could not deduce AllowedTransition' (esperado) | ok | `13_invalid_inflight_shutdown.txt` |
| base: avionics-spec-tests (conformidade, 16 verificações) | ok | `09_baseline_spec_tests.txt` |
| base: avionics-sim-tests (simulador, N = 4) | ok | `10_baseline_sim_tests.txt` |
| base: avionics-chain-tests (cadeia da bateria, N = 8) | ok | `11_baseline_chain_tests.txt` |
| base: avionics-policy-tests (oráculo e políticas, N = 8) | ok | `12_baseline_policy_tests.txt` |
| novo: validation-conformance-tests (tabelas x CREM, exaustivo) | ok | `07_conformance.txt` |
| novo: validation-boundary-tests (fronteira tipada) | ok | `08_boundary.txt` |
| novo: validation-reach-tests (alcançabilidade exaustiva) | ok | `04_reach.txt` |
| novo: validation-model-tests (Hedgehog, com mutantes) | ok | `03_model_hedgehog.txt` |
| novo: validation-sd-tests ((SD) nos 48 ternos, com controles negativos) | ok | `17_sd_48_ternos.txt` |
| matriz de rejeição: 8 compilam, 8 rejeitados, causa conferida | ok | `02_negative_matrix.md` |
| auditoria C/C++: versões sem defeito sem aviso e iguais à tabela | ok | `05_c_cpp_matrix.md` |
| matriz de 16 pares em C++17 tipado: 8 compilam, 8 recusados por static_assert | ok | `15_typed_matrix.md` |
| defeitos em Haskell: FSM ingênua (N0 a N6) e ação do CREM (C0, C5, C6) | ok | `16_haskell_defects.md` |
| TLC: OneSlot viola NoPermanentBlindness, Level satisfaz; ternos iguais aos do Haskell | ok | `14_tlc_console.txt` |
| O3: traços da implementação aceitos pelo TLC (aresta e aleatórios); corrompidos recusados | ok | `18_trace_validation_console.txt` |
| O2: SCION aceita os mesmos traços que o TLC | ok | `18_scion_console.txt` |
| amostragem contra fechamento (valores exatos) e enumeração por profundidade | ok | `19_amostragem.md` |
| mutação do CREM | não executada (use --mutacao) | `06_mutation_haskell.md` (execução anterior, se existir) |
| mutação exaustiva de destinos (48): 32 recusados, 16 aceitos, nenhum vivo | ok | `06b_mutation_dest48.md` |
| TLC sob hipóteses de justiça: tabela igual à esperada (9 hipóteses x 2 políticas) | ok | `20_justica/20_justica.md` |
