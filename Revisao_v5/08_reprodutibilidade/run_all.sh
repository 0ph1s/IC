#!/usr/bin/env bash
# ============================================================================
# REPRODUZ TUDO da Revisao_v5 e registra os logs (parecer de 03/11/2026, etapa 1 do plano de ação:
# "congelar versão e reproduzir os experimentos atuais; log de build, lista de testes positivos e
# negativos, versão do GHC e dependências").
#
# Uso (de qualquer pasta):
#     bash Revisao_v5/08_reprodutibilidade/run_all.sh              # tudo, sem a mutação (rápida: alguns minutos)
#     bash Revisao_v5/08_reprodutibilidade/run_all.sh --mutacao    # inclui a mutação da implementação (lenta: dezenas de minutos)
#     --destinos   inclui a mutação exaustiva de destinos, 48 mutantes (lenta: cerca de 2 horas; em Windows, defina
#                  TMPDIR com caminho curto, por exemplo TMPDIR=/c/mv)
#     --justica    inclui o TLC sob hipóteses de justiça alternativas (cerca de 35 minutos)
#     As opções se combinam. SCXML_DIR (opcional): pasta onde se fez `npm install scxml@4.3.1 --ignore-scripts`;
#     se definida, o oráculo SCION também valida os traços (04_tla/scion/).
#
# Requisitos: GHC 9.6.7, cabal 3.12.1.0, bash (no Windows, o Git Bash), clang/clang++ (os do GHC servem),
# Java e 04_tla/tools/tla2tools.jar v1.7.4 (ver 04_tla/run_tlc.sh; sem o jar, o passo do TLC é marcado FALHA) e Python.
# A primeira execução compila tudo e baixa do Hackage as dependências do Hedgehog.
#
# Escreve 08_reprodutibilidade/logs/ (um arquivo por passo) e logs/SUMARIO.md. Sai com 0 se todos os
# passos esperados passarem (o teste de invalidez DEVE falhar na compilação, e isso conta como passo ok).
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"          # 08_reprodutibilidade/
ROOT="$(cd "$HERE/.." && pwd)"                 # Revisao_v5/
CODE="$ROOT/03_codigo"
LOGS="$HERE/logs"
WITH_MUT=0; WITH_DEST=0; WITH_FAIR=0
for arg in "$@"; do
  case "$arg" in
    --mutacao) WITH_MUT=1;;
    --destinos) WITH_DEST=1;;
    --justica) WITH_FAIR=1;;
    *) echo "opção desconhecida: $arg"; exit 2;;
  esac
done
export LANG=C.UTF-8
mkdir -p "$LOGS"
cd "$CODE" || exit 2

SUM="$LOGS/SUMARIO.md"
{
  echo "# Sumário da execução de \`run_all.sh\`"
  echo
  echo "Data: $(date '+%F %T'). Cada linha é um passo; o log completo está no arquivo indicado."
  echo
  echo "| Passo | Resultado | Log |"
  echo "|---|---|---|"
} > "$SUM"
FAILED=0
record() { # $1 nome, $2 ok|FALHA, $3 log
  echo "| $1 | $2 | \`$3\` |" >> "$SUM"
  printf '%-58s %s\n' "$1" "$2"
  [ "$2" = ok ] || FAILED=1
}
run_cabal_test() { # $1 rótulo, $2 alvo, $3 arquivo de log, resto: opções
  local label="$1" target="$2" log="$3"; shift 3
  cabal test "$target" --test-show-details=direct "$@" 2>&1 | grep -v "package list for\|Run 'cabal update'" > "$LOGS/$log"
  if [ "${PIPESTATUS[0]}" -eq 0 ]; then record "$label" ok "$log"; else record "$label" FALHA "$log"; fi
}

# ---------------------------------------------------------------------------
# 0. Versões e dependências
# ---------------------------------------------------------------------------
[ -f "$CODE/cabal.project.freeze" ] || cabal freeze > /dev/null 2>&1   # fixa as versões das dependências
{
  echo "data: $(date '+%F %T')"
  echo "sistema: $(uname -a)"; cmd //c ver 2>/dev/null | tr -d '\r' | sed '/^$/d' | iconv -f CP850 -t UTF-8 2>/dev/null
  echo "ghc: $(ghc --numeric-version)"; echo "cabal: $(cabal --numeric-version)"
  MING="/c/ghcup/ghc/$(ghc --numeric-version)/mingw/bin"
  [ -x "$MING/clang.exe" ] && echo "clang: $("$MING/clang.exe" --version | head -1)"
  command -v pdflatex > /dev/null && echo "pdflatex: $(pdflatex --version | head -1)"
  echo "repositório de trabalho (IC), HEAD: $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null) (a pasta Revisao_v5 pode estar não versionada)"
  echo "instantâneo avionics-crem: ver 03_codigo/base/SNAPSHOT.md"
  echo
  echo "--- cabal.project.freeze (versões exatas das dependências) ---"
  [ -f "$CODE/cabal.project.freeze" ] && sed -n '1,200p' "$CODE/cabal.project.freeze" || echo "(ainda não gerado: cabal freeze)"
} > "$LOGS/00_versions.txt"
record "versões registradas" ok "00_versions.txt"

