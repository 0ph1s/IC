#!/usr/bin/env bash
# Oráculo PX4 (T27): baixa o failsafe do PX4 (se faltar), compila o código real, roda o autoteste e passa os
# traços da implementação (08_reprodutibilidade/logs/18_traces/) pelo failsafe do PX4.
# Uso (de qualquer pasta):  bash 11_oraculo-px4/run_px4_oracle.sh [pasta de trabalho]
#   pasta de trabalho (padrão: $TMPDIR/px4_oraculo): recebe o checkout do PX4 (px4_src/) e o build (build/).
#   No Windows use um caminho curto (por exemplo C:/mv) e deixe o clang do GHC no PATH.
# Saída: logs/px4_*.md e logs/px4_console.txt aqui; código 0 se o autoteste passa e não há classe inexplicada.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
WORK="${1:-${TMPDIR:-/tmp}/px4_oraculo}"
TR="$ROOT/08_reprodutibilidade/logs/18_traces"
LOGS="$HERE/logs"
mkdir -p "$WORK" "$LOGS"
PY=""; for c in python python3; do if "$c" -c 'import sys' > /dev/null 2>&1; then PY="$c"; break; fi; done
[ -n "$PY" ] || { echo "nenhum Python"; exit 2; }
W() { command -v cygpath > /dev/null 2>&1 && cygpath -w "$1" || echo "$1"; }
[ -f "$TR/TraceData.tla" ] && [ -f "$TR/tracos.csv" ] || { echo "faltam os traços em $TR (rode 08_reprodutibilidade/run_all.sh antes)"; exit 2; }
[ -f "$WORK/px4_src/src/modules/commander/failsafe/failsafe.cpp" ] || bash "$HERE/fetch_px4.sh" "$WORK/px4_src" || exit 2
bash "$HERE/build.sh" "$WORK/px4_src" "$WORK/build" || exit 2
EXE="$WORK/build/px4_failsafe"; [ -f "$EXE.exe" ] && EXE="$EXE.exe"
FAIL=0
{
  echo "PX4 em $(git -C "$WORK/px4_src" rev-parse HEAD)"
  "$PY" "$HERE/selftest.py" "$(W "$EXE")" || FAIL=1
  for a in 2 3; do
    echo; echo "== traduzindo CriticalBattery como bateria Critical (assert=1), COM_LOW_BAT_ACT=$a"
    "$PY" "$HERE/px4_diff.py" "$(W "$EXE")" "$(W "$TR/TraceData.tla")" "$(W "$TR/tracos.csv")" "$a" "$(W "$LOGS/px4_diff_act$a.md")" 1 || FAIL=1
  done
  echo; echo "== sem afirmar bateria Critical pelo comando (assert=0), COM_LOW_BAT_ACT=2 (sensibilidade da tradução)"
  # só sensibilidade: as classes mudam de proporção de propósito, então o código de saída não conta
  "$PY" "$HERE/px4_diff.py" "$(W "$EXE")" "$(W "$TR/TraceData.tla")" "$(W "$TR/tracos.csv")" 2 "$(W "$LOGS/px4_diff_act2_assert0.md")" 0 || true
  echo "FAIL=$FAIL" > "$WORK/fail.txt"
} 2>&1 | tee "$LOGS/px4_console.txt"
FAIL="$(sed 's/FAIL=//' "$WORK/fail.txt")"
[ "$FAIL" -eq 0 ] && echo "ORÁCULO PX4 OK" || echo "ORÁCULO PX4: FALHA"
exit "$FAIL"
