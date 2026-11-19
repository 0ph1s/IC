#!/usr/bin/env bash
# Oráculo PX4 (T27): baixa o failsafe do PX4 (se faltar), compila o código real, roda o autoteste e passa os
# traços da implementação (08_reprodutibilidade/logs/18_traces/) pelo failsafe do PX4.
# Uso (de qualquer pasta):  bash 11_oraculo-px4/run_px4_oracle.sh [pasta de trabalho]
#   pasta de trabalho (padrão: $TMPDIR/px4_oraculo): recebe o checkout do PX4 (px4_src/) e o build (build/).
#   No Windows use um caminho curto (por exemplo C:/mv) e deixe o clang do GHC no PATH.
# FULL=1: enumerações maiores de (SD); MUTANTES=1: o PX4 contra os 16 mutantes de destino (lento).
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
  # política do oráculo em Haskell (OneSlot = a implementação; Level existe só no modelo): precisa de cabal
  if command -v cabal > /dev/null 2>&1; then
    for pol in oneslot level; do
      echo; echo "== oráculo em Haskell, política $pol (traços de validation-export $pol), COM_LOW_BAT_ACT=2"
      ( cd "$ROOT/03_codigo/validation" && cabal run -v0 avionics-validation:exe:validation-export -- "$WORK/tr_$pol" "$pol" ) > /dev/null || FAIL=1
      "$PY" "$HERE/px4_diff.py" "$(W "$EXE")" "$(W "$WORK/tr_$pol/TraceData.tla")" "$(W "$WORK/tr_$pol/tracos.csv")" 2 "$(W "$LOGS/px4_diff_$pol.md")" 1 || FAIL=1
    done
  else
    echo "cabal ausente: política Level não rodada"
  fi
  for cfg in "5 100" "5 1000"; do
    set -- $cfg
    echo; echo "== com atraso: COM_FAIL_ACT_T=$1 s, $2 ms por passo, COM_LOW_BAT_ACT=2"
    "$PY" "$HERE/px4_diff.py" "$(W "$EXE")" "$(W "$TR/TraceData.tla")" "$(W "$TR/tracos.csv")" 2 "$(W "$LOGS/px4_diff_act2_T$1_$2ms.md")" 1 "$1" "$2" || FAIL=1
  done
  echo; echo "== (SD) com atraso, enumeração exaustiva rápida (alfabeto 0,1,2; N=8, L=4)"
  "$PY" "$HERE/px4_sd.py" "$(W "$EXE")" "$(W "$LOGS/px4_sd_rapido.md")" 8 4 0,1,2,3,5 0,1,2 > "$WORK/sd_rapido.txt" || FAIL=1
  tail -9 "$WORK/sd_rapido.txt"
  echo; echo "== takeover do piloto: cenários e sonda nos estados EmergencyLanding (px4_takeover.py)"
  "$PY" "$HERE/px4_takeover.py" "$(W "$EXE")" "$(W "$TR/TraceData.tla")" "$(W "$TR/tracos.csv")" "$(W "$LOGS/px4_takeover.md")" > "$WORK/takeover.txt" || FAIL=1
  grep -E "^T=" "$WORK/takeover.txt"
  echo; echo "== (SD) com manche e troca de modo, enumeração rápida (bateria:manche:modo; N=6, L=3)"
  "$PY" "$HERE/px4_sd.py" "$(W "$EXE")" "$(W "$LOGS/px4_sd_takeover_rapido.md")" 6 3 0,2,5 0:0,2:0,2:1,2:0:4 > "$WORK/sd_takeover.txt" || FAIL=1
  tail -5 "$WORK/sd_takeover.txt"
  echo; echo "== outras causas de failsafe: trava ou libera, lei de severidade, ordem (px4_causas.py, 40 configurações)"
  "$PY" "$HERE/px4_causas.py" "$(W "$EXE")" "$(W "$LOGS/px4_causas_rapido.md")" 40 > "$WORK/causas.txt" || FAIL=1
  grep -E "^T=|^ordem" "$WORK/causas.txt"
  echo; echo "== (SD) com 4 causas, uma de cada vez (alfabeto 0,bat2,gnss1,mc1,gf1; N=6, L=3)"
  PX4_PARAMS="NAV_RCL_ACT=2,COM_GNSSLOSS_ACT=2,GF_ACTION=2" "$PY" "$HERE/px4_sd.py" "$(W "$EXE")" "$(W "$LOGS/px4_sd_causas_rapido.md")" 6 3 0,2 0,bat2,gnss1,mc1,gf1 > "$WORK/sd_causas.txt" || FAIL=1
  tail -4 "$WORK/sd_causas.txt"
  if [ "${FULL:-0}" = 1 ]; then
    "$PY" "$HERE/px4_causas.py" "$(W "$EXE")" "$(W "$LOGS/px4_causas.md")" 300 > /dev/null || FAIL=1
    PX4_PARAMS="NAV_RCL_ACT=2,COM_GNSSLOSS_ACT=2,GF_ACTION=2" "$PY" "$HERE/px4_sd.py" "$(W "$EXE")" "$(W "$LOGS/px4_sd_causas.md")" 7 3 0,2 0,bat2,gnss1,mc1,gf1 > /dev/null || FAIL=1
    PX4_PARAMS="NAV_RCL_ACT=2,COM_GNSSLOSS_ACT=2,GF_ACTION=2" "$PY" "$HERE/px4_sd.py" "$(W "$EXE")" "$(W "$LOGS/px4_sd_causas_ref.md")" 7 3 0,2 0,bat2 > /dev/null || FAIL=1
    "$PY" "$HERE/px4_sd.py" "$(W "$EXE")" "$(W "$LOGS/px4_sd_takeover.md")" 8 4 0,2,5 0:0,2:0,2:1,2:0:4 > /dev/null || FAIL=1
    "$PY" "$HERE/px4_sd.py" "$(W "$EXE")" "$(W "$LOGS/px4_sd_takeover_ref.md")" 8 4 0,2,5 0:0,2:0 > /dev/null || FAIL=1
  fi
  if [ "${FULL:-0}" = 1 ]; then
    echo; echo "== (SD) com atraso, enumerações maiores (FULL=1; cerca de 3 minutos)"
    "$PY" "$HERE/px4_sd.py" "$(W "$EXE")" "$(W "$LOGS/px4_sd_atraso_2simbolos.md")" 16 8 0,1,2,3,5,8 0,2 > /dev/null || FAIL=1
    "$PY" "$HERE/px4_sd.py" "$(W "$EXE")" "$(W "$LOGS/px4_sd_atraso_3simbolos.md")" 10 5 0,1,2,3 0,1,2 > /dev/null || FAIL=1
  fi
  echo; echo "== sem afirmar bateria Critical pelo comando (assert=0), COM_LOW_BAT_ACT=2 (sensibilidade da tradução)"
  if [ "${MUTANTES:-0}" = 1 ]; then
    echo; echo "== PX4 contra os 16 mutantes de destino (MUTANTES=1; cerca de 40 minutos; TMPDIR curto no Windows)"
    "$PY" "$HERE/px4_mutants.py" "$(W "$EXE")" > "$WORK/mutantes.txt" 2>&1 || FAIL=1
    tail -3 "$WORK/mutantes.txt"
  fi
  # só sensibilidade: as classes mudam de proporção de propósito, então o código de saída não conta
  "$PY" "$HERE/px4_diff.py" "$(W "$EXE")" "$(W "$TR/TraceData.tla")" "$(W "$TR/tracos.csv")" 2 "$(W "$LOGS/px4_diff_act2_assert0.md")" 0 || true
  echo "FAIL=$FAIL" > "$WORK/fail.txt"
} 2>&1 | tee "$LOGS/px4_console.txt"
FAIL="$(sed 's/FAIL=//' "$WORK/fail.txt")"
[ "$FAIL" -eq 0 ] && echo "ORÁCULO PX4 OK" || echo "ORÁCULO PX4: FALHA"
exit "$FAIL"