# ---------------------------------------------------------------------------
# 1. Compilação (alvos explícitos: `cabal build all` tentaria o teste de invalidez, que não compila)
# ---------------------------------------------------------------------------
TARGETS=(avionics-crem:lib:avionics-crem avionics-crem:exe:avionics-sim avionics-crem:exe:avionics-crem
  avionics-crem:test:avionics-spec-tests avionics-crem:test:avionics-sim-tests avionics-crem:test:avionics-chain-tests avionics-crem:test:avionics-policy-tests
  avionics-validation:lib:avionics-validation avionics-validation:test:validation-conformance-tests avionics-validation:test:validation-boundary-tests
  avionics-validation:test:validation-reach-tests avionics-validation:test:validation-model-tests
  avionics-validation:test:validation-sd-tests avionics-validation:exe:validation-export avionics-validation:exe:validation-sampling)
cabal build "${TARGETS[@]}" 2>&1 | grep -v "package list for\|Run 'cabal update'" > "$LOGS/01_build_all.txt"
if [ "${PIPESTATUS[0]}" -eq 0 ]; then record "compilação de todos os alvos (-Wall -Werror=incomplete-patterns)" ok "01_build_all.txt"
else record "compilação de todos os alvos" FALHA "01_build_all.txt"; fi

# Avisos do GHC: só uma compilação LIMPA os mostra (numa compilação incremental, módulos já compilados não
# são recompilados e seus avisos não reaparecem). Pasta própria, dentro de dist-newstyle (ignorada pelo git),
# apagada a cada execução; a compilação normal acima não é afetada.
WARN_DIR="$CODE/dist-newstyle/w"
rm -rf "$WARN_DIR"
cabal build --builddir="$WARN_DIR" "${TARGETS[@]}" 2>&1 | grep -v "package list for\|Run 'cabal update'" > "$LOGS/01_build_clean.txt"
cc_clean=${PIPESTATUS[0]}
n_mod=$(grep -c "Compiling" "$LOGS/01_build_clean.txt")
n_warn=$(grep -c ": warning:" "$LOGS/01_build_clean.txt")
echo "compilação limpa: $n_mod módulos compilados, $n_warn avisos do GHC (linhas com ': warning:')" >> "$LOGS/01_build_clean.txt"
if [ "$cc_clean" -eq 0 ] && [ "$n_warn" -eq 0 ]; then record "compilação limpa de todos os alvos: $n_mod módulos, 0 avisos do GHC" ok "01_build_clean.txt"
else record "compilação limpa: código $cc_clean, $n_warn avisos do GHC" FALHA "01_build_clean.txt"; fi
rm -rf "$WARN_DIR"

# ---------------------------------------------------------------------------
# 2. Teste de invalidez do pacote base: DEVE falhar na compilação, com a causa conhecida
# ---------------------------------------------------------------------------
cabal build avionics-crem:test:invalid-inflight-shutdown 2>&1 | grep -v "package list for\|Run 'cabal update'" > "$LOGS/13_invalid_inflight_shutdown.txt"
if [ "${PIPESTATUS[0]}" -ne 0 ] && grep -q "Could not deduce" "$LOGS/13_invalid_inflight_shutdown.txt"; then
  record "invalid-inflight-shutdown: não compila, com 'Could not deduce AllowedTransition' (esperado)" ok "13_invalid_inflight_shutdown.txt"
else record "invalid-inflight-shutdown: deveria falhar com 'Could not deduce'" FALHA "13_invalid_inflight_shutdown.txt"; fi

# ---------------------------------------------------------------------------
# 3. Suítes do pacote base (reprodução dos resultados da v4)
# ---------------------------------------------------------------------------
run_cabal_test "base: avionics-spec-tests (conformidade, 16 verificações)" avionics-crem:test:avionics-spec-tests 09_baseline_spec_tests.txt
run_cabal_test "base: avionics-sim-tests (simulador, N = 4)" avionics-crem:test:avionics-sim-tests 10_baseline_sim_tests.txt
run_cabal_test "base: avionics-chain-tests (cadeia da bateria, N = 8)" avionics-crem:test:avionics-chain-tests 11_baseline_chain_tests.txt
run_cabal_test "base: avionics-policy-tests (oráculo e políticas, N = 8)" avionics-crem:test:avionics-policy-tests 12_baseline_policy_tests.txt

