#!/usr/bin/env bash
# T25/T13 (plano v2): compara, traço a traço, o que o O3 (TLC contra AvionicsLoop.tla) e o O2 (SCION contra
# avionics_loop.scxml) ACEITAM, para o conjunto de traços de cada pasta dada. Cada pasta tem TraceData.tla e
# tracos.csv (saída de `validation-export`), da implementação original ou de um mutante.
#
# Uso: bash compare_oracles.sh <pasta 04_tla> <SCXML_DIR> <saída.md> <pasta de traços>...
#   <pasta 04_tla>  : com AvionicsLoop.tla, TraceCheck.tla, TraceCheck_OneSlot.cfg, check_trace_dump.py, tools/tla2tools.jar
#   <SCXML_DIR>     : onde se fez `npm install scxml@4.3.1 --ignore-scripts`
set -u
TLA="$1"; SCXML_DIR="$2"; OUT="$3"; shift 3
HERE="$(cd "$(dirname "$0")" && pwd)"
export SCXML_DIR
{
  echo "# O2 (SCION) x O3 (TLC): traços aceitos por cada oráculo"
  echo
  echo "| Traços de | TLC aceitos | SCION aceitos | listas idênticas |"
  echo "|---|---|---|---|"
} > "$OUT"
for d in "$@"; do
  name="$(basename "$d")"
  cp "$d/TraceData.tla" "$TLA/TraceData.tla"
  rm -rf "$TLA/states_cmp"
  ( cd "$TLA" && java -Xmx2g -cp tools/tla2tools.jar tlc2.TLC -deadlock -workers 4 -metadir states_cmp \
      -dump states_cmp/dump.txt -config TraceCheck_OneSlot.cfg TraceCheck.tla ) > /dev/null 2>&1
  PYTHONIOENCODING=utf8 python "$TLA/check_trace_dump.py" "$TLA/states_cmp/dump.txt.dump" "$TLA/TraceData.tla" "$d/tracos.csv" "$d/aceitos_tlc.txt" > /dev/null 2>&1
  ACCEPT_LIST="$d/aceitos_scion.txt" node --no-deprecation "$HERE/scion_oracle.js" "$d/TraceData.tla" "$d/tracos.csv" > /dev/null 2>&1
  a=$(grep -c . "$d/aceitos_tlc.txt"); b=$(grep -c . "$d/aceitos_scion.txt")
  # o Python do Windows grava CRLF e o Node grava LF: comparar sem o CR
  if cmp -s <(tr -d '\r' < "$d/aceitos_tlc.txt") <(tr -d '\r' < "$d/aceitos_scion.txt"); then same=sim; else same="**NÃO**"; fi
  echo "| $name | $a | $b | $same |" | tee -a "$OUT"
done
