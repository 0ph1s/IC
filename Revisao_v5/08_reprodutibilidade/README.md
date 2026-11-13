# 08_reprodutibilidade

`run_all.sh` reproduz tudo e escreve em `logs/`. Atende à etapa 1 do plano (congelar e reproduzir) e à melhoria 4 do
documento de 07/11/2026 (scripts reprodutíveis).

```bash
bash Revisao_v5/08_reprodutibilidade/run_all.sh            # ~10 minutos depois da primeira compilação
bash Revisao_v5/08_reprodutibilidade/run_all.sh --mutacao  # inclui mutação do CREM (dezenas de minutos)
```

| Log | O que é |
|---|---|
| `SUMARIO.md` | uma linha por passo, com o resultado |
| `00_versions.txt` | GHC, cabal, clang, sistema, `cabal.project.freeze` |
| `00_build_baseline.txt`, `01_build_hedgehog.txt` | **primeiras** compilações (as de uma máquina sem cache), sem avisos do GHC; mantidas como registro |
| `01_build_all.txt` | compilação de todos os alvos nesta execução |
| `02_negative_matrix.md` | matriz de rejeição, 16 pares, causa conferida |
| `03_model_hedgehog.txt` | Hedgehog: propriedades, mutantes com o contraexemplo reduzido e a semente |
| `04_reach.txt` | alcançabilidade exaustiva: estados, arestas, equivalência, achados |
| `05_c_cpp_matrix.md`, `05_c_cpp_raw.txt` | auditoria de C, C++ e C++17 tipado |
| `06_mutation_haskell.md` | mutação da implementação em CREM (H1 a H8) |
| `06_mutation_h9.md` | mutante H9 (curinga de identidade), executado à parte depois de H1 a H8; uma execução completa de `mutation.sh` agora roda H1 a H9 |
| `15_typed_matrix.md` | matriz de 16 pares em C++17 tipado (8 compilam, 8 recusados por `static_assert`) |
| `16_haskell_defects.md` | seis defeitos na FSM em Haskell ingênua (`-Wall`, `-Werror=incomplete-patterns`, harness) |
| `07_conformance.txt`, `08_boundary.txt` | tabelas × CREM; contrato da fronteira |
| `09_` a `12_baseline_*` | as suítes originais do pacote base reproduzidas |
| `14_tlc_*.txt` | TLC: `OneSlot` (viola `NoPermanentBlindness`), `OneSlot_sem_cegueira`, `Level`, e a conferência cruzada com o Haskell |
| `13_invalid_inflight_shutdown.txt` | teste de invalidez: **falha de propósito** com `Could not deduce AllowedTransition` |

## Limites da reprodução

* Uma máquina (Windows 11), um compilador por linguagem. Tempos servem de ordem de grandeza.
* `cabal.project.freeze` fixa as versões das dependências; o índice do Hackage local tem 118 dias (aviso do cabal) e **não foi atualizado**.
* O TLC roda à parte: `bash 04_tla/run_tlc.sh` (exige `04_tla/tools/tla2tools.jar` v1.7.4, não versionado) e escreve `logs/14_tlc_*.txt`.
* A mutação roda em cópia temporária e não altera o projeto; ela recompila tudo na primeira vez.