# ---------------------------------------------------------------------------
# 4. Suítes novas (validação em três níveis)
# ---------------------------------------------------------------------------
run_cabal_test "novo: validation-conformance-tests (tabelas x CREM, exaustivo)" avionics-validation:test:validation-conformance-tests 07_conformance.txt
run_cabal_test "novo: validation-boundary-tests (fronteira tipada)" avionics-validation:test:validation-boundary-tests 08_boundary.txt
run_cabal_test "novo: validation-reach-tests (alcançabilidade exaustiva)" avionics-validation:test:validation-reach-tests 04_reach.txt
run_cabal_test "novo: validation-model-tests (Hedgehog, com mutantes)" avionics-validation:test:validation-model-tests 03_model_hedgehog.txt
run_cabal_test "novo: validation-sd-tests ((SD) nos 48 ternos, com controles negativos)" avionics-validation:test:validation-sd-tests 17_sd_48_ternos.txt

# ---------------------------------------------------------------------------
# 5. Matriz de rejeição (16 compilações, causa conferida) e auditoria de C e C++
# ---------------------------------------------------------------------------
bash "$CODE/validation/scripts/negative_matrix.sh" > "$LOGS/02_negative_matrix_console.txt" 2>&1
if [ $? -eq 0 ]; then record "matriz de rejeição: 8 compilam, 8 rejeitados, causa conferida" ok "02_negative_matrix.md"; else record "matriz de rejeição" FALHA "02_negative_matrix_console.txt"; fi

bash "$ROOT/05_c-cpp/scripts/audit.sh" > "$LOGS/05_c_cpp_console.txt" 2>&1
if [ $? -eq 0 ]; then record "auditoria C/C++: versões sem defeito sem aviso e iguais à tabela" ok "05_c_cpp_matrix.md"; else record "auditoria C/C++" FALHA "05_c_cpp_console.txt"; fi

bash "$ROOT/05_c-cpp/scripts/typed_matrix.sh" > "$LOGS/15_typed_matrix_console.txt" 2>&1
if [ $? -eq 0 ]; then record "matriz de 16 pares em C++17 tipado: 8 compilam, 8 recusados por static_assert" ok "15_typed_matrix.md"; else record "matriz C++17 tipado" FALHA "15_typed_matrix_console.txt"; fi

bash "$ROOT/05_c-cpp/scripts/haskell_defects.sh" > "$LOGS/16_haskell_defects_console.txt" 2>&1
if [ $? -eq 0 ]; then record "defeitos em Haskell: FSM ingênua (N0 a N6) e ação do CREM (C0, C5, C6)" ok "16_haskell_defects.md"; else record "defeitos Haskell" FALHA "16_haskell_defects_console.txt"; fi

# ---------------------------------------------------------------------------
# 5b. TLC (só se 04_tla/tools/tla2tools.jar existir; ver o cabeçalho de 04_tla/run_tlc.sh)
# ---------------------------------------------------------------------------
if [ -f "$ROOT/04_tla/tools/tla2tools.jar" ]; then
  bash "$ROOT/04_tla/run_tlc.sh" > "$LOGS/14_tlc_console.txt" 2>&1
  if [ $? -eq 0 ]; then record "TLC: OneSlot viola NoPermanentBlindness, Level satisfaz; ternos iguais aos do Haskell" ok "14_tlc_console.txt"; else record "TLC" FALHA "14_tlc_console.txt"; fi
else
  record "TLC: não executado (falta 04_tla/tools/tla2tools.jar; ver 04_tla/run_tlc.sh)" FALHA "14_tlc_*.txt"
fi

