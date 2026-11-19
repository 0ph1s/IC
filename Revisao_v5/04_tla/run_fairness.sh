#!/usr/bin/env bash
# T15 (plano v2): NoPermanentBlindness sob hipóteses de justiça alternativas sobre o ambiente externo.
# Para cada política (OneSlot, Level) e cada hipótese de AvionicsLoopFairness.tla, roda o TLC e anota
# o veredito (código 0 = vale; 13 = propriedade temporal violada).
# Uso: bash run_fairness.sh [pasta de logs]   (requer tools/tla2tools.jar; leva cerca de 35 minutos, quase todo
# na hipótese "All", com 20 condições de justiça forte)
# Esperado (registrado em 19/11/2026): OneSlot viola em H0, LandedCmd, CutoffCmd e TakeoffCmd e vale nas demais;
# Level vale em todas. O script sai com 0 se a tabela for exatamente essa.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LOGS="${1:-$HERE/logs_fairness}"
JAR="$HERE/tools/tla2tools.jar"
[ -f "$JAR" ] || { echo "tools/tla2tools.jar ausente; veja o cabeçalho de run_tlc.sh"; exit 2; }
mkdir -p "$LOGS" "$HERE/cfg_fairness"
cd "$HERE" || exit 2
HYPS="H0 Drain Recharge ShedLoad CritCmd LandedCmd CutoffCmd TakeoffCmd All"
OUT="$LOGS/20_justica.md"
FAIL=0
{
  echo "# T15 — NoPermanentBlindness sob hipóteses de justiça sobre o ambiente"
  echo
  echo "TLC 2.19; módulo AvionicsLoopFairness.tla (estende AvionicsLoop.tla). Veredito: **vale** (código 0) ou **violada** (código 13)."
  echo
  echo "| Hipótese (justiça forte sobre o tick) | OneSlot | Level |"
  echo "|---|---|---|"
} > "$OUT"
for h in $HYPS; do
  row="| $h |"
  for pol in OneSlot Level; do
    cfg="cfg_fairness/${h}_${pol}.cfg"
    printf 'SPECIFICATION Spec%s\nCONSTANT Policy = "%s"\nPROPERTY NoPermanentBlindness\n' "$h" "$pol" > "$cfg"
    log="$LOGS/20_justica_${h}_${pol}.txt"
    java -cp "$JAR" tlc2.TLC -metadir "states_f/${h}_${pol}" -config "$cfg" AvionicsLoopFairness.tla > "$log" 2>&1
    code=$?
    case "$code" in
      0) v="vale";;
      13) v="**violada**";;
      *) v="ERRO ($code)"; FAIL=1;;
    esac
    # esperado: violada só com OneSlot em H0, LandedCmd, CutoffCmd e TakeoffCmd
    want=0; if [ "$pol" = OneSlot ]; then case "$h" in H0|LandedCmd|CutoffCmd|TakeoffCmd) want=13;; esac; fi
    [ "$code" -eq "$want" ] || FAIL=1
    row="$row $v |"
  done
  echo "$row" >> "$OUT"
done
{
  echo
  # contagem de estados lida do log (a linha tem a forma "1638 states generated, 1143 distinct states found")
  n=$(sed 's/\x1b\[[0-9;]*m//g' "$LOGS"/20_justica_*.txt | grep -E "states generated, .* distinct states found" | sed -E 's/^([0-9,]+) states generated, ([0-9,]+) distinct.*/\1 gerados, \2 distintos/' | sort | uniq -c | tr '\n' ';')
  echo "Estados por execução (quantas execuções): $n"
} >> "$OUT"
cat "$OUT"
[ "$FAIL" -eq 0 ] && echo "tabela igual à esperada" || echo "FALHA: tabela diferente da esperada"
exit "$FAIL"
