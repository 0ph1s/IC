#!/usr/bin/env bash
# O3 (plano v2, T12): exporta traços da IMPLEMENTAÇÃO (CREM), valida-os no TLC contra AvionicsLoop.tla
# (via TraceCheck.tla) e confere o resultado. Também exporta o grafo (T21) e a cegueira por sinal (T14).
#
# Pré-requisitos: GHC/cabal (como run_all.sh), Java e 04_tla/tools/tla2tools.jar, Python 3.
# Uso (em 04_tla/):   bash run_trace_validation.sh <pasta de saída> [pasta 03_codigo]
#   - exporta com `cabal run validation-export` (grafo_*.csv, cegueira_por_sinal.txt, TraceData.tla, tracos.csv);
#   - roda o TLC com -deadlock (todo traço termina) e -dump;
#   - check_trace_dump.py diz quantos traços foram aceitos. Esperado: todos os de aresta e aleatórios aceitos,
#     todos os corrompidos recusados. Código de saída 0 se for assim.
# Variável BUILDDIR (opcional): pasta de build do cabal. Sem ela, usa o build normal de 03_codigo. No Windows,
# em pastas de trabalho de caminho longo, aponte para uma pasta curta (limite de caminho do sistema).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(mkdir -p "${1:-$HERE/saida_traces}" && cd "${1:-$HERE/saida_traces}" && pwd)"
CODE="$(cd "${2:-$HERE/../03_codigo}" && pwd)"
JAR="$HERE/tools/tla2tools.jar"
export LANG=C.UTF-8
BUILDOPT=(); [ -n "${BUILDDIR:-}" ] && BUILDOPT=(--builddir="$BUILDDIR")
( cd "$CODE" && cabal run "${BUILDOPT[@]}" -v0 avionics-validation:exe:validation-export -- "$OUT" ) || { echo "FALHA: exportação"; exit 2; }
cp "$OUT/TraceData.tla" "$HERE/TraceData.tla"
rm -rf "$HERE/states_trace"
( cd "$HERE" && java -Xmx2g -cp "$JAR" tlc2.TLC -deadlock -workers 4 -metadir states_trace \
    -dump states_trace/dump.txt -config TraceCheck_OneSlot.cfg TraceCheck.tla ) > "$OUT/18_tlc_trace_validation.txt" 2>&1
tcode=$?
[ "$tcode" -eq 0 ] || { echo "FALHA: TLC terminou com código $tcode"; exit 2; }
PY=""; for c in python python3; do if "$c" -c 'import sys' > /dev/null 2>&1; then PY="$c"; break; fi; done
[ -n "$PY" ] || { echo "FALHA: nenhum Python"; exit 2; }
PYTHONIOENCODING=utf8 "$PY" "$HERE/check_trace_dump.py" "$HERE/states_trace/dump.txt.dump" "$HERE/TraceData.tla" "$OUT/tracos.csv" "$OUT/aceitos_tlc.txt" | tee "$OUT/18_trace_validation_resultado.txt"
exit "${PIPESTATUS[0]}"