# ---------------------------------------------------------------------------
# 5c. O3: traços da implementação validados no TLC contra AvionicsLoop.tla (T12), grafo exportado (T21) e
#     cegueira medida a cada sinal (T14). Também precisa do jar do TLC. Opcional: o SCION como segundo motor (T13).
# ---------------------------------------------------------------------------
if [ -f "$ROOT/04_tla/tools/tla2tools.jar" ]; then
  TRACES="$LOGS/18_traces"; rm -rf "$TRACES"
  bash "$ROOT/04_tla/run_trace_validation.sh" "$TRACES" > "$LOGS/18_trace_validation_console.txt" 2>&1
  if [ $? -eq 0 ]; then record "O3: traços da implementação aceitos pelo TLC (aresta e aleatórios); corrompidos recusados" ok "18_trace_validation_console.txt"
  else record "O3: validação de traços no TLC" FALHA "18_trace_validation_console.txt"; fi
  if [ -n "${SCXML_DIR:-}" ] && [ -d "$SCXML_DIR/node_modules/scxml" ] && command -v node > /dev/null; then
    SCXML_DIR="$SCXML_DIR" ACCEPT_LIST="$TRACES/aceitos_scion.txt" node --no-deprecation "$ROOT/04_tla/scion/scion_oracle.js" "$ROOT/04_tla/TraceData.tla" "$TRACES/tracos.csv" > "$LOGS/18_scion_console.txt" 2>&1
    if [ $? -eq 0 ] && cmp -s <(tr -d '\r' < "$TRACES/aceitos_tlc.txt") <(tr -d '\r' < "$TRACES/aceitos_scion.txt"); then record "O2: SCION aceita os mesmos traços que o TLC" ok "18_scion_console.txt"
    else record "O2: SCION difere do TLC" FALHA "18_scion_console.txt"; fi
  else
    echo "| O2 (SCION): não executado (defina SCXML_DIR; ver 04_tla/scion/) | n/a | \`18_scion_console.txt\` |" >> "$SUM"
  fi
else
  record "O3: não executado (falta 04_tla/tools/tla2tools.jar)" FALHA "18_trace_validation_console.txt"
fi

# ---------------------------------------------------------------------------
# 5d. Amostragem contra fechamento (T16) e enumeração limitada por profundidade (T17): probabilidades exatas
# ---------------------------------------------------------------------------
( cd "$CODE/validation" && cabal run -v0 avionics-validation:exe:validation-sampling ) 2>&1 | grep -v "package list for\|Run 'cabal update'" > "$LOGS/19_amostragem.md"
if [ "${PIPESTATUS[0]}" -eq 0 ]; then record "amostragem contra fechamento (valores exatos) e enumeração por profundidade" ok "19_amostragem.md"; else record "amostragem contra fechamento" FALHA "19_amostragem.md"; fi

# ---------------------------------------------------------------------------
# 6. Mutação da implementação em CREM (lenta; só com --mutacao)
# ---------------------------------------------------------------------------
if [ "$WITH_MUT" -eq 1 ]; then
  bash "$CODE/validation/scripts/mutation.sh" > "$LOGS/06_mutation_haskell_console.txt" 2>&1
  if [ $? -eq 0 ]; then record "mutação do CREM (H1 a H9): nenhum mutante vivo" ok "06_mutation_haskell.md"; else record "mutação do CREM: há mutante vivo ou erro" FALHA "06_mutation_haskell_console.txt"; fi
else
  echo "| mutação do CREM | não executada (use --mutacao) | \`06_mutation_haskell.md\` (execução anterior, se existir) |" >> "$SUM"
fi

if [ "$WITH_DEST" -eq 1 ]; then
  bash "$CODE/validation/scripts/mutation_dest48.sh" > "$LOGS/06b_mutation_dest48_console.txt" 2>&1
  if [ $? -eq 0 ]; then record "mutação exaustiva de destinos (48): 32 recusados, 16 aceitos, nenhum vivo" ok "06b_mutation_dest48.md"; else record "mutação de destinos: há mutante vivo ou erro" FALHA "06b_mutation_dest48_console.txt"; fi
else
  echo "| mutação de destinos (48) | não executada (use --destinos) | \`06b_mutation_dest48.md\` (execução anterior, se existir) |" >> "$SUM"
fi

if [ "$WITH_FAIR" -eq 1 ] && [ -f "$ROOT/04_tla/tools/tla2tools.jar" ]; then
  bash "$ROOT/04_tla/run_fairness.sh" "$LOGS/20_justica" > "$LOGS/20_justica_console.txt" 2>&1
  if [ $? -eq 0 ]; then record "TLC sob hipóteses de justiça: tabela igual à esperada (9 hipóteses x 2 políticas)" ok "20_justica/20_justica.md"; else record "TLC sob hipóteses de justiça" FALHA "20_justica_console.txt"; fi
else
  echo "| TLC sob hipóteses de justiça | não executado (use --justica) | \`20_justica/20_justica.md\` (execução anterior, se existir) |" >> "$SUM"
fi

echo
echo "sumário: $SUM"
[ "$FAILED" -eq 0 ] && echo "TUDO OK" || echo "HÁ FALHAS: veja o sumário"
exit $FAILED
