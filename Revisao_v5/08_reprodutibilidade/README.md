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
| `00_build_baseline.txt`, `01_build_hedgehog.txt` | **primeiras** compilações (as de uma máquina sem cache); mantidas como registro histórico |
| `01_build_all.txt` | compilação (incremental) de todos os alvos nesta execução |
| `01_build_clean.txt` | compilação **limpa** de todos os alvos, numa pasta própria apagada a cada execução: é ela que conta os avisos do GHC (o passo reprova se houver algum) |
| `02_negative_matrix.md` | matriz de rejeição, 16 pares, causa conferida e tamanho de cada diagnóstico |
| `03_model_hedgehog.txt` | Hedgehog com semente **fixa** (impressa no início): propriedades, mutantes com o contraexemplo reduzido |
| `04_reach.txt` | alcançabilidade exaustiva: estados, arestas, equivalência, achados |
| `05_c_cpp_matrix.md`, `05_c_cpp_raw.txt` | auditoria de C, C++ e C++17 tipado, com o tamanho do diagnóstico em A (dados da Figura 2 do artigo do SCP) |
| `06_mutation_haskell.md` | mutação da implementação em CREM (H1 a H9; só com `--mutacao`) |
| `15_typed_matrix.md` | matriz de 16 pares em C++17 tipado (8 compilam, 8 recusados por `static_assert`) |
| `16_haskell_defects.md` | seis defeitos na FSM em Haskell ingênua (`-Wall`, `-Werror=incomplete-patterns`, harness) e as classes D5 e D6 na ação do CREM (C5, C6) |
| `07_conformance.txt`, `08_boundary.txt` | tabelas × CREM; contrato da fronteira |
| `09_` a `12_baseline_*` | as suítes originais do pacote base reproduzidas |
| `14_tlc_*.txt` | TLC: `OneSlot` (viola `NoPermanentBlindness`), `OneSlot_sem_cegueira`, `Level`, e a conferência cruzada com o Haskell |
| `13_invalid_inflight_shutdown.txt` | teste de invalidez: **falha de propósito** com `Could not deduce AllowedTransition` |

## Limites da reprodução

* Uma máquina (Windows 11), um compilador por linguagem. Tempos servem de ordem de grandeza.
* `cabal.project.freeze` fixa as versões das dependências; o índice do Hackage local tem 118 dias (aviso do cabal) e **não foi atualizado**.
* O TLC é um passo do `run_all.sh` e também roda à parte: `bash 04_tla/run_tlc.sh` (exige Java, Python e `04_tla/tools/tla2tools.jar` v1.7.4, não versionado; sem o jar, o passo é marcado FALHA) e escreve `logs/14_tlc_*.txt`.
* Os bytes dos diagnósticos incluem o caminho absoluto dos arquivos compilados e mudam com a pasta do repositório; as linhas, não.
* Os logs desta pasta são todos gerados pelos scripts; nenhum é editado à mão.
* A mutação roda em cópia temporária e não altera o projeto; ela recompila tudo na primeira vez.

## Passos acrescentados na v3 do artigo JFP (18 a 19/11/2026)

| Passo | Arquivo | O que mostra |
|---|---|---|
| `validation-sd-tests` | `17_sd_48_ternos.txt` | determinação do estado (SD), no sentido comportamental, a partir dos 48 ternos (404 208 casos exaustivos e 5 000 testes Hedgehog), com dois controles negativos que reprovam |
| validação de traços (O3) | `18_trace_validation_console.txt`, `18_traces/` | traços da implementação aceitos pelo TLC contra `AvionicsLoop.tla`; corrompidos recusados; grafo exportado (`grafo_*.csv`) e cegueira por sinal (`cegueira_por_sinal.txt`) |
| SCION (opcional, `SCXML_DIR`) | `18_scion_console.txt` | os mesmos traços no SCION: aceita o mesmo conjunto que o TLC |
| amostragem | `19_amostragem.md` | probabilidade exata de um teste aleatório (e de uma enumeração limitada) achar a lacuna da bateria |
| `--destinos` | `06b_mutation_dest48.md` | os 48 mutantes de destino: 32 recusados pelo compilador, 16 aceitos e mortos pelas suítes |
| `--justica` | `20_justica/20_justica.md` | `NoPermanentBlindness` sob 9 hipóteses de justiça, para `OneSlot` e `Level` |
| `--px4` | `21_px4_console.txt`, `../11_oraculo-px4/logs/` | os traços da implementação passados pelo failsafe real do PX4 (baixado do GitHub, precisa de rede e de `clang++`); autoteste 14/14 e divergências só em 3 classes explicadas. Ver `11_oraculo-px4/README.md` |

O3 e o SCION contra os 16 mutantes de destino que o compilador aceita rodam à parte, em cópia de trabalho: `python 03_codigo/validation/scripts/o3_mutants.py` (com `SCXML_DIR` definido para incluir o SCION; sem ele, só o TLC) escreve `logs/18_o3_contra_mutantes.md` (cerca de 1 hora; em Windows, `TMPDIR` curto). **Executado neste repositório em 19/11/2026**: 16 de 16 mutantes recusados pelo TLC e 16 de 16 pelo SCION, com o mesmo conjunto de traços aceitos nos 16 (o console está em `logs/18_o3_contra_mutantes_console.txt`). Antes disso, uma versão anterior do script e `04_tla/scion/compare_oracles.sh` tinham sido executados em cópias de trabalho (18 e 19/11/2026), com o mesmo resultado.
